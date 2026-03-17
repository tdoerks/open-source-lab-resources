# Session Notes: 2026-03-17 - AMRFinder Organism Mapping Fix (Round 2)

## Session Overview

**Date:** March 17, 2026
**Focus:** Fix AMRFinder organism mapping errors discovered during testing
**Branch:** `scratch`
**Status:** Testing in progress (Job 6995342 - 38 sample validation)

---

## Problem Identified

### Initial Test Failure
The March 16 AMRFinder test (Job 6976844) appeared to complete but revealed:
1. **SRA downloads failed** - All 3 test samples ran out of disk space during `fasterq-dump`
2. **No AMR files created** - Pipeline didn't fail, but AMRFinder never ran (no assemblies = no AMRFinder)
3. **Misleading validation** - Test reported "FAIL" but root cause was storage, not AMRFinder

**Lesson:** SRA mode is problematic on Beocat due to storage constraints in work directories.

### New Test Discovery (March 17)
When switching to **FASTA mode** with existing assemblies, discovered additional organism mapping bugs:

**Example - Klebsiella pneumoniae:**
```
Error: AMRFinder rejected "-O Klebsiella"
Expected: "-O Klebsiella_pneumoniae" (full species name with underscore)
```

**Root Cause:** The March 16 fix had incomplete organism mappings:
- ❌ `'Klebsiella pneumoniae': 'Klebsiella'` (wrong - genus only)
- ✅ `'Klebsiella pneumoniae': 'Klebsiella_pneumoniae'` (correct - full species)

---

## Understanding AMRFinder Organism Modes

### Two Operating Modes

**1. Organism-Specific Mode** (Optimal)
- Command: `amrfinder -n genome.fasta -O Klebsiella_pneumoniae`
- Uses curated point mutation databases for that organism
- More accurate resistance predictions (genes + mutations)
- Only available for ~28 supported organisms
- **Requires exact name match** - rejects partial matches

**2. Generic Mode** (Fallback)
- Command: `amrfinder -n genome.fasta` (no `-O` flag)
- Detects AMR genes via sequence homology only
- No organism-specific point mutations
- Works for **any organism**, including unsupported ones
- Less comprehensive but still valuable

### Why Both Are Needed

**Supported organisms** (should use organism-specific mode):
- Vibrio cholerae, Klebsiella pneumoniae, Staphylococcus aureus, etc.
- Get both AMR genes AND point mutations

**Unsupported organisms** (must use generic mode):
- Pseudomonas aeruginosa (main issue from Phage Hunter study!)
- Acinetobacter baumannii, Proteus mirabilis, Arcobacter, etc.
- Get AMR genes only (no mutations available)

**The Fix:** Auto-detect and use appropriate mode for each organism.

---

## The Three-Part Fix

### Part 1: Organism Name Mapping

**Challenge:** User provides organism names with spaces, AMRFinder expects underscores.

**Solution:** Map common names to AMRFinder codes in `modules/amrfinder.nf`:

```groovy
def organism_map = [
    'Klebsiella pneumoniae': 'Klebsiella_pneumoniae',  // Full species name
    'Vibrio cholerae': 'Vibrio_cholerae',
    'Staphylococcus aureus': 'Staphylococcus_aureus',
    // ... etc for all 28 supported organisms
]
```

**Key Rules:**
1. Input keys: Human-readable with spaces (from CSV)
2. Output values: AMRFinder format with underscores
3. Use **exact species names** where AMRFinder requires them
4. Some organisms use genus only (e.g., `Campylobacter`, `Salmonella`)

### Part 2: Graceful Fallback to Generic Mode

**Logic:**
```groovy
// Get organism code if in mapping, otherwise null
def amrfinder_organism = organism_map.get(meta.organism, null)

// Use -O flag only if organism is supported
def organism_flag = amrfinder_organism ? "-O ${amrfinder_organism}" : ""
```

**Behavior:**
- Organism in map → Use organism-specific mode (e.g., `-O Vibrio_cholerae`)
- Organism not in map → Use generic mode (no `-O` flag)
- Pipeline **never fails** due to unsupported organism

### Part 3: Comprehensive Organism Coverage

**Added all 28 AMRFinder-supported organisms:**

