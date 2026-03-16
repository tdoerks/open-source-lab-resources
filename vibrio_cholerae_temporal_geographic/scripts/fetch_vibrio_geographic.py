#!/usr/bin/env python3
"""
Download Vibrio cholerae SRA accessions with geographic + temporal stratification

This script queries NCBI SRA for V. cholerae samples from 2020-2026,
stratifies by geographic region (South Asia, Africa, Americas, SE Asia),
and samples 50 per month with regional proportions.

Based on fetch_pseudomonas_monthly.py but adds geographic dimension.

Usage:
    python3 fetch_vibrio_geographic.py [--delay SECONDS]
"""

import requests
import xml.etree.ElementTree as ET
import time
import random
from datetime import datetime
from pathlib import Path
import argparse
from collections import defaultdict

# NCBI E-utilities base URLs
ESEARCH_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
EFETCH_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

# Geographic region definitions (based on geo_loc_name patterns)
REGION_PATTERNS = {
    'South_Asia': ['india', 'bangladesh', 'pakistan', 'nepal', 'sri lanka'],
    'Africa': ['democratic republic of the congo', 'drc', 'kenya', 'nigeria',
               'mozambique', 'tanzania', 'zimbabwe', 'malawi', 'uganda', 'ethiopia',
               'somalia', 'south africa', 'ghana', 'cameroon', 'angola'],
    'Americas': ['haiti', 'dominican republic', 'mexico', 'brazil', 'peru',
                 'colombia', 'ecuador', 'venezuela'],
    'Southeast_Asia': ['thailand', 'vietnam', 'philippines', 'indonesia',
                       'malaysia', 'cambodia', 'laos', 'myanmar']
}

# Target samples per month per region (total = 50/month)
SAMPLES_PER_REGION = {
    'South_Asia': 30,      # Endemic hotspot (Bangladesh, India)
    'Africa': 10,          # Major endemic region
    'Americas': 5,         # Haiti outbreaks
    'Southeast_Asia': 5    # Endemic but less coverage
    # Any unclassified or other regions: use if regional quotas not met
}


def search_sra(query, retmax=10000):
    """Search NCBI SRA and return list of SRA IDs"""
    params = {
        'db': 'sra',
        'term': query,
        'retmax': retmax,
        'retmode': 'json'
    }

    response = requests.get(ESEARCH_URL, params=params)
    response.raise_for_status()

    data = response.json()
    id_list = data['esearchresult'].get('idlist', [])

    return id_list


def fetch_sra_metadata(sra_ids):
    """Fetch full metadata for list of SRA IDs"""
    if not sra_ids:
        return []

    # Join IDs into comma-separated string
    id_string = ','.join(sra_ids)

    params = {
        'db': 'sra',
        'id': id_string,
        'rettype': 'full',
        'retmode': 'xml'
    }

    response = requests.get(EFETCH_URL, params=params)
    response.raise_for_status()

    return response.text


def parse_sra_xml(xml_text):
    """Parse SRA XML and extract SRR accession + metadata"""
    root = ET.fromstring(xml_text)

    samples = []
    for exp_package in root.findall('.//EXPERIMENT_PACKAGE'):
        try:
            # Get SRR accession
            srr = exp_package.find('.//RUN').get('accession')

            # Get platform
            platform = exp_package.find('.//PLATFORM')
            platform_type = platform[0].tag if platform is not None and len(platform) > 0 else 'UNKNOWN'

            # Get library strategy
            lib_strategy_elem = exp_package.find('.//LIBRARY_STRATEGY')
            lib_strategy = lib_strategy_elem.text if lib_strategy_elem is not None else 'UNKNOWN'

            # Get library source
            lib_source_elem = exp_package.find('.//LIBRARY_SOURCE')
            lib_source = lib_source_elem.text if lib_source_elem is not None else 'UNKNOWN'

            # Get geographic location
            geo_loc = None
            for attr in exp_package.findall('.//SAMPLE_ATTRIBUTE'):
                tag = attr.find('TAG')
                value = attr.find('VALUE')
                if tag is not None and value is not None:
                    if tag.text and 'geo' in tag.text.lower():
                        geo_loc = value.text
                        break

            # Get collection date
            collection_date = None
            for attr in exp_package.findall('.//SAMPLE_ATTRIBUTE'):
                tag = attr.find('TAG')
                value = attr.find('VALUE')
                if tag is not None and value is not None:
                    if tag.text and 'collection' in tag.text.lower() and 'date' in tag.text.lower():
                        collection_date = value.text
                        break

            samples.append({
                'srr': srr,
                'platform': platform_type,
                'lib_strategy': lib_strategy,
                'lib_source': lib_source,
                'geo_loc_name': geo_loc if geo_loc else 'Unknown',
                'collection_date': collection_date if collection_date else 'Unknown'
            })

        except Exception as e:
            # Skip samples with parsing errors
            continue

    return samples


