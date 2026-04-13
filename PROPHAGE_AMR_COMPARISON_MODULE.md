# Prophage-AMR 3-Method Comparison Module

## Overview

This module runs **three different methods** to detect AMR genes within prophage regions and compares the results. It's designed for **validation studies** and **method comparison** research.

## Quick Start

### Enable Comparison Mode

```bash
nextflow run main.nf \
    -profile beocat \
    --input samplesheet.csv \
    --outdir results \
    --prophage_amr_comparison true  # Enable 3-method comparison (SLOW!)
```

**⚠️ WARNING**: This adds ~1-2 minutes per sample. Use only for validation studies or small datasets.

---

## Three Methods Compared

### Method 1: Coordinate Intersection ⚡ (Fast)
**Default method in v1.2.0**
- Uses existing whole-genome prophage/AMR coordinates
- Filters terminal regions (5kb buffer)
- **Speed**: Seconds per sample
- **Script**: `bin/intersect_prophage_amr.py`

### Method 2: Direct AMRFinder Scan 🎯 (Definitive)
**Most biologically accurate**
- Extracts prophage sequences from VIBRANT
- Runs AMRFinder directly on prophage DNA
- **Speed**: 1-2 minutes per sample
- **Script**: `bin/run_amrfinder_on_prophages.py`

### Method 3: RGI/CARD Scan 📄 (Pinto et al. 2024)
**Published paper approach**
- Extracts prophage sequences from VIBRANT
- Runs RGI (CARD database) on prophage DNA
- **Speed**: 1-2 minutes per sample
- **Script**: `bin/run_rgi_on_prophages.py`
- **Citation**: Pinto et al., Genes 16(5):656

---

## Output Files

### Per-Sample Outputs
`results/prophage_amr_comparison/<sample_id>_*`

```
ERR123456_method1_coordinate.tsv       # Method 1 results
ERR123456_method2_amrfinder.tsv        # Method 2 results
ERR123456_method3_rgi.tsv              # Method 3 results (if RGI installed)
ERR123456_comparison_summary.tsv       # Comparison table
ERR123456_comparison_report.txt        # Human-readable report
```

### Aggregate Outputs
`results/prophage_amr_comparison/`

```
comparison_aggregate_summary.tsv       # Summary statistics across all samples
comparison_aggregate_report.txt        # Overall comparison report
```

---

## Example Output

### Individual Sample Report
```
================================================================================
PROPHAGE-AMR METHOD COMPARISON: ERR123456
================================================================================

RESULTS BY METHOD:
--------------------------------------------------------------------------------
  Method 1 (Coordinate):      2 genes - success
  Method 2 (AMRFinder Direct): 2 genes - success
  Method 3 (RGI/CARD):        1 gene - success

COMPARISON SUMMARY:
--------------------------------------------------------------------------------
  Total unique genes detected: 2
  Genes detected by ≥2 methods: 2
  Genes detected by 1 method:   0
  Agreement: 100.0%

GENES WITH AGREEMENT (detected by ≥2 methods):
--------------------------------------------------------------------------------
  • tet(A): Coordinate, AMRFinder, RGI
  • blaCTX-M-15: Coordinate, AMRFinder
```

### Aggregate Report
```
================================================================================
PROPHAGE-AMR METHOD COMPARISON - AGGREGATE RESULTS
================================================================================

Total samples analyzed: 163
Samples with prophage-AMR: 8

DETECTIONS BY METHOD:
--------------------------------------------------------------------------------
  Method 1 (Coordinate):       14 genes
  Method 2 (AMRFinder Direct): 13 genes
  Method 3 (RGI/CARD):         12 genes

AGREEMENT ANALYSIS:
--------------------------------------------------------------------------------
  Genes detected by ≥2 methods: 11
  Genes detected by 1 method:   3

✓ 92.9% agreement across methods
```

---

## Use Cases

### 1. Validate Method 1 (Coordinate Intersection)
**Scenario**: You want to confirm Method 1 is accurate

```bash
# Run comparison on validation dataset
nextflow run main.nf \
    -profile beocat \
    --input validation_samplesheet.csv \
    --outdir validation_comparison \
    --prophage_amr_comparison true \
    -resume
```

**Expected**: Method 1 and Method 2 should show high agreement (>90%)

### 2. Compare to Published Literature (Pinto et al.)
**Scenario**: You want to replicate paper's methodology

```bash
# Run all 3 methods including RGI
nextflow run main.nf \
    -profile beocat \
    --input dataset.csv \
    --outdir pinto_comparison \
    --prophage_amr_comparison true
```

**Analysis**: Compare Method 3 (RGI) results to Method 1/2 (AMRFinder)
- Different databases: CARD vs NCBI
- May detect different gene variants

### 3. Publication-Quality Validation
**Scenario**: Preparing manuscript with prophage-AMR findings

```bash
# Step 1: Run standard pipeline on full dataset (fast)
nextflow run main.nf \
    -profile beocat \
    --input all_samples.csv \
    --outdir results \
    --prophage_amr_comparison false  # Default, fast

# Step 2: Find positive samples
grep "Yes" results/prophage_amr/*_prophage_amr.tsv | cut -f1 > positive_samples.txt

# Step 3: Run validation on ONLY positive samples
# (Create samplesheet with just positives)
nextflow run main.nf \
    -profile beocat \
    --input positive_samples_samplesheet.csv \
    --outdir validation \
    --prophage_amr_comparison true  # Slow but thorough
```

**Manuscript text**:
> "Prophage-encoded AMR genes were detected using coordinate-based intersection (Method 1). Results were validated using direct AMRFinder scan of extracted prophage sequences (Method 2), showing 95% agreement."