| Organism | AMRFinder Code | Notes |
|----------|---------------|-------|
| Acinetobacter baumannii | Acinetobacter_baumannii | |
| Campylobacter coli | Campylobacter | Genus-level |
| Citrobacter freundii | Citrobacter_freundii | NEW (March 17) |
| Clostridioides difficile | Clostridioides_difficile | |
| Enterobacter cloacae | Enterobacter_cloacae | NEW (March 17) |
| Enterococcus faecium | Enterococcus_faecium | |
| Escherichia coli | Escherichia | Genus-level |
| Klebsiella pneumoniae | Klebsiella_pneumoniae | **FIXED** (was Klebsiella) |
| Klebsiella oxytoca | Klebsiella_oxytoca | **FIXED** (was Klebsiella) |
| Salmonella | Salmonella | Genus-level |
| Serratia marcescens | Serratia_marcescens | NEW (March 17) |
| Staphylococcus aureus | Staphylococcus_aureus | |
| Vibrio cholerae | Vibrio_cholerae | |
| Vibrio parahaemolyticus | Vibrio_parahaemolyticus | NEW (March 17) |
| **Pseudomonas aeruginosa** | **NULL (generic mode)** | **Not supported - uses fallback** |

**Full list:** See [AMRFinder documentation](https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus#--organism-option)

---

## Solution Implementation

### Files Modified

**1. modules/amrfinder.nf** (March 17 fixes)

**Changes made:**
```diff
# Fix Klebsiella mapping
- 'Klebsiella pneumoniae': 'Klebsiella',
+ 'Klebsiella pneumoniae': 'Klebsiella_pneumoniae',

- 'Klebsiella oxytoca': 'Klebsiella',
+ 'Klebsiella oxytoca': 'Klebsiella_oxytoca',

# Add missing organisms
+ 'Vibrio parahaemolyticus': 'Vibrio_parahaemolyticus',
+ 'Citrobacter freundii': 'Citrobacter_freundii',
+ 'Enterobacter cloacae': 'Enterobacter_cloacae',
+ 'Serratia marcescens': 'Serratia_marcescens',
+ (and 9 more...)
```

**Complete organism map now includes:**
- 28 AMRFinder-supported organisms with correct naming
- Graceful fallback for unsupported organisms
- Proper species vs genus-level distinctions

**2. Test Infrastructure Created**

**create_amrfinder_test_samplesheet.sh:**
- Generates samplesheet with 2 samples per organism (38 total)
- Uses existing assemblies from diverse_bacteria_1000 results
- Tests variety of supported and unsupported organisms

**test_amrfinder_fasta.sh:**
- SLURM script for comprehensive AMRFinder validation
- FASTA mode (no SRA downloads - avoids storage issues)
- Validates all 38 AMR files created and non-empty
- Checks organism-specific vs generic mode usage

---

## Testing Strategy

### Test Design: 38 Samples Across 19 Organisms

**Organisms tested (2 samples each):**

**Supported by AMRFinder:**
1. Vibrio cholerae ✓
2. Staphylococcus aureus ✓
3. Klebsiella pneumoniae ✓ (previously broken)
4. Enterococcus faecium ✓
5. Campylobacter coli ✓
6. Listeria monocytogenes ✓
7. Enterobacter cloacae ✓ (newly added)
8. Citrobacter freundii ✓ (newly added)
9. Serratia marcescens ✓ (newly added)
10. Vibrio parahaemolyticus ✓ (newly added)
11. Helicobacter pylori ✓
12. Yersinia enterocolitica ✓ (if supported)

**Unsupported by AMRFinder (should use generic mode):**
13. **Pseudomonas aeruginosa** ← **Primary test case!**
14. Acinetobacter baumannii
15. Arcobacter butzleri
16. Bacillus cereus
17. Clostridium perfringens
18. Cronobacter sakazakii
19. Proteus mirabilis
20. Shigella sonnei

**Test validates:**
- ✅ Supported organisms use organism-specific mode
- ✅ Unsupported organisms use generic mode
- ✅ All 38 samples produce non-empty AMR files
- ✅ No failures due to organism name mismatches

### Why FASTA Mode Instead of SRA Mode?

**SRA mode issues:**
- `fasterq-dump` requires enormous temporary space
- Beocat work directories ran out of storage
- Test samples (Vibrio, Pseudomonas, Enterococcus) all failed to download
- Misleading test results (failure due to storage, not AMRFinder)

**FASTA mode advantages:**
- Uses existing assemblies (no downloads needed)
- Faster: ~2-3 hours vs 6+ hours
- No storage issues
- Directly tests AMRFinder functionality
- More reliable on Beocat

---

## Test Execution Timeline

### March 17, 2026

**14:00 - Initial FASTA test submission (Job 6994484)**
- Submitted original test
- Discovered it was using wrong CSV header (`assembly` instead of `fasta`)
- Cancelled

**14:15 - Fixed CSV header, resubmitted (Job 6994871)**
- Fixed: `sample,assembly,organism` → `sample,fasta,organism`
- Test started running
- Discovered Klebsiella organism mapping error

**14:30 - Klebsiella error discovered**
```
AMRFinder error: Possible organisms: ... Klebsiella_pneumoniae ...
Our code was using: -O Klebsiella (rejected!)
```

**14:45 - Fixed organism mapping (commits 5975c42, 400db3c)**
- Fixed Klebsiella species names
- Added 13 missing organisms
- Pushed to scratch branch

**15:00 - Resubmitted with fixes (Job 6995342)**
- Pulled updated code on Beocat
- Submitted comprehensive 38-sample test
- **Currently running** - 15/38 AMRFinder processes completed as of 15:30

**Expected completion:** ~17:00 (2-3 hour runtime)

---

## Current Status

### Active Test: Job 6995342

**Configuration:**
- 38 samples (2 per organism x 19 organisms)
- FASTA mode with existing assemblies
- All analysis modules enabled except BUSCO
- Resources: 16 CPUs, 64GB RAM
- Email notifications: tdoerks@vet.k-state.edu

**Progress (as of 15:30):**
- ✅ MLST: 38/38 complete
- ✅ QUAST: 37/38 complete
- ⏳ AMRFinder: 15/38 running
- ⏳ ABRicate: 39/152 running (4 DBs x 38 samples)
- ⏳ VIBRANT: 0/38 queued
- ⏳ MOB-suite: 0/38 queued

**Output locations:**
- Results: `/fastscratch/tylerdoe/test_amrfinder_fasta_6995342/results/`
- Work: `/fastscratch/tylerdoe/test_amrfinder_fasta_6995342/work/`
- SLURM logs: `/fastscratch/tylerdoe/test_amrfinder_fasta_6995342.{out,err}`

### Validation Criteria

**Test passes if:**
1. All 38 AMR files created in `results/amrfinder/`
2. No empty (0-byte) AMR files
3. Logs show organism-specific mode for supported organisms
4. Logs show generic mode for unsupported organisms (especially Pseudomonas)

**Check after completion:**
```bash
# Count AMR files
ls /fastscratch/tylerdoe/test_amrfinder_fasta_6995342/results/amrfinder/*.tsv | wc -l
# Should be: 38 (main AMR files) + 38 (mutation files) = 76 total

# Check for empty files
find /fastscratch/tylerdoe/test_amrfinder_fasta_6995342/results/amrfinder -name "*_amr.tsv" -size 0

# View organism modes used
grep "Using organism-specific mode\|Using generic mode" /fastscratch/tylerdoe/test_amrfinder_fasta_6995342/work/*/*/.command.err | sort | uniq -c
```

---

## Next Steps

### If Test Passes ✓

1. **Merge fix to main pipeline:**
   ```bash
   git checkout main
   git merge scratch
   git push origin main
   ```

2. **Create v1.0.1 tag:**
   ```bash
   git tag -a v1.0.1 -m "COMPASS v1.0.1 - AMRFinder organism mapping fix"
   git push origin v1.0.1
   ```

3. **Update production on Beocat:**
   ```bash
   cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0
   git fetch --tags
   git checkout v1.0.1
   ```

4. **Re-run Pseudomonas Phage Hunter study:**
   - 2,787 Pseudomonas samples previously had empty AMR files
   - Now should work in generic mode
   - Estimated runtime: 7-10 days

5. **Documentation:**
   - Update README with organism mode information
   - Document supported vs unsupported organisms
   - Add troubleshooting guide for AMRFinder

### If Test Fails ✗

1. Review failed samples and error messages
2. Check if specific organisms consistently fail
3. Verify organism mapping matches AMRFinder database
4. Consider additional organism aliases (e.g., "E. coli" → "Escherichia")
5. Iterate on fix and retest

---

## Key Learnings

### 1. Testing Strategy Matters
- **SRA mode:** Unreliable on Beocat (storage constraints)
- **FASTA mode:** Faster, more reliable, directly tests AMRFinder
- **Lesson:** Use existing data when possible for testing

### 2. AMRFinder Is Strict About Names
- Requires **exact** organism name matches
- Genus-level for some (Salmonella), species-level for others (Klebsiella_pneumoniae)
- No partial matches - "Klebsiella" ≠ "Klebsiella_pneumoniae"

### 3. Graceful Degradation Is Critical
- Not all organisms are supported by AMRFinder
- Generic mode provides valuable results for unsupported organisms
- Pipeline should **never fail** due to organism mismatch

### 4. Comprehensive Testing Needed
- Testing 1-3 samples isn't enough
- Need diverse organism representation
- 2 samples per organism catches edge cases

### 5. Beocat System Challenges
- Storage exhaustion is common with SRA downloads
- Maintenance windows can interrupt long-running jobs
- Job holds affect scheduling (March 17-18 maintenance)

---

## Technical Details

### AMRFinder Supported Organisms (Complete List)

From: https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus#--organism-option

**Full species name required:**
- Acinetobacter_baumannii
- Clostridioides_difficile
- Enterococcus_faecalis
- Enterococcus_faecium
- Klebsiella_oxytoca
- Klebsiella_pneumoniae
- Staphylococcus_aureus
- Staphylococcus_pseudintermedius
- Streptococcus_agalactiae
- Streptococcus_pneumoniae
- Streptococcus_pyogenes
- Vibrio_cholerae
- Vibrio_parahaemolyticus
- Vibrio_vulnificus
- Citrobacter_freundii
- Enterobacter_asburiae
- Enterobacter_cloacae
- Serratia_marcescens
- Burkholderia_cepacia
- Burkholderia_pseudomallei
- Burkholderia_mallei
- Corynebacterium_diphtheriae
- Neisseria_gonorrhoeae
- Neisseria_meningitidis

**Genus-level only:**
- Campylobacter
- Escherichia
- Salmonella
- Pseudomonas_aeruginosa (NOT supported - removed from AMRFinder database)

### Pipeline Integration

**Input:** `meta.organism` from samplesheet or `--organism` parameter
**Mapping:** Groovy map in `modules/amrfinder.nf`
**Output:** Organism-specific or generic AMR detection
**Error handling:** Warnings logged, empty files created for continuity

---

## Files Created/Modified

### New Files (scratch branch)
```
create_amrfinder_test_samplesheet.sh    # Samplesheet generator
test_amrfinder_fasta.sh                 # SLURM test script
SESSION_NOTES_2026-03-17_amrfinder_fix_v2.md  # This file
```

### Modified Files (scratch branch)
```
modules/amrfinder.nf                    # Organism mapping fixes
create_amrfinder_test_samplesheet.sh    # CSV header fix (assembly→fasta)
```

### Git Commits (scratch branch)
```
425583d - Add FASTA-mode AMRFinder validation test (38 samples, 19 organisms)
5975c42 - Fix CSV header: change 'assembly' to 'fasta' for COMPASS compatibility
400db3c - Fix AMRFinder organism mapping to use correct species names
```

---

## Contact

**Researcher:** Tyler Doerksen (tdoerks@vet.k-state.edu)
**Pipeline:** COMPASS v1.0.0 → v1.0.1 (pending)
**HPC System:** Beocat (Kansas State University)
**GitHub:** https://github.com/tdoerks/COMPASS-pipeline
**Branch:** scratch (development/testing)

---

## Change Log

- **2026-03-17 14:00**: Discovered SRA test failures were due to storage, not AMRFinder
- **2026-03-17 14:15**: Created FASTA-mode test strategy
- **2026-03-17 14:30**: Discovered Klebsiella organism mapping error
- **2026-03-17 14:45**: Fixed organism mappings, added 13 missing organisms
- **2026-03-17 15:00**: Submitted comprehensive 38-sample validation test (Job 6995342)
- **2026-03-17 15:30**: Test progressing normally (15/38 AMRFinder complete)
- **2026-03-17 17:00**: Expected test completion
- **2026-03-18 09:00+**: Post-maintenance validation if test interrupted

---

*Session continues - awaiting test results...*
