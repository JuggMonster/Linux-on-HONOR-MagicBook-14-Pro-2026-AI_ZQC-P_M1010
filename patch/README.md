# Fixes for HONOR MagicBook Pro 14 AI (ZQC-P / M1010)

Each subdirectory is one self-contained fix: the patch or source it needs, an
`install.sh`, and a `README.md` explaining what is broken and why the fix looks
the way it does. Every installer is safe to re-run and locates its own files,
so it can be invoked directly from anywhere.

Developed and tested on BIOS 1.09, Core Ultra X9 388H (Panther Lake), CachyOS,
kernel 7.1.5.

## Status

| Area | Status | Fix |
|---|---|---|
| Touchpad, touchscreen, internal keyboard | works | [`acpi-override/`](acpi-override/) — patched SSDT27 plus `i8042.dumbkbd=1`. **Prerequisite for a usable machine** |
| Microphone mutes itself, mic-mute LED flickers | works | [`micmute/`](micmute/) — HID-BPF fixup for the touchscreen's vendor collection |
| Fingerprint reader, Goodix `27c6:6f94` | works | [`fingerprint/`](fingerprint/) — two-line `libfprint` id patch |
| Headset microphone, 3.5 mm jack | works | [`headset-mic/`](headset-mic/) — one-line `SND_PCI_QUIRK` for ALC256 |
| OLED minimum brightness too low, uneven steps | works | [`oled-backlight/`](oled-backlight/) — patched VBT raises the firmware's backlight floor |
| Fan RPM readout | works | [`fan/`](fan/) — `honor-zqcp-hwmon` module |
| Fan control | not available | [`fan/README.md`](fan/README.md) — every OS-side path was tested, the EC ignores all of them |
| SOF DSP suspend/resume panic | preventive | [`sof-audio/`](sof-audio/) — upstream IPC4 backport; the race never reproduced on this unit |
| Fixes reverted by package updates | handled | [`auto-rebuild/`](auto-rebuild/) — pacman hooks that rebuild them automatically |
| Internal keyboard, Caps Lock LED | upstream pending | [`keyboard-atkbd/`](keyboard-atkbd/) — an `atkbd` DMI quirk replaces `i8042.dumbkbd=1` and restores the LED; verified here, needs a kernel rebuild until merged |

## Installing

`apply_patch.sh` in the repository root runs the full sequence, ACPI override,
initramfs, kernel cmdline, then the module-level fixes, and is the intended
entry point for a fresh install. `uninstall_patch.sh` reverts it.

The fingerprint, fan and OLED backlight fixes are independent of the ACPI
override and of each other, so they are not part of that sequence:

```sh
sudo bash patch/fingerprint/install.sh
sudo bash patch/fan/install.sh
sudo bash patch/oled-backlight/measure-floor.sh      # pick the value first
sudo VBT_MIN=<value> bash patch/oled-backlight/install.sh
```

The backlight fix needs a number measured on your own panel, which is why it
is not part of the unattended sequence. See
[`oled-backlight/README.md`](oled-backlight/README.md).

## Surviving updates

With [`auto-rebuild/`](auto-rebuild/) installed, nothing has to be redone by
hand. `apply_patch.sh` installs it as its last step.

| Fix | What an update does | Handled by |
|---|---|---|
| `acpi-override/` | nothing, it is a firmware file | — |
| `micmute/` | nothing, the BPF object is CO-RE | — |
| `oled-backlight/` | nothing on a kernel update; a **BIOS** update invalidates the blob | re-run `install.sh` |
| `fan/` | rebuilt automatically | DKMS |
| `headset-mic/` | a kernel update leaves the new kernel without the overlay | `auto-rebuild/` hook |
| `sof-audio/` | same | `auto-rebuild/` hook |
| `fingerprint/` | a libfprint update replaces the patched package | `auto-rebuild/` hook |

Without the hooks, re-run `headset-mic/install.sh` and `sof-audio/install.sh`
after every kernel update, and `fingerprint/install.sh` after every libfprint
update.

On a rolling distribution you will regularly have a kernel installed but not
yet booted, at which point the running kernel's headers no longer exist and
nothing can build. `fan/`, `headset-mic/` and `sof-audio/` accept a `KVER`
override to pre-build for the installed kernel instead:

```sh
sudo KVER=7.1.5-1-cachyos bash patch/fan/install.sh
```

## Belongs upstream

Two of these are small enough to belong in the projects themselves, and the
repo should shrink as they land:

- the `libfprint` id addition for Goodix `27c6:6f94`
- the `SND_PCI_QUIRK` entry for PCI SSID `1ee7:209d`

The SSDT override is firmware-specific and stays here. The mic-mute fix works
around a real kernel bug in `hid-input.c`, described in
[`micmute/README.md`](micmute/README.md).
