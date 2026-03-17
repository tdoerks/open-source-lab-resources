#!/bin/bash
# Generate samplesheet with 2 samples from each organism for AMRFinder testing

OUTPUT="/fastscratch/tylerdoe/test_amrfinder_fasta_samplesheet.csv"
ASSEMBLIES="/fastscratch/tylerdoe/diverse_bacteria_1000_results/assemblies"
DATA_DIR="/fastscratch/tylerdoe/COMPASS-pipeline/diverse_bacteria_1000/data/srr_accessions_by_organism"

echo "Creating AMRFinder FASTA test samplesheet with 2 samples per organism..."
echo ""

echo "sample,fasta,organism" > $OUTPUT

for org_file in $DATA_DIR/*_srr_list.txt; do
    org_name=$(basename $org_file _srr_list.txt | sed 's/_/ /g')

    echo "Processing: $org_name"

    # Find 2 assemblies for this organism
    count=0
    ls $ASSEMBLIES/ | grep -f $org_file | head -2 | while read assembly; do
        sample_id=$(basename $assembly _contigs.fasta)
        echo "${sample_id},${ASSEMBLIES}/${assembly},${org_name}" >> $OUTPUT
        ((count++))
    done
done

echo ""
echo "============================================"
echo "Samplesheet created: $OUTPUT"
echo "Total samples: $(tail -n +2 $OUTPUT | wc -l)"
echo "============================================"
echo ""
echo "First 20 lines:"
head -20 $OUTPUT
