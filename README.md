# COMPASS Pipeline

**COMPASS**: COmprehensive Mobile element & Pathogen ASsessment Suite

An integrated Nextflow pipeline for comprehensive bacterial genomic analysis combining antimicrobial resistance (AMR) detection and phage characterization.

## Overview

COMPASS automates the analysis of bacterial genomes, providing:

**Important:** This pipeline is designed for **Illumina short-read sequencing data** from **pure bacterial isolates only**. Metagenomic, transcriptomic, and long-read data (PacBio, Oxford Nanopore) are not supported.
- **Quality Control**: FastQC, fastp, BUSCO, QUAST, and MultiQC for comprehensive QC
- **Assembly Statistics**: Detailed metrics on assembly quality and contiguity
- **Strain Typing**: MLST for sequence type determination across 100+ species
- **Serotyping**: SISTR for Salmonella serovar prediction
- **Plasmid Detection**: MOB-suite for identifying and typing mobile genetic elements
- **AMR Detection**: AMRFinder+ and ABRicate for multi-database resistance screening
- **Phage Identification**: VIBRANT for prophage detection and lifestyle prediction (includes quality assessment)
- **Prophage Analysis**: DIAMOND database comparison for prophage classification
- **Gene Prediction**: PHANOTATE for ORF calling in phage sequences
- **Integrated Reporting**: MultiQC aggregation and COMPASS summary TSV with all metrics

## Features

- **Flexible Input**: Process assemblies, raw reads, or download directly from NCBI SRA
- **NARMS Integration**: Built-in metadata filtering for NARMS surveillance BioProjects
- **Containerized**: All tools run in Apptainer/Singularity containers for reproducibility
- **HPC Ready**: Configured for SLURM cluster execution
- **Comprehensive Output**: Enhanced reports combining AMR and phage data

## Pipeline Architecture

COMPASS uses a modular architecture with the following components:

### Subworkflows

1. **Data Acquisition** (`subworkflows/data_acquisition.nf`)
   - Downloads and filters NARMS metadata
   - Downloads SRA data from NCBI
   - Supports metadata filtering or direct SRR accession lists

2. **Assembly** (`subworkflows/assembly.nf`)
   - Raw read quality assessment with FastQC
   - Quality trimming with fastp
   - Genome assembly using SPAdes
   - Assembly quality assessment with BUSCO
   - Metadata integration for downstream analysis

3. **AMR Analysis** (`subworkflows/amr_analysis.nf`)
   - AMRFinder+ database download and management
   - Antimicrobial resistance gene detection

4. **Phage Analysis** (`subworkflows/phage_analysis.nf`)
   - VIBRANT prophage detection (with quality assessment)
   - DIAMOND prophage classification
   - PHANOTATE gene annotation

5. **Typing** (`subworkflows/typing.nf`)
   - MLST for strain typing (all bacteria)
   - SISTR for Salmonella serotyping (conditional)

6. **Mobile Elements** (`subworkflows/mobile_elements.nf`)
   - MOB-suite for plasmid detection and typing
   - Identification of mobile genetic elements

7. **Complete Pipeline** (`workflows/complete_pipeline.nf`)
   - Orchestrates all subworkflows
   - MultiQC for comprehensive QC reporting
   - Combines results for final reporting

## Quick Start

### Prerequisites

- Nextflow >= 24.04
- Apptainer/Singularity
- SLURM scheduler (or configure alternative executor)

### Installation

```bash
git clone https://github.com/tdoerks/COMPASS-pipeline.git
cd COMPASS-pipeline
```

### Database Setup

**IMPORTANT**: Before running the pipeline, set up required databases to avoid runtime download failures.

**Quick Setup (Recommended):**

```bash
# Set up BUSCO databases (one-time setup, ~15-30 minutes)
./bin/setup_busco_databases.sh \
    --download-path /fastscratch/$USER/databases/busco_downloads \
    --auto-lineage

# Verify prophage database exists (required)
ls -lh /path/to/prophage_db.dmnd
```

See [`docs/DATABASE_SETUP.md`](docs/DATABASE_SETUP.md) for comprehensive database setup instructions including:
- BUSCO lineage datasets and placement files
- Prophage database (DIAMOND format)
- AMRFinderPlus database (auto-downloaded)
- Troubleshooting common issues

