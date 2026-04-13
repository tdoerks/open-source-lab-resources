# Fusobacterium necrophorum Comprehensive Prophage Study

## Overview

This project analyzes **all available Fusobacterium necrophorum WGS genomes (~600)** from NCBI SRA to conduct a comprehensive study of **prophage burden, subspecies diversity, and mobile genetic element dynamics** in this important anaerobic pathogen.

### Why Fusobacterium necrophorum?

- **Veterinary importance**: Causes liver abscesses in cattle, foot rot in sheep
- **Human pathogen**: Lemierre's syndrome, necrobacillosis
- **Subspecies diversity**: F. necrophorum subsp. *necrophorum* vs *funduliforme*
- **Anaerobic pathogen**: Different from aerobic organisms in other phage studies
- **Recent prophage research**: 2023 paper "Characterizing prophages in the genus Fusobacterium"
- **Novel phage isolation**: Multiple 2024 papers on F. necrophorum bacteriophages
- **Research gap**: Limited comparative genomics on prophage dynamics
- **Host diversity**: Bovine, human, ovine, and other animal sources

### Research Objectives

1. **Quantify prophage burden** in F. necrophorum across all available genomes
2. **Compare prophage profiles** between subspecies (*necrophorum* vs *funduliforme*)
3. **Analyze host-specific patterns** (bovine vs human vs other sources)
4. **Identify prophage-plasmid interactions** and mobile element dynamics
5. **Characterize virulence gene mobility** on prophages vs plasmids vs chromosomes
6. **Assess AMR distribution** across subspecies and host sources
7. **Compare to other phage-rich organisms** (Pseudomonas, Salmonella, Vibrio)
8. **MLST diversity** and population structure

## Sampling Strategy

**ALL available Fusobacterium necrophorum WGS Illumina genomes (~600 total)**

- **Organism**: *Fusobacterium necrophorum* (all subspecies)
- **Data source**: NCBI SRA (all WGS Illumina GENOMIC samples)
- **Sample selection**: Comprehensive (all available)
- **Expected subspecies distribution**:
  - F. necrophorum subsp. *necrophorum*: ~60-70%
  - F. necrophorum subsp. *funduliforme*: ~30-40%
