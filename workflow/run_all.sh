#!/usr/bin/env bash
set -euo pipefail

# run_all.sh
# Orchestrate the etexana-genome-pipeline steps in order.
#
# Usage:
#   bash workflow/run_all.sh -c config/example_paths.yaml
#   bash workflow/run_all.sh -c config/example_paths.yaml --from 03
#
# The --from flag lets you resume from a given step number.

CONFIG=""
START_STEP="01"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG="$2"
      shift 2
      ;;
    --from)
      START_STEP="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 -c <config.yaml> [--from <step>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$CONFIG" ]]; then
  echo "Error: config file not specified. Use -c <config.yaml>." >&2
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: config file not found: $CONFIG" >&2
  exit 1
fi

# Helper to run a step if >= START_STEP
run_step() {
  local num="$1"
  local script="$2"

  if [[ "$num" < "$START_STEP" ]]; then
    echo "[SKIP] Step $num ($script) because --from $START_STEP"
    return 0
  fi

  if [[ ! -x "bin/$script" ]]; then
    echo "[WARN] bin/$script not found or not executable; skipping step $num"
    return 0
  fi

  echo "=================================================="
  echo "Running step $num: bin/$script"
  echo "=================================================="
  bash "bin/$script" "$CONFIG"
  echo "Step $num completed: $script"
}

# Adjust the list below to match exactly the scripts you’ve created
run_step "01" "01_kmer_jellyfish.sh"
run_step "02" "02_genomescope2.R"
run_step "03" "03_hifiasm_vgp.sh"
run_step "04" "04_blobtoolkit_filter.sh"
run_step "05" "05_minimap2_clean_reads.sh"
run_step "06" "06_busco_quast_assembly.sh"
run_step "07" "07_blobtoolkit_reference.sh"
run_step "08" "08_tgsgapcloser.sh"
run_step "09" "09_ragtag_scaffold.sh"
run_step "10" "10_dotplotly.sh"
run_step "11" "11_repeatmodeler.sh"
run_step "12" "12_repeatmasker.sh"
run_step "13" "13_trinity_rnaseq.sh"
run_step "14" "14_maker_round1.sh"
run_step "15" "15_train_snap_augustus.sh"
# run_step "16" "16_maker_round2_3.sh"   # optional, if you add it

echo "All requested steps finished."
