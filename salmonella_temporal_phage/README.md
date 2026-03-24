# Salmonella Prophage Dynamics - Multi-Serotype Temporal Analysis (2020-2026)

## Overview

This project analyzes **~3,750 Salmonella enterica genomes** sampled monthly from January 2020 to March 2026 to study **prophage-mediated virulence and AMR spread across serotypes**.

### Why Salmonella enterica?

- **High prophage burden**: 3-7 prophages per genome on average
- **Well-characterized prophages**: Gifsy-1/2, P22, ST64B, Fels-1/2
- **Prophage-encoded virulence**: SopE, SodC1, GogB, GtgE on prophages
- **Serotype diversity**: 2,500+ serovars with different prophage profiles
- **Clinical + foodborne importance**: #1 cause of bacterial foodborne illness
- **Rich NARMS data**: PRJNA292661 with extensive metadata
- **Source diversity**: Clinical, retail meat, environmental isolates

### Research Objectives

1. **Track prophage prevalence across serotypes** over 6 years (2020-2026)
2. **Compare prophage profiles** between major serotypes (Typhimurium, Enteritidis, Newport)
3. **Identify prophage-plasmid co-occurrence** patterns by serotype
4. **Determine virulence gene mobility** on prophages vs plasmids
5. **Track AMR emergence** linked to mobile elements by serotype
6. **Compare clinical vs food source** prophage/AMR differences
7. **Detect serotype-specific HGT events** over time

## Sampling Strategy

**50 Salmonella enterica samples per month × 75 months = ~3,750 total**

- **Time period**: January 2020 - March 2026
- **Temporal resolution**: Monthly (75 time points)
- **Sample selection**: Random from available WGS Illumina GENOMIC samples
- **Geographic scope**: Global (NARMS + other SRA data)
- **Expected serotype distribution**:
  - Typhimurium: ~20-25%
  - Enteritidis: ~15-20%
  - Newport: ~10-15%
  - Javiana, I 4,[5],12:i:-, Heidelberg, Montevideo: ~5-10% each
  - Others: ~20-30%

## Project Structure

```
salmonella_temporal_phage/
├── README.md                                  # This file
├── scripts/
│   ├── fetch_salmonella_monthly.py          # Download SRR accessions (HTTP API)
│   └── create_samplesheet.py                  # Generate COMPASS samplesheet
├── run_salmonella_temporal_phage.sh          # SLURM submission script
└── data/                                      # Created during download
    ├── sra_accessions_salmonella_monthly_50_2020-2026.txt
    └── samplesheet_salmonella_temporal_phage.txt
```

## Usage Instructions

### Step 1: Download SRA Accessions

Run on any machine with Python and internet (including Beocat):

```bash
cd salmonella_temporal_phage/

# Download monthly accessions using HTTP API (takes ~90 minutes with rate limiting)
# No EDirect module needed - just Python with 'requests' library
python3 scripts/fetch_salmonella_monthly.py

# Verify
cat data/sra_accessions_salmonella_monthly_50_2020-2026.txt | wc -l  # Should be ~3,750
```

**What this does:**
- Queries NCBI SRA via HTTP API for each month (Jan 2020 - Mar 2026)
- Search: "Salmonella enterica"[Organism] + Illumina + WGS + GENOMIC
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
head data/samplesheet_salmonella_temporal_phage.txt
wc -l data/samplesheet_salmonella_temporal_phage.txt
```

### Step 3: Run COMPASS Pipeline

On Beocat:

```bash
# Submit job
sbatch run_salmonella_temporal_phage.sh

# Monitor
squeue -u $USER
tail -f /fastscratch/tylerdoe/slurm-salmonella-temporal-phage-<JOBID>.out
```

**Runtime estimate:** 18-25 days for ~3,750 samples

**Resource usage:**
- CPUs: 8 per job
- Memory: 64GB (SPAdes)
- Time limit: 336 hours (14 days, with resume capability)
- Storage: ~1.8-2TB for results

## Expected Results

```
/fastscratch/tylerdoe/salmonella_temporal_phage_results/
├── fastqc/              # Raw read QC
├── fastp/               # Trimmed reads QC
├── assemblies/          # SPAdes assemblies
├── busco/               # Assembly quality (genome completeness)
├── quast/               # Assembly statistics (N50, contigs, etc.)
├── mlst/                # 🔥 Multi-locus sequence typing (KEY - ST diversity)
├── sistr/               # 🔥 Salmonella serotyping (KEY - serovar identification)
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

