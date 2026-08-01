# `huawei-wmi` KEY_MICMUTE storm filter — optional, superseded

> **Read [`../micmute/`](../micmute/) first.** The self-toggling microphone was
> tracked down to a kernel HID bug: the touchscreen's vendor-defined collection
> on usage page `0xff01` is mapped to `KEY_MICMUTE` because that page belongs to
> HP's hotkeys, producing a phantom input device stuck at ~30 autorepeats per
> second. Fixing that fixes the symptom.
>
> This filter was built against the earlier, wrong diagnosis. Everything below
> about `_Q14` and WMI event `0x287` is accurate as a description of how the
> **legitimate** Fn+F7 key reaches the kernel; what is not established is that
> the EC ever fires it spuriously. The `atkbd ... code 0xf8` marker counted here
> as evidence of a storm is emitted for real key presses too, including the
> repeated presses made while fighting the flicker.
>
> Keep this installed only if self-toggling survives the HID fix. It is harmless
> in its default PERMISSIVE mode, but it is one more out-of-tree module to
> rebuild after every kernel update.

Mitigated in the driver, on the assumption that the underlying bug is in
HONOR's EC firmware.

## The symptom

The microphone mutes and unmutes on its own, the `platform::micmute` LED
flickers, on-screen notifications repeat, and the mic frequently ends up stuck
muted with Fn+F7 unable to recover it — only unmuting through the desktop's
tray or `pavucontrol` restores it.

Reported independently by another user on a U5 338H variant, so this affects
the model line, not one unit.

## Root cause — confirmed

HONOR's EC firmware raises SCI query `0x14` on its own. The AML is a plain
pass-through:

```asl
Method (_Q14, 0, NotSerialized)
{
    \_SB.WMI1.WMEN = 0x0287       // huawei-wmi keymap -> KEY_MICMUTE
    Notify (\_SB.WMI1, 0xA0)
}
```

The EC also writes the legacy PS/2 scancode `0xf8` to i8042 in parallel. That
scancode is not in the atkbd keymap, so it surfaces in `dmesg` as

```
atkbd serio0: Unknown key pressed (translated set 2, code 0xf8 on isa0060/serio0)
```

which is the cleanest forensic marker for when a storm fires — count it with

```sh
journalctl -b | grep -c 'code 0xf8 on isa0060'
```

**`_Q14` fires for both a legitimate Fn+F7 press and the spurious storm.** The
EC merges them at hardware level before raising the SCI, so there is no in-AML
signal that distinguishes them. Neither an SSDT override of `_Q14` nor a keymap
change can silence the storm without also killing the real key. The only
distinguishing feature is **timing**: a real press is one event, a storm is a
burst of two or more within a second or so.

### Dead ends, so nobody repeats them

- Every setter in the `WMAA` dispatcher was checked. `SMLS` is the only
  mic-related method and it is a one-way OS→EC write of the current mute state.
  There is no "disable mic privacy" or timer-disable method.
- HONOR's own Windows binaries (`HardwareHal.dll`, `OSD_Daemon.exe`,
  `AdvancedService.exe`) contain no such call either — the OSD daemon only
  *receives* the event. The storm happens on Windows too; it is invisible there
  because the fast dispatch path lets the two events self-cancel cleanly.
- The Windows registry hive carries no ACPI mic-privacy configuration.

## The fix

`0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch` adds
a two-mode state machine to `huawei_wmi_process_key()`:

- **PERMISSIVE** (default after boot) — every `0x287` is emitted immediately,
  so a legitimate Fn+F7 press has zero added latency and behaves exactly like
  upstream. A watch timer, re-armed on each event, fires
  `micmute_storm_window_ms` after the most recent one. A single event needs no
  action; a burst of N was already emitted naturally, so the driver emits one
  extra `KEY_MICMUTE` iff N is odd — parity correction gives zero net mute
  change for any burst size — and switches to GUARDED.
- **GUARDED** (for `micmute_storm_cooldown_ms` after a burst) — the first event
  of a window still emits instantly, subsequent ones are counted but dropped,
  and one compensating event is emitted at window expiry if a burst occurred.

After a quiet cooldown the driver returns to PERMISSIVE on its own, so a
storm-free day restores upstream behaviour with no module reload.

```sh
sudo bash patch/micmute/install.sh
# reboot, or: sudo modprobe -r huawei_wmi && sudo modprobe huawei_wmi
```

The installer fetches the running kernel's `huawei-wmi.c` from the upstream
stable tree, applies the patch, builds out-of-tree, and drops the result into
the modules `updates/` overlay. It becomes a no-op if the fix ever lands
upstream. Accepts `KVER=...` to pre-build for an installed-but-not-yet-booted
kernel.

## Runtime tuning

```sh
# widen or narrow the burst-detection window (0 disables the filter entirely)
echo 1500 | sudo tee /sys/module/huawei_wmi/parameters/micmute_storm_window_ms

# how long GUARDED persists after a burst (0 = always PERMISSIVE)
echo 300000 | sudo tee /sys/module/huawei_wmi/parameters/micmute_storm_cooldown_ms
```

Defaults are 2000 ms and 300000 ms (5 minutes). The window was raised from
1000 ms because a 4-event burst at exactly 1.0 s intervals sat right on the
edge and raced the scheduler.

## Limits

Bursts whose events are spaced further apart than the window (an outlier
pattern at 3-6 s intervals was observed once) are indistinguishable from
deliberate human presses by any timing-only filter, and are left alone.

Verifying the fix works: storms remain visible in `dmesg` as `0xf8` lines —
that is the EC, and it does not stop. What should stop is the mute state
flapping and the LED flickering.
