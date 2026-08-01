#!/bin/sh
# Re-apply the HID-BPF mic-mute fixup if the boot-time attach lost a race.
#
# The kernel recomputes the BPF-fixed report descriptor only when
# hdev->bpf_rsize == 0, and only hid_bpf_reconnect() clears it, which runs when
# the program is *registered*:
#
#	int hid_bpf_reconnect(struct hid_device *hdev)
#	{
#		if (!test_and_set_bit(ffs(HID_STAT_REPROBED), &hdev->status)) {
#			hdev->bpf_rsize = 0;
#			return device_reprobe(&hdev->dev);
#		}
#		return 0;
#	}
#
# At boot, udev attaches the program while the device is still being handed
# over from hid-generic to hid-multitouch. HID_STAT_REPROBED is already set by
# that handover, so hid_bpf_reconnect() returns 0 without reprobing, and the
# descriptor is never fixed. The program is attached and does nothing.
#
# Detaching and re-attaching after the device has settled runs the reconnect
# properly. This is a no-op when the boot-time attach won the race.

set -eu

OBJ=/etc/udev-hid-bpf/honor-ftsc1000-micmute.bpf.o
[ -f "$OBJ" ] || exit 0

DEV=""
i=0
while [ $i -lt 30 ]; do
    for d in /sys/bus/hid/devices/*2808:5662*; do
        [ -e "$d" ] && DEV="$d"
    done
    [ -n "$DEV" ] && break
    i=$((i + 1))
    sleep 1
done
[ -n "$DEV" ] || exit 0

phantom() {
    for n in /sys/class/input/input*/name; do
        [ -e "$n" ] || continue
        case "$(cat "$n" 2>/dev/null)" in
            *2808:5662*UNKNOWN*) return 0 ;;
        esac
    done
    return 1
}

if ! phantom; then
    echo "phantom KEY_MICMUTE device absent, fixup already effective"
    exit 0
fi

echo "phantom present, re-applying the fixup to ${DEV##*/}"
udev-hid-bpf remove "$DEV" || true
sleep 1
udev-hid-bpf add "$DEV" "$OBJ" || true
sleep 1

if phantom; then
    echo "still present, the fixup did not take" >&2
    exit 1
fi
echo "phantom removed"
