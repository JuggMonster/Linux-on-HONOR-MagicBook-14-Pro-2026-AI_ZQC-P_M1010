# Touchpad edge slide, brightness

| | |
|---|---|
| Symptom | sliding along the left edge of the touchpad does nothing under Linux; the right edge changes volume and works |
| Cause | the two edges use different transports, and the left one ends in a HID vendor collection the kernel ignores |
| Fix | HID-BPF, injects a brightness key tap per gesture report |
| Needs | `CONFIG_HID_BPF=y`, `udev-hid-bpf`, no reboot, no daemon |

## The two edges are not symmetric

This took a capture to establish, because it is not what you would guess.

**Right edge, volume.** The touchpad does not report it over HID at all. The
gesture goes to the EC, which emits PS/2 scancodes, and `atkbd` turns them into
key events on the internal keyboard device:

```
 20.537 event2:AT Translated Set 2 keyboard KEY VOLUMEDOWN=1
 20.547 event2:AT Translated Set 2 keyboard KEY VOLUMEDOWN=0
 20.582 event2:AT Translated Set 2 keyboard KEY VOLUMEDOWN=1
 20.592 event2:AT Translated Set 2 keyboard KEY VOLUMEDOWN=0
```

Discrete press and release pairs about 10 ms apart, roughly 22 per second while
the finger moves. Nothing to fix, and worth noting as the reference for what
the hardware considers correct behaviour.

**Left edge, brightness.** Reported over HID, on a vendor collection:

```
Usage Page (Vendor 0xff00)
Usage (0x01)
Collection (Application)
  Report ID (0x0e)
  Report Count (8), Report Size (8)
  Input (Data,Var,Abs)
End Collection
```

```
 39.288 hidraw1 rid=0x0e  0e 03 02 00 00 00 00 00     sliding down
 40.791 hidraw1 rid=0x0e  0e 03 01 00 00 00 00 00     sliding up
```

`0x0e` is the report id, `0x03` marks the edge gesture, and the third byte is
the direction. About 10 reports per second, and the firmware stops reporting
the finger as a contact while the gesture is active, so nothing shows up in the
touchpad's coordinate stream either.

Nothing consumes it, because `drivers/hid/hid-input.c` discards the whole page:

```c
	case HID_UP_MSVENDOR:
		goto ignore;
```

## Why a descriptor fixup is not enough

The obvious move is to rewrite the vendor collection into a consumer one with
`hid_rdesc_fixup` and let `hid-input` do the rest. It does not work.

The firmware sends a stream of identical reports while the finger moves and
**no terminating report** when it stops. For an array field
`hid_input_field()` presses a usage when it appears in a report and releases it
when it disappears; for a variable field the input core swallows repeated
identical values. Either way one gesture produces a single key press that is
never released.

That is the same failure mode as the phantom `KEY_MICMUTE` in
[`../micmute/`](../micmute/), and it is why this fix is a device event hook
rather than a descriptor rewrite.

## What the fix does

`hid_bpf_try_input_report()` is the non-sleepable variant of the report
injection kfunc:

```c
BTF_ID_FLAGS(func, hid_bpf_input_report, KF_SLEEPABLE)
BTF_ID_FLAGS(func, hid_bpf_try_input_report)          /* no KF_SLEEPABLE */
```

```c
/**
 * hid_bpf_try_input_report - Inject a HID report in the kernel from a HID device
 * ...
 * This function will immediately fail if the device is not available, thus can be
 * safely used in IRQ context.
 */
```

So the device event hook can synthesise reports. On each gesture report it
injects a press on the touchpad's **own** consumer collection, which the
firmware already declares wide open:

```
Usage Page (Consumer)
Usage (Consumer Control)
Collection (Application)
  Report ID (0x08)
  Usage Minimum (0x00), Usage Maximum (0x2ff)
  Report Size (16), Report Count (1)
  Input (Data,Array,Abs)
End Collection
```

Usage `0x006f` is Display Brightness Increment and `0x0070` is Decrement, both
mapped by `hid-input` to `KEY_BRIGHTNESSUP` and `KEY_BRIGHTNESSDOWN`. One
gesture report becomes one discrete key tap, matching what the EC does for the
right edge.

### One buffer per device

The subtle part. `dispatch_hid_bpf_device_event()` points the context at a
single per-device buffer and refills it on every dispatch:

```c
	struct hid_bpf_ctx_kern ctx_kern = {
		...
		.data = hdev->bpf.device_data,
	};
	...
	memset(ctx_kern.data, 0, hdev->bpf.allocated_data);
	memcpy(ctx_kern.data, data, *size);
```

An injected report goes through that same path, so it overwrites the buffer the
hook is currently working on. Injecting both halves of the pair and letting the
original report through therefore delivers a third, stray report built from
whatever the last injection left behind.

The program instead injects only the press and rewrites the incoming vendor
report into the release, returning the shorter length. Two reports, in the
right order, nothing left over. Measured before and after:

| | reports per gesture on hidraw |
|---|---|
| inject press and release, pass the original through | `08 6f 00`, `08 00 00`, `08 00 00 00 00 00 00 00` |
| inject press, rewrite the original into the release | `08 6f 00`, `08 00 00` |

The vendor report is consumed rather than forwarded. Nothing in the kernel
wants it, and a userspace tool that wanted to read it from hidraw would not see
it anyway, for the buffer reason above.

## Installing

```sh
sudo bash patch/touchpad-edge/install.sh
```

No reboot. The object is CO-RE, so a kernel update needs nothing.

## Verified on this unit

90 second capture of every input device, both hidraw nodes and the backlight
value, while sliding on both edges:

| | |
|---|---|
| injected presses, `08 6f 00` / `08 70 00` | 93 / 75 |
| injected releases, `08 00 00` | 168 |
| `KEY_BRIGHTNESSUP` / `KEY_BRIGHTNESSDOWN` | 186 / 150 |
| key presses left unreleased | **0** |
| keys still held at the end of the capture | **none** |
| `KEY_VOLUMEUP` / `KEY_VOLUMEDOWN` from the right edge | 86 / 70, unaffected |
| actual backlight changes | 40 |

## Known gaps

**Direction.** `0x01` is up and `0x02` is down. Established two ways: in a
capture with coordinates the `0x02` bursts coincide with the finger moving
toward larger Y, and the daemon in
[issue #7](https://github.com/rs0x29a/Linux-on-HONOR-MagicBook-14-Pro-2026-AI_ZQC-P_M1010/issues/7)
maps them the same way independently.

**The rest of the vendor protocol is unknown.** Only `0x0e 0x03 0x01|0x02` has
ever been observed. The program matches on the report id and the `0x03` marker
at fixed offsets, so any other event on that collection passes through
untouched. A daemon that scans the whole buffer for the byte sequence, by
contrast, also matches those bytes inside the 40 byte touch reports and fires at
random.

**Step rate is the firmware's.** About 10 reports per second while sliding,
against 22 for the EC-driven right edge, so brightness moves at roughly half
the pace volume does. That is what the touchpad sends; nothing here throttles
it.

**Boot-time attach is not proven yet.** The sibling fixup in
[`../micmute/`](../micmute/) needs a service to re-apply itself, because a
descriptor rewrite only takes effect if `hid_bpf_reconnect()` reprobes the
device, and at boot that race is lost. A device event hook has no such
dependency: it only has to be attached. That should make the service
unnecessary here, but it has not been confirmed across a reboot yet. After the
next one, check:

```sh
sudo udev-hid-bpf list-loaded | grep honor_tops0102
```
