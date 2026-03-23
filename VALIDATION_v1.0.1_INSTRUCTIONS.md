# COMPASS v1.0.1 Validation Instructions

## Overview

Before merging the AMRFinder organism mapping fix from `scratch` to `main` and tagging v1.0.1, we need to validate that the fix works correctly.

**Fix Summary:**
- **Issue:** AMRFinder failed for unsupported organisms (esp. Pseudomonas aeruginosa)
- **Root Cause:** Organism name mapping incomplete; no fallback to generic mode
- **Solution:** Added all 28 supported organism mappings + graceful generic mode fallback
- **Impact:** ~2,787 Pseudomonas samples in Phage Hunter study had empty AMR files

---

## Validation Test Suite

Two complementary tests validate the fix:

### Test 1: Diverse Organisms (20 samples)
**Script:** `validation_v1.0.1_test1_diverse.sh`

**Purpose:** Validate both supported AND unsupported organisms work correctly

**Test samples:**
- **Supported organisms (organism-specific mode):**
  - Vibrio cholerae (2 samples)
  - Staphylococcus aureus (2 samples)
  - Klebsiella pneumoniae (2 samples) ← **Previously broken!**
  - Enterococcus faecium (2 samples)
  - Escherichia coli (2 samples)

- **Unsupported organisms (generic mode fallback):**
  - Pseudomonas aeruginosa (2 samples) ← **Primary issue!**
  - Acinetobacter baumannii (2 samples)
  - Proteus mirabilis (2 samples)
  - Bacillus cereus (2 samples)
  - Arcobacter butzleri (2 samples)

**Expected result:** All 20 samples produce non-empty AMR files

**Runtime:** ~2-4 hours

---

### Test 2: Pseudomonas Focus (10 samples)
**Script:** `validation_v1.0.1_test2_pseudomonas.sh`

**Purpose:** Deep validation of the primary issue (Pseudomonas generic mode fallback)

**Test samples:**
- 10 Pseudomonas aeruginosa samples
- All should use generic mode (no `-O` flag to AMRFinder)

**Expected result:**
- ✅ All 10 samples produce non-empty AMR files
- ✅ AMRFinder runs without `-O` flag (generic mode)
- ✅ Gene-based AMR detection works (no point mutations, but genes detected)

**Runtime:** ~1-3 hours

---

## How to Run Validation on Beocat

### Step 1: Pull Updated scratch Branch

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline
git checkout scratch
git pull origin scratch
```

### Step 2: Submit Test 1 (Diverse Organisms)

```bash
sbatch validation_v1.0.1_test1_diverse.sh
```

**Monitor:**
```bash
squeue -u tylerdoe
tail -f /fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_*.out
```

### Step 3: Submit Test 2 (Pseudomonas Focus)

Can run in parallel with Test 1:

```bash
sbatch validation_v1.0.1_test2_pseudomonas.sh
```

**Monitor:**
```bash
tail -f /fastscratch/tylerdoe/validation_v1.0.1_test2_pseudomonas_*.out
```

---

## Validation Criteria

### Test 1 PASSES if:
- ✅ Pipeline completes without errors (exit code 0)
- ✅ All 20 AMR files created
- ✅ **Zero empty AMR files** (all organisms processed correctly)
- ✅ Supported organisms show organism-specific mode in logs
- ✅ Unsupported organisms show generic mode in logs

### Test 2 PASSES if:
- ✅ Pipeline completes without errors (exit code 0)
- ✅ All 10 Pseudomonas AMR files created
- ✅ **Zero empty Pseudomonas AMR files** (critical!)
- ✅ AMRFinder commands show NO `-O` flag (generic mode)
- ✅ AMR genes detected in all samples

---

## If Both Tests Pass

### 1. Merge scratch → main

```bash
cd /workspace  # or your local development environment
git checkout main
git merge scratch
git push origin main
```

### 2. Tag v1.0.1

```bash
git tag -a v1.0.1 -m "COMPASS v1.0.1 - AMRFinder organism mapping fix

Fixes:
- Add comprehensive organism name mapping for all 28 AMRFinder-supported organisms
- Implement graceful fallback to generic mode for unsupported organisms
- Fix Klebsiella species name mapping (Klebsiella_pneumoniae vs Klebsiella)
- Resolve Pseudomonas empty AMR file issue (~2,787 affected samples)

Validated:
- Test 1: 20 diverse organisms (supported + unsupported)
- Test 2: 10 Pseudomonas aeruginosa samples (generic mode)

