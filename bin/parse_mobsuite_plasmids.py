#!/usr/bin/env python3
"""
Parse MOB-suite Plasmid Results
================================

Aggregates MOB-suite plasmid reconstruction results and generates
summary statistics for temporal/comparative studies.

Key for understanding:
- Plasmid prevalence and diversity
- Incompatibility group distribution
- Plasmid-AMR-prophage interactions

Usage:
    python3 parse_mobsuite_plasmids.py \\
        --mobsuite results/mobsuite/ \\
        --output mobsuite_summary.tsv \\
        --plasmid-catalog mobsuite_plasmids.tsv

Author: Claude Code (Anthropic)
Date: 2026-03-24
"""

import argparse
import pandas as pd
import os
import sys
from pathlib import Path
from collections import defaultdict, Counter

def parse_mobsuite_results(mobsuite_dir):
    """
    Parse all MOB-suite results

    Returns: dict[sample_id] = {'plasmids': list, 'mobtyper': DataFrame}
    """
    mobsuite_path = Path(mobsuite_dir)
    all_results = {}

    for sample_dir in mobsuite_path.iterdir():
        if not sample_dir.is_dir():
            continue

        # Extract sample ID (remove _mobsuite suffix if present)
        sample_id = sample_dir.name.replace('_mobsuite', '')

        sample_data = {
            'plasmids': [],
            'mobtyper': None
        }

        # Count plasmid FASTA files
        plasmid_files = list(sample_dir.glob('plasmid_*.fasta'))
        sample_data['plasmids'] = plasmid_files

        # Parse mobtyper results for incompatibility groups
        mobtyper_file = sample_dir / 'mobtyper_results.txt'
        if mobtyper_file.exists():
            try:
                df = pd.read_csv(mobtyper_file, sep='\t')
                sample_data['mobtyper'] = df
            except Exception as e:
                print(f"Warning: Could not parse mobtyper for {sample_id}: {e}", file=sys.stderr)

        all_results[sample_id] = sample_data

    return all_results

def generate_summary_table(mobsuite_data):
    """
    Generate per-sample summary statistics

    Returns: pandas DataFrame
    """
    summary_rows = []

    for sample_id, data in mobsuite_data.items():
        plasmid_count = len(data['plasmids'])

        # Extract incompatibility groups
        inc_groups = []
        total_plasmid_size = 0

        if data['mobtyper'] is not None:
            # Get incompatibility groups
            if 'predicted_mobility' in data['mobtyper'].columns:
                mobility = data['mobtyper']['predicted_mobility'].tolist()
            else:
                mobility = []

            if 'rep_type(s)' in data['mobtyper'].columns:
                inc_groups = data['mobtyper']['rep_type(s)'].dropna().tolist()
            elif 'replicon_type' in data['mobtyper'].columns:
                inc_groups = data['mobtyper']['replicon_type'].dropna().tolist()

            # Get plasmid sizes
            if 'size' in data['mobtyper'].columns:
                total_plasmid_size = data['mobtyper']['size'].sum()

        # Combine inc groups into comma-separated string
        inc_groups_str = ','.join([str(g) for g in inc_groups if g and g != '-'])

        summary_rows.append({
            'sample_id': sample_id,
            'plasmid_count': plasmid_count,
            'total_plasmid_size_bp': int(total_plasmid_size) if total_plasmid_size else 0,
            'inc_groups': inc_groups_str if inc_groups_str else 'None',
            'has_plasmids': plasmid_count > 0
        })

    return pd.DataFrame(summary_rows)

def generate_plasmid_catalog(mobsuite_data):
    """
    Generate detailed catalog of all plasmids

    Returns: pandas DataFrame
    """
    catalog_rows = []

    for sample_id, data in mobsuite_data.items():
        if data['mobtyper'] is not None:
            for idx, row in data['mobtyper'].iterrows():
                catalog_rows.append({
                    'sample_id': sample_id,
                    'plasmid_id': row.get('sample_id', f"{sample_id}_plasmid_{idx+1}"),
                    'size_bp': row.get('size', 0),
                    'rep_type': row.get('rep_type(s)', row.get('replicon_type', 'Unknown')),
                    'mobility': row.get('predicted_mobility', 'Unknown'),
                    'mash_nearest_neighbor': row.get('mash_nearest_neighbor', 'Unknown')
                })

    return pd.DataFrame(catalog_rows)

def analyze_inc_groups(mobsuite_data):
    """
    Analyze incompatibility group distribution

    Returns: Counter object
    """
    inc_counter = Counter()

    for sample_id, data in mobsuite_data.items():
        if data['mobtyper'] is not None:
            # Get rep types
            if 'rep_type(s)' in data['mobtyper'].columns:
                rep_types = data['mobtyper']['rep_type(s)'].dropna()
            elif 'replicon_type' in data['mobtyper'].columns:
                rep_types = data['mobtyper']['replicon_type'].dropna()
            else:
                continue

            for rep_type in rep_types:
                if rep_type and rep_type != '-':
                    # Split multi-replicon plasmids
                    for r in str(rep_type).split(','):
                        r = r.strip()
                        if r:
                            inc_counter[r] += 1

    return inc_counter

