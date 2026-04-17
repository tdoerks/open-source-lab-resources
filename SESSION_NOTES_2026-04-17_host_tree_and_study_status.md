# Session Notes: 2026-04-17 - Fusobacterium Host Tree Complete & Study Status

## Summary
Completed Fusobacterium host genome phylogenetic tree using 20 core BUSCO genes. Created iTOL visualization files. Checked status of running STEC study (ongoing, 3+ days runtime).

## Work Completed

### 1. Fusobacterium Host Genome Tree - COMPLETED ✓

**Pipeline Details:**
- **Method**: FastTree maximum likelihood
- **Genes used**: 20 core single-copy BUSCO genes from bacteria_odb10
- **Samples**: 203 Fusobacterium genomes (successful assemblies)
- **Runtime**: ~48 seconds (FastTree is fast!)
- **Tree quality**: ML score -106459.5, 135 unique topologies tested

**Core Genes Used:**
```
1906715at2
1971380at2
1827295at2
1822215at2
1590629at2
... (15 more core genes)
```

**Output Files:**
- `fusobacterium_host_tree.nwk` - Newick format tree with bootstrap support values
- Tree includes support values (shown as decimals, e.g., 0.998 = 99.8% bootstrap)

**Key Observations:**
- Very short branch lengths overall (0.00055 - 0.86208)
- Most branches have high support (>0.95)
- A few long branches suggesting potential:
  - Divergent species/subspecies (SRRSRR4090967, SRRSRR536825: 0.86, 0.85)
  - Possible sequencing/assembly issues
  - Different Fusobacterium species

**Build Method:**
```bash
# Built on Beocat using:
/fastscratch/tylerdoe/fusobacterium_results/analysis/host_phylogenomics/
- Extracted BUSCO genes from successful assemblies
- Aligned 20 core genes with MAFFT
- Concatenated alignments
- Built tree with FastTree (GTR+CAT model)
```

### 2. iTOL Visualization Files Created

**Files Generated:**
1. `host_tree_colorstrip_basic.txt` - Color-coded sample groups
2. `host_tree_labels.txt` - Sample ID labels

**Usage:**
1. Upload `fusobacterium_host_tree.nwk` to https://itol.embl.de
2. Drag and drop annotation files
3. Customize as needed

**Current Annotations:**
- Basic grouping by sample ID numeric ranges
- Can be enhanced with metadata (species, host, isolation source)

**Enhancement Opportunity:**
- Run `fetch_sra_metadata.py` to get:
  - Fusobacterium subspecies (nucleatum, necrophorum, etc.)
  - Host organism (human, animal)
  - Isolation source (blood, abscess, oral cavity, etc.)
  - Geographic location

### 3. STEC Study Status Check

**Job Information:**
- **Job ID**: 7614525
- **Runtime**: 3 days, 16 hours, 33 minutes (as of 2026-04-17)
- **Status**: RUNNING
- **Samples**: 7,340 STEC (Shiga toxin E. coli) genomes
- **Node**: hero17

**Active Sub-processes:**
- 11 total jobs (2 pending, 9 running)
- VIBRANT prophage detection: 3 running, 1 pending
- MOB-suite mobile elements: 2 running
- BUSCO quality assessment: 1 running
- AMRFinderPlus: 3 running, 1 pending

**Progress Assessment:**
- Downloads likely complete (3+ days is sufficient for 7,340 samples)
- Assembly phase ongoing or nearing completion
- Analysis phase (VIBRANT, BUSCO, MOB-suite, AMRFinderPlus) actively running
- Multiple parallel jobs indicate healthy pipeline progression

**Expected Completion:**
- Estimated: 1-2 more days
- Total runtime: ~5 days for 7,340 samples (reasonable for this scale)

**Note:**
- Log file not found at `/fastscratch/tylerdoe/stec_results/logs/run_compass_pipeline.log`
- May be using different log location in COMPASS 1.1.0-candidate

### 4. Bacteroides fragilis Study Status

**Status**: NOT LAUNCHED
- No log files found
- Not in squeue
- Study scripts should be ready from previous session planning

**Action Item**: Launch Bacteroides study when ready (as part of anaerobe comparative study)

## Analysis Opportunities

### Immediate: Compare Prophage Tree vs Host Tree

Now that we have both trees, we can test:

**Hypothesis**: Do prophages follow vertical inheritance (match host tree) or horizontal transfer (different topology)?

