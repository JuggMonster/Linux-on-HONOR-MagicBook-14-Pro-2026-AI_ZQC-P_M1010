#!/usr/bin/env bash
# Build and install the HID-BPF program that turns the touchpad's left-edge
# slide into brightness keys.
#
# See README.md in this directory for what the gesture actually sends and why
# a report descriptor fixup is not enough.
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
SRC="${SCRIPT_DIR}/honor-tops0102-edge.bpf.c"
OBJ_NAME="honor-tops0102-edge.bpf.o"
INSTALL_DIR="/etc/udev-hid-bpf"
RULES_FILE="/etc/udev/rules.d/99-hid-bpf-honor-tops0102-edge.rules"
KVER="$(uname -r)"
TAG="v${KVER%%-*}"
BASE_URL="https://raw.githubusercontent.com/gregkh/linux/${TAG}/drivers/hid/bpf/progs"
WORK=$(mktemp -d /var/tmp/honor-edge-XXXXXX)

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

# hid_bpf_try_input_report() is what makes this work without a daemon. It is
# the non-sleepable injection kfunc, so it can be called from the device event
# hook; the sleepable hid_bpf_input_report() cannot.
grep -qa 'hid_bpf_try_input_report' /sys/kernel/btf/vmlinux \
    || warn "hid_bpf_try_input_report not found in the kernel BTF.
    On a kernel without it the program will fail to load."

log "kernel  = ${KVER}"
log "headers = ${TAG}"

# --- 2. fetch the kernel's BPF prog headers -----------------------------------
# hid_bpf_helpers.h includes hid_report_descriptor_helpers.h, so all three are
# needed even though this program does not touch the descriptor.
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

# --- 5. apply to the live device ----------------------------------------------
DEV=""
for d in /sys/bus/hid/devices/*27C6:0F9A*; do [[ -e "$d" ]] && DEV="$d"; done

if [[ -z "$DEV" ]]; then
    warn "No 27C6:0F9A touchpad present. The program is installed and will be"
    warn "attached when the device appears."
    exit 0
fi

log "attaching to ${DEV##*/}"
udev-hid-bpf remove "$DEV" >/dev/null 2>&1 || true
sleep 1
udev-hid-bpf add "$DEV" "${INSTALL_DIR}/${OBJ_NAME}" >/dev/null 2>&1 || true
sleep 1

udev-hid-bpf list-loaded 2>/dev/null | grep -q 'honor_tops0102' \
    || die "the program is not attached to the device"

log "attached"

cat <<EOF

════════════════════════════════════════════════════════════════════
  Installed.

  BPF object : ${INSTALL_DIR}/${OBJ_NAME}
  udev rule  : ${RULES_FILE}

  Slide along the LEFT edge of the touchpad to change brightness.
  The right edge already changes volume through the EC and is untouched.

  Nothing to redo after a kernel update.

  Verify:
      sudo udev-hid-bpf list-loaded | grep honor_tops0102
      sudo evtest /dev/input/event\$(...)   # Consumer Control device
      # or simply watch the value while sliding:
      watch -n0.2 cat /sys/class/backlight/intel_backlight/brightness

  Uninstall:
      sudo rm ${INSTALL_DIR}/${OBJ_NAME} ${RULES_FILE}
      sudo udevadm control --reload
      reboot
════════════════════════════════════════════════════════════════════
EOF
