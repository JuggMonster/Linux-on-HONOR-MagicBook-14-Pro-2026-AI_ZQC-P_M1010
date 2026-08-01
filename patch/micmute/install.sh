#!/usr/bin/env bash
# install.sh — stop the phantom KEY_MICMUTE device created from the
# touchscreen's vendor-defined HID collection.
#
# Root cause (measured on this machine, see README.md):
#   The FocalTech FTSC1000 touchscreen (I2C HID 2808:5662) declares a
#   vendor-defined application collection on HID usage page 0xff01. That page
#   is HID_UP_HPVENDOR2 in the kernel, so hid-input maps usage 0xff010001 to
#   KEY_MICMUTE. The device matches MT_CLS_WIN_8, which sets export_all_inputs,
#   so hid-multitouch exports the collection as a second input device whose
#   only key is KEY_MICMUTE. Its 59 data bytes all carry that usage, and
#   hid-input sets EV_REP for the page, so a single vendor report leaves
#   KEY_MICMUTE held down and auto-repeating at ~30 Hz until reboot.
#
#   That is the microphone muting and unmuting on its own.
#
# The fix rebuilds hid-multitouch.ko with one extra guard: never export a
# vendor-defined application collection. The touchscreen and the touchpad keep
# working, and the real Fn+F7 key is untouched — it arrives over WMI on the
# "Huawei WMI hotkeys" input device, not over HID.
#
# Reruns are safe. Re-run after every kernel update.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

# Override with KVER=... to build for a kernel other than the running one -
# needed when a kernel update is installed but not yet booted, since the
# headers for the running kernel are gone at that point.
KVER="${KVER:-$(uname -r)}"
BUILD_DIR="/usr/lib/modules/${KVER}/build"
UPDATES_DIR="/usr/lib/modules/${KVER}/updates"
KO_NAME="hid-multitouch.ko.zst"
KO_OVERLAY="${UPDATES_DIR}/${KO_NAME}"
KO_INTREE="/usr/lib/modules/${KVER}/kernel/drivers/hid/${KO_NAME}"
BACKUP="/root/${KO_NAME}.orig"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/0001-HID-multitouch-do-not-export-vendor-defined-applicat.patch"
RULES_FILE="${SCRIPT_DIR}/99-honor-phantom-micmute.rules"
WORK=$(mktemp -d /var/tmp/hid-micmute-XXXXXX)

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

req() { command -v "$1" >/dev/null || die "missing required tool: $1"; }
for t in curl make clang ld.lld patch depmod modinfo zstd; do req "$t"; done

log "kernel = ${KVER}"
log "target = ${KO_OVERLAY}"

[[ -f "$PATCH_FILE" ]] || die "patch file not found: $PATCH_FILE"

# --- 0. is the phantom device even present? -----------------------------------
# Purely informational when building for another kernel.
PHANTOM=""
for d in /sys/class/input/input*; do
    [[ "$(cat "$d/name" 2>/dev/null)" == *"2808:5662"*UNKNOWN* ]] || continue
    PHANTOM="$d"
done
if [[ -n "$PHANTOM" ]]; then
    log "phantom device present: $(cat "$PHANTOM/name")"
elif [[ "$KVER" == "$(uname -r)" ]]; then
    warn "No '2808:5662 ... UNKNOWN' input device on this system."
    warn "Either the fix is already active, or this machine has a different"
    warn "touchscreen. Continuing anyway - the patch is a no-op if so."
fi

