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

echo "[3/5] Strip acpi_override from /etc/mkinitcpio.conf and i8042.dumbkbd=1 from cmdline"
sed -i 's/ acpi_override//' /etc/mkinitcpio.conf
echo "    HOOKS=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf)"

if [[ -f /etc/default/limine ]]; then
    sed -i 's/ i8042\.dumbkbd=1//' /etc/default/limine
    echo "    $(grep -E '^KERNEL_CMDLINE\[default\]' /etc/default/limine)"
fi

echo "[4/5] Restore original snd-hda-codec-alc269.ko.zst (if backup present)"
KVER=$(uname -r)
KO_PATH="/usr/lib/modules/${KVER}/kernel/sound/hda/codecs/realtek/snd-hda-codec-alc269.ko.zst"
BACKUP="/root/snd-hda-codec-alc269.ko.zst.orig"
if [[ -f "$BACKUP" ]]; then
    cp -av "$BACKUP" "$KO_PATH"
    rm -fv "$BACKUP"
    depmod -a
else
    echo "    no backup at $BACKUP — patched module (if any) left in place."
    echo "    reinstall the linux-headers / linux package to restore the original."
fi

# Earlier iterations of install-alc269-fix.sh installed a systemd hotfix
# service to fire EXECUTE_PIN_SENSE on every boot. The current kernel-side
# fixup makes it unnecessary — remove it if it's still present.
if systemctl list-unit-files honor-mic-jack-init.service >/dev/null 2>&1 \
   && systemctl is-enabled honor-mic-jack-init.service >/dev/null 2>&1; then
    systemctl disable --now honor-mic-jack-init.service 2>/dev/null || true
fi
rm -f /etc/systemd/system/honor-mic-jack-init.service \
      /usr/local/bin/honor-mic-jack-init.sh
systemctl daemon-reload 2>/dev/null || true

echo "[5/5] Rebuild initramfs + bootloader config"
if command -v limine-update >/dev/null; then
    limine-update
else
    mkinitcpio -P
fi

echo
echo "Done. Reboot to fully revert. Touchpad/touchscreen will be unavailable"
echo "again until apply_patch.sh is re-run or a different fix is installed."
echo "Analog 3.5mm-jack headset mic input will also disappear."
