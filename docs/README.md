# E. coli RNA-seq Pipeline Documentation

This repository provides a reproducible RNA-seq analysis pipeline for *Escherichia coli*.

## Overview

The project includes:

- a Bash-based pipeline wrapper for alignment, sorting, and gene counting
- configuration templates in `config/pipeline.env`
- RNA-seq analysis scripts in `scripts/`
- example outputs in `results/`
- archived reference and sample data in `rnaseq/`

## Setup

1. Create the Conda environment:
   ```bash
   conda env create -f environment.yml
   conda activate ecoli-rnaseq
   ```

2. Edit `config/pipeline.env` to point to your reference files and sample directory.

3. Place paired-end FASTQ files in `raw_fastq/` using the naming convention `<sample>_1.fastq.gz` and `<sample>_2.fastq.gz`.

## Running the pipeline

Use the wrapper script:

```bash
bash scripts/pipeline.sh
```

This script loads `config/pipeline.env` and then runs the main pipeline wrapper at `scripts/ecoli_rnaseq_gcp_pipeline.sh`.

## Expected outputs

The pipeline writes files under the configured `WORKDIR`:

- `reference/` for genome FASTA and annotation files
- `results/aligned/` for sorted BAM files
- `results/counts/` for featureCounts output

## Analysis scripts

- `scripts/differential_gene_expression.R` — differential expression analysis and plot generation
- `scripts/generate_plots.R` — volcano, MA, and heatmap plotting
- `scripts/exploratory_plots.R` — expression distribution and cumulative expression plots
- `scripts/quick_vis.R` — top 20 expressed gene bar plot

## Notes

- `workflow/` is currently a placeholder for future workflow automation files.
- Example result files are preserved in `results/`.
- The `rnaseq/` directory contains archived data and reference materials used for this project.
