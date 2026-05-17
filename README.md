# HONOR MagicBook Pro 14 AI (ZQC-P, M1010) — Linux fixes

ACPI override + kernel-cmdline patch that gets the **touchpad** and
**touchscreen** working on a HONOR MagicBook Pro 14 AI under Linux, plus a
small i8042 quirk for the internal keyboard.

The repo contains everything needed to:

- apply the fix on a working system (`apply_patch.sh`),
- rebuild the SSDT from source (`build/build_patch.sh`),
- redo the investigation on a similar device (`build/extract_oem_acpi.sh`,
  plus a full Windows-side dump under `win11_dump/`).

---

## Device

| | |
|---|---|
| **Manufacturer** | HONOR |
| **Product name** | ZQC-P |
| **Marketing name** | HONOR MagicBook Pro 14 AI (2026) |
| **DMI version** | M1010 |
| **CPU** | Intel® Core™ Ultra X9 388H ("Panther Lake") |
| **PCH GPIO ID** | `INTC10BC` (five communities, gpiochip0..4) |
| **BIOS** | HONOR 1.09 (2026-03-19) |
| **Touchpad** | Goodix **TOPS0102** on `\_SB.PC00.I2C1.TPD0` (I²C HID, addr `0x5D`) |
| **Touchscreen** | FocalTech **FTSC1000** on `\_SB.PC00.I2C2.TPL1` (I²C HID) |
| **Fingerprint** | Goodix USB `27c6:6f94` (separate problem, see below) |
| **Webcam (built-in)** | Shinetech FHD over USB (`3277:00de`) — works out of the box |

Both touch devices are advertised in firmware with `_HID/_CID = PNP0C50`
(Microsoft HID-over-I²C), so the in-kernel `i2c-hid-acpi` driver is the
correct binding — there is no need for a vendor-specific driver.

---

## Tested environment

- **OS**: CachyOS (Arch-based, rolling)
- **Kernel**: `linux-cachyos 7.0.8-1` and `linux-cachyos-lts 6.18.31-1`
  (anything ≥ 6.10 with `CONFIG_ACPI_TABLE_UPGRADE=y` and
  `CONFIG_ARCH_HAS_ACPI_TABLE_UPGRADE=y` should work)
