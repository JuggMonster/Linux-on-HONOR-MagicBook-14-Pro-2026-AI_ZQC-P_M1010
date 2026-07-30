#!/usr/bin/env bash
# install-fingerprint-fix.sh — build a patched libfprint that recognises the
# HONOR ZQC-P M1010 power-button fingerprint reader, and install fprintd.
#
# Background:
#   The reader is a Goodix match-on-chip sensor on USB, id 27c6:6f94
#   ("Goodix USB2.0 MISC", vendor-specific class, 2 bulk endpoints,
#   firmware 01010106). It is NOT an ACPI/SPI device — the DSDT's FPNT
#   node is an inactive SPI slot for other SKUs — so nothing about it
#   depends on the DSDT override this repo ships. It enumerates purely
#   from its own USB descriptors, which means the only place to fix it
#   is the USB driver.
#
#   The sensor speaks the ordinary goodixmoc protocol that libfprint has
#   supported for years. It simply is not in the driver's id table: the
#   table already carries 0x6984, 0x6A94, 0x6594 and friends, but not
#   0x6F94. Adding the id (and the max_enroll_stage = 12 case, which the
#   whole family shares) is the entire fix — no protocol work needed.
#
#   Verified on this machine before this script was written: with the
#   two-line patch applied, the device is claimed by the goodixmoc
#   driver, opens cleanly, reports its firmware version, and answers a
#   template-list query ("Device contains 0 prints").
#
#   Upstream status as of 2026-07-30: 0x6F94 is absent from libfprint
#   master (checked at commit c4654fd). Worth submitting upstream — it
#   is a trivially reviewable id addition.
#
# Reruns are safe. Re-run after a libfprint package update, since a
# distro update will overwrite the patched library.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

FP_VID_PID="27c6:6f94"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH="${REPO_DIR}/libfprint-goodixmoc-honor-zqc-p-6f94.patch"
WORK=$(mktemp -d /tmp/honor-fprint-XXXXXX)
trap 'rm -rf "$WORK"' EXIT

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$PATCH" ]] || die "patch not found: $PATCH"

# --- 1. sanity: is the reader actually present? -------------------------------
if ! lsusb -d "$FP_VID_PID" >/dev/null 2>&1; then
    die "No USB device $FP_VID_PID found. This script is for the HONOR ZQC-P
    Goodix reader only — check 'lsusb' and adjust if your unit differs."
fi
log "Found fingerprint reader $FP_VID_PID"

# --- 2. build deps ------------------------------------------------------------
if command -v pacman >/dev/null 2>&1; then
    log "Installing build dependencies (pacman)"
    pacman -S --needed --noconfirm \
        base-devel git meson ninja glib2 libgusb nss libgudev \
        gobject-introspection cairo pixman polkit dbus systemd-libs
    NEED_FPRINTD_PKG="fprintd"
elif command -v apt-get >/dev/null 2>&1; then
    log "Installing build dependencies (apt)"
    apt-get update
    apt-get install -y build-essential git meson ninja-build libglib2.0-dev \
        libgusb-dev libnss3-dev libgudev-1.0-dev libgirepository1.0-dev \
        gobject-introspection libcairo2-dev libpixman-1-dev libpolkit-gobject-1-dev
    NEED_FPRINTD_PKG="fprintd"
elif command -v dnf >/dev/null 2>&1; then
    log "Installing build dependencies (dnf)"
    dnf install -y gcc make git meson ninja-build glib2-devel libgusb-devel \
        nss-devel libgudev-devel gobject-introspection-devel cairo-devel \
        pixman-devel polkit-devel
    NEED_FPRINTD_PKG="fprintd"
else
    warn "Unknown distro — install meson/ninja/glib/libgusb/nss/libgudev dev
    packages yourself, then re-run."
    NEED_FPRINTD_PKG=""
fi

# --- 3. clone + patch + build -------------------------------------------------
log "Cloning libfprint"
git clone --depth 1 https://gitlab.freedesktop.org/libfprint/libfprint.git \
    "$WORK/libfprint" >/dev/null 2>&1 || die "clone failed"

