#!/usr/bin/env python3
"""
Parse SISTR Serotyping Results
===============================

Aggregates SISTR serotyping predictions across Salmonella samples and
generates serotype distribution summaries for temporal/comparative studies.

Critical for Salmonella temporal phage study to answer:
- Which serotypes are most prevalent?
- How does serotype distribution change over time?
- Does prophage burden vary by serotype?

Usage:
    python3 parse_sistr_serotypes.py \\
        --sistr results/sistr/ \\
        --output sistr_distribution.tsv \\
        --top-n 20

Author: Claude Code (Anthropic)
Date: 2026-03-24
"""

import argparse
import pandas as pd
import os
import sys
from pathlib import Path
from collections import Counter

def parse_sistr_results(sistr_dir):
    """
    Parse all SISTR result files

    Returns: pandas DataFrame with all results
    """
    sistr_path = Path(sistr_dir)
    all_results = []

    for sistr_file in sistr_path.glob('*/*_sistr.tsv'):
        try:
            # Read SISTR results
            df = pd.read_csv(sistr_file, sep='\t')

            # Add sample ID from filename if not in results
            if 'genome' not in df.columns:
                sample_id = sistr_file.stem.replace('_sistr', '')
                df['sample_id'] = sample_id
            else:
                df['sample_id'] = df['genome'].apply(lambda x: os.path.basename(x).split('.')[0])

            all_results.append(df)

        except Exception as e:
            print(f"Warning: Could not parse {sistr_file}: {e}", file=sys.stderr)

    if not all_results:
        return pd.DataFrame()

    # Combine all results
    combined_df = pd.concat(all_results, ignore_index=True)

    return combined_df

def generate_serotype_distribution(sistr_df, top_n=20):
    """
    Generate serotype distribution summary

    Returns: pandas DataFrame
    """
    # Filter out skipped samples
    valid_df = sistr_df[
        (~sistr_df['serovar'].str.contains('SKIPPED', na=False)) &
        (sistr_df['serovar'] != '-')
    ]

    # Count serotypes
    serotype_counts = valid_df['serovar'].value_counts()

    # Create distribution dataframe
    distribution = pd.DataFrame({
        'serotype': serotype_counts.index,
        'count': serotype_counts.values,
        'percentage': (serotype_counts.values / serotype_counts.sum() * 100).round(2)
    })

    # Add top N indicator
    distribution['rank'] = range(1, len(distribution) + 1)
    distribution['top_n'] = distribution['rank'] <= top_n

    return distribution

def generate_serogroup_distribution(sistr_df):
    """
    Generate serogroup distribution

    Returns: pandas DataFrame
    """
    # Filter out skipped samples
    valid_df = sistr_df[
        (~sistr_df['serogroup'].str.contains('SKIPPED', na=False)) &
        (sistr_df['serogroup'] != '-')
    ]

    # Count serogroups
    serogroup_counts = valid_df['serogroup'].value_counts()

    distribution = pd.DataFrame({
        'serogroup': serogroup_counts.index,
        'count': serogroup_counts.values,
        'percentage': (serogroup_counts.values / serogroup_counts.sum() * 100).round(2)
    })

    return distribution

def generate_antigen_formula_summary(sistr_df):
    """
    Generate antigen formula summary (H1, H2, O antigens)

    Returns: pandas DataFrame
    """
    # Filter valid results
    valid_df = sistr_df[
        (~sistr_df.get('h1', pd.Series(['-'])).str.contains('SKIPPED', na=False)) &
        (sistr_df.get('h1', pd.Series(['-'])) != '-')
    ]

    summary_rows = []

    # H1 antigen distribution
    if 'h1' in valid_df.columns:
        h1_counts = valid_df['h1'].value_counts().head(10)
        for antigen, count in h1_counts.items():
            summary_rows.append({
                'antigen_type': 'H1',
                'antigen': antigen,
                'count': count
            })

    # H2 antigen distribution
    if 'h2' in valid_df.columns:
        h2_counts = valid_df['h2'].value_counts().head(10)
        for antigen, count in h2_counts.items():
            summary_rows.append({
                'antigen_type': 'H2',
                'antigen': antigen,
                'count': count
            })

    # O antigen distribution
    if 'o_antigen' in valid_df.columns:
        o_counts = valid_df['o_antigen'].value_counts().head(10)
        for antigen, count in o_counts.items():
            summary_rows.append({
                'antigen_type': 'O',
                'antigen': antigen,
                'count': count
            })

    return pd.DataFrame(summary_rows)

