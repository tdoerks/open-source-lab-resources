#!/bin/bash
#SBATCH --job-name=vibrio_cholerae_geo
#SBATCH --output=/fastscratch/tylerdoe/slurm-vibrio-cholerae-%j.out
#SBATCH --error=/fastscratch/tylerdoe/slurm-vibrio-cholerae-%j.err
#SBATCH --time=336:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS Pipeline - Vibrio cholerae Geographic + Temporal"
echo "=========================================="
echo "Organism: Vibrio cholerae"
echo "Sampling: 50 per month (Jan 2020 - Mar 2026)"
echo "Geographic: South Asia, Africa, Americas, SE Asia"
echo "Focus: CTXφ prophage + Geographic AMR spread"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo ""

# Change to pipeline directory
# NOTE: Update this path based on which COMPASS version you're using
# For 1.0.0: /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
# For scratch: /fastscratch/tylerdoe/COMPASS-pipeline
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0"
PROJECT_DIR="$PIPELINE_DIR/vibrio_cholerae_temporal_geographic"

cd "$PIPELINE_DIR" || {
    echo "ERROR: Could not cd to $PIPELINE_DIR"
    exit 1
}

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set unique Nextflow home to avoid cache conflicts
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_vibrio_cholerae

# Set output directory
OUTPUT_DIR="/fastscratch/tylerdoe/vibrio_cholerae_results"

echo "Working directory: $(pwd)"
echo "Project directory: $PROJECT_DIR"
echo "Input file: $PROJECT_DIR/samplesheet_vibrio_cholerae.txt"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if samplesheet exists
if [ ! -f "$PROJECT_DIR/samplesheet_vibrio_cholerae.txt" ]; then
    echo "ERROR: Samplesheet not found!"
    echo "Expected: $PROJECT_DIR/samplesheet_vibrio_cholerae.txt"
    echo ""
    echo "Please run the data download first:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. python3 scripts/fetch_vibrio_geographic.py"
    echo "  3. python3 scripts/create_samplesheet.py"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(wc -l < "$PROJECT_DIR/samplesheet_vibrio_cholerae.txt")
echo "Total samples in samplesheet: $SAMPLE_COUNT"
echo ""

# Run COMPASS pipeline
echo "=========================================="
echo "Starting COMPASS pipeline..."
echo "=========================================="
echo ""

nextflow run main.nf \
    -profile beocat \
    --input_mode sra_list \
    --input "$PROJECT_DIR/samplesheet_vibrio_cholerae.txt" \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --outdir "$OUTPUT_DIR" \
    -w work_vibrio_cholerae \
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
    echo "Results location: $OUTPUT_DIR"
    echo ""
    echo "Key outputs for geographic + temporal analysis:"
    echo "  - Prophages (VIBRANT): $OUTPUT_DIR/vibrant/"
    echo "  - Plasmids (MOB-suite): $OUTPUT_DIR/mobsuite/"
    echo "  - AMR genes (AMRFinder): $OUTPUT_DIR/amrfinder/"
    echo "  - ABRicate AMR: $OUTPUT_DIR/abricate/"
    echo "  - MLST typing: $OUTPUT_DIR/mlst/"
    echo "  - BUSCO QC: $OUTPUT_DIR/busco/"
    echo "  - MultiQC report: $OUTPUT_DIR/multiqc/multiqc_report.html"
    echo "  - COMPASS summary: $OUTPUT_DIR/summary/"
    echo "  - Geographic metadata: $PROJECT_DIR/data/vibrio_geographic_metadata.csv"
    echo ""
    echo "Quick stats:"
    vibrant_count=$(find "$OUTPUT_DIR/vibrant" -type d -name "*_vibrant" 2>/dev/null | wc -l)
    mob_count=$(find "$OUTPUT_DIR/mobsuite" -type d -name "*_mobsuite" 2>/dev/null | wc -l)
    amr_count=$(find "$OUTPUT_DIR/amrfinder" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    echo "  Samples with prophage analysis: $vibrant_count"
    echo "  Samples with plasmid analysis: $mob_count"
    echo "  Samples with AMR analysis: $amr_count"
    echo ""
    echo "Geographic analysis ideas:"
    echo "  1. CTXφ prophage prevalence by region (South Asia vs Africa vs Americas)"
    echo "  2. Temporal epidemic waves per region (2020-2026)"
    echo "  3. AMR emergence patterns (fluoroquinolone resistance spread)"
    echo "  4. Prophage-plasmid co-occurrence by geography"
    echo "  5. MLST diversity and regional clustering"
    echo "  6. SXT/R391 ICE distribution across endemic zones"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo ""
    echo "Check logs:"
    echo "  - SLURM output: /fastscratch/tylerdoe/slurm-vibrio-cholerae-${SLURM_JOB_ID}.out"
    echo "  - Nextflow log: $PIPELINE_DIR/.nextflow.log"
    echo ""
    echo "Resume with: sbatch $PROJECT_DIR/run_vibrio_cholerae.sh"
fi

exit $EXIT_CODE
