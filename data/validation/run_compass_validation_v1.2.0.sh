#!/bin/bash
#SBATCH --job-name=compass_val_v1.2.0
#SBATCH --output=/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_%j/logs/compass_validation_%j.out
#SBATCH --error=/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_%j/logs/compass_validation_%j.err
#SBATCH --time=96:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

# COMPASS v1.2.0 Validation Run
# Testing new features: Panaroo pangenome, IQ-TREE phylogeny, enhanced HTML summary
# Date: 2026-04-01
# Expected runtime: 48-96 hours (includes phylogenetic tree construction)

set -e

echo "=========================================="
echo "COMPASS v1.2.0 Validation Run"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "Node: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: 128GB"
echo "Walltime: 96 hours (4 days)"
echo "Pipeline Version: 1.2.0 (1.2.0-candidate branch)"
echo ""

# Load required modules
echo "Loading modules..."
module load Nextflow || {
    echo "ERROR: Could not load Nextflow"
    exit 1
}

# Set Nextflow JVM options for large runs
export NXF_OPTS='-Xms4g -Xmx16g'

# Change to COMPASS v1.2.0 candidate directory
PIPELINE_DIR="/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate"
if [ ! -d "$PIPELINE_DIR" ]; then
    echo "ERROR: Pipeline directory not found: $PIPELINE_DIR"
    echo "Please ensure you have the v1.2.0 candidate directory set up"
    exit 1
fi

cd "$PIPELINE_DIR" || exit 1
echo "Working directory: $(pwd)"
echo ""

# Verify we're on 1.2.0-candidate branch
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_COMMIT=$(git log --oneline -1)

echo "Git branch: $CURRENT_BRANCH"
echo "Latest commit: $CURRENT_COMMIT"
echo ""

if [ "$CURRENT_BRANCH" != "1.2.0-candidate" ]; then
    echo "ERROR: Not on 1.2.0-candidate branch (currently on: $CURRENT_BRANCH)"
    echo "Run: git checkout 1.2.0-candidate"
    exit 1
fi

# Check samplesheet exists
SAMPLESHEET="$PIPELINE_DIR/data/validation/validation_samplesheet_fasta.csv"
if [ ! -f "$SAMPLESHEET" ]; then
    echo "ERROR: Samplesheet not found: $SAMPLESHEET"
    echo ""
    echo "Available samplesheets in data/validation/:"
    ls -lh "$PIPELINE_DIR/data/validation/"*samplesheet*.csv 2>/dev/null || echo "  (none found)"
    echo ""
    echo "Please create or specify the correct samplesheet path."
    echo "The samplesheet should have columns: sample,organism,fasta"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(tail -n +2 "$SAMPLESHEET" | wc -l)
echo "Samplesheet: $SAMPLESHEET"
echo "Total samples: $SAMPLE_COUNT"
echo ""

# Set output directory with job ID
OUTDIR="/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_${SLURM_JOB_ID}"
mkdir -p "$OUTDIR/logs"
echo "Output directory: $OUTDIR"
echo ""

# Run COMPASS v1.2.0 pipeline (1.2.0-candidate branch)
echo "=========================================="
echo "Starting COMPASS v1.2.0 pipeline..."
echo "=========================================="
echo ""
echo "v1.2.0 Features enabled:"
echo "  ✓ Prokka annotation"
echo "  ✓ Panaroo pangenome analysis"
echo "  ✓ IQ-TREE phylogenetic tree (ModelFinder + 1000 bootstrap)"
echo "  ✓ Prophage-AMR intersection analysis"
echo "  ✓ Enhanced HTML summary with new tabs"
echo ""

nextflow run main.nf \
    -profile beocat \
    --input "$SAMPLESHEET" \
    --outdir "${OUTDIR}/results" \
    --input_mode fasta \
    --max_cpus 32 \
    --max_memory 128.GB \
    --max_time 96.h \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --skip_prokka false \
    --skip_panaroo false \
    --skip_iqtree false \
    --iqtree_model MFP \
    --iqtree_bootstrap 1000 \
    --skip_prophage_amr false \
    -resume \
    -with-report "${OUTDIR}/results/nextflow_report.html" \
    -with-timeline "${OUTDIR}/results/nextflow_timeline.html" \
    -with-dag "${OUTDIR}/results/nextflow_dag.html"

