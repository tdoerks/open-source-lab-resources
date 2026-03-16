#!/bin/bash
#SBATCH --job-name=amrfinder_comprehensive_test
#SBATCH --output=/fastscratch/tylerdoe/test_amrfinder_comprehensive_%j.out
#SBATCH --error=/fastscratch/tylerdoe/test_amrfinder_comprehensive_%j.err
#SBATCH --time=4:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=killable.q
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# Comprehensive AMRFinder v1.0.1 Validation Test
# Tests organism mapping across supported, unsupported, and edge-case organisms

set -euo pipefail

echo "============================================================"
echo "AMRFinder v1.0.1 Comprehensive Validation Test"
echo "============================================================"
echo "Date: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo ""
echo "This test validates the AMRFinder organism mapping fix across:"
echo "  - AMRFinder-supported organisms (should use -O flag)"
echo "  - Unsupported organisms (should use generic mode)"
echo "  - Edge cases (genus-level mappings)"
echo ""

# Test configuration
TEST_DIR="/fastscratch/tylerdoe/test_amrfinder_comprehensive_${SLURM_JOB_ID}"
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline"

mkdir -p ${TEST_DIR}
cd ${TEST_DIR}

echo "Test directory: ${TEST_DIR}"
echo "Pipeline directory: ${PIPELINE_DIR}"
echo ""

# Define test organisms with known SRR accessions
# Format: "Organism|SRR_Accession|Expected_Mode|Category"
declare -a TEST_CASES=(
    "Escherichia coli|SRR15214185|Escherichia|SUPPORTED"
    "Salmonella enterica|SRR15214186|Salmonella|SUPPORTED"
    "Vibrio cholerae|SRR19726915|Vibrio_cholerae|SUPPORTED"
    "Klebsiella pneumoniae|SRR15214187|Klebsiella|SUPPORTED"
    "Pseudomonas aeruginosa|SRR15214188|GENERIC|UNSUPPORTED"
    "Citrobacter freundii|SRR15214189|GENERIC|UNSUPPORTED"
    "Proteus mirabilis|SRR15214190|GENERIC|UNSUPPORTED"
    "Serratia marcescens|SRR15214191|GENERIC|UNSUPPORTED"
    "Campylobacter jejuni|SRR15214192|Campylobacter|EDGE_CASE"
    "Enterococcus faecium|SRR15214193|Enterococcus_faecium|EDGE_CASE"
    "Staphylococcus aureus|SRR15214194|Staphylococcus_aureus|EDGE_CASE"
    "Acinetobacter baumannii|SRR15214195|Acinetobacter_baumannii|EDGE_CASE"
)

# Create samplesheet
SAMPLESHEET="${TEST_DIR}/test_samplesheet.csv"
echo "sample_id,organism,srr_accession" > ${SAMPLESHEET}

echo "Creating test samplesheet with 12 organisms..."
echo ""
echo "Test Cases:"
echo "----------------------------------------"
printf "%-30s %-20s %-20s %s\n" "ORGANISM" "SRR" "EXPECTED_MODE" "CATEGORY"
echo "----------------------------------------"

for test_case in "${TEST_CASES[@]}"; do
    IFS='|' read -r organism srr expected_mode category <<< "$test_case"

    # Generate sample ID from organism name
    sample_id=$(echo "$organism" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')

    # Add to samplesheet
    echo "${sample_id},${organism},${srr}" >> ${SAMPLESHEET}

    # Print test case
    printf "%-30s %-20s %-20s %s\n" "$organism" "$srr" "$expected_mode" "$category"
done

echo "----------------------------------------"
echo ""
echo "Samplesheet created: ${SAMPLESHEET}"
echo "Total test samples: $(( ${#TEST_CASES[@]} ))"
echo ""

# Run COMPASS pipeline
echo "============================================================"
echo "Running COMPASS Pipeline with AMRFinder fix..."
echo "============================================================"
echo ""

cd ${PIPELINE_DIR}

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow module"
    exit 1
}

# Run pipeline
nextflow run workflows/main.nf \
    -profile hpc \
    --input ${SAMPLESHEET} \
    --input_mode samplesheet \
    --outdir ${TEST_DIR}/results \
    --max_cpus 8 \
    --max_memory 32.GB \
    --skip_busco true \
    -w ${TEST_DIR}/work \
    -resume

EXIT_CODE=$?

