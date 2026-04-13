#!/usr/bin/env python3
"""
Categorize AMR Genes by Genomic Location
==========================================

Cross-references AMRFinder+, MOB-suite, and VIBRANT results to determine
whether AMR genes are located on:
- Chromosome (not on plasmid or prophage)
- Plasmid (MOB-suite reconstruction)
- Prophage (VIBRANT prediction)

Critical for phage-rich organism studies (Pseudomonas, Vibrio, Salmonella)

Usage:
    python3 categorize_amr_by_location.py \\
        --amrfinder results/amrfinder/ \\
        --mobsuite results/mobsuite/ \\
        --vibrant results/vibrant/ \\
        --output amr_location_matrix.tsv

Author: Claude Code (Anthropic)
Date: 2026-03-24
"""

import argparse
import pandas as pd
import os
import sys
from pathlib import Path
from collections import defaultdict

def parse_amrfinder(amrfinder_dir):
    """
    Parse AMRFinder results to get AMR gene locations

    Returns: dict[sample_id] = list of (gene, contig, start, end, class)
    """
    amr_data = defaultdict(list)

    amrfinder_path = Path(amrfinder_dir)

    # Find all AMRFinder TSV files (files are directly in directory, not subdirs)
    for amr_file in amrfinder_path.glob('*_amr.tsv'):
        sample_id = amr_file.stem.replace('_amr', '')

        # Parse AMRFinder output
        try:
            df = pd.read_csv(amr_file, sep='\t')

            for _, row in df.iterrows():
                gene = row['Gene symbol']
                contig = row['Contig id']
                start = int(row['Start'])
                end = int(row['Stop'])
                amr_class = row.get('Class', row.get('Subclass', 'Unknown'))

                amr_data[sample_id].append({
                    'gene': gene,
                    'contig': contig,
                    'start': start,
                    'end': end,
                    'class': amr_class
                })
        except Exception as e:
            print(f"Error parsing {amr_file}: {e}", file=sys.stderr)

    return amr_data

def parse_mobsuite(mobsuite_dir):
    """
    Parse MOB-suite results to get plasmid contigs

    Returns: dict[sample_id] = set of plasmid contig IDs
    """
    plasmid_contigs = defaultdict(set)

    mobsuite_path = Path(mobsuite_dir)

    for sample_dir in mobsuite_path.iterdir():
        if not sample_dir.is_dir():
            continue

        sample_id = sample_dir.name.replace('_mobsuite', '')

        # Look for plasmid FASTA files
        for plasmid_file in sample_dir.glob('plasmid_*.fasta'):
            # Extract contig IDs from plasmid reconstructions
            with open(plasmid_file, 'r') as f:
                for line in f:
                    if line.startswith('>'):
                        # Parse contig ID from FASTA header
                        contig_id = line.strip().split()[0][1:]  # Remove '>'
                        plasmid_contigs[sample_id].add(contig_id)

        # Also check mobtyper results for additional plasmid contigs
        mobtyper_file = sample_dir / 'mobtyper_results.txt'
        if mobtyper_file.exists():
            try:
                df = pd.read_csv(mobtyper_file, sep='\t')
                if 'sample_id' in df.columns and 'contig_id' in df.columns:
                    for contig in df['contig_id']:
                        plasmid_contigs[sample_id].add(contig)
            except Exception as e:
                print(f"Warning: Could not parse {mobtyper_file}: {e}", file=sys.stderr)

    return plasmid_contigs

def parse_vibrant(vibrant_dir):
    """
    Parse VIBRANT results to get prophage regions

    Returns: dict[sample_id] = list of (contig, start, end) for prophages
    """
    prophage_regions = defaultdict(list)

    vibrant_path = Path(vibrant_dir)

    for sample_dir in vibrant_path.iterdir():
        if not sample_dir.is_dir():
            continue

        sample_id = sample_dir.name.replace('_vibrant', '')

        # Look for VIBRANT integrated_prophage_coordinates file
        # Actual path: vibrant/E1373_vibrant/VIBRANT_E1373/VIBRANT_results_E1373/VIBRANT_integrated_prophage_coordinates_E1373.tsv
        prophage_files = list(sample_dir.glob('VIBRANT_*/VIBRANT_results_*/VIBRANT_integrated_prophage_coordinates_*.tsv'))

        if prophage_files:
            try:
                df = pd.read_csv(prophage_files[0], sep='\t')

                for _, row in df.iterrows():
                    contig = row['scaffold']
                    start = int(row['nucleotide start'])
                    end = int(row['nucleotide stop'])

                    # Store prophage region
                    prophage_regions[sample_id].append({
                        'contig': contig,
                        'start': start,
                        'end': end
                    })
            except Exception as e:
                print(f"Warning: Could not parse {prophage_files[0]}: {e}", file=sys.stderr)

    return prophage_regions

