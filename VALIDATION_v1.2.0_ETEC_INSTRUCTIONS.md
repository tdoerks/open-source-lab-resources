# COMPASS v1.2.0 ETEC Validation Instructions

## Quick Start (On Beocat)

```bash
# 1. Go to the 1.2.0-candidate directory
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate

# 2. Pull latest changes (includes validation script)
git pull origin 1.2.0-candidate

# 3. Copy ETEC files from 1.0.1-candidate (if not already present)
cp /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_samplesheet.csv data/validation/
cp -r /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_genomes data/validation/

# 4. Submit validation job
sbatch data/validation/run_etec_validation_v1.2.0.sh
```

---

## What This Tests

### v1.2.0 Features
- ✅ **Prokka annotation** (enabled for testing)
- ✅ **FastQC/fastp** - Read QC
- ✅ **BUSCO** - Assembly quality/contamination
- ✅ **MLST** - Sequence typing
- ✅ **MOB-suite** - Plasmid detection (ETEC is plasmid-rich!)
- ✅ **ABRicate** - Multi-database AMR screening
- ✅ **MultiQC** - Integrated reporting
- ✅ **AMRFinder organism mapping fix** (from v1.0.1)

### Test Dataset
- **8 ETEC strains** from doi:10.1038/s41598-021-88316-2
- Same strains used for v1.0.0 and v1.0.1 validation
- Expected runtime: 4-6 hours
- Expected plasmids: ETEC typically carries multiple plasmids

---

## Expected Results Structure

```
data/validation/etec_results_v1.2.0/
├── amrfinder/          # AMR gene predictions
├── vibrant/            # Prophage predictions
├── mobsuite/           # Plasmid reconstructions
├── prokka/             # NEW: Genome annotations
├── mlst/               # Sequence typing
├── busco/              # Assembly QC
├── fastqc/             # Read quality
├── fastp/              # Trimmed reads
├── abricate/           # Multi-DB AMR
├── multiqc/            # Integrated report
└── pipeline_info/      # Execution reports
```

---

## After Job Completes - Test Parsing Scripts

The validation script will print these commands. Run them to test all 5 new parsing tools:

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/data/validation/etec_results_v1.2.0

# 1. Parse VIBRANT prophage predictions
python3 ../../bin/parse_vibrant_summary.py \
  --vibrant vibrant/ \
  --output vibrant_summary.tsv

# 2. Parse MOB-suite plasmid detections
python3 ../../bin/parse_mobsuite_plasmids.py \
  --mobsuite mobsuite/ \
  --output mobsuite_summary.tsv

# 3. Categorize AMR by genomic location (CRITICAL SCRIPT)
python3 ../../bin/categorize_amr_by_location.py \
  --amrfinder amrfinder/ \
  --mobsuite mobsuite/ \
  --vibrant vibrant/ \
  --output amr_location_matrix.tsv

# 4. Create master results table (integrates everything)
python3 ../../bin/create_master_results_table.py \
  --results-dir . \
  --output master_results_table.tsv

# 5. Parse SISTR (will skip for ETEC, only works on Salmonella)
# (Not applicable for ETEC validation)
```

---

## Validation Checklist

After job completes, verify:

### Pipeline Execution
- [ ] All 8 ETEC samples completed
- [ ] No SLURM errors in log files
- [ ] Exit code 0 (success)

### Module Outputs
- [ ] AMRFinder TSV files created (8 files)
- [ ] **Prokka outputs present** (`prokka/` directory with 8 subdirs)
- [ ] MOB-suite detected plasmids (ETEC should have plasmids!)
- [ ] VIBRANT prophage predictions
- [ ] MLST sequence types assigned
- [ ] BUSCO completeness scores >80%
- [ ] MultiQC report generated

### Parsing Scripts
- [ ] All 5 scripts run without errors
- [ ] `vibrant_summary.tsv` created
- [ ] `mobsuite_summary.tsv` created
- [ ] `amr_location_matrix.tsv` created
- [ ] `master_results_table.tsv` created
- [ ] Master table has 8 rows (one per sample)

### Scientific Validation
- [ ] AMR genes detected (ETEC typically carries AMR)
- [ ] Plasmids detected (ETEC is plasmid-rich)
- [ ] AMR location categorization logical (expect AMR on plasmids)
- [ ] Prokka gene counts reasonable (~4000-5000 genes for E. coli)

---

## Comparing to v1.0.1

You can compare results to the v1.0.1 validation:

```bash
# v1.0.1 results location
ls /bulk/tylerdoe/archives/ETEC_Validation_v1.0.1_2026-03-23/

