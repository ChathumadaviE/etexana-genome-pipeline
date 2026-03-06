#!/usr/bin/env bash
set -euo pipefail

# 06_busco_quast_assembly.sh
# Run BUSCO and QUAST on the ZZ genome assembly to assess completeness
# and contiguity.
#
# Usage:
#   bash bin/06_busco_quast_assembly.sh config/example_paths.yaml
#
# Requires:
#   - busco
#   - quast.py (QUAST)
#   - samtools (optional, for some QUAST modes)
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
for prog in yq busco quast.py; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Error: '$prog' not found in PATH. Make sure your conda env is active." >&2
    exit 1
  fi
done

# Read values from YAML
OUTDIR=$(yq -r '.outdir' "$CONFIG")
ASSEMBLY_FASTA=$(yq -r '.qc.assembly_fasta' "$CONFIG")
BUSCO_LINEAGE=$(yq -r '.busco.lineage' "$CONFIG")
BUSCO_MODE=$(yq -r '.qc.busco_mode' "$CONFIG")
THREADS=$(yq -r '.qc.threads' "$CONFIG")
REFERENCE_FOR_QUAST=$(yq -r '.qc.reference_for_quast // ""' "$CONFIG")

if [ ! -f "$ASSEMBLY_FASTA" ]; then
  echo "Assembly FASTA not found: $ASSEMBLY_FASTA" >&2
  exit 1
fi

QCDIR="${OUTDIR}/qc"
mkdir -p "$QCDIR"

echo "Running BUSCO on assembly..."
echo "  Assembly:  $ASSEMBLY_FASTA"
echo "  Lineage:   $BUSCO_LINEAGE"
echo "  Mode:      $BUSCO_MODE"
echo "  Threads:   $THREADS"
echo "  Output:    ${QCDIR}/busco"

busco \
  -i "$ASSEMBLY_FASTA" \
  -o "busco" \
  -l "$BUSCO_LINEAGE" \
  -m "$BUSCO_MODE" \
  -c "$THREADS" \
  --out_path "$QCDIR"

echo "BUSCO finished. Results in: ${QCDIR}/busco"

echo "Running QUAST on assembly..."
QUAST_OUT="${QCDIR}/quast"
mkdir -p "$QUAST_OUT"

if [ -n "$REFERENCE_FOR_QUAST" ] && [ "$REFERENCE_FOR_QUAST" != "null" ]; then
  if [ ! -f "$REFERENCE_FOR_QUAST" ]; then
    echo "Reference for QUAST not found: $REFERENCE_FOR_QUAST" >&2
    exit 1
  fi
  echo "  Using reference: $REFERENCE_FOR_QUAST"
  quast.py \
    -o "$QUAST_OUT" \
    -t "$THREADS" \
    -r "$REFERENCE_FOR_QUAST" \
    "$ASSEMBLY_FASTA"
else
  echo "  No reference specified, running QUAST in reference-free mode."
  quast.py \
    -o "$QUAST_OUT" \
    -t "$THREADS" \
    "$ASSEMBLY_FASTA"
fi

echo "QUAST finished. Results in: ${QUAST_OUT}"
echo "Assembly QC (BUSCO + QUAST) completed."

#Then Run:
#bash bin/06_busco_quast_assembly.sh config/example_paths.yaml
