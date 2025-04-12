#!/bin/bash


# Update AMRFinder database
echo "Updating AMRFinder database..."
DB_DIR="/work/vetmed_data/mamba/envs/amrplus/bin/data"
amrfinder_update --force_update --database "$DB_DIR"

# Create directories if they don't exist
mkdir -p /work/vetmed_data/mamba/envs/amrplus/share/amrfinderplus/data/

# Create a symbolic link from where AMRFinder expects the database to where it actually is
ln -sf "$DB_DIR/2025-03-25.1" /work/vetmed_data/mamba/envs/amrplus/share/amrfinderplus/data/latest


# Make a directory to store results
mkdir -p amrfinder_results

# Loop through directories ending with L004
for dir in *L004/; do
    # Find the first fasta file in the directory (adjust extension if needed)
    assembly=$(find "$dir" -maxdepth 1 -type f \( -name "*.fasta" -o -name "*.fa" -o -name "*.fna" \) | head -n 1)

    if [[ -f "$assembly" ]]; then
        sample_name=$(basename "$dir" | sed 's/\/$//')
        output_file="amrfinder_results/${sample_name}_amrfinder.txt"

        echo "Running AMRFinder on $assembly..."
        amrfinder -n "$assembly" -o "$output_file"
    else
        echo "No fasta file found in $dir"
    fi
done

echo "All done!"
