#!/usr/bin/env bash
set -euo pipefail

# Generate a dot plot comparing the gap-filled WW reference
# and the RagTag-scaffolded ZZ assembly using minimap2 + your
# existing dotPlotly R scripts.
#
# Usage:
#   bash bin/10_dotplotly.sh config/example_paths.yaml

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config.yaml>" >&2
  exit 1
fi

CONFIG="$1"

if [ ! -f "$CONFIG" ]; then
  echo "Config file not found: $CONFIG" >&2
  exit 1
fi

for prog in yq minimap2 Rscript; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Activate your environment." >&2
    exit 1
  fi
done

OUTDIR=$(yq -r '.outdir' "$CONFIG")
REF_FASTA=$(yq -r '.dotplotly.reference_fasta' "$CONFIG")
QUERY_FASTA=$(yq -r '.dotplotly.query_fasta' "$CONFIG")
THREADS=$(yq -r '.dotplotly.threads' "$CONFIG")
DOTPLOTLY_DIR=$(yq -r '.dotplotly.repo_path' "$CONFIG")  # your separate repo
PLOT_PREFIX=$(yq -r '.dotplotly.plot_prefix' "$CONFIG")

if [ ! -f "$REF_FASTA" ]; then
  echo "Reference FASTA not found: $REF_FASTA" >&2
  exit 1
fi

if [ ! -f "$QUERY_FASTA" ]; then
  echo "Query FASTA not found: $QUERY_FASTA" >&2
  exit 1
fi

if [ ! -d "$DOTPLOTLY_DIR" ]; then
  echo "dotPlotly repo directory not found: $DOTPLOTLY_DIR" >&2
  exit 1
fi

PLOTDIR="${OUTDIR}/dotplot"
mkdir -p "$PLOTDIR"

PAF_FILE="${PLOTDIR}/${PLOT_PREFIX}.paf"

echo "Generating minimap2 PAF alignment..."
minimap2 -x asm5 -t "$THREADS" "$REF_FASTA" "$QUERY_FASTA" > "$PAF_FILE"

echo "Running dotPlotly (pafCoordsDotPlotly.R)..."
Rscript "${DOTPLOTLY_DIR}/pafCoordsDotPlotly.R" \
  -i "$PAF_FILE" \
  -o "${PLOTDIR}/${PLOT_PREFIX}" \
  -s \
  -t "$PLOT_PREFIX" \
  -q \
  --minAlignmentLength 10000

echo "Dot plot created in: ${PLOTDIR}"
