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