# Compare AMRFinder outputs
diff -u \
  /bulk/tylerdoe/archives/ETEC_Validation_v1.0.1_2026-03-23/amrfinder/E925_amr.tsv \
  /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/data/validation/etec_results_v1.2.0/amrfinder/E925_amr.tsv
```

**Expected:** AMRFinder results should be identical between v1.0.1 and v1.2.0 (same fix applied)

**New in v1.2.0:** Additional outputs (Prokka, MOB-suite, etc.)

---

## Monitoring the Job

```bash
# Check job status
squeue -u tylerdoe | grep etec

# Follow SLURM output
tail -f /homes/tylerdoe/slurm-etec-validation-v1.2.0-*.out

# Check Nextflow log
tail -f /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/.nextflow.log
```

---

## If Validation Passes ✅

1. Archive results to bulk:
   ```bash
   rsync -av --progress \
     /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate/data/validation/etec_results_v1.2.0/ \
     /bulk/tylerdoe/archives/ETEC_Validation_v1.2.0_$(date +%Y-%m-%d)/
   ```

2. Tag v1.2.0 release:
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline-1.2.0-candidate
   git tag -a v1.2.0 -m "v1.2.0: Prokka annotation + 5 parsing scripts + all v1.0.1 fixes"
   git push origin v1.2.0
   ```

3. Update documentation

4. Use for production analyses!

---

## If Validation Fails ❌

1. Check error logs:
   - SLURM error: `/homes/tylerdoe/slurm-etec-validation-v1.2.0-*.err`
   - Nextflow log: `.nextflow.log`
   - Process logs: `work/` subdirectories

2. Document issues in GitHub

3. Fix on 1.2.0-candidate branch

4. Re-run validation

---

## Troubleshooting

### "etec_samplesheet.csv not found"
```bash
cp /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_samplesheet.csv data/validation/
cp -r /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/data/validation/etec_genomes data/validation/
```

### "Not on 1.2.0-candidate branch"
```bash
git checkout 1.2.0-candidate
git pull
```

### Memory errors
The script requests 64GB which should be sufficient. If issues occur, check individual process logs.

---

## Expected Timeline

| Step | Duration |
|------|----------|
| Job submission | 1 min |
| Pipeline execution | 4-6 hours |
| Parsing scripts | 5 min |
| Result review | 30 min |
| **Total** | **~5-7 hours** |

---

## Key Differences from v1.0.1

| Feature | v1.0.1 | v1.2.0 |
|---------|--------|--------|
| Modules | 5 | 30 |
| Prokka annotation | ❌ | ✅ |
| Read QC | ❌ | ✅ |
| Assembly QC (BUSCO) | ❌ | ✅ |
| Plasmid detection | ❌ | ✅ |
| Multi-DB AMR | ❌ | ✅ |
| Parsing scripts | 0 | 5 |
| Integrated reporting | ❌ | ✅ |
| AMR location analysis | ❌ | ✅ |

---

## Resources

- **Memory:** 64GB (handles all new modules)
- **CPUs:** 16 (parallel processing)
- **Time:** 6 hours (generous for 8 samples)
- **NXF_OPTS:** 8GB JVM heap (larger pipeline needs more memory)

---

## Success Criteria

### Must Have
- ✅ Pipeline completes with exit code 0
- ✅ All 8 AMR files created
- ✅ Prokka outputs present for all 8 samples
- ✅ All 5 parsing scripts run successfully

### Should Have
- ✅ Plasmids detected by MOB-suite
- ✅ AMR genes categorized by location
- ✅ Master results table complete
- ✅ Results consistent with v1.0.1 (for shared modules)

### Nice to Have
- ✅ MultiQC report looks good
- ✅ No warning messages
- ✅ Fast runtime (<4 hours)

---

## Questions?

Check session notes: `SESSION_NOTES_2026-03-24_1.2.0_candidate_setup.md`

---

**Ready to test v1.2.0!** 🚀