**Quick Reference:**
- **BUSCO**: Pre-download recommended to avoid network issues (`bacteria_odb10` + placement files ~2 GB)
- **Prophage DB**: Required, must be provided (`prophage_db.dmnd` ~500 MB)
- **AMRFinder**: Auto-downloads on first run (~500 MB)

**Automatic Validation:**
The pipeline automatically validates all required databases before execution. If any databases are missing, it will fail immediately with clear setup instructions, preventing wasted compute time.

### Basic Usage

COMPASS supports three input modes:

#### 1. FASTA Mode (Default)
Analyze pre-assembled genomes from a samplesheet:

```bash
nextflow run main.nf --input samplesheet.csv --outdir results
```

**Samplesheet format (CSV):**
```csv
sample,organism,fasta
Sample1,Salmonella,/path/to/assembly1.fasta
Sample2,Escherichia,/path/to/assembly2.fasta
Sample3,Campylobacter,/path/to/assembly3.fasta
```

**Required columns:**
- `sample`: Unique sample identifier
- `organism`: Organism name (for AMRFinder+)
- `fasta`: Path to assembly file

#### 2. NARMS Metadata Mode
Download and filter NARMS BioProject data automatically:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292661,PRJNA292663,PRJNA292664" \
    --filter_state "KS" \
    --filter_year_start 2020 \
    --outdir results
```

**NARMS BioProjects:**
- **Campylobacter**: PRJNA292664
- **Salmonella**: PRJNA292661
- **E. coli**: PRJNA292663

**Note:** If no `--bioproject` parameter is specified, all three NARMS BioProjects are downloaded by default for backward compatibility.

#### 3. SRA List Mode
Process samples from a list of SRA accessions:

```bash
nextflow run main.nf \
    --input_mode sra_list \
    --input srr_accessions.txt \
    --outdir results
```

**SRA list format (TXT):**
```
SRR12345678
SRR12345679
SRR12345680
```

## Parameters

### Core Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `--input_mode` | Input mode: `fasta`, `metadata`, or `sra_list` | `fasta` | No |
| `--input` | Input file path (samplesheet CSV or SRR list TXT) | `samplesheet.csv` | Depends on mode |
| `--outdir` | Output directory | `results` | No |

### Metadata Filtering (for `metadata` mode)

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `--bioproject` | BioProject ID(s) - comma-separated | `null` (NARMS defaults) | `PRJNA292661`, `PRJNA123456,PRJNA789012` |
| `--species` | Species name filter (searches all SRA) | `null` | `Listeria`, `Campylobacter` |
| `--all_bacterial` | Download all bacterial samples (use with caution!) | `false` | `true` |
| `--filter_platform` | Sequencing platform filter (Illumina only) | `ILLUMINA` | `ILLUMINA` |
| `--filter_library_source` | Library source filter (isolates vs metagenomic) | `GENOMIC` | `GENOMIC`, `METAGENOMIC` |
| `--filter_state` | State code (2-letter) | `null` | `KS`, `CA`, `TX` |
| `--filter_year_start` | Minimum year | `null` | `2020` |
| `--filter_year_end` | Maximum year | `null` | `2023` |
| `--filter_source` | Source keyword | `null` | `chicken`, `clinical` |
| `--max_samples` | Maximum samples to process | `10000` | `5000`, `50000` |

**Important Notes:**
- **Platform Filtering**: The pipeline is designed for **Illumina short reads only**. By default, only ILLUMINA platform data is processed. Long-read platforms (PacBio, Oxford Nanopore) are automatically excluded.
- **Isolate Filtering**: By default, only **GENOMIC** library sources are processed (pure bacterial isolates). This automatically excludes metagenomic, transcriptomic, and environmental samples that are unsuitable for genome assembly. Set `--filter_library_source null` to disable this filter.
- **BioProject vs Species**: Use `--bioproject` for specific projects, or `--species` to search across all SRA data for a particular organism.
- **Default Behavior**: If no `--bioproject`, `--species`, or `--all_bacterial` is specified, the pipeline defaults to downloading all three NARMS BioProjects (Campylobacter, Salmonella, E. coli).

### Database Paths

| Parameter | Description | Setup |
|-----------|-------------|-------|
| `--amrfinder_db` | AMRFinder+ database directory | Auto-downloaded |
| `--prophage_db` | Prophage DIAMOND database (.dmnd) | See [DATABASE_SETUP.md](docs/DATABASE_SETUP.md) |
| `--busco_download_path` | BUSCO lineage datasets directory | Run `./bin/setup_busco_databases.sh` |

**Setup Script:**
```bash
./bin/setup_busco_databases.sh --download-path /fastscratch/$USER/databases/busco_downloads --auto-lineage
```

See [`docs/DATABASE_SETUP.md`](docs/DATABASE_SETUP.md) for detailed instructions.

### BUSCO Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--skip_busco` | Skip BUSCO quality assessment | `false` |
| `--busco_auto_lineage` | Auto-select best lineage for each genome | `true` (recommended) |
| `--busco_lineage` | Fixed lineage dataset (if auto-lineage=false) | `bacteria_odb10` |
| `--busco_mode` | BUSCO mode (genome, proteins, transcriptome) | `genome` |
| `--busco_download_path` | Path for BUSCO lineage datasets | See config |