- **Host sources** (if metadata available):
  - Bovine (cattle liver abscesses)
  - Human (Lemierre's syndrome, oral/pharyngeal)
  - Ovine (foot rot)
  - Other animal sources

## Project Structure

```
fusobacterium_necrophorum_study/
├── README.md                                           # This file
├── scripts/
│   ├── fetch_fusobacterium_necrophorum.py             # Download ALL SRR accessions
│   └── create_samplesheet.py                           # Generate COMPASS samplesheet
├── run_fusobacterium_necrophorum.sh                   # SLURM submission script
└── data/                                               # Created during download
    ├── sra_accessions_fusobacterium_necrophorum_all.txt
    └── samplesheet_fusobacterium_necrophorum.txt
```

## Usage Instructions

### Step 1: Download SRA Accessions

Run on any machine with Python and internet (including Beocat):

```bash
cd fusobacterium_necrophorum_study/

# Download ALL F. necrophorum accessions using HTTP API (~5-10 minutes)
python3 scripts/fetch_fusobacterium_necrophorum.py

# Verify
cat data/sra_accessions_fusobacterium_necrophorum_all.txt | wc -l  # Should be ~600
```

**What this does:**
- Queries NCBI SRA via HTTP API for ALL F. necrophorum samples
- Search: "Fusobacterium necrophorum"[Organism] + Illumina + WGS + GENOMIC
- Downloads only SRR accession lists (small file), NOT sequencing data
- COMPASS pipeline downloads actual FASTQ files later on Beocat

### Step 2: Generate Samplesheet

```bash
# Create samplesheet for COMPASS
python3 scripts/create_samplesheet.py

# Verify
head data/samplesheet_fusobacterium_necrophorum.txt
wc -l data/samplesheet_fusobacterium_necrophorum.txt
```

### Step 3: Run COMPASS Pipeline

On Beocat:

```bash
# Copy project to COMPASS pipeline directory
cp -r fusobacterium_necrophorum_study /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/

# Navigate and submit
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/fusobacterium_necrophorum_study
sbatch run_fusobacterium_necrophorum.sh

# Monitor
squeue -u $USER
tail -f /fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-<JOBID>.out
```

**Runtime estimate:** 4-7 days for ~600 samples

**Resource usage:**
- CPUs: 8 per job
- Memory: 32-64GB (SPAdes)
- Time limit: 168 hours (7 days, with resume capability)
- Storage: ~350-500GB for results

## Expected Results

```
/fastscratch/tylerdoe/fusobacterium_necrophorum_results/
├── fastqc/              # Raw read QC
├── fastp/               # Trimmed reads QC
├── assemblies/          # SPAdes assemblies
├── busco/               # Assembly quality (genome completeness)
├── quast/               # Assembly statistics (N50, contigs, etc.)
├── mlst/                # 🔥 Multi-locus sequence typing (KEY - diversity)
├── mobsuite/            # 🔥 Plasmid detection and typing (KEY FOR ANALYSIS)
├── amrfinder/           # 🔥 AMR + virulence genes (KEY FOR ANALYSIS)
├── abricate/            # Multi-database AMR/virulence screening
├── vibrant/             # 🔥 Prophage detection (KEY FOR ANALYSIS)
├── diamond_prophage/    # Prophage classification
├── phanotate/           # Phage gene prediction
├── multiqc/             # Comprehensive QC report
└── summary/             # COMPASS integrated summary
```

## Analysis Roadmap

### Phase 1: Data Quality & Basic Characterization
1. **BUSCO completeness** (genome quality, anaerobe-specific database)
2. **Assembly statistics** (N50, contigs, genome size ~2.2-2.4 Mb)
3. **MLST diversity** (subspecies clustering)
4. **Sample metadata** (subspecies, host source if available)
5. **Identify high-quality samples** (>90% BUSCO completeness)

### Phase 2: Prophage Burden Analysis
1. **Quantify prophage prevalence**
   - Overall prophage counts per genome
   - VIBRANT quality scores
   - Prophage lifestyle predictions (lysogenic vs lytic)
   - Intact vs partial prophages

2. **Subspecies comparison**
   - Prophage burden: *necrophorum* vs *funduliforme*
   - Prophage diversity by subspecies
   - Novel prophages vs known families

3. **Host source analysis** (if metadata available)
   - Bovine vs human vs ovine prophage profiles
   - Clinical vs environmental isolates

4. **Compare to other organisms**
   - F. necrophorum vs Pseudomonas (5-10 prophages/genome)
   - F. necrophorum vs Salmonella (3-7 prophages/genome)
   - F. necrophorum vs Vibrio (CTXφ + accessory)
   - Where does F. necrophorum fall on the prophage burden spectrum?

### Phase 3: Prophage Characterization
1. **Prophage families and clusters**
   - Sequence similarity clustering
   - Identify common vs rare prophage types
   - Compare to known F. necrophorum phages from recent literature

2. **Prophage genes and function**
   - PHANOTATE gene predictions
   - DIAMOND prophage database hits
   - Identify prophage-encoded genes (virulence, toxins, etc.)

### Phase 4: Plasmid Analysis
1. **Plasmid prevalence and distribution**
   - MOB-suite incompatibility groups
   - Plasmid typing across subspecies
   - Plasmid size distribution

2. **Plasmid-prophage interactions**
   - Co-occurrence patterns
   - Samples with high prophage + plasmid burden
   - Shared mobile element signatures

### Phase 5: Virulence Gene Analysis
1. **Categorize virulence genes by location**
   - Chromosomal (core genome)
   - Plasmid-associated (MOB-suite hits)
   - Prophage-associated (VIBRANT hits)

2. **F. necrophorum-specific virulence factors**
   - Leukotoxin (lktA) - major virulence factor
   - Hemagglutinin
   - Other known virulence genes
   - Location analysis (chromosome vs mobile element)

3. **Subspecies virulence comparison**
   - Virulence gene differences between *necrophorum* and *funduliforme*

### Phase 6: AMR Gene Analysis
1. **Categorize AMR genes by location**
   - Chromosomal
   - Plasmid-associated
   - Prophage-associated (rare but possible)

2. **AMR distribution across subspecies**
   - Resistance patterns in *necrophorum* vs *funduliforme*
   - Multi-drug resistance profiles

3. **Mobile element-mediated AMR**
   - Which AMR genes are on plasmids?
   - Evidence of AMR on prophages?

### Phase 7: Population Structure
1. **MLST-based phylogeny**
   - Subspecies clustering
   - Population structure
   - Genetic diversity

2. **Geographic distribution** (if metadata available)
   - Regional differences
   - Host-specific lineages

### Phase 8: Comparative Analysis
1. **Cross-organism prophage comparison**
   - F. necrophorum (anaerobe) vs aerobic pathogens
   - Prophage-plasmid-AMR patterns across organisms
   - Anaerobe-specific prophage biology

2. **Publication-ready figures**
   - Prophage burden comparison (F. necrophorum vs others)
   - Subspecies prophage profiles (heatmap)
   - Virulence gene mobility (pie chart)
   - MLST phylogeny with prophage/plasmid annotations
   - Prophage-plasmid co-occurrence network

## Key Analysis Questions

### Prophage Burden
1. **How many prophages does F. necrophorum carry on average?**
   - Hypothesis: Moderate burden (2-5 prophages/genome)

2. **Do subspecies differ in prophage content?**
   - Hypothesis: *necrophorum* has more prophages than *funduliforme*

3. **How does F. necrophorum compare to other pathogens?**
   - Position on the prophage burden spectrum

### Virulence
4. **Is leukotoxin (lktA) ever on prophages or plasmids?**
   - Expected: chromosomal, but mobile elements should be checked

5. **Are there prophage-encoded virulence factors?**
   - Look for toxins, adhesins, immune evasion genes

### Mobile Elements
6. **What is the prophage-plasmid co-occurrence rate?**
   - Do samples with many prophages also carry more plasmids?

7. **Is there evidence of phage-mediated HGT?**
   - Shared genes between prophages and plasmids

### Clinical Relevance
8. **Do bovine and human isolates differ in prophage profiles?**
   - Host-specific prophage adaptations

9. **Is AMR linked to mobile elements in F. necrophorum?**
   - Plasmid-mediated resistance vs chromosomal

## Known F. necrophorum Biology

### Subspecies
- **F. necrophorum subsp. *necrophorum***
  - More virulent
  - Leukotoxin production
  - Bovine liver abscesses, human Lemierre's syndrome

- **F. necrophorum subsp. *funduliforme***
  - Less virulent
  - Lower leukotoxin levels
  - Oral/pharyngeal infections

### Virulence Factors
- **Leukotoxin (LktA)**: Major virulence factor, kills leukocytes
- **Hemagglutinin**: Adhesion
- **Lipopolysaccharide (LPS)**: Endotoxin
- **Hemolysins**: Tissue damage

### Recent Phage Research
- **2023**: "Characterizing prophages in the genus Fusobacterium" (ScienceDirect)
- **2024**: Novel F. necrophorum bacteriophage isolation studies
- **Active research area**: Prophage biology in Fusobacterium

## Comparison to Other Studies

| Feature | Pseudomonas | Vibrio | Salmonella | Fusobacterium 🆕 |
|---------|-------------|---------|------------|-----------------|
| **Organism** | P. aeruginosa | V. cholerae | S. enterica | F. necrophorum |
| **Samples** | ~3,750 | 2,787 | ~3,750 | ~600 |
| **Focus** | Temporal phage-AMR | Geographic + temporal | Serotype + temporal | Comprehensive + subspecies |
| **Time period** | Monthly 2020-2026 | Monthly 2020-2026 | Monthly 2020-2026 | All available |
| **Prophage burden** | Very high (5-10/genome) | High (CTXφ + others) | High (3-7/genome) | Unknown (to be determined) |
| **Strength** | Highest phage content | Epidemic dynamics | Serotype diversity | Anaerobe, subspecies |
| **Special feature** | CF pathogen, XDR | Geographic spread | Foodborne + clinical | Veterinary + human |
| **Typing system** | MLST | MLST | MLST + SISTR | MLST |
| **Unique analysis** | Phage-plasmid-AMR | Geographic AMR | Serotype-virulence | Subspecies + host source |
| **Metabolism** | Aerobic | Facultative anaerobe | Facultative anaerobe | **Obligate anaerobe** |

## Troubleshooting

### Download script fails?

Check Python and requests library:
```bash
python3 --version  # Should be Python 3.6+
python3 -c "import requests; print('requests OK')"

# If requests missing:
pip3 install --user requests
```

### Fewer samples than expected?

F. necrophorum has fewer publicly available genomes than Salmonella or Pseudomonas. This is normal for veterinary anaerobes. We'll analyze whatever is available (~600 is still a substantial dataset).

### Pipeline runs slowly?

Monitor progress:
```bash
# Check completed assemblies
ls /fastscratch/tylerdoe/fusobacterium_necrophorum_results/assemblies/*.fasta | wc -l

# Check VIBRANT (prophage) progress
find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/vibrant -type d -name "*_vibrant" | wc -l

# Check MOB-suite (plasmid) progress
find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/mobsuite -type d -name "*_mobsuite" | wc -l
```

## Data Retention

**Important:** Results will be ~350-500GB. After completion:

1. **Archive key results:**
   ```bash
   cd /fastscratch/tylerdoe/

   # Create compressed archive of essential results
   tar -czf fusobacterium_necrophorum_key_results.tar.gz \
       fusobacterium_necrophorum_results/mlst/ \
       fusobacterium_necrophorum_results/vibrant/ \
       fusobacterium_necrophorum_results/mobsuite/ \
       fusobacterium_necrophorum_results/amrfinder/ \
       fusobacterium_necrophorum_results/multiqc/ \
       fusobacterium_necrophorum_results/summary/

   # Move to long-term storage
   mv fusobacterium_necrophorum_key_results.tar.gz /bulk/tylerdoe/archives/
   ```

2. **Clean up work directory (after confirming results):**
   ```bash
   rm -rf /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/work_fusobacterium_necrophorum
   ```

## Publication Potential

### Individual Paper
**"Comprehensive prophage analysis reveals subspecies-specific mobile element dynamics in Fusobacterium necrophorum"**

- First large-scale prophage study in F. necrophorum (~600 genomes)
- Subspecies comparison (*necrophorum* vs *funduliforme*)
- Prophage burden quantification
- Virulence gene mobility (leukotoxin and others)
- Compare to aerobic pathogens (anaerobe-specific prophage biology?)

### Comparative Paper
**"Prophage-plasmid-AMR interactions across aerobic and anaerobic bacterial pathogens: A multi-organism analysis"**

- Include F. necrophorum (anaerobe) vs Pseudomonas, Salmonella, Vibrio (aerobes)
- Universal vs organism-specific prophage dynamics
- Metabolism-specific patterns (aerobic vs anaerobic prophage biology)

## Citation

If you use this dataset in publications, cite:
- **COMPASS Pipeline**: (your pipeline DOI/GitHub)
- **NCBI SRA**: All F. necrophorum BioProjects
- **COMPASS tools**: AMRFinder+, VIBRANT, MOB-suite, MLST, BUSCO, etc.
- **Recent F. necrophorum prophage paper**: "Characterizing prophages in the genus Fusobacterium" (2023)

## Contact

For questions or issues:
- Create an issue on the COMPASS GitHub repository
- Email: tdoerks@vet.k-state.edu

## Changelog

- **2026-04-13**: Initial project creation
  - Target: Fusobacterium necrophorum (ALL available genomes ~600)
  - Focus: Prophage burden, subspecies comparison, anaerobe pathogen
  - Complements Pseudomonas, Salmonella, and Vibrio phage studies
  - Adds first obligate anaerobe to phage-rich organism series

---

*This project adds an anaerobic pathogen to the phage-rich organism study series, enabling comparison of prophage dynamics between aerobic and anaerobic bacteria with veterinary and human health importance.*
