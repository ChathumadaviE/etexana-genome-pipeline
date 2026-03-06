# etexana-genome-pipeline

Reproducible long-read genome assembly and annotation workflow for the ZZ male genome of *Eulimnadia texana*.  
The pipeline combines k‑mer–based genome size estimation, PacBio HiFi assembly, contamination filtering, reference‑guided scaffolding, repeat masking, and MAKER‑based gene prediction using RNA‑seq and protein homology evidence.

## Overview

- Genome size estimation with Jellyfish (k‑mer counting) and GenomeScope 2.0.  
- Preliminary de novo assembly using the Vertebrate Genomes Project (VGP) hifiasm pipeline on the Galaxy platform.  
- Contamination detection and removal with BlobToolKit and BUSCO‑based taxonomic filtering.  
- Reference gap filling of the WW hermaphrodite assembly with ZZ HiFi reads using TGS‑GapCloser and minimap2.  
- Reference‑guided scaffolding of ZZ contigs onto the gap‑filled WW assembly with RagTag and visualization with dotPlotly.  
- Repeat identification with RepeatModeler and soft‑masking with RepeatMasker.  
- Genome annotation with MAKER, integrating Trinity‑assembled ZZ transcripts, *Daphnia magna* protein homology, and iterative training of SNAP and AUGUSTUS.

## Galaxy vs HPC components

- **Galaxy (VGP pipeline):**  
  - hifiasm‑based de novo assembly and duplicate‑purging (preliminary ZZ contigs).
  - Link: https://training.galaxyproject.org/training-material/topics/assembly/tutorials/vgp_workflow_training/tutorial.html
  - BUSCO and QUAST runs reported in the manuscript.  

- **HPC (Rocky Linux 8.5 + SLURM):**  
  - All other steps in this repository (k‑mer/GenomeScope, BlobToolKit filtering, gap filling, RagTag scaffolding, repeats, Trinity, MAKER rounds).

The purged contig FASTA from the Galaxy VGP pipeline is used as input to the local scripts provided here.

## Installation

1. Clone this repository:

```bash
git clone https://github.com/<your-username>/etexana-genome-pipeline.git
cd etexana-genome-pipeline
```

Create the Conda environment:

```bash
mamba env create -f envs/conda-genome.yml
mamba activate etexana-genome
(If you use conda instead of mamba, replace mamba with conda.)
```

Inputs
Expected main inputs:
1. PacBio HiFi reads from ZZ males (FASTQ).
2. RNA‑seq reads from ZZ males for transcript assembly (FASTQ).
3. WW hermaphrodite reference genome assembly (FASTA).
4. Purged ZZ contigs from the VGP hifiasm Galaxy pipeline (FASTA).
5. Paths to these files are specified in a YAML config file (see config/example_paths.yaml).

Basic usage
Once inputs and config are set, the local part of the workflow can be run as:

```bash
bash workflow/run_all.sh -c config/example_paths.yaml
This script sequentially runs the numbered modules in bin/ (k‑mer counting, contamination filtering, gap filling, scaffolding, repeats, and annotation).
```

Status and future work
This repository currently focuses on the HPC‑side scripts and configuration for the E. texana analysis described in the manuscript.
Next steps include:

Adding a small test dataset and example configuration.

Wrapping the pipeline in a workflow manager (e.g. Nextflow) for fully automated, portable execution.