## Output Structure

```
results/
├── metadata/                    # NARMS metadata (if filtering used)
│   ├── campylobacter_metadata.csv
│   ├── salmonella_metadata.csv
│   └── ecoli_metadata.csv
├── filtered_samples/            # Filtered sample lists
│   ├── filtered_samples.csv
│   ├── srr_accessions.txt
│   └── *_srr_list.txt
├── fastqc/                      # Raw read quality assessment
│   ├── *_fastqc.html
│   └── *_fastqc.zip
├── fastp/                       # Read quality control and trimming reports
│   ├── *_fastp.json
│   └── *_fastp.html
├── trimmed_fastq/               # Quality-trimmed reads
│   └── *_trimmed*.fastq.gz
├── assemblies/                  # Assembled genomes
│   └── *_scaffolds.fasta
├── busco/                       # Assembly quality assessment
│   └── *_busco/
│       ├── short_summary.*.txt
│       └── full_table.tsv
├── mlst/                        # Strain typing results
│   └── *_mlst.tsv
├── sistr/                       # Salmonella serotyping (if applicable)
│   └── *_sistr.tsv
├── mobsuite/                    # Plasmid detection and typing
│   └── *_mobsuite/
│       ├── mobtyper_results.txt
│       └── plasmid_*.fasta
├── amrfinder/                   # AMR detection results
│   ├── *_amr.tsv
│   └── *_mutations.tsv
├── vibrant/                     # Phage identification (includes quality assessment)
│   └── *_vibrant/
├── diamond_prophage/            # Prophage comparisons
│   └── *_diamond_results.tsv
├── phanotate/                   # Gene predictions
│   └── *_phanotate.gff
├── multiqc/                     # Comprehensive QC report
│   ├── multiqc_report.html
│   └── multiqc_data/
└── summary/                     # Integrated reports
    ├── phage_analysis_summary.tsv
    └── phage_analysis_report.html
```

## Output Files

### Summary Report (`summary/phage_analysis_summary.tsv`)

Tab-delimited file containing per-sample metrics:
- Total phages identified
- Lytic vs lysogenic counts
- Quality distribution (high/medium/low)
- Prophage database hits
- Best match identity
- Predicted gene counts

### HTML Report (`summary/phage_analysis_report.html`)

Interactive report with:
- Analysis overview statistics
- Quality distribution
- Detailed per-sample results table
- Tool version information

### Quality Control Reports

**FastQC** - Raw read quality assessment:
- `*_fastqc.html`: Interactive HTML report with per-base quality, GC content, adapter content, and more
- `*_fastqc.zip`: Archive containing all FastQC analysis files and plots

**fastp** - Trimming and post-QC reports:
- `*_fastp.html`: Interactive HTML report with quality metrics, filtering stats, and adapter detection
- `*_fastp.json`: Machine-readable JSON format with comprehensive QC data

These complementary tools provide before/after quality assessment for read trimming.

### Assembly Quality Assessment

**BUSCO** - Genome completeness and contamination:
- `short_summary.*.txt`: Summary statistics with percentages of complete, fragmented, and missing BUSCOs
- `full_table.tsv`: Detailed results for each BUSCO gene assessed
- Metrics include:
  - Complete and single-copy BUSCOs (C:S)
  - Complete and duplicated BUSCOs (C:D) - indicates potential contamination
  - Fragmented BUSCOs (F) - partial gene presence
  - Missing BUSCOs (M) - expected genes not found

### Strain Typing Results

**MLST** - Multi-locus sequence typing:
- `*_mlst.tsv`: Sequence type (ST) and allelic profile for each sample
- Automatically detects appropriate MLST scheme based on species
- Provides scheme name, ST number, and allele assignments

