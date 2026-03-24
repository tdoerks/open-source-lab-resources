# Phage-Rich Organism Study Series

## Overview

A comprehensive temporal analysis series focusing on organisms with **high prophage burdens** to study prophage-plasmid-AMR interactions across different bacterial pathogens.

## Completed Studies

### 1. Pseudomonas aeruginosa Phage Hunter ✅
- **Status**: COMPLETED
- **Samples**: ~3,750 genomes (50/month, Jan 2020 - Mar 2026)
- **Prophage burden**: **5-10 prophages/genome** (HIGHEST)
- **Focus**: Temporal phage-plasmid-AMR dynamics
- **Unique features**:
  - CF pathogen, XDR/MDR crisis organism
  - Biofilm formation
  - Highest prophage content of any bacteria studied
- **Location**: `pseudomonas_phage_hunter_monthly/`

### 2. Vibrio cholerae Geographic + Temporal ✅
- **Status**: COMPLETED (or running job 7194213)
- **Samples**: 2,787 genomes (50/month, Jan 2020 - Mar 2026)
- **Prophage burden**: **High** (CTXφ + accessory prophages)
- **Focus**: Geographic + temporal epidemic dynamics
- **Unique features**:
  - Epidemic pathogen (cholera)
  - CTXφ prophage encodes cholera toxin
  - Geographic spread across endemic regions
  - SXT/R391 ICE (integrative conjugative element)
- **Location**: `vibrio_cholerae_temporal_geographic/`

### 3. Diverse Bacteria 1000 ✅
- **Status**: COMPLETED
- **Samples**: 1,000 genomes (50 per organism × 20 organisms)
- **Prophage burden**: **Variable** (baseline comparison)
- **Focus**: Cross-species AMR, plasmid, prophage diversity
- **Purpose**: Establish prophage baseline across 20 pathogens
- **Location**: `diverse_bacteria_1000/`

## New Study: Salmonella enterica

### 4. Salmonella Prophage Dynamics - Multi-Serotype Temporal 🆕
- **Status**: READY TO LAUNCH
- **Samples**: ~3,750 genomes (50/month, Jan 2020 - Mar 2026)
- **Prophage burden**: **High** (3-7 prophages/genome)
- **Focus**: Prophage-virulence-AMR dynamics by serotype
- **Unique features**:
  - **Serotype diversity**: 2,500+ serovars
  - **Well-characterized prophages**: Gifsy-1/2, P22, ST64B, Fels-1/2
  - **Prophage-encoded virulence**: SopE, SodC1, GogB on prophages
  - **Clinical + foodborne**: #1 bacterial foodborne pathogen
  - **SISTR serotyping**: Automated serovar identification
  - **Compare serotypes**: Typhimurium vs Enteritidis vs Newport
- **Location**: `salmonella_temporal_phage/`

## Study Comparison Matrix

| Feature | Pseudomonas | Vibrio | Salmonella |
|---------|-------------|---------|------------|
| **Samples** | ~3,750 | 2,787 | ~3,750 |
| **Prophage burden** | 5-10/genome (highest) | High (CTXφ) | 3-7/genome (high) |
| **Time resolution** | Monthly (75 pts) | Monthly (75 pts) | Monthly (75 pts) |
| **Special typing** | MLST | MLST | MLST + SISTR serotyping |
| **Clinical relevance** | CF, nosocomial | Epidemic cholera | Foodborne + clinical |
| **AMR focus** | XDR/MDR emergence | Geographic spread | Serotype-specific MDR |
| **Unique analysis** | Highest phage content | Geographic clustering | Serotype comparison |
| **Known prophages** | Varied | CTXφ, SXT/R391 | Gifsy, P22, Fels |
| **Virulence on prophages** | Yes (various) | Yes (cholera toxin) | Yes (SopE, SodC1) |

## Research Questions Across Studies

### Shared Questions (All 3 Studies)
1. How does prophage prevalence change over time (2020-2026)?
2. What are plasmid-prophage co-occurrence patterns?
3. How do AMR genes move (chromosome vs plasmid vs prophage)?
4. Can we detect phage-mediated HGT events temporally?
5. How does XDR/MDR emergence relate to mobile elements?

### Organism-Specific Questions

#### Pseudomonas
- Why does Pseudomonas have the highest prophage burden?
- Do prophages contribute to biofilm formation?
- Phage-plasmid interactions in CF isolates?

#### Vibrio
- CTXφ prophage prevalence by geographic region?
- Temporal epidemic waves per region?
- SXT/R391 ICE distribution across endemic zones?