Changes:
- modules/amrfinder.nf: Updated organism_map with all 28 organisms + fallback logic
- Added validation test suite for v1.0.1
"

git push origin v1.0.1
```

### 3. Deploy to Production on Beocat

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
git fetch --tags
git checkout v1.0.1
```

**Verify deployment:**
```bash
git log --oneline -1
git describe --tags
```

Should show:
```
v1.0.1
<commit hash> Fix AMRFinder organism mapping...
```

### 4. Re-run Affected Studies

#### Pseudomonas Phage Hunter Study
The primary beneficiary of this fix:

```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
sbatch pseudomonas_phage_hunter_monthly/run_pseudomonas_phage_hunter.sh
```

**What this fixes:**
- Previously: ~2,787 Pseudomonas samples with empty AMR files
- Now: All samples get gene-based AMR detection via generic mode
- Runtime: 7-10 days for full re-run

#### Other Studies to Consider
- Diverse Bacteria 1000 (if it had Klebsiella or unsupported organisms)
- Any study with mixed bacterial species

---

## If Tests Fail

### Debug Steps

1. **Check SLURM logs:**
   ```bash
   cat /fastscratch/tylerdoe/validation_v1.0.1_test1_diverse_<JOBID>.err
   cat /fastscratch/tylerdoe/validation_v1.0.1_test2_pseudomonas_<JOBID>.err
   ```

2. **Check AMRFinder work directory:**
   ```bash
   # Find failed AMRFinder tasks
   find /fastscratch/tylerdoe/validation_v1.0.1_test*/work -name ".command.err" -exec grep -l "amrfinder\|error" {} \;
   ```

3. **Verify organism mapping:**
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline
   grep "organism_map" modules/amrfinder.nf
   ```

4. **Check for empty AMR files:**
   ```bash
   find /fastscratch/tylerdoe/validation_v1.0.1_test*/results/amrfinder -name "*_amr.tsv" -size 0
   ```

5. **Inspect AMRFinder commands used:**
   ```bash
   grep -r "amrfinder" /fastscratch/tylerdoe/validation_v1.0.1_test*/work/*/*/.command.sh | head -20
   ```

### Common Issues

**Issue:** Empty Pseudomonas AMR files
- **Cause:** Generic mode not working; `-O` flag still present
- **Fix:** Check `modules/amrfinder.nf` - ensure Pseudomonas NOT in organism_map

**Issue:** Klebsiella fails with organism mismatch
- **Cause:** Still using genus-level "Klebsiella" instead of "Klebsiella_pneumoniae"
- **Fix:** Verify organism_map has species-level names

**Issue:** Pipeline crashes during AMRFinder
- **Cause:** AMRFinder database version mismatch
- **Fix:** Update AMRFinder database or check AMRFinder version

---

## Test Architecture Details

### Why FASTA Mode?
- **Faster:** Uses existing assemblies (no SRA downloads)
- **Reliable:** No storage issues from fasterq-dump
- **Focused:** Directly tests AMRFinder, not download/assembly
- **Reproducible:** Same assemblies can be re-tested

### Why Two Tests?
1. **Test 1 (Diverse):** Broad coverage ensures no regressions
2. **Test 2 (Pseudomonas):** Deep validation of the primary fix

### Auto-Checkout of scratch Branch
Both scripts automatically:
```bash
git fetch origin scratch
git checkout scratch
git pull origin scratch
```

This ensures they test the latest AMRFinder fix, not v1.0.0.

---

## Timeline

**Estimated validation time:** 4-6 hours total
- Test 1: 2-4 hours (20 samples)
- Test 2: 1-3 hours (10 samples)
- Can run in parallel

**Post-validation (if pass):**
- Merge + tag: 10 minutes
- Deploy to production: 5 minutes
- **Total time to v1.0.1 release:** Same day

---

## Success Criteria Summary

| Test | Samples | Key Validation | Status |
|------|---------|----------------|--------|
| Test 1 | 20 (10 organisms) | All non-empty, mixed modes | ⏳ Pending |
| Test 2 | 10 (Pseudomonas) | All non-empty, generic mode | ⏳ Pending |

**Release v1.0.1 when:** Both tests show ✅

---

## Contact

**Researcher:** Tyler Doerksen (tdoerks@vet.k-state.edu)
**Pipeline:** COMPASS v1.0.0 → v1.0.1
**GitHub:** https://github.com/tdoerks/COMPASS-pipeline
**Branch:** scratch (pre-release testing)

---

**Last Updated:** 2026-03-23
**Next Action:** Submit both validation tests on Beocat
