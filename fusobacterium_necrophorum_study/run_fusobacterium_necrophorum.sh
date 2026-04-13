#!/bin/bash
#SBATCH --job-name=fusobacterium_necrophorum
#SBATCH --output=/fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-%j.out
#SBATCH --error=/fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-%j.err
#SBATCH --time=168:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

echo "=========================================="
echo "COMPASS Pipeline - Fusobacterium necrophorum Prophage Study"
echo "=========================================="
echo "Organism: Fusobacterium necrophorum (all subspecies)"
echo "Sampling: ALL available WGS genomes (~600)"
echo "Focus: Prophage burden, subspecies comparison, host analysis"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo ""

# Change to pipeline directory
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate"
PROJECT_DIR="$PIPELINE_DIR/fusobacterium_necrophorum_study"

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
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_fusobacterium_necrophorum

# Set Nextflow JVM heap size
export NXF_OPTS='-Xms2g -Xmx8g'

# Set output directory
OUTPUT_DIR="/fastscratch/tylerdoe/fusobacterium_necrophorum_results"

echo "Working directory: $(pwd)"
echo "Project directory: $PROJECT_DIR"
echo "Input file: $PROJECT_DIR/data/samplesheet_fusobacterium_necrophorum.txt"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if samplesheet exists
if [ ! -f "$PROJECT_DIR/data/samplesheet_fusobacterium_necrophorum.txt" ]; then
    echo "ERROR: Samplesheet not found!"
    echo "Expected: $PROJECT_DIR/data/samplesheet_fusobacterium_necrophorum.txt"
    echo ""
    echo "Please run the data download first:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. python3 scripts/fetch_fusobacterium_necrophorum.py"
    echo "  3. python3 scripts/create_samplesheet.py"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(wc -l < "$PROJECT_DIR/data/samplesheet_fusobacterium_necrophorum.txt")
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
    --input "$PROJECT_DIR/data/samplesheet_fusobacterium_necrophorum.txt" \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --outdir "$OUTPUT_DIR" \
    -w work_fusobacterium_necrophorum \
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
    echo "Key outputs for F. necrophorum prophage analysis:"
    echo "  - MLST typing: $OUTPUT_DIR/mlst/"
    echo "  - Prophages (VIBRANT): $OUTPUT_DIR/vibrant/"
    echo "  - Plasmids (MOB-suite): $OUTPUT_DIR/mobsuite/"
    echo "  - AMR genes (AMRFinder): $OUTPUT_DIR/amrfinder/"
    echo "  - Virulence (ABRicate): $OUTPUT_DIR/abricate/"
    echo "  - BUSCO QC: $OUTPUT_DIR/busco/"
    echo "  - MultiQC report: $OUTPUT_DIR/multiqc/multiqc_report.html"
    echo "  - COMPASS summary: $OUTPUT_DIR/summary/"
    echo ""
    echo "Quick stats:"
    mlst_count=$(find "$OUTPUT_DIR/mlst" -type f -name "*.tsv" 2>/dev/null | wc -l)
    vibrant_count=$(find "$OUTPUT_DIR/vibrant" -type d -name "*_vibrant" 2>/dev/null | wc -l)
    mob_count=$(find "$OUTPUT_DIR/mobsuite" -type d -name "*_mobsuite" 2>/dev/null | wc -l)
    amr_count=$(find "$OUTPUT_DIR/amrfinder" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    echo "  Samples with MLST: $mlst_count"
    echo "  Samples with prophage analysis: $vibrant_count"
    echo "  Samples with plasmid analysis: $mob_count"
    echo "  Samples with AMR analysis: $amr_count"
    echo ""
    echo "Fusobacterium-focused analysis ideas:"
    echo "  1. Prophage prevalence (compare to Salmonella, Vibrio, Pseudomonas)"
    echo "  2. Subspecies comparison (necrophorum vs funduliforme)"
    echo "  3. Host source analysis (bovine vs human vs other)"
    echo "  4. Prophage-virulence gene associations"
    echo "  5. Prophage-plasmid co-occurrence patterns"
    echo "  6. AMR distribution across subspecies"
    echo "  7. MLST diversity and subspecies clustering"
    echo ""
else
    echo "❌ Pipeline failed with exit code $EXIT_CODE"
    echo ""
    echo "Check logs:"
    echo "  - SLURM output: /fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-${SLURM_JOB_ID}.out"
    echo "  - Nextflow log: $PIPELINE_DIR/.nextflow.log"
    echo ""
    echo "Resume with: sbatch $PROJECT_DIR/run_fusobacterium_necrophorum.sh"
fi

exit $EXIT_CODE