### Phase 1: Data Quality & Serotype Distribution
1. **BUSCO completeness** by month (genome quality trends)
2. **Assembly statistics** (N50, contigs, genome size)
3. **SISTR serotype distribution** over time
4. **MLST diversity** (sequence types by serotype)
5. **Identify high-quality samples** for downstream analysis (>90% BUSCO)

### Phase 2: Prophage Analysis by Serotype
1. **Prophage prevalence trends** (2020-2026)
   - Overall prophage counts per sample
   - Stratify by serotype (Typhimurium vs Enteritidis vs Newport)
   - VIBRANT quality scores
   - Prophage lifestyle predictions

2. **Serotype-specific prophage profiles**
   - Which serotypes carry the most prophages?
   - Gifsy-1/2 prevalence in Typhimurium
   - P22-like phages across serotypes
   - Novel prophages in emerging serotypes

3. **Prophage diversity**
   - Cluster by sequence similarity
   - Identify common vs rare prophage families
   - Temporal turnover of prophage types by serotype

### Phase 3: Plasmid Analysis
1. **Plasmid prevalence and distribution**
   - MOB-suite incompatibility groups by serotype
   - Plasmid typing over time
   - Plasmid size distribution

2. **Plasmid-prophage interactions**
   - Co-occurrence patterns
   - Serotype-specific associations
   - Shared samples with high prophage + plasmid burden

### Phase 4: Virulence Gene Mobility
1. **Categorize virulence genes by location**
   - Chromosomal (core genome)
   - Plasmid-associated (MOB-suite hits)
   - Prophage-associated (VIBRANT hits)

2. **Prophage-encoded virulence**
   - SopE (Salmonella outer protein E) - Gifsy-1
   - SodC1 (superoxide dismutase) - Gifsy-2
   - GogB, GtgE - Gifsy-2
   - Identify using AMRFinder virulence gene detection

3. **Serotype-virulence associations**
   - Which serotypes carry prophage virulence genes?
   - Temporal emergence of virulent clones

### Phase 5: AMR Gene Mobility
1. **Categorize AMR genes by location**
   - Chromosomal
   - Plasmid-associated
   - Prophage-associated

2. **Temporal AMR dynamics by serotype**
   - Resistance gene prevalence trends
   - Emergence of MDR strains
   - Compare Typhimurium (often MDR) vs Enteritidis

3. **Mobile element-mediated AMR spread**
   - Which AMR genes move via phages vs plasmids?
   - Serotype-specific resistance patterns

### Phase 6: Source & Geographic Analysis
1. **Clinical vs food source comparison** (if metadata available)
   - Prophage differences
   - AMR differences
   - Serotype distribution

2. **Temporal clustering**
   - MLST sequence types by time period
   - Clonal expansion events
   - Outbreak detection

### Phase 7: Comparative Analysis
1. **Compare to Pseudomonas & Vibrio studies**
   - Phage-plasmid-AMR patterns across organisms
   - Which organism has more prophage-mediated virulence?

2. **Serotype comparison**
   - Typhimurium vs Enteritidis prophage profiles
   - Newport AMR patterns
   - Emerging serotypes (I 4,[5],12:i:-, Javiana)

### Phase 8: Publication-Ready Figures
1. **Prophage prevalence over time by serotype** (line graph, 2020-2026)
2. **Serotype distribution timeline** (stacked area chart)
3. **Plasmid-prophage co-occurrence heatmap by serotype**
4. **Virulence gene mobility** (pie chart: chromosome vs plasmid vs prophage)
5. **Temporal HGT network** (prophage-mediated gene transfer events)
6. **MDR emergence timeline by serotype** (linked to mobile element acquisition)
7. **MLST diversity by serotype** (rarefaction curves)

## Key Analysis Scripts (To Be Developed)

```bash
# After COMPASS completes, create analysis scripts:
bin/analyze_prophage_by_serotype.py           # Prophage patterns by serovar
bin/analyze_sistr_temporal_trends.py          # Serotype distribution over time
bin/categorize_virulence_by_location.py       # Virulence on chromosome/plasmid/prophage
bin/compare_clinical_vs_food_sources.py       # Source-specific analysis
bin/identify_serotype_specific_hgt.py         # Temporal HGT events by serotype
bin/track_mdr_emergence_by_serotype.py        # MDR linked to mobile elements
```

