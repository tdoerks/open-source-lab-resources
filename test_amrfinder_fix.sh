#!/bin/bash
#SBATCH --job-name=test_amrfinder_fix
#SBATCH --output=/fastscratch/tylerdoe/test_amrfinder_fix_%j.out
#SBATCH --error=/fastscratch/tylerdoe/test_amrfinder_fix_%j.err
#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=ksu-gen-highmem.q,ksu-plantpath-lee.q,batch.q

# Test the AMRFinder organism mapping fix
# This script tests with 5 Pseudomonas samples to verify the fix

set -euo pipefail

echo "========================================="
echo "Testing AMRFinder Fix - v1.0.1 hotfix"
echo "========================================="
echo "Date: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo ""

# Get 5 Pseudomonas accessions from the existing results
PSEUDOMONAS_DIR="/fastscratch/tylerdoe/pseudomonas_phage_hunter_results"
echo "Finding test samples from: ${PSEUDOMONAS_DIR}"

# Find 5 accessions that actually completed in the previous run
TEST_ACCESSIONS=$(find ${PSEUDOMONAS_DIR} -name "*_amr.tsv" 2>/dev/null | head -5 | xargs -n1 basename | sed 's/_amr.tsv$//' | tr '\n' ',' | sed 's/,$//')

if [ -z "$TEST_ACCESSIONS" ]; then
    echo "ERROR: Could not find any previous Pseudomonas results"
    echo "Trying to get accessions from assembly files instead..."
    TEST_ACCESSIONS=$(find ${PSEUDOMONAS_DIR} -name "*.fna" 2>/dev/null | head -5 | xargs -n1 basename | sed 's/.fna$//' | tr '\n' ',' | sed 's/,$//')
fi

echo "Test samples (5 Pseudomonas aeruginosa):"
echo "$TEST_ACCESSIONS" | tr ',' '\n'
echo ""

# Create test accession file
TEST_DIR="/fastscratch/tylerdoe/test_amrfinder_v1.0.1_${SLURM_JOB_ID}"
mkdir -p ${TEST_DIR}
echo "$TEST_ACCESSIONS" | tr ',' '\n' > ${TEST_DIR}/test_accessions.txt

echo "Test accessions saved to: ${TEST_DIR}/test_accessions.txt"
echo "Output directory: ${TEST_DIR}"
echo ""

# Run COMPASS with the hotfix
echo "Running COMPASS with AMRFinder fix..."
cd /fastscratch/tylerdoe/COMPASS-pipeline

nextflow run workflows/main.nf \
    -profile hpc \
    --input ${TEST_DIR}/test_accessions.txt \
    --organism "Pseudomonas aeruginosa" \
    --outdir ${TEST_DIR}/results \
    --max_cpus 4 \
    --max_memory 16.GB \
    -resume

EXIT_CODE=$?

echo ""
echo "========================================="
echo "Test Results"
echo "========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Pipeline completed successfully"
    echo ""

    # Check AMRFinder results
    echo "Checking AMRFinder output files..."
    AMR_FILES=$(find ${TEST_DIR}/results/amrfinder -name "*_amr.tsv" 2>/dev/null | wc -l)
    EMPTY_FILES=$(find ${TEST_DIR}/results/amrfinder -name "*_amr.tsv" -size 0 2>/dev/null | wc -l)
    NON_EMPTY=$(find ${TEST_DIR}/results/amrfinder -name "*_amr.tsv" ! -size 0 2>/dev/null | wc -l)

    echo "  Total AMR files: ${AMR_FILES}"
    echo "  Empty files (0 bytes): ${EMPTY_FILES}"
    echo "  Non-empty files: ${NON_EMPTY}"
    echo ""

    if [ ${EMPTY_FILES} -eq 0 ] && [ ${NON_EMPTY} -gt 0 ]; then
        echo "✓ SUCCESS: All AMRFinder files have content!"
        echo "✓ The fix works - Pseudomonas now produces AMR results"
        echo ""
        echo "Sample file sizes:"
        find ${TEST_DIR}/results/amrfinder -name "*_amr.tsv" -exec ls -lh {} \; | awk '{print "  " $9 ": " $5}'
        echo ""
        echo "Sample file preview (first file):"
        FIRST_FILE=$(find ${TEST_DIR}/results/amrfinder -name "*_amr.tsv" | head -1)
        echo "  File: $(basename $FIRST_FILE)"
        head -20 "$FIRST_FILE" | sed 's/^/  /'
    else
        echo "✗ FAILURE: Still have empty AMRFinder files"
        echo "  This indicates the fix did not work as expected"
        echo ""
        echo "Empty files:"
        find ${TEST_DIR}/results/amrfinder -name "*_amr.tsv" -size 0
    fi

    echo ""
    echo "Results location: ${TEST_DIR}/results"
else
    echo "✗ Pipeline failed with exit code: $EXIT_CODE"
    echo "Check logs at: ${TEST_DIR}/results/.nextflow.log"
fi

echo ""
echo "Test completed: $(date)"
echo "========================================="
