#!/usr/bin/env bash
set -euo pipefail

# 12_repeatmasker.sh
# Soft-mask repeats in the ZZ genome assembly using RepeatMasker
# and the custom RepeatModeler library.
#
# Usage:
#   bash bin/12_repeatmasker.sh config/example_paths.yaml
#
# Expected YAML block:
#
# repeatmasker:
#   assembly_fasta: /path/to/ragtag_scaffold/ragtag.scaffold.fasta
#   custom_lib: /path/to/repeatmodeler/etexana_zz_rmdb-families.fa
#   species: "eulimnadia texana"   # or "arthropoda"
#   threads: 16
#
# outdir: /path/to/project/output

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config.yaml>" >&2
  exit 1
fi

CONFIG="$1"

if [ ! -f "$CONFIG" ]; then
  echo "Config file not found: $CONFIG" >&2
  exit 1
fi

# Minimal YAML parsing without external tools:
get_yaml_value() {
  local key="$1"
  awk -F': *' -v k="$key" '
    $1 == k {print $2; exit}
  ' "$CONFIG"
}

OUTDIR=$(get_yaml_value "outdir")

ASM_FASTA=$(awk '/^repeatmasker:/{flag=1;next}/^[^ ]/{flag=0}flag && /assembly_fasta:/{gsub(/^[[:space:]]*assembly_fasta:[[:space:]]*/,""); print; exit}' "$CONFIG")
CUSTOM_LIB=$(awk '/^repeatmasker:/{flag=1;next}/^[^ ]/{flag=0}flag && /custom_lib:/{gsub(/^[[:space:]]*custom_lib:[[:space:]]*/,""); print; exit}' "$CONFIG")
SPECIES=$(awk '/^repeatmasker:/{flag=1;next}/^[^ ]/{flag=0}flag && /species:/{gsub(/^[[:space:]]*species:[[:space:]]*/,""); print; exit}' "$CONFIG")
THREADS=$(awk '/^repeatmasker:/{flag=1;next}/^[^ ]/{flag=0}flag && /threads:/{gsub(/^[[:space:]]*threads:[[:space:]]*/,""); print; exit}' "$CONFIG")

if [ -z "$OUTDIR" ] || [ -z "$ASM_FASTA" ] || [ -z "$CUSTOM_LIB" ] || [ -z "$THREADS" ]; then
  echo "Error: could not parse repeatmasker block from config. Check indentation and keys." >&2
  exit 1
fi

if [ ! -f "$ASM_FASTA" ]; then
  echo "Assembly FASTA not found: $ASM_FASTA" >&2
  exit 1
fi

if [ ! -f "$CUSTOM_LIB" ]; then
  echo "RepeatModeler library not found: $CUSTOM_LIB" >&2
  exit 1
fi

if ! command -v RepeatMasker >/dev/null 2>&1; then
  echo "Error: RepeatMasker not found in PATH. Activate the env where it is installed." >&2
  exit 1
fi

RMDIR="${OUTDIR}/repeatmasker"
mkdir -p "$RMDIR"
cd "$RMDIR"

ASM_BASENAME=$(basename "$ASM_FASTA")

echo "Running RepeatMasker..."
echo "  Assembly:     $ASM_FASTA"
echo "  Library:      $CUSTOM_LIB"
echo "  Species tag:  $SPECIES"
echo "  Threads:      $THREADS"
echo "  Output dir:   $RMDIR"

RepeatMasker \
  -pa "$THREADS" \
  -gff \
  -xsmall \
  -lib "$CUSTOM_LIB" \
  -species "$SPECIES" \
  -dir "$RMDIR" \
  "$ASM_FASTA"

echo "RepeatMasker finished."
echo "Key outputs:"
echo "  Masked FASTA: ${RMDIR}/${ASM_BASENAME}.masked"
echo "  GFF:          ${RMDIR}/${ASM_BASENAME}.out.gff"
echo "  Repeat table: ${RMDIR}/${ASM_BASENAME}.tbl"
