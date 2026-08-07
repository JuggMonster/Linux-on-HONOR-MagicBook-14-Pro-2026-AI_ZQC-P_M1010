#!/usr/bin/env bash
# uninstall_patch.sh — revert the ACPI override and cmdline change applied by
# apply_patch.sh. Run as root.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

echo "[1/10] Remove patched SSDT"
rm -fv /usr/lib/firmware/acpi/SSDT27_TPD0.aml

echo "[2/10] Remove mkinitcpio install hook"
rm -fv /etc/initcpio/install/acpi_override

echo "[3/10] Strip acpi_override from /etc/mkinitcpio.conf and i8042.dumbkbd=1 from cmdline"
sed -i 's/ acpi_override//' /etc/mkinitcpio.conf
echo "    HOOKS=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf)"

if [[ -f /etc/default/limine ]]; then
    sed -i 's/ i8042\.dumbkbd=1//' /etc/default/limine
    echo "    $(grep -E '^KERNEL_CMDLINE\[default\]' /etc/default/limine)"
fi

KVER=$(uname -r)

echo "[4/10] Remove the ALC256 codec-quirk overlay and the capture-priority rule"
rm -fv "/usr/lib/modules/${KVER}/updates/snd-hda-codec-alc269.ko.zst" 2>/dev/null || true
rm -fv /etc/wireplumber/wireplumber.conf.d/51-honor-zqcp-mic-priority.conf 2>/dev/null || true
rmdir --ignore-fail-on-non-empty /etc/wireplumber/wireplumber.conf.d /etc/wireplumber 2>/dev/null || true

echo "[4b/10] Restore original snd-hda-codec-alc269.ko.zst if a legacy in-place install is present"
ALC_PATH="/usr/lib/modules/${KVER}/kernel/sound/hda/codecs/realtek/snd-hda-codec-alc269.ko.zst"
ALC_BACKUP="/root/snd-hda-codec-alc269.ko.zst.orig"
if [[ -f "$ALC_BACKUP" ]]; then
    cp -av "$ALC_BACKUP" "$ALC_PATH"
    rm -fv "$ALC_BACKUP"
else
    echo "    no backup at $ALC_BACKUP — patched module (if any) left in place."
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

echo "[5/10] Remove SOF IPC4 fix overlay (if present)"
SOF_OVERLAY="/usr/lib/modules/${KVER}/updates/snd-sof.ko.zst"
SOF_BACKUP="/root/snd-sof.ko.zst.orig"
if [[ -f "$SOF_OVERLAY" ]]; then
    rm -fv "$SOF_OVERLAY"
else
    echo "    no overlay at $SOF_OVERLAY — already absent."
fi
[[ -f "$SOF_BACKUP" ]] && echo "    in-tree backup at $SOF_BACKUP retained for next install."

echo "[6/10] Remove the auto-rebuild pacman hooks"
rm -fv /etc/pacman.d/hooks/95-honor-zqcp-kernel-modules.hook \
       /etc/pacman.d/hooks/96-honor-zqcp-libfprint.hook \
       /usr/local/lib/honor-zqcp/rebuild.sh \
       /etc/honor-zqcp-autorebuild.conf
rmdir --ignore-fail-on-non-empty /usr/local/lib/honor-zqcp 2>/dev/null || true

echo "[7/10] Remove the HID-BPF mic-mute fixup and any legacy module overlays"
systemctl disable --now honor-hid-bpf-reapply.service 2>/dev/null || true
rm -fv /etc/systemd/system/honor-hid-bpf-reapply.service \
       /usr/local/lib/honor-zqcp/hid-bpf-reapply.sh
systemctl daemon-reload 2>/dev/null || true
rm -fv /etc/udev-hid-bpf/honor-ftsc1000-micmute.bpf.o \
       /etc/udev/rules.d/99-hid-bpf-honor-ftsc1000-micmute.rules
udevadm control --reload 2>/dev/null || true
for pair in \
    "/usr/lib/modules/${KVER}/updates/hid-multitouch.ko.zst:/root/hid-multitouch.ko.zst.orig" \
    "/usr/lib/modules/${KVER}/updates/huawei-wmi.ko.zst:/root/huawei-wmi.ko.zst.orig"
do
    OVERLAY="${pair%%:*}"; BACKUP="${pair##*:}"
    [[ -f "$OVERLAY" ]] && rm -fv "$OVERLAY"
    [[ -f "$BACKUP" ]] && echo "    in-tree backup at $BACKUP retained."
done

rmdir --ignore-fail-on-non-empty "/usr/lib/modules/${KVER}/updates" 2>/dev/null || true
depmod -a "$KVER"

echo "[8/10] Remove the touchpad edge-gesture HID-BPF program"
rm -fv /etc/udev-hid-bpf/honor-tops0102-edge.bpf.o \
       /etc/udev/rules.d/99-hid-bpf-honor-tops0102-edge.rules
udevadm control --reload 2>/dev/null || true

echo "[9/10] Revert the OLED backlight VBT"
if [[ -x "$(dirname "${BASH_SOURCE[0]}")/patch/oled-backlight/uninstall.sh" ]]; then
    REGEN=0 bash "$(dirname "${BASH_SOURCE[0]}")/patch/oled-backlight/uninstall.sh" || \
        echo "    [warn] revert failed, see patch/oled-backlight/uninstall.sh"
else
    echo "    patch/oled-backlight/uninstall.sh not found — removing by hand"
    sed -i "s# \(xe\|i915\)\.vbt_firmware=[^ \"]*##" /etc/default/limine 2>/dev/null || true
    sed -i "/^FILES=/ { s#/usr/lib/firmware/honor/zqc-p-vbt.bin *##; s#^FILES=( *)#FILES=()#; }" \
        /etc/mkinitcpio.conf 2>/dev/null || true
    rm -fv /usr/lib/firmware/honor/zqc-p-vbt.bin
fi

echo "[10/10] Rebuild initramfs + bootloader config"
if command -v limine-update >/dev/null; then
    limine-update
else
    mkinitcpio -P
fi

echo
echo "Done. Reboot to fully revert. Touchpad/touchscreen will be unavailable"
echo "again until apply_patch.sh is re-run or a different fix is installed."
echo "Analog 3.5mm-jack headset mic input will also disappear."
echo "SOF DSP will fall back to the in-tree (unpatched) module — expect"
echo "occasional DSP panics on suspend/resume per thesofproject/sof#10700."
echo "The touchscreen's vendor HID collection will be exported as a phantom"
echo "KEY_MICMUTE device again, so the mic will start muting itself."
echo "The touchpad left-edge brightness gesture and the raised OLED backlight"
echo "floor are reverted too."
echo
echo "Not touched, remove separately if you want them gone:"
echo "  fan sensor   sudo dkms remove honor-zqcp-hwmon/1.0 --all"
echo "  fingerprint  sudo pacman -S libfprint    # replaces the patched build"
