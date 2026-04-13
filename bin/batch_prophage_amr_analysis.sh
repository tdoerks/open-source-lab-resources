#!/bin/bash
#
# Batch Prophage-AMR Intersection Analysis
#
# Analyzes all samples in a COMPASS results directory to identify
# AMR genes encoded within prophage regions.
#
# Usage:
#   bash bin/batch_prophage_amr_analysis.sh /path/to/compass_results output_directory
#
# Example:
#   bash bin/batch_prophage_amr_analysis.sh \
#       /fastscratch/tylerdoe/vibrio_cholerae_results \
#       /fastscratch/tylerdoe/vibrio_prophage_amr_analysis
#

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <compass_results_dir> <output_dir>"
    echo ""
    echo "Example:"
    echo "  $0 /fastscratch/tylerdoe/vibrio_cholerae_results vibrio_prophage_amr"
    exit 1
fi

RESULTS_DIR="$1"
OUTPUT_DIR="$2"

# Verify input directory exists
if [ ! -d "$RESULTS_DIR" ]; then
    echo "ERROR: Results directory not found: $RESULTS_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/individual_samples"
mkdir -p "$OUTPUT_DIR/logs"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Batch Prophage-AMR Intersection Analysis"
echo "=========================================="
echo "Results directory: $RESULTS_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Script directory: $SCRIPT_DIR"
echo "Start time: $(date)"
echo ""

# Find all samples by looking for AMRFinder results
AMR_FILES=$(find "$RESULTS_DIR/amrfinder" -name "*_amr.tsv" -o -name "amr.txt" 2>/dev/null || true)

if [ -z "$AMR_FILES" ]; then
    echo "ERROR: No AMRFinder results found in $RESULTS_DIR/amrfinder"
    echo "Expected files: *_amr.tsv or amr.txt"
    exit 1
fi

# Count samples
TOTAL_SAMPLES=$(echo "$AMR_FILES" | wc -l)
echo "Found $TOTAL_SAMPLES samples with AMRFinder results"
echo ""

# Initialize counters
PROCESSED=0
SUCCESS=0
FAILED=0
SAMPLES_WITH_PROPHAGE_AMR=0

# Create summary file
SUMMARY_FILE="$OUTPUT_DIR/prophage_amr_summary.tsv"
echo -e "sample\tprophages\tamr_genes\ttotal_intersections\tretained_intersections\tprophage_amr_genes" > "$SUMMARY_FILE"

# Track samples with prophage-encoded AMR
POSITIVE_SAMPLES="$OUTPUT_DIR/samples_with_prophage_amr.txt"
> "$POSITIVE_SAMPLES"

echo "Processing samples..."
echo ""

# Process each sample
while IFS= read -r AMR_FILE; do
    PROCESSED=$((PROCESSED + 1))

    # Extract sample name from AMR file path
    SAMPLE=$(basename "$AMR_FILE" | sed 's/_amr\.tsv$//' | sed 's/amr\.txt$//')

    echo "[$PROCESSED/$TOTAL_SAMPLES] Processing: $SAMPLE"

    # Find prophage coordinates file (handle various directory structures)
    PROPHAGE_FILE=""

    # Try different possible locations (including _contigs suffix)
    SEARCH_PATHS=(
        "$RESULTS_DIR/vibrant/$SAMPLE/VIBRANT_${SAMPLE}/VIBRANT_results_${SAMPLE}/VIBRANT_integrated_prophage_coordinates_${SAMPLE}.tsv"
        "$RESULTS_DIR/vibrant/${SAMPLE}_vibrant/VIBRANT_${SAMPLE}/VIBRANT_results_${SAMPLE}/VIBRANT_integrated_prophage_coordinates_${SAMPLE}.tsv"
        "$RESULTS_DIR/vibrant/${SAMPLE}_vibrant/VIBRANT_${SAMPLE}_contigs/VIBRANT_results_${SAMPLE}_contigs/VIBRANT_integrated_prophage_coordinates_${SAMPLE}_contigs.tsv"
        "$RESULTS_DIR/vibrant/$SAMPLE/VIBRANT_integrated_prophage_coordinates_${SAMPLE}.tsv"
        "$RESULTS_DIR/vibrant/VIBRANT_${SAMPLE}/VIBRANT_results_${SAMPLE}/VIBRANT_integrated_prophage_coordinates_${SAMPLE}.tsv"
    )

    for path in "${SEARCH_PATHS[@]}"; do
        if [ -f "$path" ]; then
            PROPHAGE_FILE="$path"
            break
        fi
    done

    # If still not found, try searching with wildcard (handles _contigs and other suffixes)
    if [ -z "$PROPHAGE_FILE" ]; then
        PROPHAGE_FILE=$(find "$RESULTS_DIR/vibrant" -name "VIBRANT_integrated_prophage_coordinates_${SAMPLE}*.tsv" 2>/dev/null | head -1 || true)
    fi

    if [ -z "$PROPHAGE_FILE" ] || [ ! -f "$PROPHAGE_FILE" ]; then
        echo "  ⚠️  Prophage coordinates not found, skipping"
        echo -e "${SAMPLE}\tNA\tNA\tNA\tNA\tNA" >> "$SUMMARY_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Run prophage-AMR intersection
    OUTPUT_FILE="$OUTPUT_DIR/individual_samples/${SAMPLE}_prophage_amr.tsv"
    LOG_FILE="$OUTPUT_DIR/logs/${SAMPLE}.log"

    python3 "$SCRIPT_DIR/intersect_prophage_amr.py" \
        --prophage_coords "$PROPHAGE_FILE" \
        --amr_results "$AMR_FILE" \
        --output "$OUTPUT_FILE" \
        --sample_name "$SAMPLE" \
        --terminal_buffer 5000 \
        > "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        SUCCESS=$((SUCCESS + 1))

        # Parse results to get counts
        NUM_PROPHAGES=$(grep "✓ Loaded" "$LOG_FILE" | grep "prophage regions" | awk '{print $3}' || echo "0")
        NUM_AMR=$(grep "✓ Loaded" "$LOG_FILE" | grep "AMR genes" | awk '{print $3}' || echo "0")

        # Check if output file has intersections
        if [ -f "$OUTPUT_FILE" ]; then
            TOTAL_INTERSECTIONS=$(tail -n +2 "$OUTPUT_FILE" | wc -l)
            RETAINED=$(tail -n +2 "$OUTPUT_FILE" | awk -F'\t' '$13 == "False" || $13 == "false"' | wc -l)

            if [ $RETAINED -gt 0 ]; then
                SAMPLES_WITH_PROPHAGE_AMR=$((SAMPLES_WITH_PROPHAGE_AMR + 1))
                echo "$SAMPLE" >> "$POSITIVE_SAMPLES"

                # Extract AMR gene names
                PROPHAGE_AMR_GENES=$(tail -n +2 "$OUTPUT_FILE" | awk -F'\t' '$13 == "False" || $13 == "false" {print $7}' | sort -u | tr '\n' ',' | sed 's/,$//')

                echo "  🚨 PROPHAGE-ENCODED AMR FOUND: $RETAINED genes ($PROPHAGE_AMR_GENES)"
                echo -e "${SAMPLE}\t${NUM_PROPHAGES}\t${NUM_AMR}\t${TOTAL_INTERSECTIONS}\t${RETAINED}\t${PROPHAGE_AMR_GENES}" >> "$SUMMARY_FILE"
            else
                echo "  ✓ No prophage-encoded AMR genes"
                echo -e "${SAMPLE}\t${NUM_PROPHAGES}\t${NUM_AMR}\t${TOTAL_INTERSECTIONS}\t0\t-" >> "$SUMMARY_FILE"
            fi
        else
            echo "  ℹ️  No intersections found"
            echo -e "${SAMPLE}\t${NUM_PROPHAGES}\t${NUM_AMR}\t0\t0\t-" >> "$SUMMARY_FILE"
        fi
    else
        echo "  ❌ Analysis failed (see $LOG_FILE)"
        FAILED=$((FAILED + 1))
        echo -e "${SAMPLE}\tERROR\tERROR\tERROR\tERROR\tERROR" >> "$SUMMARY_FILE"
    fi

    echo ""
