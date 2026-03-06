#!/usr/bin/env bash
set -euo pipefail

# 01_kmer_jellyfish.sh
# Run Jellyfish k‑mer counting and histogram generation using settings
# defined in a YAML config file (e.g. config/example_paths.yaml).
#
# Usage:
#   bash bin/01_kmer_jellyfish.sh config/example_paths.yaml

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
  echo "Error: 'yq' not found. Install it in your conda env (e.g. 'mamba install -c conda-forge yq')." >&2
  exit 1
fi

# Read values from YAML
HIFI_READS=$(yq -r '.inputs.hifi_reads' "$CONFIG")
OUTDIR=$(yq -r '.outdir' "$CONFIG")
KMER_SIZE=$(yq -r '.genomescope.kmer_size' "$CONFIG")
THREADS=$(yq -r '.genomescope.threads' "$CONFIG")
MEMORY=$(yq -r '.genomescope.jellyfish_memory' "$CONFIG")

# Basic checks
if [ ! -f "$HIFI_READS" ]; then
  echo "HiFi reads file not found: $HIFI_READS" >&2
  exit 1
fi

mkdir -p "${OUTDIR}/kmer"
cd "${OUTDIR}/kmer"

echo "Running Jellyfish k-mer counting..."
echo "  Reads:        $HIFI_READS"
echo "  k-mer size:   $KMER_SIZE"
echo "  Threads:      $THREADS"
echo "  Memory (-s):  $MEMORY"
echo "  Output dir:   ${OUTDIR}/kmer"

# 1) Count k-mers
jellyfish count \
  -C \
  -m "${KMER_SIZE}" \
  -s "${MEMORY}" \
  -t "${THREADS}" \
  "${HIFI_READS}" \
  -o reads.jf

# 2) Build histogram
echo "Generating k-mer histogram..."
jellyfish histo \
  -t "${THREADS}" \
  reads.jf > reads.histo
  

echo "Done. Files created:"

#Make it executable (locally or via terminal on HPC):
#chmod +x bin/01_kmer_jellyfish.sh

echo "  ${OUTDIR}/kmer/reads.jf"
echo "  ${OUTDIR}/kmer/reads.histo"
