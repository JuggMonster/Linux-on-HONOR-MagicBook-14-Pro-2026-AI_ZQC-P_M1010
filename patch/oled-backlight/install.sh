#!/usr/bin/env bash
# install.sh — raise the OLED minimum backlight level by feeding the display
# driver a patched VBT.
#
# Background:
#   intel_backlight does not pass the sysfs value to the hardware. i915/xe map
#   the user range [0..max_brightness] onto [pwm_level_min..pwm_level_max], and
#   pwm_level_min comes from the VBT:
#
#       pwm_level_min = scale(vbt.backlight.min_brightness, 0, 255, 0, pwm_max)
#
#   On this machine the VBT declares 6/255, which lands on 17/704 = 2.4% PWM
#   duty. That is the floor the firmware considers acceptable, and this panel
#   does not render it evenly: at that duty the OLED shows a colour cast and
#   visible blotches. "0%" in any desktop environment lands exactly there.
#
#   Raising that one value fixes two things at once. The floor moves up out of
#   the ugly region, and the whole slider is rescaled rather than clipped, so
#   the first brightness step stops tripling the light output (2.41% -> 7.24%
#   at the factory floor).
#
#   The driver takes a VBT from a file when told to, validates the signature
#   and the sizes, and falls back to the firmware's own copy on any failure.
#   Worst case is therefore stock behaviour, not a dark screen.
#
# The blob is extracted from this machine at install time and patched in place.
# Nothing panel-specific is shipped in the repository, because the VBT belongs
# to the BIOS revision of the unit it came from.
#
# Usage:
#   sudo bash install.sh                # uses VBT_MIN below
#   sudo VBT_MIN=20 bash install.sh     # after running measure-floor.sh
#
# Reruns are safe and always patch from the saved factory copy, so changing
# VBT_MIN and re-running does the right thing.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

# 12/255 = 33/704 = 4.69% duty. Measured on the reference unit: 3.55% still
# showed the colour cast and the blotches, 3.98% was clean, so the threshold
# sits between them and this leaves two steps of margin. Panels vary, so run
# measure-floor.sh and override if yours disagrees.
VBT_MIN="${VBT_MIN:-12}"

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW_DIR=/usr/lib/firmware/honor
FW_NAME=zqc-p-vbt.bin
FW_PATH="${FW_DIR}/${FW_NAME}"
FW_PARAM="honor/${FW_NAME}"
STATE_DIR=/var/lib/honor-zqcp
FACTORY="${STATE_DIR}/vbt-factory.bin"
STAMP="${STATE_DIR}/oled-backlight.stamp"
TS=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/honor-zqcp-oled-backlight-backup-${TS}"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. DMI gate --------------------------------------------------------------
VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
BIOS=$(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo "unknown")
if [[ "$VENDOR" != "HONOR" || "$PRODUCT" != "ZQC-P" ]]; then
    die "This machine reports '$VENDOR / $PRODUCT', not 'HONOR / ZQC-P'.
    The panel and its VBT layout are model-specific — refusing to install."
fi
log "DMI matches HONOR ZQC-P, BIOS $BIOS"

[[ "$VBT_MIN" =~ ^[0-9]+$ ]] || die "VBT_MIN must be a number, got '$VBT_MIN'"
(( VBT_MIN >= 1 && VBT_MIN <= 64 )) || \
    die "VBT_MIN must be 1..64 (i915 clamps the VBT minimum to 64/255)"
# The panel's own 4320 Hz dimming only runs at low brightness and is gone
# somewhere around 15% duty, so a high floor trades blotches for 200 Hz
# flicker. See README, "Do not raise the floor too far".
if (( VBT_MIN > 30 )); then
    warn "VBT_MIN ${VBT_MIN}/255 is above the practical ceiling of 30/255:
    past roughly 15% duty the panel drops out of its high frequency dimming
    mode and you are left with the bare 200 Hz PWM. Continuing anyway."
fi

# --- 2. Which driver owns the panel -------------------------------------------
DRV=""
for d in /sys/class/drm/card*/device/driver; do
    [[ -e "$d" ]] || continue
    case "$(basename "$(readlink -f "$d")")" in
        xe)   DRV=xe;   break ;;
        i915) DRV=i915; break ;;
    esac
done
[[ -n "$DRV" ]] || die "neither xe nor i915 is bound to a display device"
log "display driver: $DRV (parameter ${DRV}.vbt_firmware)"

BL=/sys/class/backlight/intel_backlight
if [[ -r "$BL/max_brightness" ]]; then
    log "backlight: max_brightness $(< "$BL/max_brightness"), current $(< "$BL/brightness")"
else
    warn "$BL not found — the fix still installs, but verify it after reboot"
fi

# --- 3. Obtain the factory VBT ------------------------------------------------
mkdir -p "$STATE_DIR" "$BACKUP"

if [[ -f "$FACTORY" ]]; then
    OLD_BIOS=$(sed -n 's/^bios_version=//p' "$STAMP" 2>/dev/null || true)
    if [[ -n "$OLD_BIOS" && "$OLD_BIOS" != "$BIOS" ]]; then
        warn "the saved factory VBT was taken under BIOS $OLD_BIOS, this machine now"
        warn "runs BIOS $BIOS. The blob may be stale. To rebuild it from scratch:"
        warn "    sudo PURGE=1 bash uninstall.sh   # then reboot, then run this again"
    fi
    log "using the saved factory VBT ($FACTORY)"
