# Diverse Bacterial Pathogen Analysis - 1,000 Samples

## Overview

This project analyzes **1,000 bacterial genome samples** spanning **20 different pathogenic species** to create a comprehensive comparative genomics dataset.

### Objectives
- **Taxonomic diversity**: 50 samples per organism × 20 organisms
- **Comparative AMR**: Antimicrobial resistance patterns across species
- **Plasmid distribution**: Mobile genetic elements by organism
- **Prophage diversity**: Phage integration patterns
- **MLST coverage**: Sequence type diversity assessment

## Target Organisms (50 samples each)

### Foodborne Pathogens
1. **Listeria monocytogenes** - Cold-tolerant, surveillance priority
2. **Vibrio parahaemolyticus** - Seafood-associated
3. **Yersinia enterocolitica** - Cold-tolerant enteropathogen
4. **Shigella sonnei** - Most common Shigella in developed countries
5. **Clostridium perfringens** - Spore-former, enterotoxin producer
6. **Bacillus cereus** - Emetic and diarrheal syndromes
7. **Cronobacter sakazakii** - Infant formula contamination
8. **Campylobacter coli** - Complement to C. jejuni
9. **Arcobacter butzleri** - Emerging zoonotic pathogen

### Clinical Pathogens
10. **Staphylococcus aureus** - MRSA tracking
11. **Enterococcus faecium** - VRE concern
12. **Klebsiella pneumoniae** - Carbapenem resistance
13. **Acinetobacter baumannii** - MDR nosocomial
14. **Pseudomonas aeruginosa** - Biofilms, cystic fibrosis
15. **Citrobacter freundii** - Opportunistic infections
16. **Enterobacter cloacae** - Nosocomial AMR
17. **Proteus mirabilis** - UTI pathogen
18. **Serratia marcescens** - Nosocomial infections
19. **Vibrio cholerae** - Epidemic potential
20. **Helicobacter pylori** - Gastric ulcers, cancer

## Project Structure

```
diverse_bacteria_1000/
├── README.md                          # This file
├── scripts/
│   ├── organism_targets.txt           # List of 20 target organisms
│   ├── download_diverse_bacteria.py   # Download SRR accessions from NCBI
│   └── create_samplesheet.py          # Generate COMPASS input
├── data/
│   ├── srr_accessions_by_organism/    # Individual organism SRR lists
│   └── combined_srr_list.txt          # All 1,000 SRRs
├── samplesheet_diverse_1000.txt       # COMPASS pipeline input
└── run_diverse_bacteria_1000.sh       # SLURM submission script
```

## Usage Instructions

### Step 1: Download SRA Accessions

Run on any machine with Python and internet access (including Beocat):

```bash
cd diverse_bacteria_1000/

# Download accessions using HTTP API (takes ~10-15 minutes)
# No EDirect module needed - just Python with 'requests' library
python3 scripts/download_diverse_bacteria.py

# Check results
ls -lh data/srr_accessions_by_organism/
cat data/combined_srr_list.txt | wc -l
```

**What this does:**
- Queries NCBI SRA via HTTP API (same approach as `fetch_ecoli_monthly_v2.py`)
- Downloads only SRR accession lists (~few KB total, NOT sequencing data)
- COMPASS pipeline will download actual FASTQ files later on Beocat

**Expected output:**
- `data/srr_accessions_by_organism/`: 20 files (one per organism)
- `data/combined_srr_list.txt`: ~1,000 total SRR accessions

### Step 2: Generate Samplesheet

```bash
# Create samplesheet for COMPASS
python scripts/create_samplesheet.py

# Verify
head samplesheet_diverse_1000.txt
wc -l samplesheet_diverse_1000.txt
```

### Step 3: Run COMPASS Pipeline

On Beocat:

```bash
# Submit job
sbatch run_diverse_bacteria_1000.sh

# Monitor
squeue -u $USER
tail -f /fastscratch/tylerdoe/slurm-diverse-bacteria-1000-<JOBID>.out
```

**Runtime estimate:** 5-7 days for 1,000 samples

