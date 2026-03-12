#!/usr/bin/env python3
"""
Fetch Pseudomonas aeruginosa SRA Accessions from NCBI
50 random samples per month from January 2020 to March 2026

Focus: Temporal dynamics of prophage-plasmid-AMR interactions
Organism: Pseudomonas aeruginosa (highest prophage burden bacteria)
"""
import requests
import random
import time
import xml.etree.ElementTree as ET
from datetime import datetime

def fetch_sra_accessions(year, month, max_results=500):
    """Fetch SRA accessions for Pseudomonas aeruginosa from a specific month"""
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

    # Format: 2020/01
    date_str = f"{year}/{month:02d}"

    params = {
        'db': 'sra',
        'term': f'Pseudomonas aeruginosa[Organism] AND {date_str}[Release Date] AND illumina[Platform] AND GENOMIC[Source] AND WGS[Strategy]',
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

        # Fetch SRR accessions from UIDs using XML format (more reliable)
        if id_list:
            fetch_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

            accessions = []
            # Process in batches of 100
            for i in range(0, min(len(id_list), max_results), 100):
                batch_ids = id_list[i:i+100]

                fetch_params = {
                    'db': 'sra',
                    'id': ','.join(batch_ids),
                    'rettype': 'full',
                    'retmode': 'xml'
                }

                time.sleep(0.4)  # Be nice to NCBI
                response = requests.get(fetch_url, params=fetch_params, timeout=60)

                # Parse XML to get Run accessions
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
    print("Pseudomonas Phage Hunter - Monthly Temporal Sampling")
    print("="*70)
    print("Organism: Pseudomonas aeruginosa")
    print("Period: January 2020 - March 2026")
    print("Target: 50 random samples per month")
    print("Focus: Prophage-Plasmid-AMR temporal dynamics")
    print("="*70)
    print()

    all_accessions = []
    monthly_counts = []

    # January 2020 to March 2026 (current month)
    for year in range(2020, 2027):
        for month in range(1, 13):
            # Stop at March 2026
            if year == 2026 and month > 3:
                break

            accessions = fetch_sra_accessions(year, month)

            # Sample 50 random (or all if less than 50)
            sample_size = min(50, len(accessions))
            if sample_size > 0:
                sampled = random.sample(accessions, sample_size)
                all_accessions.extend(sampled)
                monthly_counts.append((year, month, sample_size))
                print(f"  ✓ Sampled {sample_size} accessions")
            else:
                print(f"  ✗ No accessions found")
                monthly_counts.append((year, month, 0))

            time.sleep(1)  # Rate limiting for NCBI API

    # Save to file
    output_file = "sra_accessions_pseudomonas_monthly_50_2020-2026.txt"
    with open(output_file, 'w') as f:
        for acc in all_accessions:
            f.write(f"{acc}\n")

    print()
    print("="*70)
    print(f"Total accessions: {len(all_accessions)}")
    print(f"Saved to: {output_file}")
    print()
    print("Monthly breakdown:")

    total_months = len(monthly_counts)
    months_with_data = sum(1 for _, _, count in monthly_counts if count > 0)
    avg_per_month = len(all_accessions) / total_months if total_months > 0 else 0

    for year, month, count in monthly_counts:
        status = "✓" if count >= 50 else "⚠" if count > 0 else "✗"
        print(f"  {status} {year}-{month:02d}: {count} samples")

    print()
    print("="*70)
    print("SUMMARY STATISTICS")
    print("="*70)
    print(f"Total months queried: {total_months}")
    print(f"Months with data: {months_with_data}")
    print(f"Months with 50 samples: {sum(1 for _, _, c in monthly_counts if c == 50)}")
    print(f"Average per month: {avg_per_month:.1f}")
    print()
    print("Next steps:")
    print(f"  1. Review: head {output_file}")
    print(f"  2. Generate samplesheet: python3 scripts/create_samplesheet.py")
    print(f"  3. Run COMPASS: sbatch run_pseudomonas_phage_hunter.sh")
    print("="*70)

if __name__ == "__main__":
    main()
