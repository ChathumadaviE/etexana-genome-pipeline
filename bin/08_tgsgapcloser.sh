#!/usr/bin/env bash
set -euo pipefail

# 08_tgsgapcloser.sh
# Fill gaps in the WW reference assembly using ZZ clean HiFi reads
# with TGS-GapCloser.
#
# Usage:
#   bash bin/08_tgsgapcloser.sh config/example_paths.yaml
#
# YAML config block (example):
#
# gapcloser:
#   ww_clean_fasta: /path/to/ww_reference_clean/clean_ww_assembly.fasta
#   zz_clean_reads_fasta: /path/to/minimap2_clean_reads/ZZ_cleanreads.fasta
#   threads: 32
#   tgstype: pb
#   minmap_arg: "-x asm20"
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

# Check dependencies
for prog in yq tgsgapcloser; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Load the conda env with TGS-GapCloser." >&2
    exit 1
  fi
done

OUTDIR=$(yq -r '.outdir' "$CONFIG")

WW_CLEAN_FASTA=$(yq -r '.gapcloser.ww_clean_fasta' "$CONFIG")
ZZ_CLEAN_READS=$(yq -r '.gapcloser.zz_clean_reads_fasta' "$CONFIG")
THREADS=$(yq -r '.gapcloser.threads' "$CONFIG")
TGSTYPE=$(yq -r '.gapcloser.tgstype' "$CONFIG")
MINMAP_ARG=$(yq -r '.gapcloser.minmap_arg' "$CONFIG")

if [ ! -f "$WW_CLEAN_FASTA" ]; then
  echo "Clean WW reference FASTA not found: $WW_CLEAN_FASTA" >&2
  exit 1
fi

if [ ! -f "$ZZ_CLEAN_READS" ]; then
  echo "Clean ZZ reads FASTA not found: $ZZ_CLEAN_READS" >&2
  exit 1
fi

GAPDIR="${OUTDIR}/gapcloser"
mkdir -p "$GAPDIR"

echo "Running TGS-GapCloser..."
echo "  Scaffolds (WW clean):  $WW_CLEAN_FASTA"
echo "  Reads (ZZ clean HiFi): $ZZ_CLEAN_READS"
echo "  Threads:               $THREADS"
echo "  TGS type:              $TGSTYPE"
echo "  minimap2 args:         $MINMAP_ARG"
echo "  Output dir:            $GAPDIR"

tgsgapcloser \
  --scaff "$WW_CLEAN_FASTA" \
  --reads "$ZZ_CLEAN_READS" \
  --output "${GAPDIR}/gap_filled_Etexana" \
  --ne \
  --tgstype "$TGSTYPE" \
  --thread "$THREADS" \
  --minmap_arg "$MINMAP_ARG" \
  > "${GAPDIR}/pipe.log" 2> "${GAPDIR}/pipe.err"

echo "TGS-GapCloser finished."
echo "  Gap-filled assembly prefix: ${GAPDIR}/gap_filled_Etexana"
echo "  Log files: ${GAPDIR}/pipe.log , ${GAPDIR}/pipe.err"
