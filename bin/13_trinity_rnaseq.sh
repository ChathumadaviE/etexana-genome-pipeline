#!/usr/bin/env bash
set -euo pipefail

# 13_trinity_rnaseq.sh
# De novo transcriptome assembly of ZZ RNA-seq reads using Trinity.
#
# Usage:
#   bash bin/13_trinity_rnaseq.sh config/example_paths.yaml
#
# YAML example:
#
# trinity:
#   left_reads:
#     - /path/to/RNAseq_rep1_R1.fastq.gz
#     - /path/to/RNAseq_rep2_R1.fastq.gz
#   right_reads:
#     - /path/to/RNAseq_rep1_R2.fastq.gz
#     - /path/to/RNAseq_rep2_R2.fastq.gz
#   stranded: RF          # or "none" if unstranded
#   max_memory: 100G
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

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: 'yq' not found. Activate the conda env first." >&2
  exit 1
fi

if ! command -v Trinity >/dev/null 2>&1; then
  echo "Error: Trinity not found in PATH." >&2
  exit 1
fi

OUTDIR=$(yq -r '.outdir' "$CONFIG")
MAX_MEM=$(yq -r '.trinity.max_memory' "$CONFIG")
THREADS=$(yq -r '.trinity.threads' "$CONFIG")
STRANDED=$(yq -r '.trinity.stranded' "$CONFIG")

# Join left/right read lists with commas for Trinity
LEFT_READS=$(yq -r '.trinity.left_reads | join(",")' "$CONFIG")
RIGHT_READS=$(yq -r '.trinity.right_reads | join(",")' "$CONFIG")

if [ -z "$LEFT_READS" ] || [ -z "$RIGHT_READS" ]; then
  echo "Error: left/right RNA-seq reads not defined in config under trinity.left_reads/right_reads." >&2
  exit 1
fi

TRIN_DIR="${OUTDIR}/trinity"
mkdir -p "$TRIN_DIR"
cd "$TRIN_DIR"

echo "Running Trinity de novo transcriptome assembly..."
echo "  Left reads:   $LEFT_READS"
echo "  Right reads:  $RIGHT_READS"
echo "  Stranded:     $STRANDED"
echo "  Max memory:   $MAX_MEM"
echo "  Threads:      $THREADS"
echo "  Output dir:   $TRIN_DIR"

CMD=(Trinity
  --seqType fq
  --max_memory "$MAX_MEM"
  --left "$LEFT_READS"
  --right "$RIGHT_READS"
  --CPU "$THREADS"
  --output "$TRIN_DIR"
)

if [ "$STRANDED" != "none" ] && [ -n "$STRANDED" ]; then
  CMD+=(--SS_lib_type "$STRANDED")
fi

"${CMD[@]}" > trinity.log 2> trinity.err

echo "Trinity finished."
echo "  Assembled transcripts: ${TRIN_DIR}/Trinity.fasta"
echo "  Logs: trinity.log, trinity.err"