def classify_region(geo_loc_name):
    """Classify sample into geographic region based on geo_loc_name"""
    if not geo_loc_name or geo_loc_name == 'Unknown':
        return 'Other'

    geo_lower = geo_loc_name.lower()

    for region, patterns in REGION_PATTERNS.items():
        for pattern in patterns:
            if pattern in geo_lower:
                return region

    return 'Other'


def filter_samples(samples):
    """Filter for Illumina, WGS, GENOMIC samples"""
    filtered = []

    for sample in samples:
        # Check platform
        if 'ILLUMINA' not in sample['platform'].upper():
            continue

        # Check library strategy
        if sample['lib_strategy'].upper() != 'WGS':
            continue

        # Check library source
        if sample['lib_source'].upper() != 'GENOMIC':
            continue

        filtered.append(sample)

    return filtered


def fetch_monthly_samples(year, month, delay=1):
    """Fetch V. cholerae samples for a specific month"""

    # Format month query
    month_str = f"{year:04d}/{month:02d}"

    # Query for V. cholerae samples from this month
    query = f'"Vibrio cholerae"[Organism] AND {month_str}[Publication Date] AND "ILLUMINA"[Platform] AND "WGS"[Strategy] AND "GENOMIC"[Source]'

    print(f"  Querying: {year}-{month:02d}")

    # Search SRA
    sra_ids = search_sra(query)

    if not sra_ids:
        print(f"    No samples found for {year}-{month:02d}")
        return []

    print(f"    Found {len(sra_ids)} potential samples")

    # Fetch metadata
    time.sleep(delay)  # Rate limiting
    xml_text = fetch_sra_metadata(sra_ids)

    # Parse metadata
    samples = parse_sra_xml(xml_text)

    # Filter
    filtered = filter_samples(samples)

    # Add region classification
    for sample in filtered:
        sample['region'] = classify_region(sample['geo_loc_name'])

    print(f"    {len(filtered)} samples after filtering")

    return filtered


def stratified_sample_by_region(samples, n_total=50):
    """Sample n_total samples with regional stratification"""

    # Group by region
    by_region = defaultdict(list)
    for sample in samples:
        by_region[sample['region']].append(sample)

    # Show distribution
    print(f"    Regional distribution:")
    for region, region_samples in sorted(by_region.items()):
        print(f"      {region}: {len(region_samples)}")

    # Stratified sampling
    selected = []

    # First, try to meet regional quotas
    for region, target in SAMPLES_PER_REGION.items():
        available = by_region.get(region, [])
        n_sample = min(target, len(available))

        if n_sample > 0:
            sampled = random.sample(available, n_sample)
            selected.extend(sampled)
            print(f"      → Selected {n_sample} from {region}")

    # If we haven't reached n_total, fill from Other or any remaining
    if len(selected) < n_total:
        remaining_needed = n_total - len(selected)

        # Pool all unselected samples
        selected_srrs = {s['srr'] for s in selected}
        unselected = [s for s in samples if s['srr'] not in selected_srrs]

        if unselected:
            n_fill = min(remaining_needed, len(unselected))
            additional = random.sample(unselected, n_fill)
            selected.extend(additional)
            print(f"      → Selected {n_fill} additional from unclassified/other")

    # If we have too many (shouldn't happen), trim randomly
    if len(selected) > n_total:
        selected = random.sample(selected, n_total)

    print(f"    Total selected: {len(selected)}")

    return selected