EXIT_CODE=$?

# Check exit status
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "COMPASS v1.2.0 validation run completed successfully!"
    echo "=========================================="
    echo "End time: $(date)"
    echo "Results saved to: $OUTDIR"
    echo ""

    # Validation checks
    echo "Validation checks:"
    echo ""

    # Check core outputs
    AMR_COUNT=$(ls ${OUTDIR}/results/amrfinder/*_amr.tsv 2>/dev/null | wc -l)
    MLST_COUNT=$(ls ${OUTDIR}/results/mlst/*.tsv 2>/dev/null | wc -l)
    QUAST_COUNT=$(ls ${OUTDIR}/results/quast/*/report.tsv 2>/dev/null | wc -l)

    echo "  Core outputs:"
    echo "    - AMR files: $AMR_COUNT / $SAMPLE_COUNT"
    echo "    - MLST files: $MLST_COUNT / $SAMPLE_COUNT"
    echo "    - QUAST reports: $QUAST_COUNT / $SAMPLE_COUNT"
    echo ""

    # Check v1.2.0 specific outputs
    if [ -f "${OUTDIR}/results/panaroo/gene_presence_absence.csv" ]; then
        echo "  ✅ Panaroo pangenome analysis complete"
        CORE_GENES=$(tail -n +2 "${OUTDIR}/results/panaroo/gene_presence_absence.csv" | wc -l)
        echo "    - Total genes in pangenome: $CORE_GENES"
    else
        echo "  ⚠️  Panaroo results not found"
    fi

    if [ -f "${OUTDIR}/results/iqtree/core_gene_alignment.treefile" ]; then
        echo "  ✅ IQ-TREE phylogenetic tree complete"
        TREE_SIZE=$(wc -c < "${OUTDIR}/results/iqtree/core_gene_alignment.treefile")
        echo "    - Tree file size: $TREE_SIZE bytes"
    else
        echo "  ⚠️  IQ-TREE results not found"
    fi

    if [ -d "${OUTDIR}/results/prophage_amr" ]; then
        echo "  ✅ Prophage-AMR analysis complete"
        PROPHAGE_AMR_COUNT=$(ls ${OUTDIR}/results/prophage_amr/*_intersection.tsv 2>/dev/null | wc -l)
        echo "    - Samples analyzed: $PROPHAGE_AMR_COUNT"
    else
        echo "  ⚠️  Prophage-AMR results not found"
    fi

    if [ -f "${OUTDIR}/results/summary/compass_summary.html" ]; then
        echo "  ✅ Enhanced HTML summary generated"
        HTML_SIZE=$(du -h "${OUTDIR}/results/summary/compass_summary.html" | cut -f1)
        echo "    - HTML file size: $HTML_SIZE"
    else
        echo "  ⚠️  HTML summary not found"
    fi
    echo ""

    echo "Key outputs:"
    echo "  - AMR results: ${OUTDIR}/results/amrfinder/"
    echo "  - Prophage results: ${OUTDIR}/results/vibrant/"
    echo "  - Plasmid results: ${OUTDIR}/results/mobsuite/"
    echo "  - MLST results: ${OUTDIR}/results/mlst/"
    echo "  - Pangenome: ${OUTDIR}/results/panaroo/"
    echo "  - Phylogenetic tree: ${OUTDIR}/results/iqtree/"
    echo "  - Prophage-AMR: ${OUTDIR}/results/prophage_amr/"
    echo "  - MultiQC report: ${OUTDIR}/results/multiqc/multiqc_report.html"
    echo "  - HTML summary: ${OUTDIR}/results/summary/compass_summary.html"
    echo ""
    echo "Next steps:"
    echo "  1. Review HTML summary report with new tabs"
    echo "  2. Verify phylogenetic tree accuracy"
    echo "  3. Check pangenome core/accessory gene counts"
    echo "  4. Validate prophage-AMR intersection results"
    echo "  5. If validation passes, merge 1.2.0-candidate → main and tag v1.2.0"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "COMPASS v1.2.0 validation run FAILED"
    echo "=========================================="
    echo "End time: $(date)"
    echo "Exit code: $EXIT_CODE"
    echo "Check error log: ${OUTDIR}/logs/compass_validation_${SLURM_JOB_ID}.err"
    echo ""
    exit 1
fi
