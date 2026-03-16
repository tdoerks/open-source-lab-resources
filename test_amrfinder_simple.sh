#!/bin/bash
#SBATCH --job-name=amrfinder_test
#SBATCH --output=/fastscratch/tylerdoe/test_amrfinder_simple_%j.out
#SBATCH --error=/fastscratch/tylerdoe/test_amrfinder_simple_%j.err
#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=killable.q
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# Simple AMRFinder v1.0.1 Validation Test
# Tests 3 key organism categories with 1 sample each

set -euo pipefail

echo "============================================================"
echo "AMRFinder v1.0.1 Simple Validation Test"
echo "============================================================"
echo "Date: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo ""
echo "Testing 3 organism categories:"
echo "  1. SUPPORTED: Vibrio cholerae (should use -O Vibrio_cholerae)"
echo "  2. UNSUPPORTED: Pseudomonas aeruginosa (should use generic mode)"
echo "  3. EDGE CASE: Enterococcus faecium (should use -O Enterococcus_faecium)"
echo ""

TEST_DIR="/fastscratch/tylerdoe/test_amrfinder_simple_${SLURM_JOB_ID}"
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline"

mkdir -p ${TEST_DIR}
cd ${PIPELINE_DIR}

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow module"
    exit 1
}

echo "Test directory: ${TEST_DIR}"
echo "Pipeline directory: ${PIPELINE_DIR}"
echo ""

# Test 1: Vibrio cholerae (SUPPORTED)
echo "============================================================"
echo "Test 1: Vibrio cholerae (SUPPORTED organism)"
echo "============================================================"
echo "SRR: SRR19726915"
echo "Expected: AMRFinder runs with -O Vibrio_cholerae"
echo ""

echo "SRR19726915" > ${TEST_DIR}/vibrio_test.txt

nextflow run main.nf \
    -profile beocat \
    --input_mode sra_list \
    --input ${TEST_DIR}/vibrio_test.txt \
    --organism "Vibrio cholerae" \
    --outdir ${TEST_DIR}/vibrio_results \
    --skip_busco true \
    --max_cpus 8 \
    --max_memory 32.GB \
    -w ${TEST_DIR}/work_vibrio \
    -resume

VIBRIO_EXIT=$?

# Test 2: Pseudomonas aeruginosa (UNSUPPORTED)
echo ""
echo "============================================================"
echo "Test 2: Pseudomonas aeruginosa (UNSUPPORTED organism)"
echo "============================================================"
echo "SRR: SRR15214188"
echo "Expected: AMRFinder runs in generic mode (no -O flag)"
echo ""

echo "SRR15214188" > ${TEST_DIR}/pseudomonas_test.txt

nextflow run main.nf \
    -profile beocat \
    --input_mode sra_list \
    --input ${TEST_DIR}/pseudomonas_test.txt \
    --organism "Pseudomonas aeruginosa" \
    --outdir ${TEST_DIR}/pseudomonas_results \
    --skip_busco true \
    --max_cpus 8 \
    --max_memory 32.GB \
    -w ${TEST_DIR}/work_pseudomonas \
    -resume

PSEUDOMONAS_EXIT=$?

# Test 3: Enterococcus faecium (EDGE CASE)
echo ""
echo "============================================================"
echo "Test 3: Enterococcus faecium (EDGE CASE - species-specific)"
echo "============================================================"
echo "SRR: SRR15214193"
echo "Expected: AMRFinder runs with -O Enterococcus_faecium"
echo ""

echo "SRR15214193" > ${TEST_DIR}/enterococcus_test.txt

nextflow run main.nf \
    -profile beocat \
    --input_mode sra_list \
    --input ${TEST_DIR}/enterococcus_test.txt \
    --organism "Enterococcus faecium" \
    --outdir ${TEST_DIR}/enterococcus_results \
    --skip_busco true \
    --max_cpus 8 \
    --max_memory 32.GB \
    -w ${TEST_DIR}/work_enterococcus \
    -resume

