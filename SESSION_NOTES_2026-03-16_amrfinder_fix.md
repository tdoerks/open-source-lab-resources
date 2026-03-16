# Session Notes: 2026-03-16 - AMRFinder Organism Mapping Fix

## Session Overview

**Date:** March 16, 2026
**Focus:** Fix AMRFinder producing 0-byte output files for unsupported organisms
**Branch:** `hotfix/v1.0.1-amrfinder`
**Status:** Testing in progress (Job 6976776)

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
- **Status:** Cancelled in favor of comprehensive test

### Test 2: Comprehensive Validation (RUNNING)
- **Job:** 6976776
- **Script:** `test_amrfinder_comprehensive.sh`
- **Samples:** 12 organisms across 3 categories
  - **Supported (4):** E. coli, Salmonella, Vibrio cholerae, Klebsiella
  - **Unsupported (4):** Pseudomonas, Citrobacter, Proteus, Serratia
  - **Edge cases (4):** Campylobacter, Enterococcus, Staph, Acinetobacter
- **Expected runtime:** 2-4 hours
- **Validation criteria:**
  - All 12 AMR files must be non-empty
  - Supported organisms use `-O` flag
  - Unsupported organisms use generic mode
  - No silent failures

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

### AMRFinder Comprehensive Test (Running)
- **Job:** 6976776
- **Directory:** `/fastscratch/tylerdoe/COMPASS-pipeline` (hotfix branch)
- **Version:** hotfix/v1.0.1-amrfinder
- **Expected completion:** ~2-4 hours
- **Email notification:** Enabled (tdoerks@vet.k-state.edu)

---

## Files Created

### Test Scripts
1. **`test_amrfinder_fix.sh`**
   - Simple 5-sample Pseudomonas test
   - Status: Not used (cancelled)

2. **`test_amrfinder_comprehensive.sh`**
   - Comprehensive 12-organism validation
   - Downloads fresh samples from NCBI
   - Tests all organism categories
   - Automated pass/fail reporting
   - **Currently running**

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
1. Review comprehensive test results
2. Re-create v1.0.1 tag on hotfix branch
3. Push tag to GitHub
4. Update production directory on Beocat:
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
   git fetch --tags
   git checkout v1.0.1
   ```
5. Update documentation
6. Consider merging to main branch

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
- **2026-03-16 21:00**: Created comprehensive test script
- **2026-03-16 21:15**: Submitted comprehensive test (Job 6976776)
- **2026-03-16 21:30**: Waiting for test results...

---

## Files Modified

```
modules/amrfinder.nf                           # Core fix
test_amrfinder_comprehensive.sh                # Validation script
v1.0.1_DEPLOYMENT.md                           # Deployment guide
SESSION_NOTES_2026-03-16_amrfinder_fix.md     # This file
```

## Git Status

```
Branch: hotfix/v1.0.1-amrfinder (testing)
Branch: scratch (development, includes hotfix)
Tag: v1.0.1 (deleted, will recreate after testing)
Commit: 356599a (hotfix)
Remote: https://github.com/tdoerks/COMPASS-pipeline
```
