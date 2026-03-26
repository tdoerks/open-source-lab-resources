# Testing v1.2.0 HTML Summary with 163 Genomes

This guide explains how to test the new v1.2.0 HTML summary report features with the 163-genome validation dataset on beocat.

## Quick Start

On **beocat**, run:

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate

# Pull latest changes
git pull origin 1.2.0-candidate

# Run the test script
bash test_compass_summary_v1.2.0_163genomes.sh
```

## What This Tests

The script will generate the enhanced HTML summary report with all new v1.2.0 features:

### New Mandatory Tabs (v1.2.0)
- **Tab 10: Genome Annotation** - Gene count histogram, RNA composition, hypothetical proteins
- **Tab 11: Virulence Analysis** - VF distribution, top genes, heatmap
- **Tab 12: Enhanced Prophage** - Quality-based charts, complete/partial prophage analysis

### Optional Tabs (if data available)
- **Tab 13: Pangenome Analysis** - Core/shell/cloud gene distribution (requires Panaroo)
- **Tab 14: Phylogenetic Tree** - Sample tree structure (requires IQ-TREE)
- **Tab 15: SNP Analysis** - Distance histogram and statistics (requires Snippy)

## Requirements

### 1. Pipeline Setup
```bash
# Ensure 1.2.0-candidate branch is cloned
cd /fastscratch/tylerdoe/
git clone https://github.com/tdoerks/COMPASS-pipeline.git COMPASS-pipeline-1.2.0-candidate
cd COMPASS-pipeline-1.2.0-candidate
git checkout 1.2.0-candidate
```

### 2. Validation Results
The script looks for existing 163-genome validation results at:
```
/scratch/tylerdoe/COMPASS_Validation_Results_v1.3-dev_2026-02-09/results/
```

**If this directory doesn't exist**, you have two options:

#### Option A: Use Different Results Directory
```bash
# Set environment variable before running
export RESULTS_DIR=/path/to/your/validation/results
bash test_compass_summary_v1.2.0_163genomes.sh
```

#### Option B: Generate New 163-Genome Results
```bash
# This takes 24-48 hours on beocat
sbatch data/validation/run_compass_validation_v1.0.1.sh
```

## Expected Output

### Console Output
```
==========================================
COMPASS v1.2.0 HTML Summary - 163 Genome Test
==========================================

Found results for:
  - QUAST: 163 samples
  - MLST: 163 samples
  - AMRFinder: 163 samples

Checking for optional module results...
  ✓ Panaroo results found
  ✓ IQ-TREE results found
  ✓ Snippy results found

==========================================
Generating HTML Summary Report...
==========================================

SUCCESS! HTML Summary Generated

Verification checks:
  - Total Chart.js visualizations: 35
  - Total tabs: 15

Checking for new v1.2.0 tabs...
  ✓ Tab 10: Genome Annotation
  ✓ Tab 11: Virulence Analysis
  ✓ Tab 12: Enhanced Prophage Analysis
  ✓ Tab 13: Pangenome Analysis (optional)
  ✓ Tab 14: Phylogenetic Tree (optional)
  ✓ Tab 15: SNP Analysis (optional)

