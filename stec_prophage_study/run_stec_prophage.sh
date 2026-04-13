#!/bin/bash
#SBATCH --job-name=stec_prophage
#SBATCH --output=/fastscratch/tylerdoe/slurm-stec-prophage-%j.out
#SBATCH --error=/fastscratch/tylerdoe/slurm-stec-prophage-%j.err
#SBATCH --time=672:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS Pipeline - STEC Prophage Dynamics Study"
echo "=========================================="
echo "Organism: E. coli (STEC - Shiga toxin-producing)"
echo "Focus: Stx prophage dynamics, serotype comparison"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo ""

# Change to pipeline directory
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.1.0-candidate"
PROJECT_DIR="$PIPELINE_DIR/stec_prophage_study"

cd "$PIPELINE_DIR" || {
    echo "ERROR: Could not cd to $PIPELINE_DIR"
    exit 1
}

# Load Nextflow
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set unique Nextflow home
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_stec

# Set Nextflow JVM heap size
export NXF_OPTS='-Xms2g -Xmx8g'

# Set output directory
OUTPUT_DIR="/fastscratch/tylerdoe/stec_prophage_results"

echo "Working directory: $(pwd)"
echo "Project directory: $PROJECT_DIR"
echo "Input file: $PROJECT_DIR/data/samplesheet_stec.txt"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if samplesheet exists
if [ ! -f "$PROJECT_DIR/data/samplesheet_stec.txt" ]; then
    echo "ERROR: Samplesheet not found!"
    echo "Expected: $PROJECT_DIR/data/samplesheet_stec.txt"
    echo ""
    echo "Please run the data download first:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. python3 scripts/fetch_stec_temporal.py  # or fetch_stec_all.py"
    echo "  3. python3 scripts/create_samplesheet.py"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(wc -l < "$PROJECT_DIR/data/samplesheet_stec.txt")
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
    --input "$PROJECT_DIR/data/samplesheet_stec.txt" \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --outdir "$OUTPUT_DIR" \
    -w work_stec \
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
    echo "Key outputs for STEC prophage analysis:"
    echo "  - MLST typing: $OUTPUT_DIR/mlst/"
    echo "  - Prophages (VIBRANT): $OUTPUT_DIR/vibrant/"
    echo "  - Plasmids (MOB-suite): $OUTPUT_DIR/mobsuite/"
    echo "  - AMR/Virulence (AMRFinder): $OUTPUT_DIR/amrfinder/ 🔥 stx1/stx2/eae HERE"
    echo "  - ABRicate: $OUTPUT_DIR/abricate/"
    echo "  - BUSCO QC: $OUTPUT_DIR/busco/"
    echo "  - MultiQC report: $OUTPUT_DIR/multiqc/multiqc_report.html"
    echo "  - COMPASS summary: $OUTPUT_DIR/summary/"
    echo ""
    echo "STEC Analysis Strategy:"
    echo "  1. Filter AMRFinder results for stx1/stx2 genes"
    echo "  2. Identify STEC samples (stx+)"
    echo "  3. Analyze prophage burden: STEC vs non-STEC"
    echo "  4. Stx1 vs Stx2 prophage variants"
    echo "  5. Serotype identification (if possible from MLST/metadata)"
    echo "  6. Temporal dynamics of Stx prophages"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo ""
    echo "Check logs:"
    echo "  - SLURM output: /fastscratch/tylerdoe/slurm-stec-prophage-${SLURM_JOB_ID}.out"
    echo "  - Nextflow log: $PIPELINE_DIR/.nextflow.log"
    echo ""
    echo "Resume with: sbatch $PROJECT_DIR/run_stec_prophage.sh"
fi

exit $EXIT_CODE
