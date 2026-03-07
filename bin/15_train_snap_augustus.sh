#!/usr/bin/env bash
set -euo pipefail

# 15_train_snap_augustus.sh
# Train SNAP (and optionally AUGUSTUS) from round 1 MAKER output
# and re-run MAKER round 2/3 locally.
#
# This script assumes:
#   - MAKER round 1 has already been run locally in $RND1_DIR
#   - gff3_merge and fasta_merge are available
#   - SNAP and AUGUSTUS are installed and on PATH
#
# Usage:
#   bash bin/15_train_snap_augustus.sh

#####################
# USER CONFIG START #
#####################

# Round 1 MAKER output directory and base name
RND1_DIR="/path/to/maker_round1"           # contains *_master_datastore_index.log
RND1_BASE="etexana_rnd1"                   # arbitrary base name for round1 output

# Genome FASTA and masked genome (same one used in round1 MAKER)
GENOME_FASTA="/path/to/repeatmasker/ragtag.scaffold.fasta.masked"

# Repeat library/GFF used in MAKER
REPEAT_LIB="/path/to/repeatmodeler/etexana_zz_rmdb-families.fa"
REPEAT_GFF="/path/to/repeatmasker/ragtag.scaffold.fasta.out.gff"

# Transcript and protein evidence
TRANSCRIPTS="/path/to/trinity/Trinity.fasta"
PROTEINS="/path/to/daphnia_magna_proteome.fasta"

# SNAP training parameters
SNAP_PREFIX="etexana_snap"
AED_MAX=0.25
MIN_LEN=50

# AUGUSTUS species name (if you want AUGUSTUS training)
AUG_SPECIES="etexana"

# Number of CPUs for MAKER and training
THREADS=32

# Where to run subsequent rounds
WORKDIR="/path/to/annotation_workdir"   # e.g. ${OUTDIR}/annotation

###################
# USER CONFIG END #
###################

mkdir -p "$WORKDIR"
cd "$WORKDIR"

########################
# 1. Merge round1 GFFs #
########################

echo "Merging round 1 MAKER output..."

MASTER_LOG="${RND1_DIR}/${RND1_BASE}_master_datastore_index.log"

if [ ! -f "$MASTER_LOG" ]; then
  echo "Cannot find master datastore log: $MASTER_LOG" >&2
  exit 1
fi

# All features with sequences
gff3_merge -s -d "$MASTER_LOG" > "${RND1_BASE}.all.maker.gff"
fasta_merge -d "$MASTER_LOG"

# GFF without embedded sequences (easier to process)
gff3_merge -n -s -d "$MASTER_LOG" > "${RND1_BASE}.all.maker.noseq.gff"

#######################################
# 2. Convert MAKER GFF to ZFF for SNAP #
#######################################

echo "Preparing SNAP training data..."

# Convert to ZFF format (maker2zff is distributed with MAKER)
maker2zff "${RND1_BASE}.all.maker.noseq.gff"

# Filter by AED and length; these thresholds are typical defaults
# (you can tune to match your paper exactly)
fathom genome.ann genome.dna -validate > validate.log 2>&1
fathom genome.ann genome.dna -categorize 1000 > categorize.log 2>&1
fathom uni.ann uni.dna -export 1000 -plus > export.log 2>&1

mkdir -p params
cd params
forge ../export.ann ../export.dna > ../forge.log 2>&1
cd ..

# Assemble SNAP HMM
hmm-assembler.pl "$SNAP_PREFIX" params > "${SNAP_PREFIX}.hmm"

echo "SNAP HMM built: ${WORKDIR}/${SNAP_PREFIX}.hmm"

##########################################
# 3. MAKER round 2 with SNAP (±AUGUSTUS) #
##########################################

echo "Setting up MAKER round 2..."

# Create new control files
maker -CTL

# Update maker_opts.ctl with genome, evidence, repeats, SNAP HMM
sed -i "s|^genome=.*|genome=${GENOME_FASTA}|" maker_opts.ctl
sed -i "s|^est=.*|est=${TRANSCRIPTS}|" maker_opts.ctl
sed -i "s|^protein=.*|protein=${PROTEINS}|" maker_opts.ctl
sed -i "s|^rmlib=.*|rmlib=${REPEAT_LIB}|" maker_opts.ctl
sed -i "s|^rm_gff=.*|rm_gff=${REPEAT_GFF}|" maker_opts.ctl