**SISTR** - Salmonella serotyping (Salmonella samples only):
- `*_sistr.tsv`: Serovar prediction, serogroup, H1/H2 antigens, and O antigens
- `*_sistr_allele.json`: Detailed allele calls and QC metrics
- Only runs on samples identified as Salmonella

### Mobile Elements Results

**MOB-suite** - Plasmid detection and typing:
- `mobtyper_results.txt`: Plasmid incompatibility groups and MOB types
- `plasmid_*.fasta`: Reconstructed plasmid sequences
- Identifies number of plasmids, types, and mobility characteristics

### AMRFinder Results

- `*_amr.tsv`: Detected resistance genes
- `*_mutations.tsv`: Point mutations conferring resistance

### MultiQC Report

- `multiqc_report.html`: Comprehensive HTML report aggregating all QC metrics
- `multiqc_data/`: Directory containing parsed data from all QC tools
- Includes FastQC, fastp, and BUSCO results in interactive visualizations

## Tools & Versions

| Tool | Version | Purpose |
|------|---------|---------|
| FastQC | 0.12.1 | Raw read quality assessment |
| fastp | 0.23.4 | Read quality trimming |
| SPAdes | 3.15.5 | Genome assembly |
| BUSCO | 5.7.1 | Assembly quality assessment |
| MLST | 2.23.0 | Multi-locus sequence typing |
| SISTR | 1.1.1 | Salmonella serotyping |
| MOB-suite | 3.1.9 | Plasmid detection and typing |
| AMRFinder+ | 3.12.8 | AMR gene detection |
| VIBRANT | 4.0 | Phage identification and quality assessment |
| DIAMOND | 2.0 | Prophage database search |
| PHANOTATE | 1.6.7 | Gene prediction |
| MultiQC | 1.25.1 | Aggregate QC reporting |

## Usage Examples

### NARMS-Specific Examples

These examples show how to work with NARMS surveillance data for common use cases:

#### Example 1: Kansas NARMS 2024 - All Three Organisms

Download all NARMS data (E. coli, Salmonella, Campylobacter) from Kansas for 2024:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292663,PRJNA292661,PRJNA292664" \
    --filter_state "KS" \
    --filter_year_start 2024 \
    --filter_year_end 2024 \
    --outdir results_ks_narms_2024
```

#### Example 2: Kansas NARMS 2024 - E. coli Only

Download only E. coli NARMS samples from Kansas for 2024:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292663" \
    --filter_state "KS" \
    --filter_year_start 2024 \
    --filter_year_end 2024 \
    --outdir results_ks_ecoli_2024
```

#### Example 3: Kansas NARMS 2024 - Salmonella Only

Download only Salmonella NARMS samples from Kansas for 2024:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292661" \
    --filter_state "KS" \
    --filter_year_start 2024 \
    --filter_year_end 2024 \
    --outdir results_ks_salmonella_2024
```

#### Example 4: Kansas NARMS 2024 - Campylobacter Only

Download only Campylobacter NARMS samples from Kansas for 2024:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292664" \
    --filter_state "KS" \
    --filter_year_start 2024 \
    --filter_year_end 2024 \
    --outdir results_ks_campy_2024
```

#### Example 5: California NARMS Salmonella - Clinical Sources

Download NARMS Salmonella from California, filtering for clinical isolates:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292661" \
    --filter_state "CA" \
    --filter_source "clinical" \
    --outdir results_ca_salmonella_clinical
```

#### Example 6: Multi-Year NARMS Analysis

Download Kansas NARMS data across multiple years (2020-2023):

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA292663,PRJNA292661,PRJNA292664" \
    --filter_state "KS" \
    --filter_year_start 2020 \
    --filter_year_end 2023 \
    --outdir results_ks_narms_2020-2023
```

### General Usage Examples

#### Example 7: Pre-assembled FASTA files (default mode)

Analyze pre-assembled genomes from a samplesheet:

```bash
nextflow run main.nf \
    --input my_samples.csv \
    --outdir my_analysis
```

#### Example 8: Search by Species Across All SRA

Download and analyze all Listeria samples from SRA (non-NARMS):

```bash
nextflow run main.nf \
    --input_mode metadata \
    --species "Listeria monocytogenes" \
    --filter_year_start 2020 \
    --outdir results_listeria
```

#### Example 9: Custom BioProject

