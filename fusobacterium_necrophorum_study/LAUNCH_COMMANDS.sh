#!/bin/bash
# Commands to launch Fusobacterium necrophorum study on Beocat
# Run these commands step-by-step (not as a script)

echo "=============================================="
echo "Fusobacterium necrophorum Study Launch Guide"
echo "=============================================="
echo ""

# STEP 1: Navigate to COMPASS pipeline directory on Beocat
echo "STEP 1: Navigate to pipeline directory"
echo "----------------------------------------------"
cat << 'CMD1'
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate
pwd
CMD1
echo ""

# STEP 2: Pull latest from git scratch branch (to get the new study)
echo "STEP 2: Pull from git (if you pushed it) OR copy local files"
echo "----------------------------------------------"
echo "Option A: If you pushed to git:"
cat << 'CMD2A'
git fetch compass
git checkout compass/scratch
git pull compass scratch
CMD2A
echo ""
echo "Option B: If copying from local (recommended for new study):"
cat << 'CMD2B'
# From your LOCAL machine (not Beocat), upload the study:
# scp -r fusobacterium_necrophorum_study tylerdoe@beocat.ksu.edu:/fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/

# Or if already on Beocat with the files:
# cp -r /path/to/fusobacterium_necrophorum_study /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/
CMD2B
echo ""

# STEP 3: Navigate to project directory
echo "STEP 3: Navigate to project directory"
echo "----------------------------------------------"
cat << 'CMD3'
cd /fastscratch/tylerdoe/COMPASS-pipeline-1.0.1-candidate/fusobacterium_necrophorum_study
pwd
ls -lh
CMD3
echo ""

# STEP 4: Download SRA accessions
echo "STEP 4: Download ALL F. necrophorum SRA accessions"
echo "----------------------------------------------"
cat << 'CMD4'
# This will take ~5-10 minutes and download ~600 SRR accessions
python3 scripts/fetch_fusobacterium_necrophorum.py

# Check the output
ls -lh data/
cat data/sra_accessions_fusobacterium_necrophorum_all.txt | head -10
wc -l data/sra_accessions_fusobacterium_necrophorum_all.txt
CMD4
echo ""

# STEP 5: Generate COMPASS samplesheet
echo "STEP 5: Generate COMPASS samplesheet"
echo "----------------------------------------------"
cat << 'CMD5'
python3 scripts/create_samplesheet.py

# Verify samplesheet
ls -lh data/
head -20 data/samplesheet_fusobacterium_necrophorum.txt
wc -l data/samplesheet_fusobacterium_necrophorum.txt
CMD5
echo ""

# STEP 6: Submit the SLURM job
echo "STEP 6: Submit COMPASS pipeline job"
echo "----------------------------------------------"
cat << 'CMD6'
# Submit the job
sbatch run_fusobacterium_necrophorum.sh

# Note the job ID, then monitor:
squeue -u $USER

# Watch the output log (replace JOBID with actual job ID):
tail -f /fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-JOBID.out

# Or check latest:
ls -lt /fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-*.out | head -1
tail -f $(ls -t /fastscratch/tylerdoe/slurm-fusobacterium-necrophorum-*.out | head -1)
CMD6
echo ""

# STEP 7: Monitor progress
echo "STEP 7: Monitor progress (while job runs)"
echo "----------------------------------------------"
cat << 'CMD7'
# Check completed assemblies
ls /fastscratch/tylerdoe/fusobacterium_necrophorum_results/assemblies/*.fasta 2>/dev/null | wc -l

# Check VIBRANT (prophage detection) progress
find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/vibrant -type d -name "*_vibrant" 2>/dev/null | wc -l

# Check MOB-suite (plasmids) progress
find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/mobsuite -type d -name "*_mobsuite" 2>/dev/null | wc -l

# Check AMRFinder progress
find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/amrfinder -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l

# Overall summary
echo "=== Progress Summary ==="
echo "Assemblies: $(ls /fastscratch/tylerdoe/fusobacterium_necrophorum_results/assemblies/*.fasta 2>/dev/null | wc -l)"
echo "VIBRANT: $(find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/vibrant -type d -name "*_vibrant" 2>/dev/null | wc -l)"
echo "MOB-suite: $(find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/mobsuite -type d -name "*_mobsuite" 2>/dev/null | wc -l)"
echo "AMRFinder: $(find /fastscratch/tylerdoe/fusobacterium_necrophorum_results/amrfinder -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
CMD7
echo ""

echo "=============================================="
echo "That's it! The pipeline will run for 4-7 days"
echo "Expected samples: ~600"
echo "=============================================="
