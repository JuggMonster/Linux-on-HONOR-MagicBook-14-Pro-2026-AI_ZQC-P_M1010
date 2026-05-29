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
#      Step [6/8] rebuilds snd-hda-codec-alc269.ko with the SND_PCI_QUIRK
#      entry our hardware needs (matches the existing HONOR BRB-X M1010
#      sibling); see patch/install-alc269-fix.sh and the upstream patch
#      at patch/alc269-honor-zqc-p-m1010.patch.
#   4) PREVENTIVE — SOF DSP IPC4 copier stale-payload race on suspend/
#      resume. On Intel Panther Lake the IPC4 copier widget's
#      ipc_config_data buffer is cached at first ipc_prepare and reused;
#      on resume the host/link DMA channels are re-allocated with new
#      tags but the stale cached payload still gets sent to firmware,
#      producing a ChainDMA collision and DSP panic. Step [7/8] backports
#      the upstream fix (thesofproject/linux PR #5762 by @ujfalusi) and
#      installs the rebuilt snd-sof.ko in the modules updates/ overlay.
#      Note: on this specific HONOR ZQC-P unit the upstream race was
#      NOT reproducible (zero `DSP panic!` entries in journal across
#      six boots, and zero panics from a pavucontrol + rtcwake -m mem
#      ×3 repro). We ship it anyway because (a) the patch is a clean
#      upstream backport, (b) the workflow that triggers it is
#      application-driven and may surface later, and (c) it is
#      defensive — no behavioural change when the race doesn't fire.
#      See patch/install-sof-ipc4-fix.sh and the patch file:
#      patch/0001-ASoC-SOF-ipc4-topology-Refresh-copier-IPC-payload-before-widget-setup.patch
#      Upstream tracking issue: thesofproject/sof#10700.
#   5) HONOR EC mic-privacy storm on KEY_MICMUTE (WMI 0x287). HONOR EC
#      firmware fires the mic-privacy WMI event 0x287 autonomously in
#      2-event pairs (touchpad swipe + focus change, intel_lpmd profile
#      transitions, or even pure idle), confirmed by `code 0xf8 on
#      isa0060/serio0` bursts in dmesg. Each pair would self-cancel
#      but userspace dispatch races leave the mic stuck muted; Fn+F7
#      no longer restores. Trigger is opaque firmware logic — not
#      exposed via any WMI setter, no OEM-level disable possible. Step
#      [8/8] applies a kernel patch to huawei-wmi.c that detects the
#      storm pair pattern (two 0x287 within `micmute_storm_window_ms`
#      = default 2000 ms) and drops both events; legitimate single
#      Fn+F7 press emits normally with at most 2 s latency. Set
#      `micmute_storm_window_ms=0` via /sys to disable the filter.
#      See patch/install-huawei-wmi-fix.sh and
#      patch/0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch.
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
# [1/8] Backup everything we are about to touch.
#────────────────────────────────────────────────────────────────────────
echo "[1/8] Backup → $BACKUP"
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
# [2/8] Install patched SSDT and mkinitcpio install hook.
#────────────────────────────────────────────────────────────────────────
echo "[2/8] Install patched SSDT + mkinitcpio hook"
install -Dm0644 "$PATCH_DIR/SSDT27_TPD0.aml" \
                /usr/lib/firmware/acpi/SSDT27_TPD0.aml
install -Dm0755 "$PATCH_DIR/acpi_override.install" \
                /etc/initcpio/install/acpi_override
echo "    /usr/lib/firmware/acpi/SSDT27_TPD0.aml"
echo "    /etc/initcpio/install/acpi_override"

#────────────────────────────────────────────────────────────────────────
# [3/8] Wire acpi_override into HOOKS=… (right after autodetect).
#────────────────────────────────────────────────────────────────────────
echo "[3/8] Patch /etc/mkinitcpio.conf"
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
# [4/8] Append i8042.dumbkbd=1 to Limine default cmdline (idempotent).
#────────────────────────────────────────────────────────────────────────
echo "[4/8] Patch /etc/default/limine (i8042.dumbkbd=1)"
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
# [5/8] Rebuild initramfs and regenerate Limine config.
#────────────────────────────────────────────────────────────────────────
echo "[5/8] Rebuild initramfs"
if command -v limine-update >/dev/null; then
    limine-update
else
    mkinitcpio -P
    echo "    note: limine-update not found — if you use Limine, run it now"
    echo "    or rebuild your bootloader config manually."
fi

#────────────────────────────────────────────────────────────────────────
# [6/8] Build + install ALC256 codec quirk for the 3.5mm-jack headset mic.
# Fetches the running kernel's alc269.c from the upstream stable tree,
# adds SND_PCI_QUIRK(0x1ee7, 0x209d, "HONOR ZQC-P M1010", …) — pin 0x19
# is wired to the combo jack mic on this board, identical to the existing
# BRB-X M1010 sibling — and replaces /lib/modules/.../snd-hda-codec-alc269.ko.zst.
# Original is backed up to /root/snd-hda-codec-alc269.ko.zst.orig.
# The script is idempotent: if the in-tree module already carries the
# quirk (e.g. after upstream merge), it exits without rebuilding.
#────────────────────────────────────────────────────────────────────────
echo "[6/8] Apply ALC256 headset-mic quirk (snd-hda-codec-alc269 rebuild)"
if bash "$PATCH_DIR/install-alc269-fix.sh"; then
    echo "    OK"
