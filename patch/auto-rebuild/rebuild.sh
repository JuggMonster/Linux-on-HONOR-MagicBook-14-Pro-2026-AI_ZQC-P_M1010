#!/usr/bin/env bash
# Re-applies the fixes that a package update would otherwise revert.
#
# Installed to /usr/local/lib/honor-zqcp/rebuild.sh and invoked by the pacman
# hooks in this directory. Never fails a transaction: every problem is reported
# and the script still exits 0.
#
# Modes:
#   modules      rebuild the kernel-module fixes for the kernels named on stdin
#                (pacman passes the changed paths), or for every installed
#                kernel that has headers when stdin is empty
#   fingerprint  re-apply the libfprint patch once pacman has released its lock

set -uo pipefail

CONF=/etc/honor-zqcp-autorebuild.conf
LOG=/var/log/honor-zqcp-autorebuild.log

log() { printf '  [honor-zqcp] %s\n' "$*"; }

if [[ ! -r "$CONF" ]]; then
    log "no $CONF - nothing to do"
    exit 0
fi
# shellcheck source=/dev/null
. "$CONF"

REPO="${REPO:-}"
BUILD_USER="${BUILD_USER:-root}"

if [[ -z "$REPO" || ! -d "$REPO/patch" ]]; then
    log "repository not found at '${REPO}' - re-run patch/auto-rebuild/install.sh"
    exit 0
fi

# Exit code 3 from an installer means "this fix does not apply to that kernel",
# which is a normal outcome, not a failure.
run_fix() {
    local name="$1" kver="$2" rc=0
    log "rebuilding ${name} for ${kver}"
    KVER="$kver" bash "${REPO}/patch/${name}/install.sh" >>"$LOG" 2>&1 || rc=$?
    case "$rc" in
        0) log "  ok" ;;
        3) log "  not applicable to this kernel, skipped" ;;
        *) log "  FAILED - see $LOG, then run: sudo KVER=${kver} bash ${REPO}/patch/${name}/install.sh" ;;
    esac
}

mode="${1:-}"

case "$mode" in
modules)
    { echo; echo "=== $(date -Is) modules ==="; } >>"$LOG"

    declare -A kvers=()
    while read -r target; do
        [[ "$target" =~ ^/?usr/lib/modules/([^/]+)/ ]] && kvers["${BASH_REMATCH[1]}"]=1
    done

    if (( ${#kvers[@]} == 0 )); then
        for d in /usr/lib/modules/*/; do
            [[ -e "${d}build/Makefile" ]] && kvers["$(basename "$d")"]=1
        done
    fi

    if (( ${#kvers[@]} == 0 )); then
        log "no kernels to rebuild for"
        exit 0
    fi

    for k in "${!kvers[@]}"; do
        if [[ ! -e "/usr/lib/modules/${k}/build/Makefile" ]]; then
            log "no kernel headers for ${k} - skipping"
            log "  install linux-*-headers for it, then run: sudo KVER=${k} bash ${REPO}/apply_patch.sh"
            continue
        fi
        run_fix headset-mic "$k"
        run_fix sof-audio   "$k"
    done
    ;;

fingerprint)
    # The libfprint fix builds a package and installs it with pacman -U, which
    # cannot happen inside a transaction. Defer it to a transient unit that
    # waits for the database lock to clear.
    if ! command -v systemd-run >/dev/null; then
        log "libfprint was updated - the fingerprint patch is gone."
        log "  re-apply it with: sudo bash ${REPO}/patch/fingerprint/install.sh"
        exit 0
    fi
    log "libfprint updated - re-applying the fingerprint patch in the background"
    log "  progress: $LOG"
    systemd-run --quiet --collect --unit=honor-zqcp-fingerprint-rebuild \
        --setenv=SUDO_USER="$BUILD_USER" \
        /bin/bash -c "
            { echo; echo '=== '\$(date -Is)' fingerprint ==='; } >>'$LOG'
            for _ in \$(seq 1 120); do
                [[ -e /var/lib/pacman/db.lck ]] || break
                sleep 5
            done
            bash '${REPO}/patch/fingerprint/install.sh' >>'$LOG' 2>&1 \
                || echo 'fingerprint rebuild FAILED' >>'$LOG'
        " || log "  could not schedule the rebuild - run the installer by hand"
    ;;

*)
    log "usage: ${0##*/} {modules|fingerprint}"
    ;;
esac

exit 0
