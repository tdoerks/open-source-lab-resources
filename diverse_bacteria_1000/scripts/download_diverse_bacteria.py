#!/usr/bin/env python3
"""
Download Diverse Bacterial Pathogen SRA Accessions

Queries NCBI SRA for 20 different bacterial pathogens and downloads
N random samples per organism to create a diverse 1,000-sample dataset.

Uses NCBI E-utilities HTTP API (same approach as fetch_ecoli_monthly_v2.py)
No EDirect command-line tools required - just Python with 'requests' library.

Usage:
    python download_diverse_bacteria.py --output data/
"""

import argparse
import requests
import random
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict

def fetch_sra_accessions(organism, max_samples=50, min_size_gb=1, max_size_gb=10):
    """
    Query NCBI SRA for bacterial samples using E-utilities HTTP API

    Args:
        organism: Scientific name of organism
        max_samples: Maximum number of samples to retrieve
        min_size_gb: Minimum file size in GB
        max_size_gb: Maximum file size in GB

    Returns:
        List of SRR accessions
    """
    print(f"\n{'='*60}")
    print(f"Searching for: {organism}")
    print(f"Target samples: {max_samples}")
    print(f"{'='*60}")

    # Build query with filters
    query = f'"{organism}"[Organism] AND "GENOMIC"[Source] AND "ILLUMINA"[Platform] AND "WGS"[Strategy]'

    print(f"Query: {query}")

    # Step 1: Search for matching samples
    search_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
    search_params = {
        'db': 'sra',
        'term': query,
        'retmax': max_samples * 3,  # Get more than needed for filtering
        'retmode': 'json',
        'usehistory': 'y'
    }

    try:
        print("Counting available samples...")
        response = requests.get(search_url, params=search_params, timeout=30)
        response.raise_for_status()
        data = response.json()

        id_list = data.get('esearchresult', {}).get('idlist', [])
        count = int(data.get('esearchresult', {}).get('count', 0))

        print(f"  Found {count} total samples")

        if not id_list:
            print(f"  Warning: No results found for {organism}")
            return []

        # Step 2: Fetch run information in batches
        print(f"Fetching sample details (batches of 100)...")

        accessions = []

        # Process in batches of 100 to avoid timeout
        for i in range(0, min(len(id_list), max_samples * 3), 100):
            batch_ids = id_list[i:i+100]

            fetch_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
            fetch_params = {
                'db': 'sra',
                'id': ','.join(batch_ids),
                'rettype': 'full',
                'retmode': 'xml'
            }

            time.sleep(0.4)  # Rate limiting - be nice to NCBI

            try:
                response = requests.get(fetch_url, params=fetch_params, timeout=60)
                response.raise_for_status()

                # Parse XML to extract Run accessions and sizes
                root = ET.fromstring(response.content)

                for run in root.findall('.//RUN'):
                    acc = run.get('accession')

                    if not acc or not acc.startswith(('SRR', 'ERR', 'DRR')):
                        continue

                    # Try to get file size for filtering
                    size_valid = True
                    try:
                        # Find total_bases or size attributes
                        total_bases = run.get('total_bases')
                        if total_bases:
                            # Rough estimate: 1GB fastq ~ 4M bases
                            estimated_gb = int(total_bases) / (4_000_000 * 1_000_000_000)
                            if estimated_gb < min_size_gb or estimated_gb > max_size_gb:
                                size_valid = False
                    except:
                        pass  # If we can't determine size, include it

                    if size_valid:
                        accessions.append(acc)

            except ET.ParseError as e:
                print(f"  Warning: XML parse error in batch {i//100 + 1}: {e}")
                continue
            except requests.RequestException as e:
                print(f"  Warning: Request error in batch {i//100 + 1}: {e}")
                continue

        print(f"  Retrieved {len(accessions)} valid accessions")

        # Step 3: Randomly sample if we have more than needed
        if len(accessions) > max_samples:
            accessions = random.sample(accessions, max_samples)
            print(f"  Randomly sampled {max_samples} accessions")

        return accessions

    except requests.RequestException as e:
        print(f"  Error querying NCBI: {e}")
        return []
    except Exception as e:
        print(f"  Unexpected error: {e}")
        return []

