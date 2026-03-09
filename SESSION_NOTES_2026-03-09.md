# Session Notes - 2026-03-09

## Summary
Successfully launched diverse bacteria 1000 project on COMPASS 1.0.0 after fixing download script to use HTTP API instead of EDirect.

---

## Part 1: Fixed Download Script for Diverse Bacteria Project

### Issue Identified
The `download_diverse_bacteria.py` script originally used EDirect command-line tools (`esearch`, `efetch`) which were not available on Beocat.

### Research Findings
Investigated how the E. coli monthly 100 project handled downloads:
- **Found**: `fetch_ecoli_monthly_v2.py` uses Python `requests` library with NCBI E-utilities HTTP API
- **Key insight**: Only downloads SRR accession lists (tiny text files), NOT sequencing data
- **Benefit**: Can run on any machine with Python + internet (including Beocat)
- **Actual data download**: Handled by COMPASS pipeline using `fasterq-dump` on Beocat

### Solution Implemented

**First attempt - HTTP API conversion:**
1. Rewrote `download_diverse_bacteria.py` to use `requests` library
2. Replaced subprocess calls to EDirect with direct HTTP API calls
3. Used same endpoints as E. coli monthly 100 project
4. Committed and pushed (commit 9eb01e5)

**Initial run failed:**
- Only retrieved 51 out of 1,000 target samples
- 18 out of 20 organisms returned 0 samples
- Problem: Size filtering logic was too aggressive

**Root cause:**
- NCBI XML responses don't reliably include file size information
- Size filter was rejecting almost all valid samples
- `total_bases` attribute often missing from XML

**Second fix - Remove size filtering:**
1. Removed size filtering logic entirely
2. Accept all valid WGS Illumina GENOMIC samples
3. Random sampling from available pool (50 per organism)
4. Matches E. coli monthly 100 behavior (also no size filtering)
5. Committed and pushed (commit 5d6367c)

**Second run succeeded:**
- ✅ All 20 organisms: 50 samples each
- ✅ Total: 1,000 SRR accessions
- ✅ Runtime: ~15 minutes with rate limiting

### Files Modified

**On scratch branch:**
- `diverse_bacteria_1000/scripts/download_diverse_bacteria.py` - Converted to HTTP API, removed size filtering
- `diverse_bacteria_1000/README.md` - Updated instructions (no EDirect needed)
- `SESSION_NOTES_2026-03-07.md` - Added research findings about HTTP API approach

### Download Results

**Location**: `/fastscratch/tylerdoe/COMPASS-pipeline/diverse_bacteria_1000/data/`

**Files created:**
```
data/
├── srr_accessions_by_organism/
│   ├── Acinetobacter_baumannii_srr_list.txt (50 SRRs)
│   ├── Arcobacter_butzleri_srr_list.txt (50 SRRs)
│   ├── Bacillus_cereus_srr_list.txt (50 SRRs)
│   ├── Campylobacter_coli_srr_list.txt (50 SRRs)
│   ├── Citrobacter_freundii_srr_list.txt (50 SRRs)
│   ├── Clostridium_perfringens_srr_list.txt (50 SRRs)
│   ├── Cronobacter_sakazakii_srr_list.txt (50 SRRs)
│   ├── Enterobacter_cloacae_srr_list.txt (50 SRRs)
│   ├── Enterococcus_faecium_srr_list.txt (50 SRRs)
│   ├── Helicobacter_pylori_srr_list.txt (50 SRRs)
│   ├── Klebsiella_pneumoniae_srr_list.txt (50 SRRs)
│   ├── Listeria_monocytogenes_srr_list.txt (50 SRRs)
│   ├── Proteus_mirabilis_srr_list.txt (50 SRRs)
│   ├── Pseudomonas_aeruginosa_srr_list.txt (50 SRRs)
│   ├── Serratia_marcescens_srr_list.txt (50 SRRs)
│   ├── Shigella_sonnei_srr_list.txt (50 SRRs)
│   ├── Staphylococcus_aureus_srr_list.txt (50 SRRs)
│   ├── Vibrio_cholerae_srr_list.txt (50 SRRs)
│   ├── Vibrio_parahaemolyticus_srr_list.txt (50 SRRs)
│   └── Yersinia_enterocolitica_srr_list.txt (50 SRRs)
└── combined_srr_list.txt (1,000 SRRs total)
```

