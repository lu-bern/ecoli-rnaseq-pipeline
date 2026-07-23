# E. coli RNA-seq Pipeline Documentation

This repository provides a reproducible RNA-seq analysis pipeline for *Escherichia coli*.

## Overview

The repository includes:

- a Bash-based pipeline wrapper for raw read alignment, sorting, and gene counting
- configurable pipeline settings in `config/pipeline.env`
- DESeq2-based differential expression analysis scripts in `scripts/`
- sample counts and metadata in `example_data/`
- QC and plotting outputs in `results/`
- GitHub Actions CI in `.github/workflows/`

## Local setup

1. Create the environment:
   ```bash
   conda env create -f environment.yml
   conda activate ecoli-rnaseq
   ```
2. Edit `config/pipeline.env` if you want to change `WORKDIR`, FASTQ location, or reference names.
3. Add paired-end FASTQ files to `raw_fastq/` with the pattern `<sample>_1.fastq.gz` and `<sample>_2.fastq.gz`.

Bioconductor note:

If a Bioconductor package is missing from the conda channels on your platform, install it in R after activating the environment:

```r
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
BiocManager::install(c("DESeq2", "apeglm"), update = FALSE, ask = FALSE)
```

## Quick validation

Use the sample count dataset to verify the analysis scripts:

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

## Full pipeline

Run the full wrapper when raw reads and references are available:

```bash
bash scripts/pipeline.sh
```

This will run raw-read QC, build or reuse Bowtie2 indexes, align paired-end samples, generate alignment QC summaries, and count genes with `featureCounts`.

## Results

- `results/qc/raw_fastq/` contains raw-read QC summaries
- `results/qc/alignment/` contains alignment flagstat output
- `results/diff_exp/` contains DESeq2 results and normalized counts
- `results/plots/` contains visualization outputs

## Notes

- The primary pipeline is in `scripts/`; the `rnaseq/` directory is archived raw/reference data and not required for example usage.
- GitHub Actions in `.github/workflows/main.yml` validates the R scripts and shell wrapper.