## Known Salmonella Prophages to Look For

### Major Prophage Families
1. **Gifsy-1 and Gifsy-2** (Typhimurium-associated)
   - Carry SopE, SodC1, GogB, GtgE virulence genes
   - Lambda-like phages

2. **P22-like phages**
   - Widely distributed across serotypes
   - Can mediate generalized transduction

3. **ST64B**
   - Typhimurium phage
   - Encodes virulence factors

4. **Fels-1 and Fels-2**
   - Found in many Typhimurium strains
   - Contribute to genomic diversity

5. **ST104**
   - Associated with DT104 multidrug-resistant strain

## Comparison to Other Studies

| Feature | Pseudomonas Phage Hunter | Vibrio Cholerae | Salmonella Temporal Phage |
|---------|--------------------------|-----------------|---------------------------|
| Organism | Pseudomonas aeruginosa | Vibrio cholerae | Salmonella enterica |
| Samples | ~3,750 | 2,787 | ~3,750 |
| Focus | Temporal phage-AMR | Geographic + temporal | Serotype + temporal |
| Time period | Monthly 2020-2026 | Monthly 2020-2026 | Monthly 2020-2026 |
| Prophage burden | Very high (5-10/genome) | High (CTXφ + others) | High (3-7/genome) |
| Strength | Highest phage content | Epidemic dynamics | Serotype diversity |
| Special feature | CF pathogen, XDR | Geographic spread | Foodborne + clinical |
| Typing system | MLST | MLST | MLST + SISTR serotyping |
| Unique analysis | Phage-plasmid-AMR | Geographic AMR | Serotype-virulence |

## Salmonella-Specific Research Questions

1. **Do Typhimurium strains carry more prophages than Enteritidis?**
   - Hypothesis: Typhimurium has more prophages (Gifsy, Fels)

2. **Are Gifsy-1/2 prophages still prevalent in modern Typhimurium?**
   - Track over 2020-2026

3. **Does prophage content correlate with MDR in Salmonella?**
   - Compare prophage burden in MDR vs susceptible strains

4. **Are virulence genes more often on prophages or plasmids?**
   - Categorize SopE, SodC1, etc. by location

5. **Do emerging serotypes (I 4,[5],12:i:-) have different prophage profiles?**
   - Compare to classic serotypes

6. **Is there evidence of phage-mediated AMR transfer in Salmonella?**
   - Look for AMR genes on prophages (rare but possible)

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
ls /fastscratch/tylerdoe/salmonella_temporal_phage_results/assemblies/*.fasta | wc -l

# Check SISTR (serotyping) progress
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/sistr -type f -name "*.tsv" | wc -l

# Check VIBRANT (prophage) progress
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/vibrant -type d -name "*_vibrant" | wc -l

# Check MOB-suite (plasmid) progress
find /fastscratch/tylerdoe/salmonella_temporal_phage_results/mobsuite -type d -name "*_mobsuite" | wc -l
```

## Data Retention

**Important:** Results will be ~1.8-2TB. After completion:

1. **Archive key results:**
   ```bash
   cd /fastscratch/tylerdoe/

   # Create compressed archive of essential results
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

2. **Clean up work directory (after confirming results):**
   ```bash
   rm -rf /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/work_salmonella_temporal_phage
   ```

## Citation

If you use this dataset in publications, cite:
- **COMPASS Pipeline**: Your pipeline DOI/GitHub
- **NCBI SRA**: BioProject PRJNA292661 (NARMS Salmonella)
- **All COMPASS tools**: AMRFinder+, VIBRANT, MOB-suite, MLST, SISTR, BUSCO, etc.

## Contact

For questions or issues:
- Create an issue on the COMPASS GitHub repository
- Email: tdoerks@vet.k-state.edu

## Changelog

- **2026-03-24**: Initial project creation
  - Target: Salmonella enterica monthly 50 (2020-2026)
  - Focus: Prophage-virulence-AMR dynamics by serotype
  - Expected samples: ~3,750
  - Complements Pseudomonas and Vibrio phage studies

---

*This project adds serotype diversity to temporal phage analysis, enabling comparison of prophage profiles across Salmonella serovars during a 6-year period.*
