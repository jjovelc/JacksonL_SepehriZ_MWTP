import sys
import os
import pandas as pd
import matplotlib.pyplot as plt

# Check command-line arguments
if len(sys.argv) != 3:
    print("Usage: python script.py <directory> <top_n>")
    sys.exit(1)

directory = sys.argv[1]
top_n = int(sys.argv[2])

# Dictionary to store abundance data
gene_abundance = {}

# Parse files
for filename in os.listdir(directory):
    if filename.endswith(".gene_mapping_data.txt"):
        sample_name = filename.split("_S")[0]
        file_path = os.path.join(directory, filename)
        df = pd.read_csv(file_path, sep="\t")

        if 'ARO Term' in df.columns and 'All Mapped Reads' in df.columns:
            gene_sum = df.groupby('ARO Term')['All Mapped Reads'].sum()

            for gene, abundance in gene_sum.items():
                if gene not in gene_abundance:
                    gene_abundance[gene] = {}
                gene_abundance[gene][sample_name] = abundance

# Convert to DataFrame
abundance_df = pd.DataFrame(gene_abundance).fillna(0)
abundance_df = abundance_df.T  # rows = genes, cols = samples

# Normalize by total reads per sample (relative abundance)
relative_abundance = abundance_df.div(abundance_df.sum(axis=0), axis=1)

# Identify top N genes by total relative abundance across all samples
top_genes = relative_abundance.sum(axis=1).nlargest(top_n).index

# Subset and transpose for plotting (samples as x-axis)
plot_data = relative_abundance.loc[top_genes]
plot_data = plot_data.T

# Plot
plot_data.plot(kind='bar', stacked=True, figsize=(12, 6))
plt.ylabel("Relative Abundance")
plt.xlabel("Sample")
plt.title(f"Top {top_n} AMR Genes by Relative Abundance")
plt.legend(title="AMR Gene", bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()
plt.savefig("top_AMR_genes_stacked_barplot.png", dpi=300)

# Also save table
plot_data.T.to_csv("top_AMR_relative_abundance.tsv", sep="\t")

print("Plot saved as 'top_AMR_genes_stacked_barplot.png'")
print("Data saved as 'top_AMR_relative_abundance.tsv'")

