#!/usr/bin/env bash
# build_patch.sh — rebuild patch/SSDT27_TPD0.aml from patch/SSDT27_TPD0.dsl.
#
# Steps:
#   1. Compile the patched DSL with iasl.
#   2. Bump OEM revision in the compiled AML from 0x1000 to 0x2000 so the
#      kernel's ACPI table-upgrade logic prefers our copy over the OEM SSDT.
#   3. Recompute the ACPI table checksum.
#
# Requires: iasl (acpica package on Arch/CachyOS), python3.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SRC="$REPO_DIR/patch/SSDT27_TPD0.dsl"
OUT="$REPO_DIR/patch/SSDT27_TPD0.aml"

command -v iasl    >/dev/null || { echo "missing iasl (install acpica)" >&2; exit 1; }
command -v python3 >/dev/null || { echo "missing python3" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cp "$SRC" "$WORK/SSDT27_TPD0.dsl"

echo "[1/3] iasl compile"
( cd "$WORK" && iasl SSDT27_TPD0.dsl ) | tail -3

echo "[2/3] bump OEM revision 0x1000 -> 0x2000, recompute checksum"
python3 - <<PY
import sys
p = "$WORK/SSDT27_TPD0.aml"
data = bytearray(open(p, "rb").read())
old = int.from_bytes(data[24:28], "little")
data[24:28] = (0x2000).to_bytes(4, "little")
data[9] = 0
data[9] = (-sum(data)) & 0xFF
verify = sum(data) & 0xFF
print(f"    len={len(data)} oem_rev=0x{old:x}->0x2000 "
      f"checksum=0x{data[9]:02x} verify=0x{verify:02x}")
assert verify == 0, "checksum recomputation broken"
open(p, "wb").write(data)
PY

echo "[3/3] install -> $OUT"
install -m0644 "$WORK/SSDT27_TPD0.aml" "$OUT"

echo
echo "Done. Now run:  sudo $REPO_DIR/apply_patch.sh"