else
    if grep -q 'vbt_firmware=' /proc/cmdline; then
        die "the kernel is already booted with vbt_firmware= but $FACTORY is missing.
    The VBT exposed through debugfs is the patched one, so extracting it now
    would save a patched blob as the factory copy. Remove the parameter from
    the kernel command line, reboot, and run this again."
    fi

    mountpoint -q /sys/kernel/debug || mount -t debugfs none /sys/kernel/debug || \
        die "cannot mount debugfs, needed to read the VBT"

    VBT_DBG=$(ls /sys/kernel/debug/dri/*/i915_vbt 2>/dev/null | head -1 || true)
    [[ -n "$VBT_DBG" ]] || die "no i915_vbt in debugfs — is CONFIG_DEBUG_FS enabled?"

    cp "$VBT_DBG" "$FACTORY"
    [[ -s "$FACTORY" ]] || die "extracted VBT is empty"
    log "extracted the factory VBT from $VBT_DBG ($(stat -c%s "$FACTORY") bytes)"
fi
cp -a "$FACTORY" "$BACKUP/vbt-factory.bin"

# --- 4. Patch it --------------------------------------------------------------
log "patching brightness_min_level to ${VBT_MIN}/255"
python3 "${SRC_DIR}/vbt-min.py" patch "$FACTORY" "${STATE_DIR}/vbt-patched.bin" "$VBT_MIN" \
    || die "patching failed, nothing was installed"

install -Dm644 "${STATE_DIR}/vbt-patched.bin" "$FW_PATH"
log "installed $FW_PATH"

# --- 5. initramfs -------------------------------------------------------------
# xe.ko is pulled into the initramfs by the kms hook, so request_firmware()
# runs before the root filesystem is up. The blob has to travel with it.
cp -a /etc/mkinitcpio.conf "$BACKUP/mkinitcpio.conf"
if grep -q "$FW_NAME" /etc/mkinitcpio.conf; then
    log "mkinitcpio.conf already lists the blob in FILES="
elif grep -qE '^FILES=\(\)' /etc/mkinitcpio.conf; then
    sed -i "s|^FILES=()|FILES=(${FW_PATH})|" /etc/mkinitcpio.conf
    log "added $FW_PATH to FILES="
elif grep -qE '^FILES=\(' /etc/mkinitcpio.conf; then
    sed -i "s|^FILES=(|FILES=(${FW_PATH} |" /etc/mkinitcpio.conf
    log "prepended $FW_PATH to the existing FILES="
else
    printf 'FILES=(%s)\n' "$FW_PATH" >> /etc/mkinitcpio.conf
    log "appended a FILES= line"
fi
echo "    $(grep -E '^FILES=' /etc/mkinitcpio.conf)"

# --- 6. kernel command line ---------------------------------------------------
CMDLINE_ARG="${DRV}.vbt_firmware=${FW_PARAM}"
if [[ -f /etc/default/limine ]]; then
    cp -a /etc/default/limine "$BACKUP/limine.default"
    if grep -q "vbt_firmware=" /etc/default/limine; then
        # replace whatever is there, the driver name may have changed
        sed -i "s#\b\(xe\|i915\)\.vbt_firmware=[^ \"]*#${CMDLINE_ARG}#" /etc/default/limine
        log "updated the existing vbt_firmware= on the cmdline"
    else
        sed -i "s|^\(KERNEL_CMDLINE\[default\]+=\"[^\"]*\)\"$|\1 ${CMDLINE_ARG}\"|" \
            /etc/default/limine
        log "appended $CMDLINE_ARG to the Limine cmdline"
    fi
    echo "    $(grep -E '^KERNEL_CMDLINE\[default\]' /etc/default/limine)"
else
    warn "/etc/default/limine not found — add this to your bootloader's cmdline:"
    warn "    $CMDLINE_ARG"
fi

# --- 7. regenerate ------------------------------------------------------------
# apply_patch.sh runs this step itself once, after every config edit, so it
# calls us with REGEN=0 to avoid rebuilding the initramfs twice.
if (( ${REGEN:-1} )); then
    log "regenerating the initramfs"
    mkinitcpio -P
    if command -v limine-update >/dev/null; then
        log "updating the Limine config"
        limine-update
    fi
else
    log "skipping the initramfs rebuild (REGEN=0), the caller will do it"
fi

cat > "$STAMP" <<EOF
# written by patch/oled-backlight/install.sh
date=$(date -Is)
bios_version=$BIOS
driver=$DRV
vbt_min=$VBT_MIN
firmware=$FW_PATH
EOF

# --- 8. report ----------------------------------------------------------------
cat <<EOF

$(printf '\033[1;32m==>\033[0m') done. Reboot to pick it up.

  factory VBT kept at  $FACTORY
  backup of this run   $BACKUP
  minimum raised to    ${VBT_MIN}/255

After the reboot:

  # the parameter reached the driver
  cat /sys/module/${DRV}/parameters/vbt_firmware

  # request_firmware() succeeded at probe (a failure is drm_err, always printed)
  journalctl -k -b | grep -i 'VBT firmware'

  # the blob travelled in the initramfs, which is where probe looks for it
  sudo lsinitcpio /boot/*/linux-cachyos/initramfs | grep ${FW_NAME}

  # the floor moved. Use 1, not 0: writing 0 switches the panel off entirely
  # rather than selecting the lowest level.
  echo 1 | sudo tee $BL/brightness

For proof rather than inference, boot once with drm.debug=0x4 and read what
parse_lfp_backlight() logged:

  journalctl -k -b | grep -i 'VBT backlight PWM'      # expect: min brightness ${VBT_MIN}

Do NOT check /sys/kernel/debug/dri/0/i915_vbt. That node re-runs
request_firmware() when you read it, so it reports the file on disk rather than
what the driver parsed at boot. See README.

To change the level, re-run with a different VBT_MIN. To revert entirely, run
uninstall.sh in this directory.

If a BIOS update changes the VBT, the installed blob goes stale. This one was
built against BIOS $BIOS; re-run install.sh after any firmware update.
EOF
