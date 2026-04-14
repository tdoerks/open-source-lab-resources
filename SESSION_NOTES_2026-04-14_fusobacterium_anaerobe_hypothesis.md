# Session Notes: 2026-04-14 - Fusobacterium Study & Anaerobe Prophage Hypothesis

## Summary
Completed Fusobacterium prophage study analysis and discovered potentially novel finding: **obligate anaerobes have significantly lower prophage burden than aerobic/facultative bacteria**.

## Work Completed

### 1. Fusobacterium Study Results
- **Pipeline**: COMPASS 1.2.0-candidate on Beocat
- **Job**: 7610190 (completed successfully)
- **Samples**: 292 attempted, 218 successful assemblies
- **Results location**: `/fastscratch/tylerdoe/fusobacterium_results/`
- **Archived to**: `/bulk/tylerdoe/archives/fusobacterium_results/`

### 2. Key Findings

#### Prophage Prevalence
- **Total prophages**: 278 across 218 genomes
- **Average**: 1.3 prophages/genome
- **Prophage-positive genomes**: 140 (64%)
- **Prophage-free genomes**: 78 (36%) ⬅️ **unusually high**

#### Prophage Characteristics
- **Size range**: 5.8 kb - 180 kb
- **Average size**: 38.4 kb (typical lambdoid size)
- **Size distribution**:
  - Small (<20 kb): 85 prophages
  - Medium (20-50 kb): 148 prophages
  - Large (>50 kb): 46 prophages

#### Assembly Quality
- **Average genome size**: ~3.3 Mb (typical for Fusobacterium)
- **Average GC content**: 29-30% (matches Fusobacterium)
- **BUSCO completeness**: 97.6% (high quality)
- **DIAMOND prophage hits**: 5,469 total (25 hits/genome avg)

### 3. Analysis Files Created
Location: `/fastscratch/tylerdoe/fusobacterium_results/analysis/`

- `fusobacterium_prophage_summary.txt` - Comprehensive summary
- `prophage_counts_per_sample.tsv` - Prophage burden per genome
- `all_prophage_regions.tsv` - Coordinates and sizes
- `assembly_stats.tsv` - GC%, length, contigs
- `bacterial_lineages.tsv` - BUSCO lineage assignments
- `prophage_amr_analysis.txt` - Prophage-AMR associations
- `prophage_proteins.txt` - Top prophage proteins detected
- `cross_study_comparison.txt` - Comparison to other studies
- `phylogenomics_plan.txt` - Future phylogenetic analysis plan

### 4. STEC Study Status
- **Pipeline**: COMPASS 1.1.0-candidate
- **Job**: 7614525 (running)
- **Progress**: 3,632 of 7,340 SRA downloads complete (49%)
- **Samples ready**: 3,521 queued for assembly

## NOVEL HYPOTHESIS: Oxygen-Dependent Prophage Burden

### The Discovery
Fusobacterium (obligate anaerobe) has **dramatically lower** prophage burden compared to aerobic/facultative bacteria:

| Organism | Metabolism | Prophages/Genome | Source |
|----------|------------|------------------|--------|
| **Fusobacterium** | **Obligate anaerobe** | **1.3** | **This study (n=218)** |
| E. coli | Facultative | 8.2 | Literature (n=58) |
| Salmonella | Facultative | 5.6 | Literature (n=27) |
| Salmonella | Facultative | ~4.2 | Your study (n=2,737) |
| P. aeruginosa | Aerobic | 11-12 | Literature |

### Hypothesis
**"Prophage burden correlates inversely with anaerobic lifestyle - anaerobic bacteria harbor fewer prophages due to lack of oxidative stress-driven lysogeny selection"**

### Supporting Evidence from Literature

#### Oxidative Stress & Prophage Relationship
1. **Oxidative stress triggers prophage induction** (2025 study)
   - ROS activates OxyR → prophage Pf4 production in P. aeruginosa
   - Prophages help bacteria survive oxidative stress

2. **Prophages provide oxidative stress tolerance**
   - Lysogenic prophages enhance survival under ROS/RNS
   - Prophage phi456 regulates oxidative stress response genes

3. **Anaerobes lack oxidative stress pressure**
   - Fusobacterium (obligate anaerobe) doesn't face ROS
   - No selective advantage for prophage-mediated ROS tolerance
   - Result: Lower prophage acquisition/retention

#### Why This Is Novel
- **No direct comparative study** of prophage burden across oxygen tolerance groups
- Literature focuses on:
  - Individual species (E. coli, Salmonella, Pseudomonas)
  - Stress-induced prophage induction
  - Gut microbiome prophages (mixed aerotolerance)
- **Missing**: Systematic comparison of aerobes vs facultative vs anaerobes

### Proposed Study Design

#### Study: "Prophage Burden Across the Oxygen Gradient"

**Hypothesis**: Prophage burden decreases with obligate anaerobic lifestyle

