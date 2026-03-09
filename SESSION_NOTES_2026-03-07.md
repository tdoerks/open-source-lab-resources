# Session Notes - 2026-03-07

## Summary
Today we set up validation testing for COMPASS v1.0.0 and created a new diverse bacterial pathogen sampling project for 1,000 genomes across 20 species.

---

## Part 1: COMPASS v1.0.0 Validation Setup

### Objective
Test COMPASS v1.0.0 against the v1.3-dev validation baseline from 2026-02-09 to compare pipeline versions.

### What We Did

1. **Found validation data** in scratch branch
   - Original validation: `/scratch/tylerdoe/COMPASS_Validation_Results_v1.3-dev_2026-02-09/`
   - 163 E. coli reference genomes
   - ETEC strains, FDA ARGOS, K12, and other reference strains

2. **Created validation framework** on scratch branch:
   - `data/validation/run_compass_validation_v1.0.0.sh` - SLURM script for v1.0.0
   - `data/validation/V1.0.0_VALIDATION_GUIDE.md` - Complete setup guide
   - `VALIDATION_SUMMARY.md` - Quick reference

3. **Fixed paths** for Beocat:
   - Changed from `/scratch/tylerdoe/` to `/fastscratch/tylerdoe/`
   - Updated all output paths in the script

4. **Submitted validation job** on Beocat:
   - Job ID: 6810451
   - Status: Running as of 2026-03-07 afternoon
   - Expected runtime: 24-48 hours (but may be faster due to cached results)
   - Output: `/fastscratch/tylerdoe/COMPASS_Validation_Results_v1.0.0_6810451/`

### Beocat Setup Steps (Completed)

```bash
# On Beocat
cd /fastscratch/tylerdoe/COMPASS-pipeline
git checkout 1.0.0
git checkout scratch -- data/validation/
sbatch data/validation/run_compass_validation_v1.0.0.sh
```

### Issues Encountered

**MLST staging error:**
- Sample `ETEC_E24377A` failed with "Unable to read from 'ETEC_E24377A.fasta'"
- This is a known file staging issue affecting both v1.0.0 and v1.3-dev
- Pipeline continues with other samples
- Most samples completed successfully (163/170 cached from previous runs)

### Next Steps (After Validation Completes)

1. **Review results:**
   - Check MultiQC report
   - Compare with v1.3-dev results

2. **Run comparison analysis:**
   ```bash
   V13_DIR="/fastscratch/tylerdoe/COMPASS_Validation_Results_v1.3-dev_2026-02-09/results"
   V10_DIR="/fastscratch/tylerdoe/COMPASS_Validation_Results_v1.0.0_6810451/results"

   # Compare MLST
   diff <(cut -f1-3 $V13_DIR/mlst/*.tsv | sort) \
        <(cut -f1-3 $V10_DIR/mlst/*.tsv | sort)

   # Compare AMR counts
   wc -l $V13_DIR/amrfinder/*.tsv
   wc -l $V10_DIR/amrfinder/*.tsv
   ```

3. **Document differences** in tool outputs and versions

---

## Part 2: Diverse Bacterial Pathogen Project (1,000 Samples)

### Objective
Create a diverse bacterial dataset with controlled representation across 20 important foodborne/clinical pathogens for comparative genomics.

### Sampling Strategy
**50 samples per organism × 20 organisms = 1,000 total samples**

### Target Organisms

**Foodborne Pathogens (9 species):**
1. Listeria monocytogenes
2. Vibrio parahaemolyticus
3. Yersinia enterocolitica
4. Shigella sonnei
5. Clostridium perfringens
6. Bacillus cereus
7. Cronobacter sakazakii
8. Campylobacter coli
9. Arcobacter butzleri

**Clinical Pathogens (11 species):**
10. Staphylococcus aureus (MRSA tracking)
11. Enterococcus faecium (VRE concern)
12. Klebsiella pneumoniae (carbapenem resistance)
13. Acinetobacter baumannii (MDR nosocomial)
14. Pseudomonas aeruginosa (biofilms, CF)
15. Citrobacter freundii
16. Enterobacter cloacae
17. Proteus mirabilis (UTI)
18. Serratia marcescens
19. Vibrio cholerae (epidemic potential)
20. Helicobacter pylori (gastric cancer)

