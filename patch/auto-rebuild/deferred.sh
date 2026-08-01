#!/usr/bin/env bash
# Does the work that cannot run inside a pacman transaction.
#
# Started by /usr/local/lib/honor-zqcp/rebuild.sh through systemd-run, so it
# runs outside the transaction with a normal environment: the pacman database
# is unlocked (needed by the fingerprint package build) and the network is
# reachable (needed by every installer, which fetches its sources from the
# matching kernel tag).
#
# Reads: REPO, LOG, and either KVERS (modules) or BUILD_USER (fingerprint).

set -uo pipefail

REPO="${REPO:?}"
LOG="${LOG:-/var/log/honor-zqcp-autorebuild.log}"
mode="${1:-}"

w() { printf '%s %s\n' "$(date -Is)" "$*" >>"$LOG"; }

wait_for_pacman() {
    local i
    for ((i = 0; i < 120; i++)); do
        [[ -e /var/lib/pacman/db.lck ]] || return 0
        sleep 5
    done
    w "pacman database still locked after 10 minutes, giving up"
    return 1
}

case "$mode" in
modules)
    w "=== deferred module rebuild: ${KVERS:-none} ==="
    wait_for_pacman || exit 0
    for k in ${KVERS:-}; do
        if [[ ! -e "/usr/lib/modules/${k}/build/Makefile" ]]; then
            w "${k}: no kernel headers, skipped"
            continue
        fi
        for fix in headset-mic sof-audio; do
            rc=0
            KVER="$k" bash "${REPO}/patch/${fix}/install.sh" >>"$LOG" 2>&1 || rc=$?
            case "$rc" in
                0) w "${fix} ${k}: ok" ;;
                3) w "${fix} ${k}: not applicable to this kernel, skipped" ;;
                *) w "${fix} ${k}: FAILED (rc=${rc}), run: sudo KVER=${k} bash ${REPO}/patch/${fix}/install.sh" ;;
            esac
        done
    done
    w "=== deferred module rebuild done ==="
    ;;

fingerprint)
    w "=== deferred fingerprint rebuild ==="
    wait_for_pacman || exit 0
    rc=0
    SUDO_USER="${BUILD_USER:-root}" bash "${REPO}/patch/fingerprint/install.sh" >>"$LOG" 2>&1 || rc=$?
    if (( rc == 0 )); then
        w "fingerprint: ok"
    else
        w "fingerprint: FAILED (rc=${rc}), run: sudo bash ${REPO}/patch/fingerprint/install.sh"
    fi
    ;;

*)
    w "deferred: unknown mode '${mode}'"
    ;;
esac

exit 0
