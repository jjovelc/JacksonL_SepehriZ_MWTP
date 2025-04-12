#!/bin/bash

# Script to run MEGAHIT assemblies on individual paired-end samples
# Usage: ./megahit_assemblies.sh /path/to/fastq/directory

# Check if directory argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/fastq/directory"
    exit 1
fi

# Directory containing FASTQ files
FASTQ_DIR=$1

# Create a directory for output assemblies
ASSEMBLY_DIR="megahit_assemblies"
mkdir -p $ASSEMBLY_DIR

# Log file
LOG_FILE="megahit_assembly.log"
echo "Starting MEGAHIT assemblies at $(date)" > $LOG_FILE

# Find all R1 files assuming standard naming convention *_R1*.fastq.gz
# Adjust the pattern if your file naming is different
R1_FILES=$(find $FASTQ_DIR -name "*_R1*.fastq.gz" | sort)

# Loop through each R1 file and find its corresponding R2 file
for R1_FILE in $R1_FILES; do
    # Extract sample name (assuming format: samplename_R1_something.fastq.gz)
    SAMPLE_NAME=$(basename $R1_FILE | sed 's/_R1.*//g')
    echo "Processing sample: $SAMPLE_NAME" | tee -a $LOG_FILE
    
    # Find corresponding R2 file
    R2_FILE=$(echo $R1_FILE | sed 's/_R1/_R2/g')
    
    # Check if R2 file exists
    if [ ! -f "$R2_FILE" ]; then
        echo "ERROR: Cannot find R2 file for $R1_FILE" | tee -a $LOG_FILE
        echo "Expected: $R2_FILE" | tee -a $LOG_FILE
        continue
    fi
    
    # Create sample-specific output directory
    SAMPLE_OUT_DIR="$ASSEMBLY_DIR/${SAMPLE_NAME}"
    
    echo "Running MEGAHIT for sample: $SAMPLE_NAME" | tee -a $LOG_FILE
    echo "  R1: $R1_FILE" | tee -a $LOG_FILE
    echo "  R2: $R2_FILE" | tee -a $LOG_FILE
    
    # Run MEGAHIT with default parameters
    # Adjust parameters as needed for your specific analysis
    megahit \
        -1 $R1_FILE \
        -2 $R2_FILE \
        -o $SAMPLE_OUT_DIR \
        --min-contig-len 500 \
        --k-min 21 \
        --k-max 141 \
        --k-step 20 \
        --memory 0.8 \
        --num-cpu-threads 48 \
        --out-prefix $SAMPLE_NAME 2>&1 | tee -a $LOG_FILE
    
    EXITCODE=$?
    if [ $EXITCODE -eq 0 ]; then
        echo "MEGAHIT completed successfully for $SAMPLE_NAME" | tee -a $LOG_FILE
        
        # Generate basic assembly statistics
        echo "Generating assembly statistics for $SAMPLE_NAME" | tee -a $LOG_FILE
        if [ -f "$SAMPLE_OUT_DIR/${SAMPLE_NAME}.contigs.fa" ]; then
            # Count number of contigs
            NUM_CONTIGS=$(grep -c "^>" $SAMPLE_OUT_DIR/${SAMPLE_NAME}.contigs.fa)
            echo "  Number of contigs: $NUM_CONTIGS" | tee -a $LOG_FILE
            
            # Calculate total assembly size
            TOTAL_SIZE=$(grep -v "^>" $SAMPLE_OUT_DIR/${SAMPLE_NAME}.contigs.fa | tr -d '\n' | wc -c)
            echo "  Total assembly size: $TOTAL_SIZE bp" | tee -a $LOG_FILE
        else
            echo "  Warning: Assembly file not found at $SAMPLE_OUT_DIR/${SAMPLE_NAME}.contigs.fa" | tee -a $LOG_FILE
        fi
    else
        echo "ERROR: MEGAHIT failed for $SAMPLE_NAME with exit code $EXITCODE" | tee -a $LOG_FILE
    fi
    
    echo "Finished processing $SAMPLE_NAME at $(date)" | tee -a $LOG_FILE
    echo "------------------------------------------------------" | tee -a $LOG_FILE
done

echo "All assemblies completed at $(date)" | tee -a $LOG_FILE
echo "Summary of assemblies:" | tee -a $LOG_FILE

# Generate summary of all assemblies
for SAMPLE_DIR in $ASSEMBLY_DIR/*; do
    if [ -d "$SAMPLE_DIR" ]; then
        SAMPLE=$(basename $SAMPLE_DIR)
        CONTIG_FILE="$SAMPLE_DIR/${SAMPLE}.contigs.fa"
        
        if [ -f "$CONTIG_FILE" ]; then
            NUM_CONTIGS=$(grep -c "^>" $CONTIG_FILE)
            TOTAL_SIZE=$(grep -v "^>" $CONTIG_FILE | tr -d '\n' | wc -c)
            
            # Find the largest contig
            MAX_CONTIG_SIZE=$(grep -v "^>" $CONTIG_FILE | awk '{print length}' | sort -nr | head -1)
            
            # Calculate N50 (simplified approach)
            SORTED_SIZES=$(grep -v "^>" $CONTIG_FILE | awk '{print length}' | sort -nr)
            HALF_SIZE=$(echo $TOTAL_SIZE/2 | bc)
            SUM=0
            N50="N/A"
            
            for SIZE in $SORTED_SIZES; do
                SUM=$((SUM + SIZE))
                if [ $SUM -ge $HALF_SIZE ]; then
                    N50=$SIZE
                    break
                fi
            done
            
            echo "$SAMPLE: $NUM_CONTIGS contigs, $TOTAL_SIZE bp total, largest contig: $MAX_CONTIG_SIZE bp, N50: $N50" | tee -a $LOG_FILE
        else
            echo "$SAMPLE: No assembly file found" | tee -a $LOG_FILE
        fi
    fi
done

echo "Done! See $LOG_FILE for detailed log."