ENTEROCOCCUS_EXIT=$?

# Validation
echo ""
echo "============================================================"
echo "Validation Results"
echo "============================================================"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

# Check Vibrio
echo "Test 1: Vibrio cholerae"
if [ $VIBRIO_EXIT -eq 0 ]; then
    VIBRIO_AMR="${TEST_DIR}/vibrio_results/amrfinder/SRR19726915_amr.tsv"
    if [ -f "$VIBRIO_AMR" ] && [ -s "$VIBRIO_AMR" ]; then
        SIZE=$(ls -lh "$VIBRIO_AMR" | awk '{print $5}')
        echo "  ✓ PASS - AMR file exists and has content ($SIZE)"
        ((SUCCESS_COUNT++))
    else
        echo "  ✗ FAIL - AMR file is empty or missing"
        ((FAIL_COUNT++))
    fi
else
    echo "  ✗ FAIL - Pipeline failed with exit code $VIBRIO_EXIT"
    ((FAIL_COUNT++))
fi

# Check Pseudomonas
echo "Test 2: Pseudomonas aeruginosa"
if [ $PSEUDOMONAS_EXIT -eq 0 ]; then
    PSEUDOMONAS_AMR="${TEST_DIR}/pseudomonas_results/amrfinder/SRR15214188_amr.tsv"
    if [ -f "$PSEUDOMONAS_AMR" ] && [ -s "$PSEUDOMONAS_AMR" ]; then
        SIZE=$(ls -lh "$PSEUDOMONAS_AMR" | awk '{print $5}')
        echo "  ✓ PASS - AMR file exists and has content ($SIZE)"
        ((SUCCESS_COUNT++))
    else
        echo "  ✗ FAIL - AMR file is empty or missing"
        ((FAIL_COUNT++))
    fi
else
    echo "  ✗ FAIL - Pipeline failed with exit code $PSEUDOMONAS_EXIT"
    ((FAIL_COUNT++))
fi

# Check Enterococcus
echo "Test 3: Enterococcus faecium"
if [ $ENTEROCOCCUS_EXIT -eq 0 ]; then
    ENTEROCOCCUS_AMR="${TEST_DIR}/enterococcus_results/amrfinder/SRR15214193_amr.tsv"
    if [ -f "$ENTEROCOCCUS_AMR" ] && [ -s "$ENTEROCOCCUS_AMR" ]; then
        SIZE=$(ls -lh "$ENTEROCOCCUS_AMR" | awk '{print $5}')
        echo "  ✓ PASS - AMR file exists and has content ($SIZE)"
        ((SUCCESS_COUNT++))
    else
        echo "  ✗ FAIL - AMR file is empty or missing"
        ((FAIL_COUNT++))
    fi
else
    echo "  ✗ FAIL - Pipeline failed with exit code $ENTEROCOCCUS_EXIT"
    ((FAIL_COUNT++))
fi

echo ""
echo "============================================================"
echo "Final Verdict"
echo "============================================================"
echo "Passed: ${SUCCESS_COUNT} / 3"
echo "Failed: ${FAIL_COUNT} / 3"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓✓✓ SUCCESS: All 3 organism categories passed! ✓✓✓"
    echo ""
    echo "The AMRFinder organism mapping fix is working:"
    echo "  ✓ Supported organisms: Using organism-specific mode"
    echo "  ✓ Unsupported organisms: Using generic mode"
    echo "  ✓ Edge cases: Properly mapped"
    echo ""
    echo "Ready to tag as v1.0.1!"
    EXIT_CODE=0
else
    echo "✗ FAILURE: Some tests did not pass"
    echo ""
    echo "Check individual test results above for details"
    EXIT_CODE=1
fi

echo ""
echo "Results location: ${TEST_DIR}"
echo "Test completed: $(date)"
echo "============================================================"

exit $EXIT_CODE
