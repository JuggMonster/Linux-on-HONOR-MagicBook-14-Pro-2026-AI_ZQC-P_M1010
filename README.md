# HONOR MagicBook Pro 14 AI (ZQC-P, M1010) — Linux fixes

ACPI override + kernel-cmdline patch that gets the **touchpad** and
**touchscreen** working on a HONOR MagicBook Pro 14 AI under Linux, plus
a small i8042 quirk for the internal keyboard.

The **Fn+F7 microphone-mute key with its LED** works out of the box on
mainline Linux thanks to the `huawei-wmi` driver — no extra setup is
required. See [Mic-mute key (Fn+F7) and its LED](#mic-mute-key-fnf7-and-its-led)
for details.

The cooling system also has unusual default behaviour on Linux — see
[Cooling system / fan behaviour](#cooling-system--fan-behaviour) for what
is normal and what isn't.

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

Additionally, the internal keyboard responds incorrectly to atkbd's
`SET_LEDS` / autorepeat commands on this BIOS, which the kernel interprets
as phantom keypresses ("key repeats / dropouts"). Adding
`i8042.dumbkbd=1` to the kernel command line suppresses all atkbd command
traffic and fixes the misbehaviour — at the cost of the Caps Lock LED no
longer following the kernel's caps-lock state. See [Caps Lock LED
known limitation](#caps-lock-led--known-limitation) for the trade-off.

**Fn+F7 (mic-mute) is *not* in the list of things this patch fixes.** It
works on stock mainline Linux: the `huawei-wmi` driver registers a
separate input device called *"Huawei WMI hotkeys"* and emits
`KEY_MICMUTE` on every Fn+F7 press. PipeWire then toggles the default
source's mute and the LED on the F7 key follows via the `audio-micmute`
trigger. The only visible side-effect is a single line per press in
`dmesg`:

```
atkbd serio0: Unknown key pressed (translated set 2, code 0xf8 on
isa0060/serio0).
```

That comes from the BIOS *also* echoing the key on the legacy i8042
bus, where atkbd doesn't know what to do with scancode `0xE078`. It is
cosmetic noise — the message is harmless and can be ignored. **Don't
"fix" it by mapping `0xE078` to `KEY_MICMUTE` on atkbd**; that creates
a second input source for the same press, GNOME / Mutter then receives
two `KEY_MICMUTE` events per push and toggles the mute twice, making
the key appear non-functional. (Earlier revisions of this patch did
exactly that — the duplicate channel was the source of "Fn+F7
occasionally stops working". If you have those files left over from
older installs, see [Removing an old Fn+F7 keymap fix](#removing-an-old-fnf7-keymap-fix).)

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
   `/boot/limine.conf`, `/etc/initcpio/install/`, and
   `/usr/lib/firmware/acpi/`.
2. Installs `patch/SSDT27_TPD0.aml` → `/usr/lib/firmware/acpi/SSDT27_TPD0.aml`.
3. Installs `patch/acpi_override.install` → `/etc/initcpio/install/acpi_override`.
4. Adds the `acpi_override` hook right after `autodetect` in
   `/etc/mkinitcpio.conf` (only if absent).
5. Appends `i8042.dumbkbd=1` to `KERNEL_CMDLINE[default]` in
   `/etc/default/limine` (only if absent).
6. Rebuilds the bootloader config via `limine-update` (falls back to
   `mkinitcpio -P` if Limine isn't used).

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

# press Fn+F7 once; the F7 microphone icon should light up, mic should
# mute, status should toggle in your audio applet. Then:
cat /sys/class/leds/platform::micmute/trigger
#   → ... [audio-micmute] ...   (square brackets mark active trigger)
```

---

## Mic-mute key (Fn+F7) and its LED

Press Fn+F7: the F7 LED lights up, your default PipeWire source gets
muted; press again: LED off, mic live. The signal path:

```
Fn+F7
 │
 │  WMI hot-key event   (BIOS → ACPI WMI)
 │  ──────────────────────────────────
 │  huawei-wmi sparse keymap (in-kernel)
 │  → KEY_MICMUTE on input device "Huawei WMI hotkeys"
 │
 │  GNOME / KDE / Mutter / KWin grab XF86AudioMicMute
 │  → toggle PipeWire default source mute via pactl/D-Bus
 │
 │  audio stack updates ALSA mixer state
 │  → kernel snd driver calls ledtrig_audio_set(MICMUTE)
 │
 │  led trigger "audio-micmute" attached by huawei-wmi
 │  → /sys/class/leds/platform::micmute/brightness flips
 ▼
LED on the F7 key
```

Everything in this chain is already in mainline kernel and the standard
audio/desktop stack — no patches, hwdb entries, udev rules, or systemd
units are required (verified on `linux-cachyos 7.0.8` with
`sof-audio-pci-intel-ptl`, PipeWire 1.6.5, GNOME 49 Wayland).

**Why the obvious-looking hwdb fix is wrong.** The BIOS additionally
echoes the key as PS/2 scancode `0xE078` on the legacy i8042 bus, which
shows up as `atkbd serio0: Unknown key pressed (translated set 2, code
0xf8)` in dmesg. The textbook reaction is to drop a udev hwdb entry
mapping `0xE078` → `KEY_MICMUTE`. **Don't do that on this laptop.** It
would give you a second input source emitting `KEY_MICMUTE` on top of
the WMI device's event, so each press would toggle the mute twice
(net effect: nothing), making Fn+F7 appear broken. The `dmesg` warning
is cosmetic; the `huawei-wmi` device is the canonical source.

As a side note, the in-tree `atkbd` driver rejects `EVIOCSKEYCODE_V2`
(the ioctl systemd-udev uses to apply hwdb keymaps) with `-EINVAL` for
any extended scancode (`0xE0xx`) as of `linux 7.0.8` / `systemd 260`,
so a hwdb-only mapping wouldn't take effect at all in any case —
only the legacy `setkeycodes` path through `KDSKBENT` works, which
makes the duplicate-channel pitfall easier to fall into.

### Removing an old Fn+F7 keymap fix

If you installed an earlier revision of this patch (or followed a
similar guide) and now have Fn+F7 toggling twice per press, undo the
keymap files:

```bash
sudo systemctl disable --now honor-fnf7-keymap.service 2>/dev/null
sudo rm -f /etc/systemd/system/honor-fnf7-keymap.service \
           /usr/lib/systemd/system-sleep/honor-fnf7-keymap.sh \
           /etc/udev/hwdb.d/61-keyboard-honor-zqc-p.hwdb
sudo systemctl daemon-reload
sudo systemd-hwdb update
sudo udevadm trigger --subsystem-match=input --action=change
# Optional: silence the dmesg "Unknown key" line for the current boot
sudo setkeycodes e078 0
```

After this Fn+F7 will toggle exactly once per press via the
`huawei-wmi` device.

If you ever manually write to `/sys/class/leds/platform::micmute/brightness`
(e.g. for testing), the kernel automatically detaches the
`audio-micmute` trigger and switches it to `none`. Restore it with:

```bash
echo audio-micmute | sudo tee /sys/class/leds/platform::micmute/trigger
```

A reboot also restores it, since `huawei-wmi` hard-codes
`audio-micmute` as the default trigger.

### Caps Lock LED — known limitation

The Caps Lock LED **does not light up** with this patch applied, because
the `i8042.dumbkbd=1` cmdline argument that we add to fix the internal
keyboard's misbehaviour also disables atkbd's `SET_LEDS` command path.
That means the kernel never tells the keyboard about the Caps Lock
state, so the LED stays dark even though Caps Lock itself works
correctly as a modifier.

If you'd like to try recovering the LED, the cleanest experiment is:

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

## Cooling system / fan behaviour

The fans **work** on this machine under Linux, but they engage at a much
higher temperature threshold than they do on Windows + HONOR PC Manager.
This is a property of the EC firmware on the ZQC-P/M1010 and **is not
something this patch fixes** — it's documented here so you know what to
expect.

**What you'll observe under Linux (no HONOR PC Manager):**

- At idle and under light/medium load (CPU package up to ~60 °C), the
  fans are completely silent. The EC keeps them off; you might think
  they don't work at all.
- Under sustained heavy load (compile-from-scratch, ML inference, etc.),
  once CPU package crosses roughly **85 °C** the EC engages the fans
  autonomously. Exhaust fan ramps to ~80 % PWM (audibly loud); intake
  fan follows more conservatively.
- Intel RAPL package power is firmware-capped at **50 W** (not the 88 W
  advertised through the `intel_rapl` constraints) — the cap is
  enforced by the EC via the `VCCC` register, not by Intel RAPL itself.
  Per-core clocks under sustained load settle around 3.3 GHz on average.

**Why it's different from Windows:** HONOR PC Manager runs a userspace
loop that polls temperatures every ~200 ms and writes EC fields
(`SVRF` / `SPPM`) to widen the thermal envelope, so the EC starts
spinning the fans much earlier (~55 °C). Nothing equivalent exists in
mainline `huawei-wmi`, so the EC sticks to its conservative default
profile.

**This is fine for most workloads** and actually quieter than Windows.
But under sustained heavy load you'll hit thermal throttling earlier
because CPU clocks down-step before the fan threshold is reached.

If you want Windows-PC-Manager-like behaviour:

- Install the `acpi_call` kernel module (CachyOS: `paru -S acpi_call`,
  Arch: `pacman -S acpi_call` from the AUR).
- Write a small userspace daemon that polls
  `\_SB.WMI1.WMAA(ABBC0F5B-…, 0, 1, …)` for temperatures every ~500 ms
  and lowers `EC.VCCC` (or raises target temperatures) via the `SVRF`
  method (MFID=0x07, SFID=0x0F) once CPU package exceeds ~55 °C.

The full WMI dispatcher table — including which method ID controls
which EC register, which methods are stubs in this firmware revision,
and which require larger input buffers than `huawei-wmi` can send — was
mapped during the development of this patch. If anyone wants to write
that daemon, the source-of-truth for the ABI is `win11_dump/OEM/SSDT21.dsl`
(method `WMAA`) and `win11_dump/OEM/DSDT.dsl` (the EC `OperationRegion`
definitions and method bodies). The relevant EC field offsets are:

| Field | Region | Offset | What it controls |
|---|---|---|---|
| `VCCC` / `VCCG` / `VCCS` / `VCCL` | ECF6 @ `0xFE0B0600` | 0x20-0x23 | Per-rail power limits, range 1..51 W or 0xFF = unlock. Written by `SVRF`. |
| `PPL4` | ECF6 | 0x24 | Power-limit 4 (peak). Written by `SVRF`. |
| `SCPM` | ECF5 @ `0xFE0B0500` | 0x32 | System CPU Performance Mode. Written by `SPPM`; in this firmware revision it accepts values 0–3 but has no observable effect on PL1 or clocks. |
| `FWMD` | ECF5 | 0x31 | Fan Working Mode. Written by `SFNM`. |
| `FA0L` / `FA1L` | ECF0 @ `0xFE0B0000` | 0x2C / 0x2E | Per-fan **PWM duty 0..255** (this is the actual fan target the EC uses). Written by `SFNS`, but only if `EC.MFGM == 1`. |
| `MFGM` | ECF0 | 0x0F bit 0 | Master manual-fan enable. Not writable from ASL — only the EC firmware sets this. |

`ECF0` (the first 256 bytes of EC RAM) is accessible through the
standard ACPI EC interface: `sudo modprobe ec_sys` then read
`/sys/kernel/debug/ec/ec0/io`. `ECF5` / `ECF6` / `ECF7` are extended EC
banks not reachable through that interface; they need `/dev/mem` mmap
or an ACPI method call (i.e. `acpi_call` or a custom module).

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
├── README.md                          # this file
├── apply_patch.sh                     # one-shot installer (idempotent)
├── uninstall_patch.sh                 # revert installer
├── patch/
│   ├── SSDT27_TPD0.aml                # ready-to-install ACPI override (binary)
│   ├── SSDT27_TPD0.dsl                # human-readable source
│   └── acpi_override.install          # mkinitcpio install hook (early CPIO)
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
| Caps Lock LED | (keyboard-internal, driven via atkbd `SET_LEDS`) | (same) | ❌ *blocked by `i8042.dumbkbd=1` — see [Caps Lock LED](#caps-lock-led--known-limitation)* |
| Hotkey / function-key WMI | `huawei_wmi`, "Huawei WMI hotkeys" input | Huawei PC Manager hotkey driver | ✅ |
| **Fn+F7 mic-mute key + LED** | `huawei_wmi` WMI hot-key → `KEY_MICMUTE`; LED at `/sys/class/leds/platform::micmute` with `audio-micmute` trigger | Huawei PC Manager mic toggle | ✅ *works out of the box* |
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
| **CPU/exhaust fans (physical)** | EC `FA0L`/`FA1L` PWM via HONOR WMI `WMAA` | HONOR PC Manager fan control | ⚠️ *engages only above ~85 °C CDTS — see [Cooling system](#cooling-system--fan-behaviour)* |
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

- **Caps Lock LED** stays dark — the `i8042.dumbkbd=1` quirk that fixes
  the internal keyboard also disables atkbd's `SET_LEDS` path. See
  [Caps Lock LED — known limitation](#caps-lock-led--known-limitation).
- **Early fan engagement** — fans only engage above ~85 °C package
  temp on Linux, as opposed to ~55 °C on Windows + HONOR PC Manager.
  This is an EC firmware policy; see
  [Cooling system / fan behaviour](#cooling-system--fan-behaviour) for
  the explanation and the path to a future userspace daemon.
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
