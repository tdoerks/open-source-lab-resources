# Vibrio cholerae - Temporal & Geographic Prophage-AMR Dynamics (2020-2026)

## Overview

This project analyzes **~3,750 Vibrio cholerae genomes** with **BOTH temporal and geographic stratification** to study prophage-plasmid-AMR interactions across epidemic regions.

### Why Vibrio cholerae?

- **HIGHEST prophage burden**: 8-12 prophages per genome (highest of any pathogen!)
- **CTXφ prophage**: Carries cholera toxin genes - directly linked to virulence
- **Epidemic tracking**: Clear geographic and temporal patterns
- **Global health importance**: Endemic in Bangladesh, India, Haiti, Africa
- **Phage-mediated pathogenesis**: CTXφ conversion is THE disease mechanism
- **Emerging AMR**: Fluoroquinolone, azithromycin resistance spreading

### Research Objectives

1. **Geographic prophage distribution**: CTXφ and other prophages by region
2. **Temporal epidemic tracking**: Outbreak waves 2020-2026 via phage signatures
3. **Regional AMR emergence**: Resistance spread patterns by geography + time
4. **CTXφ variant tracking**: Different CTXφ types across regions/time
5. **Phage-plasmid co-occurrence**: Geographic patterns in mobile element burden
6. **Pandemic genomics**: 7th pandemic O1 El Tor strain evolution

## Sampling Strategy

**Geographic + Temporal Stratification:**

### Target Regions (Based on Cholera Endemicity)

1. **South Asia** (India, Bangladesh, Pakistan) - ~30 samples/month
2. **Africa** (DRC, Kenya, Nigeria, Mozambique, etc.) - ~10 samples/month
3. **Americas** (Haiti, Dominican Republic) - ~5 samples/month
4. **Southeast Asia** (Thailand, Philippines, Vietnam) - ~5 samples/month

**Total: 50 samples/month × 75 months (Jan 2020 - Mar 2026) = ~3,750 samples**

### Geographic Metadata Fields to Capture

From SRA metadata, we'll extract:
- `geo_loc_name` - Country/region
- `isolation_source` - Clinical, environmental, water
- `collection_date` - Exact date (for temporal analysis)
- `host` - Human, environmental
- `lat_lon` - GPS coordinates (if available)
- `serogroup` - O1, O139, etc.
- `biotype` - El Tor, Classical

## Project Structure

```
vibrio_cholerae_temporal_geographic/
├── README.md                                # This file
├── scripts/
│   ├── fetch_vibrio_geographic.py          # Download with geographic stratification
│   ├── create_samplesheet.py               # COMPASS samplesheet
│   └── analyze_geographic_temporal.py      # Post-pipeline analysis
├── run_vibrio_cholerae.sh                  # SLURM submission script
└── data/                                   # Created during download
    ├── sra_accessions_by_region/          # Separate lists per region
    │   ├── south_asia_monthly.txt
    │   ├── africa_monthly.txt
    │   ├── americas_monthly.txt
    │   └── southeast_asia_monthly.txt
    ├── combined_vibrio_accessions.txt      # All ~3,750 SRRs
    └── samplesheet_vibrio_cholerae.txt     # With geographic metadata
```

## Usage Instructions

### Step 1: Download SRA Accessions with Geographic Stratification

```bash
cd vibrio_cholerae_temporal_geographic/

# Download with geographic filtering
python3 scripts/fetch_vibrio_geographic.py

# This creates:
# - Individual region files (for subsetting analyses)
# - Combined file (for full run)
# - Geographic summary report
```

**What the script does:**
- Queries NCBI SRA for Vibrio cholerae by month (2020-2026)
- Filters by geographic region using metadata fields
- Stratifies sampling: More from endemic regions (South Asia, Africa)
- Downloads only SRR accessions + full metadata
- Creates geographic distribution summary

### Step 2: Generate Samplesheet

```bash
python3 scripts/create_samplesheet.py

# Verify
head samplesheet_vibrio_cholerae.txt
wc -l samplesheet_vibrio_cholerae.txt  # Should be ~3,750
```

