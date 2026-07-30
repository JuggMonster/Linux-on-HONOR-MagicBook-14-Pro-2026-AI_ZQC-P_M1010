#!/usr/bin/env bash
# install-fan-hwmon.sh — build and install honor-zqcp-hwmon, exposing the
# HONOR ZQC-P M1010 EC fan tachometers to lm_sensors / hwmon consumers.
#
# Background:
#   This machine has no fan RPM readout under Linux. The ACPI fan participant
#   (INTC10D6, hwmon "acpi_fan") registers a fan1_input but reading it returns
#   -ENODEV, because the firmware's _FST is a stub. The real tachometers live
#   in EC RAM as two 16-bit little-endian words:
#
#       0x2C/0x2D -> fan 0        0x2E/0x2F -> fan 1
#
#   Measured on this unit: ~2280 / ~2000 rpm at 48 degC idle, and 3656 / 3276
#   rpm at 89 degC under a sustained compile. The same offsets were confirmed
#   independently on the sibling FMB-P (colorcube PR #21). Note this corrects
#   an earlier reading of these bytes as "PWM duty + status flag" — the DSDT
#   splits each word into two named 8-bit fields (FA0L/FA0R), which is what
#   caused the confusion.
#
#   READ-ONLY, deliberately. Fan speed on this machine is EC-autonomous and
#   cannot be driven from the OS:
#     * SFNS (manual fan duty via WMI) is gated on the EC's MFGM master flag,
#       which no AML path ever sets;
#     * the DPTF fan participant TFN1 (/sys/class/thermal/cooling_device0,
#       51 states) accepts cur_state writes but the EC ignores them —
#       verified: 0 -> 50 produced no tachometer change at all.
#   So this module reports; it does not control. See README for the full
#   discussion of why the fans feel "lazy" versus Windows PC Manager.
#
# Reruns are safe. With dkms the module is rebuilt automatically on kernel
# updates; without dkms you must re-run this after every kernel update.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

MODNAME="honor-zqcp-hwmon"
MODVER="1.0"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Override with KVER=... to build for a kernel other than the running one -
# needed when a kernel update is installed but not yet booted, since the
# headers for the running kernel are gone at that point.
KVER="${KVER:-$(uname -r)}"
KDIR="/lib/modules/${KVER}/build"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. DMI gate --------------------------------------------------------------
VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
if [[ "$VENDOR" != "HONOR" || "$PRODUCT" != "ZQC-P" ]]; then
    die "This machine reports '$VENDOR / $PRODUCT', not 'HONOR / ZQC-P'.
    The EC offsets are model-specific driver knowledge — refusing to install."
fi
log "DMI matches HONOR ZQC-P"

