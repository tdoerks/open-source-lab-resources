# Session Notes: 2026-03-16 - AMRFinder Organism Mapping Fix

## Session Overview

**Date:** March 16, 2026
**Focus:** Fix AMRFinder producing 0-byte output files for unsupported organisms
**Branch:** `hotfix/v1.0.1-amrfinder`
**Status:** Testing in progress (Job 6976844 - Simple 3-organism validation)

---

## Problem Identified

### Issue
AMRFinder was producing **empty 0-byte output files** for organisms not in its supported organism list, particularly:
- **Pseudomonas aeruginosa**: All 2,787 samples in Phage Hunter study had 0-byte AMR files
- Other unsupported organisms likely affected

### Root Cause
1. AMRFinder was being called with `-O "Pseudomonas aeruginosa"`
2. AMRFinder doesn't recognize this organism (not in supported list)
3. The `|| true` flag was hiding failures, causing silent fails
4. No organism mapping existed for common organism names → AMRFinder codes

### Impact
- Pseudomonas aeruginosa: 100% failure (all samples)
- Vibrio cholerae: Working (organism supported, but no mapping implemented)
- Other unsupported organisms: Likely affected

---

## Solution Implemented

### Fix Details (commit `356599a`)

**File Modified:** `modules/amrfinder.nf`

**Changes:**

1. **Added organism name mapping** (lines 50-71):
   - Maps common organism names to AMRFinder-supported codes
   - Example: "Vibrio cholerae" → "Vibrio_cholerae"
   - Example: "Escherichia coli" → "Escherichia"
   - Includes 20 supported organisms

2. **Generic mode fallback** (line 75):
   - If organism not in mapping → runs without `-O` flag (generic mode)
   - Pseudomonas now runs in generic mode instead of failing

3. **Improved error handling** (lines 107-115):
   - Removed silent `|| true` flag
   - Logs warnings when AMRFinder fails
   - Creates empty files for pipeline continuity (prevents downstream crashes)
   - Distinguishes between "failed" vs "no results found"

4. **Diagnostic logging** (line 79):
   - Logs which mode is being used (organism-specific vs generic)
   - Helps troubleshooting

### Supported Organism Mapping

The fix includes mappings for:
- Acinetobacter baumannii → Acinetobacter_baumannii
- Campylobacter (genus-level)
- Clostridioides difficile → Clostridioides_difficile
- Enterococcus faecalis/faecium
- Escherichia (E. coli)
- Klebsiella
- Salmonella
- Staphylococcus aureus/pseudintermedius
- Streptococcus (multiple species)
- **Vibrio cholerae → Vibrio_cholerae** (your current run!)

### Unsupported Organisms (Generic Mode)
- Pseudomonas aeruginosa (main fix!)
- Citrobacter freundii
- Proteus mirabilis
- Serratia marcescens
- Any other organism not in AMRFinder database

---

## Testing Strategy

### Test 1: Quick Pseudomonas Test (Cancelled)
- **Job:** 6976707 (cancelled)
- **Purpose:** Test 5 Pseudomonas samples to verify fix
- **Status:** Cancelled in favor of simpler test

### Test 2: Comprehensive 12-Organism Test (Failed - Input Mode Issue)
- **Jobs:** 6976776, 6976830 (both failed)
- **Script:** `test_amrfinder_comprehensive.sh`
- **Issue:** Tried to use `samplesheet` input mode with CSV containing organism info
- **Problem:** COMPASS doesn't support multi-organism CSV in sra_list mode
- **Status:** Abandoned - created simpler test instead

### Test 3: Simple 3-Organism Validation (RUNNING) ✓
- **Job:** 6976844
- **Script:** `test_amrfinder_simple.sh`
- **Samples:** 3 organisms (1 sample each)
  - **SUPPORTED:** Vibrio cholerae (SRR19726915) - Should use `-O Vibrio_cholerae`
  - **UNSUPPORTED:** Pseudomonas aeruginosa (SRR15214188) - Should use generic mode
  - **EDGE CASE:** Enterococcus faecium (SRR15214193) - Should use `-O Enterococcus_faecium`
- **Method:** Uses `sra_list` mode with `--organism` parameter (3 separate pipeline runs)
- **Expected runtime:** 1-2 hours
- **Validation criteria:**
  - All 3 AMR files must be non-empty
  - Validates supported, unsupported, and edge case organisms
  - Proves fix works across critical categories

---

## Git Workflow

### Branches Created
1. **`hotfix/v1.0.1-amrfinder`** (from v1.0.0 commit `c8f8b18`)
   - Contains the AMRFinder fix
   - Commit: `356599a` - "Fix AMRFinder organism mapping for unsupported organisms"
   - Pushed to GitHub ✓

2. **`scratch`** (updated)
   - Merged hotfix: commit `966bf0f`
   - Added deployment guide: `v1.0.1_DEPLOYMENT.md`
   - Added test scripts

### Tag Status
- **v1.0.1**: Created, then deleted (waiting for test validation)
- Will re-create tag after comprehensive test passes

### Commands Used
```bash
# Create hotfix branch from v1.0.0
git checkout -b hotfix/v1.0.1-amrfinder c8f8b18

# Make fix to modules/amrfinder.nf
git add modules/amrfinder.nf
git commit -m "Fix AMRFinder organism mapping for unsupported organisms"
git push origin hotfix/v1.0.1-amrfinder

# Merge to scratch
git checkout scratch
git merge hotfix/v1.0.1-amrfinder

# Tag deleted (will re-create after testing)
git push --delete origin v1.0.1
git tag -d v1.0.1
```

---

## Active Jobs

