# Session Notes - March 24, 2026: Salmonella Temporal Phage Study Setup

## Overview

**Date:** 2026-03-24
**Focus:** Create and launch Salmonella enterica temporal phage analysis study
**Status:** Project created, download script running on Beocat

---

## Study Design: Salmonella Prophage Dynamics

### Research Objective

Analyze **~3,750 Salmonella enterica genomes** sampled monthly (Jan 2020 - Mar 2026) to study **prophage-virulence-AMR dynamics across serotypes**.

### Why Salmonella?

Completes the phage-rich organism study series:
1. ✅ **Pseudomonas aeruginosa** - Highest prophage burden (5-10/genome)
2. ✅ **Vibrio cholerae** - Epidemic dynamics + geography
3. ✅ **Diverse Bacteria 1000** - Baseline across 20 species
4. 🆕 **Salmonella enterica** - Serotype diversity + well-characterized prophages

### Key Features

- **Prophage burden**: 3-7 prophages/genome (high)
- **Serotype diversity**: 2,500+ serovars
- **Well-characterized prophages**: Gifsy-1/2, P22, ST64B, Fels-1/2
- **Prophage-encoded virulence**: SopE, SodC1, GogB, GtgE
- **SISTR serotyping**: Automated serovar identification in COMPASS
- **Clinical + foodborne**: #1 bacterial foodborne pathogen
- **NARMS data**: Rich metadata available

### Research Questions

1. Do Typhimurium strains carry more prophages than Enteritidis?
2. Are Gifsy-1/2 prophages still prevalent in modern Typhimurium?
3. Does prophage content correlate with MDR by serotype?
4. Are virulence genes more often on prophages or plasmids?
5. Do emerging serotypes (I 4,[5],12:i:-) have different prophage profiles?
6. Temporal trends in prophage prevalence by serotype (2020-2026)?

---

## Project Files Created

### 1. Project Directory Structure

```
salmonella_temporal_phage/
├── README.md                                  # Comprehensive documentation
├── scripts/
│   ├── fetch_salmonella_monthly.py          # HTTP API downloader
│   └── create_samplesheet.py                  # Samplesheet generator
├── run_salmonella_temporal_phage.sh          # SLURM submission script
└── data/                                      # Created during download
    ├── sra_accessions_salmonella_monthly_50_2020-2026.txt
    └── samplesheet_salmonella_temporal_phage.txt
```

### 2. Download Script

**File:** `scripts/fetch_salmonella_monthly.py`

**Based on:** Proven Pseudomonas template
**Method:** HTTP API (no EDirect needed)
**Query:**
```
Salmonella enterica[Organism] AND
{YYYY/MM}[Release Date] AND
illumina[Platform] AND
GENOMIC[Source] AND
WGS[Strategy]
```

**Sampling:** 50 random per month
**Time period:** Jan 2020 - Mar 2026 (75 months)
**Expected total:** ~3,750 samples
**Runtime:** ~90 minutes with rate limiting

### 3. SLURM Submission Script

**File:** `run_salmonella_temporal_phage.sh`

**Key configurations:**
- **Pipeline directory**: `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate`
- **NXF_OPTS**: `-Xms2g -Xmx8g` (prevents JVM OOM on large runs)
- **Work directory**: `work_salmonella_temporal_phage`
- **Output directory**: `/fastscratch/tylerdoe/salmonella_temporal_phage_results`
- **Time limit**: 336 hours (14 days)
- **Resume enabled**: `-resume` flag
- **BUSCO enabled**: Pre-download required
- **Prophage database**: `/fastscratch/tylerdoe/databases/prophage_db.dmnd`

### 4. Documentation

**File:** `README.md`

**Includes:**
- Comprehensive overview
- 8-phase analysis roadmap
- Known Salmonella prophages to track
- Serotype-specific research questions
- Comparison to other studies
- Expected results and outputs
- Troubleshooting guide

---

## Deployment on Beocat

