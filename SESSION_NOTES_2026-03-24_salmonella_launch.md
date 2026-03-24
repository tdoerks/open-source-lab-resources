# Session Notes - March 24, 2026: Salmonella Temporal Phage Study Launch

## Overview

**Date:** 2026-03-24
**Focus:** Launch Salmonella enterica temporal phage analysis study
**Status:** ✅ JOB SUBMITTED - Running on Beocat

---

## Salmonella Study Successfully Launched

### Job Details

**SLURM Job ID:** 7199221
**Pipeline:** COMPASS 1.0.1-candidate
**Samples:** 2,850 Salmonella enterica genomes
**Sampling:** 50 per month (Jan 2020 - Mar 2026)
**Expected runtime:** 16-22 days
**Expected completion:** ~April 9-15, 2026

### Project Location

```
Project directory: /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/salmonella_temporal_phage/
Work directory: work_salmonella_temporal_phage
Output directory: /fastscratch/tylerdoe/salmonella_temporal_phage_results/
```

### Data Download Summary

**Downloaded:** 2,850 SRA accessions (originally fetched 3,720, filtered to 2,850 unique)
**File:** `data/sra_accessions_salmonella_monthly_50_2020-2026.txt`
**Samplesheet:** `data/samplesheet_salmonella_temporal_phage.txt`

**Download output preview:**
```
Expected serotype distribution (based on NARMS data):
  - Typhimurium: ~20-25%
  - Enteritidis: ~15-20%
  - Newport: ~10-15%
  - Javiana, I 4,[5],12:i:-, Heidelberg: ~5-10% each
  - Others: ~20-30%
```

---

## Concurrent Studies Status

### Two Major Temporal Phage Studies Running

| Study | Job ID | Pipeline | Samples | Status | Completion |
|-------|--------|----------|---------|--------|------------|
| **Vibrio cholerae** | 7194213 | 1.0.0 | 2,787 | 🔄 Running | ~April 7-13 |
| **Salmonella enterica** | 7199221 | 1.0.1-candidate | 2,850 | 🔄 Running | ~April 9-15 |

**No conflicts:** Different pipeline directories, work dirs, and output dirs ensure no clashes.

---

## Study Design: Salmonella Prophage Dynamics

### Research Objective

Analyze **2,850 Salmonella enterica genomes** sampled monthly (Jan 2020 - Mar 2026) to study **prophage-virulence-AMR dynamics across serotypes**.

### Why Salmonella?

Completes the phage-rich organism study series:
1. ✅ **Pseudomonas aeruginosa** - Highest prophage burden (5-10/genome) - COMPLETED
2. ✅ **Vibrio cholerae** - Epidemic dynamics + geography - RUNNING (Job 7194213)
3. ✅ **Diverse Bacteria 1000** - Baseline across 20 species - COMPLETED
4. ✅ **Salmonella enterica** - Serotype diversity + well-characterized prophages - RUNNING (Job 7199221)

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

## Pipeline Configuration

### Key Settings

**Pipeline directory:** `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate`
**Input mode:** `sra_list`
**Input file:** `salmonella_temporal_phage/data/samplesheet_salmonella_temporal_phage.txt`
**BUSCO:** Enabled (with pre-downloaded databases)
**Prophage database:** `/fastscratch/tylerdoe/databases/prophage_db.dmnd`
**Resume enabled:** `-resume` flag (can restart if interrupted)

**NXF_OPTS:** `-Xms2g -Xmx8g` (prevents JVM OOM on large runs)

### Expected Outputs

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

---

## Monitoring Commands

### Check Job Status
```bash
squeue -u tylerdoe
```

### Monitor Log Output
```bash
tail -f /fastscratch/tylerdoe/slurm-salmonella-temporal-phage-7199221.out
```

### Check Results Progress
```bash
# Check how many samples have been processed
ls -lh /fastscratch/tylerdoe/salmonella_temporal_phage_results/

# Check serotyping progress (key for Salmonella)
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/sistr -name "*.tsv" | wc -l

# Check prophage analysis progress
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/vibrant -type d -name "*_vibrant" | wc -l

# Check plasmid analysis progress
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/mobsuite -type d -name "*_mobsuite" | wc -l
```

---

## Next Steps (After Completion)

### 1. Run Parsing Scripts

Use the new Claude-created parsing scripts to generate summaries:

```bash
cd /fastscratch/tylerdoe/salmonella_temporal_phage_results

# Serotype distribution (CRITICAL for Salmonella study)
python3 /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/bin/parse_sistr_serotypes.py \
    --sistr sistr/ \
    --output sistr_distribution.tsv \
    --serogroup-output serogroup_dist.tsv \
    --top-n 20

# Prophage summary
python3 /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/bin/parse_vibrant_summary.py \
    --vibrant vibrant/ \
    --output vibrant_summary.tsv \
    --prophage-catalog vibrant_prophages.tsv

# Plasmid summary
python3 /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/bin/parse_mobsuite_plasmids.py \
    --mobsuite mobsuite/ \
    --output mobsuite_summary.tsv \
    --plasmid-catalog mobsuite_plasmids.tsv

# AMR location categorization (prophage vs plasmid vs chromosome)
python3 /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/bin/categorize_amr_by_location.py \
    --amrfinder amrfinder/ \
    --mobsuite mobsuite/ \
    --vibrant vibrant/ \
    --output amr_location_matrix.tsv

# Master results table (combines everything)
python3 /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/bin/create_master_results_table.py \
    --results-dir . \
    --output master_results_table.tsv
```

**Expected runtime for all parsing scripts:** ~5 minutes total

### 2. Key Analyses to Run