#### Salmonella (NEW)
- Do Typhimurium strains carry more prophages than Enteritidis?
- Are Gifsy-1/2 prophages still prevalent in modern Typhimurium?
- Does prophage content correlate with MDR by serotype?
- Are virulence genes more often on prophages or plasmids?
- Do emerging serotypes (I 4,[5],12:i:-) have different prophage profiles?

## Comparative Analysis Opportunities

### Cross-Organism Prophage Comparison
- **Highest to lowest prophage burden**: Pseudomonas > Salmonella > Vibrio
- **Prophage-encoded virulence**: All three have critical virulence genes on prophages
- **AMR on prophages**: Rare but potentially detectable in all three

### Temporal Dynamics
- All three studies span 2020-2026 (75 monthly time points)
- Enable comparison of prophage dynamics across organisms
- Detect universal vs organism-specific trends

### Mobile Element Interactions
- Compare prophage-plasmid co-occurrence across organisms
- Which organism shows strongest prophage-plasmid association?
- AMR gene mobility patterns (chromosome/plasmid/prophage)

## Publication Potential

### Individual Papers
1. **Pseudomonas**: "Temporal dynamics of prophage burden in the world's most phage-rich bacterial pathogen"
2. **Vibrio**: "Geographic spread of CTXφ prophage and AMR in Vibrio cholerae (2020-2026)"
3. **Salmonella**: "Serotype-specific prophage profiles and virulence gene mobility in Salmonella enterica"

### Comparative Paper
4. **Multi-organism comparison**: "Prophage-plasmid-AMR interactions across three high-prophage-burden bacterial pathogens: A temporal analysis (2020-2026)"

## Next Steps for Salmonella Study

### On Beocat Cluster

1. **Copy project to production directory:**
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline
   git pull origin scratch
   cp -r salmonella_temporal_phage ../COMPASS-pipeline-1.0.0/
   ```

2. **Download SRA accessions:**
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/salmonella_temporal_phage
   python3 scripts/fetch_salmonella_monthly.py
   ```

3. **Generate samplesheet:**
   ```bash
   python3 scripts/create_samplesheet.py
   ```

4. **Submit job:**
   ```bash
   sbatch run_salmonella_temporal_phage.sh
   ```

**Expected runtime:** 18-25 days for ~3,750 samples

## Data Storage Requirements

| Study | Samples | Results Size | Work Dir Size | Total |
|-------|---------|--------------|---------------|-------|
| Pseudomonas | 3,750 | ~1.8 TB | ~500 GB | ~2.3 TB |
| Vibrio | 2,787 | ~1.4 TB | ~400 GB | ~1.8 TB |
| Salmonella | 3,750 | ~1.8 TB | ~500 GB | ~2.3 TB |
| **TOTAL** | **10,287** | **~5 TB** | **~1.4 TB** | **~6.4 TB** |

**Archive strategy**: Compress and archive key results (SISTR, MLST, VIBRANT, MOB-suite, AMRFinder, MultiQC) to long-term storage after completion.

## Future Phage-Rich Candidates

If additional studies are desired:

1. **Streptococcus pyogenes** (3-6 prophages/genome)
   - Prophage-encoded superantigens
   - Invasive disease linked to prophages

2. **Staphylococcus aureus** (2-5 prophages/genome)
   - PVL toxin on prophages
   - MRSA spread

3. **Listeria monocytogenes** (1-4 prophages/genome)
   - Comovirus prophages
   - Hypervirulence linkage

4. **E. coli STEC** (2-8 prophages/genome, strain-dependent)
   - Shiga toxin on prophages
   - Pathotype comparison

## Key Analysis Tools

**Prophage detection:**
- VIBRANT (primary)
- DIAMOND prophage database
- PHANOTATE (gene prediction)

**Typing:**
- MLST (all organisms)
- SISTR (Salmonella serotyping) ⭐ NEW
- spa typing (if Staph added)

**Mobile elements:**
- MOB-suite (plasmids)
- AMRFinder (AMR + virulence)
- ABRicate (multi-database AMR)

**Quality:**
- BUSCO (contamination detection)
- QUAST (assembly stats)
- MultiQC (integrated QC)

## Contact

- **Researcher**: Tyler Doerksen
- **Institution**: Kansas State University
- **Email**: tdoerks@vet.k-state.edu
- **GitHub**: https://github.com/tdoerks/COMPASS-pipeline
- **Branch**: scratch (development/projects)

---

*Last updated: 2026-03-24*
*Studies completed: 3/4*
*Next: Salmonella temporal phage analysis*