def print_statistics(sistr_df, serotype_dist, serogroup_dist):
    """
    Print summary statistics
    """
    print("\n" + "="*70)
    print("SISTR SEROTYPING SUMMARY")
    print("="*70)

    total_samples = len(sistr_df)
    skipped = len(sistr_df[sistr_df['serovar'].str.contains('SKIPPED', na=False)])
    typed = total_samples - skipped

    print(f"\nTotal samples: {total_samples}")
    print(f"Successfully typed: {typed}")
    print(f"Skipped (non-Salmonella): {skipped}")

    if typed > 0:
        print(f"\nUnique serotypes: {len(serotype_dist)}")
        print(f"Unique serogroups: {len(serogroup_dist)}")

        print("\n" + "-"*70)
        print("Top 10 Serotypes:")
        print("-"*70)

        for idx, row in serotype_dist.head(10).iterrows():
            print(f"  {row['rank']:2d}. {row['serotype']:30s}: {row['count']:6d} ({row['percentage']:5.1f}%)")

        print("\n" + "-"*70)
        print("Serogroup Distribution:")
        print("-"*70)

        for idx, row in serogroup_dist.head(10).iterrows():
            pct = row['percentage']
            print(f"  {row['serogroup']:10s}: {row['count']:6d} ({pct:5.1f}%)")

        # Check for known high-prophage serotypes
        print("\n" + "-"*70)
        print("High-Prophage Serotypes (Known from Literature):")
        print("-"*70)

        high_prophage_serotypes = ['Typhimurium', 'Enteritidis', 'Newport', 'Heidelberg']
        for serovar in high_prophage_serotypes:
            count = len(sistr_df[sistr_df['serovar'].str.contains(serovar, case=False, na=False)])
            if count > 0:
                pct = (count / typed * 100) if typed > 0 else 0
                print(f"  {serovar:20s}: {count:6d} ({pct:5.1f}%)")

    print("\n" + "="*70)

def main():
    parser = argparse.ArgumentParser(
        description='Parse and summarize SISTR serotyping results for Salmonella',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 parse_sistr_serotypes.py \\
        --sistr results/sistr/ \\
        --output sistr_distribution.tsv

    # Show top 20 serotypes
    python3 parse_sistr_serotypes.py \\
        --sistr results/sistr/ \\
        --output sistr_distribution.tsv \\
        --top-n 20

Output columns:
    - serotype: Salmonella serovar (e.g., Typhimurium, Enteritidis)
    - count: Number of samples
    - percentage: Percentage of typed samples
    - rank: Rank by frequency
    - top_n: True if in top N serotypes
        """
    )

    parser.add_argument('--sistr', required=True,
                        help='SISTR results directory')
    parser.add_argument('--output', default='sistr_distribution.tsv',
                        help='Output distribution TSV (default: sistr_distribution.tsv)')
    parser.add_argument('--serogroup-output', default=None,
                        help='Optional serogroup distribution TSV')
    parser.add_argument('--antigen-output', default=None,
                        help='Optional antigen formula summary TSV')
    parser.add_argument('--top-n', type=int, default=20,
                        help='Number of top serotypes to highlight (default: 20)')

    args = parser.parse_args()

    # Validate input
    if not os.path.isdir(args.sistr):
        print(f"Error: SISTR directory not found: {args.sistr}", file=sys.stderr)
        sys.exit(1)

    print("Parsing SISTR results...")
    sistr_df = parse_sistr_results(args.sistr)

    if sistr_df.empty:
        print("Error: No SISTR results found", file=sys.stderr)
        sys.exit(1)

    print(f"  Found {len(sistr_df)} samples")

    print("\nGenerating serotype distribution...")
    serotype_dist = generate_serotype_distribution(sistr_df, args.top_n)

    print("Generating serogroup distribution...")
    serogroup_dist = generate_serogroup_distribution(sistr_df)

    # Write outputs
    serotype_dist.to_csv(args.output, sep='\t', index=False)
    print(f"\nSerotype distribution written to: {args.output}")

    if args.serogroup_output:
        serogroup_dist.to_csv(args.serogroup_output, sep='\t', index=False)
        print(f"Serogroup distribution written to: {args.serogroup_output}")

    if args.antigen_output:
        print("\nGenerating antigen formula summary...")
        antigen_summary = generate_antigen_formula_summary(sistr_df)
        antigen_summary.to_csv(args.antigen_output, sep='\t', index=False)
        print(f"Antigen summary written to: {args.antigen_output}")

    # Print statistics
    print_statistics(sistr_df, serotype_dist, serogroup_dist)

if __name__ == '__main__':
    main()