else
    echo "    [warn] ALC256 quirk install failed — touchpad/touchscreen fix is"
    echo "    still applied; only the analog headset mic on the 3.5mm jack will"
    echo "    stay unavailable. Inspect patch/install-alc269-fix.sh output above."
fi

#────────────────────────────────────────────────────────────────────────
# [7/8] Build + install SOF IPC4 copier-payload refresh patch
# (thesofproject/linux PR #5762 by @ujfalusi). Fetches the running
# kernel's sound/soc/sof/ tree from the upstream stable tree, applies the
# 33-line ipc4-topology.c fix, builds snd-sof.ko out-of-tree and drops
# the rebuild into /lib/modules/$KVER/updates/ as an overlay so the in-
# tree module is left untouched. Original snd-sof.ko.zst is backed up to
# /root/snd-sof.ko.zst.orig.
# The script is idempotent: if upstream has already merged the fix (or
# our overlay is already in place), it exits without rebuilding.
# Skipped silently if kernel lockdown / module.sig_enforce blocks
# unsigned modules — see patch/install-sof-ipc4-fix.sh for details.
#────────────────────────────────────────────────────────────────────────
echo "[7/8] Apply SOF IPC4 copier-payload refresh (snd-sof rebuild)"
if bash "$PATCH_DIR/install-sof-ipc4-fix.sh"; then
    echo "    OK"
else
    echo "    [warn] SOF IPC4 fix install failed — earlier steps are still"
    echo "    applied; only the Fn+F7 mic-mute stability after suspend/resume"
    echo "    on Panther Lake will be affected. Inspect"
    echo "    patch/install-sof-ipc4-fix.sh output above."
fi

#────────────────────────────────────────────────────────────────────────
# [8/8] Build + install huawei-wmi KEY_MICMUTE storm-detection patch.
# Fetches the running kernel's drivers/platform/x86/huawei-wmi.c from
# the upstream stable tree, applies the storm-detection patch, builds
# huawei-wmi.ko out-of-tree, and drops the rebuild into
# /lib/modules/$KVER/updates/ as an overlay so the in-tree module is
# left untouched. Original huawei-wmi.ko.zst is backed up to
# /root/huawei-wmi.ko.zst.orig.
# The script is idempotent: if upstream has already merged the fix
# (or our overlay is already in place), it exits without rebuilding.
# Skipped silently if kernel lockdown / module.sig_enforce blocks
# unsigned modules — see patch/install-huawei-wmi-fix.sh for details.
#────────────────────────────────────────────────────────────────────────
echo "[8/8] Apply huawei-wmi KEY_MICMUTE storm-detection (huawei-wmi rebuild)"
if bash "$PATCH_DIR/install-huawei-wmi-fix.sh"; then
    echo "    OK"
else
    echo "    [warn] huawei-wmi storm-detection install failed — earlier steps"
    echo "    are still applied; only the EC privacy-storm pair suppression"
    echo "    on KEY_MICMUTE will be affected. Inspect"
    echo "    patch/install-huawei-wmi-fix.sh output above."
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

  # SOF DSP IPC4 fix — verify the overlay loaded instead of the in-tree one:
  modinfo -F filename snd_sof
    expect: /lib/modules/.../updates/snd-sof.ko.zst (not kernel/sound/soc/sof/)

  # No DSP panic should follow a suspend/resume cycle with pavucontrol running
  # (this is the direct repro from upstream thesofproject/sof#10700):
  sudo rtcwake -m mem -s 5  # × 2-3 times with pavucontrol open
  journalctl -k -b | grep -c 'DSP panic'
    expect: 0 — on this HONOR ZQC-P unit it stays at 0 with or without
            the patch (the upstream race does not trigger here in
            normal use; the patch is preventive)

  # DO NOT use grep -c 'CRASHED' /var/log/honor-fnf7-watch.log as a
  # before/after metric. That counter also flips during runtime PM D3
  # cycles and overstates real panics by orders of magnitude.

  # huawei-wmi storm-detection — verify overlay loaded and new parameter present:
  modinfo -F filename huawei_wmi
    expect: /lib/modules/.../updates/huawei-wmi.ko.zst
  modinfo -F parm huawei_wmi | grep micmute_storm_window_ms
    expect: micmute_storm_window_ms:EC privacy-storm window (ms) ... (int)
  cat /sys/module/huawei_wmi/parameters/micmute_storm_window_ms
    expect: 2000  (override at runtime by writing a new value)

  # When an EC privacy storm fires, dmesg gets a paired "code 0xf8 on
  # isa0060/serio0" burst regardless of the filter. With the filter the
  # microphone mute state will NOT flap — count storm events and look at
  # current LED state:
  sudo dmesg --since '30 minutes ago' | grep -c 'code 0xf8 on isa0060'
  cat /sys/class/leds/platform::micmute/brightness
    expect: brightness=0 when mic is meant to be active (no stuck mute)

  # After every kernel update, re-run patch/install-alc269-fix.sh,
  # patch/install-sof-ipc4-fix.sh, AND patch/install-huawei-wmi-fix.sh
  # so the codec quirk + SOF overlay + huawei-wmi storm-detection are
  # rebuilt against the new headers.
EOF
