# Prophage-Encoded AMR Gene Detection

## Overview

This analysis identifies antimicrobial resistance (AMR) genes that are encoded within prophage regions, which represents a critical mechanism for horizontal gene transfer and AMR dissemination in bacterial populations.

**Key Concept:** AMR genes within prophages can be transferred to other bacteria via phage transduction, facilitating rapid spread of antibiotic resistance.

## Scientific Background

### Why This Matters

1. **Horizontal Gene Transfer**: Prophages can mobilize AMR genes between bacteria
2. **Rapid AMR Spread**: Phage transduction is more efficient than conjugation in some environments
3. **Clinical Significance**: Prophage-mediated AMR spread contributes to treatment failures
4. **Evolutionary Insights**: Reveals co-evolution of phages and resistance genes

### Methodology

Based on: *Genes* **2024**, 16(5), 656; https://doi.org/10.3390/genes16050656

**Approach:**
1. Intersect prophage coordinates (from VIBRANT) with AMR gene positions (from AMRFinder)
2. Filter out AMR genes in terminal regions (<5kb from prophage ends) to exclude potential host contamination
3. Retain only AMR genes in internal prophage regions (high-confidence prophage-encoded)

## Tools

### 1. Single Sample Analysis

**Script:** `bin/intersect_prophage_amr.py`

Analyzes one sample to identify AMR genes within prophage regions.

**Usage:**
```bash
python3 bin/intersect_prophage_amr.py \
    --prophage_coords path/to/VIBRANT_integrated_prophage_coordinates.tsv \
    --amr_results path/to/sample_amr.tsv \
    --output prophage_amr_intersect.tsv \
    --sample_name SAMPLE_ID \
    --terminal_buffer 5000
```

**Parameters:**
- `--prophage_coords`: VIBRANT prophage coordinates TSV file
- `--amr_results`: AMRFinder results TSV file
- `--output`: Output file for intersection results
- `--sample_name`: Sample identifier for reporting
- `--terminal_buffer`: Exclude AMR genes within N bp of prophage termini (default: 5000)

**Output:**
- `prophage_amr_intersect.tsv`: Detailed intersection results with columns:
  - sample, scaffold, prophage_fragment, prophage_start, prophage_stop
  - amr_gene, amr_start, amr_stop, amr_class, amr_subclass
  - location_in_prophage, dist_from_start, dist_from_end
  - excluded, exclusion_reason
- `prophage_amr_intersect_summary.txt`: Human-readable summary

### 2. Batch Analysis

**Script:** `bin/batch_prophage_amr_analysis.sh`

Analyzes all samples in a COMPASS results directory.

**Usage:**
```bash
bash bin/batch_prophage_amr_analysis.sh \
    /path/to/compass_results \
    /path/to/output_directory
```

**What it does:**
- Finds all samples with AMRFinder results
- Locates corresponding VIBRANT prophage coordinates (handles nested directories)
- Runs prophage-AMR intersection for each sample
- Generates comprehensive summary report
- Highlights samples with prophage-encoded AMR genes

**Output:**
- `prophage_amr_summary.tsv`: Table with all samples
- `samples_with_prophage_amr.txt`: List of positive samples
- `PROPHAGE_AMR_REPORT.txt`: Detailed report for positive samples
- `individual_samples/`: Per-sample TSV files
- `logs/`: Processing logs for each sample

## Running on Large Datasets

### Example 1: Vibrio cholerae (3,750 samples)

```bash
# On Beocat
cd /fastscratch/tylerdoe/COMPASS-pipeline

# Run batch analysis
bash bin/batch_prophage_amr_analysis.sh \
    /fastscratch/tylerdoe/vibrio_cholerae_results \
    /fastscratch/tylerdoe/vibrio_prophage_amr_analysis
```

**Expected runtime:** ~5-10 minutes for 3,750 samples

**Why interesting for Vibrio:**
- Highest prophage burden (8-12 prophages/genome)
- CTXφ prophage carries cholera toxin genes
- Emerging fluoroquinolone and azithromycin resistance
- Geographic spread patterns

### Example 2: Salmonella (2,700 samples)

```bash
bash bin/batch_prophage_amr_analysis.sh \
    /fastscratch/tylerdoe/salmonella_temporal_phage_results \
    /fastscratch/tylerdoe/salmonella_prophage_amr_analysis
```

