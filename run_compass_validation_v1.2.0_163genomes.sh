#!/bin/bash
#SBATCH --job-name=compass_val_v1.2.0
#SBATCH --output=/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_%j/logs/compass_validation_%j.out
#SBATCH --error=/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_%j/logs/compass_validation_%j.err
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=96G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# COMPASS v1.2.0 Full Validation Run - 163 Genomes
# Tests all new features including optional modules for complete 15-tab HTML summary
# Reuses cached results from v1.0.1 where possible (via -resume)
# Date: 2026-03-26
# Expected runtime: 6-12 hours (much faster with cached results!)

set -e

echo "=========================================="
echo "COMPASS v1.2.0 Full Validation - 163 Genomes"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: 96GB"
echo "Pipeline Version: 1.2.0-candidate"
echo ""
echo "New Features to Test:"
echo "  - Tab 10: Genome Annotation (Prokka integration)"
echo "  - Tab 11: Virulence Factor Analysis (VFDB)"
echo "  - Tab 12: Enhanced Prophage Analysis (quality-based)"
echo "  - Tab 13: Pangenome Analysis (Panaroo - ENABLED)"
echo "  - Tab 14: Phylogenetic Tree (IQ-TREE - ENABLED)"
echo "  - Tab 15: SNP Analysis (Snippy - ENABLED)"
echo ""

# Load required modules
echo "Loading modules..."
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set Nextflow JVM options for large runs
export NXF_OPTS='-Xms4g -Xmx16g'

# Change to COMPASS v1.2.0 candidate directory
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate"
if [ ! -d "$PIPELINE_DIR" ]; then
    echo "ERROR: Pipeline directory not found: $PIPELINE_DIR"
    echo "Please ensure you have the v1.2.0-candidate directory set up"
    exit 1
fi

cd "$PIPELINE_DIR" || exit 1
echo "Working directory: $(pwd)"
echo ""

# Verify we're on 1.2.0-candidate branch
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_COMMIT=$(git log --oneline -1)

echo "Git branch: $CURRENT_BRANCH"
echo "Latest commit: $CURRENT_COMMIT"
echo ""

if [ "$CURRENT_BRANCH" != "1.2.0-candidate" ]; then
    echo "ERROR: Not on 1.2.0-candidate branch (currently on: $CURRENT_BRANCH)"
    echo "Run: git checkout 1.2.0-candidate"
    exit 1
fi

# Check samplesheet exists
SAMPLESHEET="$PIPELINE_DIR/data/validation/validation_samplesheet_fasta.csv"

# If default doesn't exist, try to find one
if [ ! -f "$SAMPLESHEET" ]; then
    echo "WARNING: Default samplesheet not found: $SAMPLESHEET"
    echo ""
    echo "Looking for alternative samplesheets..."
    ALTERNATIVE=$(find "$PIPELINE_DIR/data" -name "*samplesheet*.csv" -o -name "*163*.csv" 2>/dev/null | head -1)

    if [ -n "$ALTERNATIVE" ] && [ -f "$ALTERNATIVE" ]; then
        echo "Found: $ALTERNATIVE"
        SAMPLESHEET="$ALTERNATIVE"
    else
        echo "ERROR: No samplesheet found!"
        echo ""
        echo "Please create a samplesheet with 163 genomes:"
        echo "  Format: sample,organism,fasta"
        echo "  Path: $PIPELINE_DIR/data/validation/validation_samplesheet_fasta.csv"
        exit 1
    fi
fi

# Count samples
SAMPLE_COUNT=$(tail -n +2 "$SAMPLESHEET" | wc -l)
echo "Samplesheet: $SAMPLESHEET"
echo "Total samples: $SAMPLE_COUNT"
echo ""

if [ $SAMPLE_COUNT -lt 100 ]; then
    echo "WARNING: Expected ~163 samples, found only $SAMPLE_COUNT"
    echo "Continue anyway? (Press Ctrl+C to cancel, waiting 5 seconds...)"
    sleep 5
fi

# Set output directory with job ID
OUTDIR="/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_${SLURM_JOB_ID}"
mkdir -p "$OUTDIR/logs"
echo "Output directory: $OUTDIR"
echo ""

# Look for v1.0.1 work directory to reuse cached results
V101_WORK_DIR=""
echo "Checking for v1.0.1 cached results to speed up run..."

# Search for most recent v1.0.1 validation work directory
for dir in /scratch/tylerdoe/COMPASS_Validation_Results_v1.0.1_*/; do
    if [ -d "$dir" ]; then
        V101_WORK_DIR="$dir"
        echo "  Found: $V101_WORK_DIR"
    fi
done

if [ -n "$V101_WORK_DIR" ] && [ -d "${V101_WORK_DIR}work" ]; then
    echo "  ✓ Will reuse work directory: ${V101_WORK_DIR}work"
    echo "  This will skip unchanged modules (QUAST, MLST, AMR, plasmids, etc.)"
    echo "  Only new v1.2.0 modules will run!"
    RESUME_FLAG="-resume -w ${V101_WORK_DIR}work"
