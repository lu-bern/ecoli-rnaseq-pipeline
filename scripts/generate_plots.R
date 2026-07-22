#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(pheatmap)
  library(RColorBrewer)
  library(dplyr)
  library(optparse)
})

WORKDIR <- "/mnt/data/rnaseq/work"

option_list = list(
  make_option(c("-d", "--dds"), type="character", default=NULL, 
              help="RDS file containing the dds object (optional)", metavar="path"),
  make_option(c("-r", "--results"), type="character", default=file.path(WORKDIR, "results/diff_exp/differential_expression.csv"), 
              help="Path to DE results CSV", metavar="path"),
  make_option(c("-v", "--vst"), type="character", default=file.path(WORKDIR, "results/diff_exp/vst_normalized_counts.csv"), 
              help="Path to VST normalized counts CSV", metavar="path"),
  make_option(c("-o", "--outdir"), type="character", default=file.path(WORKDIR, "results/plots"), 
              help="Directory for plots", metavar="path")
)

opt = parse_args(OptionParser(option_list=option_list))

if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

# --- LOAD DATA ---
res_df <- read.csv(opt$results)
vst_counts <- read.csv(opt$vst, row.names=1)

# --- 1. VOLCANO PLOT ---
cat(">>> Generating Volcano Plot...\n")
volcano <- ggplot(res_df, aes(x=log2FoldChange, y=-log10(padj))) +
  geom_point(aes(color = (abs(log2FoldChange) > 1 & padj < 0.05)), alpha=0.5) +
  scale_color_manual(values = c("black", "red")) +
  theme_minimal() +
  geom_vline(xintercept=c(-1, 1), linetype="dashed") +
  geom_hline(yintercept=-log10(0.05), linetype="dashed") +
  labs(title="Volcano Plot: Differential Expression",
       subtitle="Red points: |log2FC| > 1 and adj. p < 0.05",
       x="log2 Fold Change", y="-log10 Adjusted P-value") +
  theme(legend.position = "none")

ggsave(file.path(opt$outdir, "volcano_plot.png"), volcano, width=8, height=6)

# --- 2. MA PLOT ---
cat(">>> Generating MA Plot...\n")
ma_plot <- ggplot(res_df, aes(x=baseMean, y=log2FoldChange)) +
  geom_point(aes(color = (padj < 0.05)), alpha=0.4) +
  scale_x_log10() +
  scale_color_manual(values = c("black", "blue")) +
  theme_minimal() +
  geom_hline(yintercept=0, color="red") +
  labs(title="MA Plot", x="Mean of Normalized Counts", y="log2 Fold Change")

ggsave(file.path(opt$outdir, "ma_plot.png"), ma_plot, width=8, height=6)

# --- 3. HEATMAP OF TOP 30 GENES ---
cat(">>> Generating Heatmap...\n")
top_genes <- res_df %>%
  filter(!is.na(padj)) %>%
  arrange(padj) %>%
  head(30) %>%
  pull(locus_tag)

if(length(top_genes) > 0) {
  hm_matrix <- vst_counts[top_genes, ]
  # Z-score scaling by row
  hm_matrix_scaled <- t(apply(hm_matrix, 1, scale))
  colnames(hm_matrix_scaled) <- colnames(hm_matrix)
  
  png(file.path(opt$outdir, "top30_heatmap.png"), width=800, height=1000)
  pheatmap(hm_matrix_scaled, 
           main="Top 30 Differentially Expressed Genes (Z-scores)",
           color = colorRampPalette(c("blue", "white", "red"))(100),
           border_color = NA)
  dev.off()
}

cat(">>> All plots saved to:", opt$outdir, "\n")
