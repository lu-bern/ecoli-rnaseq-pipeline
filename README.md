# E. coli RNA-seq Pipeline

A reproducible RNA-seq analysis pipeline for Escherichia coli. The repository includes alignment, feature counting, differential expression, and plotting utilities.

## Features

- Bowtie2 alignment for paired-end RNA-seq reads.
- Samtools BAM conversion and sorting.
- `featureCounts` read summarization.
- DESeq2-based differential expression analysis.
- R scripts for volcano, MA, heatmap, and exploratory expression plots.

## Repository structure

- `config/`: pipeline configuration templates.
- `scripts/`: pipeline wrapper and analysis scripts.
- `example_data/`: sample dataset for quick evaluation.
- `results/`: example output files and generated plots.
- `rnaseq/`: archived raw data, reference files, and additional outputs. This subtree is an archival copy of project inputs and outputs rather than the active pipeline entrypoint.
- `workflow/`: placeholder directory for workflow definitions. It is currently reserved for future workflow automation files.
- `docs/`: documentation and usage notes.

> Note: The active pipeline is defined in `scripts/` and invoked via `scripts/pipeline.sh`; `rnaseq/` is kept for reference and archival purposes.

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
2. Review and update `config/pipeline.env` to match your local file layout and reference names.
3. Run the pipeline wrapper:
   ```bash
   bash scripts/pipeline.sh
   ```

## Notes

- `scripts/pipeline.sh` launches the main pipeline wrapper located at `scripts/ecoli_rnaseq_gcp_pipeline.sh`.
- The pipeline sources the configuration file at `config/pipeline.env` when present.
- Example results and plots are available under `results/`.
- `workflow/` is currently a placeholder for future Snakemake or workflow definitions.

## Documentation

More details are available in `docs/README.md`.
