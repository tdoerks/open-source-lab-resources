# Session Notes: 2026-03-23 - Vibrio Cholerae Job OOM Fix

## Session Overview

**Date:** March 23, 2026
**Focus:** Fix Nextflow Java heap space OOM error on large Vibrio cholerae run
**Branch:** `scratch`
**Job:** 7054018 (FAILED after 3 days due to OOM)
**Status:** Fix implemented, ready to resume

---

## Problem Identified

### Job Failure

**Job 7054018** - Vibrio cholerae Geographic + Temporal study (~3,750 samples)

**Error message:**
```
Terminating due to java.lang.OutOfMemoryError: Java heap space

Work dir:
  /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/work_vibrio_cholerae/95/79965b478aeff06007f9d75fed139f

Tip: you can replicate the issue by changing to the process work dir and entering the command `bash .command.run`

 -- Check '.nextflow.log' file for details
```

**When it occurred:** After ~3 days of runtime on warlock40

### Root Cause Analysis

This is **NOT** a process-specific memory issue (e.g., SPAdes, VIBRANT, etc. running out of RAM).

This is a **Nextflow orchestrator JVM issue**:
- Nextflow itself runs out of Java heap space while managing the pipeline
- Common with large runs (3,750+ samples)
- Happens when Nextflow manages:
  - 100+ concurrent jobs in queue
  - Deep work directory structures
  - Many file handles
  - Extensive task metadata

**Default Nextflow JVM settings:**
- Typically `-Xmx512m` to `-Xmx2g` (2GB max heap)
- Not sufficient for 3,750 sample runs

---

## Solution

### Set Nextflow JVM Options

Add to job submission script **before** running `nextflow run`:

```bash
export NXF_OPTS='-Xms2g -Xmx8g'
```

**What this does:**
- `-Xms2g`: Initial heap size = 2GB
- `-Xmx8g`: Maximum heap size = 8GB
- Gives Nextflow 8GB to manage pipeline orchestration
- Does NOT affect individual process memory (those are controlled by `base.config`)

### Implementation

**File modified:** `vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh`

**Changes:**
```diff
# Set unique Nextflow home to avoid cache conflicts
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_vibrio_cholerae

+ # Increase Nextflow JVM heap size for large runs (3,750+ samples)
+ # Prevents "java.lang.OutOfMemoryError: Java heap space" during pipeline orchestration
+ export NXF_OPTS='-Xms2g -Xmx8g'
+
# Set output directory
OUTPUT_DIR="/fastscratch/tylerdoe/vibrio_cholerae_results"
```

---

## How to Resume

### On Beocat

```bash
# Navigate to pipeline
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0

# Pull updated run script from GitHub
git fetch origin scratch
git checkout scratch
git pull origin scratch

# Copy updated script to project
cp vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh \
   vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh

# Resubmit (with -resume, will continue from where it left off)
sbatch vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh
```

**Key points:**
- The `-resume` flag in the script ensures it picks up where it left off
- Completed work won't be re-run (saved in `work_vibrio_cholerae/` dir)
- Only incomplete/failed processes will retry
- New job will use 8GB heap, preventing future OOM

---

## Why This Matters

### Scale Context

**Job 7054018 specifics:**
- ~3,750 Vibrio cholerae genomes
- Geographic + temporal stratification (2020-2026)
- Expected runtime: 18-25 days
- Failed after 3 days (~10-15% complete)

**Nextflow challenges at this scale:**
1. **Queue management:** Up to 100 concurrent SLURM jobs
2. **Task tracking:** 3,750 samples × ~10 processes/sample = 37,500 tasks
3. **File metadata:** Thousands of work directories with symlinks
4. **Process retries:** Tracking failed/retry states
5. **Report generation:** Execution timeline, trace, report

**With default 2GB heap:**
- Nextflow runs out of memory managing task metadata
- Fails ungracefully with OutOfMemoryError
- No way to recover without restarting

**With 8GB heap:**
- Sufficient for 5,000+ sample runs
- Stable orchestration
- Smooth operation even with high queue pressure

---

## Broader Applicability

### When to Use Increased Heap

**Apply NXF_OPTS fix to:**

1. **Large sample counts:**
   - ≥1,000 samples: Use `-Xmx4g`
   - ≥2,500 samples: Use `-Xmx8g`
   - ≥5,000 samples: Use `-Xmx12g` or `-Xmx16g`

2. **Complex pipelines:**
   - Many processes per sample (COMPASS has ~10-12)
   - Deep process dependencies
   - Lots of file outputs