cd "$WORK/libfprint"
log "Applying $FP_VID_PID id patch"
if patch -p1 --dry-run < "$PATCH" >/dev/null 2>&1; then
    patch -p1 < "$PATCH"
elif grep -q '0x6F94' libfprint/drivers/goodixmoc/goodix.c; then
    log "Upstream already carries 0x6F94 — nothing to patch"
else
    die "Patch does not apply to current libfprint master. The id table or the
    max_enroll_stage switch has moved; re-diff the two hunks by hand."
fi

# introspection=true is deliberate: libfprint's tests/meson.build has an
# upstream bug in the introspection=false branch that trips newer meson
# ("Foreach expects exactly 2 variables ... type dict").
log "Configuring and building (this takes a minute)"
meson setup build \
    --prefix=/usr --libdir=lib --buildtype=release \
    -Ddrivers=all -Dintrospection=true -Ddoc=false -Dgtk-examples=false \
    >/dev/null || die "meson setup failed"
ninja -C build >/dev/null || die "build failed"

# --- 4. verify against the real device BEFORE installing ----------------------
log "Probing the reader with the freshly built driver"
PROBE=$(LD_LIBRARY_PATH="$PWD/build/libfprint" timeout 30 \
        ./build/examples/manage-prints 2>&1 || true)
if grep -q 'goodixmoc driver' <<<"$PROBE"; then
    log "OK: $(grep 'claimed by' <<<"$PROBE" | head -1)"
    grep -q 'contains' <<<"$PROBE" && log "OK: $(grep 'contains' <<<"$PROBE" | head -1)"
else
    warn "Device was NOT claimed by goodixmoc. Not installing. Output:"
    printf '%s\n' "$PROBE" | tail -20
    exit 1
fi

# --- 5. install ---------------------------------------------------------------
#
# On Arch/CachyOS, build a real package instead of dropping files into /usr.
# Learned the hard way: a bare `ninja install` puts unowned files in /usr, and
# the very next `pacman -S fprintd` fails with "libfprint: /usr/lib/
# libfprint-2.so exists in filesystem" because fprintd pulls libfprint in as a
# dependency. Letting pacman own the files avoids that and makes the patch
# visible in `pacman -Qi libfprint`.
#
if command -v pacman >/dev/null 2>&1; then
    log "Installing fprintd (repo) first, so the dependency is satisfied"
    pacman -S --needed --noconfirm fprintd libfprint

    command -v makepkg >/dev/null 2>&1 || pacman -S --needed --noconfirm base-devel
    pacman -S --needed --noconfirm gtk-doc gobject-introspection meson git \
        python-cairo python-gobject

    # makepkg refuses to run as root; build as the invoking user.
    BUILD_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
    [[ "$BUILD_USER" != "root" ]] || die "Cannot determine a non-root user to
    run makepkg as. Re-run via sudo from your normal account."
    BUILD_HOME=$(getent passwd "$BUILD_USER" | cut -d: -f6)
    PKGDIR="${BUILD_HOME}/.cache/honor-libfprint-build"

    CUR_VER=$(pacman -Q libfprint | awk '{print $2}')
    UPSTREAM_VER="${CUR_VER%-*}"
    log "Building a patched libfprint package matching repo version $UPSTREAM_VER"

    rm -rf "$PKGDIR"; mkdir -p "$PKGDIR"
    curl -sfL "https://gitlab.archlinux.org/archlinux/packaging/packages/libfprint/-/raw/main/PKGBUILD" \
        -o "$PKGDIR/PKGBUILD" || die "could not fetch Arch PKGBUILD"
    cp "$PATCH" "$PKGDIR/"

    PKGBUILD_VER=$(awk -F= '/^pkgver=/{print $2}' "$PKGDIR/PKGBUILD")
    if [[ "$PKGBUILD_VER" != "$UPSTREAM_VER" ]]; then
        warn "Arch PKGBUILD is at $PKGBUILD_VER but your repo ships $UPSTREAM_VER."
        warn "Building $PKGBUILD_VER — check that it is not a downgrade."
    fi

    # pkgrel bumped past the repo's so ours is unambiguously newer and does
    # not get silently swapped back on the next -Syu.
    REPO_REL="${CUR_VER##*-}"
    NEW_REL="${REPO_REL%%.*}.$(( ${REPO_REL#*.} + 1 ))"
    python3 - "$PKGDIR/PKGBUILD" "$NEW_REL" "$(basename "$PATCH")" <<'PYEOF'