# --- 1. refuse if unsigned modules cannot load --------------------------------
if [[ -r /sys/kernel/security/lockdown ]] \
   && grep -qE '\[(integrity|confidentiality)\]' /sys/kernel/security/lockdown; then
    die "kernel lockdown is active - unsigned modules will not load.
    $(cat /sys/kernel/security/lockdown)
    Use the udev fallback instead: install ${RULES_FILE##*/} into /etc/udev/rules.d/"
fi
if grep -qE '\bmodule\.sig_enforce=1\b' /proc/cmdline; then
    die "module.sig_enforce=1 in /proc/cmdline - unsigned modules will not load."
fi

[[ -f "${BUILD_DIR}/Makefile" && -f "${BUILD_DIR}/Module.symvers" ]] \
    || die "kernel build dir incomplete: ${BUILD_DIR}
    install the matching linux-*-headers package and re-run."

# --- 2. fetch matching sources ------------------------------------------------
TAG="v${KVER%%-*}"
BASE_URL="https://raw.githubusercontent.com/gregkh/linux/${TAG}"

fetch() {
    local rel="$1" dest="$2" code
    code=$(curl -sSL --max-time 60 -o "$dest" -w '%{http_code}' "${BASE_URL}/${rel}")
    [[ "$code" == "200" ]] || die "fetch failed: ${BASE_URL}/${rel} (HTTP $code)"
}

log "fetching drivers/hid sources at tag ${TAG}"
fetch "drivers/hid/hid-multitouch.c" "${WORK}/hid-multitouch.c"
# hid-ids.h and hid-haptic.h live in drivers/hid/ and are not shipped in the
# headers package, so they have to come from the tree as well.
fetch "drivers/hid/hid-ids.h"        "${WORK}/hid-ids.h"
fetch "drivers/hid/hid-haptic.h"     "${WORK}/hid-haptic.h"

# Already merged upstream? Then the overlay is redundant.
if grep -qF 'Vendor-defined application collections carry raw firmware' \
        "${WORK}/hid-multitouch.c"; then
    log "in-tree hid-multitouch.c at ${TAG} already contains the fix."
    if [[ -f "$KO_OVERLAY" ]]; then
        log "removing redundant overlay $KO_OVERLAY"
        rm -f "$KO_OVERLAY"
        rmdir --ignore-fail-on-non-empty "$UPDATES_DIR" 2>/dev/null || true
        depmod -a "$KVER"
    fi
    exit 0
fi

# Skip the rebuild if our overlay is already in place.
if [[ -f "$KO_OVERLAY" ]]; then
    sv_o=$(modinfo -F srcversion "$KO_OVERLAY" 2>/dev/null || true)
    sv_i=$(modinfo -F srcversion "$KO_INTREE"  2>/dev/null || true)
    if [[ -n "$sv_o" && "$sv_o" != "$sv_i" ]]; then
        log "overlay already present with a srcversion different from the"
        log "in-tree module - assumed patched. Delete it and re-run to rebuild."
        exit 0
    fi
fi

# --- 3. patch and build -------------------------------------------------------
log "applying ${PATCH_FILE##*/}"
patch -p3 --no-backup-if-mismatch -d "$WORK" < "$PATCH_FILE" \
    || die "patch did not apply against ${TAG} - upstream layout drifted.
    Review .rej files in $WORK"

cat > "${WORK}/Makefile" <<EOF
obj-m += hid-multitouch.o
KDIR := ${BUILD_DIR}
PWD  := \$(shell pwd)
default:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) LLVM=1 LLVM_IAS=1 modules
EOF

log "building hid-multitouch.ko (LLVM toolchain)"
( cd "$WORK" && make ) 2>&1 | tail -6

BUILT="${WORK}/hid-multitouch.ko"
[[ -f "$BUILT" ]] || die "build did not produce ${BUILT}"

SV_BUILT=$( modinfo -F srcversion "$BUILT"     2>/dev/null || true)
SV_INTREE=$(modinfo -F srcversion "$KO_INTREE" 2>/dev/null || true)
[[ -z "$SV_INTREE" || "$SV_BUILT" != "$SV_INTREE" ]] \
    || die "built srcversion == in-tree srcversion (${SV_BUILT}) - the patch
    produced identical output. Refusing to install an indistinguishable module."

# --- 4. install ---------------------------------------------------------------
if [[ ! -f "$BACKUP" && -f "$KO_INTREE" ]]; then
    log "backing up ${KO_INTREE} -> ${BACKUP}"
    cp -a "$KO_INTREE" "$BACKUP"
fi

log "installing to ${KO_OVERLAY}"
install -d -m 0755 "$UPDATES_DIR"
zstd -19 -q --force "$BUILT" -o "${WORK}/${KO_NAME}"
install -m 0644 "${WORK}/${KO_NAME}" "$KO_OVERLAY"
depmod -a "$KVER"

RESOLVED=$(readlink -f "$(modinfo -F filename hid_multitouch 2>/dev/null)" 2>/dev/null || true)
if [[ "$RESOLVED" != "$(readlink -f "$KO_OVERLAY")" ]]; then
    warn "modinfo resolves hid_multitouch to $RESOLVED, expected $KO_OVERLAY."
    warn "depmod ordering may need investigation."
fi

# --- 5. activate --------------------------------------------------------------
if [[ "$KVER" != "$(uname -r)" ]]; then
    log "Built for $KVER, not the running kernel. It becomes active on reboot."
    exit 0
fi

log "reloading hid_multitouch (touchpad and touchscreen re-enumerate)"
if modprobe -r hid_multitouch 2>/dev/null && modprobe hid_multitouch; then
    LEFT=""
    for d in /sys/class/input/input*; do
        [[ "$(cat "$d/name" 2>/dev/null)" == *"2808:5662"*UNKNOWN* ]] && LEFT="$d"
    done
    if [[ -n "$LEFT" ]]; then
        die "phantom device is still present after the reload: $(cat "$LEFT/name")"
    fi
    log "phantom KEY_MICMUTE device is gone."
else
    warn "Could not reload the module now (device busy?). It will take effect"
    warn "on the next reboot."
fi

cat <<EOF

════════════════════════════════════════════════════════════════════
  Phantom KEY_MICMUTE device removed.

  Overlay: $KO_OVERLAY
  Backup of the in-tree module: $BACKUP
  (delete the overlay and re-run depmod -a to revert.)

  Verify - this should print nothing:
    grep -l UNKNOWN /sys/class/input/input*/name | xargs -r grep -H 2808

  Verify the real key still works - "Huawei WMI hotkeys" must still list
  event code 248 (KEY_MICMUTE), and Fn+F7 must still toggle the mic:
    sudo evtest /dev/input/by-path/platform-huawei-wmi-event

  Re-run this script after every kernel update.
════════════════════════════════════════════════════════════════════
EOF
