#!/usr/bin/env bash
# install-huawei-wmi-fix.sh — fetch the running kernel's huawei-wmi.c
# from the upstream stable tree, apply our KEY_MICMUTE storm-detection
# patch, build huawei-wmi.ko out-of-tree against the installed kernel
# headers, and drop the resulting huawei-wmi.ko.zst into the modules
# updates/ overlay so it loads instead of the unpatched in-tree module.
#
# Background:
#   The HONOR ZQC-P M1010 EC firmware fires the mic-privacy WMI event
#   (0x287, KEY_MICMUTE) autonomously in 2-event pairs, separated by
#   anywhere from 0.5 to 5 seconds, with no user keypress. The trigger
#   is opaque firmware logic — not exposed via any documented ACPI/WMI
#   setter — and includes touchpad swipes that change focus to audio-
#   playing windows, intel_lpmd platform-profile transitions, and pure
#   idle. The EC also writes the legacy PS/2 scancode 0xf8 to i8042 in
#   parallel ("atkbd serio0: Unknown key pressed (translated set 2,
#   code 0xf8 on isa0060/serio0)" in dmesg) — easy forensic marker.
#
#   Each pair toggles the default source mute twice, which should self-
#   cancel; but in practice the userspace dispatch path (Wayland
#   compositor + gsd-media-keys grab + audio backend) loses one of the
#   two toggles to races, leaving the mic stuck muted with the
#   platform::micmute LED on and the hardware Fn+F7 shortcut unable to
#   restore it. Manual unmute through the GNOME tray or pavucontrol
#   recovers; nothing else does.
#
#   The patch adds storm-detection in huawei_wmi_process_key(): when
#   a 0x287 event arrives, the driver defers emission by a configurable
#   number of milliseconds (micmute_storm_window_ms, default 1000);
#   if a second 0x287 arrives during the window both are dropped
#   (storm pair); otherwise the deferred event is emitted normally
#   (legitimate single Fn+F7 press). Trade-off: <=1 s emit latency on
#   legitimate Fn+F7 press in exchange for full silencing of the EC
#   storm. Set micmute_storm_window_ms=0 to disable the filter.
#
# This is a workaround for as long as the upstream patch under
# patch/0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch
# has not yet landed in the kernel being used. Once the change is in
# the running kernel's huawei-wmi.c this script becomes a no-op (it
# will detect the existing edit and skip the rebuild, removing any
# stale overlay).
#
# Reruns are safe — running it after a kernel update will rebuild
# against the new headers automatically.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

