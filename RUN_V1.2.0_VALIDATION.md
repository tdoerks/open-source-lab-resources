# COMPASS v1.2.0 Full Validation - 163 Genomes

## Quick Start (On Beocat)

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate

# Pull latest code
git pull origin 1.2.0-candidate

# Submit the validation job
sbatch run_compass_validation_v1.2.0_163genomes.sh
```

## What This Does

This script runs a **complete v1.2.0 validation** with 163 E. coli reference genomes, testing ALL new features:

### ✅ Reuses v1.0.1 Cached Results
- Automatically finds your v1.0.1 work directory
- Skips unchanged modules (QUAST, MLST, AMR, plasmids, etc.)
- **Only runs NEW v1.2.0 modules** → Much faster! (~6-12 hours instead of 48)

### 🆕 New Mandatory Modules (v1.2.0)
1. **Prokka** - Genome annotation for Tab 10
2. **VFDB** - Virulence factor detection for Tab 11
3. **Enhanced VIBRANT** - Quality-based prophage analysis for Tab 12
4. **Prophage-AMR** - Identifies AMR genes within prophage regions for Tab 16

### 🔬 Optional Modules (ENABLED for complete 16-tab testing)
4. **Panaroo** - Pangenome analysis (Tab 13)
5. **IQ-TREE** - Phylogenetic tree (Tab 14)
6. **Snippy** - SNP analysis (Tab 15)

### 📊 Enhanced HTML Summary
- Automatically generated with all new visualizations
- All 16 tabs fully functional (including new prophage-AMR analysis)
- Tested with 163 samples for scalability

---

## Prerequisites

### 1. Samplesheet Required
The script looks for:
```
data/validation/validation_samplesheet_fasta.csv
```

**Format:**
```csv
sample,organism,fasta
E925,Escherichia coli,/path/to/E925.fasta
E1649,Escherichia coli,/path/to/E1649.fasta
...
```

### 2. v1.0.1 Results (Optional but Recommended)
If you have existing v1.0.1 validation results at:
```
/scratch/tylerdoe/COMPASS_Validation_Results_v1.0.1_*/
```

The script will automatically:
- Find the work directory
- Reuse cached results with `-resume -w /path/to/work`
- **Save 20-30 hours** of compute time!

### 3. Reference Genome for Snippy
The script uses the **first genome in the samplesheet** as the reference.

If reference genome is missing, Snippy is skipped (Tab 15 won't appear).

---

## Resource Allocation

```bash
#SBATCH --cpus-per-task=20     # Increased for parallel processing
#SBATCH --mem=96G              # Increased for optional modules
#SBATCH --time=48:00:00        # Max time (usually finishes in 6-12h with -resume)
```

### Why More Resources?
- **Panaroo**: Memory-intensive with 163 genomes
- **IQ-TREE**: CPU-intensive phylogenetic inference
- **Snippy**: Runs 163 comparisons against reference

With `-resume` using v1.0.1 cache, most jobs finish in **6-12 hours**.

---

## Monitoring the Run

### Check Job Status
```bash
squeue -u $USER
```

### View Live Output
```bash
# Find your job ID from squeue or sbatch output
tail -f /scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_<JOBID>/logs/compass_validation_<JOBID>.out
```

### Check for Errors
```bash
tail -f /scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_<JOBID>/logs/compass_validation_<JOBID>.err
```

---

## Expected Output

### Console Summary
```
==========================================
COMPASS v1.2.0 validation completed successfully!
==========================================

Validation checks:

  Core modules:
    - QUAST reports: 163 / 163
    - AMR files: 163 / 163
    - MLST files: 163 / 163

  New v1.2.0 modules:
    - Prokka annotations: 163 / 163
    - VFDB results: 163 / 163
    - VIBRANT prophage: 163 / 163

  Optional modules:
    ✓ Panaroo pangenome: 5432 genes
    ✓ IQ-TREE phylogeny: Tree file exists
    ✓ Snippy SNPs: 163 comparisons

✅ HTML Summary Report Generated!

  HTML Report Statistics:
    - Total tabs: 16
    - Total charts: 38
    - File size: 3.5M

  v1.2.0 Features:
    ✓ Tab 10: Genome Annotation
    ✓ Tab 11: Virulence Analysis
    ✓ Tab 12: Enhanced Prophage
    ✓ Tab 13: Pangenome Analysis
    ✓ Tab 14: Phylogenetic Tree
    ✓ Tab 15: SNP Analysis
    ✓ Tab 16: Prophage-Encoded AMR
```

### Output Directory Structure
```
/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_<JOBID>/
├── logs/
│   ├── compass_validation_<JOBID>.out
│   └── compass_validation_<JOBID>.err
└── results/
    ├── quast/              # Assembly QC
    ├── mlst/               # Strain typing
    ├── amrfinder/          # AMR genes
    ├── mobsuite/           # Plasmids
    ├── busco/              # Completeness
    ├── vibrant/            # Enhanced prophage
    ├── prokka/             # NEW: Genome annotations
    ├── vfdb/               # NEW: Virulence factors
    ├── prophage_amr/       # NEW: Prophage-encoded AMR genes
    ├── panaroo/            # OPTIONAL: Pangenome
    ├── iqtree/             # OPTIONAL: Phylogeny
    ├── snippy/             # OPTIONAL: SNPs
    ├── multiqc/
    │   └── multiqc_report.html
    ├── summary/
    │   └── compass_summary.html    # ← Enhanced 16-tab report!
    ├── nextflow_report.html
    ├── nextflow_timeline.html
    └── nextflow_dag.html
