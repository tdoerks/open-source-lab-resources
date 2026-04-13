#!/usr/bin/env python3
"""
Fetch ALL Fusobacterium SRA Accessions from NCBI

Focus: Comprehensive prophage analysis across Fusobacterium genus
Organism: Fusobacterium (all species)
Target: All available WGS Illumina samples
"""
import requests
import time
import xml.etree.ElementTree as ET
from datetime import datetime

def fetch_all_fnec_accessions():
    """Fetch ALL Fusobacterium SRA accessions (all species)"""
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

    # Search for ALL Fusobacterium WGS data (all species)
    params = {
        'db': 'sra',
        'term': 'Fusobacterium[Organism] AND illumina[Platform] AND GENOMIC[Source] AND WGS[Strategy]',
        'retmax': 10000,  # Get up to 10,000
        'retmode': 'json'
    }

    print("Searching NCBI SRA for ALL Fusobacterium species...", flush=True)

    try:
        response = requests.get(base_url, params=params, timeout=30)
        data = response.json()

        id_list = data.get('esearchresult', {}).get('idlist', [])
        count = int(data.get('esearchresult', {}).get('count', 0))
        print(f"Found {count} total Fusobacterium WGS samples (all species)")

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

            print(f"\n✓ Retrieved {len(accessions)} Fusobacterium SRR accessions")
            return accessions

    except Exception as e:
        print(f"ERROR: {e}")

    return []

def main():
    print("="*70)
    print("Fusobacterium Genus Comprehensive Prophage Study")
    print("="*70)
    print("Organism: Fusobacterium (all species)")
    print("Target: ALL available WGS Illumina genomes")
    print("Focus: Prophage burden across Fusobacterium genus, species comparison")
    print("="*70)
    print()

    # Fetch all accessions
    accessions = fetch_all_fnec_accessions()

    if not accessions:
        print("\n❌ ERROR: No accessions retrieved")
        return

    # Write to file
    output_file = "data/sra_accessions_fusobacterium_all.txt"

    with open(output_file, 'w') as f:
        for acc in accessions:
            f.write(f"{acc}\n")

    print(f"\n✓ Saved {len(accessions)} accessions to {output_file}")
    print()
    print("="*70)
    print("Summary")
    print("="*70)
    print(f"Total samples: {len(accessions)} (all Fusobacterium species)")
    print(f"Output file: {output_file}")
    print()
    print("Next steps:")
    print("  1. Generate samplesheet: python3 scripts/create_samplesheet.py")
    print("  2. Submit COMPASS job: sbatch run_fusobacterium.sh")
    print("="*70)

if __name__ == "__main__":
    main()
