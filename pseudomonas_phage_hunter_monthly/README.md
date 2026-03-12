

# Pseudomonas Phage Hunter - Monthly Temporal Sampling (2020-2026)

## Overview

This project analyzes **~3,750 Pseudomonas aeruginosa genomes** sampled monthly from January 2020 to March 2026 to study the **temporal dynamics of prophage-plasmid-AMR interactions**.

### Why Pseudomonas aeruginosa?

- **Highest prophage burden**: 5-10 prophages per genome on average
- **High plasmid prevalence**: Extensive mobile genetic element repertoire
- **Clinical importance**: CF infections, nosocomial pathogens, biofilms
- **AMR crisis organism**: XDR/MDR, carbapenem resistance
- **Well-studied phage biology**: Rich literature for comparison
- **No NARMS restrictions**: Publicly available global isolates

### Research Objectives

1. **Track prophage prevalence trends** over 6 years (2020-2026)
2. **Identify phage-plasmid co-occurrence** patterns
3. **Determine AMR gene mobility**: Chromosomal vs plasmid vs prophage
4. **Detect XDR/MDR strain emergence** linked to mobile elements
5. **Discover temporal HGT events** mediated by phages
6. **Map biofilm/virulence genes** on prophages and plasmids

## Sampling Strategy

**50 Pseudomonas aeruginosa samples per month × 75 months = ~3,750 total**

- **Time period**: January 2020 - March 2026
- **Temporal resolution**: Monthly (75 time points)
- **Sample selection**: Random from available WGS Illumina GENOMIC samples
- **Geographic scope**: Global (all available in NCBI SRA)

## Project Structure

```
pseudomonas_phage_hunter_monthly/
├── README.md                                  # This file
├── scripts/
│   ├── fetch_pseudomonas_monthly.py          # Download SRR accessions (HTTP API)
│   └── create_samplesheet.py                  # Generate COMPASS samplesheet
├── run_pseudomonas_phage_hunter.sh           # SLURM submission script
└── data/                                      # Created during download
    ├── sra_accessions_pseudomonas_monthly_50_2020-2026.txt
    └── samplesheet_pseudomonas_phage_hunter.txt
```

## Usage Instructions

### Step 1: Download SRA Accessions

Run on any machine with Python and internet (including Beocat):

```bash
cd pseudomonas_phage_hunter_monthly/

# Download monthly accessions using HTTP API (takes ~90 minutes with rate limiting)
# No EDirect module needed - just Python with 'requests' library
python3 scripts/fetch_pseudomonas_monthly.py

# Verify
cat sra_accessions_pseudomonas_monthly_50_2020-2026.txt | wc -l  # Should be ~3,750
```

**What this does:**
- Queries NCBI SRA via HTTP API for each month (Jan 2020 - Mar 2026)
- Filters: Illumina platform, WGS strategy, GENOMIC source
- Random sampling: 50 per month
- Downloads only SRR accession lists (~few KB), NOT sequencing data
- COMPASS pipeline downloads actual FASTQ files later on Beocat

**Expected output:**
- ~3,750 SRR accessions (75 months × 50 samples)
- Some months may have <50 if data availability is limited

### Step 2: Generate Samplesheet

```bash
# Create samplesheet for COMPASS
python3 scripts/create_samplesheet.py

# Verify
head samplesheet_pseudomonas_phage_hunter.txt
wc -l samplesheet_pseudomonas_phage_hunter.txt
```

### Step 3: Run COMPASS Pipeline

On Beocat:

```bash
# Submit job
sbatch run_pseudomonas_phage_hunter.sh

# Monitor
squeue -u $USER
tail -f /fastscratch/tylerdoe/slurm-pseudomonas-phage-hunter-<JOBID>.out
```

**Runtime estimate:** 18-25 days for ~3,750 samples

**Resource usage:**
- CPUs: 8 per job
- Memory: 32GB
- Time limit: 336 hours (14 days, with resume capability)
- Storage: ~1.8-2TB for results

## Expected Results

```
/fastscratch/tylerdoe/pseudomonas_phage_hunter_results/
├── fastqc/              # Raw read QC
├── fastp/               # Trimmed reads QC
├── assemblies/          # SPAdes assemblies
├── busco/               # Assembly quality (genome completeness)
├── quast/               # Assembly statistics (N50, contigs, etc.)
├── mlst/                # Multi-locus sequence typing
├── mobsuite/            # 🔥 Plasmid detection and typing (KEY FOR ANALYSIS)
├── amrfinder/           # 🔥 AMR genes (KEY FOR ANALYSIS)
├── abricate/            # Multi-database AMR screening
├── vibrant/             # 🔥 Prophage detection (KEY FOR ANALYSIS)
├── diamond_prophage/    # Prophage classification
├── phanotate/           # Phage gene prediction
├── multiqc/             # Comprehensive QC report
└── summary/             # COMPASS integrated summary
```

## Analysis Roadmap

### Phase 1: Data Quality Assessment
1. **BUSCO completeness** by month (genome quality trends)
2. **Assembly statistics** (N50, contigs, genome size)
3. **Identify high-quality samples** for downstream analysis (>90% BUSCO)

### Phase 2: Prophage Analysis
1. **Prophage prevalence trends** (2020-2026)
   - Count prophages per sample over time
   - VIBRANT quality scores
   - Prophage lifestyle predictions (lytic vs lysogenic)

2. **Prophage diversity**
   - Cluster by sequence similarity
   - Identify common vs rare prophage families
   - Temporal turnover of prophage types

