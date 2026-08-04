#!/usr/bin/env bash
# measure-floor.sh — find the lowest PWM duty at which this panel still renders
# evenly, and print the VBT value that corresponds to it.
#
# The panel is dimmed by duty cycling, and OLED emission is badly behaved at
# the bottom of that range: colour shifts, blotches, visible mura. Where that
# starts varies from panel to panel, so the number cannot be copied from
# someone else's unit. This walks the bottom of the range in duty terms and
# waits for you at every step.
#
# Note what the first clean step is, then feed the "vbt min" printed on that
# line to install.sh:
#
#     sudo VBT_MIN=<value> bash install.sh
#
# The original level is restored on every exit path, including Ctrl+C.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

BL=/sys/class/backlight/intel_backlight
[[ -w "$BL/brightness" ]] || { echo "$BL not present" >&2; exit 1; }

MAX=$(< "$BL/max_brightness")
ORIG=$(< "$BL/brightness")

# Hardware floor = scale(vbt_min, 0..255, 0..MAX). Read the real VBT if we can,
# otherwise fall back to the value measured on the reference unit.
MIN_HW=""
DBG=$(ls /sys/kernel/debug/dri/*/i915_vbt 2>/dev/null | head -1 || true)
if [[ -n "$DBG" ]]; then
    TMP=$(mktemp) && trap 'rm -f "$TMP"' EXIT
    if cp "$DBG" "$TMP" 2>/dev/null; then
        RAW=$(python3 "$(dirname "${BASH_SOURCE[0]}")/vbt-min.py" show "$TMP" \
              2>/dev/null | awk '/minimum level/ {split($3, a, "/"); print a[1]}')
        [[ -n "${RAW:-}" ]] && MIN_HW=$(( (RAW * MAX + 127) / 255 ))
    fi
fi
: "${MIN_HW:=17}"

restore() { echo "$ORIG" > "$BL/brightness"; printf '\nrestored to %s\n' "$ORIG"; }
trap 'restore; rm -f "${TMP:-}"' EXIT INT TERM

hw_to_user() { echo $(( ( ($1 - MIN_HW) * MAX + (MAX - MIN_HW) / 2 ) / (MAX - MIN_HW) )); }
hw_to_vbt()  { echo $(( ($1 * 255 + MAX / 2) / MAX )); }

cat <<EOF
max_brightness   $MAX
current level    $ORIG
hardware floor   $MIN_HW/$MAX

Put a flat mid-grey or white window on the screen, dim the room, and press
Enter to walk up from the floor. Stop when the tint and the blotches are gone.

The walk starts at sysfs 1, not 0. Writing 0 does not dim the panel, it turns
the backlight off: intel_backlight_device_update_status() calls
backlight.power(connector, false) whenever props.brightness is 0.
EOF
echo

for hw in 18 20 22 25 28 31 35 39 44 50 56 63 70 79 88; do
    (( hw < MIN_HW )) && continue
    user=$(hw_to_user "$hw")
    # sysfs 0 is not "the lowest level", it switches the panel off:
    # intel_backlight_device_update_status() calls backlight.power(false)
    # whenever props.brightness is 0. Never walk down to it.
    (( user < 1 )) && user=1
    printf 'duty %3d/%d = %5.2f%%   sysfs %3d   vbt min %2d/255  ' \
        "$hw" "$MAX" "$(awk "BEGIN{printf \"%.2f\", $hw*100/$MAX}")" \
        "$user" "$(hw_to_vbt "$hw")"
    echo "$user" > "$BL/brightness"
    read -r _
done
