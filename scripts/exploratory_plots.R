#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tibble)
  library(optparse)
})

option_list <- list(
  make_option(c("-c", "--counts"), type = "character", default = "results/diff_exp/vst_normalized_counts.csv",
              help = "Path to normalized counts CSV", metavar = "path"),
  make_option(c("-o", "--outdir"), type = "character", default = "results/plots",
              help = "Directory for output plots", metavar = "path")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

vst_counts <- read_csv(opt$counts)
if ("gene" %in% colnames(vst_counts)) {
  vst_counts <- vst_counts %>% column_to_rownames("gene")
}

expr_values <- vst_counts[, 1]

df_dist <- data.frame(log_counts = log10(expr_values + 1))
p1 <- ggplot(df_dist, aes(x = log_counts)) +
  geom_density(fill = "forestgreen", alpha = 0.4) +
  labs(title = "Expression Distribution", x = "Log10(Normalized Counts + 1)", y = "Density") +
  theme_minimal()

counts_sorted <- sort(expr_values, decreasing = TRUE)
df_cum <- data.frame(counts = counts_sorted) %>%
  mutate(cum_sum = cumsum(counts) / sum(counts) * 100,
         index = row_number() / n() * 100)

p2 <- ggplot(df_cum, aes(x = index, y = cum_sum)) +
  geom_line(color = "firebrick", size = 1) +
  labs(title = "Cumulative Expression Curve",
       x = "% of Genes (Sorted by Expression)",
       y = "% of Total Library Expression") +
  theme_minimal()

ggsave(file.path(opt$outdir, "count_density.png"), p1, width = 7, height = 5)
ggsave(file.path(opt$outdir, "cumulative_expression.png"), p2, width = 7, height = 5)
cat("Exploratory plots saved to", opt$outdir, "\n")
