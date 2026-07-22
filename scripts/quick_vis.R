#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
  library(dplyr)
  library(tibble)
  library(optparse)
})

option_list <- list(
  make_option(c("-c", "--counts"), type = "character", default = "results/diff_exp/vst_normalized_counts.csv",
              help = "Path to normalized counts CSV", metavar = "path"),
  make_option(c("-o", "--outdir"), type = "character", default = "results/plots",
              help = "Output directory for plots", metavar = "path")
)

opt <- parse_args(OptionParser(option_list = option_list))
if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

counts <- read_csv(opt$counts)
if ("gene" %in% colnames(counts)) {
  counts <- counts %>% column_to_rownames("gene")
}

sample_name <- colnames(counts)[1]
top20 <- counts %>%
  arrange(desc(.data[[sample_name]])) %>%
  head(20) %>%
  rownames_to_column("gene")

p <- ggplot(top20, aes(x = reorder(gene, .data[[sample_name]]), y = .data[[sample_name]])) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = paste("Top 20 Expressed Genes:", sample_name),
       subtitle = "Organism: E. coli",
       x = "Gene ID", y = "Normalized Counts") +
  theme_minimal()

output_path <- file.path(opt$outdir, "top_20_expression.png")
ggsave(output_path, plot = p, width = 8, height = 6)
cat("Success! Plot saved to:", output_path, "\n")
