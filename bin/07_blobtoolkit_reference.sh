#!/usr/bin/env bash
set -euo pipefail

# 07_blobtoolkit_reference.sh
# Use BlobToolKit to identify and remove contaminant contigs
# from the WW hermaphrodite reference assembly.
#
# This script assumes you have already created a BlobToolKit dataset
# (BlobDir) for the WW assembly and interactively determined which
# contigs to retain/remove. It then filters the assembly using the
# same GC and taxonomic thresholds used in the manuscript.
#
# Usage:
#   bash bin/07_blobtoolkit_reference.sh config/example_paths.yaml
#
# YAML config block (example):
#
# ww_reference:
#   fasta: /path/to/WW_reference_genome.fasta
#
# blobtoolkit_ww:
#   blobdir: /path/to/WW_blobdir          # BlobDir built from WW assembly
#   gc_min: 0.30
#   gc_max: 0.45
#   arthropoda_key: "Arthropoda"
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
for prog in yq blobtools; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Make sure your environment is loaded." >&2
    exit 1
  fi
done

OUTDIR=$(yq -r '.outdir' "$CONFIG")
WW_FASTA=$(yq -r '.ww_reference.fasta' "$CONFIG")
BLOBDIR=$(yq -r '.blobtoolkit_ww.blobdir' "$CONFIG")
GC_MIN=$(yq -r '.blobtoolkit_ww.gc_min' "$CONFIG")
GC_MAX=$(yq -r '.blobtoolkit_ww.gc_max' "$CONFIG")
ARTHROPODA_KEY=$(yq -r '.blobtoolkit_ww.arthropoda_key' "$CONFIG")

if [ ! -f "$WW_FASTA" ]; then
  echo "WW reference FASTA not found: $WW_FASTA" >&2
  exit 1
fi

if [ ! -d "$BLOBDIR" ]; then
  echo "BlobToolKit dataset (BlobDir) for WW reference not found: $BLOBDIR" >&2
  exit 1
fi

OUT_REF_DIR="${OUTDIR}/ww_reference_clean"
mkdir -p "$OUT_REF_DIR"

echo "Cleaning WW reference assembly with BlobToolKit..."
echo "  WW FASTA:      $WW_FASTA"
echo "  BlobDir:       $BLOBDIR"
echo "  GC range:      ${GC_MIN}–${GC_MAX}"
echo "  Arthropoda key: $ARTHROPODA_KEY"
echo "  Output dir:    $OUT_REF_DIR"

# Filter to keep contigs with GC in [GC_MIN, GC_MAX] and assigned to Arthropoda.
# Adjust attribute names (gc, bestsumorder_phylum) if your BlobDir uses
# different column headers.
blobtools filter \
  --param "gc--Min=${GC_MIN}" \
  --param "gc--Max=${GC_MAX}" \
  --param "bestsumorder_phylum--Keys=${ARTHROPODA_KEY}" \
  --fasta "$WW_FASTA" \
  --output "$OUT_REF_DIR" \
  "$BLOBDIR"

echo "WW reference cleaning complete."
echo "  Cleaned WW assembly FASTA and updated BlobDir should be in: ${OUT_REF_DIR}"