def main():
    parser = argparse.ArgumentParser(description='Download V. cholerae SRA accessions with geographic stratification')
    parser.add_argument('--delay', type=float, default=1.0, help='Delay between queries (seconds)')
    args = parser.parse_args()

    print("=" * 80)
    print("Vibrio cholerae Geographic + Temporal SRA Download")
    print("=" * 80)
    print()
    print("Target: 50 samples/month (Jan 2020 - Mar 2026)")
    print("Geographic stratification:")
    for region, n in SAMPLES_PER_REGION.items():
        print(f"  - {region}: {n}/month")
    print()
    print(f"Rate limiting: {args.delay}s between queries")
    print()

    # Create output directories
    data_dir = Path('data')
    region_dir = data_dir / 'sra_accessions_by_region'
    data_dir.mkdir(exist_ok=True)
    region_dir.mkdir(exist_ok=True)

    # Track all samples by region
    all_samples_by_region = defaultdict(list)
    all_samples = []

    # Fetch for each month (Jan 2020 - Mar 2026)
    start_date = datetime(2020, 1, 1)
    end_date = datetime(2026, 3, 31)

    current = start_date
    month_count = 0

    while current <= end_date:
        year = current.year
        month = current.month

        print(f"Month {month_count + 1}: {year}-{month:02d}")

        # Fetch samples for this month
        samples = fetch_monthly_samples(year, month, delay=args.delay)

        if samples:
            # Stratified sampling
            selected = stratified_sample_by_region(samples, n_total=50)

            # Add to tracking
            for sample in selected:
                all_samples_by_region[sample['region']].append(sample)
                all_samples.append(sample)

        print()

        # Next month
        if month == 12:
            current = datetime(year + 1, 1, 1)
        else:
            current = datetime(year, month + 1, 1)

        month_count += 1

    print("=" * 80)
    print("Download Complete!")
    print("=" * 80)
    print()
    print(f"Total samples downloaded: {len(all_samples)}")
    print()
    print("Regional distribution:")
    for region in sorted(all_samples_by_region.keys()):
        count = len(all_samples_by_region[region])
        pct = (count / len(all_samples)) * 100 if all_samples else 0
        print(f"  {region}: {count} ({pct:.1f}%)")
    print()

    # Write combined file
    combined_file = data_dir / 'combined_vibrio_accessions.txt'
    with open(combined_file, 'w') as f:
        for sample in all_samples:
            f.write(f"{sample['srr']}\n")

    print(f"✅ Wrote combined file: {combined_file}")

    # Write region-specific files
    for region, samples in all_samples_by_region.items():
        region_file = region_dir / f'{region}_accessions.txt'
        with open(region_file, 'w') as f:
            for sample in samples:
                f.write(f"{sample['srr']}\n")
        print(f"✅ Wrote {region} file: {region_file} ({len(samples)} samples)")

    # Write metadata summary
    metadata_file = data_dir / 'vibrio_geographic_metadata.csv'
    with open(metadata_file, 'w') as f:
        f.write("srr,region,geo_loc_name,collection_date,platform,lib_strategy,lib_source\n")
        for sample in all_samples:
            f.write(f"{sample['srr']},{sample['region']},{sample['geo_loc_name']},"
                   f"{sample['collection_date']},{sample['platform']},"
                   f"{sample['lib_strategy']},{sample['lib_source']}\n")

    print(f"✅ Wrote metadata file: {metadata_file}")
    print()
    print("Next steps:")
    print("  1. python3 scripts/create_samplesheet.py")
    print("  2. sbatch run_vibrio_cholerae.sh")
    print()


if __name__ == '__main__':
    random.seed(42)  # For reproducibility
    main()
