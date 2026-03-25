#!/bin/bash
#
# Test COMPASS Summary Generation on ETEC Validation Results
# Tests the newly ported v1.0.0 script with v1.2.0 ETEC validation data
#

set -e

echo "========================================================================"
echo "COMPASS SUMMARY v1.2.0 TEST SCRIPT"
echo "========================================================================"

# Check if we're on Beocat (has /fastscratch)
if [ -d "/fastscratch/tylerdoe" ]; then
    RESULTS_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/results"
    echo "✅ Running on Beocat"
else
    echo "❌ This script should be run on Beocat where ETEC validation results exist"
    echo "   Expected location: /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/results"
    exit 1
fi

# Check if results directory exists
if [ ! -d "$RESULTS_DIR" ]; then
    echo "❌ Results directory not found: $RESULTS_DIR"
    exit 1
fi

echo "📂 Results directory: $RESULTS_DIR"
echo ""

# Check for expected subdirectories
echo "Checking for pipeline output directories..."
for dir in quast busco mlst sistr amrfinder mobsuite vibrant; do
    if [ -d "$RESULTS_DIR/$dir" ]; then
        count=$(ls -1 "$RESULTS_DIR/$dir" | wc -l)
        echo "  ✅ $dir/ ($count items)"
    else
        echo "  ⚠️  $dir/ (not found)"
    fi
done
echo ""

# Check for metadata file
METADATA_FILE="$RESULTS_DIR/../filtered_samples/filtered_samples.csv"
if [ -f "$METADATA_FILE" ]; then
    echo "✅ Metadata file found: $METADATA_FILE"
    sample_count=$(tail -n +2 "$METADATA_FILE" | wc -l)
    echo "   Samples in metadata: $sample_count"
else
    echo "⚠️  Metadata file not found (optional): $METADATA_FILE"
    METADATA_FILE=""
fi
echo ""

# Create output directory for test results
OUTPUT_DIR="$RESULTS_DIR/../summary_test"
mkdir -p "$OUTPUT_DIR"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Run COMPASS summary generator
echo "========================================================================"
echo "Running COMPASS Summary Generator..."
echo "========================================================================"
echo ""

SCRIPT_PATH="/workspace/bin/generate_compass_summary.py"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Script not found: $SCRIPT_PATH"
    exit 1
fi

# Build command
CMD="python3 $SCRIPT_PATH --outdir $RESULTS_DIR --output_tsv $OUTPUT_DIR/compass_summary.tsv --output_html $OUTPUT_DIR/compass_summary.html"

if [ -n "$METADATA_FILE" ]; then
    CMD="$CMD --metadata $METADATA_FILE"
fi

echo "Command: $CMD"
echo ""

# Run the script
$CMD

echo ""
echo "========================================================================"
echo "TEST COMPLETE"
echo "========================================================================"
echo ""
echo "Output files:"
echo "  TSV:  $OUTPUT_DIR/compass_summary.tsv"
echo "  HTML: $OUTPUT_DIR/compass_summary.html"
echo ""

# Check if output files were created
if [ -f "$OUTPUT_DIR/compass_summary.tsv" ]; then
    lines=$(wc -l < "$OUTPUT_DIR/compass_summary.tsv")
    cols=$(head -1 "$OUTPUT_DIR/compass_summary.tsv" | tr '\t' '\n' | wc -l)
    echo "✅ TSV created: $lines rows, $cols columns"
else
    echo "❌ TSV file not created"
    exit 1
fi

if [ -f "$OUTPUT_DIR/compass_summary.html" ]; then
    size=$(du -h "$OUTPUT_DIR/compass_summary.html" | cut -f1)
    echo "✅ HTML created: $size"
else
    echo "❌ HTML file not created"
    exit 1
fi

echo ""
echo "To view the HTML report:"
echo "  1. Copy to local machine:"
echo "     scp beocat:$OUTPUT_DIR/compass_summary.html ."
echo "  2. Open in browser"
echo ""
echo "========================================================================"
