#!/usr/bin/env bash
set -euo pipefail

# 05_minimap2_clean_reads.sh
# Map ZZ HiFi reads to clean contigs and extract the reads that map
# (clean HiFi reads belonging to E. texana).
#
# Usage:
#   bash bin/05_minimap2_clean_reads.sh config/example_paths.yaml
#
# Requires:
#   - minimap2
#   - samtools
#   - yq (for YAML parsing)

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
for prog in yq minimap2 samtools; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Load your conda env first." >&2
    exit 1
  fi
done

# Read values from YAML
OUTDIR=$(yq -r '.outdir' "$CONFIG")
HIFI_READS=$(yq -r '.inputs.hifi_reads' "$CONFIG")
CLEAN_CONTIGS=$(yq -r '.minimap2.clean_contigs_fasta' "$CONFIG")
THREADS=$(yq -r '.minimap2.threads' "$CONFIG")
PRESET=$(yq -r '.minimap2.preset' "$CONFIG")

if [ ! -f "$HIFI_READS" ]; then
  echo "HiFi reads file not found: $HIFI_READS" >&2
  exit 1
fi

if [ ! -f "$CLEAN_CONTIGS" ]; then
  echo "Clean contigs FASTA not found: $CLEAN_CONTIGS" >&2
  exit 1
fi

MAPDIR="${OUTDIR}/minimap2_clean_reads"
mkdir -p "$MAPDIR"

echo "Running minimap2 to map HiFi reads onto clean contigs..."
echo "  Reads:          $HIFI_READS"
echo "  Clean contigs:  $CLEAN_CONTIGS"
echo "  Threads:        $THREADS"
echo "  Preset:         $PRESET"
echo "  Output dir:     $MAPDIR"

# Index contigs (optional but recommended)
minimap2 -d "${MAPDIR}/clean_contigs.mmi" "$CLEAN_CONTIGS"

# Align reads and generate BAM
minimap2 -t "$THREADS" -ax "$PRESET" \
  "${MAPDIR}/clean_contigs.mmi" "$HIFI_READS" \
  | samtools view -b - \
  | samtools sort -o "${MAPDIR}/clean_reads.sorted.bam"

samtools index "${MAPDIR}/clean_reads.sorted.bam"

echo "Extracting mapped HiFi reads as FASTQ (clean reads)..."

# Extract mapped reads (-F 4 means exclude unmapped)
samtools view -F 4 -b "${MAPDIR}/clean_reads.sorted.bam" \
  | samtools fastq - \
  > "${MAPDIR}/ZZ_cleanreads.fastq"

echo "Done."
echo "  Alignments: ${MAPDIR}/clean_reads.sorted.bam"
echo "  Clean reads: ${MAPDIR}/ZZ_cleanreads.fastq"

#Then run:
#bash bin/05_minimap2_clean_reads.sh config/example_paths.yaml

