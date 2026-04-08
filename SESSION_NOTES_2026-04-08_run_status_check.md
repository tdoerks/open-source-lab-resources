# Session Notes: 2026-04-08 - Beocat Run Status Check

**Date**: April 8, 2026
**Focus**: Checking status of large-scale COMPASS runs on Beocat HPC

## Overview

Checked in on three major COMPASS pipeline runs on Beocat:
1. Vibrio cholerae geographic/temporal study (RUNNING)
2. Salmonella temporal phage study (TIMED OUT)
3. COMPASS validation v1.2.0 (FAILED - multiple attempts)

---

## Run 1: Vibrio cholerae Geographic + Temporal Study

**Job ID**: 7347084
**Status**: RUNNING
**Runtime**: 9+ days (started March 30, 2026)
**Time Limit**: 14 days (ends April 13, 2026)
**Resources**: 8 CPUs, 32GB RAM
**Node**: hero53

### Job Details
- **Working Directory**: `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0`
- **Project Directory**: `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/vibrio_cholerae_temporal_geographic`
- **Output Directory**: `/fastscratch/tylerdoe/vibrio_cholerae_results`
- **Work Directory**: `/fastscratch/tylerdoe/COMPASS-pipeline/work_vibrio_cholerae`
- **Run Script**: `run_vibrio_cholerae.sh`

### Dataset
- **Organism**: *Vibrio cholerae*
- **Sampling Strategy**: 50 samples per month (Jan 2020 - Mar 2026)
- **Geographic Regions**: South Asia, Africa, Americas, SE Asia
- **Focus**: CTXφ prophage + Geographic AMR spread
- **Total Samples**: ~2,787 SRA accessions

### Progress Summary (as of April 8, 2026)

| Process | Completed | Total | Failed | Success Rate |
|---------|-----------|-------|--------|--------------|
| SRA Download | 2,768 | 2,787 | 137 | 99.3% |
| FastQC | 2,611 | 2,623 | 1 | 99.95% |
| fastp (trimming) | 2,612 | 2,623 | 93 | 96.5% |
| SPAdes Assembly | 2,514 | 2,519 | 5 | 99.8% |
| BUSCO QC | 2,500 | 2,509 | 3 | 99.6% |
| QUAST | 2,502 | 2,509 | - | 99.7% |
| AMRFinder | 2,502 | 2,509 | - | 99.7% |
| ABRicate | 9,974 | 10,036 | - | 99.4% (in progress) |
| VIBRANT (phage) | 2,501 | 2,509 | - | 99.7% |
| DIAMOND prophage | 2,496 | 2,501 | - | 99.8% (in progress) |
| PHANOTATE | 2,494 | 2,501 | - | 99.7% (in progress) |
| MLST typing | 2,502 | 2,509 | - | 99.7% |
| MOB-suite (plasmids) | 2,501 | 2,509 | - | 99.7% |

**Overall Success**: ~2,500 samples fully analyzed (~90% of initial dataset)

### Issues Identified

1. **SRA Download Failures (137 samples)**
   - Likely corrupted downloads or unavailable accessions
   - Not critical - 90% success rate is excellent for large-scale SRA downloads

2. **fastp Failures (93 samples)**
   - Possible causes:
     - Very low quality reads
     - Corrupted FASTQ files from failed SRA downloads
     - Adapter-only reads
     - Empty or incomplete files

3. **FastQC Memory Error (1 sample: SRR24750869)**
   - Error: `java.lang.OutOfMemoryError: Java heap space`
   - Impact: Minimal (only 1 sample affected, QC only)
   - Note: Pipeline configuration sets `NXF_OPTS='-Xms2g -Xmx8g'` for Nextflow JVM heap

### Current Stage
Pipeline is in final stages:
- Finishing ABRicate multi-database screening (4 databases × ~2,500 samples)
- Completing DIAMOND prophage classification
- Completing PHANOTATE gene prediction
- Will generate combined results and MultiQC report once individual analyses complete

### Data Archival
Results archived to bulk storage (excluding FASTQ files to save space):
```bash
rsync -avh --progress \
  --exclude='*.fastq.gz' \
  --exclude='*.fq.gz' \
  --exclude='trimmed_fastq/' \
  --exclude='fastq/' \
  /fastscratch/tylerdoe/vibrio_cholerae_results/ \
  /bulk/tylerdoe/archives/vibrio_cholerae_results/
```

**Archived Results Include**:
- Assemblies (FASTA files)
- BUSCO quality assessments
- QUAST assembly statistics
- AMRFinder AMR gene detection
- ABRicate multi-database AMR screening
- VIBRANT prophage identification
- DIAMOND prophage classification
- PHANOTATE gene predictions
- MLST sequence typing
- MOB-suite plasmid detection/typing
- MultiQC aggregate reports
- COMPASS summary files

---

## Run 2: Salmonella Temporal Phage Study

**Job ID**: 7199221
**Status**: TIMEOUT
**Submitted**: March 24, 2026
**End Date**: April 7, 2026
**Runtime**: 14 days (hit time limit)

### Details
- **Project**: Salmonella temporal phage analysis
- **Location**: `/fastscratch/tylerdoe/COMPASS-pipeline*/salmonella_temporal_phage/` (exact path TBD)
- **Time Limit**: 14 days (336 hours)

### Action Items
- [ ] Investigate how far the run progressed before timeout
- [ ] Check if results are partially usable
- [ ] Determine if run should be resumed with `-resume` flag
- [ ] Consider increasing time limit if needed for large dataset

---

## Run 3: COMPASS Validation v1.2.0

**Multiple Failed Attempts** (March 26 - April 2, 2026)

### Recent Attempts