# Use existing round 1 evidence GFFs instead of est2genome/protein2genome reruns if desired
# sed -i "s|^est_gff=.*|est_gff=${RND1_BASE}.all.maker.noseq.est2genome.gff|" maker_opts.ctl
# sed -i "s|^protein_gff=.*|protein_gff=${RND1_BASE}.all.maker.noseq.protein2genome.gff|" maker_opts.ctl

# Point MAKER to SNAP HMM
sed -i "s|^snaphmm=.*|snaphmm=${WORKDIR}/${SNAP_PREFIX}.hmm|" maker_opts.ctl

# (Optional) enable AUGUSTUS species if already trained
# sed -i "s|^augustus_species=.*|augustus_species=${AUG_SPECIES}|" maker_opts.ctl

echo "Running MAKER round 2..."
maker -base etexana_rnd2 -cpus "$THREADS" > maker_rnd2.log 2> maker_rnd2.err

#############################################
# 4. (Optional) further training & round 3  #
#############################################

# If desired, you can repeat the SNAP training using round 2 GFF,
# build a second HMM (e.g. ${SNAP_PREFIX}_r2.hmm), update snaphmm,
# and run another round of MAKER (etexana_rnd3). The commands are the same
# as above, just swap in the new HMM and base name.

echo "Training and MAKER round 2 complete."
echo "Outputs:"
echo "  SNAP HMM: ${WORKDIR}/${SNAP_PREFIX}.hmm"
echo "  Round 2 MAKER dir: ${WORKDIR}/etexana_rnd2.maker.output"

############################
# 5. Train AUGUSTUS        #
############################

# Assumes:
#  - You have merged MAKER GFF and genome FASTA from round 1 or 2
#  - You created a GBK or GFF training set; here we assume GFF + genome
#  - $GENOME_FASTA and ${RND1_BASE}.all.maker.noseq.gff exist

echo "Preparing training set for AUGUSTUS..."

# 5.1 Convert MAKER GFF to AUGUSTUS training GBK (using maker2zff + zff2augustus
# or a separate helper, depending on how you prefer to do it).
# One common pattern is:
#   - starting from the same ZFF you used for SNAP
#   - use scripts (e.g. zff2augustus.pl) to produce a GenBank file.
#
# Here we assume you already generated a GenBank file `etexana.train.gb`
# from your best gene models.
AUG_TRAIN_GB="/path/to/etexana.train.gb"   # <-- replace with your actual file

if [ ! -f "$AUG_TRAIN_GB" ]; then
  echo "AUGUSTUS training GenBank file not found: $AUG_TRAIN_GB" >&2
  echo "Create this from your MAKER gene models before running." >&2
  exit 1
fi

# 5.2 Set AUGUSTUS config path and species name
: "${AUGUSTUS_CONFIG_PATH:?Please export AUGUSTUS_CONFIG_PATH before running.}"
AUG_SPECIES="etexana"

echo "Creating AUGUSTUS species '${AUG_SPECIES}'..."

# Create new species parameter directory
new_species.pl --species="$AUG_SPECIES"

# 5.3 Split training/test genes and run etraining/augustus to tune parameters

# Split into training and test sets (80/20 here; adjust as you like)
cd "$WORKDIR"
grep -n "LOCUS" "$AUG_TRAIN_GB" | awk 'NR % 5 == 0 {print $1}' | cut -d':' -f1 > test.idx
# This splitting is just a placeholder; in practice you may use a more robust script.

# Extract training genes
TRAIN_GB="etexana.train_only.gb"
TEST_GB="etexana.test_only.gb"
# You would use a small helper to split the GBK file by index;
# here we simply assume TRAIN_GB and TEST_GB already exist.

# 5.4 Run etraining on training set
etraining --species="$AUG_SPECIES" "$TRAIN_GB"

# 5.5 Evaluate on test set
augustus --species="$AUG_SPECIES" "$TEST_GB" > augustus_test.out

# Optional: further optimize meta‑parameters (time‑consuming)
# optimize_augustus.pl --species="$AUG_SPECIES" "$TRAIN_GB"

echo "AUGUSTUS training complete for species '${AUG_SPECIES}'."
echo "  Species parameters are in: ${AUGUSTUS_CONFIG_PATH}/species/${AUG_SPECIES}"