**Prophage burden by serotype:**
```bash
# After master table is created
# Load into R/Python and group by serovar
# Compare Typhimurium vs Enteritidis vs Newport
```

**Gifsy-1/2 prevalence in Typhimurium:**
```bash
# Search VIBRANT results for Gifsy prophages
# Calculate prevalence over time
```

**AMR-prophage associations:**
```bash
# Use AMR location matrix
# Calculate % AMR on prophages by serotype
```

**Temporal trends:**
```bash
# Merge with SRA metadata (collection dates)
# Plot prophage prevalence over time
# Facet by serotype
```

---

## Storage Requirements

**Estimated storage:**
- Results: ~1.4 TB (2,850 samples)
- Work directory: ~400 GB
- **Total: ~1.8 TB**

**Archive strategy (after completion):**
```bash
# Compress key results for long-term storage
tar -czf salmonella_temporal_phage_key_results.tar.gz \
    salmonella_temporal_phage_results/sistr/ \
    salmonella_temporal_phage_results/mlst/ \
    salmonella_temporal_phage_results/vibrant/ \
    salmonella_temporal_phage_results/mobsuite/ \
    salmonella_temporal_phage_results/amrfinder/ \
    salmonella_temporal_phage_results/multiqc/ \
    salmonella_temporal_phage_results/summary/

# Move to long-term storage
mv salmonella_temporal_phage_key_results.tar.gz /bulk/tylerdoe/archives/
```

---

## Known Salmonella Prophages to Track

### 1. Gifsy-1 and Gifsy-2
- **Serotype:** Typhimurium-associated
- **Virulence genes:** SopE (Gifsy-1), SodC1/GogB/GtgE (Gifsy-2)
- **Type:** Lambda-like
- **Research question:** Are these still prevalent in modern Typhimurium?

### 2. P22-like phages
- **Distribution:** Widely distributed across serotypes
- **Function:** Generalized transduction
- **Importance:** Model system for Salmonella biology

### 3. ST64B
- **Serotype:** Typhimurium
- **Function:** Encodes virulence factors

### 4. Fels-1 and Fels-2
- **Serotype:** Found in many Typhimurium strains
- **Function:** Contribute to genomic diversity

### 5. ST104
- **Strain:** Associated with DT104 multidrug-resistant strain
- **Importance:** MDR linkage - critical for AMR-prophage analysis

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

### Comparative Paper (All 3 Studies)

**Title:** "Prophage-plasmid-AMR interactions across three high-prophage-burden bacterial pathogens: A temporal analysis (2020-2026)"

**Organisms:** Pseudomonas, Vibrio, Salmonella
**Sample size:** >9,000 genomes
**Time span:** 2020-2026 (75 monthly time points)

**Comparative questions:**
1. Does prophage burden correlate with AMR across organisms?
2. Are prophage-plasmid interactions universal or organism-specific?
3. How do prophage dynamics differ in environmental vs clinical pathogens?
4. Can we detect shared prophage-mediated HGT events?

---

## Comparison to Other Phage Studies

| Feature | Pseudomonas | Vibrio | **Salmonella** |
|---------|-------------|---------|----------------|
| **Samples** | ~3,750 | 2,787 | **2,850** |
| **Status** | ✅ Complete | 🔄 Running | 🔄 Running |
| **Prophage burden** | 5-10/genome | High (CTXφ) | **3-7/genome** |
| **Special typing** | MLST | MLST | **MLST + SISTR** |
| **Unique analysis** | Highest phage | Geographic | **Serotype comparison** |
| **Known prophages** | Varied | CTXφ, SXT | **Gifsy, P22, Fels** |
| **Virulence on prophages** | Yes | Yes (cholera toxin) | **Yes (SopE, SodC1)** |

---

## Claude Pipeline Improvements Available

**NEW:** After this run completes, you can use the 5 parsing scripts created during autonomous work session:

1. `parse_vibrant_summary.py` - Prophage counts and quality
2. `parse_sistr_serotypes.py` - Serotype distribution (KEY for Salmonella!)
3. `parse_mobsuite_plasmids.py` - Plasmid analysis
4. `categorize_amr_by_location.py` - AMR location (chromosome/plasmid/prophage)
5. `create_master_results_table.py` - Combines all outputs into single TSV

**Branch:** `claude/pipeline-improvements`
**Status:** Tested and ready to use
**Documentation:** See `CLAUDE_PROGRESS_NOTES_2026-03-24.md` for full details

---

## Timeline Summary

| Date | Event |
|------|-------|
| 2026-03-24 (morning) | Salmonella study conceived |
| 2026-03-24 (afternoon) | Scripts created, pushed to scratch branch |
| 2026-03-24 (evening) | Copied to COMPASS-1.0.1-candidate on Beocat |
| 2026-03-24 (late) | Download script run (~3,720 accessions → 2,850 samples) |
| 2026-03-24 (night) | **JOB SUBMITTED (7199221)** ✅ |
| ~2026-04-09 to 04-15 | Expected completion (16-22 days) |

---

## Contact

- **Researcher:** Tyler Doerksen
- **Email:** tdoerks@vet.k-state.edu
- **HPC:** Beocat (Kansas State University)
- **GitHub:** https://github.com/tdoerks/COMPASS-pipeline

---

## Changelog

- **2026-03-24 morning**: Project conception (phage-rich organism #4)
- **2026-03-24 afternoon**: Scripts created, pushed to scratch branch
- **2026-03-24 evening**: Copied to COMPASS-1.0.1-candidate on Beocat
- **2026-03-24 late**: Download completed (2,850 samples)
- **2026-03-24 night**: Samplesheet generated, job submitted (7199221) ✅

---

*Salmonella temporal phage study RUNNING. Both Vibrio and Salmonella studies now executing in parallel.*