**Resource usage:**
- CPUs: 8 per job
- Memory: 32GB
- Storage: ~500GB for results

## Expected Results

```
/fastscratch/tylerdoe/diverse_bacteria_1000_results/
├── fastqc/          # Raw read QC
├── fastp/           # Trimmed reads QC
├── assemblies/      # SPAdes assemblies
├── busco/           # Assembly quality
├── quast/           # Assembly statistics
├── mlst/            # Sequence typing
├── sistr/           # Salmonella serotyping (if applicable)
├── mobsuite/        # Plasmid detection
├── amrfinder/       # AMR genes (AMRFinderPlus)
├── abricate/        # Multi-database AMR screening
├── vibrant/         # Prophage detection
├── diamond_prophage/# Prophage classification
├── phanotate/       # Phage gene prediction
├── multiqc/         # Comprehensive QC report
└── summary/         # COMPASS integrated summary
```

## Analysis Ideas

### 1. **Cross-Organism AMR Comparison**
- Which organisms carry the most AMR genes?
- Are certain resistance mechanisms organism-specific?
- Carbapenem resistance distribution

### 2. **Plasmid Diversity**
- Plasmid incompatibility groups by organism
- MOB-suite plasmid typing patterns
- Shared plasmids across species?

### 3. **Prophage Distribution**
- Which organisms have the most prophages?
- Quality scores (VIBRANT/CheckV)
- Lifestyle predictions (lytic vs lysogenic)

### 4. **MLST Diversity**
- Sequence type richness per organism
- Novel STs discovered?
- Geographic distribution of STs

### 5. **Genome Quality Assessment**
- BUSCO completeness by organism
- Assembly statistics (N50, contigs)
- Identify high-quality reference genomes

### 6. **Serotype Diversity** (organism-specific)
- *S. aureus*: spa typing
- *E. faecium*: vancomycin resistance types
- *K. pneumoniae*: K-locus types

## Troubleshooting

### Not enough samples for an organism?

Edit `scripts/organism_targets.txt` and reduce target count, or substitute organism:

```bash
nano scripts/organism_targets.txt
# Change: Helicobacter pylori|50| to |30|
# Or replace with: Streptococcus pneumoniae|50|
```

### Download script fails?

Check Python and requests library:
```bash
python3 --version  # Should be Python 3.6+
python3 -c "import requests; print('requests OK')"

# If requests missing, install:
pip install requests
# or on Beocat: pip3 install --user requests
```

### Pipeline runs slowly?

This is expected for 1,000 samples. Monitor progress:
```bash
# Check how many assemblies completed
ls /fastscratch/tylerdoe/diverse_bacteria_1000_results/assemblies/*.fasta | wc -l

# Check current work directory size
du -sh /fastscratch/tylerdoe/COMPASS-pipeline/work_diverse_bacteria_1000
```

## Data Retention

**Important:** Results will be large (~500GB). After completion:

1. **Archive to long-term storage:**
   ```bash
   cd /fastscratch/tylerdoe/
   tar -czf diverse_bacteria_1000_results.tar.gz diverse_bacteria_1000_results/
   mv diverse_bacteria_1000_results.tar.gz /homes/tylerdoe/archives/
   ```

2. **Clean up work directory:**
   ```bash
   rm -rf /fastscratch/tylerdoe/COMPASS-pipeline/work_diverse_bacteria_1000
   ```

3. **Keep key outputs:**
   - MultiQC report
   - COMPASS summary TSV
   - MLST results
   - AMR results
   - MOB-suite results

## Citation

If you use this dataset in publications, cite:
- **COMPASS Pipeline**: Your pipeline DOI/GitHub
- **NCBI SRA**: Individual BioProjects used
- **All COMPASS tools**: AMRFinder+, VIBRANT, MOB-suite, MLST, etc.

## Contact

For questions or issues:
- Create an issue on the COMPASS GitHub repository
- Email: tdoerks@vet.k-state.edu

## Changelog

- **2026-03-07**: Initial project setup with 20 target organisms
