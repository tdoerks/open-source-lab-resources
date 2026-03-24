#!/usr/bin/env python3
"""
Parse VIBRANT Prophage Results Summary
======================================

Aggregates VIBRANT prophage predictions across all samples and generates
summary statistics for temporal/comparative studies.

Inputs:
- VIBRANT results directory containing per-sample subdirectories
- Each sample has: VIBRANT_phages_*/VIBRANT_results_*.txt

Outputs:
- Prophage counts per sample
- Quality distribution (complete/high/medium/low)
- Temporal trends (if metadata provided)
- Prophage catalog

Usage:
    python3 parse_vibrant_summary.py \\
        --vibrant results/vibrant/ \\
        --output vibrant_summary.tsv \\
        --prophage-catalog vibrant_prophages.tsv

Author: Claude Code (Anthropic)
Date: 2026-03-24
"""

import argparse
import pandas as pd
import os
import sys
from pathlib import Path
from collections import defaultdict
import re

def find_vibrant_results(vibrant_dir):
    """
    Find all VIBRANT result files

    Returns: dict[sample_id] = path_to_results_file
    """
    results_files = {}
    vibrant_path = Path(vibrant_dir)

    for sample_dir in vibrant_path.iterdir():
        if not sample_dir.is_dir():
            continue

        # Extract sample ID (remove _vibrant suffix if present)
        sample_id = sample_dir.name.replace('_vibrant', '')

        # Look for VIBRANT results file
        # Pattern: VIBRANT_phages_*/VIBRANT_results_*.txt
        phages_dir = list(sample_dir.glob('VIBRANT_phages_*'))

        if phages_dir:
            results_file = list(phages_dir[0].glob('VIBRANT_results_*.txt'))
            if results_file:
                results_files[sample_id] = results_file[0]

    return results_files

def parse_vibrant_file(results_file):
    """
    Parse a single VIBRANT results file

    Returns: list of prophage predictions with metadata
    """
    prophages = []

    try:
        with open(results_file, 'r') as f:
            # Skip header comments
            for line in f:
                if line.startswith('#'):
                    continue
                if not line.strip():
                    continue

                # Parse tab-delimited results
                fields = line.strip().split('\t')

                if len(fields) < 2:
                    continue

                scaffold = fields[0]
                prediction = fields[1] if len(fields) > 1 else "unknown"

                # Extract quality/classification if available
                # VIBRANT classifications: complete, high quality, medium quality, low quality
                quality = "unknown"
                if "complete" in prediction.lower():
                    quality = "complete"
                elif "high" in prediction.lower():
                    quality = "high"
                elif "medium" in prediction.lower():
                    quality = "medium"
                elif "low" in prediction.lower():
                    quality = "low"

                prophages.append({
                    'scaffold': scaffold,
                    'prediction': prediction,
                    'quality': quality
                })

    except Exception as e:
        print(f"Warning: Could not parse {results_file}: {e}", file=sys.stderr)

    return prophages

def parse_all_vibrant_results(vibrant_dir):
    """
    Parse all VIBRANT results

    Returns: dict[sample_id] = list of prophage dicts
    """
    results_files = find_vibrant_results(vibrant_dir)

    all_prophages = {}

    print(f"Found {len(results_files)} samples with VIBRANT results")

    for sample_id, results_file in results_files.items():
        prophages = parse_vibrant_file(results_file)
        all_prophages[sample_id] = prophages

        if prophages:
            print(f"  {sample_id}: {len(prophages)} prophages")

    return all_prophages

def generate_summary_table(prophage_data):
    """
    Generate per-sample summary statistics

    Returns: pandas DataFrame
    """
    summary_rows = []

    for sample_id, prophages in prophage_data.items():
        # Count prophages by quality
        quality_counts = defaultdict(int)
        for p in prophages:
            quality_counts[p['quality']] += 1

        summary_rows.append({
            'sample_id': sample_id,
            'total_prophages': len(prophages),
            'complete': quality_counts.get('complete', 0),
            'high_quality': quality_counts.get('high', 0),
            'medium_quality': quality_counts.get('medium', 0),
            'low_quality': quality_counts.get('low', 0),
            'unknown_quality': quality_counts.get('unknown', 0)
        })

    return pd.DataFrame(summary_rows)

def generate_prophage_catalog(prophage_data):
    """
    Generate detailed catalog of all prophages

    Returns: pandas DataFrame
    """
    catalog_rows = []

    for sample_id, prophages in prophage_data.items():
        for idx, p in enumerate(prophages, 1):
            catalog_rows.append({
                'sample_id': sample_id,
                'prophage_id': f"{sample_id}_prophage_{idx}",
                'scaffold': p['scaffold'],
                'prediction': p['prediction'],
                'quality': p['quality']
            })

    return pd.DataFrame(catalog_rows)

