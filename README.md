# HONOR MagicBook Pro 14 AI (ZQC-P, M1010) — Linux fixes

What this repo fixes on a HONOR MagicBook Pro 14 AI under Linux:

1. **Touchpad and touchscreen** — patched SSDT so the firmware's
   `I2C_DEVT` table loads instead of failing with `AE_AML_INTERNAL`.
2. **Internal keyboard repeats / dropouts** — `i8042.dumbkbd=1` on the
   kernel cmdline.
3. **3.5 mm-jack analog headset microphone** — rebuild of
   `snd-hda-codec-alc269.ko` with a `SND_PCI_QUIRK` entry for our PCI
   subsystem ID `1ee7:209d`, see
   [3.5mm-jack headset microphone](#35mm-jack-headset-microphone).

What works out of the box and is **not** touched by this patch:

- **Fn+F7 mic-mute key + LED** for the built-in microphone array
  (DMIC) — handled by the in-tree `huawei-wmi` driver. See
  [Fn+F7 mic-mute key](#fnf7-mic-mute-key).
- **Built-in microphone array (DMIC)**, speakers, headphone output,
  WebCam, Wi-Fi, Bluetooth.

Known limitations and their causes are documented at the end of each
section.

The cooling system also has unusual default behaviour on Linux —
see [Cooling system / fan behaviour](#cooling-system--fan-behaviour).

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

A separate problem on this hardware is that the 3.5 mm combo jack's
**analog headset microphone** is unusable on stock Linux — the BIOS
reports the codec pin as `NO_PRESENCE` and no `SND_PCI_QUIRK` for our
PCI subsystem ID `1ee7:209d` exists upstream yet. `apply_patch.sh`
ships a rebuild of `snd-hda-codec-alc269.ko` that adds the missing
quirk; see [3.5mm-jack headset microphone](#35mm-jack-headset-microphone)
for what was wrong and what was verified.

And a fourth problem, reported against other Intel Panther Lake
laptops: the **SOF DSP firmware can panic on suspend/resume** under
specific PipeWire / pavucontrol stream-rotation patterns. The IPC4
copier widget's `ipc_config_data` buffer is built once at first
`ipc_prepare` and cached; on resume the host and link DMA channels
are re-allocated with new stream tags, but the widget list persists
across suspend so the cached payload with stale boot-time DMA IDs
is sent to the firmware → ChainDMA collision → DSP panic (`DSP
panic!` + `Core dump is not available due to invalid separator
0xc0de` in `dmesg`). Once the DSP panics, PipeWire's stream
associations are stale and every Fn+F7 press silently fails to
toggle the source mute (the LED stays frozen and audio is dead
until the DSP is reloaded). `apply_patch.sh` ships a rebuild of
`snd-sof.ko` that backports [thesofproject/linux PR #5762] by Peter
Ujfalusi (`sound/soc/sof/ipc4-topology.c`, +33 lines, refreshes the
cached payload right before IPC send); see [SOF DSP suspend/resume
crash](#sof-dsp-suspendresume-crash) for the trigger conditions,
the upstream tracking issue, and how to verify the fix.

This patch is shipped as a **preventive backport**: the upstream
race is real and the kernel fix is correct, but on this particular
HONOR ZQC-P unit a `rtcwake -m mem -s 8` × 3 cycles repro with
pavucontrol open produced **zero** `DSP panic!` entries in `dmesg`
both before and after the backport, and there are no `DSP panic!`
entries across any of the six boots in the local journal either.
So we cannot claim on this hardware that the patch fixes a
reproducible symptom — only that it closes the upstream race
should some application workflow ever trigger it here.

[thesofproject/linux PR #5762]: https://github.com/thesofproject/linux/pull/5762

A fifth, distinct problem turned out to be the **actual** cause of
the user-visible "mic mutes itself and Fn+F7 won't restore it"
symptom that the SOF backport was originally chasing: the HONOR EC
firmware autonomously fires the mic-privacy WMI event 0x287 in
2-event pairs without any user keypress, triggered by combinations
of touchpad swipes, focus changes to audio-playing windows,
`intel_lpmd` platform-profile transitions, and pure idle. The
trigger is opaque EC firmware logic — the full WMAA dispatcher in
`SSDT21` was audited and no "disable privacy timer" setter exists.
HONOR's own Windows PCManager binaries do not call any such setter
either; Windows just handles the storm pairs fast enough that the
two source-mute toggles self-cancel without a visible LED flicker,
whereas on Linux Wayland the userspace dispatch races leave the
mic stuck muted. `apply_patch.sh` ships a small (+63-line)
huawei-wmi.c patch (step [8/8]) that detects the storm pair pattern
at the kernel-driver level and drops both events; see
[EC mic-privacy storm](#ec-mic-privacy-storm-on-wmi-0x287) for the
full AML chain, the runtime-tunable `micmute_storm_window_ms`
module parameter, and verification commands.

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
7. Runs `patch/install-alc269-fix.sh` which fetches the running
   kernel's `alc269.c` from the upstream stable tree, adds our
   `SND_PCI_QUIRK` entry, builds `snd-hda-codec-alc269.ko`
   out-of-tree against the installed kernel headers, and replaces
   `/lib/modules/$(uname -r)/kernel/sound/hda/codecs/realtek/snd-hda-codec-alc269.ko.zst`
   (the original is saved as `/root/snd-hda-codec-alc269.ko.zst.orig`).
   This step is idempotent and re-runs cleanly after every kernel update.
8. Runs `patch/install-sof-ipc4-fix.sh` which fetches the running
   kernel's `sound/soc/sof/` tree from the upstream stable tree,
   applies `patch/0001-ASoC-SOF-ipc4-topology-Refresh-copier-IPC-payload-before-widget-setup.patch`
   ([thesofproject/linux PR #5762]), builds `snd-sof.ko` out-of-tree
   against the installed kernel headers, and drops the rebuild into
   `/lib/modules/$(uname -r)/updates/snd-sof.ko.zst` as an overlay
   (the in-tree module is left untouched and the original is also
   saved as `/root/snd-sof.ko.zst.orig`). This step is idempotent:
   if upstream has already merged the patch it removes the now-
   redundant overlay; if the overlay is already in place it is a
   no-op. It is skipped with a warning if kernel lockdown or
   `module.sig_enforce=1` would block the unsigned overlay.
9. Runs `patch/install-huawei-wmi-fix.sh` which fetches the running
   kernel's `drivers/platform/x86/huawei-wmi.c` from the upstream
   stable tree, applies
   `patch/0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch`
   (a local +63-line storm-detection patch), builds `huawei-wmi.ko`
   out-of-tree against the installed kernel headers, and drops the
   rebuild into `/lib/modules/$(uname -r)/updates/huawei-wmi.ko.zst`
   as an overlay (the in-tree module is left untouched and the
   original is saved as `/root/huawei-wmi.ko.zst.orig`). The new
   module exposes a runtime-tunable `micmute_storm_window_ms`
   parameter (default 1000 ms; 0 disables the filter). Same
   idempotency, lockdown, and sig_enforce handling as step 8.

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

# ALC256 quirk picked up our entry:
sudo dmesg | grep 'picked fixup.*1ee7:209d'
#   → snd_hda_codec_alc269 ehdaudio0D0: ALC256: picked fixup for PCI SSID 1ee7:209d

# Plug a headset into the 3.5mm jack:
pactl list short sources | grep -iv monitor
#   → ...HiFi__Mic1__source    (built-in DMIC array)
#   → ...HiFi__Mic2__source    (analog headset mic — the new one)

# SOF IPC4 fix is active — modinfo resolves to the updates/ overlay,
# not the in-tree module:
modinfo -F filename snd_sof
#   → /lib/modules/.../updates/snd-sof.ko.zst

# After a suspend/resume cycle with pavucontrol open, no DSP panic in
# the kernel log (direct repro from upstream thesofproject/sof#10700):
sudo rtcwake -m mem -s 5     # repeat 2-3 times
journalctl -k -b | grep -iE 'sof.*(panic|crash|exception)'
#   → empty

# huawei-wmi storm-detection is active — overlay loaded and the new
# tunable parameter is exposed:
modinfo -F filename huawei_wmi
#   → /lib/modules/.../updates/huawei-wmi.ko.zst
cat /sys/module/huawei_wmi/parameters/micmute_storm_window_ms
#   → 1000  (write any other value to retune, 0 to disable)
```

---

## Fn+F7 mic-mute key

The key chain itself **works on stock mainline Linux** with no
keymap, hwdb, or systemd plumbing. The `huawei-wmi` driver registers
a separate input device called *"Huawei WMI hotkeys"* which emits
`KEY_MICMUTE` (= `XF86AudioMicMute`) on every press; the desktop's
audio shortcut binding toggles the PipeWire default source mute; the
F7 LED follows via the `audio-micmute` LED trigger that `huawei-wmi`
registers on `/sys/class/leds/platform::micmute`.

What is NOT stable on stock mainline is the **HONOR EC firmware**
itself: it autonomously fires the mic-privacy WMI event (0x287,
`KEY_MICMUTE`) in 2-event pairs without any user keypress —
triggered by touchpad swipes that change focus to an audio-playing
window, by `intel_lpmd` platform-profile transitions, and even
during pure idle. Each pair would normally self-cancel (two
toggles return to the original state), but userspace dispatch
races (Wayland compositor + `gsd-media-keys` grab + audio
backend) lose one of the two toggles and leave the mic stuck
muted, with the platform::micmute LED on and Fn+F7 unable to
restore it. Step [8/8] in `apply_patch.sh` installs a kernel
patch that detects the storm pair pattern and drops both events;
see [EC mic-privacy storm](#ec-mic-privacy-storm-on-wmi-0x287)
for the full root-cause chain and the tunable parameter.

A separate but unrelated issue used to also break this chain: the
SOF DSP firmware on Panther Lake can panic on suspend/resume under
specific PipeWire / pavucontrol stream-rotation patterns, after
which every Fn+F7 press silently fails. Step [7/8] backports the
upstream kernel fix; see
[SOF DSP suspend/resume crash](#sof-dsp-suspendresume-crash). On
this particular HONOR ZQC-P unit the upstream SOF race is not
reproducible (zero `DSP panic!` in journal across all logged
boots), so the SOF backport ships as a defensive preventive only.

Verified on `linux-cachyos 7.0.10-1` with `sof-audio-pci-intel-ptl`,
PipeWire 1.6.6, GNOME 50 Wayland and niri.

**Two gotchas, each with a definite cause:**

1. **`dmesg` prints `atkbd serio0: Unknown key pressed (translated set 2,
   code 0xf8 on isa0060/serio0)` on every Fn+F7 press.** The BIOS
   echoes the key both on the WMI hot-key bus *and* on legacy i8042
   as PS/2 scancode `0xE078`. `atkbd` has no mapping for it. This is
   cosmetic — nothing in the audio stack reads from `atkbd` for
   `KEY_MICMUTE`. Do not add an `hwdb` / `setkeycodes` entry to
   silence it: that creates a second `KEY_MICMUTE` source, the
   desktop toggles the mute twice per press, and Fn+F7 appears
   broken. The legacy `setkeycodes` path is the only one that
   actually takes effect for extended scancodes on current `atkbd` —
   a pure `hwdb` rule is rejected with `-EINVAL` — but neither
   should be applied here. Earlier revisions of this patch shipped
   exactly that mistake; if you have leftover files from them, see
   [Removing an old Fn+F7 keymap fix](#removing-an-old-fnf7-keymap-fix).

   The same `0xf8` line is **also** the forensic marker for the EC
   privacy storm: a legitimate human Fn+F7 press produces ONE
   `code 0xf8` pair (press + release) in the kernel log, whereas
   the EC storm produces TWO pairs within ~1 second. Counting these
   in dmesg (`grep -c 'code 0xf8 on isa0060'`) is how we measured
   the burst rate during the investigation.

2. **The LED follows only the built-in DMIC array's mute, not the
   analog headset mic's mute.** On this hardware the audio chain is
   owned by the SOF DSP; the `audio-micmute` LED trigger is updated
   from the SOF DMIC mute path only. When the analog 3.5 mm headset
   mic (the source added by [section below](#35mm-jack-headset-microphone))
   is selected as default, Fn+F7 still toggles the correct source's
   mute (the desktop notification is right), but the F7 LED does not
   change. Investigated and not fixed at the `alc269.c` quirk-table
   layer — a proper fix needs either modifying
   `sound/hda/codecs/realtek/realtek.c` (broader change with
   ALSA-maintainer review) or adding the equivalent hook on the SOF
   skl_hda_dsp_generic side. Practical workaround until then: keep
   the DMIC as the system default and only switch to the headset mic
   from inside the specific app that needs it (Telegram per-call
   selector etc.). Fn+F7 then keeps toggling the DMIC and the LED
   stays correct, while the app captures from the headset.

### Removing an old Fn+F7 keymap fix

If you installed an earlier revision of this patch (or followed a
similar guide) and now have Fn+F7 toggling twice per press, remove
the leftover keymap files:

```bash
sudo systemctl disable --now honor-fnf7-keymap.service 2>/dev/null
sudo rm -f /etc/systemd/system/honor-fnf7-keymap.service \
           /usr/lib/systemd/system-sleep/honor-fnf7-keymap.sh \
           /etc/udev/hwdb.d/61-keyboard-honor-zqc-p.hwdb
sudo systemctl daemon-reload
sudo systemd-hwdb update
sudo udevadm trigger --subsystem-match=input --action=change
sudo setkeycodes e078 0   # silence the dmesg line for the current boot
```

If you ever write to `/sys/class/leds/platform::micmute/brightness`
manually (e.g. for testing), the kernel detaches the `audio-micmute`
trigger and switches it to `none`. Restore it with:

```bash
echo audio-micmute | sudo tee /sys/class/leds/platform::micmute/trigger
```

A reboot also restores the trigger because `huawei-wmi` re-applies it
on probe.

---

## EC mic-privacy storm on WMI 0x287

The HONOR EC firmware on this laptop autonomously fires the
mic-privacy WMI event 0x287 (`KEY_MICMUTE`) in 2-event pairs without
any user keypress. The "privacy storm" is triggered by various
combinations of:

- touchpad swipe gestures (multi-finger workspace/overview swipes)
  that change focus to a window doing audio playback
- `intel_lpmd` platform-profile transitions (`active` ↔ `low-power`)
- and even pure system idle — bursts fire on no observable input

Measured rate on this unit: **17 bursts in an 80-minute session**;
each burst is exactly two `KEY_MICMUTE` press+release pairs within
~0.5–5 seconds of each other. Each pair would normally self-cancel
(two source-mute toggles return to the original state), but in
practice userspace dispatch races leave the source stuck muted, the
platform::micmute LED on, and the hardware Fn+F7 shortcut unable to
restore it. The user-visible symptom is *"the mic muted itself
without me touching anything, and Fn+F7 no longer un-mutes."*

### Root cause (research notes)

The exact ACPI / WMI path is identical for both a legitimate human
Fn+F7 press and a spurious EC storm event — there is no in-AML
signal that distinguishes them:

```
AML handler in DSDT.dsl:

  Method (_Q14, 0, NotSerialized) {   // EC SCI Query, code 0x14
      \_SB.WMI1.WMEN = 0x0287          // <-- KEY_MICMUTE
      Notify (\_SB.WMI1, 0xA0)
  }

Full chain:

  1. Touchpad swipe gesture + focus change to audio-playing window
                  ↓
  2. HONOR EC firmware (internal privacy logic, NOT modifiable)
                  ↓
  3. EC raises SCI with query code 0x14
                  ↓
  4. AML executes _Q14 (visible in DSDT.dsl line ~25072):
         WMI1.WMEN = 0x0287
         Notify (WMI1, 0xA0)
                  ↓
  5. huawei-wmi driver receives the WMI event
                  ↓
  6. huawei-wmi keymap: { KE_KEY, 0x287, { KEY_MICMUTE } } → emit
     KEY_MICMUTE on the "Huawei WMI hotkeys" input device
                  ↓
  7. gsd-media-keys toggles the source mute → the audio-micmute
     LED trigger follows

Parallel side-effect: the EC also emits the legacy PS/2 scancode
0xf8 on i8042, for which atkbd has no keymap → produces "Unknown
key code 0xf8" in dmesg as the cleanest forensic marker of when
the storm fires.

Burst signature (easy to tell from a human press):

  22:31:18 press  →  22:31:18 release  →  pause ~700 ms
  22:31:19 press  →  22:31:19 release      <-- second pair = storm marker

Real Fn+F7 press = ONE press+release pair.
EC storm        = TWO press+release pairs within 1–1.5 seconds.
```

OEM-level disablement was **investigated and ruled out**: the full
WMAA dispatcher in `SSDT21` (~100 setter/getter methods) was
audited and the only mic-related method is `SMLS` (an OS→EC writer
that sets the current mute state via the `MCON` EC RAM bit); no
"disable privacy timer" setter exists. HONOR's own Windows
PCManager binaries do not call any such setter either — Windows
simply handles the storm fast enough that the 2-event self-cancel
returns mute to the original state without a visible LED flicker.

### The fix

`apply_patch.sh` step [8/8] (= `patch/install-huawei-wmi-fix.sh`)
backports a small (+63-line) patch to
`drivers/platform/x86/huawei-wmi.c` that detects the storm pair
pattern at the driver level:

1. On the first WMI 0x287 the driver defers emission by
   `micmute_storm_window_ms` milliseconds via a `delayed_work`,
   instead of forwarding the `KEY_MICMUTE` immediately.
2. If a second WMI 0x287 arrives during the window, both are
   dropped (the storm pair is silenced — no mute toggle, no LED
   flicker, no userspace dispatch).
3. If no second event arrives, the deferred event is emitted
   normally (legitimate single Fn+F7 press toggles mute with at
   most ~1 s of added latency).

All other WMI events (volume, brightness, wlan, …) keep the upstream
immediate-emit behaviour. The patch file is at
`patch/0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch`.

### Runtime tuning

The storm window is exposed as a writable module parameter and can
be adjusted without a reboot or module reload:

```bash
# current value (1000 ms default):
cat /sys/module/huawei_wmi/parameters/micmute_storm_window_ms

# larger window — catches longer storm gaps but adds more Fn+F7 latency:
echo 1500 | sudo tee /sys/module/huawei_wmi/parameters/micmute_storm_window_ms

# disable the filter entirely — restore upstream immediate-emit behaviour
# (useful for A/B testing or if a future kernel makes the patch obsolete):
echo 0    | sudo tee /sys/module/huawei_wmi/parameters/micmute_storm_window_ms

# also persistable via modprobe.d:
echo 'options huawei-wmi micmute_storm_window_ms=1500' \
   | sudo tee /etc/modprobe.d/honor-zqcp-huawei-wmi.conf
```

The default 1000 ms was chosen because all measured EC storm pairs
on this unit fell within that window, and 1 s of added latency on
the legitimate hardware shortcut is below the typical "press the
button while talking" reaction threshold.

### Verifying after reboot

```bash
# Overlay is picked up by modinfo:
modinfo -F filename huawei_wmi
#   → /lib/modules/.../updates/huawei-wmi.ko.zst

# New parameter is exported:
modinfo -F parm huawei_wmi | grep micmute_storm_window_ms
#   → micmute_storm_window_ms: EC privacy-storm window (ms) ... (int)

# Storm events stay visible in dmesg as the 0xf8 marker, but the
# source mute state and the LED should no longer flap:
sudo dmesg --since '1 hour ago' | grep -c 'code 0xf8 on isa0060'
#   ≥ 0 — count is *expected* to grow; the patch silences the
#   downstream KEY_MICMUTE delivery, not the EC trigger itself

pactl get-source-mute @DEFAULT_SOURCE@
cat /sys/class/leds/platform::micmute/brightness
#   should stay "Mute: no" / 0 across storms when the mic is meant
#   to be active
```

### Rolling back

```bash
sudo rm /lib/modules/$(uname -r)/updates/huawei-wmi.ko.zst
sudo depmod -a
sudo reboot
```

The in-tree (unpatched) module is restored as the resolved
candidate. The original is also kept at
`/root/huawei-wmi.ko.zst.orig` for byte-for-byte restore if desired.
After rolling back the storm will resume — there is no upstream
firmware fix from HONOR at the time of writing and the EC trigger
is not exposed via any documented ACPI/WMI ABI.

---

## SOF DSP suspend/resume crash

On Intel Panther Lake, the SOF DSP firmware is reported to panic on
a suspend/resume cycle under specific PipeWire / pavucontrol stream-
rotation patterns. The panic shows up in `dmesg` as `DSP panic!`
followed by `Core dump is not available due to invalid separator
0xc0de` and a series of `ipc4_tx_msg_unlocked: ... failed: -19`
lines. After such a panic, Fn+F7 still emits `KEY_MICMUTE` (the
input chain is fine) but PipeWire cannot route the toggle through
the dead DSP — the source stays silently un-toggled and the F7 LED
stays in whichever state it was in. Cold-booting the DSP via the
kernel's auto-recovery path (every ~5 s) returns it to
`NOT_STARTED(0)`, where it boots again and may re-panic on the next
stream open.

**Reproducibility note for this specific hardware.** The honor-fnf7-
watch logger writes a `[SOF] fw_state CHANGED` line for *every*
state transition it polls from `/sys/kernel/debug/sof/fw_state`, and
in practice many of those transitions are part of the runtime PM
D3 cycle (kernel temporarily flips state to `CRASHED(7)` when an
IPC is dropped during D3 entry, then `auto-recovers` to
`NOT_STARTED(0)`). They are **not the same** as the
firmware-reported `DSP panic!` from upstream
[thesofproject/sof#10700]: that one is an actual exception inside
the DSP that gets dumped to `dmesg`. On this HONOR ZQC-P unit, six
boots of journal history contain **zero** `DSP panic!` entries, and
a `pavucontrol`-plus-`rtcwake -m mem -s 8` × 3 repro produces zero
panics both with and without the kernel patch installed. Treat the
fix below as a **preventive backport** of a real upstream race,
not as a known-reproducible cure for a symptom on this exact
laptop.

### Root cause

The `ipc_config_data` buffer for IPC4 copier widgets is built once
during `ipc_prepare` (called from `sof_pcm_setup_connected_widgets`)
and cached for reuse. For host copiers the buffer contains
`copier_data` with `gtw_cfg.node_id` (host DMA ID); for DAI copiers
it additionally includes a `dma_config_tlv` trailer with
`stream_id` and `dma_channel_id` for HDA link DMA.

On suspend/resume both host and link DMA streams are released and
re-allocated with potentially different stream tags. The underlying
`copier_data` and `dma_config_tlv` structures *are* updated by
`host_config` and `sdw_hda_dai_hw_params`, but because the widget
list (`spcm->stream[].list`) persists across suspend,
`sof_pcm_hw_params` skips `sof_pcm_setup_connected_widgets` and
`ipc_prepare` never runs again to rebuild `ipc_config_data`. The
stale cached payload with the boot-time DMA channel assignments
is then sent to firmware → DMA channel conflict → DSP panic.

Upstream tracking: [thesofproject/sof#10700] (Dell XPS 14 DA14260,
Panther Lake — same crash signature).

### The fix

[thesofproject/linux PR #5762] by Peter Ujfalusi (`@ujfalusi`, SOF
maintainer at Intel/Linaro) adds 33 lines to
`sound/soc/sof/ipc4-topology.c`'s `sof_ipc4_widget_setup()`. Inside
the `aif_in/aif_out/buffer` (host copier) and `dai_in/dai_out` (DAI
copier) cases the patch refreshes the `copier_data` and (for DAI
copiers) `dma_config_tlv` portions of the cached `ipc_config_data`
right before the IPC message is sent. After the fix the payload
always reflects the current DMA state regardless of whether
`ipc_prepare` ran on this cycle.

`apply_patch.sh` step [7/7] (= `patch/install-sof-ipc4-fix.sh`) does
the backport against the running kernel:

1. Refuses to run if `/sys/kernel/security/lockdown` is anything but
   `[none]` or if `module.sig_enforce=1` is in `/proc/cmdline` —
   unsigned modules wouldn't load.
2. Fetches `sound/soc/sof/ipc4-topology.c` at the running kernel's
   tag from the [gregkh stable-tree mirror][stable-tree] and greps
   for the patch's distinctive comment text. If present, upstream
   has already merged the fix into this kernel: the script removes
   any prior overlay it had installed, `depmod -a`, and exits.
3. Otherwise fetches the rest of `sound/soc/sof/*.{c,h,Makefile}`
   plus a handful of cross-tree headers from `sound/soc/intel/common/`
   that `sof-acpi-dev.c` `#includes`. Subdirectory descents (intel/,
   amd/, imx/, mediatek/, xtensa/) are stripped from the Makefile so
   the build does not cascade into platform-specific modules.
4. Applies the patch with `patch -p3` and stages the patched tree
   into `/lib/modules/$(uname -r)/build/sound/soc/sof/` (the kernel
   headers package only ships `Kconfig` + per-platform subdirs there
   on Arch / CachyOS).
5. Builds `snd-sof.ko` out-of-tree with `LLVM=1 LLVM_IAS=1` (the
   matching toolchain CachyOS uses) and `M=sound/soc/sof modules`.
6. Sanity-checks that the rebuilt module's `srcversion` differs from
   the in-tree one — if not, the patch did not actually change the
   compiled output and the script bails out.
7. zstd-compresses and installs the rebuild to
   `/lib/modules/$(uname -r)/updates/snd-sof.ko.zst` (the `updates/`
   overlay takes precedence over `kernel/sound/soc/sof/` after
   `depmod -a`). The original is also saved to
   `/root/snd-sof.ko.zst.orig` (one-time backup).

The overlay is ~1.9 MB vs the in-tree 197 KB. The size difference
is **not** a bug: CachyOS rebuilds kernel modules with LTO + AutoFDO
+ Propeller (the "Cachy Sauce") which compresses much better; our
out-of-tree build uses the same `LLVM=1` toolchain but without those
cross-module optimisations. Functionally the two modules are
identical; the perf hit (if any) on the audio I/O path is not
measurable.

### Verifying after reboot

```bash
# Overlay is picked up by modinfo:
modinfo -F filename snd_sof
#   → /lib/modules/.../updates/snd-sof.ko.zst

# srcversion differs from the in-tree module:
modinfo -F srcversion snd_sof
diff <(modinfo -F srcversion /lib/modules/$(uname -r)/updates/snd-sof.ko.zst) \
     <(modinfo -F srcversion /lib/modules/$(uname -r)/kernel/sound/soc/sof/snd-sof.ko.zst)
#   → the two srcversions must differ

# Direct repro from upstream issue #10700 — should produce NO DSP
# panic after the patch is loaded:
pavucontrol &                # leave it open
sudo rtcwake -m mem -s 5     # repeat 2-3 times
journalctl -k -b | grep -iE 'sof.*(panic|crash|exception|fw_state)'
#   → no `DSP panic`, no `fw_state: SOF_FW_CRASHED`
```

**Do not** use `grep -c 'CRASHED' /var/log/honor-fnf7-watch.log` as
the validation metric. That counter conflates real firmware panics
with benign runtime PM transitions and was the source of the
"~30/day" baseline we initially (incorrectly) attributed to this
patch. The reliable metric is the journal one above:

```bash
# Real firmware panics only — should stay at 0 on this hardware
# both with and without the patch (so the patch is preventive, not
# corrective, on this specific unit):
journalctl -b 0 -k | grep -c 'DSP panic'
```

### Rolling back

```bash
sudo rm /lib/modules/$(uname -r)/updates/snd-sof.ko.zst
sudo depmod -a
sudo reboot
```

The in-tree module is restored as the resolved candidate. The
original is also kept at `/root/snd-sof.ko.zst.orig` for byte-for-byte
restore if desired.

[thesofproject/sof#10700]: https://github.com/thesofproject/sof/issues/10700
[stable-tree]: https://github.com/gregkh/linux

---

## 3.5mm-jack headset microphone

**Symptom on stock mainline Linux:** plugging a 3.5 mm CTIA headset
into the combo jack — headphone output works, microphone is not
exposed. Only the built-in `HiFi__Mic1__source` (DMIC array) appears
in PipeWire; the codec analog capture device `pcm0c HDA Analog` exists
but captures silence.

**Cause:** the Realtek ALC256 codec on this board has PCI subsystem ID
`1ee7:209d`, which is **not** in the `SND_PCI_QUIRK` table in
`sound/hda/codecs/realtek/alc269.c`. With no quirk applied, the BIOS
default pin configs `0x411111f0` ("Speaker at Ext Rear, NO_PRESENCE")
on nodes 0x18 / 0x19 / 0x1a / 0x1b are taken at face value, codec
autoconfig finds zero input pins, and no analog mic input is wired
into the SOF DSP capture topology.

**Sibling HONOR boards with the same ALC256 codec are already in the
quirk table** — `1ee7:2078` (BRB-X M1010) and `1ee7:2081` (MRB-XXX
M1020). Ours, `1ee7:209d` (ZQC-P), is not. The hardware itself is
analogous: pin 0x19 is wired to the headset mic.

**Why the BRB-X-style one-line `ALC2XX_FIXUP_HEADSET_MIC` isn't
enough on this board.** That fixup uses pincfg `0x03a1103c`
(`JACK_DETECT_OVERRIDE=0`) and only handles `HDA_FIXUP_ACT_PRE_PROBE`.
Verified on hardware: with that simpler fixup, pin 0x19's
`GET_PIN_SENSE` returns 0 immediately after every cold boot, warm
reboot and S3/S4 resume; the SOF DSP analog capture path is never
activated; `arecord -D plughw:0,0` records silence — until the user
physically unplugs and replugs the headset, which fires the codec's
unsolicited jack event and gets things going. The ZQC-P PCB's
impedance-detect circuit on pin 0x19 is unreliable across reset
cycles.

**The shipped fix.** A new fixup `ALC256_FIXUP_HONOR_ZQC_P_M1010_MIC`
that:

1. sets pin 0x19 to pincfg `0x01a1913c` (`JACK_DETECT_OVERRIDE=1` —
   treat as always-present, bypass the unreliable impedance circuit),
2. chains to the existing `ALC269_FIXUP_HEADSET_MODE_NO_HP_MIC` so
   that the full `alc_fixup_headset_mode_no_hp_mic` lifecycle runs at
   PRE_PROBE, PROBE *and* INIT (including S3/S4 resume), wiring the
   analog mic path through `alc_probe_headset_mode` and
   `alc_update_headset_mode`.

The upstream-ready patch is `patch/alc269-honor-zqc-p-m1010.patch`.
The runtime applier `patch/install-alc269-fix.sh` reproduces it
against the running kernel's own `alc269.c` and rebuilds the codec
module out-of-tree against `linux-*-headers`. It is invoked from step
6 of `apply_patch.sh` and is re-runnable after every kernel update;
it no-ops once the upstream patch has actually landed.

**Verified on hardware:**

```text
# pin sense is "always present" immediately after module load,
# no unplug/replug needed:
$ hda-verb /dev/snd/hwC0D0 0x19 GET_PIN_SENSE 0x00
nid = 0x19, verb = 0xf09, param = 0x00
value = 0x80000000

# new HDA analog capture device:
$ ls /proc/asound/card0/pcm*c
pcm0c   # HDA Analog (* new *)
pcm6c   # DMIC Raw

# PipeWire exposes a second mic source:
$ pactl list short sources | grep -v monitor
... HiFi__Mic1__source   s32le 4ch 48000Hz   # DMIC array
... HiFi__Mic2__source   s32le 2ch 48000Hz   # analog headset mic

# voice capture at +10dB Headset Mic Boost, Capture Volume 50/63:
$ arecord -D plughw:0,0 -d 4 -f S16_LE -r 48000 -c 2 voice.wav
$ python3 -c "import wave,struct; \
    w = wave.open('voice.wav','rb'); \
    s = struct.unpack(f'<{w.getnframes()*2}h', w.readframes(w.getnframes())); \
    print(f'abs_max={max(abs(x) for x in s)} RMS={(sum(x*x for x in s)/len(s))**.5:.0f}')"
abs_max=32647 RMS=648    # clean speech, 0% clipping
```

**Known limitations:**

- The F7 LED does **not** follow when the headset mic source is the
  active one. See gotcha #2 in [Fn+F7 mic-mute key](#fnf7-mic-mute-key)
  above.
- The OEM may roll out new firmware revisions that ship a different
  PCI subsystem ID. Re-run `apply_patch.sh` and confirm
  `dmesg | grep 'picked fixup.*1ee7:209d'` still matches your live
  hardware after a firmware update.

---

## Caps Lock LED — known limitation

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
│   ├── acpi_override.install          # mkinitcpio install hook (early CPIO)
│   ├── alc269-honor-zqc-p-m1010.patch # kernel patch: ALC256 quirk for 1ee7:209d
│   ├── install-alc269-fix.sh          # build+install snd-hda-codec-alc269.ko
│   ├── 0001-ASoC-SOF-ipc4-topology-Refresh-copier-IPC-payload-before-widget-setup.patch
│   │                                  # kernel patch: PR #5762 backport
│   ├── install-sof-ipc4-fix.sh        # build+install snd-sof.ko (updates/ overlay)
│   ├── 0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch
│   │                                  # kernel patch: EC privacy-storm filter
│   └── install-huawei-wmi-fix.sh      # build+install huawei-wmi.ko (updates/ overlay)
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
| **Fn+F7 mic-mute key** | `huawei_wmi` WMI hot-key → `KEY_MICMUTE`; LED at `/sys/class/leds/platform::micmute` with `audio-micmute` trigger | Huawei PC Manager mic toggle | ✅ *works out of the box*; LED only follows DMIC mute, not the analog headset mic — see [Fn+F7 mic-mute key](#fnf7-mic-mute-key) |
| PS/2 mouse port (legacy) | ACPI `MSFT0003`, status=0 | (disabled by firmware) | ➖ disabled in firmware (correctly) |
| ACPI Video / brightness | `acpi-video`, "Video Bus" input | Intel Display Control | ✅ |

### Audio

| Component | Linux identifier / driver | Windows identifier / driver | Status |
|---|---|---|---|
| HD-Audio + DSP (SOF) | PCI `8086:e428`, `sof-audio-pci-intel-ptl`, card `sofhdadsp` (HDA Analog + 3× HDMI) | Realtek HD Audio + Intel SST | ✅ *needs this patch* — see [SOF DSP suspend/resume crash](#sof-dsp-suspendresume-crash) (suspend/resume reliability) |
| Fn+F7 mic-mute key | huawei-wmi WMI event `0x287` → `KEY_MICMUTE` on the "Huawei WMI hotkeys" input device | HONOR PCManager + Windows HID built-in | ✅ *needs this patch* — see [EC mic-privacy storm](#ec-mic-privacy-storm-on-wmi-0x287) (filter spurious EC storm pairs) |
| Speakers / headphone jack | ALSA `sof-hda-dsp Headphone` | (same as above) | ✅ |
| Microphone array (DMIC) | SOF DMIC capture, `HiFi__Mic1__source` (4ch) | Intel Smart Sound DMIC | ✅ |
| 3.5mm-jack headset microphone | ALC256 pin 0x19, `HiFi__Mic2__source` (2ch stereo) | Intel SST + Realtek HD Audio | ✅ *needs this patch* — see [3.5mm-jack headset microphone](#35mm-jack-headset-microphone) |

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