**Samplesheet generated:**
- `samplesheet_diverse_1000.txt` - 1,000 lines (COMPASS input format)

---

## Part 2: Running Diverse Bacteria 1000 on COMPASS 1.0.0

### Strategy: Keep 1.0.0 Clean

**Decision**: Keep 1.0.0 tag pristine for production runs, all development/notes on scratch branch

**Approach used:**
1. Created separate clean 1.0.0 directory: `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/`
2. Cloned from GitHub at 1.0.0 tag with `--depth 1` (shallow clone)
3. Copied `diverse_bacteria_1000/` folder from scratch branch
4. Submitted job from the 1.0.0 directory

### Execution Steps

```bash
# On Beocat (as tylerdoe)
cd /fastscratch/tylerdoe/

# Clone clean 1.0.0 version
git clone --branch 1.0.0 --depth 1 https://github.com/tdoerks/COMPASS-pipeline.git COMPASS-pipeline-1.0.0

# Copy project folder with downloaded data
cp -r COMPASS-pipeline/diverse_bacteria_1000 COMPASS-pipeline-1.0.0/

# Submit job
cd COMPASS-pipeline-1.0.0/diverse_bacteria_1000
sbatch run_diverse_bacteria_1000.sh
```

**Result**: Job 6818330 submitted successfully

### Job Details

**SLURM Job:**
- Job ID: 6818330
- Job name: diverse_bacteria_1000
- SLURM output: `/fastscratch/tylerdoe/slurm-diverse-bacteria-1000-6818330.out`
- SLURM error: `/fastscratch/tylerdoe/slurm-diverse-bacteria-1000-6818330.err`
- Time limit: 168 hours (7 days)
- Resources: 8 CPUs, 32GB RAM

**Pipeline Configuration:**
- COMPASS version: 1.0.0 (clean tag)
- Input mode: `sra_list`
- Input file: `samplesheet_diverse_1000.txt` (1,000 samples)
- Output directory: `/fastscratch/tylerdoe/diverse_bacteria_1000_results/`
- Work directory: `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/work_diverse_bacteria_1000`
- BUSCO enabled: Yes
- All analysis modules enabled: MLST, AMRFinder, ABRicate, MOB-suite, VIBRANT, etc.

**Expected Results:**
- Runtime: 5-7 days for 1,000 samples
- Storage: ~500GB in results directory
- Outputs: assemblies, MLST, AMR, plasmids, prophages, BUSCO QC, MultiQC report

### Pipeline Status (Initial Check)

**Active processes observed:**
- ✅ CHECK_DATABASES - cached from previous runs
- ✅ DOWNLOAD_AMRFINDER_DB - cached
- ✅ DOWNLOAD_PROPHAGE_DB - cached
- 🔄 DOWNLOAD_SRA - Starting to download FASTQ files (0 of 1,000 started)

**Warnings seen (expected):**
- Process name warnings for CHECKV, READ_QC, etc. (naming differences between v1.0.0 and current dev)
- These are configuration warnings, not errors
- Pipeline is functioning correctly

---

## Directory Structure

### On Beocat

**Production (1.0.0 - clean):**
```
/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/
├── main.nf                    # COMPASS 1.0.0 pipeline
├── nextflow.config            # 1.0.0 configuration
├── diverse_bacteria_1000/     # Project folder (copied from scratch)
│   ├── data/                  # Downloaded SRR lists
│   ├── scripts/               # Download & samplesheet scripts
│   ├── samplesheet_diverse_1000.txt
│   └── run_diverse_bacteria_1000.sh
└── work_diverse_bacteria_1000/  # Nextflow work directory
```

**Development (scratch branch - notes & iterations):**
```
/fastscratch/tylerdoe/COMPASS-pipeline/
├── diverse_bacteria_1000/     # Original project development
├── data/validation/           # Validation framework
├── SESSION_NOTES_*.md         # All session documentation
└── (on scratch branch)
```

