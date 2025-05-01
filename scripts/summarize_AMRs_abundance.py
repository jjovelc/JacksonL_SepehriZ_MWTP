import sys
import os
import pandas as pd

# Define the directory containing the gene_mapping_data.txt files
directory = sys.argv[1]

# Create an empty dictionary to store the gene counts
gene_counts = {}

# Iterate over all files in the specified directory
for filename in os.listdir(directory):
    if filename.endswith(".gene_mapping_data.txt"):
        # Parse the sample name from the file name
        sample_name = filename.split("_S")[0]

        # Define the file path
        file_path = os.path.join(directory, filename)

        # Read the file into a pandas dataframe
        df = pd.read_csv(file_path, sep="\t")

        # Check that the relevant column exists
        if 'ARO Term' in df.columns:
            # Count occurrences of each gene in the 'ARO Term' column
            gene_count = df['ARO Term'].value_counts()

            # Add the gene counts for the sample to the dictionary
            for gene, count in gene_count.items():
                if gene not in gene_counts:
                    gene_counts[gene] = {}
                gene_counts[gene][sample_name] = count

# Create a DataFrame from the gene_counts dictionary
count_df = pd.DataFrame(gene_counts).fillna(0)

# Transpose the table to have samples as columns and genes as rows
count_df = count_df.T

# Save the transposed table to a tab-separated file
count_df.to_csv("AMR_gene_counts_summary_transposed.tsv", sep="\t")

print("AMR gene counts summary (transposed) has been saved to 'AMR_gene_counts_summary_transposed.tsv'.")