else
    echo "  ✗ No v1.0.1 work directory found"
    echo "  Will run all modules from scratch (this will take longer)"
    RESUME_FLAG="-resume"
fi
echo ""

# For Snippy, we need a reference genome
# Using the first genome in the samplesheet as reference
REFERENCE_GENOME=$(tail -n +2 "$SAMPLESHEET" | head -1 | cut -d',' -f3)
echo "Reference genome for Snippy: $REFERENCE_GENOME"

if [ ! -f "$REFERENCE_GENOME" ]; then
    echo "WARNING: Reference genome not found: $REFERENCE_GENOME"
    echo "Snippy will be skipped (Tab 15 won't appear)"
    SNIPPY_REF=""
else
    echo "  ✓ Reference genome exists"
    SNIPPY_REF="--snippy_reference $REFERENCE_GENOME"
fi
echo ""

# Run COMPASS v1.2.0 pipeline with ALL modules enabled
echo "=========================================="
echo "Starting COMPASS v1.2.0 Full Validation..."
echo "=========================================="
echo ""
echo "Enabled modules:"
echo "  ✓ Base modules (QUAST, MLST, AMR, Plasmids, etc.)"
echo "  ✓ Genome Annotation (Prokka)"
echo "  ✓ Virulence Factors (VFDB)"
echo "  ✓ Enhanced Prophage (VIBRANT)"
echo "  ✓ Pangenome Analysis (Panaroo)"
echo "  ✓ Phylogenetic Tree (IQ-TREE)"
if [ -n "$SNIPPY_REF" ]; then
    echo "  ✓ SNP Analysis (Snippy)"
else
    echo "  ✗ SNP Analysis (Snippy - no reference)"
fi
echo ""

nextflow run main.nf \
    -profile beocat \
    --input "$SAMPLESHEET" \
    --outdir "${OUTDIR}/results" \
    --input_mode fasta \
    --max_cpus 20 \
    --max_memory 96.GB \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --skip_panaroo false \
    --skip_iqtree false \
    $SNIPPY_REF \
    $RESUME_FLAG \
    -with-report "${OUTDIR}/results/nextflow_report.html" \
    -with-timeline "${OUTDIR}/results/nextflow_timeline.html" \
    -with-dag "${OUTDIR}/results/nextflow_dag.html"

EXIT_CODE=$?