```

---

## Verification Steps

### 1. Download HTML Summary
```bash
# From your local machine
scp beocat:/scratch/tylerdoe/COMPASS_Validation_Results_v1.2.0_<JOBID>/results/summary/compass_summary.html .
```

### 2. Open in Browser
- Double-click `compass_summary.html`
- Should see all 16 tabs

### 3. Test Each Tab
Navigate through all tabs and verify:

**Base Tabs (v1.0.0):**
- [x] Sample Overview
- [x] Assembly QC
- [x] MLST Typing
- [x] AMR Detection
- [x] Plasmid Analysis
- [x] Prophage Detection
- [x] Tool Versions
- [x] Data Table

**New Mandatory Tabs (v1.2.0):**
- [x] **Tab 10: Genome Annotation** - Gene counts, RNA composition, hypothetical proteins
- [x] **Tab 11: Virulence Analysis** - VF distribution, top genes, heatmap (163 samples)
- [x] **Tab 12: Enhanced Prophage** - Quality-based charts, complete/partial analysis
- [x] **Tab 16: Prophage-Encoded AMR** - Prevalence, gene frequency, resistance classes, positive sample details

**Optional Tabs (v1.2.0):**
- [x] **Tab 13: Pangenome Analysis** - Core/soft-core/shell/cloud genes, frequency histogram
- [x] **Tab 14: Phylogenetic Tree** - Sample tree with 163 taxa
- [x] **Tab 15: SNP Analysis** - Distance histogram, statistics

### 4. Performance Check
With 163 samples, verify:
- [x] Page loads in <10 seconds
- [x] Tabs switch smoothly
- [x] Charts render without freezing
- [x] No JavaScript errors in browser console (F12)

---

## Troubleshooting

### Error: "Samplesheet not found"
```bash
# Check for available samplesheets
ls -la data/validation/*samplesheet*.csv

# Or create one:
# Format: sample,organism,fasta
# Point to your 163 genome FASTA files
```

### Error: "Not on 1.2.0-candidate branch"
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate
git checkout 1.2.0-candidate
git pull origin 1.2.0-candidate
```

### Warning: "No v1.0.1 work directory found"
This is OK! The script will run all modules from scratch. It will just take longer (24-48 hours instead of 6-12 hours).

### Panaroo Fails: "Need at least 2 samples"
Panaroo requires ≥2 samples for pangenome analysis. With 163 samples, this should not be an issue.

### IQ-TREE Skipped
IQ-TREE requires Panaroo to run first (uses core genome alignment). If Panaroo fails, IQ-TREE won't run.

### Snippy Skipped: "Reference genome not found"
The script uses the first genome in the samplesheet as reference. Verify:
```bash
# Check first genome path
head -2 data/validation/validation_samplesheet_fasta.csv

# Verify file exists
ls -lh /path/to/first/genome.fasta
```

---

## After Validation Completes

### If Everything Works ✅

1. **Document Results**
   - Update session notes
   - Add validation summary
   - Note any performance observations with 163 samples

2. **Prepare for Release**
   ```bash
   # Merge to main
   git checkout main
   git merge 1.2.0-candidate

   # Tag release
   git tag -a v1.2.0 -m "COMPASS v1.2.0 - Enhanced reporting and analysis"

   # Push
   git push origin main --tags
   ```

3. **Announce Release**
   - Update CHANGELOG.md
   - Create GitHub release
   - Document new features

### If Issues Found 🐛

1. **Document the Issue**
   - Specific error messages
   - Which module failed
   - Sample IDs affected

2. **Fix and Re-test**
   - Update code
   - Test with small dataset first
   - Re-run validation

---

## Estimated Timeline

| Stage | With v1.0.1 Cache | From Scratch |
|-------|-------------------|--------------|
| Core modules (cached) | ~1 hour | ~12 hours |
| Prokka (NEW) | 2-3 hours | 2-3 hours |
| VFDB (NEW) | 1-2 hours | 1-2 hours |
| VIBRANT (cached) | ~30 min | ~4 hours |
| Panaroo (NEW) | 2-4 hours | 2-4 hours |
| IQ-TREE (NEW) | 1-3 hours | 1-3 hours |
| Snippy (NEW) | 2-4 hours | 2-4 hours |
| **TOTAL** | **~6-12 hours** | **~24-48 hours** |

**Recommendation:** Always try to reuse v1.0.1 cache if available!

---

## Questions or Issues?

If you encounter problems:
1. Check the error log in the output directory
2. Review the Nextflow execution report
3. Look at session notes for known issues
4. Check browser console for HTML report errors

## Related Files

- `run_compass_validation_v1.2.0_163genomes.sh` - This validation script
- `bin/generate_compass_summary.py` - HTML report generator
- `test_compass_summary_v1.2.0_163genomes.sh` - HTML-only test (no pipeline run)
- `session-notes-2026-03-26-genomic-charts-fix.md` - Development notes