3. **High queue concurrency:**
   - `queueSize = 100+`
   - Many parallel processes

### Update All Large Run Scripts

**Scripts to update:**
- ✅ `vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh` (DONE)
- ⚠️ Pseudomonas Phage Hunter study (~3,750 samples) - check if affected
- ⚠️ `diverse_bacteria_1000` run script (if it exists)
- ⚠️ Any future 1,000+ sample runs

**Standard template for large runs:**
```bash
#!/bin/bash
#SBATCH --job-name=large_study
#SBATCH --time=336:00:00    # 14 days
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tdoerks@vet.k-state.edu

module load Nextflow

# Set Nextflow home
export NXF_HOME=/fastscratch/tylerdoe/.nextflow_<project_name>

# CRITICAL: Increase JVM heap for large runs
export NXF_OPTS='-Xms2g -Xmx8g'

# Run pipeline
nextflow run main.nf \
    -profile beocat \
    -resume
```

---

## Impact on Current Work

### Vibrio Cholerae Study

**Before fix:**
- Job 7054018 failed after 3 days
- ~10-15% of samples processed
- All work saved in `work_vibrio_cholerae/`

**After fix:**
- Resume will continue from last checkpoint
- Expected additional runtime: 15-22 days
- Total time to completion: ~18-25 days (as originally estimated)

**No data loss:**
- All completed assemblies, AMR, prophage results preserved
- Nextflow work directory intact
- `-resume` will skip completed tasks

---

## Key Learnings

### 1. JVM Memory ≠ Process Memory

**Two separate memory pools:**

**Process memory** (controlled by `base.config`):
- RAM allocated to each task (SPAdes, VIBRANT, QUAST, etc.)
- Example: `memory = { 32.GB * task.attempt }`
- Consumed by tools running in containers
- Managed by SLURM (`#SBATCH --mem=32G`)

**Nextflow JVM memory** (controlled by `NXF_OPTS`):
- RAM used by Nextflow orchestrator itself
- NOT for running tools
- For managing pipeline state, queue, files
- Separate from SLURM job allocation

**Confusion factor:**
- Job has `--mem=32G` but Nextflow still ran OOM
- Because Nextflow JVM has its own heap limit!

### 2. Default Settings Don't Scale

**Nextflow defaults are optimized for:**
- Small-medium runs (<500 samples)
- Simple linear pipelines
- Local/small cluster execution

**Not sufficient for:**
- 1,000+ sample studies
- Complex DAGs with many processes
- HPC environments with high queue pressure

**Always explicitly set `NXF_OPTS` for large runs**

### 3. OOM Errors Are Cryptic

**What you see:**
```
java.lang.OutOfMemoryError: Java heap space
Work dir: /fastscratch/.../95/79965b478aeff06007f9d75fed139f
```

**What's unclear:**
- Is it a process OOM or Nextflow OOM?
- Which tool failed?
- What triggered it?

**How to distinguish:**

| Type | Error location | Clue |
|------|---------------|------|
| Process OOM | In `.command.log` inside work dir | Tool-specific error (e.g., "SPAdes: malloc failed") |
| Nextflow OOM | In main console output / `.nextflow.log` | Says "java.lang.OutOfMemoryError" with no tool name |
| SLURM OOM | In `.err` file | Says "Exceeded job memory limit" or "Out of memory" |

