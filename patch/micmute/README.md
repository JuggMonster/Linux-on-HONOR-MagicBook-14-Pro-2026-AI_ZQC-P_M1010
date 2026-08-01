# Microphone mutes itself, mic-mute LED flickers

| | |
|---|---|
| Status | Fixed |
| Cause | Kernel HID bug, not firmware |
| Fix | HID-BPF report-descriptor fixup |
| Survives kernel updates | Yes, nothing to rebuild |

```sh
sudo bash patch/micmute/install.sh
```

## Symptom

The microphone mutes and unmutes on its own, the `platform::micmute` LED
flickers, notifications repeat, and the mic often ends up stuck muted with
Fn+F7 unable to recover it.

It starts only after the SSDT27 override in [`../acpi-override/`](../acpi-override/)
is applied, because that is what makes the I²C touch controllers enumerate.
Reported independently on the sibling FMB-P and on a U5 338H variant.

## Cause

The touchscreen is a FocalTech **FTSC1000**, I²C HID `2808:5662`. Its report
descriptor contains a vendor-defined collection:

```
Usage Page (0xff01)
Usage (0x01)
Collection (Application)
    Report ID (0x10)
    Report Size (8)
    Report Count (0x3b)      59 bytes of raw data
    Usage (0x01)
    Input (Data,Var,Abs)
End Collection
```

Usage page `0xff01` is `HID_UP_HPVENDOR2` in `include/linux/hid.h`, the page HP
uses for hotkey buttons. `drivers/hid/hid-input.c` maps it with no vendor
check:

```c
	case HID_UP_HPVENDOR2:
		set_bit(EV_REP, input->evbit);
		switch (usage->hid & HID_USAGE) {
		case 0x001: map_key_clear(KEY_MICMUTE);		break;
```

Three things compound from there:

| Step | Effect |
|---|---|
| Device matches `MT_CLS_WIN_8`, which sets `export_all_inputs` | `hid-multitouch` does not filter the collection out |
| `HID_QUIRK_INPUT_PER_APP` | the collection gets its own input device, `FTSC1000:00 2808:5662 UNKNOWN`, whose only capability is `KEY_MICMUTE` |
| All 59 bytes carry the same usage, 8 bits wide, logical range 0..255, and the same code path sets `EV_REP` | any non-zero byte is a key press, and one report leaves the key held down and auto-repeating |

### Measured

```
$ cat /proc/bus/input/devices
I: Bus=0018 Vendor=2808 Product=5662 Version=0100
N: Name="FTSC1000:00 2808:5662 UNKNOWN"
H: Handlers=kbd event6
B: KEY=100000000000000 0 0 0        bit 248 only = KEY_MICMUTE

$ sudo evtest /dev/input/event6
12:14:00.736 type=1 code=248 value=2
12:14:00.770 type=1 code=248 value=2
12:14:00.804 type=1 code=248 value=2
```

29 `KEY_MICMUTE` autorepeat events per second, continuously, 8.5 hours into an
uptime, with nobody touching the machine.

- `EVIOCGKEY` confirmed the key was stuck in the pressed state.
- `EVIOCGKEYCODE` confirmed the mapping: `scancode 0xff010001 -> keycode 248`.

Compositors drop most autorepeats, so the mic does not toggle thirty times a
second. What is visible are the press/release edges: each time a vendor report
goes zero → non-zero → zero the mute toggles once, and whichever toggle the
desktop loses to a race leaves the mic muted.

## Fix

`honor-ftsc1000-micmute.bpf.c` is a HID-BPF `rdesc_fixup` program. It walks the
report descriptor before the kernel parses it and applies one rule:

> A hotkey is either a single bit of a button bitmap or an entry of a usage
> array, never a multi-bit variable data field.

That is the same test `hid-input` already uses in its own `unknown:` fallback.
Where a wide variable field is found on page `0xff01`, the usage page item is
rewritten `0xff01 → 0xff00`. `0xff00` is `HID_UP_MSVENDOR`, which `hid-input`
ignores outright, so no input device is created for the collection.

The digitizer collections carry their own usage pages and are untouched.

`install.sh` fetches the kernel's BPF prog headers for the running kernel's
tag, generates `vmlinux.h` from `/sys/kernel/btf/vmlinux`, builds the object
with clang, and installs it through `udev-hid-bpf`:

```
/etc/udev-hid-bpf/honor-ftsc1000-micmute.bpf.o
/etc/udev/rules.d/99-hid-bpf-honor-ftsc1000-micmute.rules
```

The udev rule matches `hid:b0018g0004v00002808p00005662` and loads the program
on device add. The object is CO-RE, so kernel updates need no rebuild.

### Verified after installing

| Check | Result |
|---|---|
| `... UNKNOWN` input device | gone |
| `KEY_MICMUTE` events from HID | zero |
| Touchscreen (`event5`, multitouch + `BTN_TOUCH`) | works |
| Touchpad (`TOPS0102`, also `hid-multitouch`) | works |
| `Huawei WMI hotkeys` keycode 248 | still present, real Fn+F7 unaffected |

The real Fn+F7 arrives over WMI as scancode `0x287 → keycode 248`, never over
HID, so it is on a completely separate path.

### Uninstall

```sh
sudo rm /etc/udev-hid-bpf/honor-ftsc1000-micmute.bpf.o \
        /etc/udev/rules.d/99-hid-bpf-honor-ftsc1000-micmute.rules
sudo udevadm control --reload
reboot
```

## Why HID-BPF and not a kernel patch

The bug is in `hid-input.c`, and the natural fix is to guard the
`HID_UP_HPVENDOR2` case:

```c
	case HID_UP_HPVENDOR2:
		if ((field->flags & HID_MAIN_ITEM_VARIABLE) &&
		    field->report_size != 1)
			goto ignore;
		set_bit(EV_REP, input->evbit);
```

`hid-input.c` is part of `hid.ko`, and CachyOS builds it with `CONFIG_HID=y`, so
it cannot be replaced with a module overlay. Deploying that patch means
rebuilding the kernel package after every update. HID-BPF applies the identical
rule at the descriptor level, needs no rebuild, and is the kernel's own
mechanism for this class of problem.

## Ruled out

| Approach | Why it fails |
|---|---|
| `udev` hwdb `KEYBOARD_KEY_ff010001=reserved` | `hidinput_setkeycode()` remaps only the *first* usage matching a scancode, then re-sets the capability bit because the other 58 still map to 248. Tested live, no change |
| `LIBINPUT_IGNORE_DEVICE` udev rule (used by the FMB-P port) | works for libinput consumers only; the kernel still creates the device, holds the key down and burns ~30 timer wakeups per second |
| Rebuilt `hid-multitouch.ko` refusing to export vendor collections | works, but is the wrong layer and has to be rebuilt after every kernel update |
| SSDT override of `_Q14`, WMI `SMLS`, the `WMAA` dispatcher | all belong to the legitimate Fn+F7 path and have nothing to do with the phantom key |

## Earlier diagnosis, now withdrawn

This was previously attributed to the EC firmware firing WMI event `0x287` on
its own, and mitigated by a storm filter in `huawei-wmi`. The evidence was
bursts of `atkbd ... code 0xf8` in `dmesg`, but that line is emitted for every
genuine Fn+F7 press too, including the repeated presses made while fighting the
flicker, so the count conflated deliberate presses with spurious events. The
`_Q14 → WMI 0x287 → KEY_MICMUTE` chain is real and is how the key works; the EC
was never shown to fire it unprompted. The filter has been removed from this
repository.
