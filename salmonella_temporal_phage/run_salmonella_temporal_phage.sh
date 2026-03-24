#!/bin/bash
#SBATCH --job-name=salmonella_temporal_phage
#SBATCH --output=/fastscratch/tylerdoe/slurm-salmonella-temporal-phage-%j.out
#SBATCH --error=/fastscratch/tylerdoe/slurm-salmonella-temporal-phage-%j.err
#SBATCH --time=336:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS Pipeline - Salmonella Prophage Dynamics"
echo "=========================================="
echo "Organism: Salmonella enterica"
echo "Sampling: 50 per month (Jan 2020 - Mar 2026)"
echo "Focus: Prophage-virulence-AMR dynamics by serotype"
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
PROJECT_DIR="$PIPELINE_DIR/salmonella_temporal_phage"

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
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_salmonella_temporal_phage

# Increase Nextflow JVM heap size for large runs (3,750+ samples)
# Prevents "java.lang.OutOfMemoryError: Java heap space" during pipeline orchestration
export NXF_OPTS='-Xms2g -Xmx8g'

# Set output directory
OUTPUT_DIR="/fastscratch/tylerdoe/salmonella_temporal_phage_results"

echo "Working directory: $(pwd)"
echo "Project directory: $PROJECT_DIR"
echo "Input file: $PROJECT_DIR/data/samplesheet_salmonella_temporal_phage.txt"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if samplesheet exists
if [ ! -f "$PROJECT_DIR/data/samplesheet_salmonella_temporal_phage.txt" ]; then
    echo "ERROR: Samplesheet not found!"
    echo "Expected: $PROJECT_DIR/data/samplesheet_salmonella_temporal_phage.txt"
    echo ""
    echo "Please run the data download first:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. python3 scripts/fetch_salmonella_monthly.py"
    echo "  3. python3 scripts/create_samplesheet.py"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(wc -l < "$PROJECT_DIR/data/samplesheet_salmonella_temporal_phage.txt")
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
    --input "$PROJECT_DIR/data/samplesheet_salmonella_temporal_phage.txt" \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --outdir "$OUTPUT_DIR" \
    -w work_salmonella_temporal_phage \
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
    echo "Key outputs for Salmonella serotype + temporal analysis:"
    echo "  - Serotyping (SISTR): $OUTPUT_DIR/sistr/"
    echo "  - MLST typing: $OUTPUT_DIR/mlst/"
    echo "  - Prophages (VIBRANT): $OUTPUT_DIR/vibrant/"
    echo "  - Plasmids (MOB-suite): $OUTPUT_DIR/mobsuite/"
    echo "  - AMR genes (AMRFinder): $OUTPUT_DIR/amrfinder/"
    echo "  - ABRicate AMR: $OUTPUT_DIR/abricate/"
    echo "  - BUSCO QC: $OUTPUT_DIR/busco/"
    echo "  - MultiQC report: $OUTPUT_DIR/multiqc/multiqc_report.html"
    echo "  - COMPASS summary: $OUTPUT_DIR/summary/"
    echo ""
    echo "Quick stats:"
    sistr_count=$(find "$OUTPUT_DIR/sistr" -type f -name "*.tsv" 2>/dev/null | wc -l)
    vibrant_count=$(find "$OUTPUT_DIR/vibrant" -type d -name "*_vibrant" 2>/dev/null | wc -l)
    mob_count=$(find "$OUTPUT_DIR/mobsuite" -type d -name "*_mobsuite" 2>/dev/null | wc -l)
    amr_count=$(find "$OUTPUT_DIR/amrfinder" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    echo "  Samples with serotyping: $sistr_count"
    echo "  Samples with prophage analysis: $vibrant_count"
    echo "  Samples with plasmid analysis: $mob_count"
    echo "  Samples with AMR analysis: $amr_count"
    echo ""
    echo "Serotype-focused analysis ideas:"
    echo "  1. Prophage prevalence by serotype (Typhimurium vs Enteritidis vs Newport)"
    echo "  2. Gifsy-1/2 distribution in Typhimurium over time"
    echo "  3. Serotype diversity trends (2020-2026)"
    echo "  4. AMR patterns by serotype (MDR in Typhimurium vs others)"
    echo "  5. Prophage-plasmid co-occurrence by serotype"
    echo "  6. Virulence gene location (chromosome/plasmid/prophage) by serotype"
    echo "  7. MLST clustering and temporal dynamics"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo ""
    echo "Check logs:"
    echo "  - SLURM output: /fastscratch/tylerdoe/slurm-salmonella-temporal-phage-${SLURM_JOB_ID}.out"
    echo "  - Nextflow log: $PIPELINE_DIR/.nextflow.log"
    echo ""
    echo "Resume with: sbatch $PROJECT_DIR/run_salmonella_temporal_phage.sh"
fi

exit $EXIT_CODE