### Phase 3: Plasmid Analysis
1. **Plasmid prevalence and distribution**
   - MOB-suite incompatibility groups
   - Plasmid typing over time
   - Plasmid size distribution

2. **Plasmid-prophage interactions**
   - Co-occurrence patterns
   - Shared samples with high prophage + plasmid burden

### Phase 4: AMR Gene Mobility
1. **Categorize AMR genes by location**
   - Chromosomal (not on prophage or plasmid)
   - Plasmid-associated (MOB-suite hits)
   - Prophage-associated (VIBRANT hits)

2. **Temporal AMR dynamics**
   - Resistance gene prevalence trends
   - Emergence of new resistance mechanisms
   - XDR/MDR strain identification

3. **Mobile element-mediated AMR spread**
   - Which AMR genes move via phages vs plasmids?
   - Co-occurrence of resistance genes on same mobile elements

### Phase 5: Comparative Analysis
1. **Compare to E. coli monthly 100** (if available)
   - Phage-plasmid-AMR patterns across species
   - Which organism has more phage-mediated AMR?

2. **Geographic/temporal clustering**
   - MLST sequence types by time period
   - Clonal expansion events

### Phase 6: Publication-Ready Figures
1. **Prophage prevalence over time** (line graph, 2020-2026)
2. **Plasmid-prophage co-occurrence heatmap**
3. **AMR gene mobility** (pie chart: chromosome vs plasmid vs prophage)
4. **Temporal HGT network** (prophage-mediated gene transfer events)
5. **XDR emergence timeline** (linked to mobile element acquisition)

## Key Analysis Scripts (To Be Developed)

```bash
# After COMPASS completes, create analysis scripts:
bin/analyze_prophage_temporal_trends.py        # Track prophage over time
bin/analyze_plasmid_prophage_cooccurrence.py   # Co-occurrence patterns
bin/categorize_amr_by_location.py              # AMR on chromosome/plasmid/prophage
bin/identify_phage_mediated_hgt.py             # Temporal HGT events
bin/track_xdr_emergence.py                     # XDR linked to mobile elements
```

## Comparison to Diverse Bacteria 1000

| Feature | Diverse Bacteria 1000 | Pseudomonas Phage Hunter |
|---------|----------------------|--------------------------|
| Organisms | 20 species (50 each) | 1 species (Pseudomonas) |
| Samples | 1,000 | ~3,750 |
| Focus | Cross-species diversity | Temporal dynamics |
| Time period | Random (2010s-2020s) | Monthly 2020-2026 |
| Strength | Organism comparison | Time-series analysis |
| Phage content | Variable | Very high (5-10/genome) |
| Analysis | Comparative genomics | Evolutionary dynamics |

## Troubleshooting

### Not enough samples for some months?

This is expected - some months may have limited data availability. The script will:
- Take all available samples if <50 found
- Report actual counts per month
- Continue with next month

### Download script fails?

Check Python and requests library:
```bash
python3 --version  # Should be Python 3.6+
python3 -c "import requests; print('requests OK')"

# If requests missing:
pip3 install --user requests
```

### Pipeline runs slowly?

Expected for 3,750 samples! Monitor progress:
```bash
# Check completed assemblies
ls /fastscratch/tylerdoe/pseudomonas_phage_hunter_results/assemblies/*.fasta | wc -l

# Check VIBRANT (prophage) progress
find /fastscratch/tylerdoe/pseudomonas_phage_hunter_results/vibrant -type d -name "*_vibrant" | wc -l

# Check MOB-suite (plasmid) progress
find /fastscratch/tylerdoe/pseudomonas_phage_hunter_results/mobsuite -type d -name "*_mobsuite" | wc -l
```

## Data Retention

**Important:** Results will be ~1.8-2TB. After completion:

1. **Archive key results:**
   ```bash
   cd /fastscratch/tylerdoe/

   # Create compressed archive of essential results
   tar -czf pseudomonas_phage_hunter_key_results.tar.gz \
       pseudomonas_phage_hunter_results/vibrant/ \
       pseudomonas_phage_hunter_results/mobsuite/ \
       pseudomonas_phage_hunter_results/amrfinder/ \
       pseudomonas_phage_hunter_results/mlst/ \
       pseudomonas_phage_hunter_results/multiqc/ \
       pseudomonas_phage_hunter_results/summary/

   # Move to long-term storage
   mv pseudomonas_phage_hunter_key_results.tar.gz /bulk/tylerdoe/archives/
   ```

2. **Clean up work directory (after confirming results):**
   ```bash
   rm -rf /fastscratch/tylerdoe/COMPASS-pipeline/work_pseudomonas_phage_hunter
   ```

## Citation

If you use this dataset in publications, cite:
- **COMPASS Pipeline**: Your pipeline DOI/GitHub
- **NCBI SRA**: BioProjects used
- **All COMPASS tools**: AMRFinder+, VIBRANT, MOB-suite, MLST, BUSCO, etc.

## Contact

For questions or issues:
- Create an issue on the COMPASS GitHub repository
- Email: tdoerks@vet.k-state.edu

## Changelog

- **2026-03-09**: Initial project creation
  - Target: Pseudomonas aeruginosa monthly 50 (2020-2026)
  - Focus: Phage-plasmid-AMR temporal dynamics
  - Expected samples: ~3,750

---

*This project complements the Diverse Bacteria 1000 dataset with deep temporal sampling of a single high-prophage organism.*