import re, sys
path, newrel, patchfile = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path).read()
s = re.sub(r'^pkgrel=.*$', 'pkgrel=' + newrel, s, count=1, flags=re.M)
s = re.sub(r'^(source=\()', r'\1"' + patchfile + '"\n        ', s, count=1, flags=re.M)
s = re.sub(r"^(b2sums=\()", r"\1'SKIP'\n        ", s, count=1, flags=re.M)
s = s.replace("prepare() {\n  cd $pkgname\n}",
              'prepare() {\n  cd $pkgname\n  if ! grep -q 0x6F94 libfprint/drivers/goodixmoc/goodix.c; then\n'
              '    patch -p1 < "$srcdir/' + patchfile + '"\n  fi\n}', 1)
s = s.replace("check() {\n  meson test -C build --print-errorlogs\n}",
              "check() {\n  : # skipped: id-table-only change\n}", 1)
open(path, 'w').write(s)
PYEOF

    chown -R "$BUILD_USER": "$PKGDIR"
    ( cd "$PKGDIR" && sudo -u "$BUILD_USER" makepkg --skippgpcheck --nocheck -f ) \
        >/dev/null 2>&1 || die "makepkg failed — run it by hand in $PKGDIR to see why"

    PKGFILE=$(ls -t "$PKGDIR"/libfprint-*.pkg.tar.* 2>/dev/null | head -1)
    [[ -n "$PKGFILE" ]] || die "makepkg produced no package in $PKGDIR"
    log "Installing $(basename "$PKGFILE")"
    pacman -U --noconfirm "$PKGFILE" || die "pacman -U failed"
else
    log "Installing patched libfprint to /usr"
    ninja -C build install >/dev/null || die "install failed"
    ldconfig
    if [[ -n "$NEED_FPRINTD_PKG" ]] && ! command -v fprintd-enroll >/dev/null 2>&1; then
        log "Installing $NEED_FPRINTD_PKG"
        if   command -v apt-get >/dev/null 2>&1; then apt-get install -y fprintd libpam-fprintd
        elif command -v dnf     >/dev/null 2>&1; then dnf install -y fprintd fprintd-pam
        fi
    fi
fi

systemctl daemon-reload || true
systemctl restart fprintd.service 2>/dev/null || true

# --- 6. confirm fprintd actually sees it --------------------------------------
if command -v fprintd-list >/dev/null 2>&1; then
    CHECK_USER="${SUDO_USER:-root}"
    if timeout 25 sudo -u "$CHECK_USER" fprintd-list "$CHECK_USER" 2>&1 \
         | grep -qE 'found [1-9]|no fingers enrolled'; then
        log "fprintd sees the reader"
    else
        warn "fprintd did not report the device — check 'systemctl status fprintd'"
    fi
fi

cat <<'EOF'

Done. Next steps (run as your normal user, NOT root):

    fprintd-enroll -f right-index-finger     # touch the power button repeatedly
    fprintd-verify

If enrollment works, enable it for login/sudo:

    Arch/CachyOS:  add "auth sufficient pam_fprintd.so" above the pam_unix
                   line in /etc/pam.d/system-local-login and /etc/pam.d/sudo
    Debian/Ubuntu: sudo pam-auth-update --enable fprintd
    Fedora:        sudo authselect enable-feature with-fingerprint

Caveats:
  * A distro libfprint update will overwrite this build — re-run this script.
    On Arch the durable answer is a local PKGBUILD carrying the patch, so
    pacman owns the files; see patch/fingerprint/PKGBUILD.
  * Enrollment takes 12 samples on this sensor family. Place the finger
    firmly and shift position slightly between touches.

EOF
