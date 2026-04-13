#!/usr/bin/env python3
"""
Fetch E. coli STEC SRA Accessions - Temporal Sampling Strategy

Focus: Shiga-toxin producing E. coli prophage dynamics over time
Organism: E. coli (targeting STEC-enriched datasets)
Sampling: 100 samples per month (2020-2026) = ~7,500 total
Strategy: Sample broadly, identify STEC post-pipeline via virulence genes
"""
import requests
import random
import time
import xml.etree.ElementTree as ET
from datetime import datetime

def fetch_sra_accessions(year, month, max_results=500):
    """Fetch E. coli SRA accessions for a specific month"""
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

    date_str = f"{year}/{month:02d}"

    params = {
        'db': 'sra',
        'term': f'(Escherichia coli[Organism]) AND {date_str}[Release Date] AND illumina[Platform] AND GENOMIC[Source] AND WGS[Strategy]',
        'retmax': max_results,
        'retmode': 'json'
    }

    print(f"Fetching {year}-{month:02d}...", end=" ", flush=True)

    try:
        response = requests.get(base_url, params=params, timeout=30)
        data = response.json()

        id_list = data.get('esearchresult', {}).get('idlist', [])
        count = int(data.get('esearchresult', {}).get('count', 0))
        print(f"Found {count} total", end=" ", flush=True)

        if id_list:
            fetch_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

            accessions = []
            for i in range(0, min(len(id_list), max_results), 100):
                batch_ids = id_list[i:i+100]

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
                    pass

            print(f"→ Got {len(accessions)} accessions")
            return accessions

    except Exception as e:
        print(f"ERROR: {e}")

    return []

def main():
    print("="*70)
    print("STEC Prophage Dynamics - Temporal Analysis")
    print("="*70)
    print("Organism: E. coli (targeting STEC)")
    print("Period: January 2020 - March 2026")
    print("Target: 100 random samples per month")
    print("Focus: Shiga toxin prophages, serotype dynamics")
    print("="*70)
    print()

    all_accessions = []
    monthly_counts = []

    # January 2020 to March 2026
    for year in range(2020, 2027):
        for month in range(1, 13):
            if year == 2026 and month > 3:
                break

            accessions = fetch_sra_accessions(year, month)

            # Sample 100 random (or all if less than 100)
            sample_size = min(100, len(accessions))

            if accessions:
                sampled = random.sample(accessions, sample_size)
                all_accessions.extend(sampled)
                monthly_counts.append((year, month, len(accessions), sample_size))
                print(f"    Sampled {sample_size} from {len(accessions)}")
            else:
                print(f"    No samples for {year}-{month:02d}")

            time.sleep(0.5)

    output_file = "data/sra_accessions_stec_temporal_100_2020-2026.txt"

    with open(output_file, 'w') as f:
        for acc in all_accessions:
            f.write(f"{acc}\n")

    print(f"\n✓ Saved {len(all_accessions)} accessions to {output_file}")
    print()
    print("="*70)
    print("Summary")
    print("="*70)
    print(f"Total samples: {len(all_accessions)}")
    print(f"Time points: {len(monthly_counts)} months")
    print(f"Target per month: 100")
    print()
    print("STEC Identification (Post-Pipeline):")
    print("  - AMRFinder will detect stx1, stx2, eae genes")
    print("  - Filter results for stx+ samples")
    print("  - Expected STEC %: 10-30% (varies by dataset)")
    print("  - Expected STEC samples: ~750-2,250")
    print()
    print("Analysis Opportunities:")
    print("  1. STEC vs non-STEC prophage burden")
    print("  2. Stx1 vs Stx2 prophage dynamics over time")
    print("  3. Serotype emergence (O157:H7, O26, O103, O111, O145, O104)")
    print("  4. Outbreak strain detection")
    print("  5. Prophage-mediated virulence evolution")
    print()
    print("Next steps:")
    print("  1. Generate samplesheet: python3 scripts/create_samplesheet.py")
    print("  2. Submit COMPASS job: sbatch run_stec_prophage.sh")
    print("="*70)

if __name__ == "__main__":
    main()