def print_statistics(summary_df, inc_groups):
    """
    Print summary statistics
    """
    print("\n" + "="*70)
    print("MOB-SUITE PLASMID SUMMARY")
    print("="*70)

    total_samples = len(summary_df)
    samples_with_plasmids = summary_df['has_plasmids'].sum()
    total_plasmids = summary_df['plasmid_count'].sum()

    print(f"\nTotal samples analyzed: {total_samples}")
    print(f"Samples with plasmids: {samples_with_plasmids} ({samples_with_plasmids/total_samples*100:.1f}%)")
    print(f"Samples without plasmids: {total_samples - samples_with_plasmids}")
    print(f"Total plasmids detected: {total_plasmids}")

    if samples_with_plasmids > 0:
        avg_plasmids = summary_df[summary_df['has_plasmids']]['plasmid_count'].mean()
        print(f"Average plasmids per sample (with plasmids): {avg_plasmids:.2f}")
        print(f"Max plasmids in a sample: {summary_df['plasmid_count'].max()}")

    print("\n" + "-"*70)
    print("Plasmid Burden Distribution:")
    print("-"*70)

    burden_bins = [0, 1, 2, 3, 5, 10]
    for i in range(len(burden_bins)):
        if i == len(burden_bins) - 1:
            count = len(summary_df[summary_df['plasmid_count'] >= burden_bins[i]])
            label = f">={burden_bins[i]} plasmids"
        elif i == 0:
            count = len(summary_df[summary_df['plasmid_count'] == 0])
            label = "No plasmids"
        else:
            lower = burden_bins[i]
            upper = burden_bins[i+1] - 1
            count = len(summary_df[(summary_df['plasmid_count'] >= lower) & (summary_df['plasmid_count'] <= upper)])
            if lower == upper:
                label = f"{lower} plasmid" + ("" if lower == 1 else "s")
            else:
                label = f"{lower}-{upper} plasmids"

        pct = (count / total_samples * 100) if total_samples > 0 else 0
        print(f"  {label:20s}: {count:6d} ({pct:5.1f}%)")

    if inc_groups:
        print("\n" + "-"*70)
        print("Top 20 Incompatibility Groups:")
        print("-"*70)

        for inc_group, count in inc_groups.most_common(20):
            pct = (count / total_plasmids * 100) if total_plasmids > 0 else 0
            print(f"  {inc_group:30s}: {count:6d} ({pct:5.1f}%)")

    print("\n" + "="*70)

def main():
    parser = argparse.ArgumentParser(
        description='Parse and summarize MOB-suite plasmid reconstruction results',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 parse_mobsuite_plasmids.py \\
        --mobsuite results/mobsuite/ \\
        --output mobsuite_summary.tsv

    # With plasmid catalog
    python3 parse_mobsuite_plasmids.py \\
        --mobsuite results/mobsuite/ \\
        --output mobsuite_summary.tsv \\
        --plasmid-catalog mobsuite_plasmids.tsv

Output columns (summary):
    - sample_id: Sample identifier
    - plasmid_count: Number of plasmids detected
    - total_plasmid_size_bp: Total size of all plasmids
    - inc_groups: Incompatibility groups (comma-separated)
    - has_plasmids: Boolean

Output columns (catalog):
    - sample_id: Sample identifier
    - plasmid_id: Plasmid identifier
    - size_bp: Plasmid size in base pairs
    - rep_type: Replicon/incompatibility type
    - mobility: Predicted mobility (conjugative/mobilizable/non-mobilizable)
    - mash_nearest_neighbor: Closest known plasmid
        """
    )

    parser.add_argument('--mobsuite', required=True,
                        help='MOB-suite results directory')
    parser.add_argument('--output', default='mobsuite_summary.tsv',
                        help='Output summary TSV (default: mobsuite_summary.tsv)')
    parser.add_argument('--plasmid-catalog', default=None,
                        help='Optional detailed plasmid catalog TSV')
    parser.add_argument('--inc-groups-output', default=None,
                        help='Optional incompatibility group distribution TSV')

    args = parser.parse_args()

    # Validate input
    if not os.path.isdir(args.mobsuite):
        print(f"Error: MOB-suite directory not found: {args.mobsuite}", file=sys.stderr)
        sys.exit(1)

    print("Parsing MOB-suite results...")
    mobsuite_data = parse_mobsuite_results(args.mobsuite)

    if not mobsuite_data:
        print("Error: No MOB-suite results found", file=sys.stderr)
        sys.exit(1)

    print(f"  Found {len(mobsuite_data)} samples")

    print("\nGenerating summary table...")
    summary_df = generate_summary_table(mobsuite_data)

    # Sort by plasmid count
    summary_df = summary_df.sort_values('plasmid_count', ascending=False)

    # Write summary
    summary_df.to_csv(args.output, sep='\t', index=False)
    print(f"\nSummary written to: {args.output}")

    # Generate plasmid catalog if requested
    if args.plasmid_catalog:
        print("\nGenerating plasmid catalog...")
        catalog_df = generate_plasmid_catalog(mobsuite_data)
        if not catalog_df.empty:
            catalog_df.to_csv(args.plasmid_catalog, sep='\t', index=False)
            print(f"Catalog written to: {args.plasmid_catalog}")
        else:
            print("Warning: No plasmids found for catalog")

    # Analyze incompatibility groups
    print("\nAnalyzing incompatibility groups...")
    inc_groups = analyze_inc_groups(mobsuite_data)

    if args.inc_groups_output and inc_groups:
        inc_df = pd.DataFrame(inc_groups.most_common(), columns=['inc_group', 'count'])
        inc_df['percentage'] = (inc_df['count'] / inc_df['count'].sum() * 100).round(2)
        inc_df.to_csv(args.inc_groups_output, sep='\t', index=False)
        print(f"Incompatibility groups written to: {args.inc_groups_output}")

    # Print statistics
    print_statistics(summary_df, inc_groups)

if __name__ == '__main__':
    main()