# Check exit status
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "COMPASS v1.2.0 validation completed successfully!"
    echo "=========================================="
    echo "End time: $(date)"
    echo "Results saved to: $OUTDIR"
    echo ""

    # Validation checks
    echo "Validation checks:"
    echo ""

    # Check core module outputs
    QUAST_COUNT=$(find ${OUTDIR}/results/quast -name "report.tsv" 2>/dev/null | wc -l)
    AMR_COUNT=$(find ${OUTDIR}/results/amrfinder -name "*_amr.tsv" 2>/dev/null | wc -l)
    MLST_COUNT=$(find ${OUTDIR}/results/mlst -name "*.tsv" 2>/dev/null | wc -l)

    echo "  Core modules:"
    echo "    - QUAST reports: $QUAST_COUNT / $SAMPLE_COUNT"
    echo "    - AMR files: $AMR_COUNT / $SAMPLE_COUNT"
    echo "    - MLST files: $MLST_COUNT / $SAMPLE_COUNT"

    # Check new v1.2.0 module outputs
    echo ""
    echo "  New v1.2.0 modules:"

    PROKKA_COUNT=$(find ${OUTDIR}/results/prokka -name "*.gff" 2>/dev/null | wc -l)
    echo "    - Prokka annotations: $PROKKA_COUNT / $SAMPLE_COUNT"

    VFDB_COUNT=$(find ${OUTDIR}/results/vfdb -name "*.tsv" 2>/dev/null | wc -l)
    echo "    - VFDB results: $VFDB_COUNT / $SAMPLE_COUNT"

    VIBRANT_COUNT=$(find ${OUTDIR}/results/vibrant -name "*_results.tsv" 2>/dev/null | wc -l)
    echo "    - VIBRANT prophage: $VIBRANT_COUNT / $SAMPLE_COUNT"

    # Check optional module outputs
    echo ""
    echo "  Optional modules:"

    if [ -f "${OUTDIR}/results/panaroo/gene_presence_absence.csv" ]; then
        PANAROO_GENES=$(tail -n +2 ${OUTDIR}/results/panaroo/gene_presence_absence.csv 2>/dev/null | wc -l)
        echo "    ✓ Panaroo pangenome: $PANAROO_GENES genes"
    else
        echo "    ✗ Panaroo: Not found"
    fi

    if [ -f "${OUTDIR}/results/iqtree/core_genome.treefile" ]; then
        echo "    ✓ IQ-TREE phylogeny: Tree file exists"
    else
        echo "    ✗ IQ-TREE: Not found"
    fi

    if [ -d "${OUTDIR}/results/snippy" ]; then
        SNIPPY_DIRS=$(find ${OUTDIR}/results/snippy -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        echo "    ✓ Snippy SNPs: $SNIPPY_DIRS comparisons"
    else
        echo "    ✗ Snippy: Not found"
    fi

    echo ""
    echo "Key outputs:"
    echo "  - MultiQC report: ${OUTDIR}/results/multiqc/multiqc_report.html"
    echo "  - Summary report: ${OUTDIR}/results/summary/compass_summary.html"
    echo "  - All results: ${OUTDIR}/results/"
    echo ""

    # Generate enhanced HTML summary
    echo "=========================================="
    echo "Generating Enhanced HTML Summary Report..."
    echo "=========================================="
    echo ""

    cd "$PIPELINE_DIR"

    # Build optional module flags
    OPTIONAL_FLAGS=""
    [ -d "${OUTDIR}/results/panaroo" ] && OPTIONAL_FLAGS="$OPTIONAL_FLAGS --panaroo"
    [ -d "${OUTDIR}/results/iqtree" ] && OPTIONAL_FLAGS="$OPTIONAL_FLAGS --iqtree"
    [ -d "${OUTDIR}/results/snippy" ] && OPTIONAL_FLAGS="$OPTIONAL_FLAGS --snippy"

    python3 bin/generate_compass_summary.py \
        --results_dir "${OUTDIR}/results" \
        --output_dir "${OUTDIR}/results/summary" \
        $OPTIONAL_FLAGS

    SUMMARY_EXIT=$?

    if [ $SUMMARY_EXIT -eq 0 ]; then
        echo ""
        echo "✅ HTML Summary Report Generated!"
        echo ""

        # Verify tab counts
        SUMMARY_HTML="${OUTDIR}/results/summary/compass_summary.html"
        if [ -f "$SUMMARY_HTML" ]; then
            TAB_COUNT=$(grep -c 'class="tab-button"' "$SUMMARY_HTML" || true)
            CHART_COUNT=$(grep -c "new Chart(" "$SUMMARY_HTML" || true)
            FILE_SIZE=$(du -h "$SUMMARY_HTML" | cut -f1)

            echo "  HTML Report Statistics:"
            echo "    - Total tabs: $TAB_COUNT"
            echo "    - Total charts: $CHART_COUNT"
            echo "    - File size: $FILE_SIZE"
            echo ""

            echo "  Expected tabs: 12-15 (base 9 + mandatory 3 + optional 0-3)"
            echo "  Expected charts: 26-35 (depending on optional modules)"
            echo ""

            # Check for new tabs
            echo "  v1.2.0 Features:"
            grep -q "genome-annotation" "$SUMMARY_HTML" && echo "    ✓ Tab 10: Genome Annotation" || echo "    ✗ Tab 10: Missing"
            grep -q "virulence-analysis" "$SUMMARY_HTML" && echo "    ✓ Tab 11: Virulence Analysis" || echo "    ✗ Tab 11: Missing"
            grep -q "enhanced-prophage" "$SUMMARY_HTML" && echo "    ✓ Tab 12: Enhanced Prophage" || echo "    ✗ Tab 12: Missing"
            grep -q "pangenome-analysis" "$SUMMARY_HTML" && echo "    ✓ Tab 13: Pangenome Analysis" || echo "    - Tab 13: Not applicable"
            grep -q "phylogenetic-tree" "$SUMMARY_HTML" && echo "    ✓ Tab 14: Phylogenetic Tree" || echo "    - Tab 14: Not applicable"
            grep -q "snp-analysis" "$SUMMARY_HTML" && echo "    ✓ Tab 15: SNP Analysis" || echo "    - Tab 15: Not applicable"
        fi
        echo ""
    else
        echo "⚠️  HTML Summary generation had issues (exit code: $SUMMARY_EXIT)"
        echo "Check bin/generate_compass_summary.py for errors"
    fi

    echo ""
    echo "=========================================="
    echo "Next Steps"
    echo "=========================================="
    echo ""
    echo "1. Download and review HTML summary:"
    echo "   scp beocat:${OUTDIR}/results/summary/compass_summary.html ."
    echo ""
    echo "2. Verify all 15 tabs render correctly with 163 samples"
    echo ""
    echo "3. Check browser console for JavaScript errors"
    echo ""
    echo "4. If validation passes:"
    echo "   - Document results in session notes"
    echo "   - Merge 1.2.0-candidate → main"
    echo "   - Tag v1.2.0 release"
    echo ""

else
    echo ""
    echo "=========================================="
    echo "COMPASS v1.2.0 validation run FAILED"
    echo "=========================================="
    echo "End time: $(date)"
    echo "Exit code: $EXIT_CODE"
    echo "Check error log: ${OUTDIR}/logs/compass_validation_${SLURM_JOB_ID}.err"
    echo ""
    exit 1
fi
