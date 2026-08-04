# HONOR MagicBook Pro 14 AI (ZQC-P, M1010) — Linux fixes

Everything needed to make this laptop usable under Linux: a patched ACPI table,
a HID descriptor fixup, three small kernel/userspace patches, and a fan sensor
module. Each fix lives in its own directory under [`patch/`](patch/) with its
own README, measurements, and installer.

## Status

| Area | State | Fix |
|---|---|---|
| Touchpad, touchscreen, internal keyboard | works | [`patch/acpi-override/`](patch/acpi-override/) — patched SSDT27 plus `i8042.dumbkbd=1`. **Prerequisite for a usable machine** |
| Microphone mutes itself, mic-mute LED flickers | works | [`patch/micmute/`](patch/micmute/) — HID-BPF fixup for the touchscreen's vendor collection |
| Fingerprint reader, Goodix `27c6:6f94` | works | [`patch/fingerprint/`](patch/fingerprint/) — two-line `libfprint` id patch |
| Headset microphone, 3.5 mm jack | works | [`patch/headset-mic/`](patch/headset-mic/) — one-line `SND_PCI_QUIRK` for ALC256 |
| OLED minimum brightness too low, uneven steps | works | [`patch/oled-backlight/`](patch/oled-backlight/) — patched VBT raises the firmware's backlight floor |
| Fan RPM readout | works | [`patch/fan/`](patch/fan/) — `honor-zqcp-hwmon` |
| Fan control | not available | the EC owns the fan curve and ignores every OS-side path, see [`patch/fan/README.md`](patch/fan/README.md) |
| SOF DSP suspend/resume panic | preventive | [`patch/sof-audio/`](patch/sof-audio/) — upstream IPC4 backport, the race never reproduced here |
| Fixes reverted by package updates | handled | [`patch/auto-rebuild/`](patch/auto-rebuild/) — pacman hooks that rebuild them |
| Caps Lock LED | dark | collateral of `i8042.dumbkbd=1`; an upstream `atkbd` quirk removes both, see [`patch/keyboard-atkbd/`](patch/keyboard-atkbd/) |
| Fn+F7 mic-mute key itself | works out of the box | in-tree `huawei-wmi`, nothing to install |

Speakers, headphone output, the built-in DMIC array, webcam, Wi-Fi and
Bluetooth all work with no changes.

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
| **Panel** | EDO 14.55" OLED, 3120x2080 at 120 Hz, backlight on native PWM at 200 Hz |
| **Touchpad** | Goodix **TOPS0102** on `\_SB.PC00.I2C1.TPD0` (I²C HID, addr `0x5D`) |
| **Touchscreen** | FocalTech **FTSC1000** on `\_SB.PC00.I2C2.TPL1` (I²C HID) |
| **Fingerprint** | Goodix USB `27c6:6f94` — works with a two-line `libfprint` patch, see [`patch/fingerprint/`](patch/fingerprint/) |
| **Webcam (built-in)** | Shinetech FHD over USB (`3277:00de`) — works out of the box |

Both touch devices are advertised in firmware with `_HID/_CID = PNP0C50`
(Microsoft HID-over-I²C), so the in-kernel `i2c-hid-acpi` driver is the
correct binding — there is no need for a vendor-specific driver.

---

## Tested environment

| | |
|---|---|
| OS | CachyOS (Arch-based, rolling) |
| Kernel | `linux-cachyos 7.1.5-1`, earlier work on 7.0.x and `linux-cachyos-lts 6.18.31-1` |
| initramfs | `mkinitcpio 41-x` |
| Bootloader | `limine 11.x` with `limine-mkinitcpio-hook` |
| Desktop | GNOME 50 on Wayland, PipeWire 1.6.6 |