---

## Git Status

**Scratch branch:**
- Commit 5d6367c: "Fix size filtering issue in diverse bacteria download script"
- Commit 9eb01e5: "Update diverse_bacteria_1000 download script to use HTTP API"
- Pushed to GitHub: ✅

**1.0.0 tag:**
- Remains pristine on GitHub
- Clean clone on Beocat at `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/`
- No modifications to 1.0.0 codebase

**Uncommitted changes:**
- `data/validation/run_compass_validation_v1.0.0.sh` has local edits on Beocat
- Kept on scratch branch, not committed
- Can be stashed or committed later if needed

---

## Current Running Jobs

### On Beocat

**1. Diverse Bacteria 1000 (NEW - This session)**
- Job ID: 6818330
- Pipeline: COMPASS 1.0.0
- Status: Running (just started)
- Started: 2026-03-09 ~02:30 AM
- Samples: 1,000 genomes across 20 bacterial pathogens
- Expected completion: 2026-03-14 to 2026-03-16 (5-7 days)
- Log: `/fastscratch/tylerdoe/slurm-diverse-bacteria-1000-6818330.out`

**Monitor commands:**
```bash
# Check job status
squeue -u tylerdoe

# Watch log
tail -f /fastscratch/tylerdoe/slurm-diverse-bacteria-1000-6818330.out

# Check progress
ls -lh /fastscratch/tylerdoe/diverse_bacteria_1000_results/

# Count completed assemblies
find /fastscratch/tylerdoe/diverse_bacteria_1000_results/assemblies/ -name "*.fasta" | wc -l

# Check job details
sacct -j 6818330 --format=JobID,JobName,State,Start,Elapsed,TimeLimit
```

---

## Lessons Learned

### 1. NCBI SRA Download Best Practices

**Use HTTP API, not EDirect:**
- Python `requests` library is more portable than EDirect CLI tools
- Works on any machine with Python + internet (including Beocat)
- No module dependencies to worry about

**Don't rely on size filtering from NCBI:**
- XML responses often lack file size information
- Better to filter by type (WGS, Illumina, GENOMIC) and let random sampling handle diversity
- Can filter by size later if needed using actual downloaded file sizes

**Only download accession lists:**
- Small text files (~few KB total)
- No local machine storage needed
- COMPASS downloads actual FASTQ files during pipeline execution

### 2. Git Branch Management

**Keep production tags clean:**
- 1.0.0 tag stays pristine on GitHub
- Clone separate directories for production runs on Beocat
- Use shallow clones (`--depth 1`) to save space

**Use scratch for development:**
- All notes, experiments, and iterations on scratch branch
- Easy to copy working folders to production versions
- Clear separation between stable releases and development work

### 3. SLURM Job Organization

**Separate directories for major projects:**
- `COMPASS-pipeline/` - development on scratch branch
- `COMPASS-pipeline-1.0.0/` - production runs with v1.0.0
- Each has its own work directory (no conflicts with `-resume`)

**Work directory naming:**
- Use descriptive names: `work_diverse_bacteria_1000`, `work_ecoli_monthly_100`
- Easier to track storage usage
- Can clean specific projects without affecting others

---

## Action Items

### Immediate
- [x] Download SRR accessions for diverse bacteria 1000
- [x] Generate samplesheet
- [x] Submit diverse bacteria job on COMPASS 1.0.0
- [ ] Monitor job progress over next 5-7 days

### Short-term (While Job Runs)
- [ ] Review v1.0.0 validation results (from previous session)
- [ ] Compare validation v1.0.0 vs v1.3-dev
- [ ] Document any differences in tool outputs
- [ ] Archive validation results to `/bulk/tylerdoe/archives/`

### After Job Completes
- [ ] Review MultiQC report for diverse bacteria 1000
- [ ] Check BUSCO completeness by organism
- [ ] Analyze AMR patterns across 20 organisms
- [ ] Compare plasmid diversity (MOB-suite results)
- [ ] Assess prophage distribution (VIBRANT results)
- [ ] Evaluate MLST diversity per organism
- [ ] Archive results (~500GB) to `/bulk/tylerdoe/archives/`

