#!/usr/bin/env bash
# install-alc269-fix.sh — fetch the running kernel's alc269.c from the
# upstream stable tree, apply our one-line SND_PCI_QUIRK addition for
# HONOR ZQC-P M1010 (PCI SSID 1ee7:209d), build the codec module
# out-of-tree against the installed kernel headers, and drop the
# resulting snd-hda-codec-alc269.ko.zst over the in-tree one. The
# original is backed up so uninstall_patch.sh can restore it.
#
# This is a workaround for as long as the upstream patch under
# patch/alc269-honor-zqc-p-m1010.patch has not yet landed in the kernel
# being used. Once the entry is in
# the running kernel's alc269.c, this script becomes a no-op (it will
# detect the existing entry and skip the rebuild).
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
MODULES_DIR="/usr/lib/modules/${KVER}/kernel/sound/hda/codecs/realtek"
KO_NAME="snd-hda-codec-alc269.ko.zst"
KO_PATH="${MODULES_DIR}/${KO_NAME}"
BACKUP="/root/${KO_NAME}.orig"
WORK=$(mktemp -d /tmp/alc269-fix-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

req() { command -v "$1" >/dev/null || { echo "missing required tool: $1" >&2; exit 1; }; }
req curl
req zstdcat
req zstd
req make
req clang
req depmod
req modprobe
req strings
# alsa-tools (hda-verb) is needed by the jack-sense helper service.
# Build can proceed without it, but the service won't function — warn.
if ! command -v hda-verb >/dev/null; then
    echo "[warn] hda-verb not found (alsa-tools package). The honor-mic-jack-init"
    echo "       service will be installed but won't be able to fire EXECUTE_PIN_SENSE"
    echo "       after boot. Install alsa-tools to get full functionality."
fi

echo "[*] kernel = ${KVER}"
echo "[*] target = ${KO_PATH}"

# Remove the previous-iteration systemd workaround if it's still installed.
# It was a userspace hotfix for the same problem this kernel fixup now
# solves at the source; keeping it active would pointlessly fire an extra
# hda-verb on every boot/resume.
remove_legacy_jack_service() {
    if systemctl list-unit-files honor-mic-jack-init.service >/dev/null 2>&1 \
       && systemctl is-enabled honor-mic-jack-init.service >/dev/null 2>&1; then
        echo "[*] removing legacy honor-mic-jack-init.service (no longer needed — fixed in kernel)"
        systemctl disable --now honor-mic-jack-init.service >/dev/null 2>&1 || true
    fi
    rm -f /etc/systemd/system/honor-mic-jack-init.service \
          /usr/local/bin/honor-mic-jack-init.sh
    systemctl daemon-reload 2>/dev/null || true
}

# Detect if the in-tree module already has our quirk (e.g. a future kernel
# update has merged the upstream patch). In that case skip the rebuild.
# Wrap in subshell because `grep -q` closes its stdin on first match, which
# SIGPIPEs zstdcat → with `set -o pipefail` the pipeline would return failure
# and we'd needlessly rebuild.
has_quirk() {
    [[ -f "$1" ]] || return 1
    ( set +o pipefail; zstdcat "$1" 2>/dev/null | grep -aqF $'\xe7\x1e\x9d\x20' )
}
if has_quirk "$KO_PATH"; then
    echo "[ok] in-tree alc269 already contains the ZQC-P quirk — nothing to do."
    remove_legacy_jack_service
    exit 0
fi

# Verify build infrastructure is present.
if [[ ! -f "${BUILD_DIR}/Makefile" || ! -f "${BUILD_DIR}/Module.symvers" ]]; then
    echo "[fatal] kernel build dir incomplete: ${BUILD_DIR}" >&2
    echo "        install the matching linux-*-headers package and re-run."
    exit 1
fi
if [[ ! -d "${BUILD_DIR}/sound/hda/codecs/realtek" ]]; then
    echo "[fatal] ${BUILD_DIR}/sound/hda/codecs/realtek missing" >&2
    echo "        the kernel headers package does not expose the sound/hda subtree;"
    echo "        a different distro / kernel layout is needed to rebuild this module."
    exit 1
fi

# Fetch upstream sources matching the running kernel's tag. The gregkh
# stable-tree mirror on GitHub exposes raw files at tag-based paths.
TAG="v${KVER%%-*}"
BASE_URL="https://raw.githubusercontent.com/gregkh/linux/${TAG}"

fetch() {
    local rel="$1" dest="$2"
    local code
    code=$(curl -sSL --max-time 60 -o "$dest" -w '%{http_code}' "${BASE_URL}/${rel}")
    if [[ "$code" != "200" ]]; then
        echo "[fatal] fetch failed: ${BASE_URL}/${rel} (HTTP $code)" >&2
        exit 1
    fi
}

echo "[*] fetching sources at tag ${TAG}"
mkdir -p "${WORK}/helpers"
fetch "sound/hda/codecs/realtek/alc269.c"          "${WORK}/alc269.c"
fetch "sound/hda/codecs/realtek/realtek.h"         "${WORK}/realtek.h"
fetch "sound/hda/codecs/generic.h"                 "${WORK}/generic.h"
fetch "sound/hda/codecs/side-codecs/hda_component.h" "${WORK}/hda_component.h"
fetch "sound/hda/common/hda_local.h"               "${WORK}/hda_local.h"
fetch "sound/hda/common/hda_auto_parser.h"         "${WORK}/hda_auto_parser.h"
fetch "sound/hda/common/hda_beep.h"                "${WORK}/hda_beep.h"
fetch "sound/hda/common/hda_jack.h"                "${WORK}/hda_jack.h"
for f in thinkpad ideapad_hotkey_led hp_x360 ideapad_s740; do
    fetch "sound/hda/codecs/helpers/${f}.c"        "${WORK}/helpers/${f}.c"
done

# Flatten the source-tree include paths so we don't need to mirror the
# full sound/hda subtree.
sed -i 's|#include "../helpers/|#include "helpers/|g'                   "${WORK}/alc269.c"
sed -i 's|#include "../generic.h"|#include "generic.h"|g; s|#include "../side-codecs/hda_component.h"|#include "hda_component.h"|g' "${WORK}/realtek.h"

# Apply our quirk.
#
# We do NOT use the simple ALC2XX_FIXUP_HEADSET_MIC the way BRB-X M1010
# does. That fixup's pincfg `0x03a1103c` has JACK_DETECT_OVERRIDE=0
# (use the codec's real impedance detection) and only handles
# HDA_FIXUP_ACT_PRE_PROBE — it never invokes the codec's headset-mode
# probe/init paths. On the ZQC-P PCB this leaves pin 0x19 in a state
# where GET_PIN_SENSE returns 0 after boot/suspend until the user
# physically unplugs and replugs the jack: the SOF DSP capture pathway
# is never activated and recording from `pcm0c HDA Analog` is silent.
#
# Instead we add a new fixup `ALC256_FIXUP_HONOR_ZQC_P_M1010_MIC` that:
#   1. Sets pin 0x19 to `0x01a1913c` (JACK_DETECT_OVERRIDE=1, "always
#      present, ignore the impedance circuit"); same pattern many other
#      Realtek/HONOR/Dell quirks use ("use as headset mic, without its
#      own jack detect"). This bypasses the unreliable hardware detect
#      on this PCB.
#   2. Chains to `ALC269_FIXUP_HEADSET_MODE_NO_HP_MIC`. That existing
#      kernel fixup calls `alc_fixup_headset_mode_no_hp_mic` →
#      `alc_fixup_headset_mode` which handles PRE_PROBE (parse flag),
#      PROBE (`alc_probe_headset_mode`) AND INIT
#      (`alc_update_headset_mode`, run on every codec init including
#      after S3/S4 resume). This is the piece our previous one-line
#      patch was missing.
#
# After this fixup the headset mic works out of the box across cold
# boot, warm reboot and suspend/resume cycles, with no need for any
# userspace daemon or hda-verb tricks.
if grep -q 'ALC256_FIXUP_HONOR_ZQC_P_M1010_MIC' "${WORK}/alc269.c"; then
    echo "[ok] upstream already has the ZQC-P fixup — building unmodified."
else
    python3 <<PYEOF
src_path = "${WORK}/alc269.c"
with open(src_path) as f:
    src = f.read()

# 1. Add new enum value right after ALC2XX_FIXUP_HEADSET_MIC.
enum_marker = "\tALC2XX_FIXUP_HEADSET_MIC,\n"
enum_add    = "\tALC256_FIXUP_HONOR_ZQC_P_M1010_MIC,\n"
if enum_marker not in src:
    raise SystemExit("could not find ALC2XX_FIXUP_HEADSET_MIC enum entry")
src = src.replace(enum_marker, enum_marker + enum_add, 1)

# 2. Add fixup table entry right after the ALC2XX_FIXUP_HEADSET_MIC body.
#    We use a PINS-only fixup chained to the existing
#    ALC269_FIXUP_HEADSET_MODE_NO_HP_MIC, which gives us the canonical
#    PRE_PROBE + PROBE + INIT (incl. S3/S4 resume) headset-mode lifecycle.
#
#    Note: a "mic-mute LED should follow the analog capture switch as
#    well as the DMIC one" change would belong in SOF / wireplumber
#    plumbing, not in this quirk table — analog Capture Switch toggles
#    on this hardware don't go through hda_generic's mic-mute hook
#    because the audio chain is owned by the SOF DSP. We're not trying
#    to solve that in alc269.c.
body_marker = "\t[ALC2XX_FIXUP_HEADSET_MIC] = {\n\t\t.type = HDA_FIXUP_FUNC,\n\t\t.v.func = alc2xx_fixup_headset_mic,\n\t},\n"
body_add = (
    "\t[ALC256_FIXUP_HONOR_ZQC_P_M1010_MIC] = {\n"
    "\t\t.type = HDA_FIXUP_PINS,\n"
    "\t\t.v.pins = (const struct hda_pintbl[]) {\n"
    "\t\t\t{ 0x19, 0x01a1913c }, /* use as headset mic, without its own jack detect */\n"
    "\t\t\t{ }\n"
    "\t\t},\n"
    "\t\t.chained = true,\n"
    "\t\t.chain_id = ALC269_FIXUP_HEADSET_MODE_NO_HP_MIC,\n"
    "\t},\n"
)
if body_marker not in src:
    raise SystemExit("could not find ALC2XX_FIXUP_HEADSET_MIC body")
src = src.replace(body_marker, body_marker + body_add, 1)

# 4. Add SND_PCI_QUIRK referring to the new fixup.
quirk_marker = '\tSND_PCI_QUIRK(0x1ee7, 0x2078, "HONOR BRB-X M1010", ALC2XX_FIXUP_HEADSET_MIC),\n'
quirk_add    = '\tSND_PCI_QUIRK(0x1ee7, 0x209d, "HONOR ZQC-P M1010", ALC256_FIXUP_HONOR_ZQC_P_M1010_MIC),\n'
if quirk_marker not in src:
    raise SystemExit("could not find HONOR BRB-X M1010 quirk to anchor on")
src = src.replace(quirk_marker, quirk_marker + quirk_add, 1)

with open(src_path, "w") as f:
    f.write(src)
PYEOF
    if ! grep -q '0x1ee7, 0x209d' "${WORK}/alc269.c"; then
        echo "[fatal] could not insert the SND_PCI_QUIRK line — upstream layout changed" >&2
        echo "        review patch/alc269-honor-zqc-p-m1010.patch and adjust." >&2
        exit 1
    fi
    echo "[ok] inserted SND_PCI_QUIRK for 1ee7:209d HONOR ZQC-P M1010"
fi

cat > "${WORK}/Makefile" <<'EOF'
KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

obj-m += snd-hda-codec-alc269.o
snd-hda-codec-alc269-y := alc269.o

ccflags-y += -I$(src)

default:
	$(MAKE) -C $(KDIR) M=$(PWD) CC=clang LLVM=1 modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
EOF

echo "[*] building module"
make -C "$WORK" -s 2>&1 | tail -10
if [[ ! -f "${WORK}/snd-hda-codec-alc269.ko" ]]; then
    echo "[fatal] build did not produce snd-hda-codec-alc269.ko" >&2
    exit 1
fi

if has_quirk "$KO_PATH"; then
    echo "[ok] installed module already patched — nothing more to do."
    exit 0
fi

if [[ ! -f "$BACKUP" ]]; then
    echo "[*] backing up original $KO_PATH → $BACKUP"
    cp -a "$KO_PATH" "$BACKUP"
fi

echo "[*] installing patched module"
zstd -19 -q --force "${WORK}/snd-hda-codec-alc269.ko" -o "${WORK}/${KO_NAME}"
install -m 0644 "${WORK}/${KO_NAME}" "$KO_PATH"
depmod -a

# Drop the legacy systemd hotfix if a previous run of this script
# installed it — the kernel-side fixup makes it redundant.
remove_legacy_jack_service

echo
echo "════════════════════════════════════════════════════════════════════"
echo "  ALC256 ZQC-P quirk installed."
echo
echo "  After a fresh boot, the analog 3.5mm-jack headset microphone"
echo "  will appear as 'HiFi__Headset__source' in PipeWire and as the"
echo "  'Headset Mic' input under GNOME/KDE/niri sound settings."
echo
echo "  Pin 0x19 uses pincfg 0x01a1913c (JACK_DETECT_OVERRIDE=1) and the"
echo "  fixup chains to the kernel's existing headset_mode_no_hp_mic init,"
echo "  so the analog mic path is wired up at codec probe + every init,"
echo "  including after S3/S4 resume. No userspace jack-detect helper"
echo "  is needed."
echo
echo "  Original module backed up at: $BACKUP"
echo "  Re-run this script after every kernel update to keep the fix."
echo "════════════════════════════════════════════════════════════════════"
