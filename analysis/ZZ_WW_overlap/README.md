# ZZ–WW genome overlap analysis

This directory contains scripts to quantify sequence overlap between the *Eulimnadia texana* ZZ male assembly and the WW hermaphrodite reference genome.

## Inputs

- **WW reference (cleaned)**
  - FASTA file of the decontaminated WW assembly  
  - Example: `WW_cleaned.fasta`

- **ZZ assembly**
  - Scaffold-level ZZ RagTag assembly FASTA  
  - Example: `ZZ_RagTag_scaffolds.fasta`

- **Alignment file (PAF)**
  - Output of minimap2 asm-to-asm alignment of ZZ onto WW  
  - Example: `ZZ_on_WW.paf`

## Generate ZZ-on-WW alignment

```bash
module load minimap2   # adjust for your HPC environment

REF=WW_cleaned.fasta
QUERY=ZZ_RagTag_scaffolds.fasta
OUT=ZZ_on_WW.paf

minimap2 -x asm10 -t 24 "${REF}" "${QUERY}" > "${OUT}"
```

-x asm10 selects the assembly-to-assembly preset.

WW is used as the reference, ZZ as the query.

Genome-wide ZZ overlap
compute_ZZ_WW_overlap.py reports the fraction of the ZZ assembly that aligns to WW at different identity thresholds.
```
python compute_ZZ_WW_overlap.py ZZ_on_WW.paf
```

Example output (values are illustrative):
Identity ≥90%: aligned 42220000 bp of 112931588 bp (37.4% of ZZ assembly)
Identity ≥80%: aligned 51330000 bp of 112931588 bp (45.5% of ZZ assembly)

These percentages are calculated by:

selecting primary alignments only, filtering by percent identity, merging non-overlapping intervals per ZZ scaffold, 
dividing total aligned ZZ bases by total ZZ assembly size.

WW scaffold-level coverage
compute_WW_scaffold_coverage.py summarizes coverage of each WW scaffold by ZZ at a chosen identity threshold.
```
# For 90% identity
python compute_WW_scaffold_coverage.py ZZ_on_WW.paf 0.90 > WW_scaffold_coverage_90.tsv

# For 80% identity
python compute_WW_scaffold_coverage.py ZZ_on_WW.paf 0.80 > WW_scaffold_coverage_80.tsv
```

Each output file has columns:
scaffold    length_bp   covered_bp   percent_covered

Coverage is computed by merging non-overlapping aligned intervals per WW scaffold (regardless of strand) and dividing by the full scaffold length.

Reproducibility notes
All scripts are plain Python and require only the standard library.
Alignment parameters and identity thresholds (e.g. 90% vs 80%) are explicitly documented here to match the values reported in the manuscript.
Version information (minimap2, reference FASTA, ZZ assembly FASTA) should be recorded in the main pipeline README or a separate VERSIONS.md file.
