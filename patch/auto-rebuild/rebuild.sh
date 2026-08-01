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

DEFERRED=/usr/local/lib/honor-zqcp/deferred.sh

# Everything that needs the network or the pacman database has to run outside
# the transaction, so it is handed to a transient unit that waits for the
# database lock. Passing the work as a command line to systemd-run does not
# work: systemd expands $VAR in ExecStart itself and would eat the script's own
# variables, hence a real script file.
defer() {
    local unit="$1"; shift
    if [[ ! -x "$DEFERRED" ]]; then
        log "missing $DEFERRED - re-run patch/auto-rebuild/install.sh"
        return 1
    fi
    if ! command -v systemd-run >/dev/null; then
        log "systemd-run unavailable - run the installers by hand"
        return 1
    fi
    systemd-run --quiet --collect --unit="$unit" \
        --setenv=REPO="$REPO" --setenv=LOG="$LOG" "$@" \
        "$DEFERRED" "${unit##*-}" \
        || { log "could not schedule $unit"; return 1; }
}

case "$mode" in
modules)
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

    log "scheduling a rebuild for: ${!kvers[*]}"
    log "  progress: $LOG"
    defer honor-zqcp-rebuild-modules --setenv=KVERS="${!kvers[*]}"
    ;;

fingerprint)
    log "libfprint updated, re-applying the fingerprint patch in the background"
    log "  progress: $LOG"
    defer honor-zqcp-rebuild-fingerprint --setenv=BUILD_USER="$BUILD_USER"
    ;;

*)
    log "usage: ${0##*/} {modules|fingerprint}"
    ;;
esac

exit 0