### Step 3: Run COMPASS Pipeline

```bash
sbatch run_vibrio_cholerae.sh

# Monitor
squeue -u $USER
tail -f /fastscratch/tylerdoe/slurm-vibrio-cholerae-*.out
```

**Runtime estimate:** 18-25 days for ~3,750 samples

## Expected Results

All standard COMPASS outputs PLUS geographic metadata:

```
/fastscratch/tylerdoe/vibrio_cholerae_results/
├── assemblies/          # Genome assemblies
├── vibrant/             # 🔥 PROPHAGE detection (CTXφ + others)
├── mobsuite/            # 🔥 Plasmid detection
├── amrfinder/           # 🔥 AMR genes
├── mlst/                # Sequence typing
├── summary/             # COMPASS summary WITH GEOGRAPHIC FIELDS
└── metadata/            # Full SRA metadata with geo_loc_name, lat_lon, etc.
```

## Analysis Roadmap

### Phase 1: Geographic Distribution

1. **CTXφ prophage prevalence by region**
   - Map CTXφ presence across South Asia, Africa, Americas
   - Identify CTXφ-negative strains (rare, but important!)
   - CTXφ variant distribution (Classical vs El Tor CTXφ)

2. **Other prophage diversity by region**
   - Total prophage burden: South Asia vs Africa vs Americas
   - Region-specific prophage families
   - Co-occurrence with CTXφ

3. **Geographic prophage heatmaps**
   - Prophage count per sample by region/country
   - Specific prophage types enriched in certain regions

### Phase 2: Temporal Dynamics

1. **Epidemic wave tracking (2020-2026)**
   - Sample counts by region/month (proxy for outbreak activity)
   - Prophage burden during epidemic peaks
   - CTXφ variant shifts over time

2. **Prophage evolution over time**
   - Temporal changes in prophage diversity
   - New prophage types emerging
   - CTXφ sequence variation 2020-2026

### Phase 3: Geographic-Temporal AMR

1. **Regional AMR emergence**
   - Fluoroquinolone resistance: Bangladesh vs Haiti vs Africa
   - Azithromycin resistance tracking (emerging threat)
   - Tetracycline resistance (older, but still present)

2. **AMR spread patterns**
   - Does resistance emerge in one region and spread?
   - Link AMR to specific sequence types (MLST)
   - Mobile element-mediated AMR by region

### Phase 4: CTXφ Deep Dive

1. **CTXφ prophage characterization**
   - Extract CTXφ sequences from VIBRANT results
   - Classify: Classical CTXφ vs El Tor CTXφ vs variants
   - Map ctxAB toxin gene presence

2. **CTXφ phylogeography**
   - CTXφ phylogenetic tree colored by region
   - Temporal spread patterns
   - Identify transmission events between regions

### Phase 5: Plasmid-Prophage Interactions

1. **SXT/R391 ICE elements** (common in V. cholerae)
   - Co-occurrence with CTXφ
   - Geographic distribution
   - AMR genes on SXT elements

2. **Prophage-plasmid burden by region**
   - Do some regions have higher mobile element load?
   - Correlation with AMR prevalence

### Phase 6: Publication-Ready Outputs

1. **Geographic prophage map** (world map with prophage counts by region)
2. **Temporal epidemic waves** (line graph: samples/month by region)
3. **CTXφ phylogeography** (phylogenetic tree + map)
4. **Regional AMR emergence** (heatmap: resistance genes × region × year)
5. **Mobile element co-occurrence network** (CTXφ + SXT + plasmids)

## Key Analysis Scripts (To Be Developed)

```bash
# Post-COMPASS analysis tools
scripts/analyze_geographic_temporal.py         # Main analysis script
scripts/extract_ctxphi_sequences.py            # CTXφ extraction from VIBRANT
scripts/map_prophage_geography.py              # Geographic prophage mapping
scripts/track_amr_spread.py                    # AMR emergence by region/time
scripts/identify_epidemic_waves.py             # Temporal outbreak detection
```

## Comparison to Pseudomonas Phage Hunter

