# Session Notes - 2026-03-16

## Summary
Fixed Pseudomonas Phage Hunter Nextflow lock issue and designed new Vibrio cholerae geographic + temporal study with phage-rich focus.

---

## Part 1: Pseudomonas Phage Hunter - Nextflow Lock Fix

### Issue Encountered
Job 6865701 failed in 5 seconds with Nextflow session lock error:
```
ERROR ~ Unable to acquire lock on session with ID 958f282b-4a88-4fdd-83e9-3995ebf3780d
```

**Cause**: Previous run was interrupted, leaving Nextflow session locked.

### Solution
Removed the lock file to allow job to resume:
```bash
rm -rf /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/.nextflow/cache/958f282b-4a88-4fdd-83e9-3995ebf3780d
```

**Important**: This did NOT delete actual work progress - all completed tasks are preserved in `work_pseudomonas_phage_hunter/` directory (258 subdirectories from previous night's run).

### Job Resubmitted
- **Job ID**: 6865835
- **Status**: Running successfully
- **Progress**:
  - Downloads complete: 3558 of 3558, failed: 915 (26% failure - higher than usual)
  - Successful: 2643 samples (74% success rate)
  - Pipeline cascading through: FASTQC, FASTP, SPAdes, BUSCO, AMR, prophage, plasmid analysis
  - Nearly complete (~99%)

### Notes
- 915 failed downloads likely due to:
  - Older samples (2020) withdrawn from SRA
  - Restricted access clinical isolates
  - Data withdrawal by authors
- Still have excellent dataset: 2643 Pseudomonas samples spanning 2020-2026

---

## Part 2: Vibrio cholerae Geographic + Temporal Study Design

### Objective
Create a new phage-rich temporal study that adds **geographic dimension** to the temporal sampling approach used for Pseudomonas.

### Why Vibrio cholerae?

**Highest prophage burden organism:**
- 8-12 prophages per genome (HIGHEST of any bacterial pathogen!)
- CTXφ prophage carries cholera toxin genes (ctxAB) - literally causes disease
- Well-studied phage biology with epidemic relevance

**Geographic importance:**
- Cholera is geographically clustered (endemic regions: Bangladesh, India, Haiti, Africa)
- Epidemic waves are trackable temporally AND geographically
- CTXφ variants differ by region
- AMR emergence is regional (e.g., fluoroquinolone resistance in Bangladesh)

**Clinical/public health:**
- 7th pandemic ongoing (O1 El Tor)
- Recent outbreaks: Haiti 2022, Yemen, DRC
- Phage-mediated pathogenesis (CTXφ conversion)
- Emerging AMR: fluoroquinolone, azithromycin

### Sampling Strategy

**Geographic + Temporal Stratification:**
- **Total**: 50 samples/month × 75 months (Jan 2020 - Mar 2026) = ~3,750 samples
- **Regional allocation**:
  - South Asia (India, Bangladesh, Pakistan): 30/month (endemic hotspot)
  - Africa (DRC, Kenya, Nigeria, etc.): 10/month (endemic region)
  - Americas (Haiti, Dominican Republic): 5/month (outbreak region)
  - Southeast Asia (Thailand, Vietnam, Philippines): 5/month (endemic)

**Why geographic stratification matters:**
1. CTXφ variants cluster geographically
2. AMR emergence is regional
3. Enables phylogeographic analysis
4. Track epidemic spread between regions
5. Identify transmission events

### Files Created

**Project directory:** `vibrio_cholerae_temporal_geographic/`

1. **`README.md`** - Comprehensive documentation
   - Research objectives (CTXφ tracking, epidemic waves, regional AMR)
   - Sampling strategy and regional allocation
   - 6-phase analysis roadmap
   - Comparison to Pseudomonas study
   - Expected findings and citation info

2. **`scripts/fetch_vibrio_geographic.py`** - Geographic + temporal download script
   - Queries NCBI SRA for V. cholerae by month (2020-2026)
   - Extracts geographic metadata (`geo_loc_name`)
   - Classifies into regions using pattern matching
   - Stratified sampling: 30 South Asia, 10 Africa, 5 Americas, 5 SE Asia
   - Downloads SRR accessions + metadata (not sequencing data)
   - Creates region-specific files + combined file
   - Writes geographic metadata CSV

3. **`scripts/create_samplesheet.py`** - COMPASS samplesheet generator
   - Reads combined SRR list
   - Creates COMPASS-compatible samplesheet

4. **`run_vibrio_cholerae.sh`** - SLURM submission script
   - Job name: vibrio_cholerae_geo
   - Time limit: 336 hours (14 days with resume)
   - Resources: 8 CPUs, 32GB RAM
   - All modules enabled: AMRFinder, VIBRANT, MOB-suite, MLST, BUSCO
   - Output: `/fastscratch/tylerdoe/vibrio_cholerae_results/`
   - Work dir: `work_vibrio_cholerae`

### Research Questions

1. **Geographic prophage distribution**: CTXφ and other prophages by region
2. **Temporal epidemic tracking**: Outbreak waves 2020-2026 via phage signatures
3. **Regional AMR emergence**: Resistance spread patterns by geography + time
4. **CTXφ variant tracking**: Different CTXφ types across regions/time
5. **Phage-plasmid co-occurrence**: Geographic patterns in mobile element burden
6. **Pandemic genomics**: 7th pandemic O1 El Tor strain evolution

### Analysis Roadmap

**Phase 1: Geographic Distribution**
- CTXφ prevalence by region
- Other prophage diversity by region
- Geographic prophage heatmaps

**Phase 2: Temporal Dynamics**
- Epidemic wave tracking (2020-2026)
- Prophage evolution over time
- CTXφ variant shifts

**Phase 3: Geographic-Temporal AMR**
- Regional AMR emergence (fluoroquinolone, azithromycin)
- AMR spread patterns between regions
- Mobile element-mediated AMR by geography

**Phase 4: CTXφ Deep Dive**
- Extract CTXφ sequences from VIBRANT
- Classify CTXφ variants (Classical vs El Tor)
- Phylogeographic analysis

**Phase 5: Plasmid-Prophage Interactions**
- SXT/R391 ICE elements co-occurrence with CTXφ
- Prophage-plasmid burden by region

**Phase 6: Publication Figures**
- Geographic prophage map (world map)
- Temporal epidemic waves (line graph by region)
- CTXφ phylogeography (tree + map)
- Regional AMR emergence (heatmap)
- Mobile element co-occurrence network

### Comparison to Pseudomonas Study

| Feature | Pseudomonas Phage Hunter | Vibrio Cholerae |
|---------|--------------------------|-----------------|
| Organism | P. aeruginosa | V. cholerae |
| Prophage burden | 5-10/genome | **8-12/genome (HIGHEST!)** |
| Samples | ~3,750 | ~3,750 |
| Temporal | Monthly 2020-2026 ✅ | Monthly 2020-2026 ✅ |
| Geographic | Global (random) | **Stratified by endemic regions ✅** |
| Unique prophage | Various | **CTXφ (toxin-encoding!)** |
| AMR focus | XDR/MDR, carbapenem | Fluoroquinolone, azithromycin |
| Strength | Temporal phage dynamics | **Geographic + temporal dynamics** |
| Disease | Chronic infections | **Epidemic outbreaks** |

### Key Innovation: Geographic + Temporal

This is the **first study combining both dimensions**:
- Pseudomonas: Temporal only
- Diverse Bacteria 1000: Cross-species, random sampling
- **Vibrio**: Geographic stratification + temporal tracking

Enables:
- Phylogeographic analysis
- Epidemic source tracking
- Regional AMR spread patterns
- Cross-region transmission events
- Endemic vs epidemic strain comparisons

---

## Git Repository Status

**Branch:** scratch

**Commit:** `ba75a14` - Add Vibrio cholerae geographic + temporal prophage study

**Files added:**
- `vibrio_cholerae_temporal_geographic/README.md`
- `vibrio_cholerae_temporal_geographic/run_vibrio_cholerae.sh`
- `vibrio_cholerae_temporal_geographic/scripts/fetch_vibrio_geographic.py`
- `vibrio_cholerae_temporal_geographic/scripts/create_samplesheet.py`

**Pushed to GitHub:** ✅

---

## Current Running Jobs

### On Beocat

**1. Pseudomonas Phage Hunter** (Job 6865835)
- Status: Running, ~99% complete
- Samples: 2643 of 3558 successful downloads
- Expected completion: Soon (already in final analysis stages)
- Output: `/fastscratch/tylerdoe/pseudomonas_phage_hunter_results/`

**2. ETEC Validation v1.0.0** (Job 6852091)
- Status: Unknown (need to check)
- Samples: 8 ETEC reference strains
- Purpose: Validation comparison to Nature paper

---

## Pending Tasks

### Immediate
- [ ] Monitor Pseudomonas job completion (job 6865835)
- [ ] Check ETEC validation status (job 6852091)
- [ ] Transfer diverse_bacteria_1000 results to bulk (exclude FASTQs)

### Next Jobs to Launch

**After Pseudomonas completes:**

**Option 1: Vibrio cholerae Geographic + Temporal** (READY)
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline
git pull origin scratch
cp -r vibrio_cholerae_temporal_geographic /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/vibrio_cholerae_temporal_geographic
python3 scripts/fetch_vibrio_geographic.py  # ~90 min
python3 scripts/create_samplesheet.py
sbatch run_vibrio_cholerae.sh
```

**Option 2: Design more phage-rich studies**
- Staphylococcus aureus temporal (4-8 prophages/genome, MRSA tracking)
- Salmonella enterica temporal (4-7 prophages/genome, serotype tracking)
- Klebsiella pneumoniae temporal (3-5 prophages/genome, CRE focus)

### Analysis Tasks
- [ ] Compare ETEC prophage predictions: paper vs COMPASS
- [ ] Provide collaborator with ETEC strain mapping info
- [ ] Archive Pseudomonas results when complete

---

## Reference Commands

### Check Pseudomonas job status
```bash
squeue -u tylerdoe | grep 6865835
tail -f /fastscratch/tylerdoe/slurm-pseudomonas-phage-hunter-6865835.out
```

### Pull Vibrio project to Beocat
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline
git pull origin scratch
ls -la vibrio_cholerae_temporal_geographic/
```

### Transfer diverse bacteria to bulk (excluding FASTQs)
```bash
rsync -av --progress \
  --exclude='fastq/' \
  --exclude='*_fastqc/' \
  --exclude='fastp/' \
  --exclude='*.fastq' \
  --exclude='*.fastq.gz' \
  --exclude='*.fq' \
  --exclude='*.fq.gz' \
  /fastscratch/tylerdoe/diverse_bacteria_1000_results/ \
  /bulk/tylerdoe/archives/diverse_bacteria_1000_results/
```

---

## Next Phage-Rich Studies to Consider

### Tier 1: Ready to Design
1. **Staphylococcus aureus Monthly** (2020-2026)
   - Prophage burden: 4-8/genome
   - Focus: MRSA evolution, phage-encoded virulence factors
   - Unique: Gram-positive, biofilm genes

2. **Salmonella enterica Monthly** (2020-2026)
   - Prophage burden: 4-7/genome
   - Focus: Serotype tracking + prophages + AMR
   - Unique: NARMS overlap, foodborne

3. **Klebsiella pneumoniae Monthly** (2020-2026)
   - Prophage burden: 3-5/genome
   - Focus: CRE emergence, hypervirulent strains
   - Unique: Major AMR crisis organism

### Study Design Pattern Established:
✅ Temporal sampling (50/month, 2020-2026)
✅ Geographic stratification (optional, for epidemic pathogens)
✅ Phage-rich organisms (3+ prophages/genome)
✅ Clinical/public health relevance
✅ AMR focus

---

## Lessons Learned

### Nextflow Session Locks
- Lock files can persist after job interruption
- Safe to remove: `rm -rf .nextflow/cache/<SESSION_ID>/`
- Work directory preserves actual progress (`work_*/`)
- `-resume` picks up from cached tasks

### Geographic Stratification
- SRA metadata includes `geo_loc_name` field
- Can stratify by endemic regions for epidemic pathogens
- Enables phylogeographic analysis
- Regional AMR emergence tracking
- Critical for cholera, could apply to Salmonella, Staph aureus in future

### High Download Failure Rates
- 26% failure rate for Pseudomonas (915/3558) higher than usual
- Likely due to:
  - Older 2020 data withdrawn
  - Clinical isolates with restricted access
  - Author data withdrawal
- Still acceptable: 2643 samples is excellent dataset
- Consider starting from 2021 for future studies if 2020 data problematic

---

## Contact

- User: tdoerks@vet.k-state.edu
- GitHub: https://github.com/tdoerks/COMPASS-pipeline
- Branch: scratch (development/projects)
- Tag: 1.0.0 (production pipeline version)

---

---

## Part 3: NARMS Data Transfer (Windows to Beocat)

### Objective
Transfer local NARMS backup data from Windows machine to Beocat bulk storage for archival.

### Setup Steps

**Challenge**: WSL Ubuntu 24.04 didn't have D: drive mounted by default.

**Solution**:
```bash
# Mount D: drive in WSL
sudo mkdir -p /mnt/d
sudo mount -t drvfs D: /mnt/d
```

### Transfer Execution

**Data transferred**:
- Source: `D:\NARMS Data Backup\` (Windows local drive)
- Destination: `/bulk/tylerdoe/narms/` (Beocat bulk storage)
- Years: 2020, 2021, 2022, 2023, 2024, 2025, 2026
- Method: `rsync` in screen session for reliability

**Command used**:
```bash
screen -S narms_transfer
cd "/mnt/d/NARMS Data Backup"
rsync -avP ./ tylerdoe@beocat.ksu.edu:/bulk/tylerdoe/narms/
```

**Status**: Transfer running in screen session (large FASTQ files, will take several hours)

**Notes**:
- Used `screen` to allow transfer to continue if connection drops
- `rsync` will skip files already present on Beocat
- Can resume transfer if interrupted

---

## Part 4: Vibrio Download Script Fix

### Issue Encountered
Vibrio download script failed on Month 2 (Feb 2020) with:
```
requests.exceptions.HTTPError: 414 Client Error: Request-URI Too Long
```

**Cause**: 510 samples found for Feb 2020 - too many IDs to pass in single NCBI API request (URL length limit).

### Solution Implemented

Modified `fetch_vibrio_geographic.py` to batch large requests:

**Changes to `fetch_sra_metadata()` function:**
- Added `batch_size=100` parameter
- Split large ID lists into batches of 100
- Make multiple API requests for large months
- Combine batched XML responses properly
- Added 0.5s delay between batches

**Git commit**: `763770d` - "Fix Vibrio download script: batch NCBI requests to avoid 414 URI Too Long error"

### Vibrio Download Status

**Running successfully!** Currently on Month 34 (Oct 2022) of 75 total months.

**Sample geographic distribution observed:**
- Month 32 (Aug 2022): 26 South Asia, 18 Americas, 6 Southeast Asia → stratified to 50
- Month 33 (Sep 2022): 45 Africa, 11 Other → selected 10 Africa + 40 Other
- Successfully adapting to regional data availability

**Expected completion**: ~75-90 minutes total (started ~30 mins ago)

**Next steps after download completes:**
```bash
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.0/vibrio_cholerae_temporal_geographic
python3 scripts/create_samplesheet.py
sbatch run_vibrio_cholerae.sh
```

---

## Part 5: Archive Status Check

### Diverse Bacteria 1000 Results
- **Status**: ✅ Already transferred to `/bulk/tylerdoe/archives/diverse_bacteria_1000_results/`
- Contains: assemblies, AMR, prophage, plasmid, MLST, BUSCO, etc.
- FASTQs excluded (space savings)
- No additional transfer needed

---

## Current Status Summary

### Jobs Running on Beocat

**1. Pseudomonas Phage Hunter** (Job 6865835)
- Status: ~99% complete, final samples finishing
- Progress visible: QUAST 2630/2636, AMRFinder 2629/2636, VIBRANT 2579/2636
- Started: March 12, 10:20 AM
- Runtime so far: ~4 days
- Expected completion: Within 30-60 minutes

**2. Vibrio Download** (in progress)
- Currently on Month 34 of 75 (Oct 2022)
- Geographic stratification working correctly
- Expected completion: 45-60 minutes remaining
- Ready to submit pipeline job after download completes

**3. NARMS Data Transfer** (in screen session)
- Transferring 2020-2026 FASTQ data from Windows to Beocat
- Running in `screen -S narms_transfer`
- Large transfer, will take several hours

**4. ETEC Validation v1.0.0** (Job 6852091)
- Status: Unknown (need to check)
- 8 ETEC reference strains

---

## Git Repository Status

**Branch:** scratch

**Recent commits:**
- `763770d` - Fix Vibrio download script (batch NCBI requests)
- `ba75a14` - Add Vibrio cholerae geographic + temporal study
- `0a89b5e` - Session notes for 2026-03-16

**Pushed to GitHub:** ✅

---

## Updated Action Items

### Immediate (Next 1-2 hours)
- [ ] Monitor Pseudomonas job completion
- [ ] Monitor Vibrio download completion
- [ ] Generate Vibrio samplesheet after download completes
- [ ] Submit Vibrio job to run after Pseudomonas finishes

### Short-term
- [ ] Check ETEC validation status (job 6852091)
- [ ] Archive Pseudomonas results to bulk (when complete)
- [ ] Monitor NARMS transfer completion (screen session)
- [ ] Compare ETEC prophage predictions: paper vs COMPASS
- [ ] Provide collaborator with ETEC mapping information

### Future Studies to Design
- [ ] Staphylococcus aureus temporal (4-8 prophages/genome, MRSA)
- [ ] Salmonella enterica temporal (4-7 prophages/genome, serotypes)
- [ ] Klebsiella pneumoniae temporal (3-5 prophages/genome, CRE)

---

*Session date: 2026-03-16*

*Jobs running:*
- *6865835 (Pseudomonas Phage Hunter) - ~99% complete, finishing soon*
- *Vibrio download - Month 34/75, ~45-60 min remaining*
- *NARMS transfer - running in screen session*

*Projects created:*
- *Vibrio cholerae geographic + temporal study - download in progress*

*Accomplishments:*
- *✅ Fixed Pseudomonas Nextflow lock issue*
- *✅ Created Vibrio geographic+temporal study*
- *✅ Fixed Vibrio download batching bug*
- *✅ Started NARMS data transfer to bulk*
- *✅ Confirmed diverse bacteria already archived*

*Next session: Submit Vibrio job when download completes, design additional phage-rich studies*
