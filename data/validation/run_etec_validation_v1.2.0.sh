#!/bin/bash
#SBATCH --job-name=etec_val_v1.2.0
#SBATCH --output=/homes/tylerdoe/slurm-etec-validation-v1.2.0-%j.out
#SBATCH --error=/homes/tylerdoe/slurm-etec-validation-v1.2.0-%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS v1.2.0 ETEC Validation"
echo "8 ETEC strains from doi:10.1038/s41598-021-88316-2"
echo "Testing: All v1.2.0 features including Prokka"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo ""

# Change to COMPASS v1.2.0-candidate directory
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate || {
    echo "ERROR: Could not cd to /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate"
    exit 1
}

# Verify we're on 1.2.0-candidate branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "1.2.0-candidate" ]; then
    echo "ERROR: Not on 1.2.0-candidate branch (currently on: $CURRENT_BRANCH)"
    echo "Run: git checkout 1.2.0-candidate"
    exit 1
fi

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set Nextflow JVM options (v1.2.0 has more modules, needs more memory)
export NXF_OPTS='-Xms2g -Xmx8g'

echo "Working directory: $(pwd)"
echo "Pipeline branch: $CURRENT_BRANCH"
echo "Latest commit: $(git log --oneline -1)"
echo "Input file: data/validation/etec_samplesheet.csv"
echo "Output directory: data/validation/etec_results_v1.2.0"
echo ""

# Verify input files exist
if [ ! -f "data/validation/etec_samplesheet.csv" ]; then
    echo "ERROR: data/validation/etec_samplesheet.csv not found"
    echo "Need to copy from 1.0.1-candidate:"
    echo "  cp /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_samplesheet.csv data/validation/"
    echo "  cp -r /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_genomes data/validation/"
    exit 1
fi

# Check ETEC genome files
ETEC_COUNT=$(wc -l < data/validation/etec_samplesheet.csv)
echo "ETEC samplesheet has $ETEC_COUNT lines (including header)"
echo ""

# Verify ETEC genomes directory exists
if [ ! -d "data/validation/etec_genomes" ]; then
    echo "ERROR: data/validation/etec_genomes/ directory not found"
    echo "Copying from 1.0.1-candidate..."
    cp -r /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_genomes data/validation/ || {
        echo "ERROR: Failed to copy etec_genomes"
        exit 1
    }
fi

# Count FASTA files
FASTA_COUNT=$(find data/validation/etec_genomes -name "*.fasta" | wc -l)
echo "Found $FASTA_COUNT FASTA files in etec_genomes/"
echo ""

echo "=========================================="
echo "v1.2.0 Features Enabled:"
echo "  - FastQC/fastp (read QC)"
echo "  - BUSCO (assembly QC)"
echo "  - MLST (sequence typing)"
echo "  - SISTR (Salmonella - will skip for ETEC)"
echo "  - MOB-suite (plasmid detection)"
echo "  - ABRicate (multi-DB AMR)"
echo "  - Prokka (genome annotation) - ENABLED"
echo "  - MultiQC (integrated reporting)"
echo "  - AMRFinder organism mapping fix"
echo "=========================================="
echo ""

# Run pipeline with Prokka ENABLED for testing
echo "Starting Nextflow pipeline..."
echo "Command:"
echo "nextflow run main.nf \\"
echo "  -profile beocat \\"
echo "  --input data/validation/etec_samplesheet.csv \\"
echo "  --outdir data/validation/etec_results_v1.2.0 \\"
echo "  --skip_prokka false \\"
echo "  -resume"
echo ""

nextflow run main.nf \
  -profile beocat \
  --input data/validation/etec_samplesheet.csv \
  --outdir data/validation/etec_results_v1.2.0 \
  --skip_prokka false \
  -resume

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Pipeline finished with exit code: $EXIT_CODE"
echo "End time: $(date)"
echo "=========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ VALIDATION SUCCESSFUL"
    echo ""
    echo "Results location: data/validation/etec_results_v1.2.0/"
    echo ""
    echo "Next steps - Test parsing scripts:"
    echo "  cd data/validation/etec_results_v1.2.0/"
    echo ""
    echo "  # Test VIBRANT parsing"
    echo "  python3 ../../bin/parse_vibrant_summary.py \\"
    echo "    --vibrant vibrant/ \\"
    echo "    --output vibrant_summary.tsv"
    echo ""
    echo "  # Test MOB-suite parsing"
    echo "  python3 ../../bin/parse_mobsuite_plasmids.py \\"
    echo "    --mobsuite mobsuite/ \\"
    echo "    --output mobsuite_summary.tsv"
    echo ""
    echo "  # Test AMR location categorization"
    echo "  python3 ../../bin/categorize_amr_by_location.py \\"
    echo "    --amrfinder amrfinder/ \\"
    echo "    --mobsuite mobsuite/ \\"
    echo "    --vibrant vibrant/ \\"
    echo "    --output amr_location_matrix.tsv"
    echo ""
    echo "  # Test master results table"
    echo "  python3 ../../bin/create_master_results_table.py \\"
    echo "    --results-dir . \\"
    echo "    --output master_results_table.tsv"
    echo ""
    echo "Validation checklist:"
    echo "  [ ] All 8 samples completed"
    echo "  [ ] AMRFinder outputs created"
    echo "  [ ] Prokka outputs present (prokka/ directory)"
    echo "  [ ] MOB-suite detected plasmids (ETEC is plasmid-rich)"
    echo "  [ ] VIBRANT prophage predictions"
    echo "  [ ] All 5 parsing scripts run successfully"
    echo "  [ ] Master results table has expected columns"
else
    echo ""
    echo "❌ VALIDATION FAILED"
    echo ""
    echo "Check logs for errors:"
    echo "  - Pipeline log: .nextflow.log"
    echo "  - SLURM output: /homes/tylerdoe/slurm-etec-validation-v1.2.0-$SLURM_JOB_ID.out"
    echo "  - SLURM errors: /homes/tylerdoe/slurm-etec-validation-v1.2.0-$SLURM_JOB_ID.err"
fi

exit $EXIT_CODE