**Why interesting for Salmonella:**
- Known prophage-mediated virulence gene transfer
- Rising AMR prevalence globally
- Temporal dynamics of phage-AMR co-occurrence

### Example 3: Diverse Bacteria (1,000 samples)

```bash
bash bin/batch_prophage_amr_analysis.sh \
    /fastscratch/tylerdoe/diverse_bacteria_1000_results \
    /fastscratch/tylerdoe/diverse_bacteria_prophage_amr_analysis
```

**Why interesting:**
- Cross-species comparison of prophage-AMR prevalence
- Identify which species most affected
- Taxonomic patterns in phage-mediated AMR spread

## Interpreting Results

### Summary Table Columns

| Column | Description |
|--------|-------------|
| sample | Sample identifier |
| prophages | Number of prophage regions detected |
| amr_genes | Number of AMR genes detected |
| total_intersections | AMR genes overlapping prophage regions (any position) |
| retained_intersections | AMR genes in internal prophage regions (high confidence) |
| prophage_amr_genes | Gene names of retained prophage-encoded AMR |

### What to Look For

1. **Positive Samples** (`retained_intersections > 0`):
   - These samples have AMR genes within prophage internal regions
   - High confidence for phage-encoded resistance
   - Potential for horizontal transfer

2. **AMR Gene Classes**:
   - Beta-lactamases in prophages → transferable β-lactam resistance
   - Aminoglycoside resistance genes → transferable to Gram-negatives
   - Tetracycline resistance → broad transferability

3. **Prophage Fragment Information**:
   - Which prophage(s) carry AMR genes
   - Distance from prophage termini (>5kb = high confidence)

### Key Questions

- **How common is prophage-encoded AMR?** (`retained_intersections > 0` / total samples)
- **Which AMR genes are mobile?** (frequent prophage-encoded genes)
- **Taxonomic patterns?** (species with highest prophage-AMR prevalence)
- **Temporal trends?** (increasing/decreasing over time)
- **Geographic patterns?** (regions with high prophage-AMR)

## Expected Findings

Based on literature, prophage-encoded AMR is relatively rare but highly significant:

### Likely Scenarios

1. **Most samples (>95%)**: No prophage-encoded AMR
   - AMR genes on chromosome or plasmids
   - Normal bacterial evolution

2. **Rare samples (1-5%)**: Prophage-encoded AMR
   - **HIGH SIGNIFICANCE**
   - Indicates active phage-mediated AMR spread
   - Potential "super-spreader" strains

3. **Specific genes more common**:
   - Beta-lactamases (bla genes)
   - Aminoglycoside modifying enzymes (aac, aph, ant)
   - Some tetracycline resistance (tet genes)

### Publication-Worthy Findings

If you find:
- **>1% samples with prophage-AMR**: Novel finding, worth publishing
- **Specific AMR gene always in prophages**: Gene-phage association
- **Temporal increase in prophage-AMR**: Emerging threat
- **Geographic clustering**: Phage-mediated outbreak spread
- **Multi-drug resistance in prophages**: Extremely rare, high impact

## Integration with COMPASS Pipeline

### Current Status

- ✅ Standalone scripts created (`intersect_prophage_amr.py`, `batch_prophage_amr_analysis.sh`)
- ⏳ Nextflow module wrapper (TODO)
- ⏳ HTML summary visualization (TODO - Tab 16?)

### Future Development

#### Nextflow Module (v1.3)

```nextflow
process PROPHAGE_AMR_INTERSECTION {
    tag "$sample_id"
    publishDir "${params.outdir}/prophage_amr", mode: 'copy'

    input:
    tuple val(sample_id), path(prophage_coords), path(amr_results)

    output:
    path("${sample_id}_prophage_amr.tsv"), emit: tsv
    path("${sample_id}_prophage_amr_summary.txt"), emit: summary

    script:
    """
    intersect_prophage_amr.py \\
        --prophage_coords ${prophage_coords} \\
        --amr_results ${amr_results} \\
        --output ${sample_id}_prophage_amr.tsv \\
        --sample_name ${sample_id} \\
        --terminal_buffer ${params.prophage_amr_terminal_buffer}
    """
}
```

#### HTML Summary Tab

**Tab 16: Prophage-Encoded AMR**