---

## Configuration Parameters

### `prophage_amr_comparison` (boolean, default: `false`)
Enable 3-method comparison mode

```groovy
// In nextflow.config
params.prophage_amr_comparison = false  // Default: fast, single method
params.prophage_amr_comparison = true   // Validation: run all 3 methods
```

### `prophage_amr_terminal_buffer` (integer, default: `5000`)
Terminal region filter for Method 1 (bp)

```groovy
params.prophage_amr_terminal_buffer = 5000  // Exclude 5kb from termini
params.prophage_amr_terminal_buffer = 10000 // More stringent: exclude 10kb
```

---

## Requirements

### Method 1 (Always available)
- ✅ Python 3
- ✅ pandas
- ✅ Integrated in pipeline

### Method 2 (Always available)
- ✅ AMRFinderPlus (already in pipeline)
- ✅ Prophage sequences from VIBRANT

### Method 3 (Optional)
- ⚠️ **Requires RGI installation** (not included by default)
- If RGI not available, Method 3 will be skipped (not an error)
- Methods 1 and 2 will still run and be compared

### Installing RGI (Optional)

```bash
# Using conda
conda install -c bioconda rgi

# Or using pip
pip install rgi

# Load CARD database
rgi load --card_json /path/to/card.json
```

**If RGI not installed**: Comparison will run Methods 1 and 2 only.

---

## Performance Considerations

### Time Estimates

| Dataset Size | Method 1 Only | All 3 Methods |
|--------------|---------------|---------------|
| 10 samples | 1 minute | 15-20 minutes |
| 100 samples | 5 minutes | 2-3 hours |
| 1,000 samples | 30 minutes | 20-30 hours |

**Recommendation**:
- ✅ Use Method 1 for routine analysis (default)
- ✅ Use comparison mode for validation datasets (<100 samples)
- ❌ Do NOT use comparison mode for large-scale surveillance (>500 samples)

### Resource Usage

```groovy
// In conf/base.config
process {
    withName: PROPHAGE_AMR_COMPARISON {
        cpus = 2
        memory = 4.GB
        time = 10.m  // Per sample
    }
}
```

---

## Interpreting Results

### High Agreement (>90%)
**Indicates**: Methods are detecting the same AMR genes
**Action**: Method 1 (coordinate) is reliable for your dataset
**Publication**: Can confidently report Method 1 results

### Moderate Agreement (70-90%)
**Indicates**: Some methodological differences
**Investigate**:
- Are disagreements due to terminal regions?
- Do Methods 2/3 detect additional genes Method 1 missed?
- Are there annotation/coordinate issues?

**Action**: Manually inspect disagreed genes

### Low Agreement (<70%)
**Indicates**: Potential issues
**Check**:
- Are prophage coordinates accurate? (VIBRANT quality)
- Are AMR coordinates accurate? (AMRFinder quality)
- Are terminal buffer settings appropriate?

**Action**: Validate individual samples manually

### Method-Specific Detections

**Method 1 only**:
- Possible false positive from coordinate overlap
- Check if gene is truly internal to prophage

**Method 2 only**:
- Possible AMR gene missed by coordinate matching
- May be real detection that Method 1 filtered out

**Method 3 only**:
- CARD database may contain genes not in NCBI
- Could be different gene nomenclature

---

## Troubleshooting

### Error: "RGI not found"
**Solution**: Either install RGI or accept that Method 3 will be skipped

```bash
# Check if RGI is available
which rgi

# If not available, comparison will use Methods 1 and 2 only
```

### Warning: "Prophage sequences not found"
**Cause**: VIBRANT didn't produce `*_phages.fna` file
**Reason**: Sample may have no prophages, or VIBRANT failed
**Impact**: Methods 2 and 3 will show "no_sequences", only Method 1 runs

### Slow Performance
**Solution 1**: Run comparison on subset
```bash
# Only run on samples with Method 1 positives
--prophage_amr_comparison true
```

**Solution 2**: Increase time limits
```groovy
// In nextflow.config
params.max_time = '48.h'
```

**Solution 3**: Use HPC with more nodes
```bash
# Submit to cluster with higher resource allocation
-profile beocat --max_cpus 64
```

---

## Citation

If you use this comparison module, please cite:

1. **Method 1 (Our approach)**:
   - COMPASS Pipeline (your publication)

2. **Method 2 (AMRFinder)**:
   - Feldgarden et al., 2021, Scientific Data

3. **Method 3 (Pinto et al.)**:
   - Pinto et al., 2024, Genes 16(5):656
   - RGI/CARD: Alcock et al., 2020, Nucleic Acids Research

---

## Related Files

- **Scripts**:
  - `bin/intersect_prophage_amr.py` - Method 1
  - `bin/run_amrfinder_on_prophages.py` - Method 2
  - `bin/run_rgi_on_prophages.py` - Method 3
  - `bin/compare_prophage_amr_methods.py` - Orchestrator

- **Modules**:
  - `modules/prophage_amr.nf` - Standard Method 1
  - `modules/prophage_amr_comparison.nf` - Comparison module

- **Workflows**:
  - `workflows/complete_pipeline.nf` - Integration point

- **Documentation**:
  - `PROPHAGE_AMR_METHOD_COMPARISON.md` - Detailed method comparison
  - `PROPHAGE_AMR_ANALYSIS.md` - Standard analysis docs

---

## Questions?

For issues or questions:
1. Check `comparison_aggregate_report.txt` for summary
2. Review individual sample reports for details
3. See `PROPHAGE_AMR_METHOD_COMPARISON.md` for methodology
4. Check pipeline logs in `work/` directory
