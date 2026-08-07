#!/usr/bin/env bash
# uninstall.sh — revert the patched VBT and go back to the firmware's own
# minimum backlight level.
#
# Dropping the kernel parameter alone is enough to restore stock behaviour;
# everything else here is tidying up. The saved factory VBT is kept by default
# so a later re-install does not have to boot without the parameter first, pass
# PURGE=1 to remove it too.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

FW_DIR=/usr/lib/firmware/honor
FW_PATH="${FW_DIR}/zqc-p-vbt.bin"
STATE_DIR=/var/lib/honor-zqcp
PURGE="${PURGE:-0}"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

log "[1/5] Remove the kernel parameter"
if [[ -f /etc/default/limine ]]; then
    sed -i "s# \(xe\|i915\)\.vbt_firmware=[^ \"]*##" /etc/default/limine
    echo "    $(grep -E '^KERNEL_CMDLINE\[default\]' /etc/default/limine)"
else
    echo "    /etc/default/limine not found — drop xe.vbt_firmware= from your"
    echo "    bootloader's cmdline by hand"
fi

log "[2/5] Drop the blob from the initramfs file list"
sed -i "/^FILES=/ { s#${FW_PATH} *##; s#^FILES=( *)#FILES=()#; }" /etc/mkinitcpio.conf
echo "    $(grep -E '^FILES=' /etc/mkinitcpio.conf)"

log "[3/5] Remove the installed firmware blob"
rm -fv "$FW_PATH"
rmdir --ignore-fail-on-non-empty "$FW_DIR" 2>/dev/null || true
rm -fv "${STATE_DIR}/vbt-patched.bin" "${STATE_DIR}/oled-backlight.stamp"
if (( PURGE )); then
    rm -fv "${STATE_DIR}/vbt-factory.bin"
    rmdir --ignore-fail-on-non-empty "$STATE_DIR" 2>/dev/null || true
else
    echo "    kept ${STATE_DIR}/vbt-factory.bin (PURGE=1 to remove it)"
fi

# uninstall_patch.sh regenerates once at the end, so it calls us with REGEN=0.
if (( ${REGEN:-1} )); then
    log "[4/5] Regenerate the initramfs"
    mkinitcpio -P

    log "[5/5] Update the bootloader config"
    if command -v limine-update >/dev/null; then
        limine-update
    else
        echo "    limine-update not found, skipped"
    fi
else
    log "[4/5] skipping the initramfs rebuild (REGEN=0), the caller will do it"
fi

cat <<EOF

$(printf '\033[1;32m==>\033[0m') reverted. Reboot to go back to the firmware minimum.

After the reboot this must print nothing:

  grep -o 'vbt_firmware=[^ ]*' /proc/cmdline
EOF
