#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(pheatmap)
  library(dplyr)
  library(readr)
  library(tibble)
  library(optparse)
})

option_list <- list(
  make_option(c("-r", "--results"), type = "character",
              default = "results/diff_exp/differential_expression_results.csv",
              help = "Path to DESeq2 results CSV", metavar = "path"),
  make_option(c("-v", "--vst"), type = "character",
              default = "results/diff_exp/vst_normalized_counts.csv",
              help = "Path to VST normalized counts CSV", metavar = "path"),
  make_option(c("-o", "--outdir"), type = "character",
              default = "results/plots",
              help = "Directory for output plots", metavar = "path")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

res_df <- read_csv(opt$results)
vst_counts <- read_csv(opt$vst)

if ("gene" %in% colnames(vst_counts)) {
  vst_counts <- vst_counts %>% column_to_rownames("gene")
}

res_df <- res_df %>%
  mutate(significant = if_else(!is.na(padj) & padj < 0.05 & abs(log2FoldChange) > 1, "TRUE", "FALSE"))

volcano <- ggplot(res_df, aes(x = log2FoldChange, y = -log10(padj), color = significant)) +
  geom_point(alpha = 0.7, size = 1.5) +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  theme_minimal() +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed") +
  labs(title = "Volcano Plot", x = "log2 Fold Change", y = "-log10 Adjusted P-value") +
  theme(legend.position = "none")

ggsave(file.path(opt$outdir, "volcano_plot.png"), volcano, width = 7, height = 6)

ma_plot <- ggplot(res_df, aes(x = baseMean, y = log2FoldChange, color = significant)) +
  geom_point(alpha = 0.6, size = 1.5) +
  scale_x_log10() +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "blue")) +
  theme_minimal() +
  geom_hline(yintercept = 0, color = "red") +
  labs(title = "MA Plot", x = "Mean of Normalized Counts", y = "log2 Fold Change")

ggsave(file.path(opt$outdir, "ma_plot.png"), ma_plot, width = 7, height = 6)

if (nrow(res_df) > 0) {
  top_genes <- res_df %>%
    filter(!is.na(padj)) %>%
    arrange(padj) %>%
    slice_head(n = 20) %>%
    pull(gene)

  if (length(top_genes) > 0) {
    heatmap_matrix <- vst_counts[top_genes, , drop = FALSE]
    heatmap_scaled <- t(scale(t(heatmap_matrix)))

    png(file.path(opt$outdir, "top20_heatmap.png"), width = 900, height = 900)
    pheatmap(heatmap_scaled,
             main = "Top 20 Differentially Expressed Genes",
             color = colorRampPalette(c("navy", "white", "firebrick"))(100),
             show_rownames = TRUE,
             show_colnames = TRUE)
    dev.off()
  }
}

message("Plot generation completed. Files written to ", opt$outdir)
