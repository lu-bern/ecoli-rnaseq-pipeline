#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(DESeq2)
  library(readr)
  library(dplyr)
  library(tibble)
  library(optparse)
})

option_list <- list(
  make_option(c("-c", "--counts"), type = "character", default = NULL,
              help = "Path to the counts CSV matrix", metavar = "path"),
  make_option(c("-m", "--metadata"), type = "character", default = NULL,
              help = "Path to the sample metadata TSV", metavar = "path"),
  make_option(c("-o", "--outdir"), type = "character", default = "results/diff_exp",
              help = "Output directory for DESeq2 results", metavar = "path")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$counts) || is.null(opt$metadata)) {
  stop("Please provide both --counts and --metadata arguments.")
}

if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

counts <- read_csv(opt$counts)
metadata <- read_tsv(opt$metadata)

if (!"sample" %in% colnames(metadata) || !"condition" %in% colnames(metadata)) {
  stop("Metadata must contain 'sample' and 'condition' columns.")
}

if (!"gene" %in% colnames(counts)) {
  stop("Counts CSV must contain a 'gene' column.")
}

count_matrix <- counts %>% column_to_rownames("gene")
metadata <- metadata %>% filter(sample %in% colnames(count_matrix))
metadata <- metadata %>% mutate(condition = factor(condition))
metadata <- metadata %>% arrange(sample)
count_matrix <- count_matrix[, metadata$sample, drop = FALSE]

if (nrow(metadata) < 2) {
  stop("At least two samples are required for differential expression analysis.")
}

dds <- DESeqDataSetFromMatrix(countData = count_matrix,
                              colData = metadata,
                              design = ~ condition)

keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep, ]

dds <- DESeq(dds)

condition_levels <- levels(metadata$condition)
if (length(condition_levels) != 2) {
  stop("DESeq2 comparison currently supports exactly two conditions. Found: ", paste(condition_levels, collapse = ", "))
}

contrast <- c("condition", condition_levels[2], condition_levels[1])
res <- results(dds, contrast = contrast, alpha = 0.05)
res <- lfcShrink(dds, contrast = contrast, type = "apeglm")
res_df <- as.data.frame(res) %>% rownames_to_column("gene")

vsd <- vst(dds, blind = FALSE)
vsd_mat <- assay(vsd)

write_csv(res_df, file.path(opt$outdir, "differential_expression_results.csv"))
write_csv(as.data.frame(vsd_mat) %>% rownames_to_column("gene"),
          file.path(opt$outdir, "vst_normalized_counts.csv"))
saveRDS(dds, file.path(opt$outdir, "dds_object.rds"))

message("DESeq2 differential expression completed. Results saved to ", opt$outdir)
