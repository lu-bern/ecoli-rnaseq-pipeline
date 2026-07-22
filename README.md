# E. coli RNA-seq Pipeline

A reproducible RNA-seq analysis pipeline for *Escherichia coli*. This repository includes alignment, gene counting, differential expression, QC summaries, and plotting.

## Features

- Paired-end Bowtie2 alignment and Samtools sorting.
- `featureCounts` gene-level read quantification.
- DESeq2 differential expression analysis.
- FastQC and MultiQC raw-read QC summaries.
- R plotting scripts for volcano, MA, heatmap, and exploratory expression plots.
- Example dataset and sample metadata for quick validation.

## Repository structure

- `config/`: pipeline configuration templates.
- `scripts/`: active pipeline wrapper and analysis scripts.
- `example_data/`: test counts, metadata, and sample dataset.
- `results/`: generated example plots, QC summaries, and results.
- `rnaseq/`: archived raw and reference data for reference only.
- `.github/workflows/`: GitHub Actions automation.
- `docs/`: pipeline usage and details.

> The active workflow is implemented in `scripts/`; `rnaseq/` is an archival copy and not required for the example execution.

## Requirements

- `conda` or `mamba`
- Linux/macOS
- `environment.yml` defines required tools and R packages

## Setup

1. Create the conda environment:
   ```bash
   conda env create -f environment.yml
   conda activate ecoli-rnaseq
   ```
2. Update `config/pipeline.env` if you want to use a local `WORKDIR`.
3. Run the sample differential expression workflow:
   ```bash
   Rscript scripts/differential_gene_expression.R \
     --counts example_data/test_counts.csv \
     --metadata example_data/sample_metadata.tsv \
     --outdir results/diff_exp

   Rscript scripts/generate_plots.R \
     --results results/diff_exp/differential_expression_results.csv \
     --vst results/diff_exp/vst_normalized_counts.csv \
     --outdir results/plots
   ```
4. To execute the full alignment pipeline, provide FASTQ and reference files, then run:
   ```bash
   bash scripts/pipeline.sh
   ```

## Example outputs

### Differential expression results

- `results/diff_exp/differential_expression_results.csv`
- `results/diff_exp/vst_normalized_counts.csv`
- `results/diff_exp/dds_object.rds`

### Plots

![Volcano plot](results/plots/volcano_plot.png)

![MA plot](results/plots/ma_plot.png)

![Top 20 gene heatmap](results/plots/top20_heatmap.png)

### QC summaries

- `results/qc/raw_fastq/fastqc_summary.txt`
- `results/qc/alignment/sample_A.flagstat.txt`

## Notes

- `scripts/pipeline.sh` invokes `scripts/ecoli_rnaseq_gcp_pipeline.sh`.
- `config/pipeline.env` contains configurable paths and reference names.
- `example_data/test_counts.csv` and `example_data/sample_metadata.tsv` can be used to validate the DESeq2 pipeline without full raw sequencing data.

## Documentation

More details are available in `docs/README.md`.
