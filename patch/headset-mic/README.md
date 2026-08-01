# Headset microphone on the 3.5 mm jack — ALC256 quirk

Working: the jack's microphone is captured cleanly.

## The problem

Plugging a headset into the combo jack gives working playback but no capture —
the headset microphone is not exposed at all.

The codec is a Realtek ALC256. Its behaviour on any given laptop depends on a
per-machine quirk table in `sound/pci/hda/patch_realtek.c` (`alc269.c` in the
split-out layout current kernels use), keyed by PCI subsystem id. This unit
reports SSID **`1ee7:209d`**, which has no entry, so the driver falls back to
generic pin defaults that leave the headset mic pin unconfigured.

## The fix

A one-line `SND_PCI_QUIRK` adding `1ee7:209d` with `ALC2XX_FIXUP_HEADSET_MIC`,
the same fixup used by other machines with this pin layout:

```sh
sudo bash patch/headset-mic/install.sh
```

The installer fetches the running kernel's `alc269.c` from the upstream stable
tree, applies the patch, builds the codec module out-of-tree, and installs it
over the in-tree one — backing up the original so `uninstall_patch.sh` can
restore it. It detects an already-present entry and skips the rebuild, so it
becomes a no-op once the quirk lands upstream.

Re-run after every kernel update.

## Verified

Pin `0x19` comes up as the headset microphone and voice was captured cleanly on
the physical device.

## Upstream

This is the most obviously upstreamable change in the repo — a single table
entry, exactly like the hundreds already in that file. It should be submitted
to `alsa-devel`; once merged, drop this directory.

## Default capture source and the mic-mute LED

The quirk sets pin `0x19` to `0x01a1913c`, which includes `JACK_DETECT_OVERRIDE`
because this codec reports no jack presence for that pin. The port is therefore
always "available", and WirePlumber ranked the resulting source above the
built-in microphone array:

| Source | UCM name | `priority.session` |
|---|---|---|
| 3.5 mm jack input | `HiFi__Mic2__source` | 2000 |
| built-in digital array | `HiFi__Mic1__source` | 1648 |

Two things broke as a result:

1. with nothing plugged into the jack, the default recording device was a dead
   analog input;
2. the mic-mute LED stopped following Fn+F7.

The LED failure is worth spelling out, because the obvious fix does not work.
The kernel's control-LED layer (`snd_ctl_led`) drives the `audio-micmute`
trigger that `huawei-wmi` puts on `/sys/class/leds/platform::micmute`. The SOF
machine driver attaches exactly one control to the mic LED group,
`Dmic0 Capture Switch`. Fn+F7 mutes the *default source*, which was the analog
path, so it toggled `Capture Switch` instead and the LED never moved.

Attaching `Capture Switch` to the group as well does **not** help, because
`snd_ctl_led` uses AND semantics:

```c
UPDATE_ROUTE(route, snd_ctl_led_get(lctl));   /* OR of "is unmuted" */
...
led_trigger_event(trig, route ? LED_OFF : LED_ON);
```

The LED lights only when *every* attached control is muted. With both attached,
muting one leaves the other unmuted and the LED stays dark. Verified live.

`51-honor-zqcp-mic-priority.conf` fixes it at the right layer: it lowers the
jack input to `priority.session = 1400`, below the array. The array becomes the
default again, Fn+F7 mutes `Dmic0 Capture Switch`, and the LED follows. The jack
input stays fully usable, applications can still select it.

`install.sh` drops the file into `/etc/wireplumber/wireplumber.conf.d/`,
removes a stale `~/.local/state/wireplumber/default-nodes` (a manually chosen
default outranks the priority rule) and restarts WirePlumber for the invoking
user.

Verify:

```sh
wpctl status | sed -n '/Sources:/,/Filters/p'     # the array must carry the *
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1
cat /sys/class/leds/platform::micmute/brightness  # 1
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
cat /sys/class/leds/platform::micmute/brightness  # 0
```

Known remaining limit: mute the jack input while it is *not* the default and
the LED will not move, for the same AND reason. Nothing in the kernel's
control-LED design covers "whichever mic the desktop is currently using".

## Surviving kernel updates

The rebuilt module is installed as `/usr/lib/modules/$KVER/updates/snd-hda-codec-alc269.ko.zst`,
an overlay `depmod` prefers over the packaged one, so a kernel update never
overwrites it. It does leave the *new* kernel without an overlay, which is what
the pacman hook in [`../auto-rebuild/`](../auto-rebuild/) fills in
automatically. Without that hook, re-run `install.sh` after every kernel
update, or pre-build with `KVER=` for a kernel that is installed but not yet
booted.

Earlier revisions installed the module *over* the packaged one. `install.sh`
detects that, restores the pristine file when the backup matches the kernel,
and switches to the overlay.
