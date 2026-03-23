#!/bin/bash
#SBATCH --job-name=compass_val_v1.0.1
#SBATCH --output=/scratch/tylerdoe/COMPASS_Validation_Results_v1.0.1_%j/logs/compass_validation_%j.out
#SBATCH --error=/scratch/tylerdoe/COMPASS_Validation_Results_v1.0.1_%j/logs/compass_validation_%j.err
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# COMPASS v1.0.1 Validation Run
# Testing AMRFinder organism mapping fix with same validation dataset as v1.0.0
# Date: 2026-03-23
# Expected runtime: 24-48 hours

set -e

echo "=========================================="
echo "COMPASS v1.0.1 Validation Run"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: 64GB"
echo "Pipeline Version: 1.0.1 (scratch branch - AMRFinder fix)"
echo ""

# Load required modules
echo "Loading modules..."
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set Nextflow JVM options for large runs
export NXF_OPTS='-Xms2g -Xmx8g'

# Change to COMPASS v1.0.1 candidate directory
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate"
if [ ! -d "$PIPELINE_DIR" ]; then
    echo "ERROR: Pipeline directory not found: $PIPELINE_DIR"
    echo "Please ensure you have the v1.0.1 candidate directory set up"
    exit 1
fi

cd "$PIPELINE_DIR" || exit 1
echo "Working directory: $(pwd)"
echo ""

# Verify we're on scratch branch
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_COMMIT=$(git log --oneline -1)

echo "Git branch: $CURRENT_BRANCH"
echo "Latest commit: $CURRENT_COMMIT"
echo ""

if [ "$CURRENT_BRANCH" != "scratch" ]; then
    echo "ERROR: Not on scratch branch (currently on: $CURRENT_BRANCH)"
    echo "Run: git checkout scratch"
    exit 1
fi

# Check samplesheet exists
SAMPLESHEET="$PIPELINE_DIR/data/validation/validation_samplesheet_fasta.csv"
if [ ! -f "$SAMPLESHEET" ]; then
    echo "ERROR: Samplesheet not found: $SAMPLESHEET"
    echo ""
    echo "Available samplesheets in data/validation/:"
    ls -lh "$PIPELINE_DIR/data/validation/"*samplesheet*.csv 2>/dev/null || echo "  (none found)"
    echo ""
    echo "Please create or specify the correct samplesheet path."
    echo "The samplesheet should have columns: sample,organism,fasta"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(tail -n +2 "$SAMPLESHEET" | wc -l)
echo "Samplesheet: $SAMPLESHEET"
echo "Total samples: $SAMPLE_COUNT"
echo ""

# Set output directory with job ID
OUTDIR="/scratch/tylerdoe/COMPASS_Validation_Results_v1.0.1_${SLURM_JOB_ID}"
mkdir -p "$OUTDIR/logs"
echo "Output directory: $OUTDIR"
echo ""

# Run COMPASS v1.0.1 pipeline (scratch branch)
echo "=========================================="
echo "Starting COMPASS v1.0.1 pipeline..."
echo "=========================================="
echo ""

nextflow run main.nf \
    -profile beocat \
    --input "$SAMPLESHEET" \
    --outdir "${OUTDIR}/results" \
    --input_mode fasta \
    --max_cpus 16 \
    --max_memory 64.GB \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    -resume \
    -with-report "${OUTDIR}/results/nextflow_report.html" \
    -with-timeline "${OUTDIR}/results/nextflow_timeline.html" \
    -with-dag "${OUTDIR}/results/nextflow_dag.html"

EXIT_CODE=$?

# Check exit status
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "COMPASS v1.0.1 validation run completed successfully!"
    echo "=========================================="
    echo "End time: $(date)"
    echo "Results saved to: $OUTDIR"
    echo ""

    # Validation checks
    echo "Validation checks:"
    echo ""

    # Check AMR files
    AMR_COUNT=$(ls ${OUTDIR}/results/amrfinder/*_amr.tsv 2>/dev/null | wc -l)
    EMPTY_AMR=$(find ${OUTDIR}/results/amrfinder -name "*_amr.tsv" -size 0 2>/dev/null | wc -l)

    echo "  AMR files created: $AMR_COUNT / $SAMPLE_COUNT"
    echo "  Empty AMR files: $EMPTY_AMR"

    if [ $AMR_COUNT -eq $SAMPLE_COUNT ] && [ $EMPTY_AMR -eq 0 ]; then
        echo "  ✅ All samples have non-empty AMR files"
        echo "  ✅ AMRFinder organism mapping fix validated!"
    else
        echo "  ⚠️  Some AMR files missing or empty"
        if [ $EMPTY_AMR -gt 0 ]; then
            echo "  Empty files:"
            find ${OUTDIR}/results/amrfinder -name "*_amr.tsv" -size 0 2>/dev/null | head -10
        fi
    fi

    echo ""
    echo "Key outputs:"
    echo "  - AMR results: ${OUTDIR}/results/amrfinder/"
    echo "  - Prophage results: ${OUTDIR}/results/vibrant/"
    echo "  - Plasmid results: ${OUTDIR}/results/mobsuite/"
    echo "  - MLST results: ${OUTDIR}/results/mlst/"
    echo "  - MultiQC report: ${OUTDIR}/results/multiqc/multiqc_report.html"
    echo "  - Summary: ${OUTDIR}/results/summary/"
    echo ""
    echo "Comparison with v1.0.0:"
    echo "  v1.0.0 results: /scratch/tylerdoe/COMPASS_Validation_Results_v1.0.0_*/"
    echo "  v1.0.1 results: $OUTDIR"
    echo ""
    echo "Next steps:"
    echo "  1. Review MultiQC report"
    echo "  2. Compare AMR results between v1.0.0 and v1.0.1"
    echo "  3. Document any differences in AMR detection"
    echo "  4. If validation passes, merge scratch → main and tag v1.0.1"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "COMPASS v1.0.1 validation run FAILED"
    echo "=========================================="
    echo "End time: $(date)"
    echo "Exit code: $EXIT_CODE"
    echo "Check error log: ${OUTDIR}/logs/compass_validation_${SLURM_JOB_ID}.err"
    echo ""
    exit 1
fi
