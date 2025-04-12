#!/bin/bash

# Script to run metaQUAST on all contig files from MEGAHIT assemblies
# Create output directory for metaQUAST results
METAQUAST_DIR="metaquast_results"
mkdir -p $METAQUAST_DIR

# Log file
LOG_FILE="metaquast_analysis.log"
echo "Starting metaQUAST analysis at $(date)" > $LOG_FILE

# Find all contig files
CONTIG_FILES=$(find . -name "*_L004.contigs.fa" | sort)

# Check if any contig files were found
if [ -z "$CONTIG_FILES" ]; then
    echo "ERROR: No contig files found!" | tee -a $LOG_FILE
    exit 1
fi

echo "Found $(echo "$CONTIG_FILES" | wc -l) contig files to analyze" | tee -a $LOG_FILE

# Run metaQUAST on each contig file individually
for CONTIG_FILE in $CONTIG_FILES; do
    # Extract sample name from file path
    SAMPLE_NAME=$(basename $(dirname $CONTIG_FILE))
    echo "Processing sample: $SAMPLE_NAME" | tee -a $LOG_FILE
    echo "Contig file: $CONTIG_FILE" | tee -a $LOG_FILE
    
    # Create sample-specific output directory
    SAMPLE_OUT_DIR="$METAQUAST_DIR/$SAMPLE_NAME"
    
    # Run metaQUAST
    echo "Running metaQUAST for $SAMPLE_NAME at $(date)" | tee -a $LOG_FILE
    metaquast.py \
        --threads 24 \
        --min-contig 500 \
        --output-dir $SAMPLE_OUT_DIR \
        --labels $SAMPLE_NAME \
        $CONTIG_FILE 2>&1 | tee -a $LOG_FILE
    
    # Check if metaQUAST completed successfully
    if [ $? -eq 0 ]; then
        echo "metaQUAST completed successfully for $SAMPLE_NAME" | tee -a $LOG_FILE
    else
        echo "ERROR: metaQUAST failed for $SAMPLE_NAME" | tee -a $LOG_FILE
    fi
    
    echo "Finished processing $SAMPLE_NAME at $(date)" | tee -a $LOG_FILE
    echo "------------------------------------------------------" | tee -a $LOG_FILE
done

echo "All metaQUAST analyses completed at $(date)" | tee -a $LOG_FILE

# Run a combined metaQUAST analysis for all samples
echo "Starting combined metaQUAST analysis of all samples at $(date)" | tee -a $LOG_FILE

# Create a file with all contig files and their labels
CONTIG_LIST="contigs_list.txt"
> $CONTIG_LIST
LABELS=""

for CONTIG_FILE in $CONTIG_FILES; do
    SAMPLE_NAME=$(basename $(dirname $CONTIG_FILE))
    echo "$CONTIG_FILE" >> $CONTIG_LIST
    if [ -z "$LABELS" ]; then
        LABELS="$SAMPLE_NAME"
    else
        LABELS="$LABELS,$SAMPLE_NAME"
    fi
done

# Create a combined output directory
COMBINED_OUT_DIR="$METAQUAST_DIR/combined_analysis"

# Run combined metaQUAST
echo "Running combined metaQUAST analysis at $(date)" | tee -a $LOG_FILE
metaquast.py \
    --threads 8 \
    --min-contig 500 \
    --output-dir $COMBINED_OUT_DIR \
    --labels $LABELS \
    $(cat $CONTIG_LIST) 2>&1 | tee -a $LOG_FILE

# Check if combined metaQUAST completed successfully
if [ $? -eq 0 ]; then
    echo "Combined metaQUAST analysis completed successfully" | tee -a $LOG_FILE
else
    echo "ERROR: Combined metaQUAST analysis failed" | tee -a $LOG_FILE
fi

# Clean up
rm -f $CONTIG_LIST

echo "All analyses completed at $(date)" | tee -a $LOG_FILE
echo "Results are available in $METAQUAST_DIR directory" | tee -a $LOG_FILE

# Generate a summary of the main metaQUAST results
echo "Generating summary report..." | tee -a $LOG_FILE
SUMMARY_FILE="$METAQUAST_DIR/summary_report.txt"
echo "METAQUAST SUMMARY REPORT - Generated on $(date)" > $SUMMARY_FILE
echo "================================================" >> $SUMMARY_FILE

for SAMPLE_DIR in $METAQUAST_DIR/*; do
    # Skip if not a directory or is the combined analysis directory
    if [ ! -d "$SAMPLE_DIR" ] || [ "$(basename $SAMPLE_DIR)" == "combined_analysis" ]; then
        continue
    fi
    
    SAMPLE=$(basename $SAMPLE_DIR)
    REPORT_FILE="$SAMPLE_DIR/report.txt"
    
    if [ -f "$REPORT_FILE" ]; then
        echo "" >> $SUMMARY_FILE
        echo "SAMPLE: $SAMPLE" >> $SUMMARY_FILE
        echo "----------------" >> $SUMMARY_FILE
        
        # Extract key metrics
        N50=$(grep "N50" $REPORT_FILE | head -1 | awk '{print $2}')
        TOTAL_LENGTH=$(grep "Total length" $REPORT_FILE | head -1 | awk '{print $3}')
        NUM_CONTIGS=$(grep "# contigs" $REPORT_FILE | head -1 | awk '{print $3}')
        LARGEST_CONTIG=$(grep "Largest contig" $REPORT_FILE | head -1 | awk '{print $3}')
        GC=$(grep "GC (%)" $REPORT_FILE | head -1 | awk '{print $3}')
        
        echo "N50: $N50" >> $SUMMARY_FILE
        echo "Total length: $TOTAL_LENGTH" >> $SUMMARY_FILE
        echo "Number of contigs: $NUM_CONTIGS" >> $SUMMARY_FILE
        echo "Largest contig: $LARGEST_CONTIG" >> $SUMMARY_FILE
        echo "GC content: $GC%" >> $SUMMARY_FILE
    else
        echo "" >> $SUMMARY_FILE
        echo "SAMPLE: $SAMPLE" >> $SUMMARY_FILE
        echo "Report file not found." >> $SUMMARY_FILE
    fi
done

echo "Summary report generated: $SUMMARY_FILE" | tee -a $LOG_FILE
echo "Done!"