done <<< "$AMR_FILES"

# Generate final report
echo "=========================================="
echo "Analysis Complete!"
echo "=========================================="
echo "End time: $(date)"
echo ""
echo "Summary:"
echo "  Total samples: $TOTAL_SAMPLES"
echo "  Successfully processed: $SUCCESS"
echo "  Failed: $FAILED"
echo "  Samples with prophage-encoded AMR: $SAMPLES_WITH_PROPHAGE_AMR"
echo ""

if [ $SAMPLES_WITH_PROPHAGE_AMR -gt 0 ]; then
    echo "🚨 CRITICAL FINDING: $SAMPLES_WITH_PROPHAGE_AMR samples contain AMR genes within prophage regions!"
    echo ""
    echo "Samples with prophage-encoded AMR:"
    cat "$POSITIVE_SAMPLES"
    echo ""
    echo "See full details in: $SUMMARY_FILE"
else
    echo "✓ No prophage-encoded AMR genes detected in any samples"
fi

echo ""
echo "Output files:"
echo "  - Summary table: $SUMMARY_FILE"
echo "  - Positive samples: $POSITIVE_SAMPLES"
echo "  - Individual results: $OUTPUT_DIR/individual_samples/"
echo "  - Logs: $OUTPUT_DIR/logs/"
echo ""

# Create a detailed report for positive samples
if [ $SAMPLES_WITH_PROPHAGE_AMR -gt 0 ]; then
    REPORT_FILE="$OUTPUT_DIR/PROPHAGE_AMR_REPORT.txt"

    echo "Prophage-Encoded AMR Genes - Detailed Report" > "$REPORT_FILE"
    echo "=============================================" >> "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Total samples analyzed: $TOTAL_SAMPLES" >> "$REPORT_FILE"
    echo "Samples with prophage-encoded AMR: $SAMPLES_WITH_PROPHAGE_AMR" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "SIGNIFICANCE:" >> "$REPORT_FILE"
    echo "AMR genes within prophage regions can be horizontally transferred" >> "$REPORT_FILE"
    echo "via phage transduction, facilitating rapid AMR spread in bacterial" >> "$REPORT_FILE"
    echo "populations. This represents a high-risk mechanism for AMR dissemination." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "=============================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Add details for each positive sample
    while IFS= read -r SAMPLE; do
        echo "Sample: $SAMPLE" >> "$REPORT_FILE"
        echo "-------------------------------------------" >> "$REPORT_FILE"

        # Extract retained intersections from individual file
        SAMPLE_FILE="$OUTPUT_DIR/individual_samples/${SAMPLE}_prophage_amr.tsv"
        if [ -f "$SAMPLE_FILE" ]; then
            tail -n +2 "$SAMPLE_FILE" | awk -F'\t' '$13 == "False" || $13 == "false"' | \
                awk -F'\t' '{printf "  Gene: %s\n  Class: %s\n  Subclass: %s\n  Prophage: %s\n  Position: %s-%s\n\n", $7, $10, $11, $3, $8, $9}' >> "$REPORT_FILE"
        fi

        echo "" >> "$REPORT_FILE"
    done < "$POSITIVE_SAMPLES"

    echo "Detailed report written to: $REPORT_FILE"
fi

echo "Done!"
