# Fusobacterium necrophorum Study - Quick Start Guide

## Overview
This study analyzes **ALL available F. necrophorum genomes (~600)** to investigate prophage burden, subspecies differences, and mobile genetic element dynamics in this important anaerobic pathogen.

## Why F. necrophorum?
- **First obligate anaerobe** in your phage-rich organism series
- **Veterinary importance**: Liver abscesses (cattle), foot rot (sheep)
- **Human pathogen**: Lemierre's syndrome
- **Subspecies diversity**: *necrophorum* vs *funduliforme*
- **Recent research**: 2023/2024 papers on F. necrophorum prophages
- **Your professor's interest**: Active research area!

## Project Files
```
fusobacterium_necrophorum_study/
├── README.md                                    # Full documentation
├── QUICK_START.md                               # This file
├── PHAGE_RICH_STUDY_SERIES_UPDATED.md          # Updated study series overview
├── scripts/
│   ├── fetch_fusobacterium_necrophorum.py      # Download SRA accessions
│   └── create_samplesheet.py                    # Generate COMPASS samplesheet
├── run_fusobacterium_necrophorum.sh            # SLURM job script
└── data/                                        # Created when you run scripts
    ├── sra_accessions_fusobacterium_necrophorum_all.txt
    └── samplesheet_fusobacterium_necrophorum.txt
```

## Setup & Launch (3 Steps)

### Step 1: Copy to Beocat
```bash
# From your local machine or login node:
scp -r fusobacterium_necrophorum_study username@beocat.ksu.edu:/fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/
```

### Step 2: Download SRA Accessions & Generate Samplesheet
```bash
# SSH to Beocat
ssh beocat.ksu.edu

# Navigate to project
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/fusobacterium_necrophorum_study

# Download ALL F. necrophorum SRA accessions (~5-10 minutes)
python3 scripts/fetch_fusobacterium_necrophorum.py

# Generate COMPASS samplesheet
python3 scripts/create_samplesheet.py

# Verify
wc -l data/samplesheet_fusobacterium_necrophorum.txt  # Should be ~600
```

### Step 3: Submit COMPASS Job
```bash
# Submit to SLURM
sbatch run_fusobacterium_necrophorum.sh

# Monitor progress
squeue -u $USER
tail -f /fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-*.out
```

## Expected Runtime & Resources
- **Samples**: ~600 genomes
- **Runtime**: 4-7 days
- **CPUs**: 8
- **Memory**: 32-64GB
- **Storage**: ~350-500GB for results

## Key Research Questions
1. **How many prophages does F. necrophorum carry?**
   - Compare to Pseudomonas (5-10), Salmonella (3-7), Vibrio (high)

2. **Do subspecies differ?**
   - *necrophorum* vs *funduliforme* prophage profiles

3. **Anaerobe vs aerobe prophage biology?**
   - First obligate anaerobe in your series!

4. **Is leukotoxin on mobile elements?**
   - Check prophages and plasmids for virulence genes

5. **Host-specific patterns?**
   - Bovine vs human vs ovine isolates

## Results Location
```
/fastscratch/tylerdoe/fusobacterium_necrophorum_results/
├── mlst/                # Subspecies typing
├── vibrant/             # 🔥 Prophage detection (KEY)
├── mobsuite/            # 🔥 Plasmid analysis (KEY)
├── amrfinder/           # 🔥 AMR + virulence (KEY - leukotoxin!)
├── abricate/            # Multi-database screening
├── busco/               # Genome quality
├── multiqc/             # Comprehensive report
└── summary/             # COMPASS integrated summary
```

## After Completion - Archive Results
```bash
cd /fastscratch/tylerdoe/

# Compress key results
tar -czf fusobacterium_necrophorum_key_results.tar.gz \
    fusobacterium_necrophorum_results/mlst/ \
    fusobacterium_necrophorum_results/vibrant/ \
    fusobacterium_necrophorum_results/mobsuite/ \
    fusobacterium_necrophorum_results/amrfinder/ \
    fusobacterium_necrophorum_results/multiqc/ \
    fusobacterium_necrophorum_results/summary/

# Move to archives
mv fusobacterium_necrophorum_key_results.tar.gz /bulk/tylerdoe/archives/
```

## Publication Angle
**"Prophage dynamics in an obligate anaerobe: Comprehensive analysis of Fusobacterium necrophorum reveals subspecies-specific mobile genetic element patterns"**

- First large-scale F. necrophorum prophage study
- Compare anaerobe to aerobic pathogens in your series
- Subspecies and host source analysis
- Veterinary One Health importance

## Need Help?
- Full documentation: See `README.md`
- Study series overview: See `PHAGE_RICH_STUDY_SERIES_UPDATED.md`
- Email: tdoerks@vet.k-state.edu

---
*Created: 2026-04-13*
*Part of: Phage-Rich Organism Study Series*
*Study #5: First obligate anaerobe*
