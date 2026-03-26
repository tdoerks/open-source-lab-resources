#!/bin/bash
# Test COMPASS v1.2.0 HTML Summary Report with 163 Genome Validation Dataset
#
# This script generates the enhanced HTML summary report using 163 E. coli reference genomes
# to test scalability of the new visualizations (tabs 10-15)
#
# Date: 2026-03-26
# Branch: 1.2.0-candidate

set -e

echo "=========================================="
echo "COMPASS v1.2.0 HTML Summary - 163 Genome Test"
echo "=========================================="
echo "Start time: $(date)"
echo ""

# Configuration
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate"
RESULTS_DIR="/scratch/tylerdoe/COMPASS_Validation_Results_v1.3-dev_2026-02-09/results"
OUTPUT_DIR="${PIPELINE_DIR}/data/validation/summary_163genomes_test"

echo "Pipeline directory: $PIPELINE_DIR"
echo "Results directory: $RESULTS_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Verify directories exist
if [ ! -d "$PIPELINE_DIR" ]; then
    echo "ERROR: Pipeline directory not found: $PIPELINE_DIR"
    echo "Please ensure you're running this on beocat with the 1.2.0-candidate branch cloned"
    exit 1
fi

if [ ! -d "$RESULTS_DIR" ]; then
    echo "WARNING: Default results directory not found: $RESULTS_DIR"
    echo ""
    echo "Please specify the path to your 163-genome validation results:"
    echo "  export RESULTS_DIR=/path/to/your/validation/results"
    echo ""
    echo "Or run a new validation first using:"
    echo "  sbatch data/validation/run_compass_validation_v1.0.1.sh"
    echo ""
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Change to pipeline directory
cd "$PIPELINE_DIR" || exit 1

echo "Checking validation results structure..."
echo ""

# Count samples from results
QUAST_COUNT=$(find "$RESULTS_DIR/quast" -name "report.tsv" | wc -l)
MLST_COUNT=$(find "$RESULTS_DIR/mlst" -name "*.tsv" | wc -l)
AMR_COUNT=$(find "$RESULTS_DIR/amrfinder" -name "*.tsv" | wc -l)

echo "Found results for:"
echo "  - QUAST: $QUAST_COUNT samples"
echo "  - MLST: $MLST_COUNT samples"
echo "  - AMRFinder: $AMR_COUNT samples"
echo ""

if [ "$QUAST_COUNT" -lt 100 ]; then
    echo "WARNING: Expected 163 samples, found only $QUAST_COUNT"
    echo "Results may be incomplete. Continue anyway? (Press Ctrl+C to cancel)"
    sleep 3
fi

# Optional modules check
echo "Checking for optional module results..."
if [ -d "$RESULTS_DIR/panaroo" ]; then
    echo "  ✓ Panaroo results found"
    PANAROO_FLAG="--panaroo"
else
    echo "  ✗ Panaroo results not found (tab 13 won't appear)"
    PANAROO_FLAG=""
fi

if [ -d "$RESULTS_DIR/iqtree" ]; then
    echo "  ✓ IQ-TREE results found"
    IQTREE_FLAG="--iqtree"
else
    echo "  ✗ IQ-TREE results not found (tab 14 won't appear)"
    IQTREE_FLAG=""
fi

if [ -d "$RESULTS_DIR/snippy" ]; then
    echo "  ✓ Snippy results found"
    SNIPPY_FLAG="--snippy"
else
    echo "  ✗ Snippy results not found (tab 15 won't appear)"
    SNIPPY_FLAG=""
fi
echo ""

# Generate HTML summary report
echo "=========================================="
echo "Generating HTML Summary Report..."
echo "=========================================="
echo ""

python3 bin/generate_compass_summary.py \
    --results_dir "$RESULTS_DIR" \
    --output_dir "$OUTPUT_DIR" \
    $PANAROO_FLAG \
    $IQTREE_FLAG \
    $SNIPPY_FLAG

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "SUCCESS! HTML Summary Generated"
    echo "=========================================="
    echo "End time: $(date)"
    echo ""
    echo "Output file: ${OUTPUT_DIR}/compass_summary.html"
    echo ""

    # Verify chart counts
    echo "Verification checks:"
    CHART_COUNT=$(grep -c "new Chart(" "${OUTPUT_DIR}/compass_summary.html" || true)
    TAB_COUNT=$(grep -c 'class="tab-button"' "${OUTPUT_DIR}/compass_summary.html" || true)

    echo "  - Total Chart.js visualizations: $CHART_COUNT"
    echo "  - Total tabs: $TAB_COUNT"
    echo ""

    # Expected counts
    echo "Expected counts for 163 genomes:"
    echo "  - Tabs: 12-15 (depending on optional modules)"
    echo "  - Charts: ~26-35 (depending on optional modules)"
    echo ""

    # Check for new tabs
    echo "Checking for new v1.2.0 tabs..."
    if grep -q "genome-annotation" "${OUTPUT_DIR}/compass_summary.html"; then
        echo "  ✓ Tab 10: Genome Annotation"
    else
        echo "  ✗ Tab 10: Genome Annotation MISSING!"
    fi

    if grep -q "virulence-analysis" "${OUTPUT_DIR}/compass_summary.html"; then
        echo "  ✓ Tab 11: Virulence Analysis"
    else
        echo "  ✗ Tab 11: Virulence Analysis MISSING!"
    fi

    if grep -q "enhanced-prophage" "${OUTPUT_DIR}/compass_summary.html"; then
        echo "  ✓ Tab 12: Enhanced Prophage Analysis"
    else
        echo "  ✗ Tab 12: Enhanced Prophage Analysis MISSING!"
    fi

    # Check optional tabs
    if grep -q "pangenome-analysis" "${OUTPUT_DIR}/compass_summary.html"; then
        echo "  ✓ Tab 13: Pangenome Analysis (optional)"
    fi

    if grep -q "phylogenetic-tree" "${OUTPUT_DIR}/compass_summary.html"; then
        echo "  ✓ Tab 14: Phylogenetic Tree (optional)"
    fi

    if grep -q "snp-analysis" "${OUTPUT_DIR}/compass_summary.html"; then
        echo "  ✓ Tab 15: SNP Analysis (optional)"
    fi
    echo ""

    # File size check
    FILE_SIZE=$(du -h "${OUTPUT_DIR}/compass_summary.html" | cut -f1)
    echo "HTML file size: $FILE_SIZE"
    echo ""

    echo "Next steps:"
    echo "  1. Download HTML to your local machine:"
    echo "     scp beocat:${OUTPUT_DIR}/compass_summary.html ."
    echo ""
    echo "  2. Open in browser to verify visualizations:"
    echo "     - All tabs render correctly"
    echo "     - Charts scale properly with 163 samples"
    echo "     - Interactive elements work"
    echo ""
    echo "  3. Check browser console for JavaScript errors"
    echo ""

else
    echo ""
    echo "=========================================="
    echo "ERROR: HTML Summary Generation Failed"
    echo "=========================================="
    echo "Exit code: $EXIT_CODE"
    echo "End time: $(date)"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check Python script: bin/generate_compass_summary.py"
    echo "  2. Verify results directory structure"
    echo "  3. Check for missing required files"
    echo ""
    exit 1
fi
