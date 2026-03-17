#!/bin/bash
#SBATCH --job-name=amrfinder_fasta_test
#SBATCH --output=/fastscratch/tylerdoe/test_amrfinder_fasta_%j.out
#SBATCH --error=/fastscratch/tylerdoe/test_amrfinder_fasta_%j.err
#SBATCH --time=4:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=batch.q
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# AMRFinder v1.0.1 FASTA Mode Validation Test
# Tests 38 samples (2 per organism) across 19 bacterial species
# Uses existing assemblies from diverse_bacteria_1000 results

set -euo pipefail

echo "============================================================"
echo "AMRFinder v1.0.1 FASTA Mode Validation Test"
echo "============================================================"
echo "Date: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo ""
echo "Testing 38 samples (2 per organism) from 19 bacterial species:"
echo "  - Supported organisms: Vibrio, Staph, Campylobacter, Enterococcus, Klebsiella, Listeria, etc."
echo "  - Unsupported organisms: Pseudomonas, Acinetobacter, Proteus, Citrobacter, etc."
echo "  - Goal: Verify AMRFinder organism mapping fix works across all organisms"
echo ""

TEST_DIR="/fastscratch/tylerdoe/test_amrfinder_fasta_${SLURM_JOB_ID}"
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline"
SAMPLESHEET="/fastscratch/tylerdoe/test_amrfinder_fasta_samplesheet.csv"

mkdir -p ${TEST_DIR}

echo "Test directory: ${TEST_DIR}"
echo "Pipeline directory: ${PIPELINE_DIR}"
echo "Samplesheet: ${SAMPLESHEET}"
echo ""

# Verify samplesheet exists
if [ ! -f "$SAMPLESHEET" ]; then
    echo "ERROR: Samplesheet not found at $SAMPLESHEET"
    echo "Please run create_amrfinder_test_samplesheet.sh first!"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(tail -n +2 $SAMPLESHEET | wc -l)
echo "Total samples in samplesheet: $SAMPLE_COUNT"
echo ""

# Change to pipeline directory
cd ${PIPELINE_DIR}

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow module"
    exit 1
}

echo "============================================================"
echo "Running COMPASS in FASTA mode with AMRFinder organism mapping"
echo "============================================================"
echo ""

nextflow run main.nf \
    -profile beocat \
    --input ${SAMPLESHEET} \
    --outdir ${TEST_DIR}/results \
    --skip_busco true \
    --max_cpus 16 \
    --max_memory 64.GB \
    -w ${TEST_DIR}/work \
    -resume

PIPELINE_EXIT=$?

echo ""
echo "============================================================"
echo "Pipeline completed with exit code: $PIPELINE_EXIT"
echo "============================================================"
echo ""

# Validation
echo "============================================================"
echo "Validation Results"
echo "============================================================"
echo ""

if [ $PIPELINE_EXIT -eq 0 ]; then
    echo "✓ Pipeline completed successfully"
    echo ""

    # Check AMR files
    echo "Checking AMRFinder output files..."
    AMR_DIR="${TEST_DIR}/results/amrfinder"

    if [ -d "$AMR_DIR" ]; then
        TOTAL_AMR=$(ls $AMR_DIR/*_amr.tsv 2>/dev/null | wc -l)
        EMPTY_AMR=$(find $AMR_DIR -name "*_amr.tsv" -size 0 2>/dev/null | wc -l)
        NON_EMPTY_AMR=$((TOTAL_AMR - EMPTY_AMR))

        echo "  Total AMR files: $TOTAL_AMR"
        echo "  Non-empty AMR files: $NON_EMPTY_AMR"
        echo "  Empty AMR files: $EMPTY_AMR"
        echo ""

        if [ $TOTAL_AMR -eq $SAMPLE_COUNT ]; then
            echo "  ✓ All samples have AMR files"
        else
            echo "  ✗ Missing AMR files for some samples"
            echo "    Expected: $SAMPLE_COUNT, Found: $TOTAL_AMR"
        fi

        if [ $EMPTY_AMR -gt 0 ]; then
            echo "  ⚠️  Warning: $EMPTY_AMR empty AMR files found"
            echo "  Empty files:"
            find $AMR_DIR -name "*_amr.tsv" -size 0 2>/dev/null | while read f; do
                echo "    - $(basename $f)"
            done
        fi

        echo ""
        echo "Sample size distribution:"
        find $AMR_DIR -name "*_amr.tsv" -exec ls -lh {} \; | awk '{print $5}' | sort | uniq -c | sort -rn

    else
        echo "  ✗ AMRFinder output directory not found!"
    fi

    echo ""
    echo "Check organism-specific vs generic mode usage in logs:"
    echo "  ${TEST_DIR}/work/*/*/.command.log"

else
    echo "✗ Pipeline failed with exit code $PIPELINE_EXIT"
    echo ""
    echo "Check logs for errors:"
    echo "  SLURM output: /fastscratch/tylerdoe/test_amrfinder_fasta_${SLURM_JOB_ID}.out"
    echo "  SLURM error: /fastscratch/tylerdoe/test_amrfinder_fasta_${SLURM_JOB_ID}.err"
fi

echo ""
echo "============================================================"
echo "Test Summary"
echo "============================================================"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Samples tested: $SAMPLE_COUNT"
echo "Exit code: $PIPELINE_EXIT"
echo "Results directory: ${TEST_DIR}/results"
echo "Work directory: ${TEST_DIR}/work"
echo "============================================================"
echo ""
echo "Test completed: $(date)"
