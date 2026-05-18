#!/usr/bin/env bash
# uninstall_patch.sh — revert the ACPI override and cmdline change applied by
# apply_patch.sh. Run as root.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

echo "[1/5] Remove patched SSDT"
rm -fv /usr/lib/firmware/acpi/SSDT27_TPD0.aml

echo "[2/5] Remove mkinitcpio install hook"
rm -fv /etc/initcpio/install/acpi_override

echo "[3/5] Remove keyboard hwdb override and refresh cache"
rm -fv /etc/udev/hwdb.d/61-keyboard-honor-zqc-p.hwdb
if command -v systemd-hwdb >/dev/null; then
    systemd-hwdb update
    command -v udevadm >/dev/null && \
        udevadm trigger --subsystem-match=input --action=change
fi

echo "[4/5] Strip acpi_override from /etc/mkinitcpio.conf and i8042.dumbkbd=1 from cmdline"
sed -i 's/ acpi_override//' /etc/mkinitcpio.conf
echo "    HOOKS=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf)"

if [[ -f /etc/default/limine ]]; then
    sed -i 's/ i8042\.dumbkbd=1//' /etc/default/limine
    echo "    $(grep -E '^KERNEL_CMDLINE\[default\]' /etc/default/limine)"
fi

echo "[5/5] Rebuild initramfs + bootloader config"
if command -v limine-update >/dev/null; then
    limine-update
else
    mkinitcpio -P
fi

echo
echo "Done. Reboot to fully revert. Touchpad/touchscreen will be unavailable"
echo "again until apply_patch.sh is re-run or a different fix is installed."
echo "Fn+F7 will revert to emitting an unknown PS/2 scancode (no mic mute)."
