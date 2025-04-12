# Script to run abricate on all contigs
#!/bin/bash

# Activate abricate environment
eval "$(conda shell.bash hook)"
conda activate abricate

# Make a directory to store results
mkdir -p abricate_results

# Loop through directories ending with L004
for dir in *L004/; do
    # Find the first fasta file in the directory (adjust extension if needed)
    assembly=$(find "$dir" -maxdepth 1 -type f \( -name "*.fasta" -o -name "*.fa" -o -name "*.fna" \) | head -n 1)

    if [[ -f "$assembly" ]]; then
        sample_name=$(basename "$dir" | sed 's/\/$//')
        output_file="abricate_results/${sample_name}_abricate.txt"

        echo "Running abricate on $assembly..."
        abricate "$assembly" > "$output_file"
    else
        echo "No fasta file found in $dir"
    fi
done

echo "All done!"

