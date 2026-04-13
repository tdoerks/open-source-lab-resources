# ETEC Validation Run - COMPASS Pipeline Testing

## Overview

**Purpose:** Validate COMPASS pipeline improvements and new parsing scripts
**Organism:** Enterotoxigenic E. coli (ETEC)
**Sample size:** 100 genomes (small, fast validation run)
**Expected runtime:** 6-12 hours
**Pipeline version:** 1.0.1-candidate

---

## Why ETEC?

Perfect validation organism:
- **Fast:** 100 samples = ~6-12 hour runtime
- **Well-characterized:** Known AMR patterns, plasmids
- **Prophage-positive:** ETEC carries prophages (test VIBRANT)
- **Diverse:** Multiple pathotypes (test parsing scripts)
- **Clinical relevance:** Important diarrheal pathogen

---

## Validation Objectives

### 1. Test Pipeline Stability
- ✅ Verify 64GB SPAdes fix works
- ✅ Confirm no memory crashes
- ✅ Test resume functionality
- ✅ Validate all modules run correctly

### 2. Test New Parsing Scripts
- ✅ `parse_vibrant_summary.py` - Prophage detection
- ✅ `parse_mobsuite_plasmids.py` - Plasmid analysis
- ✅ `categorize_amr_by_location.py` - AMR location (KEY TEST)
- ✅ `create_master_results_table.py` - Data integration

### 3. Validate Output Quality
- ✅ Assembly quality (BUSCO, QUAST)
- ✅ AMR detection accuracy
- ✅ Plasmid reconstruction
- ✅ Prophage predictions

### 4. Performance Benchmarking
- ⏱️ Runtime per sample
- 💾 Memory usage
- 📊 Resource efficiency

---

## Sample Selection

**Query:**
```
Escherichia coli[Organism] AND
ETEC[All Fields] AND
illumina[Platform] AND
GENOMIC[Source] AND
WGS[Strategy]
```

**Sampling:** 100 random samples from 2020-2026
**Expected characteristics:**
- Enterotoxins: ST, LT
- Colonization factors: CFA/I, CS1-CS21
- AMR genes: Common beta-lactams, aminoglycosides
- Plasmids: High burden (ETEC is plasmid-rich)

---

## Files to Create

### 1. Download Script
**File:** `scripts/fetch_etec_validation.py`
- Based on proven Salmonella/Pseudomonas template
- 100 random ETEC samples
- HTTP API (no EDirect needed)

### 2. Samplesheet Generator
**File:** `scripts/create_samplesheet.py`
- Convert SRR list to COMPASS format

### 3. SLURM Submission Script
**File:** `run_etec_validation.sh`
- Pipeline: COMPASS 1.0.1-candidate
- Time limit: 24 hours (plenty of buffer)
- BUSCO enabled
- Resume enabled

### 4. Validation Test Script
**File:** `scripts/run_validation_tests.sh`
- Runs all 5 parsing scripts
- Validates outputs
- Generates summary report

---

## Expected Outputs

### Pipeline Results
```
etec_validation_results/
├── mlst/                # E. coli MLST typing
├── vibrant/             # Prophage predictions
├── mobsuite/            # Plasmid reconstructions (expect HIGH burden)
├── amrfinder/           # AMR genes (beta-lactams, aminoglycosides expected)
├── abricate/            # Multi-database AMR
├── busco/               # Quality assessment
├── quast/               # Assembly stats
└── multiqc/             # Integrated QC report
```

### Validation Outputs
```
validation_results/
├── vibrant_summary.tsv           # Prophage counts
├── mobsuite_summary.tsv          # Plasmid burden (expect 3-8/sample)
├── amr_location_matrix.tsv       # AMR categorization (KEY)
├── master_results_table.tsv      # All data combined
└── validation_report.txt         # Summary statistics
```

---

## Success Criteria

### Pipeline Execution
- [x] All 100 samples complete assembly
- [x] No memory crashes (SPAdes 64GB should be sufficient)
- [x] <5% sample failure rate
- [x] Resume works correctly if interrupted

### Parsing Scripts
- [x] All 5 scripts run without errors
- [x] Output formats are correct (TSV, proper columns)
- [x] Summary statistics make sense
- [x] No missing data for completed samples

### Scientific Validation
- [x] AMR genes detected (expect beta-lactams, aminoglycosides)
- [x] Plasmids detected (ETEC is plasmid-rich, expect 3-8/sample)
- [x] Prophages detected (some ETEC carry prophages)
- [x] Enterotoxin genes detected (ST, LT)

### Performance
- [x] Runtime: 6-12 hours for 100 samples (acceptable)
- [x] Memory: No OOM errors
- [x] Disk space: <100 GB total

---

## Timeline

| Step | Duration | Status |
|------|----------|--------|
| Create scripts | 30 min | ⏳ Pending |
| Download samples | 10 min | ⏳ Pending |
| Submit job | 1 min | ⏳ Pending |
| Pipeline execution | 6-12 hours | ⏳ Pending |
| Run parsing scripts | 5 min | ⏳ Pending |
| Validate results | 30 min | ⏳ Pending |
| Fix any bugs | 1-2 hours | ⏳ Pending |
| **Total** | **~8-15 hours** | ⏳ Pending |

---

## After Validation

### If Successful ✅
1. Tag as `v1.0.1` release
2. Copy to production directory
3. Update documentation
4. Use for Salmonella analysis when complete
5. Proceed with Phase 2 development

### If Issues Found ⚠️
1. Document bugs
2. Fix issues
3. Re-run validation
4. Update scripts
5. Repeat until clean

---

## Commands to Run

### On Local Machine (Create Scripts)
```bash
cd etec_validation_run
# Scripts will be created by Claude
```

### On Beocat (Execute Validation)
```bash
# Copy to Beocat
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate
cp -r etec_validation_run/ .

# Run download
cd etec_validation_run
python3 scripts/fetch_etec_validation.py

# Generate samplesheet
python3 scripts/create_samplesheet.py

# Submit job
sbatch run_etec_validation.sh

# Monitor
squeue -u tylerdoe
tail -f /fastscratch/tylerdoe/slurm-etec-validation-*.out

# After completion - run validation tests
bash scripts/run_validation_tests.sh
```

---

## Notes

- **Small sample size (100)** allows rapid iteration if bugs found
- **ETEC characteristics** (plasmid-rich, AMR-positive) test key features
- **Fast turnaround** enables quick validation cycle
- **Real-world test** of all new parsing scripts

---

**Ready to create the scripts?** Let me know and I'll generate:
1. `fetch_etec_validation.py`
2. `create_samplesheet.py`
3. `run_etec_validation.sh`
4. `run_validation_tests.sh`
