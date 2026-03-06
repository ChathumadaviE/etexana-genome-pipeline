#!/usr/bin/env bash
set -euo pipefail

# 11_repeatmodeler.sh
# Build a de novo repeat library for the ZZ genome assembly using RepeatModeler.
#
# Usage:
#   bash bin/11_repeatmodeler.sh config/example_paths.yaml
#
# Expected YAML block:
#
# repeatmodeler:
#   assembly_fasta: /path/to/ragtag_scaffold/ragtag.scaffold.fasta
#   db_name: etexana_zz_rmdb
#   threads: 32
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

# Require yq and RepeatModeler
for prog in yq BuildDatabase RepeatModeler; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Activate the conda/module environment first." >&2
    exit 1
  fi
done

OUTDIR=$(yq -r '.outdir' "$CONFIG")
ASM_FASTA=$(yq -r '.repeatmodeler.assembly_fasta' "$CONFIG")
DB_NAME=$(yq -r '.repeatmodeler.db_name' "$CONFIG")
THREADS=$(yq -r '.repeatmodeler.threads' "$CONFIG")

if [ ! -f "$ASM_FASTA" ]; then
  echo "Assembly FASTA for RepeatModeler not found: $ASM_FASTA" >&2
  exit 1
fi

RMDIR="${OUTDIR}/repeatmodeler"
mkdir -p "$RMDIR"
cd "$RMDIR"

echo "Running RepeatModeler on assembly..."
echo "  Assembly: $ASM_FASTA"
echo "  DB name:  $DB_NAME"
echo "  Threads:  $THREADS"
echo "  Work dir: $RMDIR"

# 1) Build the RepeatModeler database
if [ ! -f "${DB_NAME}.nhr" ] && [ ! -f "${DB_NAME}.nal" ]; then
  BuildDatabase \
    -name "$DB_NAME" \
    -engine ncbi \
    "$ASM_FASTA"
else
  echo "Database ${DB_NAME} already exists; skipping BuildDatabase."
fi

# 2) Run RepeatModeler
RepeatModeler \
  -database "$DB_NAME" \
  -pa "$THREADS" \
  -engine ncbi \
  > repeatmodeler.log 2> repeatmodeler.err

echo "RepeatModeler finished."
echo "Key outputs:"
echo "  Custom repeat library: ${RMDIR}/${DB_NAME}-families.fa"
echo "  Log files:             ${RMDIR}/repeatmodeler.log , repeatmodeler.err"