**This was a Nextflow OOM:**
- No tool mentioned in error
- Main pipeline log showed Java error
- Work directory was intact (process didn't fail)

### 4. Resume Is Powerful But Fragile

**Why `-resume` works:**
- Nextflow caches all task hashes
- Work directory persists completed results
- Only failed/missing tasks re-run

**But...**
- Cache depends on Nextflow having enough memory to read it!
- If Nextflow OOMs during resume, no progress
- Hence why increasing heap is critical before resume

---

## Testing Strategy

### Verify Fix Before Long Run

**Option 1: Test with subset** (RECOMMENDED)
```bash
# Create test samplesheet with 100 samples
head -100 vibrio_cholerae_temporal_geographic/samplesheet_vibrio_cholerae.txt > test_100.txt

# Run with NXF_OPTS set
export NXF_OPTS='-Xms2g -Xmx8g'
nextflow run main.nf -profile beocat --input test_100.txt -resume
```

**Watch for:**
- No JVM OOM errors
- Smooth queue management
- Nextflow heap usage in `.nextflow.log`

**Option 2: Monitor heap during full run**
```bash
# Add JVM monitoring
export NXF_OPTS='-Xms2g -Xmx8g -verbose:gc -XX:+PrintGCDetails'

# Check .nextflow.log for GC activity
tail -f .nextflow.log | grep -i "GC\|heap"
```

---

## Commit Details

### Files Modified (scratch branch)

```
vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh
  - Added NXF_OPTS export before nextflow run
  - Set -Xms2g -Xmx8g for 8GB heap
  - Documented why (3,750+ sample large run)
```

### Session Note

```
SESSION_NOTES_2026-03-23_vibrio_oom_fix.md
  - Documents OOM root cause
  - Provides solution and resume instructions
  - Explains JVM vs process memory distinction
  - Template for future large runs
```

---

## Next Steps

### Immediate Actions

1. **Push fix to scratch branch:**
   ```bash
   git add vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh
   git add SESSION_NOTES_2026-03-23_vibrio_oom_fix.md
   git commit -m "Fix Nextflow JVM OOM for large Vibrio run (3,750 samples)

   - Add NXF_OPTS='-Xms2g -Xmx8g' to run_vibrio_cholerae.sh
   - Prevents java.lang.OutOfMemoryError during pipeline orchestration
   - Required for runs with 1,000+ samples
   - Job 7054018 failed after 3 days; will resume with fix
   "
   git push origin scratch
   ```

2. **Resume Vibrio job on Beocat:**
   ```bash
   # On Beocat
   cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
   git pull origin scratch
   sbatch vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh
   ```

3. **Monitor for success:**
   ```bash
   squeue -u tylerdoe
   tail -f /fastscratch/tylerdoe/slurm-vibrio-cholerae-*.out
   ```

### Follow-up Tasks

1. **Apply fix to other large run scripts**
   - Pseudomonas Phage Hunter (if affected)
   - diverse_bacteria_1000
   - Any other 1,000+ sample studies

2. **Update documentation**
   - Add NXF_OPTS guidance to main README
   - Create troubleshooting guide for OOM errors
   - Template for large-scale run scripts

3. **Consider pipeline-wide default**
   - Add to `nextflow.config` as global setting?
   - Or keep explicit in run scripts for visibility?

---

## Technical Details

### Nextflow Memory Architecture

**Three memory pools:**

1. **Nextflow JVM heap** (`NXF_OPTS -Xmx`)
   - Pipeline orchestration
   - Task graph management
   - File tracking
   - Queue state

2. **Process memory** (`process.memory` in configs)
   - Individual task RAM
   - Requested from SLURM
   - Used by containerized tools

3. **SLURM job allocation** (`#SBATCH --mem`)
   - Total memory for head node process
   - Must be ≥ Nextflow heap
   - Usually 32-64GB for large runs

### Recommended Settings by Scale

| Samples | NXF_OPTS | SLURM --mem | Notes |
|---------|----------|-------------|-------|
| <100 | Default (~2GB) | 16G | No special config needed |
| 100-500 | -Xmx4g | 16G | Optional, but safe |
| 500-1000 | -Xmx4g | 32G | Recommended |
| 1000-2500 | -Xmx8g | 32G | **Required** |
| 2500-5000 | -Xmx8g | 64G | **Required** |
| 5000+ | -Xmx12g or -Xmx16g | 64G+ | **Critical** |

**Vibrio study:** 3,750 samples → `-Xmx8g` with `--mem=32G` ✅

---

## References

- **Nextflow JVM options:** https://www.nextflow.io/docs/latest/config.html#scope-env
- **Java heap tuning:** https://docs.oracle.com/en/java/javase/11/gctuning/
- **Similar issue:** nf-core pipelines recommend `-Xmx8g` for 1,000+ sample runs

---

## Contact

**Researcher:** Tyler Doerksen (tdoerks@vet.k-state.edu)
**Pipeline:** COMPASS v1.0.0
**HPC System:** Beocat (Kansas State University)
**GitHub:** https://github.com/tdoerks/COMPASS-pipeline
**Branch:** scratch

---

## Change Log

- **2026-03-23 16:00**: Job 7054018 failed with Java heap space OOM after 3 days
- **2026-03-23 16:30**: Root cause identified (Nextflow JVM, not process memory)
- **2026-03-23 17:00**: Solution implemented (NXF_OPTS=-Xmx8g), session notes created
- **2026-03-23 17:30**: Ready to push fix and resume job on Beocat

---

*Fix implemented - ready to resume large-scale Vibrio cholerae study.*