### Files Created

**Project directory:** `diverse_bacteria_1000/`

**Structure:**
```
diverse_bacteria_1000/
├── README.md                               # Complete documentation
├── run_diverse_bacteria_1000.sh            # SLURM submission script
├── scripts/
│   ├── organism_targets.txt                # 20 target organisms with metadata
│   ├── download_diverse_bacteria.py        # NCBI SRA download script
│   └── create_samplesheet.py               # Generate COMPASS samplesheet
└── data/                                   # Created during download
    ├── srr_accessions_by_organism/         # Individual organism SRR lists
    ├── combined_srr_list.txt               # All 1,000 SRRs
    └── samplesheet_diverse_1000.txt        # COMPASS input
```

### Key Features

**Download Script (`download_diverse_bacteria.py`):**
- Queries NCBI SRA for each organism
- Filters: ILLUMINA platform, GENOMIC source, WGS strategy
- Size filter: 1-10 GB (reasonable for bacteria)
- Random sampling of 50 per organism
- Rate limiting (3-second delay between queries)
- Individual SRR lists per organism for reproducibility

**Samplesheet Generator (`create_samplesheet.py`):**
- Creates COMPASS-compatible input (txt or csv format)
- Includes organism metadata
- Summary statistics by organism

**SLURM Script (`run_diverse_bacteria_1000.sh`):**
- Job name: diverse_bacteria_1000
- Time: 168 hours (7 days)
- Resources: 8 CPUs, 32GB RAM
- BUSCO enabled for quality assessment
- All analysis modules enabled
- Expected storage: ~500GB

### Usage Instructions

**Step 1: Download SRA accessions** (run on machine with internet/E-utilities)

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline/diverse_bacteria_1000/

# Load E-utilities
module load EDirect

# Download accessions (~10-15 minutes with rate limiting)
python scripts/download_diverse_bacteria.py

# Verify
ls -lh data/srr_accessions_by_organism/  # Should have 20 files
cat data/combined_srr_list.txt | wc -l   # Should be ~1,000
```

**Step 2: Generate samplesheet**

```bash
python scripts/create_samplesheet.py

