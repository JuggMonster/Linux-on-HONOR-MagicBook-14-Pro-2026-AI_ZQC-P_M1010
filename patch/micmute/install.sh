#!/usr/bin/env bash
# Build and install the HID-BPF fixup that removes the phantom KEY_MICMUTE
# device created from the FocalTech FTSC1000 touchscreen's vendor collection.
#
# See README.md in this directory for the root cause.
#
# Reruns are safe. Nothing here has to be repeated after a kernel update:
# the BPF object is CO-RE and libbpf relocates it against the running
# kernel's BTF.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/honor-ftsc1000-micmute.bpf.c"
OBJ_NAME="honor-ftsc1000-micmute.bpf.o"
INSTALL_DIR="/etc/udev-hid-bpf"
RULES_FILE="/etc/udev/rules.d/99-hid-bpf-honor-ftsc1000-micmute.rules"
KVER="$(uname -r)"
TAG="v${KVER%%-*}"
BASE_URL="https://raw.githubusercontent.com/gregkh/linux/${TAG}/drivers/hid/bpf/progs"
WORK=$(mktemp -d /var/tmp/honor-hidbpf-XXXXXX)

trap 'rm -rf "$WORK"' EXIT

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. prerequisites ---------------------------------------------------------
[[ -f "$SRC" ]] || die "source not found: $SRC"

for t in clang bpftool curl udev-hid-bpf udevadm; do
    command -v "$t" >/dev/null || die "missing required tool: $t
    Arch/CachyOS: pacman -S clang bpf udev-hid-bpf"
done

grep -q "^CONFIG_HID_BPF=y" <(zcat /proc/config.gz 2>/dev/null) \
    || warn "CONFIG_HID_BPF=y not confirmed in /proc/config.gz - continuing anyway."

[[ -r /sys/kernel/btf/vmlinux ]] \
    || die "/sys/kernel/btf/vmlinux missing - the kernel needs CONFIG_DEBUG_INFO_BTF=y."

log "kernel  = ${KVER}"
log "headers = ${TAG}"

# --- 2. fetch the kernel's BPF prog headers -----------------------------------
for h in hid_bpf.h hid_bpf_helpers.h hid_report_descriptor_helpers.h; do
    code=$(curl -sSL --max-time 60 -o "${WORK}/${h}" -w '%{http_code}' "${BASE_URL}/${h}")
    [[ "$code" == "200" ]] || die "fetch failed: ${BASE_URL}/${h} (HTTP $code)"
done
bpftool btf dump file /sys/kernel/btf/vmlinux format c > "${WORK}/vmlinux.h"

# --- 3. build -----------------------------------------------------------------
log "building ${OBJ_NAME}"
cp "$SRC" "${WORK}/"
clang -O2 -g -target bpf -mcpu=v3 -D__TARGET_ARCH_x86 \
      -I"$WORK" -Wno-missing-declarations \
      -c "${WORK}/$(basename "$SRC")" -o "${WORK}/${OBJ_NAME}" 2>&1 \
    | grep -vE "does not declare anything|^ *[0-9]+ \||^ +\^|In file included from|warnings? generated" \
    || true
[[ -f "${WORK}/${OBJ_NAME}" ]] || die "build produced no object"

udev-hid-bpf inspect "${WORK}/${OBJ_NAME}" >/dev/null \
    || die "udev-hid-bpf does not recognise the built object"

# --- 4. install ---------------------------------------------------------------
log "installing to ${INSTALL_DIR}/${OBJ_NAME}"
udev-hid-bpf install --force "${WORK}/${OBJ_NAME}" >/dev/null
udevadm control --reload

# --- 5. apply to the live device and verify -----------------------------------
DEV=""
for d in /sys/bus/hid/devices/*2808:5662*; do [[ -e "$d" ]] && DEV="$d"; done

if [[ -z "$DEV" ]]; then
    warn "No 2808:5662 HID device present. The fixup is installed and will be"
    warn "applied when the device appears."
    exit 0
fi

log "applying to ${DEV##*/}"
udevadm trigger --action=add --subsystem-match=hid "$DEV"
udevadm settle
sleep 1

PHANTOM=""
for d in /sys/class/input/input*; do
    [[ "$(cat "$d/name" 2>/dev/null)" == *"2808:5662"*UNKNOWN* ]] && PHANTOM="$d"
done
[[ -z "$PHANTOM" ]] || die "phantom device is still present: $(cat "$PHANTOM/name")"

log "phantom KEY_MICMUTE device is gone."

cat <<EOF

════════════════════════════════════════════════════════════════════
  Installed.

  BPF object : ${INSTALL_DIR}/${OBJ_NAME}
  udev rule  : ${RULES_FILE}

  Nothing to redo after a kernel update.

  Uninstall:
      sudo rm ${INSTALL_DIR}/${OBJ_NAME} ${RULES_FILE}
      sudo udevadm control --reload
      reboot

  Verify (must print nothing):
      grep -l UNKNOWN /sys/class/input/input*/name | xargs -r grep -H 2808
════════════════════════════════════════════════════════════════════
EOF
