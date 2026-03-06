#!/usr/bin/env bash
set -euo pipefail

# 04_blobtoolkit_filter.sh
# Filter a BlobToolKit dataset to retain "clean" contigs for E. texana
# based on GC content and Arthropoda BUSCO/taxonomic assignment.
#
# Usage:
#   bash bin/04_blobtoolkit_filter.sh config/example_paths.yaml
#
# Expects:
#   - A BlobToolKit dataset (BlobDir) created from preliminary contigs.
#   - Assembly FASTA file used to build that dataset.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config.yaml>" >&2
  exit 1
fi

CONFIG="$1"

if [ ! -f "$CONFIG" ]; then
  echo "Config file not found: $CONFIG" >&2
  exit 1
fi

# Require yq for YAML parsing
if ! command -v yq >/dev/null 2>&1; then
  echo "Error: 'yq' not found. Install it in your conda env." >&2
  exit 1
fi

# Read values from YAML
OUTDIR=$(yq -r '.outdir' "$CONFIG")
BLOBDIR=$(yq -r '.blobtoolkit.prelim_blobdir' "$CONFIG")
ASSEMBLY_FASTA=$(yq -r '.blobtoolkit.prelim_assembly_fasta' "$CONFIG")
GC_MIN=$(yq -r '.blobtoolkit.gc_min' "$CONFIG")
GC_MAX=$(yq -r '.blobtoolkit.gc_max' "$CONFIG")
ARTHROPODA_KEY=$(yq -r '.blobtoolkit.arthropoda_key' "$CONFIG")

if [ ! -d "$BLOBDIR" ]; then
  echo "BlobToolKit dataset (BlobDir) not found: $BLOBDIR" >&2
  exit 1
fi

if [ ! -f "$ASSEMBLY_FASTA" ]; then
  echo "Assembly FASTA not found: $ASSEMBLY_FASTA" >&2
  exit 1
fi

CLEAN_DIR="${OUTDIR}/blobtoolkit_clean"
mkdir -p "$CLEAN_DIR"

echo "Filtering BlobToolKit dataset to obtain clean contigs..."
echo "  BlobDir:       $BLOBDIR"
echo "  Assembly:      $ASSEMBLY_FASTA"
echo "  GC range:      ${GC_MIN}–${GC_MAX}"
echo "  Arthropoda key: $ARTHROPODA_KEY"
echo "  Output dir:    $CLEAN_DIR"

# Example filter logic:
# - keep contigs with GC between GC_MIN and GC_MAX
# - keep contigs whose best-sum-order phylum is Arthropoda
# - optionally exclude explicit contaminants (Bacteria, Viruses, etc.)
#
# You may need to adjust the field names (e.g. gc, bestsumorder_phylum)
# to match your BlobToolKit dataset.

blobtools filter \
  --param "gc--Min=${GC_MIN}" \
  --param "gc--Max=${GC_MAX}" \
  --param "bestsumorder_phylum--Keys=${ARTHROPODA_KEY}" \
  --fasta "${ASSEMBLY_FASTA}" \
  --output "${CLEAN_DIR}" \
  "${BLOBDIR}"

echo "Filtering complete."
echo "  Clean assembly FASTA should be in: ${CLEAN_DIR}"
echo "  Clean BlobDir dataset: ${CLEAN_DIR}"
