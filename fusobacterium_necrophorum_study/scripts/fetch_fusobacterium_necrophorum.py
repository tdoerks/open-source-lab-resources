#!/usr/bin/env python3
"""
Fetch ALL Fusobacterium necrophorum SRA Accessions from NCBI

Focus: Comprehensive prophage-virulence analysis of F. necrophorum
Organism: Fusobacterium necrophorum (all subspecies)
Target: All available WGS Illumina samples (~600 genomes)
"""
import requests
import time
import xml.etree.ElementTree as ET
from datetime import datetime

def fetch_all_fnec_accessions():
    """Fetch ALL F. necrophorum SRA accessions"""
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

    # Search for all F. necrophorum WGS data
    params = {
        'db': 'sra',
        'term': 'Fusobacterium necrophorum[Organism] AND illumina[Platform] AND GENOMIC[Source] AND WGS[Strategy]',
        'retmax': 10000,  # Get up to 10,000 (way more than needed)
        'retmode': 'json'
    }

    print("Searching NCBI SRA for Fusobacterium necrophorum...", flush=True)

    try:
        response = requests.get(base_url, params=params, timeout=30)
        data = response.json()

        id_list = data.get('esearchresult', {}).get('idlist', [])
        count = int(data.get('esearchresult', {}).get('count', 0))
        print(f"Found {count} total F. necrophorum WGS samples")

        # Fetch SRR accessions from UIDs using XML format
        if id_list:
            fetch_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

            accessions = []
            # Process in batches of 100
            for i in range(0, len(id_list), 100):
                batch_ids = id_list[i:i+100]

                print(f"Fetching accessions batch {i//100 + 1}/{(len(id_list)-1)//100 + 1}...", flush=True)

                fetch_params = {
                    'db': 'sra',
                    'id': ','.join(batch_ids),
                    'rettype': 'full',
                    'retmode': 'xml'
                }

                time.sleep(0.4)  # Be nice to NCBI (rate limit)
                response = requests.get(fetch_url, params=fetch_params, timeout=60)

                # Parse XML to get Run accessions
                try:
                    root = ET.fromstring(response.content)
                    for run in root.findall('.//RUN'):
                        acc = run.get('accession')
                        if acc and acc.startswith('SRR'):
                            accessions.append(acc)
                except ET.ParseError:
                    print(f"  Warning: Could not parse XML for batch {i//100 + 1}")
                    pass

            print(f"\n✓ Retrieved {len(accessions)} F. necrophorum SRR accessions")
            return accessions

    except Exception as e:
        print(f"ERROR: {e}")

    return []

def main():
    print("="*70)
    print("Fusobacterium necrophorum Comprehensive Prophage Study")
    print("="*70)
    print("Organism: Fusobacterium necrophorum (all subspecies)")
    print("Target: ALL available WGS Illumina genomes (~600)")
    print("Focus: Prophage burden, subspecies comparison, host source analysis")
    print("="*70)
    print()

    # Fetch all accessions
    accessions = fetch_all_fnec_accessions()

    if not accessions:
        print("\n❌ ERROR: No accessions retrieved")
        return

    # Write to file
    output_file = "data/sra_accessions_fusobacterium_necrophorum_all.txt"

    with open(output_file, 'w') as f:
        for acc in accessions:
            f.write(f"{acc}\n")

    print(f"\n✓ Saved {len(accessions)} accessions to {output_file}")
    print()
    print("="*70)
    print("Summary")
    print("="*70)
    print(f"Total samples: {len(accessions)}")
    print(f"Output file: {output_file}")
    print()
    print("Next steps:")
    print("  1. Generate samplesheet: python3 scripts/create_samplesheet.py")
    print("  2. Submit COMPASS job: sbatch run_fusobacterium_necrophorum.sh")
    print("="*70)

if __name__ == "__main__":
    main()