Visualizations:
1. **Prevalence chart**: % samples with prophage-AMR (bar chart)
2. **AMR gene distribution**: Which genes found in prophages (bar chart)
3. **AMR class breakdown**: Resistance classes in prophages (pie chart)
4. **Heatmap**: Samples × prophage-encoded AMR genes
5. **Summary statistics**: Total samples, positive samples, unique genes

## Example Output

### Console Summary

```
==========================================================
Prophage-AMR Intersection Analysis
==========================================================
Sample: E925
Terminal buffer: 5000 bp

✓ Loaded 4 prophage regions from prophage_coords.tsv
✓ Loaded 25 AMR genes from amr_results.tsv

📊 Prophage-AMR Intersection Results:
  Total AMR genes in prophage regions: 2
  Retained (internal): 1
  Excluded (terminal <5000bp): 1

⚠️  PROPHAGE-ENCODED AMR GENES DETECTED:
    - blaTEM-1B (BETA-LACTAM) in prophage_3

✓ Results written to prophage_amr_intersect.tsv
✓ Summary written to prophage_amr_intersect_summary.txt

✓ Analysis complete!
```

### Batch Analysis Summary

```
==========================================================
Analysis Complete!
==========================================================
End time: 2026-03-27 14:32:15

Summary:
  Total samples: 3750
  Successfully processed: 3742
  Failed: 8
  Samples with prophage-encoded AMR: 47

🚨 CRITICAL FINDING: 47 samples contain AMR genes within prophage regions!

Samples with prophage-encoded AMR:
SRR12345678
SRR12345679
SRR12345680
...

See full details in: vibrio_prophage_amr_analysis/prophage_amr_summary.tsv
```

## Troubleshooting

### VIBRANT Directory Structure Varies

The batch script handles multiple directory structures:

```bash
# Standard structure
vibrant/SAMPLE/VIBRANT_SAMPLE/VIBRANT_results_SAMPLE/VIBRANT_integrated_prophage_coordinates_SAMPLE.tsv

# Alternative structure
vibrant/SAMPLE_vibrant/VIBRANT_SAMPLE/VIBRANT_results_SAMPLE/VIBRANT_integrated_prophage_coordinates_SAMPLE.tsv

# Flat structure
vibrant/SAMPLE/VIBRANT_integrated_prophage_coordinates_SAMPLE.tsv
```

If prophage files still not found:
```bash
# Manually search for file
find /path/to/results -name "VIBRANT_integrated_prophage_coordinates_*.tsv"

# Adjust script SEARCH_PATHS array
```

### No Prophage Coordinates Found

Possible reasons:
1. VIBRANT did not detect prophages (sample has no prophages)
2. VIBRANT failed to run (check pipeline logs)
3. File naming doesn't match expected pattern (check actual filenames)

### Empty Intersection Results

This is **GOOD NEWS** - means no prophage-encoded AMR genes in that sample.

Most samples (>95%) should have zero intersections.

## Citation

If you use this analysis in publications, cite:

1. **Methodology paper:**
   - *Genes* 2024, 16(5), 656; https://doi.org/10.3390/genes16050656

2. **COMPASS Pipeline:**
   - Doerks et al. (2026). COMPASS: Comprehensive Pathogen Analysis and Summary System. DOI: TBD

3. **Key tools:**
   - VIBRANT: Kieft et al. (2020). VIBRANT: automated recovery, annotation and curation of microbial viruses, and evaluation of viral community function from genomic sequences. *Microbiome* 8, 90.
   - AMRFinder+: Feldgarden et al. (2021). AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. *Scientific Reports* 11, 12728.

## Contact

- Email: tdoerks@vet.k-state.edu
- GitHub: https://github.com/tdoerks/COMPASS-pipeline
- Issues: https://github.com/tdoerks/COMPASS-pipeline/issues

## Changelog

- **2026-03-27**: Initial creation
  - Implemented coordinate intersection algorithm
  - Terminal region filtering (5kb buffer)
  - Single-sample and batch analysis scripts
  - Comprehensive documentation
  - Tested on 163-genome validation dataset

---

**Next Steps:**
1. Run batch analysis on Vibrio (3,750 samples)
2. Run batch analysis on Salmonella (2,700 samples)
3. Run batch analysis on diverse bacteria (1,000 samples)
4. Analyze results and identify patterns
5. Create visualizations for HTML summary
6. Publish findings if significant prophage-AMR prevalence detected