Analyze samples from a custom BioProject:

```bash
nextflow run main.nf \
    --input_mode metadata \
    --bioproject "PRJNA123456" \
    --outdir results_custom_project
```

#### Example 10: Process specific SRA accessions (sra_list mode)

Process a specific list of SRA accessions:

```bash
nextflow run main.nf \
    --input_mode sra_list \
    --input my_srr_list.txt \
    --outdir sra_analysis
```

## Directory Structure

```
COMPASS-pipeline/
├── main.nf                      # Main entry point
├── nextflow.config              # Pipeline configuration
├── modules/                     # Individual process definitions
│   ├── amrfinder.nf            # AMR detection
│   ├── assembly.nf             # Genome assembly
│   ├── busco.nf                # Assembly QC
│   ├── checkv.nf               # Phage quality control
│   ├── combine_results.nf      # Results aggregation
│   ├── diamond_prophage.nf     # Prophage classification
│   ├── fastp.nf                # Read trimming
│   ├── fastqc.nf               # Read QC
│   ├── metadata_filtering.nf   # NARMS data filtering
│   ├── mlst.nf                 # Strain typing
│   ├── mobsuite.nf             # Plasmid detection
│   ├── multiqc.nf              # Aggregate QC reporting
│   ├── phanotate.nf            # Gene prediction
│   ├── sistr.nf                # Salmonella serotyping
│   ├── sra_download.nf         # SRA data download
│   └── vibrant.nf              # Phage detection
├── subworkflows/                # Logical workflow components
│   ├── data_acquisition.nf     # Data download/filtering
│   ├── assembly.nf             # Assembly workflow with QC
│   ├── amr_analysis.nf         # AMR workflow
│   ├── phage_analysis.nf       # Phage workflow
│   ├── typing.nf               # MLST and serotyping
│   └── mobile_elements.nf      # Plasmid detection
└── workflows/                   # High-level workflows
    ├── complete_pipeline.nf    # Main orchestration workflow
    ├── integrated_analysis.nf  # Legacy combined analysis
    ├── full_pipeline.nf        # Legacy full pipeline
    └── metadata_to_results.nf  # Legacy metadata workflow
```

## Configuration

Edit `nextflow.config` to customize:
- Resource allocation (CPUs, memory)
- Container paths
- Database locations
- Executor settings (SLURM parameters)

## Citation

If you use COMPASS, please cite the individual tools:

**Quality Control:**
- **FastQC**: [Andrews, 2010](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- **fastp**: [Chen et al., 2018](https://doi.org/10.1093/bioinformatics/bty560)
- **BUSCO**: [Manni et al., 2021](https://doi.org/10.1007/978-1-4939-9173-0_14)
- **MultiQC**: [Ewels et al., 2016](https://doi.org/10.1093/bioinformatics/btw354)

**Assembly:**
- **SPAdes**: [Bankevich et al., 2012](https://doi.org/10.1089/cmb.2012.0021)

**Typing & Characterization:**
- **MLST**: [Seemann, 2014](https://github.com/tseemann/mlst)
- **SISTR**: [Yoshida et al., 2016](https://doi.org/10.1371/journal.pone.0147101)
- **MOB-suite**: [Robertson & Nash, 2018](https://doi.org/10.1099/mgen.0.000206)

**Resistance & Virulence:**
- **AMRFinder+**: [Feldgarden et al., 2021](https://www.nature.com/articles/s41598-021-91456-0)
- **Prophage-AMR Intersection**: [Pinto et al., 2024](https://doi.org/10.3390/genes16050656) - Identifies AMR genes within prophage regions

**Phage Analysis:**
- **VIBRANT**: [Kieft et al., 2020](https://microbiomejournal.biomedcentral.com/articles/10.1186/s40168-020-00990-y)
- **DIAMOND**: [Buchfink et al., 2021](https://www.nature.com/articles/s41592-021-01101-x)
- **PHANOTATE**: [McNair et al., 2019](https://academic.oup.com/bioinformatics/article/35/22/4537/5480131)

## License

MIT License

## Contributing

Issues and pull requests welcome at: https://github.com/tdoerks/COMPASS-pipeline

## Contact

- **Issues**: https://github.com/tdoerks/COMPASS-pipeline/issues
- **Author**: Tyler Doerksen (@tdoerks)

## Acknowledgments

Developed for bacterial genomics surveillance and characterization, with initial focus on NARMS data analysis.