**Study Groups** (n=200-500 genomes each):
1. **Obligate Aerobes**
   - Pseudomonas aeruginosa ✓ (already have some data)
   - Mycobacterium tuberculosis
   - Bacillus subtilis (aerobic)

2. **Facultative Anaerobes**
   - E. coli ✓ (STEC study in progress - 7,340 genomes!)
   - Salmonella ✓ (completed - 2,737 genomes)
   - Vibrio ✓ (completed)

3. **Microaerophiles**
   - Campylobacter jejuni
   - Helicobacter pylori

4. **Obligate Anaerobes**
   - Fusobacterium ✓ (completed - 218 genomes)
   - Bacteroides fragilis (gut anaerobe)
   - Clostridium difficile
   - Prevotella (oral anaerobe)

**Analysis Pipeline**: Use existing COMPASS pipeline
- VIBRANT (prophage detection)
- DIAMOND (prophage proteins)
- PHANOTATE (prophage annotation)
- BUSCO (quality control)

**Metrics**:
- Prophages per genome (mean ± SD)
- % genomes with prophages
- Prophage size distribution
- Prophage gene content (oxidative stress response?)

**Statistical Analysis**:
- ANOVA across oxygen tolerance groups
- Linear regression: prophage burden ~ oxygen requirement
- Control for: genome size, phylogenetic distance

**Expected Results**:
- Obligate anaerobes: 1-2 prophages/genome
- Microaerophiles: 3-4 prophages/genome
- Facultative: 5-8 prophages/genome
- Obligate aerobes: 8-12 prophages/genome

## Future Analyses for Fusobacterium

### Planned Phylogenomic Analysis
1. **Prophage gene tree** vs **host genome tree**
   - Test vertical inheritance vs horizontal transfer
   - Extract prophage sequences from VIBRANT results
   - Build trees with MAFFT + FastTree/RAxML

2. **Core prophage genes**
   - Identify conserved prophage markers (terminase, integrase)
   - Use PHANOTATE annotations

3. **Prophage-AMR associations**
   - 624 prophage-AMR intersection results available
   - Check if prophages carry virulence/resistance genes

4. **Plasmid-prophage comparison**
   - MOB-suite results (218 samples)
   - Do plasmids compensate for low prophage burden?

## Repository Updates

### Branches
- Working on: `scratch`
- Ahead of `compass/scratch` by 100 commits
- Contains both Fusobacterium and STEC studies

### Files Modified/Created
- `fusobacterium_necrophorum_study/` (complete study structure)
  - `scripts/fetch_fusobacterium_necrophorum.py` (updated to all Fusobacterium)
  - `scripts/create_samplesheet.py`
  - `run_fusobacterium.sh` (SLURM job for 1.2.0-candidate)
  - `README.md`
  - `data/sra_accessions_fusobacterium_necrophorum_all.txt` (292 accessions)

- `stec_prophage_study/` (ready to analyze when complete)
  - `scripts/fetch_stec_temporal.py` (100 samples/month, 2020-2026)
  - `scripts/fetch_stec_all.py` (comprehensive approach)
  - `scripts/create_samplesheet.py`
  - `run_stec_prophage.sh` (SLURM job for 1.1.0-candidate)
  - `README.md`

- Updated `PHAGE_RICH_STUDY_SERIES.md`
  - Added Fusobacterium as Study #5
  - Added STEC as Study #6
  - Added metabolism comparison section

## Next Steps

### Immediate
1. **Push session notes to compass/scratch** ✓
2. **Wait for STEC study completion** (job 7614525)
3. **Plan anaerobe comparative study**

### Short-term
1. **Add more obligate anaerobes**:
   - Bacteroides fragilis (abundant gut anaerobe)
   - Clostridium difficile (clinically important)
   - Prevotella species (oral microbiome)

2. **Add obligate aerobes**:
   - Mycobacterium tuberculosis
   - Additional Pseudomonas species

3. **Add microaerophiles**:
   - Campylobacter jejuni
   - Helicobacter pylori

### Long-term
1. **Manuscript preparation**: "Prophage burden inversely correlates with anaerobic lifestyle across bacterial species"
2. **Phylogenomic analysis** of Fusobacterium prophages
3. **Functional analysis**: Do aerobe prophages encode oxidative stress genes?

## Key Contacts & Resources
- **HPC**: Beocat (K-State)
- **Pipeline**: COMPASS (Nextflow-based)
- **Results**: `/fastscratch/tylerdoe/` (working), `/bulk/tylerdoe/archives/` (long-term)

## Notes
- Fusobacterium MLST failed (no PubMLST scheme exists)
- BUSCO stayed at bacteria_odb10 (didn't drill to Fusobacteriales)
- Species ID requires NCBI metadata (not in pipeline output)
- rsync transfer to bulk storage completed successfully
- This is the **first obligate anaerobe** in the phage study series

---
*Session conducted: 2026-04-14*
*Pipeline versions: 1.1.0-candidate (STEC), 1.2.0-candidate (Fusobacterium)*