### Step 1: Copy Project to Production

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline
git pull origin scratch
cp -r salmonella_temporal_phage ../COMPASS-pipeline-1.0.1-candidate/
```

**Note:** Had to use `git checkout origin/scratch -- salmonella_temporal_phage` to resolve divergent branches

### Step 2: Create Data Directory

```bash
cd ../COMPASS-pipeline-1.0.1-candidate/salmonella_temporal_phage
mkdir -p data
```

### Step 3: Run Download Script

```bash
python3 scripts/fetch_salmonella_monthly.py
```

**Status:** Currently running (~90 minute download)

---

## Expected Outputs

### COMPASS Pipeline Results

```
/fastscratch/tylerdoe/salmonella_temporal_phage_results/
├── sistr/               # 🔥 Salmonella serotyping (KEY)
├── mlst/                # Sequence typing
├── vibrant/             # Prophage detection
├── mobsuite/            # Plasmid detection
├── amrfinder/           # AMR genes
├── abricate/            # Multi-database AMR
├── busco/               # Genome quality
├── quast/               # Assembly stats
├── multiqc/             # Integrated QC report
└── summary/             # COMPASS summary
```

### Key Analyses Enabled

1. **Serotype distribution over time** (SISTR)
2. **Prophage prevalence by serotype** (VIBRANT + SISTR)
3. **Gifsy-1/2 tracking in Typhimurium**
4. **Virulence gene location** (chromosome/plasmid/prophage)
5. **AMR patterns by serotype**
6. **Temporal HGT events**
7. **MLST diversity and clonal expansion**

---

## Git Status

### Commits Made

**Branch:** `scratch`

**Commit 1:** Add Salmonella temporal phage project
- README.md with comprehensive documentation
- Download and samplesheet scripts
- SLURM submission script
- Analysis roadmap

**Commit 2:** Update run script to use COMPASS 1.0.1-candidate
- Changed PIPELINE_DIR from 1.0.0 to 1.0.1-candidate

**Commit 3:** Add phage-rich study series overview
- Comparison matrix for all 4 studies
- Publication potential
- Future candidate organisms

**All pushed to:** `origin/scratch`

---

## Comparison to Other Phage Studies

| Feature | Pseudomonas | Vibrio | **Salmonella** |
|---------|-------------|---------|----------------|
| **Samples** | ~3,750 | 2,787 | **~3,750** |
| **Prophage burden** | 5-10/genome | High (CTXφ) | **3-7/genome** |
| **Special typing** | MLST | MLST | **MLST + SISTR** |
| **Unique analysis** | Highest phage | Geographic | **Serotype comparison** |
| **Known prophages** | Varied | CTXφ, SXT | **Gifsy, P22, Fels** |
| **Virulence on prophages** | Yes | Yes (cholera toxin) | **Yes (SopE, SodC1)** |

---

## Known Salmonella Prophages

### 1. Gifsy-1 and Gifsy-2
- **Serotype:** Typhimurium-associated
- **Virulence genes:** SopE (Gifsy-1), SodC1/GogB/GtgE (Gifsy-2)
- **Type:** Lambda-like

### 2. P22-like phages
- **Distribution:** Widely distributed across serotypes
- **Function:** Generalized transduction
- **Importance:** Model system

### 3. ST64B
- **Serotype:** Typhimurium
- **Function:** Encodes virulence factors

### 4. Fels-1 and Fels-2
- **Serotype:** Found in many Typhimurium strains
- **Function:** Contribute to genomic diversity

### 5. ST104
- **Strain:** Associated with DT104 multidrug-resistant strain
- **Importance:** MDR linkage

---

## Next Steps (After Download Completes)

### 1. Generate Samplesheet

```bash
python3 scripts/create_samplesheet.py
```

### 2. Verify Sample Count

```bash
wc -l data/sra_accessions_salmonella_monthly_50_2020-2026.txt
wc -l data/samplesheet_salmonella_temporal_phage.txt
```

### 3. Submit Pipeline

```bash
sbatch run_salmonella_temporal_phage.sh
```

**Expected runtime:** 18-25 days for ~3,750 samples

### 4. Monitor Progress

```bash
squeue -u tylerdoe
tail -f /fastscratch/tylerdoe/slurm-salmonella-temporal-phage-*.out

