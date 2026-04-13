#!/usr/bin/env python3
"""
Fetch ALL STEC/pathogenic E. coli SRA Accessions from NCBI

Focus: Shiga-toxin producing E. coli (STEC) prophage dynamics
Organism: E. coli (STEC and pathogenic strains)
Target: Comprehensive sampling across time and serotypes
Strategy: Get ALL available, let MLST/serotyping reveal distribution
"""
import requests
import time
import xml.etree.ElementTree as ET
from datetime import datetime

def fetch_all_stec_accessions():
    """Fetch ALL E. coli pathogenic/STEC SRA accessions"""
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

    # Search for E. coli WGS data
    # Note: STEC filtering happens downstream via serotyping/virulence genes
    params = {
        'db': 'sra',
        'term': '(Escherichia coli[Organism] OR "E. coli"[Organism]) AND illumina[Platform] AND GENOMIC[Source] AND WGS[Strategy]',
        'retmax': 10000,
        'retmode': 'json'
    }

    print("Searching NCBI SRA for E. coli (STEC/pathogenic strains)...", flush=True)
    print("Note: Comprehensive search - STEC identification via serotyping/virulence genes", flush=True)

    try:
        response = requests.get(base_url, params=params, timeout=30)
        data = response.json()

        id_list = data.get('esearchresult', {}).get('idlist', [])
        count = int(data.get('esearchresult', {}).get('count', 0))
        print(f"Found {count} total E. coli WGS samples")
        print(f"(Will retrieve up to {len(id_list)} accessions)")

        if id_list:
            fetch_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

            accessions = []
            for i in range(0, len(id_list), 100):
                batch_ids = id_list[i:i+100]

                print(f"Fetching accessions batch {i//100 + 1}/{(len(id_list)-1)//100 + 1}...", flush=True)

                fetch_params = {
                    'db': 'sra',
                    'id': ','.join(batch_ids),
                    'rettype': 'full',
                    'retmode': 'xml'
                }

                time.sleep(0.4)
                response = requests.get(fetch_url, params=fetch_params, timeout=60)

                try:
                    root = ET.fromstring(response.content)
                    for run in root.findall('.//RUN'):
                        acc = run.get('accession')
                        if acc and acc.startswith('SRR'):
                            accessions.append(acc)
                except ET.ParseError:
                    print(f"  Warning: Could not parse XML for batch {i//100 + 1}")
                    pass

            print(f"\n✓ Retrieved {len(accessions)} E. coli SRR accessions")
            return accessions

    except Exception as e:
        print(f"ERROR: {e}")

    return []

def main():
    print("="*70)
    print("STEC Prophage Dynamics Study")
    print("="*70)
    print("Organism: E. coli (STEC and pathogenic strains)")
    print("Target: Comprehensive WGS dataset")
    print("Focus: Shiga toxin prophages (Stx1, Stx2), serotype comparison")
    print("="*70)
    print()
    print("Sampling Strategy:")
    print("  - Get ALL available E. coli WGS")
    print("  - STEC identification via:")
    print("    * Serotyping (O157:H7, O26, O103, O111, O145, O104, etc.)")
    print("    * Virulence genes (stx1, stx2, eae)")
    print("    * AMRFinder virulence detection")
    print("  - Enables:")
    print("    * Serotype comparison")
    print("    * Temporal dynamics (if date metadata available)")
    print("    * Outbreak vs sporadic strain analysis")
    print("="*70)
    print()

    accessions = fetch_all_stec_accessions()

    if not accessions:
        print("\n❌ ERROR: No accessions retrieved")
        return

    output_file = "data/sra_accessions_stec_all.txt"

    with open(output_file, 'w') as f:
        for acc in accessions:
            f.write(f"{acc}\n")

    print(f"\n✓ Saved {len(accessions)} accessions to {output_file}")
    print()
    print("="*70)
    print("Summary")
    print("="*70)
    print(f"Total E. coli samples: {len(accessions)}")
    print(f"Output file: {output_file}")
    print()
    print("STEC Identification Strategy:")
    print("  1. COMPASS will run AMRFinder (detects stx1, stx2, eae)")
    print("  2. Post-pipeline: Filter for stx+ samples")
    print("  3. Analyze prophage content in STEC vs non-STEC")
    print("  4. Compare serotypes (O157:H7 vs Big 6 vs O104:H4)")
    print()
    print("Expected STEC enrichment:")
    print("  - Clinical/outbreak datasets: High STEC %")
    print("  - Environmental: Lower STEC %")
    print("  - Exact proportion determined post-pipeline")
    print()
    print("Next steps:")
    print("  1. Generate samplesheet: python3 scripts/create_samplesheet.py")
    print("  2. Submit COMPASS job: sbatch run_stec_prophage.sh")
    print("="*70)

if __name__ == "__main__":
    main()
