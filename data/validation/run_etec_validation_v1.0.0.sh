#!/bin/bash
#SBATCH --job-name=etec_val_v1.0.0
#SBATCH --output=/homes/tylerdoe/slurm-etec-validation-v1.0.0-%j.out
#SBATCH --error=/homes/tylerdoe/slurm-etec-validation-v1.0.0-%j.err
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS v1.0.0 ETEC Validation (DOI Version)"
echo "8 ETEC strains from doi:10.1038/s41598-021-88316-2"
echo "Pipeline DOI: [YOUR_COMPASS_DOI_HERE]"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo ""

# Change to COMPASS v1.0.0 directory
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0 || {
    echo "ERROR: Could not cd to /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0"
    exit 1
}

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

echo "Working directory: $(pwd)"
echo "Pipeline version: v1.0.0 (DOI release)"
echo "Input file: data/validation/etec_samplesheet.csv"
echo "Output directory: data/validation/etec_results_v1.0.0"
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

# Run COMPASS pipeline v1.0.0
nextflow run main.nf \
    -profile beocat \
    --input data/validation/etec_samplesheet.csv \
    --outdir data/validation/etec_results_v1.0.0 \
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
    echo "Results: data/validation/etec_results_v1.0.0"
    echo ""
    echo "Next steps:"
    echo "  1. Review MultiQC report: data/validation/etec_results_v1.0.0/multiqc/multiqc_report.html"
    echo "  2. Check VIBRANT prophage predictions:"
    echo "     ls data/validation/etec_results_v1.0.0/vibrant/"
    echo "  3. Compare with Nature paper Table S4:"
    echo "     - Paper: E925 has 5 prophages"
    echo "     - Check if COMPASS found overlapping regions"
    echo "  4. Archive results to bulk:"
    echo "     rsync -avh data/validation/etec_results_v1.0.0/ \\"
    echo "       /bulk/tylerdoe/archives/ETEC_Validation_v1.0.0_$(date +%Y-%m-%d)/"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo "Check logs: /homes/tylerdoe/slurm-etec-validation-v1.0.0-${SLURM_JOB_ID}.out"
    echo ""
    exit 1
fi

exit $EXIT_CODE