# Check results
ls -lh /fastscratch/tylerdoe/salmonella_temporal_phage_results/

# Check serotyping progress
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/sistr -name "*.tsv" | wc -l
```

---

## Concurrent Pipeline Development

### Claude Improvement Branch Created

**Branch:** `claude/pipeline-improvements`

**Purpose:** Implement improvements while Salmonella download runs

**Roadmap created:** `CLAUDE_IMPROVEMENT_ROADMAP.md`

**Priority Quick Wins:**
1. Prokka annotation module (needed for pangenome)
2. Result parsing scripts (UX improvement)
3. Conditional SISTR (resource optimization)
4. **AMR location categorization** (critical for phage studies!)
5. Master results table (data integration)

**Claude working autonomously on improvements...**

---

## Expected Timeline

| Task | Duration | Status |
|------|----------|--------|
| Download SRR accessions | 90 min | 🔄 Running |
| Generate samplesheet | 1 min | ⏳ Pending |
| Submit pipeline | 1 min | ⏳ Pending |
| **Pipeline execution** | **18-25 days** | ⏳ Pending |
| Results analysis | Ongoing | ⏳ Pending |

**Start date:** 2026-03-24
**Expected completion:** ~2026-04-12 to 2026-04-18

---

## Storage Requirements

**Results size:** ~1.8-2 TB
**Work directory:** ~500 GB
**Total:** ~2.3 TB

**Archive strategy:**
```bash
# After completion
tar -czf salmonella_temporal_phage_key_results.tar.gz \
    salmonella_temporal_phage_results/sistr/ \
    salmonella_temporal_phage_results/mlst/ \
    salmonella_temporal_phage_results/vibrant/ \
    salmonella_temporal_phage_results/mobsuite/ \
    salmonella_temporal_phage_results/amrfinder/ \
    salmonella_temporal_phage_results/multiqc/ \
    salmonella_temporal_phage_results/summary/

mv salmonella_temporal_phage_key_results.tar.gz /bulk/tylerdoe/archives/
```

---

## Publication Potential

### Individual Paper
**Title:** "Serotype-specific prophage profiles and virulence gene mobility in Salmonella enterica: A temporal analysis (2020-2026)"

**Key findings** (anticipated):
- Gifsy-1/2 prevalence in Typhimurium over time
- Serotype-specific prophage profiles
- Virulence gene location (prophage vs plasmid vs chromosome)
- MDR-prophage associations by serotype
- Emerging serotype prophage patterns

### Comparative Paper
**Title:** "Prophage-plasmid-AMR interactions across three high-prophage-burden bacterial pathogens: A temporal analysis"

**Organisms:** Pseudomonas, Vibrio, Salmonella
**Sample size:** >10,000 genomes
**Time span:** 2020-2026 (75 monthly time points)

---

## Contact

- **Researcher:** Tyler Doerksen
- **Email:** tdoerks@vet.k-state.edu
- **HPC:** Beocat (Kansas State University)
- **GitHub:** https://github.com/tdoerks/COMPASS-pipeline

---

## Changelog

- **2026-03-24 00:00**: Project conception (phage-rich organism #4)
- **2026-03-24 00:30**: Scripts created, pushed to scratch branch
- **2026-03-24 00:45**: Copied to COMPASS-1.0.1-candidate on Beocat
- **2026-03-24 00:55**: Download script started (~3,750 samples)
- **2026-03-24 01:00**: Claude improvement branch created, roadmap complete

---

*Salmonella temporal phage study in progress. Download running, pipeline development ongoing.*
