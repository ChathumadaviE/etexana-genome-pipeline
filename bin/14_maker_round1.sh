#!/usr/bin/env bash
set -euo pipefail

# 14_maker_round1.sh
# Run first-round genome annotation with MAKER using:
#  - soft-masked ZZ genome
#  - Trinity-assembled ZZ transcripts
#  - Daphnia magna protein homology
#  - repeat feature GFF3 from RepeatMasker
#
# Usage:
#   bash bin/14_maker_round1.sh config/example_paths.yaml
#
# YAML example:
#
# maker_round1:
#   genome_fasta: /path/to/repeatmasker/ragtag.scaffold.fasta.masked
#   repeat_gff3: /path/to/repeatmasker/ragtag.scaffold.fasta.out.gff
#   transcript_fasta: /path/to/trinity/Trinity.fasta
#   protein_fasta: /path/to/daphnia_magna_proteome.fasta
#   maker_opts_template: /path/to/maker_opts_round1.ctl
#   maker_bopts: /path/to/maker_bopts.ctl
#   maker_exepts: /path/to/maker_exe.ctl
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
  echo "Error: 'yq' not found. Activate your conda environment." >&2
  exit 1
fi

if ! command -v maker >/dev/null 2>&1; then
  echo "Error: 'maker' not found in PATH. Load MAKER environment/module." >&2
  exit 1
fi

OUTDIR=$(yq -r '.outdir' "$CONFIG")

GENOME=$(yq -r '.maker_round1.genome_fasta' "$CONFIG")
REPEAT_GFF3=$(yq -r '.maker_round1.repeat_gff3' "$CONFIG")
TX_FASTA=$(yq -r '.maker_round1.transcript_fasta' "$CONFIG")
PROT_FASTA=$(yq -r '.maker_round1.protein_fasta' "$CONFIG")
OPTS_TEMPLATE=$(yq -r '.maker_round1.maker_opts_template' "$CONFIG")
BOPTS=$(yq -r '.maker_round1.maker_bopts' "$CONFIG")
EXEPTS=$(yq -r '.maker_round1.maker_exepts' "$CONFIG")
THREADS=$(yq -r '.maker_round1.threads' "$CONFIG")

for f in "$GENOME" "$REPEAT_GFF3" "$TX_FASTA" "$PROT_FASTA" "$OPTS_TEMPLATE" "$BOPTS" "$EXEPTS"; do
  if [ ! -f "$f" ]; then
    echo "Required file not found: $f" >&2
    exit 1
  fi
end

MKDIR="${OUTDIR}/maker_round1"
mkdir -p "$MKDIR"
cd "$MKDIR"

# Make a working copy of maker_opts.ctl and inject key paths
cp "$OPTS_TEMPLATE" maker_opts.ctl
cp "$BOPTS" maker_bopts.ctl
cp "$EXEPTS" maker_exe.ctl

# Update maker_opts.ctl with genome, transcripts, proteins, repeats
# (simple in-place substitution; assumes the template has placeholder tags)
sed -i "s|^genome=.*|genome=${GENOME}|" maker_opts.ctl
sed -i "s|^rm_gff=.*|rm_gff=${REPEAT_GFF3}|" maker_opts.ctl
sed -i "s|^est=.*|est=${TX_FASTA}|" maker_opts.ctl
sed -i "s|^protein=.*|protein=${PROT_FASTA}|" maker_opts.ctl

echo "Running MAKER round 1..."
echo "  Genome:      $GENOME"
echo "  Repeats GFF: $REPEAT_GFF3"
echo "  Transcripts: $TX_FASTA"
echo "  Proteins:    $PROT_FASTA"
echo "  Threads:     $THREADS"
echo "  Work dir:    $MKDIR"

maker -fix_nucleotides -cpus "$THREADS" > maker_round1.log 2> maker_round1.err

echo "MAKER round 1 complete."
echo "  Log:     ${MKDIR}/maker_round1.log"
echo "  Outputs: ${MKDIR} (GFF, FASTA, stats after you run gff3_merge/fasta_merge)"
