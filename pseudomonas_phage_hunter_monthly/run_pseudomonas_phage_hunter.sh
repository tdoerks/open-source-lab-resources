#!/bin/bash
#SBATCH --job-name=pseudomonas_phage_hunter
#SBATCH --output=/fastscratch/tylerdoe/slurm-pseudomonas-phage-hunter-%j.out
#SBATCH --error=/fastscratch/tylerdoe/slurm-pseudomonas-phage-hunter-%j.err
#SBATCH --time=336:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS Pipeline - Pseudomonas Phage Hunter"
echo "=========================================="
echo "Organism: Pseudomonas aeruginosa"
echo "Sampling: 50 per month (Jan 2020 - Mar 2026)"
echo "Focus: Phage-Plasmid-AMR Temporal Dynamics"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo ""

# Change to pipeline directory
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline"
PROJECT_DIR="$PIPELINE_DIR/pseudomonas_phage_hunter_monthly"

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
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_pseudomonas_phage_hunter

# Set output directory
OUTPUT_DIR="/fastscratch/tylerdoe/pseudomonas_phage_hunter_results"

echo "Working directory: $(pwd)"
echo "Project directory: $PROJECT_DIR"
echo "Input file: $PROJECT_DIR/samplesheet_pseudomonas_phage_hunter.txt"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if samplesheet exists
if [ ! -f "$PROJECT_DIR/samplesheet_pseudomonas_phage_hunter.txt" ]; then
    echo "ERROR: Samplesheet not found!"
    echo "Expected: $PROJECT_DIR/samplesheet_pseudomonas_phage_hunter.txt"
    echo ""
    echo "Please run the data download first:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. python3 scripts/fetch_pseudomonas_monthly.py"
    echo "  3. python3 scripts/create_samplesheet.py"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(wc -l < "$PROJECT_DIR/samplesheet_pseudomonas_phage_hunter.txt")
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
    --input "$PROJECT_DIR/samplesheet_pseudomonas_phage_hunter.txt" \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --outdir "$OUTPUT_DIR" \
    -w work_pseudomonas_phage_hunter \
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
    echo "Key outputs for phage-plasmid-AMR analysis:"
    echo "  - Prophages (VIBRANT): $OUTPUT_DIR/vibrant/"
    echo "  - Plasmids (MOB-suite): $OUTPUT_DIR/mobsuite/"
    echo "  - AMR genes (AMRFinder): $OUTPUT_DIR/amrfinder/"
    echo "  - ABRicate AMR: $OUTPUT_DIR/abricate/"
    echo "  - MLST typing: $OUTPUT_DIR/mlst/"
    echo "  - BUSCO QC: $OUTPUT_DIR/busco/"
    echo "  - MultiQC report: $OUTPUT_DIR/multiqc/multiqc_report.html"
    echo "  - COMPASS summary: $OUTPUT_DIR/summary/"
    echo ""
    echo "Quick stats:"
    vibrant_count=$(find "$OUTPUT_DIR/vibrant" -type d -name "*_vibrant" 2>/dev/null | wc -l)
    mob_count=$(find "$OUTPUT_DIR/mobsuite" -type d -name "*_mobsuite" 2>/dev/null | wc -l)
    amr_count=$(find "$OUTPUT_DIR/amrfinder" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    echo "  Samples with prophage analysis: $vibrant_count"
    echo "  Samples with plasmid analysis: $mob_count"
    echo "  Samples with AMR analysis: $amr_count"
    echo ""
    echo "Analysis ideas:"
    echo "  1. Prophage prevalence trends (2020-2026)"
    echo "  2. Plasmid-prophage co-occurrence patterns"
    echo "  3. AMR gene mobility (chromosome vs plasmid vs prophage)"
    echo "  4. XDR/MDR strain emergence over time"
    echo "  5. Temporal HGT events (phage-mediated)"
    echo "  6. Biofilm genes on mobile elements"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo ""
    echo "Check logs:"
    echo "  - SLURM output: /fastscratch/tylerdoe/slurm-pseudomonas-phage-hunter-${SLURM_JOB_ID}.out"
    echo "  - Nextflow log: $PIPELINE_DIR/.nextflow.log"
    echo ""
    echo "Resume with: sbatch $PROJECT_DIR/run_pseudomonas_phage_hunter.sh"
fi

exit $EXIT_CODE
