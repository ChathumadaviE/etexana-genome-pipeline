#!/usr/bin/env bash
set -euo pipefail

# 09_ragtag_scaffold.sh
# Reference-guided scaffolding of ZZ contigs onto the gap-filled WW
# reference assembly using RagTag.
#
# Usage:
#   bash bin/09_ragtag_scaffold.sh config/example_paths.yaml
#
# YAML config block (example):
#
# ragtag:
#   gapfilled_reference: /path/to/gapcloser/gap_filled_Etexana.scaffolds.fa
#   zz_contigs_fasta: /path/to/ZZ_contigs.fasta
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

# Dependencies
for prog in yq ragtag.py; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Activate the appropriate environment." >&2
    exit 1
  fi
done

OUTDIR=$(yq -r '.outdir' "$CONFIG")
GAPFILLED_REF=$(yq -r '.ragtag.gapfilled_reference' "$CONFIG")
ZZ_CONTIGS=$(yq -r '.ragtag.zz_contigs_fasta' "$CONFIG")
THREADS=$(yq -r '.ragtag.threads' "$CONFIG")

if [ ! -f "$GAPFILLED_REF" ]; then
  echo "Gap-filled reference FASTA not found: $GAPFILLED_REF" >&2
  exit 1
fi

if [ ! -f "$ZZ_CONTIGS" ]; then
  echo "ZZ contigs FASTA not found: $ZZ_CONTIGS" >&2
  exit 1
fi

RAGDIR="${OUTDIR}/ragtag_scaffold"
mkdir -p "$RAGDIR"

echo "Running RagTag scaffold..."
echo "  Reference (gap-filled WW): $GAPFILLED_REF"
echo "  Query (ZZ contigs):        $ZZ_CONTIGS"
echo "  Threads:                   $THREADS"
echo "  Output dir:                $RAGDIR"

ragtag.py scaffold \
  -t "$THREADS" \
  -r \
  -o "$RAGDIR" \
  -C \
  -w \
  -f 200000 \
  "$GAPFILLED_REF" \
  "$ZZ_CONTIGS"

echo "RagTag scaffolding complete."
echo "  Scaffolded assembly: ${RAGDIR}/ragtag.scaffold.fasta"
echo "  Unplaced contigs (chr0 etc.): ${RAGDIR}"