### Vibrio cholerae Study (Ongoing - v1.0.0)
- **Job:** 6965706
- **Directory:** `/fastscratch/tylerdoe/COMPASS-pipeline-1.0.0`
- **Version:** v1.0.0 (no fix needed - Vibrio is supported)
- **Status:** Let it finish
- **Note:** Can re-run with v1.0.1 later for organism-specific mode

### AMRFinder Simple Test (Running)
- **Job:** 6976844
- **Directory:** `/fastscratch/tylerdoe/COMPASS-pipeline` (hotfix branch)
- **Version:** hotfix/v1.0.1-amrfinder
- **Expected completion:** ~1-2 hours
- **Email notification:** Enabled (tdoerks@vet.k-state.edu)
- **Tests:** 3 organisms (Vibrio, Pseudomonas, Enterococcus)

---

## Files Created

### Test Scripts
1. **`test_amrfinder_fix.sh`**
   - Simple 5-sample Pseudomonas test
   - Status: Cancelled before completion

2. **`test_amrfinder_comprehensive.sh`**
   - Comprehensive 12-organism validation
   - Status: Failed due to input mode incompatibility
   - Lesson: COMPASS sra_list mode doesn't support multi-organism CSV

3. **`test_amrfinder_simple.sh`** ✓
   - Simple 3-organism validation (1 sample each)
   - Tests: Vibrio (supported), Pseudomonas (unsupported), Enterococcus (edge case)
   - Uses sra_list mode with --organism parameter
   - **Currently running (Job 6976844)**

### Documentation
3. **`v1.0.1_DEPLOYMENT.md`**
   - Deployment guide for v1.0.1
   - What's new, how to update, testing instructions
   - Located in scratch branch

4. **`SESSION_NOTES_2026-03-16_amrfinder_fix.md`** (this file)
   - Complete session documentation

---

## Next Steps

### If Test Passes ✓
1. Review simple test results (3 organisms)
2. Verify all 3 AMR files are non-empty
3. Re-create v1.0.1 tag on hotfix branch:
   ```bash
   git checkout hotfix/v1.0.1-amrfinder
   git tag -a v1.0.1 -m "COMPASS Pipeline v1.0.1 - AMRFinder organism mapping fix"
   git push origin v1.0.1
   ```
4. Update production directory on Beocat:
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
   git fetch --tags
   git checkout v1.0.1
   ```
5. Update documentation
6. Consider merging hotfix to main branch

### If Test Fails ✗
1. Review failed organism(s)
2. Check AMRFinder error logs
3. Adjust organism mapping or error handling
4. Re-test

---

## Technical Details

### AMRFinder Supported Organisms
Reference: https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus#--organism-option

**Note:** AMRFinder uses underscores and specific naming:
- `Vibrio_cholerae` (not "Vibrio cholerae")
- `Escherichia` (genus-level, not "Escherichia coli")
- `Staphylococcus_aureus` (species-level)

### Pipeline Integration
- **Input:** `meta.organism` from samplesheet or `--organism` parameter
- **Mapping:** Groovy map in `modules/amrfinder.nf`
- **Output:** Organism-specific or generic AMR detection
- **Error handling:** Warns but doesn't crash pipeline

---

## Lessons Learned

1. **Silent failures are dangerous**: The `|| true` flag hid the problem for months
2. **Organism naming matters**: AMRFinder expects specific formats (underscores, genus vs species)
3. **Generic mode is valuable**: Not all organisms need organism-specific mode
4. **Comprehensive testing is critical**: Test across organism spectrum, not just one case
5. **Version control discipline**: Hotfix from release tag, not dev branch

---

## Contact

**Researcher:** Tyler Doerksen (tdoerks@vet.k-state.edu)
**Pipeline:** COMPASS v1.0.0 → v1.0.1
**HPC System:** Beocat (Kansas State University)

---

## Change Log

- **2026-03-16 18:00**: Identified Pseudomonas 0-byte AMR issue
- **2026-03-16 19:00**: Created hotfix branch, implemented organism mapping fix
- **2026-03-16 20:00**: Created and pushed hotfix to GitHub
- **2026-03-16 20:30**: Tagged v1.0.1, then deleted for testing
- **2026-03-16 21:00**: Created comprehensive 12-organism test script
- **2026-03-16 21:15**: Submitted comprehensive test (Job 6976776) - failed (Nextflow path issue)
- **2026-03-16 21:20**: Fixed Nextflow path, resubmitted (Job 6976830) - failed (input_mode issue)
- **2026-03-16 21:30**: Discovered COMPASS sra_list mode doesn't support multi-organism CSV
- **2026-03-16 21:45**: Created simple 3-organism test using sra_list mode properly
- **2026-03-16 22:00**: Submitted simple test (Job 6976844) - RUNNING ✓
- **2026-03-16 22:15**: Test progressing normally, waiting for results...

---

## Files Modified/Created

```
modules/amrfinder.nf                           # Core fix (hotfix branch)
test_amrfinder_fix.sh                          # First test attempt (scratch branch)
test_amrfinder_comprehensive.sh                # Comprehensive test (failed - scratch branch)
test_amrfinder_simple.sh                       # Simple test (RUNNING - scratch branch)
v1.0.1_DEPLOYMENT.md                           # Deployment guide (scratch branch)
SESSION_NOTES_2026-03-16_amrfinder_fix.md     # This file (scratch branch)
```

## Git Status

```
Branch: hotfix/v1.0.1-amrfinder (testing)
Branch: scratch (development, includes hotfix)
Tag: v1.0.1 (deleted, will recreate after testing)
Commit: 356599a (hotfix)
Remote: https://github.com/tdoerks/COMPASS-pipeline
```