# Verify
head samplesheet_diverse_1000.txt
wc -l samplesheet_diverse_1000.txt  # Should be 1,000
```

**Step 3: Submit COMPASS job**

```bash
sbatch run_diverse_bacteria_1000.sh
```

**Expected runtime:** 5-7 days for 1,000 samples

### Analysis Potential

1. **Cross-Organism AMR Comparison**
   - Which organisms carry the most AMR genes?
   - Organism-specific resistance mechanisms?
   - Carbapenem resistance distribution

2. **Plasmid Diversity**
   - Incompatibility groups by organism
   - MOB-suite plasmid typing patterns
   - Shared plasmids across species

3. **Prophage Distribution**
   - Prophage prevalence by organism
   - Quality scores (VIBRANT)
   - Lifestyle predictions

4. **MLST Diversity**
   - Sequence type richness per organism
   - Novel STs discovered
   - Geographic patterns

5. **Genome Quality**
   - BUSCO completeness by organism
   - Assembly statistics (N50, contigs)
   - Identify high-quality references

### Important Notes

**Rate Limiting:**
- Script includes 3-second delay between NCBI queries to avoid overloading servers
- Total download time: ~10-15 minutes for 20 organisms

**Data Retention:**
- Results will be ~500GB
- Archive after completion:
  ```bash
  tar -czf diverse_bacteria_1000_results.tar.gz diverse_bacteria_1000_results/
  mv diverse_bacteria_1000_results.tar.gz /homes/tylerdoe/archives/
  ```

**Dependencies:**
- NCBI E-utilities (esearch, efetch) for download
- Python 3 for scripts
- Nextflow for COMPASS pipeline

---

## Git Repository Status

**Branch:** scratch
**Commits today:**
1. v1.0.0 validation framework (commit 284eff4)
2. Diverse bacteria project (commit e6fc676)

**Pushed to GitHub:** ✅

---

## Current Running Jobs

### On Beocat

1. **COMPASS v1.0.0 Validation**
   - Job ID: 6810451
   - Status: Running
   - Started: 2026-03-07 afternoon
   - Log: `/fastscratch/tylerdoe/COMPASS_Validation_Results_v1.0.0_6810451/logs/compass_validation_6810451.out`
   - Email notification: tdoerks@vet.k-state.edu (on END or FAIL)

**Monitor with:**
```bash
squeue -u tylerdoe
tail -f /fastscratch/tylerdoe/COMPASS_Validation_Results_v1.0.0_6810451/logs/compass_validation_6810451.out
```

---

## Action Items

### Immediate (After Validation Completes)
- [ ] Review v1.0.0 validation results
- [ ] Compare with v1.3-dev baseline
- [ ] Document any differences in tool outputs

### Next (When Ready)
- [ ] Pull diverse_bacteria_1000/ to Beocat (from scratch branch)
- [ ] Run download script for SRA accessions: `python3 scripts/download_diverse_bacteria.py`
- [ ] Generate samplesheet: `python3 scripts/create_samplesheet.py`
- [ ] Submit diverse bacteria job: `sbatch run_diverse_bacteria_1000.sh`

**Note**: Download script now uses HTTP API (like E. coli monthly 100), so can run directly on Beocat

### Future
- [ ] Archive validation results (~500GB)
- [ ] Create comparison report (v1.0.0 vs v1.3-dev)
- [ ] Analyze diverse bacteria dataset
- [ ] Consider additional organism sampling (e.g., Salmonella monthly 100)

---

## Reference Commands

### Pull latest scratch branch to Beocat
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline
git fetch origin
git checkout scratch
git pull
```

### Check validation status
```bash
squeue -u tylerdoe
sacct -j 6810451 --format=JobID,JobName,State,Start,End,Elapsed
```

### Start diverse bacteria download
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline/diverse_bacteria_1000
module load EDirect
python scripts/download_diverse_bacteria.py --delay 3
```

---

## Notes

- **v1.0.0 and v1.3-dev are essentially the same** per user
- MLST file staging issue affects both versions
- Validation uses cached results (163/170 samples), so faster than expected
- Diverse bacteria project intentionally excludes E. coli, Salmonella, Campylobacter jejuni (already heavily studied in NARMS)
- Rate limiting is critical for NCBI downloads to avoid IP blocking

### Important: How SRA Accession Download Works (E. coli Monthly 100 Approach)

**Research findings from 2026-03-09:**

The E. coli monthly 100 project (`fetch_ecoli_monthly_v2.py`) uses **Python requests library** to query NCBI E-utilities HTTP API, NOT EDirect command-line tools:

1. **What gets downloaded**: Only SRR accession lists (tiny text files, ~few KB)
2. **Where it runs**: Any machine with Python + internet (including Beocat)
3. **No EDirect needed**: Uses `requests.get('https://eutils.ncbi.nlm.nih.gov/...')`
4. **Actual sequencing data**: Downloaded by COMPASS pipeline on Beocat via `fasterq-dump`

This approach was applied to `diverse_bacteria_1000/scripts/download_diverse_bacteria.py`:
- Replaced EDirect subprocess calls with HTTP API requests
- Same filtering logic (organism, platform, size 1-10GB, random sampling)
- Can run directly on Beocat without module dependencies
- No local machine storage needed (only creates small text files)

---

## Contact

- User: tdoerks@vet.k-state.edu
- GitHub: https://github.com/tdoerks/COMPASS-pipeline
- Branch: scratch (development work)
- Tag: 1.0.0 (clean production release)

---

*Session start: 2026-03-07 afternoon*
*Session update: 2026-03-09 - Fixed download script to use HTTP API (no EDirect needed)*
*Next session: Review validation results and/or start diverse bacteria download*