def categorize_amr_genes(amr_data, plasmid_contigs, prophage_regions):
    """
    Categorize each AMR gene by location

    Returns: list of dicts with categorization info
    """
    results = []

    for sample_id, amr_genes in amr_data.items():
        plasmids = plasmid_contigs.get(sample_id, set())
        prophages = prophage_regions.get(sample_id, [])

        for amr in amr_genes:
            contig = amr['contig']
            start = amr['start']
            end = amr['end']

            # Check if on plasmid
            on_plasmid = contig in plasmids

            # Check if in prophage region
            on_prophage = False
            for prophage in prophages:
                if (prophage['contig'] == contig and
                    prophage['start'] <= start <= prophage['end'] and
                    prophage['start'] <= end <= prophage['end']):
                    on_prophage = True
                    break

            # Determine location
            if on_plasmid and on_prophage:
                location = 'plasmid+prophage'  # Rare but possible
            elif on_plasmid:
                location = 'plasmid'
            elif on_prophage:
                location = 'prophage'
            else:
                location = 'chromosome'

            results.append({
                'sample_id': sample_id,
                'gene': amr['gene'],
                'amr_class': amr['class'],
                'contig': contig,
                'start': start,
                'end': end,
                'location': location
            })

    return results

def generate_summary_stats(results_df):
    """
    Generate summary statistics
    """
    print("\n" + "="*70)
    print("AMR LOCATION CATEGORIZATION SUMMARY")
    print("="*70)

    print(f"\nTotal samples analyzed: {results_df['sample_id'].nunique()}")
    print(f"Total AMR genes found: {len(results_df)}")
    print(f"Unique AMR genes: {results_df['gene'].nunique()}")

    print("\n" + "-"*70)
    print("AMR Gene Distribution by Location:")
    print("-"*70)

    location_counts = results_df['location'].value_counts()
    total = len(results_df)

    for location, count in location_counts.items():
        pct = (count / total) * 100
        print(f"  {location.capitalize():20s}: {count:6d} ({pct:5.1f}%)")

    print("\n" + "-"*70)
    print("Top 10 AMR Genes by Frequency:")
    print("-"*70)

    top_genes = results_df['gene'].value_counts().head(10)
    for gene, count in top_genes.items():
        print(f"  {gene:20s}: {count:6d}")

    print("\n" + "-"*70)
    print("AMR Genes on Prophages (Top 10):")
    print("-"*70)

    prophage_amr = results_df[results_df['location'].str.contains('prophage')]
    if len(prophage_amr) > 0:
        prophage_genes = prophage_amr['gene'].value_counts().head(10)
        for gene, count in prophage_genes.items():
            print(f"  {gene:20s}: {count:6d}")
    else:
        print("  No AMR genes found on prophages")

    print("\n" + "-"*70)
    print("AMR Classes by Location:")
    print("-"*70)

    class_location = pd.crosstab(results_df['amr_class'], results_df['location'])
    print(class_location.to_string())

    print("\n" + "="*70)

def main():
    parser = argparse.ArgumentParser(
        description='Categorize AMR genes by genomic location (chromosome/plasmid/prophage)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 categorize_amr_by_location.py \\
        --amrfinder results/amrfinder/ \\
        --mobsuite results/mobsuite/ \\
        --vibrant results/vibrant/ \\
        --output amr_location_matrix.tsv

    # Generate summary only (no detailed output)
    python3 categorize_amr_by_location.py \\
        --amrfinder results/amrfinder/ \\
        --mobsuite results/mobsuite/ \\
        --vibrant results/vibrant/ \\
        --summary-only

Output columns:
    - sample_id: Sample identifier
    - gene: AMR gene name
    - amr_class: Resistance class (beta-lactam, aminoglycoside, etc.)
    - contig: Contig/scaffold ID
    - start: Gene start position
    - end: Gene end position
    - location: chromosome, plasmid, prophage, or plasmid+prophage
        """
    )

    parser.add_argument('--amrfinder', required=True,
                        help='AMRFinder results directory')
    parser.add_argument('--mobsuite', required=True,
                        help='MOB-suite results directory')
    parser.add_argument('--vibrant', required=True,
                        help='VIBRANT results directory')
    parser.add_argument('--output', default='amr_location_matrix.tsv',
                        help='Output TSV file (default: amr_location_matrix.tsv)')
    parser.add_argument('--summary-only', action='store_true',
                        help='Print summary statistics only, do not write file')

    args = parser.parse_args()

    # Validate input directories
    for dir_arg, dir_path in [('amrfinder', args.amrfinder),
                               ('mobsuite', args.mobsuite),
                               ('vibrant', args.vibrant)]:
        if not os.path.isdir(dir_path):
            print(f"Error: {dir_arg} directory not found: {dir_path}", file=sys.stderr)
            sys.exit(1)

    print("Parsing AMRFinder results...")
    amr_data = parse_amrfinder(args.amrfinder)
    print(f"  Found {len(amr_data)} samples with AMR genes")

    print("Parsing MOB-suite results...")
    plasmid_contigs = parse_mobsuite(args.mobsuite)
    print(f"  Found {len(plasmid_contigs)} samples with plasmids")

    print("Parsing VIBRANT results...")
    prophage_regions = parse_vibrant(args.vibrant)
    print(f"  Found {len(prophage_regions)} samples with prophages")

    print("Categorizing AMR genes by location...")
    results = categorize_amr_genes(amr_data, plasmid_contigs, prophage_regions)

    if not results:
        print("Error: No AMR genes found to categorize", file=sys.stderr)
        sys.exit(1)

    # Convert to DataFrame
    results_df = pd.DataFrame(results)

    # Generate summary statistics
    generate_summary_stats(results_df)

    # Write output file
    if not args.summary_only:
        results_df.to_csv(args.output, sep='\t', index=False)
        print(f"\nResults written to: {args.output}")
        print(f"Total entries: {len(results_df)}")

if __name__ == '__main__':
    main()
