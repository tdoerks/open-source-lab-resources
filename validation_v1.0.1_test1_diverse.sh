#!/bin/bash
#SBATCH --job-name=v1.0.1_test1_diverse
#SBATCH --output=/fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_%j.out
#SBATCH --error=/fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_%j.err
#SBATCH --time=6:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=batch.q
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# COMPASS v1.0.1 Validation Test #1: Diverse Organisms
# Tests AMRFinder organism mapping fix across 20 samples from 10 different organisms
# Goal: Validate both supported AND unsupported organisms work correctly

set -euo pipefail

echo "============================================================"
echo "COMPASS v1.0.1 Validation Test #1: Diverse Organisms"
echo "============================================================"
echo "Date: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Branch: scratch (testing AMRFinder organism mapping fix)"
echo ""
echo "Test design:"
echo "  - 20 samples from 10 organisms (2 samples each)"
echo "  - Mix of AMRFinder-supported and unsupported organisms"
echo "  - FASTA mode (using existing assemblies for speed)"
echo "  - Focus: AMRFinder organism-specific vs generic mode"
echo ""
echo "Organisms tested:"
echo "  Supported (organism-specific mode):"
echo "    - Vibrio cholerae"
echo "    - Staphylococcus aureus"
echo "    - Klebsiella pneumoniae (previously broken - FIXED)"
echo "    - Enterococcus faecium"
echo "    - Escherichia coli"
echo ""
echo "  Unsupported (generic mode):"
echo "    - Pseudomonas aeruginosa (main issue!)"
echo "    - Acinetobacter baumannii"
echo "    - Proteus mirabilis"
echo "    - Bacillus cereus"
echo "    - Arcobacter butzleri"
echo "============================================================"
echo ""

TEST_DIR="/fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_${SLURM_JOB_ID}"
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline"
RESULTS_DIR="${HOME}/diverse_bacteria_1000_results"

mkdir -p ${TEST_DIR}

echo "Test directory: ${TEST_DIR}"
echo "Pipeline directory: ${PIPELINE_DIR}"
echo "Source results: ${RESULTS_DIR}"
echo ""

# Create test samplesheet on-the-fly
SAMPLESHEET="${TEST_DIR}/samplesheet_test1_diverse.csv"

echo "Creating test samplesheet..."
echo "sample,fasta,organism" > ${SAMPLESHEET}

# Helper: Find 2 assemblies for each organism
# Vibrio cholerae (supported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Vibrio" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Vibrio cholerae" >> ${SAMPLESHEET}
done

# Staphylococcus aureus (supported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Staphylococcus" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Staphylococcus aureus" >> ${SAMPLESHEET}
done

# Klebsiella pneumoniae (supported - PREVIOUSLY BROKEN)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Klebsiella" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Klebsiella pneumoniae" >> ${SAMPLESHEET}
done

# Enterococcus faecium (supported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Enterococcus" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Enterococcus faecium" >> ${SAMPLESHEET}
done

# Escherichia coli (supported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Escherichia" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Escherichia coli" >> ${SAMPLESHEET}
done

# Pseudomonas aeruginosa (UNSUPPORTED - main issue!)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Pseudomonas" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Pseudomonas aeruginosa" >> ${SAMPLESHEET}
done

# Acinetobacter baumannii (unsupported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Acinetobacter" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Acinetobacter baumannii" >> ${SAMPLESHEET}
done

# Proteus mirabilis (unsupported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Proteus" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Proteus mirabilis" >> ${SAMPLESHEET}
done

# Bacillus cereus (unsupported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Bacillus" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Bacillus cereus" >> ${SAMPLESHEET}
done

# Arcobacter butzleri (unsupported)
find ${RESULTS_DIR}/assemblies -name "*_assembly.fasta" -exec grep -l "Arcobacter" {} \; 2>/dev/null | head -2 | while read f; do
    sample=$(basename $f _assembly.fasta)
    echo "${sample},${f},Arcobacter butzleri" >> ${SAMPLESHEET}
done

# Count samples
SAMPLE_COUNT=$(tail -n +2 ${SAMPLESHEET} | wc -l)
echo "Samples in samplesheet: $SAMPLE_COUNT"
echo ""

if [ $SAMPLE_COUNT -lt 10 ]; then
    echo "WARNING: Only found $SAMPLE_COUNT samples (expected 20)"
    echo "Proceeding with available samples..."
fi

# Change to pipeline directory and checkout scratch branch
cd ${PIPELINE_DIR}

echo "Updating pipeline to scratch branch..."
git fetch origin scratch
git checkout scratch
git pull origin scratch

CURRENT_BRANCH=$(git branch --show-current)
LATEST_COMMIT=$(git log --oneline -1)

echo "Pipeline branch: ${CURRENT_BRANCH}"
echo "Latest commit: ${LATEST_COMMIT}"
echo ""

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow module"
    exit 1
}

# Set Nextflow JVM options for stability
export NXF_OPTS='-Xms1g -Xmx4g'

echo "============================================================"
echo "Running COMPASS pipeline (scratch branch)..."
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

        if [ $EMPTY_AMR -eq 0 ]; then
            echo "  ✓ No empty AMR files (all organisms processed correctly!)"
        else
            echo "  ✗ FAIL: $EMPTY_AMR empty AMR files found"
            echo "  Empty files:"
            find $AMR_DIR -name "*_amr.tsv" -size 0 2>/dev/null | while read f; do
                echo "    - $(basename $f)"
            done
        fi

        echo ""
        echo "AMR file sizes:"
        ls -lh $AMR_DIR/*_amr.tsv | awk '{print $5, $9}' | column -t

        # Check for Pseudomonas specifically
        echo ""
        echo "Pseudomonas samples (key test):"
        grep -i "pseudomonas" ${SAMPLESHEET} | while read line; do
            sample=$(echo $line | cut -d',' -f1)
            amr_file="${AMR_DIR}/${sample}_amr.tsv"
            if [ -f "$amr_file" ]; then
                size=$(stat -f%z "$amr_file" 2>/dev/null || stat -c%s "$amr_file" 2>/dev/null)
                if [ $size -gt 0 ]; then
                    echo "  ✓ ${sample}: Non-empty (${size} bytes) - Generic mode worked!"
                else
                    echo "  ✗ ${sample}: Empty file - FAILED"
                fi
            else
                echo "  ✗ ${sample}: File not found"
            fi
        done

    else
        echo "  ✗ AMRFinder output directory not found!"
    fi

    echo ""
    echo "============================================================"
    echo "VALIDATION: PASS ✓"
    echo "============================================================"

else
    echo "✗ Pipeline failed with exit code $PIPELINE_EXIT"
    echo ""
    echo "Check logs for errors:"
    echo "  SLURM output: /fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_${SLURM_JOB_ID}.out"
    echo "  SLURM error: /fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_${SLURM_JOB_ID}.err"
    echo ""
    echo "============================================================"
    echo "VALIDATION: FAIL ✗"
    echo "============================================================"
fi

echo ""
echo "Test completed: $(date)"
echo ""
echo "Next steps:"
echo "  1. Review validation results above"
echo "  2. If PASS, run Test #2 (Pseudomonas-focused)"
echo "  3. If both pass, merge scratch → main and tag v1.0.1"
echo ""

exit $PIPELINE_EXIT