| Feature | Pseudomonas Phage Hunter | Vibrio Cholerae Study |
|---------|--------------------------|----------------------|
| Organism | P. aeruginosa | V. cholerae |
| Prophage burden | 5-10/genome | **8-12/genome (HIGHEST!)** |
| Samples | ~3,750 | ~3,750 |
| Temporal | Monthly 2020-2026 ✅ | Monthly 2020-2026 ✅ |
| Geographic | Global (random) | **Stratified by endemic regions ✅** |
| Unique prophage | Various | **CTXφ (toxin-encoding!)** |
| AMR focus | XDR/MDR, carbapenem | Fluoroquinolone, azithromycin |
| Strength | Temporal phage dynamics | **Geographic + temporal dynamics** |
| Disease | Chronic infections | **Epidemic outbreaks** |

## Geographic Stratification Details

### Why Geographic Matters for Cholera:

1. **Endemic vs epidemic regions** have different strain characteristics
2. **CTXφ variants cluster geographically** (Indian vs African vs Haitian strains)
3. **AMR emergence is regional** (e.g., fluoroquinolone resistance in Bangladesh)
4. **Transmission tracking** requires geographic + temporal data
5. **Outbreak attribution** (linking cases to source regions)

### How We'll Stratify:

**Download script** will:
1. Query NCBI SRA for all V. cholerae (2020-2026)
2. Extract `geo_loc_name` from metadata
3. Classify into regions: South Asia, Africa, Americas, Southeast Asia, Other
4. Sample proportionally: More from endemic regions (South Asia, Africa)
5. Create region-specific SRR lists + combined list

**Samplesheet** will include:
- `sample_id` (SRR)
- `organism` (Vibrio cholerae)
- `region` (South Asia, Africa, etc.)
- `country` (extracted from geo_loc_name)
- `collection_date` (for temporal analysis)
- `lat_lon` (if available - for mapping)

**Analysis** will leverage:
- Region as grouping variable for all analyses
- Country-level resolution where possible
- Temporal trends WITHIN each region
- Cross-region comparisons

## Data Retention

**Results:** ~1.8-2TB

**Archive strategy:**
```bash
# Key results by region
tar -czf vibrio_cholerae_results_south_asia.tar.gz \
    $(grep "South_Asia" samplesheet_vibrio_cholerae.txt | cut -f1 | \
      xargs -I {} find vibrio_cholerae_results -name "{}_*")

# Full archive
tar -czf vibrio_cholerae_full_results.tar.gz \
    vibrio_cholerae_results/vibrant/ \
    vibrio_cholerae_results/mobsuite/ \
    vibrio_cholerae_results/amrfinder/ \
    vibrio_cholerae_results/mlst/ \
    vibrio_cholerae_results/summary/ \
    vibrio_cholerae_results/metadata/

mv vibrio_cholerae_full_results.tar.gz /bulk/tylerdoe/archives/
```

## Expected Findings

Based on literature, we expect:

1. **CTXφ prevalence**: >90% in clinical isolates, variable in environmental
2. **Regional CTXφ variants**: El Tor CTXφ dominant globally, Classical CTXφ rare
3. **Prophage burden**: Higher in 7th pandemic O1 El Tor strains
4. **AMR hotspots**: Bangladesh/India for fluoroquinolone resistance
5. **SXT elements**: Common in African and Asian strains
6. **Temporal waves**: Corresponding to known outbreak periods (Haiti 2022, etc.)

## Citation

If you use this dataset, cite:
- COMPASS Pipeline DOI
- NCBI SRA BioProjects
- Key tools: VIBRANT, MOB-suite, AMRFinder+, MLST

## Contact

- Email: tdoerks@vet.k-state.edu
- GitHub: https://github.com/tdoerks/COMPASS-pipeline

## Changelog

- **2026-03-16**: Initial project creation
  - Added geographic stratification to temporal sampling
  - Focus: CTXφ prophage + epidemic tracking across regions
  - Target: ~3,750 samples (2020-2026) from 4 major endemic regions

---

*This project adds geographic dimension to the Pseudomonas temporal approach, enabling phylogeographic analysis of the world's highest-prophage-burden pathogen during active epidemic periods.*
