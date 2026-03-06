#!/usr/bin/env bash
set -euo pipefail

# 03_hifiasm_vgp.sh
# Document and retrieve the preliminary ZZ contig assembly generated with
# the VGP hifiasm pipeline on the Galaxy platform.
#
# This script does NOT run hifiasm locally. Instead, it:
#   - records the Galaxy history URL, VGP pipeline version, and hifiasm version
#   - copies/downloads the purged contig FASTA into the local project
#     structure so it can be used by downstream steps.
#
# Usage:
#   bash bin/03_hifiasm_vgp.sh config/example_paths.yaml
#
# Expected config entries:
#   vgp:
#     galaxy_history_url: "https://usegalaxy.org/u/<user>/h/<history-id>"
#     hifiasm_version: "0.16.1+galaxy4"
#     vgp_pipeline_version: "VGP pipeline 1.0 (Galaxy wrapper)"
#     purged_contigs_fasta: /path/to/local/ZZ_purged_contigs.fasta

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
  echo "Error: 'yq' not found. Activate the conda environment first." >&2
  exit 1
fi

OUTDIR=$(yq -r '.outdir' "$CONFIG")
GALAXY_URL=$(yq -r '.vgp.galaxy_history_url' "$CONFIG")
HIFIASM_VER=$(yq -r '.vgp.hifiasm_version' "$CONFIG")
VGP_VER=$(yq -r '.vgp.vgp_pipeline_version' "$CONFIG")
PURGED_CONTIGS=$(yq -r '.vgp.purged_contigs_fasta' "$CONFIG")

mkdir -p "${OUTDIR}/vgp"
META_FILE="${OUTDIR}/vgp/hifiasm_vgp_metadata.txt"

echo "Recording VGP / hifiasm Galaxy run metadata..."
{
  echo "VGP hifiasm Galaxy run for ZZ male HiFi reads"
  echo "Galaxy history URL: ${GALAXY_URL}"
  echo "VGP pipeline version: ${VGP_VER}"
  echo "hifiasm version: ${HIFIASM_VER}"
  echo "Local purged contigs FASTA: ${PURGED_CONTIGS}"
  echo "Recorded on: $(date)"
} > "${META_FILE}"

if [ ! -f "${PURGED_CONTIGS}" ]; then
  echo "WARNING: purged contigs FASTA does not exist locally:"
  echo "  ${PURGED_CONTIGS}"
  echo "Please download/export the purged contigs from the Galaxy VGP"
  echo "history and save them at this path. Then re-run this script."
  exit 1
fi

# Symlink or copy into a standardized location for downstream steps
STD_ASM="${OUTDIR}/vgp/ZZ_purged_contigs.fasta"
if [ ! -f "$STD_ASM" ]; then
  ln -s "${PURGED_CONTIGS}" "$STD_ASM"
fi

echo "VGP hifiasm step documented."
echo "  Metadata: ${META_FILE}"
echo "  Purged contigs for downstream steps: ${STD_ASM}"
