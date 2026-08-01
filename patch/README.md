# Fixes for HONOR MagicBook Pro 14 AI (ZQC-P / M1010)

Each subdirectory is one self-contained fix: the patch or source it needs, an
`install.sh`, and a `README.md` explaining what is broken and why the fix looks
the way it does. Every installer is safe to re-run and locates its own files,
so it can be invoked directly from anywhere.

Developed and tested on BIOS 1.09, Core Ultra X9 388H (Panther Lake),
CachyOS, kernel 7.1.5.

| Area | Status | Directory |
|------|--------|-----------|
| Touchpad / touchscreen / internal keyboard | ✅ working | [`acpi-override/`](acpi-override/) — patched SSDT27 + `i8042.dumbkbd=1`; **prerequisite for a usable machine** |
| Fingerprint reader (Goodix `27c6:6f94`) | ✅ working | [`fingerprint/`](fingerprint/) — two-line `libfprint` id patch |
| Headset microphone (3.5 mm jack) | ✅ working | [`headset-mic/`](headset-mic/) — one-line `SND_PCI_QUIRK` for ALC256 |
| Microphone mutes itself, mic-mute LED flickers | ✅ working | [`micmute/`](micmute/) — one guard in `hid-multitouch`; the touchscreen's vendor HID collection was being mapped to `KEY_MICMUTE` |
| ↳ earlier `huawei-wmi` storm filter | ➖ optional | [`micmute-wmi-filter/`](micmute-wmi-filter/) — built against the earlier, wrong diagnosis; keep only if symptoms survive |
| Fan RPM readout | ✅ working | [`fan/`](fan/) — `honor-zqcp-hwmon` hwmon module |
| Fan **control** | ❌ not available | see [`fan/README.md`](fan/README.md); every OS-side path was tested and the EC ignores all of them |
| SOF DSP suspend/resume panic | ➖ preventive | [`sof-audio/`](sof-audio/) — upstream IPC4 backport; the race never reproduced on this unit |

## Applying everything at once

`apply_patch.sh` in the repository root runs the full sequence (ACPI override,
initramfs, kernel cmdline, then the module-level fixes) and is the intended
entry point for a fresh install. `uninstall_patch.sh` reverts it.

The fingerprint and fan fixes are **not** part of that sequence — they are
independent of the ACPI override and of each other, so install them directly:

```sh
sudo bash patch/fingerprint/install.sh
sudo bash patch/fan/install.sh
```

## Kernel updates

The out-of-tree module fixes (`headset-mic/`, `micmute/`, `micmute-wmi-filter/`
and `sof-audio/`) build against the running kernel's headers and must be re-run
after every kernel update. `fan/` uses DKMS when available and rebuilds itself.

On a rolling distribution you will regularly have a kernel installed but not
yet booted, at which point the *running* kernel's headers no longer exist and
nothing can build. `fan/`, `micmute/` and `micmute-wmi-filter/` accept a `KVER`
override to pre-build for the installed kernel instead:

```sh
sudo KVER=7.1.5-1-cachyos bash patch/fan/install.sh
```

## Upstreaming

Three of these are small enough to belong upstream rather than here, and the
repo should shrink as they land:

- the `libfprint` id addition for Goodix `27c6:6f94`
- the `SND_PCI_QUIRK` entry for PCI SSID `1ee7:209d`
- the `hid-multitouch` guard against exporting vendor-defined collections —
  this one is a genuine kernel bug and affects any Win8 touchscreen whose
  firmware uses HID usage page `0xff01`, not just this laptop

The SSDT override is firmware-specific and stays here.
