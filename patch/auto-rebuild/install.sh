#!/usr/bin/env bash
# Install pacman hooks that re-apply the fixes a package update would revert.
#
# See README.md in this directory for what is fragile and why.
#
# Reruns are safe.

set -euo pipefail

if (( EUID != 0 )); then
    echo "Must be run as root. Use: sudo bash $0" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LIB_DIR="/usr/local/lib/honor-zqcp"
HOOK_DIR="/etc/pacman.d/hooks"
CONF="/etc/honor-zqcp-autorebuild.conf"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

command -v pacman >/dev/null \
    || die "This machine does not use pacman. The hooks only work on Arch-like
    systems; on others, re-run the installers in patch/headset-mic/ and
    patch/sof-audio/ after each kernel update by hand."

[[ -d "${REPO}/patch" ]] || die "cannot locate the repository from ${SCRIPT_DIR}"

# The fingerprint rebuild has to run makepkg, which refuses to run as root.
BUILD_USER="${SUDO_USER:-$(logname 2>/dev/null || true)}"
if [[ -z "$BUILD_USER" || "$BUILD_USER" == "root" ]]; then
    warn "Cannot determine a non-root user for makepkg. The libfprint hook will"
    warn "be installed but the fingerprint rebuild will fail until you set"
    warn "BUILD_USER in ${CONF} by hand."
    BUILD_USER="root"
fi

log "repository = ${REPO}"
log "build user = ${BUILD_USER}"

install -d -m 0755 "$LIB_DIR" "$HOOK_DIR"
install -m 0755 "${SCRIPT_DIR}/rebuild.sh" "${LIB_DIR}/rebuild.sh"
install -m 0644 "${SCRIPT_DIR}/95-honor-zqcp-kernel-modules.hook" "$HOOK_DIR/"
install -m 0644 "${SCRIPT_DIR}/96-honor-zqcp-libfprint.hook"      "$HOOK_DIR/"

cat > "$CONF" <<EOF
# Written by patch/auto-rebuild/install.sh. Read by
# /usr/local/lib/honor-zqcp/rebuild.sh, which the pacman hooks in
# /etc/pacman.d/hooks/ invoke.
REPO=${REPO}
BUILD_USER=${BUILD_USER}
EOF
chmod 0644 "$CONF"

cat <<EOF

════════════════════════════════════════════════════════════════════
  Auto-rebuild hooks installed.

  ${HOOK_DIR}/95-honor-zqcp-kernel-modules.hook
  ${HOOK_DIR}/96-honor-zqcp-libfprint.hook
  ${LIB_DIR}/rebuild.sh
  ${CONF}

  From now on a kernel update rebuilds patch/headset-mic/ and
  patch/sof-audio/ for the new kernel automatically, and a libfprint
  update re-applies patch/fingerprint/ shortly after the transaction.

  Log: /var/log/honor-zqcp-autorebuild.log

  The repository must stay at ${REPO}. If you move it, re-run this
  script, or edit REPO in ${CONF}.

  Dry run without waiting for an update:
      echo | sudo ${LIB_DIR}/rebuild.sh modules

  Uninstall:
      sudo rm ${HOOK_DIR}/9[56]-honor-zqcp-*.hook \\
              ${LIB_DIR}/rebuild.sh ${CONF}
════════════════════════════════════════════════════════════════════
EOF
