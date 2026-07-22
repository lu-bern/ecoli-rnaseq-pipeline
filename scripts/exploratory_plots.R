#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr)

# Load data
counts <- read.csv("/mnt/data/rnaseq/work/results/diff_exp/clean_counts.csv", row.names=1)
sample_val <- counts[[1]]

# 1. Density Plot (Distribution of Log Counts)
df_dist <- data.frame(log_counts = log10(sample_val + 1))
p1 <- ggplot(df_dist, aes(x=log_counts)) +
  geom_density(fill="forestgreen", alpha=0.4) +
  labs(title="Gene Expression Distribution", x="Log10(Counts + 1)", y="Density") +
  theme_minimal()

# 2. Cumulative Expression Plot
df_cum <- data.frame(counts = sort(sample_val, decreasing=TRUE)) %>%
  mutate(cum_sum = cumsum(counts) / sum(counts) * 100,
         index = row_number() / n() * 100)

p2 <- ggplot(df_cum, aes(x=index, y=cum_sum)) +
  geom_line(color="firebrick", size=1) +
  labs(title="Cumulative Expression Curve", 
       x="% of Genes (Sorted by Expression)", 
       y="% of Total Library Reads") +
  theme_minimal()

# Save both
ggsave("/mnt/data/rnaseq/work/results/plots/count_density.png", p1)
ggsave("/mnt/data/rnaseq/work/results/plots/cumulative_expression.png", p2)
cat("Exploratory plots saved to /mnt/data/rnaseq/work/results/plots/\n")
