# Microphone mutes itself, mic-mute LED flickers

**Solved.** It is a kernel HID bug, not the EC, not `huawei-wmi`, and not the
Fn+F7 key. One guard in `hid-multitouch` removes it completely.

```sh
sudo bash patch/micmute/install.sh
```

## The symptom

The microphone mutes and unmutes on its own, the `platform::micmute` LED
flickers, on-screen notifications repeat, and the mic often ends up stuck muted
with Fn+F7 unable to recover it. Reported independently on the sibling FMB-P
(HONOR MagicBook Pro 14, 2025) and on a U5 338H variant, so it affects the model
line rather than one unit.

It only starts after the SSDT27 override in [`../acpi-override/`](../acpi-override/)
is applied, because that is what makes the I²C touch controllers enumerate at all.

## Root cause

The touchscreen is a FocalTech **FTSC1000**, I²C HID `2808:5662`. Besides its
Win8 digitizer collections its report descriptor declares a vendor-defined
application collection:

```
Usage Page (0xff01)
Usage (0x01)
Collection (Application)
    Report ID (0x10)
    Report Size (8)
    Report Count (0x3b)      <- 59 bytes
    Usage (0x01)
    Input (Data,Var,Abs)
End Collection
```

That is a raw firmware/diagnostic data channel. The problem is what usage page
`0xff01` means to Linux. In `include/linux/hid.h`:

```c
#define HID_UP_HPVENDOR2        0xff010000
```

It is the page **HP** uses for its hotkey buttons, and `drivers/hid/hid-input.c`
maps it with no vendor check at all:

```c
	case HID_UP_HPVENDOR2:
		set_bit(EV_REP, input->evbit);
		switch (usage->hid & HID_USAGE) {
		case 0x001: map_key_clear(KEY_MICMUTE);		break;
```

So usage `0xff010001` becomes `KEY_MICMUTE` on a FocalTech touchscreen.

Three things then compound it:

1. The device matches `MT_CLS_WIN_8`, which sets `export_all_inputs`, so
   `hid-multitouch` does not filter the collection out.
2. `HID_QUIRK_INPUT_PER_APP` gives the collection its own input device, the one
   that shows up as `FTSC1000:00 2808:5662 UNKNOWN`. Its **only** capability is
   `KEY_MICMUTE`.
3. All 59 data bytes carry the same usage, and the field is 8 bits wide with a
   logical range of 0..255, so any non-zero byte in a vendor report is a key
   press. Since the same code path also sets `EV_REP`, one such report leaves
   the key **held down and auto-repeating forever**.

### What that looks like on the machine

```
$ cat /proc/bus/input/devices
I: Bus=0018 Vendor=2808 Product=5662 Version=0100
N: Name="FTSC1000:00 2808:5662 UNKNOWN"
H: Handlers=kbd event6
B: KEY=100000000000000 0 0 0        <- bit 248 only = KEY_MICMUTE
```

```
$ sudo evtest /dev/input/event6
12:14:00.736 type=1 code=248 value=2
12:14:00.770 type=1 code=248 value=2
12:14:00.804 type=1 code=248 value=2
...
```

29 `KEY_MICMUTE` autorepeat events per second, continuously, 8.5 hours into an
uptime, with nobody touching the machine. `EVIOCGKEY` confirmed the key was
stuck in the pressed state, and `EVIOCGKEYCODE` confirmed the mapping:

```
scancode 0xff010001 -> keycode 248
```

Compositors ignore most of the autorepeats, which is why the mic does not
toggle 30 times a second. What the user sees is the press/release edges: every
time a vendor report goes zero → non-zero → zero the mute toggles once more,
seemingly at random, and whichever toggle the desktop loses to a race leaves the
mic stuck.

## The fix

`0001-HID-multitouch-do-not-export-vendor-defined-applicat.patch` adds one
guard to `mt_input_mapping()`: never export a vendor-defined application
collection, whatever `export_all_inputs` says. A vendor collection is by
definition not portable input, only the vendor's own driver can interpret it.
The existing Asus custom-media-keys exception is preserved.

`install.sh` fetches `drivers/hid/hid-multitouch.c` for the running kernel's
tag, applies the patch, builds out-of-tree and drops the result into the
modules `updates/` overlay. It becomes a no-op once the change lands upstream.

Effect, verified live:

- the `... UNKNOWN` input device is gone, and with it every phantom event;
- the touchscreen (`event5`, multitouch + `BTN_TOUCH`) still works;
- the touchpad, also driven by `hid-multitouch`, still works;
- `Huawei WMI hotkeys` still lists keycode 248, so the **real Fn+F7 is
  untouched** — it arrives over WMI (`scancode 0x287 → keycode 248`), never
  over HID.

### Fallback without building a module

`99-honor-phantom-micmute.rules` is the workaround used by the FMB-P port: it
sets `LIBINPUT_IGNORE_DEVICE=1` on the phantom node.

```sh
sudo install -m644 patch/micmute/99-honor-phantom-micmute.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

It is strictly weaker. The kernel still creates the device, still holds the key
down and still burns ~30 timer wakeups per second, and anything reading evdev
directly rather than through libinput still sees the events. Use it only where
kernel modules cannot be built or loaded.

### The more general kernel fix

The layering bug is really in `hid-input.c`, which should not turn a 59-byte
data field into a key on the strength of a *vendor* usage page. HP's hotkeys
are single-bit buttons, so this would fix the whole class of device:

```c
	case HID_UP_HPVENDOR2:
		/* vendor page: only HP's single-bit hotkey buttons, not data */
		if (field->report_size != 1)
			goto ignore;
		set_bit(EV_REP, input->evbit);
```

Not shipped here: `hid-input.c` is part of `hid.ko`, so it cannot be swapped in
as cheaply as `hid-multitouch.ko`, and the claim about HP's field width has not
been verified against real HP hardware. It is the better patch to argue for
upstream.

## What this replaces

The earlier diagnosis in this repo blamed the EC: SCI query `_Q14` → WMI event
`0x287` → `KEY_MICMUTE`, mitigated by a storm filter in `huawei-wmi`. That path
is real and is how the *legitimate* Fn+F7 key works, but it was never the source
of the self-toggling. The `atkbd ... code 0xf8` line in `dmesg`, used at the
time as the storm marker, is emitted for genuine key presses too; counting it
conflated deliberate presses (including the ones made while fighting the
flicker) with spurious events.

The `huawei-wmi` filter has been demoted to
[`../micmute-wmi-filter/`](../micmute-wmi-filter/) and is now optional. Install
this fix first and leave it alone; if any self-toggling survives, that one is
still there.

## Ruled out along the way

- Every setter in the `WMAA` WMI dispatcher. `SMLS` is the only mic-related
  method and it is a one-way OS→EC write of the current mute state. There is no
  "disable mic privacy" call.
- An SSDT override of `_Q14`: it cannot distinguish a real Fn+F7 press from
  anything else, because the EC merges them before raising the SCI. Moot now.
- A `udev` hwdb `KEYBOARD_KEY_ff010001=reserved` entry. It looks like the
  obvious fix and it does not work: `hidinput_setkeycode()` remaps only the
  *first* usage matching a scancode, then re-sets the capability bit because the
  other 58 usages still map to 248. Verified — the storm continued unchanged.
- HONOR's Windows binaries (`HardwareHal.dll`, `OSD_Daemon.exe`,
  `AdvancedService.exe`) contain no mic-privacy disable call either. Windows
  never had the bug because it has a FocalTech driver that claims the vendor
  collection instead of handing it to a generic HID mapper.