Kernel requirements: `CONFIG_ACPI_TABLE_UPGRADE=y` and
`CONFIG_ARCH_HAS_ACPI_TABLE_UPGRADE=y` for the ACPI override, `CONFIG_HID_BPF=y`
and `CONFIG_DEBUG_INFO_BTF=y` for the mic-mute fixup. Anything from 6.10 on
qualifies. Other bootloaders work, see [Other bootloaders](#other-bootloaders).

The same patches should apply to any HONOR ZQC-P/M1010 unit regardless of
distro, as long as the kernel supports initrd ACPI table overrides and you have
a way to put the patched SSDT into an *early*, uncompressed CPIO.

---

## Installing

```bash
git clone <this-repo> HONOR_ZQC-P_M1010
cd HONOR_ZQC-P_M1010
sudo ./apply_patch.sh
sudo reboot
```

`apply_patch.sh` is idempotent and backs up everything it replaces into a
timestamped directory it prints at the end. `uninstall_patch.sh` reverts it.

The fingerprint, fan and OLED backlight fixes are independent of the ACPI
override and are not part of that sequence:

```bash
sudo bash patch/fingerprint/install.sh
sudo bash patch/fan/install.sh

# the backlight floor has to be measured on your own panel first
sudo bash patch/oled-backlight/measure-floor.sh
sudo VBT_MIN=<value> bash patch/oled-backlight/install.sh
```

### What `apply_patch.sh` does

| Step | Action |
|---|---|
| 1 | Installs `patch/acpi-override/SSDT27_TPD0.aml` into `/usr/lib/firmware/acpi/` |
| 2 | Installs the `acpi_override` mkinitcpio hook into `/etc/initcpio/install/` |
| 3 | Adds `acpi_override` to `HOOKS=` in `/etc/mkinitcpio.conf`, right after `autodetect` |
| 4 | Appends `i8042.dumbkbd=1` to the kernel cmdline in `/etc/default/limine` |
| 5 | Regenerates the initramfs and the bootloader config |
| 6 | Runs `patch/headset-mic/install.sh` — rebuilds `snd-hda-codec-alc269.ko` with the ALC256 quirk for PCI SSID `1ee7:209d` |
| 7 | Runs `patch/sof-audio/install.sh` — builds `snd-sof.ko` with the IPC4 backport into the `updates/` overlay |
| 8 | Runs `patch/micmute/install.sh` — builds and installs the HID-BPF descriptor fixup through `udev-hid-bpf` |
| 9 | Runs `patch/auto-rebuild/install.sh` — installs the pacman hooks that keep steps 6, 7 and the fingerprint patch applied across package updates |

Steps 6 and 7 are skipped with a warning if kernel lockdown or
`module.sig_enforce=1` would block an unsigned module. Step 9 is skipped on
non-pacman systems.

### Verifying after reboot

```bash
# ACPI override loaded, no AE_AML_INTERNAL
sudo dmesg | grep -iE 'I2C_DEVT|table upgrade'

# both touch controllers enumerated
ls /sys/bus/acpi/devices/ | grep -iE 'TOPS|FTSC'
sudo dmesg | grep -iE 'i2c.hid|hid-multitouch'

# keyboard quirk on the cmdline
grep -o 'i8042.dumbkbd=1' /proc/cmdline

# no phantom KEY_MICMUTE device — must print nothing
grep -l UNKNOWN /sys/class/input/input*/name | xargs -r grep -H 2808

# the HID-BPF fixup is loaded
sudo udev-hid-bpf list-loaded

# ALC256 quirk picked up
sudo dmesg | grep 'picked fixup.*1ee7:209d'

# fan RPM readout
sensors | grep -A3 honor_zqcp
```

### Surviving package updates

Both kernel-module fixes install into `/usr/lib/modules/$KVER/updates/`, which
`depmod` searches before `kernel/`, so a package update never overwrites them.
What it does do is produce a *new* kernel that has no `updates/` entry yet. The
pacman hooks from step 9 fill that in automatically, and re-apply the
fingerprint patch after a libfprint update.

Everything else needs nothing: the ACPI override is firmware data, the HID-BPF
object is CO-RE, and the fan module uses DKMS.

Check what happened after an update:

```bash
sudo tail -40 /var/log/honor-zqcp-autorebuild.log
```

Details and the manual fallback are in
[`patch/auto-rebuild/README.md`](patch/auto-rebuild/README.md).

---

## Known limitations

| Limitation | Cause |
|---|---|
| **Caps Lock LED stays dark** | `i8042.dumbkbd=1`, needed for the internal keyboard, also disables atkbd's `SET_LEDS` path, so the keyboard comes up without `EV_LED`. An upstream `atkbd` DMI quirk fixes the keyboard without the parameter and brings the LED back; verified on this unit, waiting to be merged. See [`patch/keyboard-atkbd/`](patch/keyboard-atkbd/) |
| **Fan control is not possible** | the EC owns the fan curve. `SFNS` is gated on an `MFGM` flag no AML path ever sets, and the DPTF `TFN1` cooling device accepts writes that the EC ignores. Both tested, see [`patch/fan/README.md`](patch/fan/README.md) |
| **Mic-mute LED follows the built-in array only** | the kernel's control-LED group tracks `Dmic0 Capture Switch` and lights the LED only when *every* attached control is muted. Mute the 3.5 mm jack input while it is not the default and the LED does not move. The built-in array is the default, so Fn+F7 works normally. See [`patch/headset-mic/README.md`](patch/headset-mic/README.md) |
| **Brightness steps are not perceptually uniform** | the desktop divides `max_brightness` linearly, 20 steps of 5% on this panel, so the first step changes the light output far more than the rest. [`patch/oled-backlight/`](patch/oled-backlight/) removes the worst of it by raising the floor, but a perceptual curve has to come from the desktop, and PowerDevil rejected one by design |
| **The very dim end is not usable** | this OLED does not render its firmware-declared minimum evenly. Raising the floor trades the darkest settings for an even image; there is no setting that gives both |
| **MIPI / IPU6 cameras unconfigured** | no sensor on this SKU |
| **NFC unusable** | the `NTAG0001` controller sits on I²C-1 and Linux has no driver for it |
| **Some OEM helper ACPI devices disabled** | `INTC10CC` HID Discovery, `INTC10DF` TSE and similar are disabled by firmware and are not needed for any user-visible function |

### Recovering the Caps Lock LED

Caps Lock itself works correctly as a modifier; only the LED is dark. If you
want to try getting it back:

1. Reboot. At the Limine menu, press `e` on the kernel entry.
2. In the `cmdline:` line, strip ` i8042.dumbkbd=1`.
3. Boot (F10 or Enter). Plug in an external USB keyboard first as a
   fallback in case the internal one misbehaves.
4. Use the internal keyboard for a few minutes. If you see no key
   repeats, no dropouts, and Caps Lock LED works — the quirk is no
   longer needed on your firmware revision; remove the parameter from
   `/etc/default/limine` permanently. If you do see misbehaviour, try
   replacing `i8042.dumbkbd=1` with `i8042.nomux=1` (a softer quirk
   that disables only mux probing, leaving the LED path intact). If
   neither works, keep `i8042.dumbkbd=1` — Caps Lock LED stays as
   collateral damage of the keyboard fix.

There is no EC-side Caps Lock LED field in this BIOS (none of `CAPL`,
`CAPS`, `CapsLed`, `KBLE` appear in the disassembled DSDT), so the LED
is keyboard-internal and only the PS/2 `SET_LEDS` command can drive it.

---

## Cooling and fan behaviour

The fans work, but they engage far later than they do on Windows with HONOR PC
Manager. This is EC firmware behaviour and is not something this repo fixes.

| EC-CPU temp | fan 0 | fan 1 | |
|---|---|---|---|
| 49 °C, idle from a cold boot | 0 | 0 | genuinely stopped |
| 51-68 °C | 0 | 0 | still stopped, load already ramping |
| **72 °C** | **2355** | **1913** | **engagement point** |
| 84 °C | 2455 | 2373 | |
| 89 °C | 3656 | 3276 | clearly audible |

Two things surprise people: the fans are completely off at idle, and there is a
long spin-down hysteresis, so a non-zero reading at low temperature usually
means "recently under load" rather than "idle speed".

RPM readout is solved by `honor-zqcp-hwmon`. Control is not available. The full
measurements, the EC register map, and every control path that was tested and
failed are in [`patch/fan/README.md`](patch/fan/README.md).

---

## How the patch is built

`patch/acpi-override/SSDT27_TPD0.aml` is regenerated from `patch/acpi-override/SSDT27_TPD0.dsl` with:

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
├── patch/                          # one self-contained directory per fix
│   ├── README.md                   # index + status table
│   ├── acpi-override/              # patched SSDT27 — touchpad, touchscreen, keyboard
│   │   ├── SSDT27_TPD0.aml         #   ready-to-install ACPI override (binary)
│   │   ├── SSDT27_TPD0.dsl         #   human-readable source
│   │   └── acpi_override.install   #   mkinitcpio install hook (early CPIO)
│   ├── keyboard-atkbd/             # upstream quirk, reference only, needs a kernel rebuild
│   │   ├── 0001-Input-atkbd-skip-deactivate-for-HONOR-ZQC-P.patch
│   │   └── README.md
│   ├── auto-rebuild/               # pacman hooks: keep fixes applied across updates
│   │   ├── rebuild.sh              #   dispatcher, installed to /usr/local/lib/honor-zqcp/
│   │   ├── 95-honor-zqcp-kernel-modules.hook
│   │   ├── 96-honor-zqcp-libfprint.hook
│   │   └── install.sh
│   ├── oled-backlight/             # firmware backlight floor is too low for this panel
│   │   ├── vbt-min.py              #   inspect / patch brightness_min_level in a VBT
│   │   ├── measure-floor.sh        #   find the lowest duty the panel renders evenly
│   │   ├── install.sh              #   extract, patch, initramfs + cmdline
│   │   └── uninstall.sh
│   ├── micmute/                    # phantom KEY_MICMUTE from the touchscreen
│   │   ├── honor-ftsc1000-micmute.bpf.c     # HID-BPF descriptor fixup
│   │   └── install.sh              #   build + install via udev-hid-bpf
│   ├── headset-mic/                # ALC256 quirk for PCI SSID 1ee7:209d
│   │   ├── alc269-honor-zqc-p-m1010.patch
│   │   └── install.sh              #   build+install snd-hda-codec-alc269.ko
│   ├── sof-audio/                  # preventive IPC4 backport (PR #5762)
│   │   ├── 0001-ASoC-SOF-ipc4-topology-Refresh-copier-IPC-payload-before-widget-setup.patch
│   │   └── install.sh              #   build+install snd-sof.ko (updates/ overlay)
│   ├── fingerprint/                # Goodix 27c6:6f94 in libfprint
│   │   ├── libfprint-goodixmoc-honor-zqc-p-6f94.patch
│   │   ├── PKGBUILD                #   pacman-owned rebuild, avoids file conflicts
│   │   └── install.sh
│   └── fan/                        # honor-zqcp-hwmon — EC fan tachometers (read-only)
│       ├── honor-zqcp-hwmon.c
│       ├── Makefile / dkms.conf
│       └── install.sh
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

Every subdirectory of `patch/` also carries its own `README.md` with the
measurements behind the fix and the approaches that were ruled out.

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
| Internal panel — EDO 14.55" OLED, 3120x2080 120 Hz | eDP-1, `intel_backlight` (native PWM, 200 Hz, `max_brightness` 704) | Intel Arc Graphics | ⚠️ *works, but the VBT declares a 2.4% minimum this panel cannot render evenly — see [`patch/oled-backlight/`](patch/oled-backlight/)* |
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
| Caps Lock LED | (keyboard-internal, driven via atkbd `SET_LEDS`) | (same) | ❌ *blocked by `i8042.dumbkbd=1` — see [Known limitations](#known-limitations)* |
| Hotkey / function-key WMI | `huawei_wmi`, "Huawei WMI hotkeys" input | Huawei PC Manager hotkey driver | ✅ |
| **Fn+F7 mic-mute key** | `huawei_wmi` WMI hot-key → `KEY_MICMUTE`; LED at `/sys/class/leds/platform::micmute` with `audio-micmute` trigger | Huawei PC Manager mic toggle | ✅ *works out of the box*; the LED only follows DMIC mute, not the analog headset mic |
| **Phantom `KEY_MICMUTE`** | `hid-multitouch` exported the FTSC1000 touchscreen's `0xff01` vendor collection, which `hid-input` maps to `KEY_MICMUTE` | none — a FocalTech driver claims the collection | ✅ fixed by [`patch/micmute/`](patch/micmute/); without it the mic mutes itself continuously |
| PS/2 mouse port (legacy) | ACPI `MSFT0003`, status=0 | (disabled by firmware) | ➖ disabled in firmware (correctly) |
| ACPI Video / brightness | `acpi-video`, "Video Bus" input | Intel Display Control | ✅ |

### Audio

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| HD-Audio + DSP (SOF) | PCI `8086:e428`, `sof-audio-pci-intel-ptl`, card `sofhdadsp` (HDA Analog + 3× HDMI) | Realtek HD Audio + Intel SST | ✅ *needs this patch* — see [`patch/sof-audio/`](patch/sof-audio/) (suspend/resume reliability) |
| Phantom `KEY_MICMUTE` | the FTSC1000 touchscreen's `0xff01` vendor collection, which `hid-input` maps to `KEY_MICMUTE` | none, a FocalTech driver claims the collection | ✅ *needs this patch* — see [`patch/micmute/`](patch/micmute/); without it the mic mutes itself |
| Speakers / headphone jack | ALSA `sof-hda-dsp Headphone` | (same as above) | ✅ |
| Microphone array (DMIC) | SOF DMIC capture, `HiFi__Mic1__source` (4ch) | Intel Smart Sound DMIC | ✅ |
| 3.5mm-jack headset microphone | ALC256 pin 0x19, `HiFi__Mic2__source` (2ch stereo) | Intel SST + Realtek HD Audio | ✅ *needs this patch* — see [`patch/headset-mic/`](patch/headset-mic/) |

### Sensors / thermal

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| Intel DTT — `IETM` root | ACPI `INTC10D4`, `int3400_thermal` (thermal_zone1) | Intel Dynamic Tuning Technology | ✅ |
| Thermal sensors SEN1..SEN7 | ACPI `INTC10D5`, `int3403_thermal` (thermal_zone2..8) | Intel DTT virtual thermal sensors | ✅ |
| Thermal fan participant TFN1 | ACPI `INTC10D6`, `int3404_fan` | Intel DTT fan | ✅ |
| **CPU/exhaust fans (physical)** | EC tachometers at ECF0 `0x2C-0x2F` via `honor-zqcp-hwmon`; PWM duty `F0PD`/`F1PD` locked behind `MFGM` | HONOR PC Manager fan control | ⚠️ *RPM readout works; control is impossible from the OS, and the EC only ramps hard above ~85 °C CDTS — see [Cooling and fan behaviour](#cooling-and-fan-behaviour)* |
| Battery charge participant | ACPI `INTC10D5` (CHRG) | Intel DTT charger | ✅ |
| CPU package / per-core temp | `coretemp`, `x86_pkg_temp_thermal` (thermal_zone9..12) | hwmon equivalents | ✅ |
| WiFi thermal | `iwlwifi_1` (thermal_zone11) | (vendor private) | ✅ |
| Power-budget participant TPWR | ACPI `INTC10D8`, status=0 | Intel DTT TPWR | ➖ disabled in firmware |
| Battery DTT participant BAT1 | ACPI `INTC10D9`, status=0 | Intel DTT BAT1 | ➖ disabled in firmware |
| Touch-screen enable (TSE) helper | ACPI `INTC10DF` (`\_SB.PC00.TSE_`), status=0 | Intel TSE | ➖ disabled in firmware |

### Bio / NFC / OEM helpers

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| **Fingerprint — Goodix USB** | USB `27c6:6f94`, "Goodix USB2.0 MISC" → `libfprint` `goodixmoc` driver | `oem32.inf` Goodix Biometric (custom MOC driver) | ✅ works after a [two-line `libfprint` id patch](patch/fingerprint/) |
| NFC — NXP NTAG | ACPI `NTAG0001` → `i2c-NTAG0001:00`, no driver bound | `\Driver\SpbNfcDriver` | ❌ no in-tree Linux driver — appears as bare I²C device |
| Microsoft HID button helper (HIDD) | ACPI `INTC10CC`, status=0 | Microsoft HID button collection | ➖ disabled in firmware |
| Intel Acoustic Context Mgr (ACM) | ACPI `INTC1025`, status=null | Intel Acoustic Context Manager | ➖ no `_STA` returned by firmware |

### Reserved / not present

| Component | Linux identifier | Windows identifier | Status |
|---|---|---|---|
| MIPI CSI camera modules (FLM1, F1Mx) | ACPI `\_SB.FLM1`, `_HID="TXNW3643"`, status=15 — but no MIPI sensor connected | (not used; the working webcam is USB) | ➖ template device, no physical sensor on this SKU |
| Other MIPI templates (FLM0/2/3/4/5) | ACPI `TXNW3643`, status=0 | (disabled) | ➖ disabled in firmware |
| INT3472 PMIC clusters (CLP0-5, DSC0-5) | ACPI `INT3472`, status=0 | (disabled) | ➖ disabled — these only matter when a MIPI sensor is wired |

See [Known limitations](#known-limitations) for what is not fixed.

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