- **initramfs**: `mkinitcpio 41-x`
- **Bootloader**: `limine 11.x` with `limine-mkinitcpio-hook`
  (other bootloaders work — see the [bootloader notes](#other-bootloaders))

The same patch should apply to any HONOR ZQC-P/M1010 unit regardless of
distro, as long as the kernel supports initrd ACPI table overrides and you
have a way to put the patched SSDT into an *early* (uncompressed) CPIO.

---

## What was wrong

The OEM firmware ships an SSDT named `I2C_DEVT` (the 27th SSDT in the table
list) that declares the real touchpad (`TPD0`) and touchscreen (`TPL1`) under
`\_SB.PC00.I2C1` / `\_SB.PC00.I2C2`. Linux refuses to load this table:

```
ACPI Error: No pointer back to namespace node in package (...) dsargs-301
ACPI Error: AE_AML_INTERNAL, While resolving operands for [Index]  dswexec-433
ACPI Error: Aborting method \_SB.GINF due to previous error (AE_AML_INTERNAL)
ACPI Error: Aborting method \_SB.GNUM due to previous error (AE_AML_INTERNAL)
ACPI Error: Aborting method \                       due to previous error
ACPI Error: AE_AML_INTERNAL, (SSDT:I2C_DEVT) while loading table  tbxfload-189
ACPI Error: 1 table load failures, 30 successful
```

Root cause: the `NFC0` device inside `I2C_DEVT` contains a *module-level*
assignment

```asl
CreateWordField (SBGF, 0x17, INT1)
INT1 = GNUM (0x001A088A)        // ← executed at load time
```

`GNUM` is defined in DSDT and depends on data the kernel hasn't initialised
yet at load time, so the Linux ACPICA interpreter (v20251212) aborts the
entire table. Windows' AML interpreter is more lenient and ignores the
violation, which is why the same firmware "just works" on Windows. With the
table missing, `TPD0`/`TPL1` never enter the ACPI namespace, no I²C-HID
device is enumerated, and neither pointer device exists on Linux.

The fix is small: move that one statement into a `Method (_INI)`, so it is
evaluated *after* the table has finished loading. Everything else is left
intact, including the original `Interrupt(Level, ActiveLow, ExclusiveAndWake)`
resource and GPIO descriptor (`TPDI[0] = 0x001A0894`).

Additionally, the internal keyboard misbehaves on this BIOS until i8042 mux
probing is disabled. Adding `i8042.dumbkbd=1` to the kernel command line
fixes it.

---

## Quick install

```bash
git clone <this-repo> HONOR_ZQC-P_M1010
cd HONOR_ZQC-P_M1010
sudo ./apply_patch.sh
sudo reboot
```

That's it. `apply_patch.sh` is idempotent — running it twice is safe; running
`uninstall_patch.sh` reverts everything (a timestamped backup is created
under `/root/honor-zqcp-fix-backup-*` on each apply).

### What `apply_patch.sh` does

1. Backs up `/etc/mkinitcpio.conf`, `/etc/default/limine`,
   `/boot/limine.conf`, `/etc/initcpio/install/` and `/usr/lib/firmware/acpi/`.
2. Installs `patch/SSDT27_TPD0.aml` → `/usr/lib/firmware/acpi/SSDT27_TPD0.aml`.
3. Installs `patch/acpi_override.install` → `/etc/initcpio/install/acpi_override`.
4. Adds the `acpi_override` hook right after `autodetect` in
   `/etc/mkinitcpio.conf` (only if absent).
5. Appends `i8042.dumbkbd=1` to `KERNEL_CMDLINE[default]` in
   `/etc/default/limine` (only if absent).
6. Runs `limine-update` (falls back to `mkinitcpio -P` if Limine isn't used).

After a reboot, sanity checks:

```bash
sudo dmesg | grep -iE 'I2C_DEVT|override|table upgrade'
#   → ACPI: Table Upgrade: override [SSDT- HONOR-I2C_DEVT]
#   → SSDT 0x... (v02 HONOR  I2C_DEVT 00002000 INTL 20251212)
#   → must NOT contain "AE_AML_INTERNAL"

ls /sys/bus/acpi/devices/ | grep -iE 'TOPS|FTSC'
#   → TOPS0102:00   (touchpad)
#   → FTSC1000:00   (touchscreen)

sudo dmesg | grep -iE 'i2c.hid|hid-multitouch'
#   → I2C HID v1.00 Mouse  [TOPS0102:00 27C6:0F9A] on i2c-TOPS0102:00
#   → I2C HID v1.00 Device [FTSC1000:00 2808:5662] on i2c-FTSC1000:00

cat /proc/cmdline | grep i8042
#   → ... i8042.dumbkbd=1
```

---

## How the patch is built

`patch/SSDT27_TPD0.aml` is regenerated from `patch/SSDT27_TPD0.dsl` with:

```bash
build/build_patch.sh
```

The script

1. Runs `iasl SSDT27_TPD0.dsl` to produce a fresh AML.
2. Patches the OEM-revision field in the AML header from `0x00001000` (the
   OEM value) to `0x00002000` — Linux only swaps an existing SSDT for an
   initrd-provided one when **all** of `signature` / `OEM_ID` /
   `OEM_TABLE_ID` / `OEM_REVISION` match and the override's revision is at
   least the installed one. Bumping the revision by 1 step is the standard
   trick to force the upgrade even when the patched and original tables would
   otherwise tie.
3. Recomputes the ACPI table checksum so the result loads cleanly.

The exact source-level change is in `reference/ssdt27.patch`:

```asl
             CreateWordField (SBGF, 0x17, INT1)
-            INT1 = GNUM (0x001A088A)
+            Method (_INI, 0, NotSerialized)
+            {
+                INT1 = GNUM (0x001A088A)
+            }
```

That is the *only* semantic change. Everything else (every other device,
every other field, every other method) is identical to the OEM SSDT.

---

## Re-deriving the patch on a similar laptop

If you have a different HONOR (or any other) machine where SSDT-load fails
with `AE_AML_INTERNAL`, the same approach should apply:

```bash
# 1. Capture live ACPI tables
sudo build/extract_oem_acpi.sh   # writes ./oem_acpi/*.dat + *.dsl

# 2. Find the SSDT named in the dmesg error line. dmesg will say
#    "(SSDT:<TABLE_ID>) while loading table". Open <TABLE_ID>.dsl and
#    look for a top-level statement that calls a method (anything that's
#    *not* inside a Method (...) {} block). Common culprits are
#    `<field> = <method>(<arg>)` lines inside Device(...) blocks.

# 3. Wrap that statement in `Method (_INI, 0, NotSerialized) { ... }` so
#    it runs after the table has loaded.

# 4. Recompile and bump the OEM revision (see build/build_patch.sh for the
#    exact one-liner).
```

The Windows-side dump under `win11_dump/` is invaluable here: `pnp_full_dump.txt`
shows the *actual* ACPI path and HID for every device, so you can confirm
which BIOS device you're chasing. For example, in our case Linux saw a
`TXNW3643:01` I²C device which turned out to be a MIPI camera template
*reused as a vendor PNP ID*, not the touchpad. The touchpad's real ACPI path
(`\_SB.PC00.I2C1.TPD0`) was only visible in the Windows PnP dump.

---

## Other bootloaders

`apply_patch.sh` writes the kernel cmdline edit to `/etc/default/limine`. If
you use another bootloader, do the same thing in its config:

- **systemd-boot**: edit the `options` line in your
  `/boot/loader/entries/*.conf` to include ` i8042.dumbkbd=1`.
- **GRUB**: append to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`,
  then `sudo grub-mkconfig -o /boot/grub/grub.cfg`.
- **rEFInd**: append to the matching `options` line in `refind.conf`.

The ACPI override side (initramfs hook) is bootloader-agnostic — any setup
that produces an early uncompressed CPIO from `mkinitcpio` will work
(default for all Arch-likes). For non-`mkinitcpio` setups (Ubuntu/Debian
`initramfs-tools`, Fedora/Bazzite `dracut`), you need to use that tool's
equivalent of "early CPIO ACPI override" — see
`Documentation/admin-guide/acpi/initrd_table_override.rst` in the kernel
tree.

---

## Repository layout

```
HONOR_ZQC-P_M1010/
├── README.md                       # this file
├── apply_patch.sh                  # one-shot installer (idempotent)
├── uninstall_patch.sh              # revert installer
├── patch/
│   ├── SSDT27_TPD0.aml             # ready-to-install ACPI override (binary)
│   ├── SSDT27_TPD0.dsl             # human-readable source
│   └── acpi_override.install       # mkinitcpio install hook (early CPIO)
├── build/
│   ├── build_patch.sh              # iasl + checksum recompute + revision bump
│   └── extract_oem_acpi.sh         # dump live ACPI tables for new investigations
├── reference/
│   ├── SSDT27_orig.aml             # untouched OEM SSDT 27 (I2C_DEVT)
│   ├── SSDT27_orig.dsl             # disassembled for diffing
│   └── ssdt27.patch                # exact diff between orig and TPD0 versions
└── win11_dump/                     # the data that made the diagnosis possible
    ├── OEM/                        # full ACPI table dump from Windows
    ├── pnp_full_dump.txt           # Get-PnpDevice + DEVPKEY_* properties
    └── HKEY_LOCAL_MACHINE.reg.zst  # full HKLM export, zstd-compressed
                                    # (~300 MiB → ~12 MiB; decompress with
                                    # `zstd -d HKEY_LOCAL_MACHINE.reg.zst`)
```

---

## Device support matrix

Legend: ✅ works · ⚠️ works partially / driver missing in mainline · ❌ broken
or unavailable · ➖ not applicable / OEM placeholder device

After running `apply_patch.sh` and rebooting, the following has been verified
on `linux-cachyos 7.0.8` (Panther Lake-aware) under CachyOS.

### Core platform

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| CPU — Intel Core Ultra X9 388H (Panther Lake) | `intel_pstate`, `intel_idle`, `coretemp` | Intel Processor | ✅ |
| Integrated GPU — Intel Arc B390 | PCI `8086:b080`, `xe` (modern Xe driver) | Intel Arc Graphics | ✅ |
| Intel NPU (AI accelerator) | PCI `8086:b03e`, `intel_vpu` | Intel AI Boost | ✅ |
| Intel Platform Monitoring Telemetry | PCI `8086:b07d`, `intel_vsec`, `intel_pmc_ssram_telemetry` | Intel PMT | ✅ |
| Intel Innovation Platform Framework (DTT) | PCI `8086:b01d`, `proc_thermal_pci` | Intel Dynamic Tuning | ✅ |
| EDAC memory controller | PCI `8086:b001`, `igen6_edac` | (none) | ✅ |
| LPSS I²C controllers ×3 | PCI `8086:e478/e479/e47a`, `intel-lpss` | Intel Serial IO I²C #0/1/2 | ✅ |
| eSPI / LPC bridge | PCI `8086:e402` | Intel LPC/eSPI E402 | ✅ |
| SMBus controller | PCI `8086:e422`, `i801_smbus` | Intel SMBus E422 | ✅ |
| SPI controller (BIOS flash) | PCI `8086:e423`, `intel-spi` | Intel SPI E423 | ✅ |
| Intel CSE / ME | PCI `8086:e470`, `mei_me` | Intel Management Engine | ✅ |
| TPM 2.0 | ACPI `INTC7002`, `tpm_crb` | Trusted Platform Module 2.0 | ✅ |
| PCH watchdog | ACPI `INTC109D`, `iTCO_wdt` | Intel CWDT | ✅ |

### Storage / power / chassis

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| NVMe SSD — YMTC PC411 (DRAM-less) | PCI `1e49:1071`, `nvme` | Standard NVM Express Controller | ✅ |
| AC adapter | ACPI `ACPI0003`, `ac` | Microsoft AC Adapter | ✅ |
| Battery | ACPI `PNP0C0A`, `battery` (+ `huawei_battery` hook) | Microsoft ACPI-Compliant Control Method Battery | ✅ |
| Lid switch | ACPI `PNP0C0D`, `button` | ACPI Lid | ✅ |
| Power button | ACPI `PNP0C0C`, `button` | ACPI Power Button | ✅ |
| Embedded Controller (EC) | ACPI `PNP0C09`, `acpi_ec` | Microsoft ACPI-Compliant EC | ✅ |

### Networking

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| Wi-Fi — Intel CNVi (Panther Lake) | PCI `8086:e440`, `iwlwifi` | Intel Wi-Fi 7 BE201 / BE211 | ✅ |
| Bluetooth — Intel CNVi | PCI `8086:e476`, `btintel_pcie` | Intel Wireless Bluetooth | ✅ |
| Thunderbolt 4 / USB4 | PCI `8086:e433` + `8086:e462`, `thunderbolt` | Thunderbolt 4 Controller | ✅ |

### USB

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| xHCI controller (TCSS) | PCI `8086:e431`, `xhci_hcd` | Intel USB 3.2 xHCI Controller | ✅ |
| xHCI controller (USB2/3 ports) | PCI `8086:e47d`, `xhci_hcd` | Intel USB 3.2 xHCI Controller | ✅ |
| Built-in webcam — Shinetech FHD | USB `3277:00de`, `uvcvideo` | USB Video Device | ✅ |

### Input

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| **Touchpad — Goodix TOPS0102** | ACPI `\_SB.PC00.I2C1.TPD0` → `i2c-TOPS0102:00`, `i2c_hid_acpi` + `hid-multitouch` (HID `27C6:0F9A`) | `\_SB.PC00.I2C1.TPD0`, `hidi2c.inf` (HID I²C Device) | ✅ *needs this patch* |
| **Touchscreen — FocalTech FTSC1000** | ACPI `\_SB.PC00.I2C2.TPL1` → `i2c-FTSC1000:00`, `i2c_hid_acpi` + `hid-multitouch` (HID `2808:5662`) | `\_SB.PC00.I2C2.TPL1`, `hidi2c.inf` (HID I²C Device) | ✅ *needs this patch* |
| **Built-in keyboard** | ACPI `MSFT0001`/`PNP0303` → `i8042`, "AT Translated Set 2 keyboard" | Microsoft PS/2 Keyboard | ✅ *needs `i8042.dumbkbd=1`* |
| Hotkey / function-key WMI | `huawei_wmi`, "Huawei WMI hotkeys" input | Huawei PC Manager hotkey driver | ✅ |
| PS/2 mouse port (legacy) | ACPI `MSFT0003`, status=0 | (disabled by firmware) | ➖ disabled in firmware (correctly) |
| ACPI Video / brightness | `acpi-video`, "Video Bus" input | Intel Display Control | ✅ |

### Audio

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| HD-Audio + DSP (SOF) | PCI `8086:e428`, `sof-audio-pci-intel-ptl`, card `sofhdadsp` (HDA Analog + 3× HDMI) | Realtek HD Audio + Intel SST | ✅ |
| Speakers / headphone jack | ALSA `sof-hda-dsp Headphone` | (same as above) | ✅ |
| Microphone array (DMIC) | SOF DMIC capture | Intel Smart Sound DMIC | ✅ |

### Sensors / thermal

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| Intel DTT — `IETM` root | ACPI `INTC10D4`, `int3400_thermal` (thermal_zone1) | Intel Dynamic Tuning Technology | ✅ |
| Thermal sensors SEN1..SEN7 | ACPI `INTC10D5`, `int3403_thermal` (thermal_zone2..8) | Intel DTT virtual thermal sensors | ✅ |
| Thermal fan participant TFN1 | ACPI `INTC10D6`, `int3404_fan` | Intel DTT fan | ✅ |
| Battery charge participant | ACPI `INTC10D5` (CHRG) | Intel DTT charger | ✅ |
| CPU package / per-core temp | `coretemp`, `x86_pkg_temp_thermal` (thermal_zone9..12) | hwmon equivalents | ✅ |
| WiFi thermal | `iwlwifi_1` (thermal_zone11) | (vendor private) | ✅ |
| Power-budget participant TPWR | ACPI `INTC10D8`, status=0 | Intel DTT TPWR | ➖ disabled in firmware |
| Battery DTT participant BAT1 | ACPI `INTC10D9`, status=0 | Intel DTT BAT1 | ➖ disabled in firmware |
| Touch-screen enable (TSE) helper | ACPI `INTC10DF` (`\_SB.PC00.TSE_`), status=0 | Intel TSE | ➖ disabled in firmware |

### Bio / NFC / OEM helpers

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| **Fingerprint — Goodix USB** | USB `27c6:6f94`, "Goodix USB2.0 MISC" (no in-tree driver yet) | `oem32.inf` Goodix Biometric (custom MOC driver) | ⚠️ device visible, [needs `libfprint`/`fprintd`](#fingerprint-status) — exact PID may not be supported upstream |
| NFC — NXP NTAG | ACPI `NTAG0001` → `i2c-NTAG0001:00`, no driver bound | `\Driver\SpbNfcDriver` | ❌ no in-tree Linux driver — appears as bare I²C device |
| Microsoft HID button helper (HIDD) | ACPI `INTC10CC`, status=0 | Microsoft HID button collection | ➖ disabled in firmware |
| Intel Acoustic Context Mgr (ACM) | ACPI `INTC1025`, status=null | Intel Acoustic Context Manager | ➖ no `_STA` returned by firmware |

### Reserved / not present

| Component | Linux identifier | Windows identifier | Status |
|---|---|---|---|
| MIPI CSI camera modules (FLM1, F1Mx) | ACPI `\_SB.FLM1`, `_HID="TXNW3643"`, status=15 — but no MIPI sensor connected | (not used; the working webcam is USB) | ➖ template device, no physical sensor on this SKU |
| Other MIPI templates (FLM0/2/3/4/5) | ACPI `TXNW3643`, status=0 | (disabled) | ➖ disabled in firmware |
| INT3472 PMIC clusters (CLP0-5, DSC0-5) | ACPI `INT3472`, status=0 | (disabled) | ➖ disabled — these only matter when a MIPI sensor is wired |

### Fingerprint status

The fingerprint reader is the Goodix USB MOC sensor `27c6:6f94`. Linux sees
the device but won't recognise it for `fprintd`/`libfprint` out of the box;
support for individual Goodix PIDs is added piecewise upstream. To try:

```bash
sudo pacman -S fprintd libfprint
fprintd-enroll
```

If `fprintd-enroll` errors out with "no devices available", `libfprint` does
not yet support this exact PID. The community-maintained `libfprint-tod`
binary blob from Lenovo / HONOR drivers sometimes covers it — but that is
outside the scope of this repo's ACPI fix.

### What this patch does *not* fix

- MIPI / IPU6 internal cameras are not configured (no sensor on this SKU).
- Some OEM helper ACPI devices remain disabled by firmware (`INTC10CC`
  HID Discovery, `INTC10DF` TSE, etc.) — they are not required for any
  user-visible function.
- NFC: the `NTAG0001` controller is on I²C-1 but Linux has no driver for
  it. If you don't use NFC, ignore.

---

## Credits / references

- Linux kernel docs:
  [`Documentation/admin-guide/acpi/initrd_table_override.rst`](https://docs.kernel.org/admin-guide/acpi/initrd_table_override.html)
- ACPI 6.5 spec, §6.4.3.6 *I²C Serial Bus Connection Resource* and §9.18.1.4
  *_DSM Specific Object*
- Microsoft HID-over-I²C protocol spec (UUID
  `3CDFF6F7-4267-4555-AD05-B30A3D8938DE`) — describes the `_DSM` call
  `i2c-hid-acpi` makes to discover the HID descriptor register address.
  Not needed by *this* patch since the OEM SSDT already implements it
  correctly inside `\_SB.PC00.I2C1.TPD0._DSM`.

---

## License

The patch, scripts, and documentation in this repo are released under the
**MIT License**. The contents of `win11_dump/` and `reference/` are
factory-shipped ACPI / registry data extracted from the device; they are
included verbatim for reproducibility and are subject to the original
vendor's terms.