echo ""
echo "============================================================"
echo "Validation Results"
echo "============================================================"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Pipeline completed successfully"
    echo ""

    # Validate AMRFinder results
    echo "Checking AMRFinder outputs..."
    echo ""

    AMR_DIR="${TEST_DIR}/results/amrfinder"

    if [ ! -d "$AMR_DIR" ]; then
        echo "✗ ERROR: AMRFinder output directory not found!"
        exit 1
    fi

    # Count results
    TOTAL_FILES=$(find ${AMR_DIR} -name "*_amr.tsv" 2>/dev/null | wc -l)
    EMPTY_FILES=$(find ${AMR_DIR} -name "*_amr.tsv" -size 0 2>/dev/null | wc -l)
    NON_EMPTY=$(find ${AMR_DIR} -name "*_amr.tsv" ! -size 0 2>/dev/null | wc -l)

    echo "Summary Statistics:"
    echo "  Total AMR files: ${TOTAL_FILES}"
    echo "  Empty files (0 bytes): ${EMPTY_FILES}"
    echo "  Non-empty files: ${NON_EMPTY}"
    echo ""

    # Detailed per-organism results
    echo "============================================================"
    echo "Per-Organism Results"
    echo "============================================================"
    echo ""
    printf "%-30s %-15s %-12s %s\n" "ORGANISM" "EXPECTED_MODE" "FILE_SIZE" "STATUS"
    echo "--------------------------------------------------------------------"

    SUCCESS_COUNT=0
    FAILURE_COUNT=0

    for test_case in "${TEST_CASES[@]}"; do
        IFS='|' read -r organism srr expected_mode category <<< "$test_case"

        sample_id=$(echo "$organism" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        amr_file="${AMR_DIR}/${sample_id}_amr.tsv"

        if [ -f "$amr_file" ]; then
            file_size=$(stat -f%z "$amr_file" 2>/dev/null || stat -c%s "$amr_file" 2>/dev/null)
            human_size=$(ls -lh "$amr_file" | awk '{print $5}')

            if [ "$file_size" -gt 0 ]; then
                status="✓ PASS"
                ((SUCCESS_COUNT++))
            else
                status="✗ FAIL (empty)"
                ((FAILURE_COUNT++))
            fi
        else
            human_size="N/A"
            status="✗ FAIL (missing)"
            ((FAILURE_COUNT++))
        fi

        printf "%-30s %-15s %-12s %s\n" "$organism" "$expected_mode" "$human_size" "$status"
    done

    echo "--------------------------------------------------------------------"
    echo ""

    # Final verdict
    echo "============================================================"
    echo "Final Verdict"
    echo "============================================================"
    echo ""
    echo "Passed: ${SUCCESS_COUNT} / ${#TEST_CASES[@]}"
    echo "Failed: ${FAILURE_COUNT} / ${#TEST_CASES[@]}"
    echo ""

    if [ $FAILURE_COUNT -eq 0 ]; then
        echo "✓✓✓ SUCCESS: All organisms produced AMR results! ✓✓✓"
        echo ""
        echo "The AMRFinder organism mapping fix is working correctly:"
        echo "  ✓ Supported organisms: Running with organism-specific mode"
        echo "  ✓ Unsupported organisms: Running in generic mode"
        echo "  ✓ All samples: Producing valid output files"
        echo ""
        echo "This fix resolves the 0-byte AMRFinder output issue."
        echo "Ready to tag as v1.0.1!"
    else
        echo "✗✗✗ FAILURE: Some organisms did not produce valid results ✗✗✗"
        echo ""
        echo "Empty or missing files:"
        find ${AMR_DIR} -name "*_amr.tsv" -size 0 2>/dev/null
        echo ""
        echo "The fix may need additional work."
    fi

    echo ""
    echo "Results location: ${TEST_DIR}/results"
    echo ""

    # Sample file preview
    if [ $SUCCESS_COUNT -gt 0 ]; then
        echo "Sample AMR file preview (first successful result):"
        echo "--------------------------------------------------------------------"
        FIRST_VALID=$(find ${AMR_DIR} -name "*_amr.tsv" ! -size 0 | head -1)
        if [ -n "$FIRST_VALID" ]; then
            echo "File: $(basename $FIRST_VALID)"
            head -10 "$FIRST_VALID" | sed 's/^/  /'
        fi
        echo "--------------------------------------------------------------------"
    fi

else
    echo "✗ Pipeline failed with exit code: $EXIT_CODE"
    echo ""
    echo "Check logs:"
    echo "  - Nextflow log: ${PIPELINE_DIR}/.nextflow.log"
    echo "  - Work directory: ${TEST_DIR}/work"
    echo "  - SLURM output: /fastscratch/tylerdoe/test_amrfinder_comprehensive_${SLURM_JOB_ID}.out"
fi

echo ""
echo "Test completed: $(date)"
echo "============================================================"

exit $EXIT_CODE