**Analysis Steps:**
1. Extract prophage sequences from VIBRANT results
2. Build prophage gene tree (terminase, integrase, major capsid protein)
3. Compare topologies:
   - Congruent = vertical inheritance (ancient prophages)
   - Incongruent = horizontal transfer (recent acquisitions)

**Tools:**
- Robinson-Foulds distance
- Tanglegram visualization
- Cophylogeny analysis

### Future: Enhanced Metadata Annotations

**SRA Metadata to Fetch:**
- Fusobacterium species/subspecies
- Host organism (human vs animal)
- Isolation source (blood, abscess, oral, respiratory)
- Geography
- Clinical metadata (disease state)

**Enhanced iTOL Files:**
- Species color strips (F. nucleatum, F. necrophorum, F. varium, etc.)
- Host type (human, bovine, ovine, etc.)
- Niche/isolation source (invasive vs commensal)
- Prophage burden overlay (integrate with prophage count data)

## Repository Updates

### Files Created/Modified:
- `fusobacterium_host_tree.nwk` - Host genome tree (203 samples)
- `create_host_tree_itol_basic.py` - iTOL annotation generator
- `host_tree_colorstrip_basic.txt` - iTOL color strip
- `host_tree_labels.txt` - iTOL sample labels
- `stec_status_summary.txt` - STEC progress summary
- `SESSION_NOTES_2026-04-17_host_tree_and_study_status.md` - This file

### Git Branch:
- Working on: `scratch`
- Ready to commit tree files and session notes

## Next Steps

### Immediate:
1. ✓ Host tree downloaded and visualized
2. ✓ STEC status checked (running normally)
3. ✓ Session notes created
4. Push updates to `scratch` branch

### Short-term:
1. **Wait for STEC completion** (~1-2 days)
2. **Download and analyze STEC results** when complete
3. **Launch Bacteroides fragilis study** (obligate anaerobe comparative study)
4. **Fetch SRA metadata** for enhanced Fusobacterium annotations

### Medium-term:
1. **Prophage vs Host tree comparison**
   - Test vertical vs horizontal inheritance
   - Identify species-specific prophages
   - Identify promiscuous prophages

2. **Launch Clostridium difficile study** (9,133 samples)
   - Another obligate anaerobe for comparative analysis
   - Clinically important pathogen

3. **Comparative anaerobe analysis**
   - Fusobacterium (✓ complete)
   - Bacteroides fragilis (ready to launch)
   - Clostridium difficile (ready to launch)
   - Compare prophage burden across anaerobic bacteria

### Long-term:
1. **Oxygen gradient study**: Prophage burden vs oxygen tolerance
   - Obligate anaerobes (Fusobacterium, Bacteroides, Clostridium)
   - Facultative anaerobes (E. coli, Salmonella, Vibrio)
   - Obligate aerobes (Pseudomonas, Mycobacterium)

2. **Manuscript preparation**: "Low prophage burden in obligate anaerobes"

3. **Functional analysis**: Do aerobe prophages encode oxidative stress genes?

## Technical Notes

### FastTree Output Interpretation:
- Support values in Newick format: `node_name:branch_length)support:parent_branch`
- Example: `(SRRSRR770040:0.00214,SRRSRR900716:0.00118)0.998:0.00280`
  - Branch to SRRSRR770040: 0.00214 substitutions/site
  - Branch to SRRSRR900716: 0.00118 substitutions/site
  - Node support: 0.998 (99.8% bootstrap equivalent)
  - Branch to parent: 0.00280

### BUSCO Core Genes:
- 20 genes identified as single-copy across all 203 samples
- Good representation for phylogenomics
- Housekeeping genes (ribosomal, transcription, translation machinery)

### iTOL Tips:
- Upload tree first, then annotations
- Color strips can show multiple metadata categories
- Can overlay prophage counts as bar charts or heatmaps
- Export as SVG for publication quality

## Resources

**HPC**: Beocat (K-State)
- Fusobacterium results: `/fastscratch/tylerdoe/fusobacterium_results/`
- STEC results: `/fastscratch/tylerdoe/stec_results/` (running)
- Archives: `/bulk/tylerdoe/archives/`

**Pipeline**: COMPASS
- Fusobacterium: v1.2.0-candidate
- STEC: v1.1.0-candidate (older version, running since before v1.2.0)

**Visualization**: iTOL (https://itol.embl.de)

---
*Session conducted: 2026-04-17*
*Host tree: 203 Fusobacterium genomes, 20 core BUSCO genes*
*STEC study: 3d 16h runtime, actively processing*