def generate_statistics(summary_df):
    """
    Print summary statistics
    """
    print("\n" + "="*70)
    print("VIBRANT PROPHAGE SUMMARY STATISTICS")
    print("="*70)

    total_samples = len(summary_df)
    total_prophages = summary_df['total_prophages'].sum()

    print(f"\nTotal samples analyzed: {total_samples}")
    print(f"Total prophages detected: {total_prophages}")
    print(f"Average prophages per sample: {total_prophages / total_samples:.2f}")
    print(f"Max prophages in a sample: {summary_df['total_prophages'].max()}")
    print(f"Min prophages in a sample: {summary_df['total_prophages'].min()}")

    print("\n" + "-"*70)
    print("Prophage Quality Distribution:")
    print("-"*70)

    quality_totals = {
        'Complete': summary_df['complete'].sum(),
        'High quality': summary_df['high_quality'].sum(),
        'Medium quality': summary_df['medium_quality'].sum(),
        'Low quality': summary_df['low_quality'].sum(),
        'Unknown': summary_df['unknown_quality'].sum()
    }

    for quality, count in quality_totals.items():
        pct = (count / total_prophages * 100) if total_prophages > 0 else 0
        print(f"  {quality:20s}: {count:6d} ({pct:5.1f}%)")

    print("\n" + "-"*70)
    print("Samples by Prophage Burden:")
    print("-"*70)

    burden_bins = [
        (0, "No prophages"),
        (1, "1-2 prophages"),
        (3, "3-5 prophages"),
        (6, "6-10 prophages"),
        (11, ">10 prophages")
    ]

    for threshold, label in burden_bins:
        if threshold == 0:
            count = len(summary_df[summary_df['total_prophages'] == 0])
        elif label == ">10 prophages":
            count = len(summary_df[summary_df['total_prophages'] > 10])
        else:
            lower, upper = threshold, threshold + (1 if "1-2" in label else 2 if "3-5" in label else 4)
            count = len(summary_df[(summary_df['total_prophages'] >= lower) & (summary_df['total_prophages'] <= upper)])

        pct = (count / total_samples * 100) if total_samples > 0 else 0
        print(f"  {label:20s}: {count:6d} ({pct:5.1f}%)")

    print("\n" + "="*70)

def main():
    parser = argparse.ArgumentParser(
        description='Parse and summarize VIBRANT prophage predictions',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 parse_vibrant_summary.py \\
        --vibrant results/vibrant/ \\
        --output vibrant_summary.tsv

    # With prophage catalog
    python3 parse_vibrant_summary.py \\
        --vibrant results/vibrant/ \\
        --output vibrant_summary.tsv \\
        --prophage-catalog vibrant_prophages.tsv

Output columns (summary):
    - sample_id: Sample identifier
    - total_prophages: Total number of prophages detected
    - complete: Complete prophage genomes
    - high_quality: High quality predictions
    - medium_quality: Medium quality predictions
    - low_quality: Low quality predictions
    - unknown_quality: Quality not determined

Output columns (catalog):
    - sample_id: Sample identifier
    - prophage_id: Unique prophage ID
    - scaffold: Scaffold/contig name
    - prediction: VIBRANT prediction
    - quality: Quality classification
        """
    )

    parser.add_argument('--vibrant', required=True,
                        help='VIBRANT results directory')
    parser.add_argument('--output', default='vibrant_summary.tsv',
                        help='Output summary TSV file (default: vibrant_summary.tsv)')
    parser.add_argument('--prophage-catalog', default=None,
                        help='Optional detailed prophage catalog TSV')

    args = parser.parse_args()

    # Validate input directory
    if not os.path.isdir(args.vibrant):
        print(f"Error: VIBRANT directory not found: {args.vibrant}", file=sys.stderr)
        sys.exit(1)

    print("Parsing VIBRANT results...")
    prophage_data = parse_all_vibrant_results(args.vibrant)

    if not prophage_data:
        print("Error: No VIBRANT results found", file=sys.stderr)
        sys.exit(1)

    print("\nGenerating summary table...")
    summary_df = generate_summary_table(prophage_data)

    # Sort by total prophages (descending)
    summary_df = summary_df.sort_values('total_prophages', ascending=False)

    # Write summary
    summary_df.to_csv(args.output, sep='\t', index=False)
    print(f"\nSummary written to: {args.output}")
    print(f"Total samples: {len(summary_df)}")

    # Generate prophage catalog if requested
    if args.prophage_catalog:
        print("\nGenerating prophage catalog...")
        catalog_df = generate_prophage_catalog(prophage_data)
        catalog_df.to_csv(args.prophage_catalog, sep='\t', index=False)
        print(f"Catalog written to: {args.prophage_catalog}")
        print(f"Total prophages: {len(catalog_df)}")

    # Print statistics
    generate_statistics(summary_df)

if __name__ == '__main__':
    main()
