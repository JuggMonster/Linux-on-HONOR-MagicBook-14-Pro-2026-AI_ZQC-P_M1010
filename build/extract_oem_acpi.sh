#!/usr/bin/env bash
# extract_oem_acpi.sh — dump the *running* ACPI tables to ./oem_acpi/ for
# auditing or re-deriving the patch on a similar device.
#
# Run from the repository root (or any writable dir). Requires acpica-tools
# (provides `acpidump` and `acpixtract`).

set -euo pipefail

command -v acpidump   >/dev/null || { echo "install 'acpica-tools' (acpidump)" >&2; exit 1; }
command -v acpixtract >/dev/null || { echo "install 'acpica-tools' (acpixtract)" >&2; exit 1; }

OUT="${1:-oem_acpi}"
mkdir -p "$OUT" && cd "$OUT"

echo "[1/3] acpidump → acpi.dump"
sudo acpidump > acpi.dump

echo "[2/3] acpixtract → *.dat"
acpixtract -a acpi.dump >/dev/null

echo "[3/3] iasl -d → *.dsl (optional, requires iasl)"
if command -v iasl >/dev/null; then
    for f in *.dat; do iasl -d "$f" >/dev/null 2>&1 || true; done
fi

echo
echo "Done. Dumped tables are in: $(pwd)"
ls -la
