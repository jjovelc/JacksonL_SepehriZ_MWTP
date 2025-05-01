import sys
import os
import pandas as pd

# Define the directory containing the gene_mapping_data.txt files
directory = sys.argv[1]

# Create an empty dictionary to store gene abundance per sample
gene_abundance = {}

# Iterate over all files in the specified directory
for filename in os.listdir(directory):
    if filename.endswith(".gene_mapping_data.txt"):
        # Parse the sample name from the file name
        sample_name = filename.split("_S")[0]

        # Define the file path
        file_path = os.path.join(directory, filename)

        # Read the file into a pandas dataframe
        df = pd.read_csv(file_path, sep="\t")

        # Check that the relevant columns exist
        if 'ARO Term' in df.columns and 'All Mapped Reads' in df.columns:
            # Group by 'ARO Term' and sum 'All Mapped Reads' for abundance
            gene_sum = df.groupby('ARO Term')['All Mapped Reads'].sum()

            # Add the gene abundances for the sample to the dictionary
            for gene, abundance in gene_sum.items():
                if gene not in gene_abundance:
                    gene_abundance[gene] = {}
                gene_abundance[gene][sample_name] = abundance

# Create a DataFrame from the gene_abundance dictionary
abundance_df = pd.DataFrame(gene_abundance).fillna(0)

# Transpose the table to have samples as columns and genes as rows
abundance_df = abundance_df.T

# Save the transposed table to a tab-separated file
abundance_df.to_csv("AMR_gene_abundance_summary_transposed.tsv", sep="\t")

print("AMR gene abundance summary (transposed) has been saved to 'AMR_gene_abundance_summary_transposed.tsv'.")