HTML file size: 3.2M
```

### Output Files
```
data/validation/summary_163genomes_test/
└── compass_summary.html    # Main HTML report with all visualizations
```

## Verification Steps

### 1. Download HTML to Local Machine
```bash
# From your local machine
scp beocat:/fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/data/validation/summary_163genomes_test/compass_summary.html .
```

### 2. Open in Browser
- Double-click `compass_summary.html`
- Should open in your default browser

### 3. Test All Tabs
Navigate through all 15 tabs and verify:

**Base Tabs (v1.0.0) - Should still work:**
1. Sample Overview
2. Assembly QC
3. MLST Typing
4. AMR Detection
5. Plasmid Analysis
6. Prophage Detection
7. Read QC (if fastq input)
8. Tool Versions
9. Data Table

**New Mandatory Tabs (v1.2.0) - These are what we're testing:**
10. **Genome Annotation**
    - [ ] Gene count histogram shows distribution across 163 samples
    - [ ] RNA gene composition pie chart displays
    - [ ] Hypothetical proteins chart renders

11. **Virulence Analysis**
    - [ ] VF distribution chart shows data
    - [ ] Top VF genes bar chart displays
    - [ ] VF presence heatmap renders (may be large with 163 samples)

12. **Enhanced Prophage Analysis**
    - [ ] Quality distribution chart shows complete/partial prophage
    - [ ] Quality score histogram displays
    - [ ] Statistics cards show correct totals

**Optional Tabs (v1.2.0) - Only if modules were run:**
13. **Pangenome Analysis** (requires Panaroo)
    - [ ] Pangenome composition pie chart (core/soft-core/shell/cloud)
    - [ ] Gene frequency histogram

14. **Phylogenetic Tree** (requires IQ-TREE)
    - [ ] Sample list displays
    - [ ] Newick format is expandable

15. **SNP Analysis** (requires Snippy)
    - [ ] SNP distance histogram shows bins
    - [ ] Statistics cards show min/max/mean distances

### 4. Check Browser Console
Open browser developer tools (F12) and check Console tab:
- [ ] No JavaScript errors (red messages)
- [ ] All Chart.js visualizations initialized successfully
- [ ] No "Uncaught SyntaxError" messages

### 5. Performance Check
With 163 samples, verify:
- [ ] Page loads in reasonable time (<10 seconds)
- [ ] Tabs switch smoothly
- [ ] Charts render without freezing browser
- [ ] Heatmaps don't cause memory issues

## Troubleshooting

### Error: "Results directory not found"
```bash
# Check if validation results exist
ls -la /scratch/tylerdoe/COMPASS_Validation_Results*/

# If different location, set environment variable
export RESULTS_DIR=/your/actual/results/path
bash test_compass_summary_v1.2.0_163genomes.sh
```

### Error: "Expected 163 samples, found only X"
This means the validation run was incomplete. You can:
1. Continue anyway (script will wait 3 seconds)
2. Or re-run validation to get complete results

### Missing Tabs 13-15
These tabs only appear if optional modules were enabled:
- Tab 13 (Pangenome): Requires `--skip_panaroo false`
- Tab 14 (Phylo Tree): Requires `--skip_iqtree false`
- Tab 15 (SNP): Requires `--snippy_reference ref.fasta`

To test with dummy data for these modules:
```bash
bash create_test_optional_data.sh
```

### Charts Not Rendering
If charts appear blank in browser:
1. Check browser console for JavaScript errors
2. Verify Chart.js library loaded (check Network tab)
3. Look for syntax errors in generated HTML
4. Compare chart count:
   ```bash
   grep -c "new Chart(" compass_summary.html
   # Should be 26-35 depending on optional modules
   ```

## What to Look For

### Success Indicators ✅
- All 12-15 tabs appear and switch correctly
- Gene count histogram shows 163 bars/bins
- VF heatmap displays all samples (may be dense)
- No JavaScript errors in browser console
- File size is reasonable (2-5 MB)
- Charts render within a few seconds

### Potential Issues ⚠️
- **Heatmap too large**: With 163 samples, heatmap may be very dense
  - Consider adding sample limit or scrollable container
  - May need to implement clustering/filtering

- **Slow rendering**: Large dataset may slow down Chart.js
  - Monitor page load time
  - Check memory usage in browser Task Manager

- **Missing visualizations**: Some charts may not render if data is missing
  - Check that parse functions handle all samples
  - Verify placeholder replacements worked

## Next Steps After Testing

### If Everything Works ✅
1. Document test results in session notes
2. Ready for v1.2.0 release candidate
3. Consider merge to main branch

### If Issues Found 🐛
1. Document specific errors
2. Fix rendering issues for large datasets
3. Add performance optimizations if needed
4. Re-test with 163 genomes

## Related Files

- `bin/generate_compass_summary.py` - Main report generator
- `test_compass_summary_v1.2.0_163genomes.sh` - This test script
- `create_test_optional_data.sh` - Script to create dummy optional module data
- `session-notes-2026-03-26-genomic-charts-fix.md` - Development notes

## Questions?

If you encounter issues:
1. Check the session notes for known issues
2. Verify you're on the 1.2.0-candidate branch
3. Ensure generate_compass_summary.py has all recent fixes
4. Look at browser console for specific error messages
