#!/usr/bin/env python3
"""
Fetch SRA metadata for Fusobacterium samples
Get isolation source, host, tissue type, geography
"""
import requests
import time
import xml.etree.ElementTree as ET
import csv

def fetch_sra_metadata(accession):
    """Get metadata for SRA accession"""
    url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

    params = {
        'db': 'sra',
        'id': accession,
        'rettype': 'full',
        'retmode': 'xml'
    }

    try:
        response = requests.get(url, params=params, timeout=30)
        root = ET.fromstring(response.content)

        # Extract useful fields
        metadata = {'accession': accession}

        # Organism
        org = root.find('.//SCIENTIFIC_NAME')
        if org is not None:
            metadata['organism'] = org.text

        # Sample attributes (isolation_source, host, tissue, etc.)
        for attr in root.findall('.//SAMPLE_ATTRIBUTE'):
            tag = attr.find('TAG')
            value = attr.find('VALUE')
            if tag is not None and value is not None:
                metadata[tag.text] = value.text

        return metadata
    except Exception as e:
        print(f"Error fetching {accession}: {e}")
        return None

def main():
    # Read successful samples only (those that assembled)
    print("Reading sample list...")
    successful = []

    # Try to read from analysis file first
    try:
        with open('/fastscratch/tylerdoe/fusobacterium_results/analysis/prophage_counts_per_sample.tsv', 'r') as f:
            for line in f:
                acc = line.strip().split('\t')[0]
                successful.append(acc)
    except FileNotFoundError:
        # Fallback to all accessions
        print("Analysis file not found, using all accessions...")
        with open('data/sra_accessions_fusobacterium_necrophorum_all.txt', 'r') as f:
            successful = [line.strip() for line in f if line.strip()]

    print(f"Fetching metadata for {len(successful)} samples...")
    print("This will take ~15 minutes (NCBI rate limits)...")

    # Fetch metadata
    all_metadata = []
    for i, acc in enumerate(successful):
        if i % 10 == 0:
            print(f"Progress: {i}/{len(successful)} ({100*i//len(successful)}%)")

        meta = fetch_sra_metadata(acc)
        if meta:
            all_metadata.append(meta)

        time.sleep(0.4)  # NCBI rate limit: 3 requests/second

    # Save results
    if all_metadata:
        # Collect all unique keys
        keys = set()
        for m in all_metadata:
            keys.update(m.keys())

        output_file = 'data/fusobacterium_metadata.tsv'
        with open(output_file, 'w') as f:
            writer = csv.DictWriter(f, fieldnames=sorted(keys), delimiter='\t')
            writer.writeheader()
            writer.writerows(all_metadata)

        print(f"\n✓ Saved metadata for {len(all_metadata)} samples to {output_file}")

        # Quick preview of available metadata fields
        print("\nMetadata fields detected:")
        for key in sorted(keys):
            count = sum(1 for m in all_metadata if key in m and m[key])
            print(f"  - {key}: {count}/{len(all_metadata)} samples")
    else:
        print("\n❌ No metadata retrieved")

if __name__ == "__main__":
    main()
