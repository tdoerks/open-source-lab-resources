# STEC Prophage Dynamics Study

## Overview
Analysis of **Shiga toxin-producing E. coli (STEC)** to study prophage-encoded virulence genes (stx1, stx2) across serotypes and time.

## Why STEC?
- **Famous prophage biology**: Stx1 and Stx2 toxins encoded on lambdoid prophages
- **High prophage burden**: 2-8 prophages/genome (strain-dependent)
- **Multiple serotypes**: O157:H7, O26, O103, O111, O145, O104:H4
- **Public health**: Major foodborne pathogen, outbreak tracking
- **Prophage variants**: Different Stx prophage types (Stx1a, Stx2a, Stx2c, etc.)

## Sampling Strategy
**Temporal sampling**: 100 samples/month (2020-2026) = ~7,500 total
- OR: 50/month = ~3,750 (like Salmonella)
- STEC identification post-pipeline via AMRFinder (stx1/stx2 genes)
- Expected STEC %: 10-30% depending on dataset
- Expected STEC samples: 750-2,250

## Research Questions
1. How does Stx prophage prevalence change over time?
2. Stx1 vs Stx2 distribution across serotypes?
3. Do different serotypes have different prophage burdens?
4. Outbreak strains vs sporadic: prophage differences?
5. Temporal emergence of new Stx variants?

## Key Virulence Genes (AMRFinder will detect)
- **stx1** - Shiga toxin 1 (on prophage)
- **stx2** - Shiga toxin 2 (on prophage)
- **eae** - Intimin (usually chromosomal)
- **ehxA** - Enterohemolysin

## Usage

### Step 1: Download accessions
```bash
cd stec_prophage_study/

# Temporal (100/month)
python3 scripts/fetch_stec_temporal.py

# OR comprehensive (all available)
python3 scripts/fetch_stec_all.py
```

### Step 2: Generate samplesheet
```bash
python3 scripts/create_samplesheet.py
```

### Step 3: Submit
```bash
sbatch run_stec_prophage.sh
```

## Analysis Pipeline
1. **COMPASS**: Assembly, QC, MLST, AMRFinder, VIBRANT, MOB-suite
2. **Filter**: Extract stx+ samples from AMRFinder results
3. **Analyze**:
   - STEC vs non-STEC prophage burden
   - Serotype-specific prophage profiles
   - Temporal dynamics
   - Stx1 vs Stx2 prophage characteristics

## Expected Results
```
stec_prophage_results/
├── amrfinder/     # 🔥 stx1/stx2/eae detection here!
├── vibrant/       # Prophage identification
├── mlst/          # E. coli typing
├── mobsuite/      # Plasmids
└── summary/       # Integrated results
```

## Publication Angle
"Temporal dynamics of Shiga toxin prophages across E. coli serotypes: A comprehensive genomic analysis (2020-2026)"

---
*Part of Phage-Rich Organism Study Series*
*Study #6: STEC prophage dynamics*