# --- 2. kernel headers --------------------------------------------------------
if [[ ! -d "$KDIR" ]]; then
    # Very common case on a rolling distro: a kernel update is installed but
    # not yet booted, so the running kernel's headers package has already been
    # replaced. Detect that and point at the installed kernel instead of
    # blindly pulling in some unrelated -headers package.
    OTHER=""
    for d in /usr/lib/modules/*/; do
        [[ -e "${d}build" ]] || continue
        OTHER+=" $(basename "$d")"
    done
    if [[ -n "$OTHER" ]]; then
        warn "No headers for the running kernel ($KVER)."
        warn "Kernels that DO have headers:${OTHER}"
        warn ""
        warn "If one of those is a newer version of the same kernel, you have a"
        warn "pending reboot. Either reboot and re-run this script, or build for"
        warn "the installed kernel now so it is ready after the reboot:"
        warn ""
        warn "    sudo KVER=<version-from-the-list-above> bash \$0"
        die "Refusing to guess which kernel you meant."
    fi

    log "Kernel headers missing for $KVER — installing"
    if command -v pacman >/dev/null 2>&1; then
        # Arch/CachyOS: the headers package name tracks the kernel package
        # that owns this kernel's module tree.
        KPKG=$(pacman -Qoq "/usr/lib/modules/${KVER}/vmlinuz" 2>/dev/null | head -1 || true)
        [[ -n "$KPKG" ]] || die "Cannot tell which package owns kernel $KVER.
    Install its -headers package by hand, then re-run."
        pacman -S --needed --noconfirm "${KPKG}-headers" base-devel
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y "linux-headers-${KVER}" build-essential
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "kernel-devel-${KVER}" gcc make
    else
        die "Install kernel headers for $KVER yourself, then re-run."
    fi
fi
[[ -d "$KDIR" ]] || die "Kernel headers still missing at $KDIR"
log "Kernel headers present for $KVER"

# --- 3. install via dkms if available, else plain out-of-tree build -----------
if command -v dkms >/dev/null 2>&1; then
    DEST="/usr/src/${MODNAME}-${MODVER}"
    log "Installing via DKMS to $DEST"
    dkms remove -m "$MODNAME" -v "$MODVER" --all >/dev/null 2>&1 || true
    rm -rf "$DEST"
    install -d "$DEST"
    install -m 644 "$SRC_DIR/honor-zqcp-hwmon.c" "$SRC_DIR/Makefile" \
                   "$SRC_DIR/dkms.conf" "$DEST/"
    # -k is required: dkms otherwise targets the running kernel, which is the
    # wrong one when we are pre-building for a not-yet-booted kernel update.
    dkms add     -m "$MODNAME" -v "$MODVER"
    dkms build   -m "$MODNAME" -v "$MODVER" -k "$KVER"
    dkms install -m "$MODNAME" -v "$MODVER" -k "$KVER"
else
    warn "dkms not installed — building out-of-tree. You will need to re-run
    this script after every kernel update. Install dkms to avoid that."
    WORK=$(mktemp -d /tmp/honor-fan-XXXXXX)
    trap 'rm -rf "$WORK"' EXIT
    cp "$SRC_DIR/honor-zqcp-hwmon.c" "$SRC_DIR/Makefile" "$WORK/"
    make -C "$KDIR" M="$WORK" modules >/dev/null || die "build failed"
    install -d "/lib/modules/${KVER}/updates"
    install -m 644 "$WORK/${MODNAME}.ko" "/lib/modules/${KVER}/updates/"
    depmod -a "$KVER"
fi

# --- 4. load + verify ---------------------------------------------------------
echo "${MODNAME}" > /etc/modules-load.d/honor-zqcp-hwmon.conf
log "Enabled at boot via /etc/modules-load.d/honor-zqcp-hwmon.conf"

if [[ "$KVER" != "$(uname -r)" ]]; then
    log "Built for $KVER, which is not the running kernel ($(uname -r))."
    log "It will load automatically after you reboot into $KVER. Nothing else to do."
    exit 0
fi

modprobe -r "$MODNAME" 2>/dev/null || true
modprobe "$MODNAME" || die "modprobe failed — see 'dmesg | tail'"

FOUND=""
for d in /sys/class/hwmon/hwmon*; do
    [[ "$(cat "$d/name" 2>/dev/null)" == "honor_zqcp" ]] || continue
    FOUND="$d"
    break
done

if [[ -z "$FOUND" ]]; then
    die "Module loaded but no honor_zqcp hwmon node appeared. Check 'dmesg | tail'."
fi

log "hwmon node: $FOUND"
for f in "$FOUND"/fan*_input; do
    lbl_file="${f%_input}_label"
    printf '    %-12s %s rpm\n' \
        "$(cat "$lbl_file" 2>/dev/null || basename "$f")" "$(cat "$f")"
done

cat <<'EOF'

Done. Fan speeds now show up in:

    sensors                # lm_sensors, under "honor_zqcp-isa-0000"
    btop / KDE sensors / GNOME extensions — anything reading hwmon

Remember: this is a read-only tachometer. The EC owns the fan curve and
ignores every OS-side control path on this machine — see patch/fan/README.md
for the measured fan behaviour and which control paths were tested.

EOF
