#!/usr/bin/env Rscript

# Load necessary library
library(ggplot2)

# 1. Load your counts
# We use the clean_counts.csv we generated earlier
counts <- read.csv("/mnt/data/rnaseq/work/results/diff_exp/clean_counts.csv", row.names=1)

# 2. Sort by expression and take the top 20
# We assume the first data column is your sample
sample_name <- colnames(counts)[1]
top20 <- head(counts[order(counts[[sample_name]], decreasing=TRUE), , drop=FALSE], 20)
top20$Gene <- rownames(top20)

# 3. Create the plot
p <- ggplot(top20, aes(x=reorder(Gene, .data[[sample_name]]), y=.data[[sample_name]])) +
  geom_bar(stat="identity", fill="steelblue") +
  coord_flip() +
  labs(title=paste("Top 20 Expressed Genes:", sample_name),
       subtitle="Organism: E. coli",
       x="Gene ID (Locus Tag)", 
       y="Read Counts") +
  theme_minimal()

# 4. Save the plot to your results folder
output_path <- "/mnt/data/rnaseq/work/results/plots/top_20_expression.png"
dir.create("/mnt/data/rnaseq/work/results/plots", showWarnings = FALSE, recursive = TRUE)
ggsave(output_path, plot=p, width=8, height=6)

cat("Success! Plot saved to:", output_path, "\n")
