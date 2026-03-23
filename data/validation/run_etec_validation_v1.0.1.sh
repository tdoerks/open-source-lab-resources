#!/bin/bash
#SBATCH --job-name=etec_val_v1.0.1
#SBATCH --output=/homes/tylerdoe/slurm-etec-validation-v1.0.1-%j.out
#SBATCH --error=/homes/tylerdoe/slurm-etec-validation-v1.0.1-%j.err
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS v1.0.1 ETEC Validation (AMRFinder Fix)"
echo "8 ETEC strains from doi:10.1038/s41598-021-88316-2"
echo "Testing: AMRFinder organism mapping fix"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo ""

# Change to COMPASS v1.0.1 candidate directory (scratch branch)
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate || {
    echo "ERROR: Could not cd to /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate"
    exit 1
}

# Verify we're on scratch branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "scratch" ]; then
    echo "ERROR: Not on scratch branch (currently on: $CURRENT_BRANCH)"
    echo "Run: git checkout scratch"
    exit 1
fi

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set Nextflow JVM options
export NXF_OPTS='-Xms1g -Xmx4g'

echo "Working directory: $(pwd)"
echo "Pipeline branch: $CURRENT_BRANCH"
echo "Latest commit: $(git log --oneline -1)"
echo "Input file: data/validation/etec_samplesheet.csv"
echo "Output directory: data/validation/etec_results_v1.0.1"
echo ""

# Verify input files exist
if [ ! -f "data/validation/etec_samplesheet.csv" ]; then
    echo "ERROR: Samplesheet not found: data/validation/etec_samplesheet.csv"
    exit 1
fi

if [ ! -d "data/validation/etec_genomes" ]; then
    echo "ERROR: ETEC genomes directory not found: data/validation/etec_genomes"
    exit 1
fi

echo "✅ Input validation passed"
echo ""

# Run COMPASS pipeline v1.0.1 (scratch branch with AMRFinder fix)
nextflow run main.nf \
    -profile beocat \
    --input data/validation/etec_samplesheet.csv \
    --outdir data/validation/etec_results_v1.0.1 \
    --input_mode fasta \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --max_cpus 8 \
    --max_memory 32.GB \
    -resume

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "End time: $(date)"
echo "Exit code: $EXIT_CODE"
echo "=========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Pipeline completed successfully!"
    echo ""
    echo "Results: data/validation/etec_results_v1.0.1"
    echo ""

    # Validation checks
    echo "Validation checks:"
    echo ""

    # Check AMR files
    AMR_COUNT=$(ls data/validation/etec_results_v1.0.1/amrfinder/*_amr.tsv 2>/dev/null | wc -l)
    EMPTY_AMR=$(find data/validation/etec_results_v1.0.1/amrfinder -name "*_amr.tsv" -size 0 2>/dev/null | wc -l)

    echo "  AMR files created: $AMR_COUNT / 8"
    echo "  Empty AMR files: $EMPTY_AMR"

    if [ $AMR_COUNT -eq 8 ] && [ $EMPTY_AMR -eq 0 ]; then
        echo "  ✅ All ETEC samples have non-empty AMR files"
    else
        echo "  ⚠️  Some AMR files missing or empty"
    fi

    echo ""
    echo "Next steps:"
    echo "  1. Review MultiQC report: data/validation/etec_results_v1.0.1/multiqc/multiqc_report.html"
    echo "  2. Compare with v1.0.0 results:"
    echo "     diff -r data/validation/etec_results_v1.0.0/amrfinder/ \\"
    echo "              data/validation/etec_results_v1.0.1/amrfinder/"
    echo "  3. Check VIBRANT prophage predictions:"
    echo "     ls data/validation/etec_results_v1.0.1/vibrant/"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo "Check logs: /homes/tylerdoe/slurm-etec-validation-v1.0.1-${SLURM_JOB_ID}.out"
    echo ""
    exit 1
fi

exit $EXIT_CODE