KVER=$(uname -r)
BUILD_DIR="/usr/lib/modules/${KVER}/build"
UPDATES_DIR="/usr/lib/modules/${KVER}/updates"
KO_NAME="huawei-wmi.ko.zst"
KO_OVERLAY="${UPDATES_DIR}/${KO_NAME}"
KO_INTREE="/usr/lib/modules/${KVER}/kernel/drivers/platform/x86/${KO_NAME}"
BACKUP="/root/${KO_NAME}.orig"
WORK=$(mktemp -d /tmp/huawei-wmi-fix-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/0001-platform-x86-huawei-wmi-Storm-detection-for-KEY_MICMUTE-0x287.patch"

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

req() { command -v "$1" >/dev/null || { echo "missing required tool: $1" >&2; exit 1; }; }
req curl
req zstdcat
req zstd
req make
req clang
req ld.lld
req patch
req depmod
req modinfo

echo "[*] kernel  = ${KVER}"
echo "[*] target  = ${KO_OVERLAY}"
echo "[*] patch   = ${PATCH_FILE}"

if [[ ! -f "$PATCH_FILE" ]]; then
    echo "[fatal] patch file not found: $PATCH_FILE" >&2
    exit 1
fi

# Refuse to run if module signature enforcement is on — our rebuilt module
# would not be loadable.
if [[ -r /sys/kernel/security/lockdown ]] \
   && grep -qE '\[(integrity|confidentiality)\]' /sys/kernel/security/lockdown; then
    echo "[fatal] kernel lockdown is active — unsigned modules won't load." >&2
    echo "        $(cat /sys/kernel/security/lockdown)" >&2
    exit 1
fi
if grep -qE '\bmodule\.sig_enforce=1\b' /proc/cmdline; then
    echo "[fatal] module.sig_enforce=1 in /proc/cmdline — unsigned modules won't load." >&2
    exit 1
fi

# Verify build infrastructure.
if [[ ! -f "${BUILD_DIR}/Makefile" || ! -f "${BUILD_DIR}/Module.symvers" ]]; then
    echo "[fatal] kernel build dir incomplete: ${BUILD_DIR}" >&2
    echo "        install the matching linux-*-headers package and re-run."
    exit 1
fi

# Fetch upstream huawei-wmi.c at the running kernel's tag.
TAG="v${KVER%%-*}"
BASE_URL="https://raw.githubusercontent.com/gregkh/linux/${TAG}"

fetch() {
    local rel="$1" dest="$2"
    local code
    mkdir -p "$(dirname "$dest")"
    code=$(curl -sSL --max-time 60 -o "$dest" -w '%{http_code}' "${BASE_URL}/${rel}")
    if [[ "$code" != "200" ]]; then
        echo "[fatal] fetch failed: ${BASE_URL}/${rel} (HTTP $code)" >&2
        exit 1
    fi
}

# Detect whether the running kernel already has the storm-detection
# patch merged. We look for the distinctive parameter name in the
# upstream huawei-wmi.c; if present, the fix is in-tree and we
# remove any prior overlay as redundant.
echo "[*] checking upstream ${TAG} for whether the fix is already merged"
fetch "drivers/platform/x86/huawei-wmi.c" "${WORK}/_check_huawei-wmi.c"
if grep -qF 'micmute_storm_window_ms' "${WORK}/_check_huawei-wmi.c"; then
    echo "[ok] in-tree huawei-wmi.c at ${TAG} already contains the fix."
    if [[ -f "$KO_OVERLAY" ]]; then
        echo "[*] removing redundant overlay $KO_OVERLAY"
        rm -f "$KO_OVERLAY"
        rmdir --ignore-fail-on-non-empty "$UPDATES_DIR" 2>/dev/null || true
        depmod -a "$KVER"
    fi
    exit 0
fi

# Skip rebuild if our overlay is already in place with a srcversion
# distinct from the in-tree baseline.
overlay_is_patched() {
    [[ -f "$KO_OVERLAY" ]] || return 1
    local sv_overlay sv_intree
    sv_overlay=$(modinfo -F srcversion "$KO_OVERLAY" 2>/dev/null || true)
    sv_intree=$( modinfo -F srcversion "$KO_INTREE"  2>/dev/null || true)
    [[ -n "$sv_overlay" && "$sv_overlay" != "$sv_intree" ]]
}
if overlay_is_patched; then
    echo "[ok] overlay already present at $KO_OVERLAY with a different srcversion"
    echo "     than the in-tree module — assumed to be the patched build."
    echo "     Delete the overlay file and re-run if you want a fresh rebuild."
    exit 0
fi

# Stage the patched source and a minimal Kbuild Makefile in $WORK.
echo "[*] fetching huawei-wmi.c at tag ${TAG}"
mv "${WORK}/_check_huawei-wmi.c" "${WORK}/huawei-wmi.c"

echo "[*] applying ${PATCH_FILE##*/}"
if ! patch -p4 --no-backup-if-mismatch -d "$WORK" < "$PATCH_FILE"; then
    echo "[fatal] patch did not apply cleanly against ${TAG}'s huawei-wmi.c" >&2
    echo "        upstream layout drifted — review .rej files in $WORK" >&2
    exit 1
fi

# Minimal out-of-tree build Makefile.
cat > "${WORK}/Makefile" <<'EOF'
obj-m += huawei-wmi.o
KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)
default:
	$(MAKE) -C $(KDIR) M=$(PWD) LLVM=1 LLVM_IAS=1 modules
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
EOF

