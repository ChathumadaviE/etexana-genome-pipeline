# Methods: E. texana genome assembly and annotation

This document summarizes the computational workflow implemented in this repository for assembling and annotating the ZZ male genome of *Eulimnadia texana*. It mirrors the methods described in the associated manuscript, with each section pointing to the corresponding script(s) in the `bin/` directory.

## Genome size estimation

PacBio HiFi reads from ZZ males were used to estimate genome size, heterozygosity, and repeat content. K‑mers were counted with Jellyfish (v2.2.7) using a k‑mer size of 21 and canonical k‑mers. The resulting k‑mer histogram was analyzed with GenomeScope 2.0 to obtain genome size and heterozygosity estimates. In this repository, these steps are implemented by:

- `bin/01_kmer_jellyfish.sh` – k‑mer counting and histogram generation.  
- `bin/02_genomescope2.R` – GenomeScope 2.0 analysis of the histogram.

## De novo genome assembly and decontamination

Preliminary de novo assembly of ZZ male HiFi reads was performed with the hifiasm‑based Vertebrate Genomes Project (VGP) pipeline on the Galaxy platform, including duplicate‑purging to remove alternative haplotigs and redundant contigs. The purged contigs were then decontaminated with BlobToolKit, using GC content and BUSCO‑based taxonomic assignment to remove non‑arthropod contigs and contigs with GC < 0.30 or > 0.45. Reads mapping to the clean contigs were isolated with minimap2 and used to generate the final ZZ assembly. In this repository:

- `bin/03_hifiasm_vgp.sh` records and stages the VGP/Galaxy hifiasm outputs.  
- `bin/04_blobtoolkit_filter.sh` filters preliminary contigs with BlobToolKit.  
- `bin/05_minimap2_clean_reads.sh` maps HiFi reads to clean contigs and extracts clean reads.  
- `bin/06_busco_quast_assembly.sh` runs BUSCO and QUAST on the resulting assembly.

## Reference genome curation and gap filling

The existing WW hermaphrodite reference assembly was retrieved from NCBI and screened for contamination with BlobToolKit using the same GC and taxonomic criteria as for the ZZ assembly. Gaps in the WW assembly were then filled with ZZ clean HiFi reads using TGS‑GapCloser (v1.2.1) with minimap2 alignment parameters optimized for assemblies. These steps are implemented by:

- `bin/07_blobtoolkit_reference.sh` – BlobToolKit‑based cleaning of the WW reference.  
- `bin/08_tgsgapcloser.sh` – gap filling of the WW reference with ZZ clean reads.

## Reference‑guided scaffolding and visualization

To obtain chromosome‑scale scaffolds for the ZZ genome, ZZ contigs were aligned and scaffolded against the gap‑filled WW reference using RagTag (v2.1.0), with options to infer gap sizes, concatenate unplaced contigs into a pseudo‑chromosome, and enforce a minimum unique alignment length of 200 kb. Alignments between the WW and ZZ assemblies were visualized with dotPlotly. In this repository:

- `bin/09_ragtag_scaffold.sh` runs RagTag scaffolding.  
- `bin/10_dotplotly.sh` generates whole‑genome dot plots from minimap2 alignments using your separate dotPlotly repository.

## Repeat discovery and masking

Species‑specific transposable element families were identified de novo with RepeatModeler (v2.0.5), and repeats in the ZZ assembly were annotated and soft‑masked with RepeatMasker (v4.2.1) using the custom library and rmblast. The resulting masked genome and repeat feature annotations are used by MAKER. Scripts:

- `bin/11_repeatmodeler.sh` – builds the RepeatModeler database and repeat library.  
- `bin/12_repeatmasker.sh` – runs RepeatMasker and produces masked FASTA + GFF3.

## Transcriptome assembly and evidence preparation

ZZ male RNA‑seq reads from Baldwin‑Brown et al. were assembled de novo with Trinity (v2.15.1) to provide transcript evidence that does not rely on the WW annotation. Protein homology evidence was obtained from the *Daphnia magna* proteome, chosen based on BUSCO hits observed in the ZZ assembly. Script:

- `bin/13_trinity_rnaseq.sh` – Trinity de novo transcript assembly.

## Genome annotation with MAKER

Genome annotation was performed with MAKER (v2.31.11), using the repeat‑masked ZZ genome, Trinity transcripts, *D. magna* proteins, and iterative training of the ab initio predictors SNAP and AUGUSTUS. An initial MAKER round was followed by training of SNAP (and optionally AUGUSTUS) on high‑confidence gene models, then two additional MAKER rounds incorporating the trained predictors to refine gene structures. In this repository:

- `bin/14_maker_round1.sh` – documents and stages the first MAKER run (or its Galaxy outputs).  
- `bin/15_train_snap_augustus.sh` – illustrates SNAP (and optional AUGUSTUS) training and re‑running MAKER locally.  
- Additional rounds can be orchestrated via `workflow/run_all.sh`.

## Workflow orchestration

The local components of the pipeline can be run end‑to‑end using:

- `workflow/run_all.sh` – sequentially executes the numbered scripts in `bin/` using a single YAML configuration file and supports resuming from a given step.

This document is intentionally high‑level; for exact commands and options, see the individual scripts in `bin/` and the configuration examples in `config/`.