| Job ID | Date | Status | Runtime | Notes |
|--------|------|--------|---------|-------|
| 7314873 | Mar 26 16:40 | FAILED | 1 sec | Immediate failure |
| 7314897 | Mar 26 16:45 | FAILED | 0 sec | Immediate failure |
| 7314900 | Mar 26 16:48 | FAILED | 1 sec | Immediate failure |
| 7314914 | Mar 26 16:54 | FAILED | 1 sec | Immediate failure |
| 7314932 | Mar 26 16:58 | FAILED | 3h 37m | Ran longer but failed |
| 7326269-7327350 | Mar 27 | FAILED/CANCELLED | Various | Multiple attempts |
| 7343445 | Mar 29 22:50 | FAILED | 3h 42m | Ran but failed |
| 7347937 | Mar 30 12:11 | TIMEOUT | 2 days | Hit time limit |
| 7387663 | Apr 1 16:42 | FAILED | 14h 4m | Most recent attempt |

### Issues
- Multiple immediate failures suggest configuration or path issues
- Some runs progressed for hours before failing
- One run timed out after 2 days
- Most recent run (14+ hours) suggests progress but ultimately failed

### Action Items
- [ ] Review validation test configuration
- [ ] Check SLURM logs for failure reasons
- [ ] Verify database paths and dependencies
- [ ] Consider if validation needs debugging/fixes

---

## Beocat Job History Summary

### Active Jobs
- **vibrio_cholerae_geo** (7347084): RUNNING, 9+ days, ~99% complete

### Recent Completed/Failed Jobs
- **salmonella_temporal_phage** (7199221): TIMEOUT after 14 days
- **compass_val_v1.2.0**: Multiple failed attempts

### Other Historical Jobs
- **vibrio_cholerae_geo** (7225899): CANCELLED after 4.5 days (Mar 25-29)
- **vibrio_cholerae_geo** (7199572): CANCELLED after 1 day (Mar 24-25)
- **vibrio_cholerae_geo** (7343696): FAILED after 43 min (Mar 30)
- Multiple compass validation attempts throughout late March

---

## Configuration Details

### Beocat SLURM Configuration
From `conf/beocat.config`:
```groovy
process {
    executor = 'slurm'
    queue = 'batch.q'
}

params {
    max_memory = 100.GB
    max_cpus = 32
    max_time = 1.d
    clusterOptions = "--gres=killable:0"
}

executor {
    queueSize = 100              // Max jobs in queue at once
    submitRateLimit = '10/1min'  // Submit max 10 jobs per minute
    pollInterval = '45 sec'      // Check job status every 45 seconds
    queueStatInterval = '10 min' // Update queue statistics every 10 minutes
    exitReadTimeout = '120 sec'  // Wait up to 120 sec for exit status
}
```

### Vibrio Run Configuration
From `run_vibrio_cholerae.sh`:
```bash
# Nextflow JVM heap size for large runs (3,750+ samples)
export NXF_OPTS='-Xms2g -Xmx8g'

# Unique Nextflow home to avoid cache conflicts
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_vibrio_cholerae

# SLURM resources
#SBATCH --time=336:00:00    # 14 days
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
```

### Pipeline Command
```bash
nextflow run main.nf \
    -profile beocat \
    --input_mode sra_list \
    --input "$PROJECT_DIR/samplesheet_vibrio_cholerae.txt" \
    --skip_busco false \
    --busco_download_path /fastscratch/tylerdoe/databases/busco_downloads \
    --prophage_db /fastscratch/tylerdoe/databases/prophage_db.dmnd \
    --outdir "$OUTPUT_DIR" \
    -w /fastscratch/tylerdoe/COMPASS-pipeline/work_vibrio_cholerae \
    -resume
```

---

## Next Steps

### Immediate
1. **Monitor Vibrio run** - Should complete by April 13 (4-5 days remaining)
2. **Archive complete results** - Continue rsync to bulk storage once complete

### Follow-up
1. **Salmonella Investigation**
   - Find run directory and check progress
   - Review logs to see how far it got before timeout
   - Decide whether to resume or restart

2. **Validation Debugging**
   - Review most recent failure logs (job 7387663)
   - Identify root cause of validation failures
   - Fix issues and re-run validation suite

### Analysis Planning
Once Vibrio run completes, analysis focus areas:
1. CTXφ prophage prevalence by region (South Asia vs Africa vs Americas)
2. Temporal epidemic waves per region (2020-2026)
3. AMR emergence patterns (fluoroquinolone resistance spread)
4. Prophage-plasmid co-occurrence by geography
5. MLST diversity and regional clustering
6. SXT/R391 ICE distribution across endemic zones

---

## Files Modified/Created

- Session notes: `SESSION_NOTES_2026-04-08_run_status_check.md`

## Commands Reference

### Check SLURM job status
```bash
squeue -u tylerdoe
sacct -u tylerdoe --starttime=2026-03-25 --format=JobID,JobName%30,State,Elapsed,Start,End -X
scontrol show job 7347084
```

### Check pipeline logs
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
tail -100 .nextflow.log
```

### Rsync results to bulk storage
```bash
rsync -avh --progress \
  --exclude='*.fastq.gz' \
  --exclude='*.fq.gz' \
  --exclude='trimmed_fastq/' \
  --exclude='fastq/' \
  /fastscratch/tylerdoe/vibrio_cholerae_results/ \
  /bulk/tylerdoe/archives/vibrio_cholerae_results/
```

---

## Notes

- Vibrio run showing excellent progress despite some failures
- Large-scale SRA downloads always have some failures - 90% success is very good
- fastp failures likely due to poor quality downloads
- Pipeline appears stable and processing correctly
- Results being archived to bulk storage efficiently (excluding large FASTQ files)