echo "[*] building huawei-wmi.ko (LLVM toolchain)"
( cd "$WORK" && make ) 2>&1 | tail -8

BUILT_KO="${WORK}/huawei-wmi.ko"
if [[ ! -f "$BUILT_KO" ]]; then
    echo "[fatal] build did not produce ${BUILT_KO}" >&2
    exit 1
fi

# Sanity-check that srcversion differs from in-tree baseline.
SV_BUILT=$( modinfo -F srcversion "$BUILT_KO" 2>/dev/null || true)
SV_INTREE=$(modinfo -F srcversion "$KO_INTREE" 2>/dev/null || true)
if [[ -n "$SV_INTREE" && "$SV_BUILT" == "$SV_INTREE" ]]; then
    echo "[fatal] built srcversion == in-tree srcversion (${SV_BUILT})" >&2
    echo "        patch did not change the compiled output — bail out rather" >&2
    echo "        than install an indistinguishable module." >&2
    exit 1
fi

# Confirm the new module parameter is exported.
if ! modinfo -F parm "$BUILT_KO" 2>/dev/null | grep -q 'micmute_storm_window_ms'; then
    echo "[fatal] built module does not export micmute_storm_window_ms parameter" >&2
    echo "        — patch did not take effect as expected." >&2
    exit 1
fi

if [[ ! -f "$BACKUP" && -f "$KO_INTREE" ]]; then
    echo "[*] backing up in-tree ${KO_INTREE} -> ${BACKUP}"
    cp -a "$KO_INTREE" "$BACKUP"
fi

echo "[*] installing patched module to ${KO_OVERLAY}"
install -d -m 0755 "$UPDATES_DIR"
zstd -19 -q --force "$BUILT_KO" -o "${WORK}/${KO_NAME}"
install -m 0644 "${WORK}/${KO_NAME}" "$KO_OVERLAY"
depmod -a "$KVER"

# Verify resolution. modinfo may report /lib/... where we wrote /usr/lib/...;
# resolve both via readlink to compare canonical paths.
RESOLVED=$(modinfo -F filename huawei_wmi 2>/dev/null || true)
RESOLVED_REAL=$(readlink -f "$RESOLVED" 2>/dev/null || echo "$RESOLVED")
EXPECTED_REAL=$(readlink -f "$KO_OVERLAY" 2>/dev/null || echo "$KO_OVERLAY")
if [[ "$RESOLVED_REAL" != "$EXPECTED_REAL" ]]; then
    echo "[warn] modinfo resolves huawei_wmi to:"
    echo "       $RESOLVED"
    echo "       (expected $KO_OVERLAY). depmod ordering may need investigation."
fi

cat <<EOF

════════════════════════════════════════════════════════════════════
  huawei-wmi KEY_MICMUTE storm-detection installed.

  Overlay: $KO_OVERLAY
  Backup of original in-tree module: $BACKUP
  (delete the overlay file and re-run depmod to revert.)

  After REBOOT the patched huawei-wmi.ko will load instead of the in-
  tree one. The driver will then debounce EC privacy-storm event pairs
  on WMI event 0x287 (KEY_MICMUTE) by deferring emission of the first
  event by ${KO_NAME%.ko.zst}'s default 1000 ms window.

  Tune at runtime without reboot:
    \$ echo 1500 | sudo tee /sys/module/huawei_wmi/parameters/micmute_storm_window_ms
    \$ echo 0    | sudo tee /sys/module/huawei_wmi/parameters/micmute_storm_window_ms  # disable

  Verification (count "Unknown key code 0xf8" lines as storm marker;
  storm events should still be visible in dmesg but mute will no
  longer flap):
    \$ sudo dmesg --since '1 hour ago' | grep -c 'code 0xf8 on isa0060'

  Re-run this script after every kernel update.
════════════════════════════════════════════════════════════════════
EOF
