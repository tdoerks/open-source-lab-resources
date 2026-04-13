#!/usr/bin/env python3
"""
Summarize Prokka Genome Annotations
====================================

Parses Prokka annotation results to generate summary statistics:
- Gene counts (CDS, tRNA, rRNA, etc.)
- Annotation quality metrics
- Functional category distribution
- Hypothetical protein percentages

Critical for comparative genomics studies.

Usage:
    python3 summarize_prokka_annotations.py \
        --prokka results/prokka/ \
        --output prokka_summary.tsv

Author: Claude Code (Anthropic)
Date: 2026-03-25
"""

import argparse
import pandas as pd
import os
import sys
from pathlib import Path
from collections import defaultdict
import re

def parse_prokka_txt(txt_file):
    """
    Parse Prokka .txt summary file for basic statistics.

    Returns: dict with annotation stats
    """
    stats = {
        'contigs': 0,
        'bases': 0,
        'cds': 0,
        'trna': 0,
        'rrna': 0,
        'misc_rna': 0,
        'repeat_region': 0
    }

    try:
        with open(txt_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('organism:') or line.startswith('contigs:'):
                    continue

                # Parse statistics lines
                if 'contigs' in line.lower():
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['contigs'] = int(match.group(1))
                elif 'bases' in line.lower():
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['bases'] = int(match.group(1))
                elif 'CDS' in line:
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['cds'] = int(match.group(1))
                elif 'tRNA' in line:
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['trna'] = int(match.group(1))
                elif 'rRNA' in line:
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['rrna'] = int(match.group(1))
                elif 'misc_RNA' in line:
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['misc_rna'] = int(match.group(1))
                elif 'repeat_region' in line:
                    match = re.search(r'(\d+)', line)
                    if match:
                        stats['repeat_region'] = int(match.group(1))

    except Exception as e:
        print(f"Warning: Could not parse {txt_file}: {e}", file=sys.stderr)

    return stats

def parse_prokka_gff(gff_file):
    """
    Parse Prokka GFF file for detailed annotation information.

    Returns: dict with annotation details
    """
    annotations = {
        'hypothetical': 0,
        'total_genes': 0,
        'with_product': 0,
        'with_ec': 0,
        'with_gene': 0
    }

    try:
        with open(gff_file, 'r') as f:
            for line in f:
                # Skip comments and headers
                if line.startswith('#'):
                    continue

                parts = line.strip().split('\t')
                if len(parts) < 9:
                    continue

                feature_type = parts[2]
                attributes = parts[8]

                if feature_type == 'CDS':
                    annotations['total_genes'] += 1

                    # Check for hypothetical proteins
                    if 'hypothetical protein' in attributes.lower():
                        annotations['hypothetical'] += 1

                    # Check for product annotation
                    if 'product=' in attributes:
                        annotations['with_product'] += 1

                    # Check for EC number
                    if 'eC_number=' in attributes:
                        annotations['with_ec'] += 1

                    # Check for gene name
                    if 'gene=' in attributes:
                        annotations['with_gene'] += 1

    except Exception as e:
        print(f"Warning: Could not parse {gff_file}: {e}", file=sys.stderr)

    return annotations

def find_prokka_results(prokka_dir):
    """
    Find all Prokka result directories.

    Returns: dict[sample_id] = path_to_prokka_dir
    """
    results = {}
    prokka_path = Path(prokka_dir)

    for item in prokka_path.iterdir():
        if not item.is_dir():
            continue

        # Sample ID is directory name (remove _prokka suffix if present)
        sample_id = item.name.replace('_prokka', '')

        # Check for required files
        txt_file = None
        gff_file = None

        # Look for .txt and .gff files
        for f in item.glob('*.txt'):
            if not f.name.startswith('.'):
                txt_file = f
                break

        for f in item.glob('*.gff'):
            if not f.name.startswith('.'):
                gff_file = f
                break

        if txt_file and gff_file:
            results[sample_id] = {
                'txt': txt_file,
                'gff': gff_file
            }
        else:
            print(f"Warning: Incomplete Prokka results for {sample_id}", file=sys.stderr)

    return results

def summarize_prokka_results(prokka_dir):
    """
    Summarize all Prokka annotation results.

    Returns: pandas DataFrame with summary statistics
    """
    print("Finding Prokka results...")
    results_files = find_prokka_results(prokka_dir)

    if not results_files:
        print("ERROR: No Prokka results found", file=sys.stderr)
        return None

    print(f"Found {len(results_files)} samples with Prokka annotations")

    summary_rows = []

    for sample_id, files in results_files.items():
        print(f"  Processing {sample_id}...")

        # Parse .txt file for basic stats
        txt_stats = parse_prokka_txt(files['txt'])

        # Parse .gff file for annotation details
        gff_stats = parse_prokka_gff(files['gff'])

        # Calculate derived metrics
        total_features = txt_stats['cds'] + txt_stats['trna'] + txt_stats['rrna'] + txt_stats['misc_rna']

        hypothetical_pct = 0
        if gff_stats['total_genes'] > 0:
            hypothetical_pct = (gff_stats['hypothetical'] / gff_stats['total_genes']) * 100

        annotation_pct = 0
        if gff_stats['total_genes'] > 0:
            annotation_pct = (gff_stats['with_product'] / gff_stats['total_genes']) * 100

        # Compile summary
        summary_rows.append({
            'sample_id': sample_id,
            'genome_size': txt_stats['bases'],
            'contigs': txt_stats['contigs'],
            'total_genes': txt_stats['cds'],
            'trna_genes': txt_stats['trna'],
            'rrna_genes': txt_stats['rrna'],
            'misc_rna': txt_stats['misc_rna'],
            'repeat_regions': txt_stats['repeat_region'],
            'total_features': total_features,
            'hypothetical_proteins': gff_stats['hypothetical'],
            'hypothetical_pct': round(hypothetical_pct, 2),
            'with_product': gff_stats['with_product'],
            'annotation_pct': round(annotation_pct, 2),
            'with_ec_number': gff_stats['with_ec'],
            'with_gene_name': gff_stats['with_gene'],
            'coding_density': round((txt_stats['cds'] / txt_stats['bases']) * 1000, 2) if txt_stats['bases'] > 0 else 0
        })

    return pd.DataFrame(summary_rows)

def generate_statistics(summary_df):
    """
    Print summary statistics to console.
    """
    print("\n" + "="*70)
    print("PROKKA ANNOTATION SUMMARY STATISTICS")
    print("="*70)

    print(f"\nTotal samples annotated: {len(summary_df)}")
    print(f"Average genome size: {summary_df['genome_size'].mean():,.0f} bp")
    print(f"Average gene count: {summary_df['total_genes'].mean():.1f}")
    print(f"Average hypothetical percentage: {summary_df['hypothetical_pct'].mean():.1f}%")
    print(f"Average annotation percentage: {summary_df['annotation_pct'].mean():.1f}%")

    print("\n" + "-"*70)
    print("Gene Type Distribution (Averages):")
    print("-"*70)
    print(f"  CDS genes:       {summary_df['total_genes'].mean():7.1f}")
    print(f"  tRNA genes:      {summary_df['trna_genes'].mean():7.1f}")
    print(f"  rRNA genes:      {summary_df['rrna_genes'].mean():7.1f}")
    print(f"  Misc RNA:        {summary_df['misc_rna'].mean():7.1f}")
    print(f"  Repeat regions:  {summary_df['repeat_regions'].mean():7.1f}")

    print("\n" + "-"*70)
    print("Annotation Quality Metrics:")
    print("-"*70)
    print(f"  Samples with >90% annotation: {(summary_df['annotation_pct'] > 90).sum()}")
    print(f"  Samples with >80% annotation: {(summary_df['annotation_pct'] > 80).sum()}")
    print(f"  Samples with <50% hypothetical: {(summary_df['hypothetical_pct'] < 50).sum()}")

    print("\n" + "-"*70)
    print("Top 5 Samples by Gene Count:")
    print("-"*70)
    top_samples = summary_df.nlargest(5, 'total_genes')[['sample_id', 'total_genes', 'genome_size']]
    for _, row in top_samples.iterrows():
        print(f"  {row['sample_id']:20s}: {row['total_genes']:5.0f} genes ({row['genome_size']:,} bp)")

    print("\n" + "="*70)

def main():
    parser = argparse.ArgumentParser(
        description='Summarize Prokka genome annotation results',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 summarize_prokka_annotations.py \\
        --prokka results/prokka/ \\
        --output prokka_summary.tsv

Output columns:
    - sample_id: Sample identifier
    - genome_size: Total genome length (bp)
    - contigs: Number of contigs
    - total_genes: Total CDS features
    - trna_genes: tRNA gene count
    - rrna_genes: rRNA gene count
    - misc_rna: Other RNA features
    - repeat_regions: Repeat region count
    - total_features: Sum of all features
    - hypothetical_proteins: Number of hypothetical proteins
    - hypothetical_pct: Percentage of genes that are hypothetical
    - with_product: Genes with product annotation
    - annotation_pct: Percentage of genes with annotation
    - with_ec_number: Genes with EC numbers
    - with_gene_name: Genes with gene names
    - coding_density: Genes per kilobase
        """
    )

    parser.add_argument('--prokka', required=True,
                        help='Prokka results directory')
    parser.add_argument('--output', default='prokka_summary.tsv',
                        help='Output TSV file (default: prokka_summary.tsv)')

    args = parser.parse_args()

    # Validate input directory
    if not os.path.isdir(args.prokka):
        print(f"Error: Prokka directory not found: {args.prokka}", file=sys.stderr)
        sys.exit(1)

    # Summarize Prokka results
    summary_df = summarize_prokka_results(args.prokka)

    if summary_df is None or len(summary_df) == 0:
        print("Error: No Prokka results could be summarized", file=sys.stderr)
        sys.exit(1)

    # Sort by sample ID
    summary_df = summary_df.sort_values('sample_id')

    # Write output
    summary_df.to_csv(args.output, sep='\t', index=False)
    print(f"\n✅ Prokka summary written to: {args.output}")
    print(f"   Total samples: {len(summary_df)}")

    # Generate statistics
    generate_statistics(summary_df)

if __name__ == '__main__':
    main()
