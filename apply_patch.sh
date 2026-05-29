#!/usr/bin/env bash
# apply_patch.sh — install ACPI override and kernel cmdline fix for
# HONOR MagicBook Pro 14 AI (ZQC-P, model M1010).
#
# Fixes:
#   1) Touchpad (Goodix TOPS0102 on I2C1) and touchscreen (FocalTech FTSC1000
#      on I2C2) not appearing — SSDT "I2C_DEVT" fails to load with
#      AE_AML_INTERNAL on stock firmware. Patched SSDT moves the offending
#      module-level GNUM() call into a Method (_INI), letting the table load
#      and exposing TPD0/TPL1 to Linux.
#   2) Internal keyboard quirks (key repeats / dropouts) — i8042.dumbkbd=1
#      kernel command line argument suppresses atkbd command sending
#      (see README for the trade-off with Caps Lock LED).
#   3) Analog 3.5mm-jack headset microphone unusable — PCI SSID 1ee7:209d
#      is missing from sound/hda/codecs/realtek/alc269.c quirk table.
#      Step [6/6] rebuilds snd-hda-codec-alc269.ko with the SND_PCI_QUIRK
#      entry our hardware needs (matches the existing HONOR BRB-X M1010
#      sibling); see patch/install-alc269-fix.sh and the upstream patch
#      at patch/alc269-honor-zqc-p-m1010.patch.
#
# Fn+F7 mic-mute already works out of the box on this hardware via the
# huawei-wmi driver (separate "Huawei WMI hotkeys" input device emits
# KEY_MICMUTE on every press; PipeWire toggles the source mute and the
# platform::micmute LED follows via the audio-micmute trigger). No
# keymap or udev/systemd plumbing is needed. See README for details.
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
# [2/5] Install patched SSDT and mkinitcpio install hook.
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
# [5/6] Rebuild initramfs and regenerate Limine config.
#────────────────────────────────────────────────────────────────────────
echo "[5/6] Rebuild initramfs"
if command -v limine-update >/dev/null; then
    limine-update
else
    mkinitcpio -P
    echo "    note: limine-update not found — if you use Limine, run it now"
    echo "    or rebuild your bootloader config manually."
fi

#────────────────────────────────────────────────────────────────────────
# [6/6] Build + install ALC256 codec quirk for the 3.5mm-jack headset mic.
# Fetches the running kernel's alc269.c from the upstream stable tree,
# adds SND_PCI_QUIRK(0x1ee7, 0x209d, "HONOR ZQC-P M1010", …) — pin 0x19
# is wired to the combo jack mic on this board, identical to the existing
# BRB-X M1010 sibling — and replaces /lib/modules/.../snd-hda-codec-alc269.ko.zst.
# Original is backed up to /root/snd-hda-codec-alc269.ko.zst.orig.
# The script is idempotent: if the in-tree module already carries the
# quirk (e.g. after upstream merge), it exits without rebuilding.
#────────────────────────────────────────────────────────────────────────
echo "[6/6] Apply ALC256 headset-mic quirk (snd-hda-codec-alc269 rebuild)"
if bash "$PATCH_DIR/install-alc269-fix.sh"; then
    echo "    OK"
else
    echo "    [warn] ALC256 quirk install failed — touchpad/touchscreen fix is"
    echo "    still applied; only the analog headset mic on the 3.5mm jack will"
    echo "    stay unavailable. Inspect patch/install-alc269-fix.sh output above."
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

  # press Fn+F7 — mic should mute/unmute and the F7 LED should follow
  # (works out of the box via huawei-wmi; no extra setup needed):
  cat /sys/class/leds/platform::micmute/trigger
    expect: contains [audio-micmute]

  # 3.5mm-jack headset mic — should appear once you plug in a CTIA-wired
  # headset and PipeWire/wireplumber rescans:
  pactl list short sources | grep -i headset
    expect: a HiFi__Headset__source endpoint

  # After every kernel update, re-run patch/install-alc269-fix.sh
  # so the codec quirk is rebuilt against the new headers.
EOF
