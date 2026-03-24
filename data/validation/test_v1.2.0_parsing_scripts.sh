#!/bin/bash
#
# Test all v1.2.0 parsing scripts on ETEC validation results
# Run this after ETEC validation completes successfully
#

set -e  # Exit on any error

echo "=========================================="
echo "Testing v1.2.0 Parsing Scripts"
echo "ETEC Validation Dataset (8 samples)"
echo "=========================================="
echo ""

# Navigate to results directory
RESULTS_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/data/validation/etec_results_v1.2.0"
BIN_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/bin"

cd "$RESULTS_DIR" || {
    echo "ERROR: Could not cd to $RESULTS_DIR"
    echo "Make sure ETEC validation completed successfully"
    exit 1
}

echo "Working directory: $(pwd)"
echo ""

# Verify key output directories exist
echo "Verifying output directories..."
for dir in amrfinder abricate vibrant mobsuite prokka assembly; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir/ exists"
    else
        echo "  ⚠️  $dir/ not found (may be skipped)"
    fi
done
echo ""

# Create output directory for parsed results
mkdir -p parsed_results
cd parsed_results

echo "=========================================="
echo "Test 1: Parse VIBRANT prophage results"
echo "=========================================="
python3 "$BIN_DIR/parse_vibrant_summary.py" \
    --vibrant ../vibrant/ \
    --output vibrant_summary.tsv

if [ -f vibrant_summary.tsv ]; then
    echo "✅ vibrant_summary.tsv created"
    echo "   Lines: $(wc -l < vibrant_summary.tsv)"
    echo "   Preview:"
    head -3 vibrant_summary.tsv | column -t -s$'\t'
else
    echo "❌ vibrant_summary.tsv not created"
fi
echo ""

echo "=========================================="
echo "Test 2: Parse MOB-suite plasmid results"
echo "=========================================="
python3 "$BIN_DIR/parse_mobsuite_plasmids.py" \
    --mobsuite ../mobsuite/ \
    --output mobsuite_summary.tsv

if [ -f mobsuite_summary.tsv ]; then
    echo "✅ mobsuite_summary.tsv created"
    echo "   Lines: $(wc -l < mobsuite_summary.tsv)"
    echo "   Preview:"
    head -3 mobsuite_summary.tsv | column -t -s$'\t'
else
    echo "❌ mobsuite_summary.tsv not created"
fi
echo ""

echo "=========================================="
echo "Test 3: Parse virulence factors (VFDB)"
echo "=========================================="
python3 "$BIN_DIR/parse_virulence_factors.py" \
    --abricate ../abricate/ \
    --output virulence_summary.tsv \
    --matrix virulence_matrix.tsv \
    --top-genes top_virulence_genes.tsv

if [ -f virulence_summary.tsv ]; then
    echo "✅ virulence_summary.tsv created"
    echo "   Lines: $(wc -l < virulence_summary.tsv)"
    echo "   Preview:"
    head -3 virulence_summary.tsv | column -t -s$'\t'
else
    echo "❌ virulence_summary.tsv not created"
fi

if [ -f virulence_matrix.tsv ]; then
    echo "✅ virulence_matrix.tsv created"
    echo "   Dimensions: $(wc -l < virulence_matrix.tsv) rows"
fi

if [ -f top_virulence_genes.tsv ]; then
    echo "✅ top_virulence_genes.tsv created"
    echo "   Preview:"
    head -3 top_virulence_genes.tsv | column -t -s$'\t'
fi
echo ""

echo "=========================================="
echo "Test 4: Categorize AMR by location"
echo "=========================================="
python3 "$BIN_DIR/categorize_amr_by_location.py" \
    --amrfinder ../amrfinder/ \
    --mobsuite ../mobsuite/ \
    --vibrant ../vibrant/ \
    --output amr_location_summary.tsv

if [ -f amr_location_summary.tsv ]; then
    echo "✅ amr_location_summary.tsv created"
    echo "   Lines: $(wc -l < amr_location_summary.tsv)"
    echo "   Preview:"
    head -3 amr_location_summary.tsv | column -t -s$'\t'
else
    echo "❌ amr_location_summary.tsv not created"
fi
echo ""

echo "=========================================="
echo "Test 5: Analyze prophage integration sites"
echo "=========================================="
python3 "$BIN_DIR/analyze_prophage_integration_sites.py" \
    --vibrant ../vibrant/ \
    --assemblies ../assembly/ \
    --output prophage_integration_sites.tsv \
    --flanking-length 1000

if [ -f prophage_integration_sites.tsv ]; then
    echo "✅ prophage_integration_sites.tsv created"
    echo "   Lines: $(wc -l < prophage_integration_sites.tsv)"
    echo "   Preview:"
    head -3 prophage_integration_sites.tsv | column -t -s$'\t'
else
    echo "❌ prophage_integration_sites.tsv not created"
fi
echo ""

echo "=========================================="
echo "Test 6: Summarize Prokka annotations"
echo "=========================================="
if [ -d ../prokka ]; then
    python3 "$BIN_DIR/summarize_prokka_annotations.py" \
        --prokka ../prokka/ \
        --output prokka_annotation_summary.tsv

    if [ -f prokka_annotation_summary.tsv ]; then
        echo "✅ prokka_annotation_summary.tsv created"
        echo "   Lines: $(wc -l < prokka_annotation_summary.tsv)"
        echo "   Preview:"
        head -3 prokka_annotation_summary.tsv | column -t -s$'\t'
    else
        echo "❌ prokka_annotation_summary.tsv not created"
    fi
else
    echo "⚠️  Prokka directory not found - skipping"
fi
echo ""

echo "=========================================="
echo "Test 7: Create master results table"
echo "=========================================="
python3 "$BIN_DIR/create_master_results_table.py" \
    --results-dir .. \
    --output master_results_table.tsv

if [ -f master_results_table.tsv ]; then
    echo "✅ master_results_table.tsv created"
    echo "   Lines: $(wc -l < master_results_table.tsv)"
    echo "   Samples: $(($(wc -l < master_results_table.tsv) - 1))"
    echo ""
    echo "   Column headers:"
    head -1 master_results_table.tsv | tr '\t' '\n' | nl
    echo ""
    echo "   First sample preview:"
    head -2 master_results_table.tsv | tail -1 | cut -f1-10 | column -t -s$'\t'
else
    echo "❌ master_results_table.tsv not created"
fi
echo ""

echo "=========================================="
echo "Summary of parsed results:"
echo "=========================================="
ls -lh *.tsv | awk '{print $9, "-", $5}'
echo ""

echo "✅ All parsing scripts tested!"
echo ""
echo "Results saved to: $RESULTS_DIR/parsed_results/"
echo ""
echo "Next steps:"
echo "  1. Review master_results_table.tsv for completeness"
echo "  2. Check virulence_summary.tsv for ETEC virulence factors"
echo "  3. Verify AMR location categorization"
echo "  4. Archive results to bulk storage if validated"