---

## Reference Commands

### Check job progress
```bash
# SLURM queue
squeue -u tylerdoe

# Job accounting
sacct -j 6818330 --format=JobID,JobName,State,Start,Elapsed,TimeLimit

# Watch log
tail -f /fastscratch/tylerdoe/slurm-diverse-bacteria-1000-6818330.out

# Check output directory
du -sh /fastscratch/tylerdoe/diverse_bacteria_1000_results/
ls -lh /fastscratch/tylerdoe/diverse_bacteria_1000_results/
```

### Monitor pipeline progress
```bash
# Count completed steps
find /fastscratch/tylerdoe/diverse_bacteria_1000_results/ -type f | wc -l

# Check assemblies
ls /fastscratch/tylerdoe/diverse_bacteria_1000_results/assemblies/*.fasta | wc -l

# Check MLST results
ls /fastscratch/tylerdoe/diverse_bacteria_1000_results/mlst/*.tsv | wc -l

# Check AMR results
ls /fastscratch/tylerdoe/diverse_bacteria_1000_results/amrfinder/ | wc -l

# Check work directory size
du -sh /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/work_diverse_bacteria_1000
```

### If job needs to be restarted
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/diverse_bacteria_1000

# Cancel if needed
scancel 6818330

# Resubmit (will resume from where it left off)
sbatch run_diverse_bacteria_1000.sh
```

---

## Technical Notes

### HTTP API vs EDirect Comparison

| Feature | EDirect (CLI) | HTTP API (requests) |
|---------|---------------|---------------------|
| Installation | Module/conda required | Python stdlib + requests |
| Availability | May not be on all systems | Works anywhere with Python |
| Usage | Subprocess calls | Direct HTTP requests |
| Output parsing | Shell piping | JSON/XML parsing in Python |
| Rate limiting | Manual `sleep` | Manual `time.sleep()` |
| Error handling | Exit codes | Try/except blocks |
| Portability | ❌ Needs EDirect | ✅ Just Python |

### NCBI E-utilities Endpoints Used

```python
# Search for samples
"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
# Parameters: db=sra, term=<query>, retmode=json

# Fetch sample details
"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
# Parameters: db=sra, id=<SRA_IDs>, rettype=full, retmode=xml
```

### Query Filters Applied

```
"<Organism>"[Organism] AND
"GENOMIC"[Source] AND
"ILLUMINA"[Platform] AND
"WGS"[Strategy]
```

This ensures:
- Species-specific samples
- Genomic DNA (not metagenomic, transcriptomic)
- Illumina sequencing (compatible with SPAdes assembly)
- Whole genome sequencing (not amplicon, RNA-seq, etc.)

---

## Analysis Ideas for Diverse Bacteria 1000 Results

### 1. Cross-Organism AMR Comparison
- Which organisms carry the most AMR genes?
- Are carbapenem resistance genes organism-specific?
- Compare resistance mechanisms across Gram-positive vs Gram-negative

### 2. Plasmid Diversity (MOB-suite)
- Incompatibility group distribution by organism
- Shared plasmids across species?
- Plasmid size distribution per organism

### 3. Prophage Analysis (VIBRANT)
- Prophage prevalence by organism
- Quality scores and completeness
- Lifestyle predictions (lytic vs lysogenic)
- Prophage-encoded AMR or virulence genes?

### 4. MLST Diversity
- Sequence type richness per organism
- Novel STs discovered?
- Clonal vs diverse populations

### 5. Genome Quality (BUSCO)
- Completeness by organism
- Which organisms assemble well?
- Identify high-quality reference genomes

### 6. Assembly Statistics (QUAST)
- N50 distribution by organism
- Contig counts
- Genome size estimates

---

## Contact

- User: tdoerks@vet.k-state.edu
- GitHub: https://github.com/tdoerks/COMPASS-pipeline
- Branch: scratch (development/notes)
- Tag: 1.0.0 (production runs)

---

*Session date: 2026-03-09*
*Job submitted: 6818330 (diverse_bacteria_1000 on COMPASS 1.0.0)*
*Next session: Monitor job progress, review validation results*