def save_srr_list(organism, srr_list, output_dir):
    """Save SRR accessions to file"""
    if not srr_list:
        return None

    # Clean organism name for filename
    safe_name = organism.replace(' ', '_').replace('/', '_')
    filename = output_dir / f"{safe_name}_srr_list.txt"

    with open(filename, 'w') as f:
        for srr in srr_list:
            f.write(f"{srr}\n")

    print(f"  Saved {len(srr_list)} accessions to: {filename}")
    return filename

def main():
    parser = argparse.ArgumentParser(
        description='Download diverse bacterial pathogen SRA accessions using HTTP API'
    )
    parser.add_argument(
        '--targets',
        default='scripts/organism_targets.txt',
        help='File with target organisms (default: scripts/organism_targets.txt)'
    )
    parser.add_argument(
        '--output',
        default='data/srr_accessions_by_organism',
        help='Output directory for SRR lists (default: data/srr_accessions_by_organism)'
    )
    parser.add_argument(
        '--combined',
        default='data/combined_srr_list.txt',
        help='Combined output file (default: data/combined_srr_list.txt)'
    )
    parser.add_argument(
        '--delay',
        type=int,
        default=3,
        help='Delay between organism queries in seconds (default: 3)'
    )

    args = parser.parse_args()

    # Create output directory
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Read organism targets
    organisms = []
    target_counts = {}

    print("Reading organism targets...")
    with open(args.targets, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('|')
            if len(parts) >= 2:
                organism = parts[0].strip()
                count = int(parts[1].strip())
                organisms.append(organism)
                target_counts[organism] = count

    print(f"\nFound {len(organisms)} target organisms")
    print(f"Total target samples: {sum(target_counts.values())}")

    # Download accessions for each organism
    all_srr_files = []
    total_accessions = 0
    results_summary = []

    for i, organism in enumerate(organisms, 1):
        print(f"\n[{i}/{len(organisms)}] Processing: {organism}")

        # Query NCBI via HTTP API
        srr_list = fetch_sra_accessions(organism, max_samples=target_counts[organism])

        # Save to file
        if srr_list:
            filename = save_srr_list(organism, srr_list, output_dir)
            all_srr_files.append(filename)
            total_accessions += len(srr_list)
            results_summary.append(f"{organism}: {len(srr_list)} samples")
        else:
            print(f"  Warning: No accessions retrieved for {organism}")
            results_summary.append(f"{organism}: 0 samples (FAILED)")

        # Rate limiting between organisms
        if i < len(organisms):
            print(f"  Waiting {args.delay} seconds before next query...")
            time.sleep(args.delay)

    # Combine all SRR lists
    print(f"\n{'='*60}")
    print("Creating combined SRR list...")
    print(f"{'='*60}")

    combined_path = Path(args.combined)
    combined_path.parent.mkdir(parents=True, exist_ok=True)

    all_srrs = []
    for srr_file in all_srr_files:
        if srr_file and srr_file.exists():
            with open(srr_file, 'r') as f:
                srrs = [line.strip() for line in f if line.strip()]
                all_srrs.extend(srrs)

    # Remove duplicates
    all_srrs = list(set(all_srrs))

    with open(combined_path, 'w') as f:
        for srr in sorted(all_srrs):
            f.write(f"{srr}\n")

    # Print summary
    print(f"\n{'='*60}")
    print("DOWNLOAD SUMMARY")
    print(f"{'='*60}")
    print(f"\nResults by organism:")
    for result in results_summary:
        print(f"  {result}")
    print(f"\nTotal accessions retrieved: {len(all_srrs)}")
    print(f"Combined list saved to: {combined_path}")
    print(f"\nIndividual organism files saved to: {output_dir}/")
    print(f"\n{'='*60}")
    print("Next steps:")
    print(f"  1. Review the combined list: cat {combined_path} | wc -l")
    print(f"  2. Generate samplesheet: python scripts/create_samplesheet.py")
    print(f"  3. Run COMPASS pipeline: sbatch run_diverse_bacteria_1000.sh")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
