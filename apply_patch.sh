#!/usr/bin/env bash
# apply_patch.sh — install ACPI override + kernel cmdline fix for
# HONOR MagicBook Pro 14 AI (ZQC-P, model M1010).
#
# Fixes:
#   1) Touchpad (Goodix TOPS0102 on I2C1) and touchscreen (FocalTech FTSC1000
#      on I2C2) not appearing — SSDT "I2C_DEVT" fails to load with
#      AE_AML_INTERNAL on stock firmware. Patched SSDT moves the offending
#      module-level GNUM() call into a Method (_INI), letting the table load
#      and exposing TPD0/TPL1 to Linux.
#   2) Internal keyboard quirks (key repeats / dropouts) — i8042.dumbkbd=1
#      kernel command line argument disables i8042 mux probing.
#
# Targets: CachyOS / Arch-like systems with mkinitcpio + Limine.
# Must be run as root.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="$SCRIPT_DIR/patch"
TS=$(date +%Y%m%d-%H%M%S)
BACKUP=/root/honor-zqcp-fix-backup-$TS

req() { command -v "$1" >/dev/null || { echo "missing required tool: $1" >&2; exit 1; }; }
req mkinitcpio
req install
req sed
req cp

mkdir -p "$BACKUP"

#────────────────────────────────────────────────────────────────────────
# [1/5] Backup everything we are about to touch.
#────────────────────────────────────────────────────────────────────────
echo "[1/5] Backup → $BACKUP"
cp -a /etc/mkinitcpio.conf                   "$BACKUP/mkinitcpio.conf"
[[ -d /usr/lib/firmware/acpi ]] && \
    cp -a /usr/lib/firmware/acpi             "$BACKUP/firmware-acpi"
[[ -d /etc/initcpio/install ]] && \
    cp -a /etc/initcpio/install              "$BACKUP/initcpio-install"
[[ -f /etc/default/limine ]] && \
    cp -a /etc/default/limine                "$BACKUP/limine.default"
[[ -f /boot/limine.conf ]] && \
    cp -a /boot/limine.conf                  "$BACKUP/limine.conf"
echo "    OK"

#────────────────────────────────────────────────────────────────────────
# [2/5] Install patched SSDT and mkinitcpio hook.
#────────────────────────────────────────────────────────────────────────
echo "[2/5] Install patched SSDT + mkinitcpio hook"
install -Dm0644 "$PATCH_DIR/SSDT27_TPD0.aml" \
                /usr/lib/firmware/acpi/SSDT27_TPD0.aml
install -Dm0755 "$PATCH_DIR/acpi_override.install" \
                /etc/initcpio/install/acpi_override
echo "    /usr/lib/firmware/acpi/SSDT27_TPD0.aml"
echo "    /etc/initcpio/install/acpi_override"

#────────────────────────────────────────────────────────────────────────
# [3/5] Wire acpi_override into HOOKS=… (right after autodetect).
#────────────────────────────────────────────────────────────────────────
echo "[3/5] Patch /etc/mkinitcpio.conf"
if ! grep -qE '^HOOKS=.*\bacpi_override\b' /etc/mkinitcpio.conf; then
    sed -i 's/\bautodetect\b/autodetect acpi_override/' /etc/mkinitcpio.conf
    echo "    + acpi_override added to HOOKS"
else
    echo "    HOOKS already contain acpi_override — skipped"
fi
# Some older instructions left FILES=(/usr/lib/firmware/acpi/DSDT.aml). Reset it.
if grep -qE '^FILES=\(/usr/lib/firmware/acpi/' /etc/mkinitcpio.conf; then
    sed -i 's|^FILES=(/usr/lib/firmware/acpi/[^)]*)|FILES=()|' /etc/mkinitcpio.conf
    echo "    cleaned stale FILES= entry"
fi
echo "    HOOKS=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf)"

#────────────────────────────────────────────────────────────────────────
# [4/5] Append i8042.dumbkbd=1 to Limine default cmdline (idempotent).
#────────────────────────────────────────────────────────────────────────
echo "[4/5] Patch /etc/default/limine (i8042.dumbkbd=1)"
if [[ -f /etc/default/limine ]]; then
    if ! grep -qE 'i8042\.dumbkbd=1' /etc/default/limine; then
        sed -i 's|^\(KERNEL_CMDLINE\[default\]+="[^"]*\)"$|\1 i8042.dumbkbd=1"|' \
            /etc/default/limine
        echo "    + i8042.dumbkbd=1 appended"
    else
        echo "    cmdline already contains i8042.dumbkbd=1 — skipped"
    fi
    echo "    $(grep -E '^KERNEL_CMDLINE\[default\]' /etc/default/limine)"
else
    echo "    /etc/default/limine not found — add i8042.dumbkbd=1 to your"
    echo "    bootloader cmdline manually."
fi

#────────────────────────────────────────────────────────────────────────
# [5/5] Rebuild initramfs and regenerate Limine config.
#────────────────────────────────────────────────────────────────────────
echo "[5/5] Rebuild initramfs"
if command -v limine-update >/dev/null; then
    limine-update
else
    mkinitcpio -P
    echo "    note: limine-update not found — if you use Limine, run it now"
    echo "    or rebuild your bootloader config manually."
fi

cat <<EOF

════════════════════════════════════════════════════════════════════
  DONE. Reboot to apply.
  Backup of replaced files: $BACKUP
════════════════════════════════════════════════════════════════════

After reboot, verify:

  sudo dmesg | grep -iE 'I2C_DEVT|override|table upgrade'
    expect: "Table Upgrade: override [SSDT- HONOR-I2C_DEVT]"
    expect: NO "AE_AML_INTERNAL" lines

  ls /sys/bus/acpi/devices/ | grep -iE 'TOPS|FTSC'
    expect: TOPS0102:00 (touchpad), FTSC1000:00 (touchscreen)

  cat /proc/cmdline | grep i8042
    expect: includes i8042.dumbkbd=1
EOF
