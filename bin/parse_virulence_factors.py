#!/usr/bin/env python3
"""
Parse ABRicate VFDB (Virulence Factor Database) results.

Aggregates virulence factor detections across samples and provides summary statistics.
Useful for identifying virulence profiles and comparing across temporal/geographic cohorts.

Usage:
    python3 parse_virulence_factors.py \\
        --abricate results/abricate/ \\
        --output virulence_summary.tsv \\
        --matrix virulence_matrix.tsv \\
        --top-n 20
"""

import argparse
import pandas as pd
import sys
from pathlib import Path
from collections import defaultdict

def parse_abricate_vfdb(abricate_dir):
    """
    Parse ABRicate VFDB results from directory.

    Args:
        abricate_dir: Path to directory containing ABRicate results

    Returns:
        DataFrame with virulence factor detections
    """
    abricate_path = Path(abricate_dir)

    # Find all VFDB result files
    vfdb_files = list(abricate_path.glob("*_vfdb.tsv"))

    if not vfdb_files:
        print(f"WARNING: No VFDB files found in {abricate_dir}", file=sys.stderr)
        print("Make sure ABRicate was run with VFDB database", file=sys.stderr)
        return pd.DataFrame()

    print(f"Found {len(vfdb_files)} VFDB result files")

    all_results = []

    for vfdb_file in vfdb_files:
        sample_id = vfdb_file.stem.replace('_vfdb', '')

        try:
            # Read ABRicate output
            df = pd.read_csv(vfdb_file, sep='\\t', comment='#')

            if df.empty:
                continue

            # Add sample ID
            df['sample'] = sample_id

            all_results.append(df)

        except Exception as e:
            print(f"WARNING: Failed to parse {vfdb_file}: {e}", file=sys.stderr)
            continue

    if not all_results:
        return pd.DataFrame()

    # Combine all results
    combined_df = pd.concat(all_results, ignore_index=True)

    print(f"Total virulence factors detected: {len(combined_df)}")

    return combined_df

def create_virulence_summary(vf_df):
    """
    Create summary statistics for virulence factors.

    Args:
        vf_df: DataFrame with virulence factor detections

    Returns:
        DataFrame with summary statistics
    """
    if vf_df.empty:
        return pd.DataFrame()

    summary_data = []

    # Per-sample summaries
    for sample in vf_df['sample'].unique():
        sample_df = vf_df[vf_df['sample'] == sample]

        # Count unique virulence genes
        unique_genes = sample_df['GENE'].nunique()
        total_hits = len(sample_df)

        # Average identity and coverage
        avg_identity = sample_df['%IDENTITY'].mean()
        avg_coverage = sample_df['%COVERAGE'].mean()

        # Extract products (virulence functions)
        products = sample_df['PRODUCT'].unique()

        summary_data.append({
            'sample': sample,
            'vf_gene_count': unique_genes,
            'vf_total_hits': total_hits,
            'vf_avg_identity': round(avg_identity, 2),
            'vf_avg_coverage': round(avg_coverage, 2),
            'vf_products': '; '.join(products[:5])  # Top 5 products
        })

    return pd.DataFrame(summary_data)

def create_virulence_matrix(vf_df):
    """
    Create gene presence/absence matrix for virulence factors.

    Args:
        vf_df: DataFrame with virulence factor detections

    Returns:
        DataFrame with genes as rows, samples as columns
    """
    if vf_df.empty:
        return pd.DataFrame()

    # Create binary presence/absence matrix
    matrix = vf_df.pivot_table(
        index='GENE',
        columns='sample',
        values='%IDENTITY',
        aggfunc='max',
        fill_value=0
    )

    # Convert to binary (1 if detected, 0 if not)
    matrix = (matrix > 0).astype(int)

    # Add gene frequency column
    matrix['frequency'] = matrix.sum(axis=1)

    # Sort by frequency (most common first)
    matrix = matrix.sort_values('frequency', ascending=False)

    return matrix

def get_top_virulence_genes(vf_df, top_n=20):
    """
    Get most frequently detected virulence genes.

    Args:
        vf_df: DataFrame with virulence factor detections
        top_n: Number of top genes to return

    Returns:
        DataFrame with top virulence genes and their frequencies
    """
    if vf_df.empty:
        return pd.DataFrame()

    # Count gene frequencies
    gene_counts = vf_df.groupby('GENE').agg({
        'sample': 'count',  # Number of samples with this gene
        'PRODUCT': 'first',  # Function/product
        '%IDENTITY': 'mean',  # Average identity
        '%COVERAGE': 'mean'   # Average coverage
    }).reset_index()

    gene_counts.columns = ['gene', 'sample_count', 'product', 'avg_identity', 'avg_coverage']

    # Calculate percentage of samples
    total_samples = vf_df['sample'].nunique()
    gene_counts['percentage'] = (gene_counts['sample_count'] / total_samples * 100).round(2)

    # Sort by frequency
    gene_counts = gene_counts.sort_values('sample_count', ascending=False)

    # Return top N
    return gene_counts.head(top_n)

def main():
    parser = argparse.ArgumentParser(
        description='Parse ABRicate VFDB virulence factor results',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument(
        '--abricate',
        required=True,
        help='Path to ABRicate results directory'
    )

    parser.add_argument(
        '--output',
        required=True,
        help='Output TSV file for per-sample summary'
    )

    parser.add_argument(
        '--matrix',
        help='Output TSV file for gene presence/absence matrix (optional)'
    )

    parser.add_argument(
        '--top-genes',
        help='Output TSV file for top virulence genes (optional)'
    )

    parser.add_argument(
        '--top-n',
        type=int,
        default=20,
        help='Number of top genes to report (default: 20)'
    )

    args = parser.parse_args()

    # Parse VFDB results
    print("\\nParsing ABRicate VFDB results...")
    vf_df = parse_abricate_vfdb(args.abricate)

    if vf_df.empty:
        print("\\nERROR: No virulence factors detected. Check:")
        print("  1. ABRicate was run with VFDB database")
        print("  2. VFDB result files exist (*_vfdb.tsv)")
        print("  3. Samples contain detectable virulence factors")
        sys.exit(1)

    # Create per-sample summary
    print("\\nCreating per-sample virulence summary...")
    summary_df = create_virulence_summary(vf_df)
    summary_df.to_csv(args.output, sep='\\t', index=False)
    print(f"✅ Per-sample summary written to {args.output}")
    print(f"   Samples analyzed: {len(summary_df)}")
    print(f"   Total unique VF genes: {vf_df['GENE'].nunique()}")

    # Create gene matrix if requested
    if args.matrix:
        print("\\nCreating virulence gene presence/absence matrix...")
        matrix_df = create_virulence_matrix(vf_df)
        matrix_df.to_csv(args.matrix, sep='\\t')
        print(f"✅ Gene matrix written to {args.matrix}")
        print(f"   Genes tracked: {len(matrix_df)}")

    # Create top genes report if requested
    if args.top_genes:
        print(f"\\nIdentifying top {args.top_n} virulence genes...")
        top_genes_df = get_top_virulence_genes(vf_df, args.top_n)
        top_genes_df.to_csv(args.top_genes, sep='\\t', index=False)
        print(f"✅ Top genes written to {args.top_genes}")

        # Display top 10 for quick review
        print("\\n📊 Top 10 Most Frequent Virulence Genes:")
        print(top_genes_df[['gene', 'product', 'sample_count', 'percentage']].head(10).to_string(index=False))

    print("\\n✅ Virulence factor analysis complete!")

    # Summary statistics
    print("\\n" + "="*60)
    print("SUMMARY STATISTICS")
    print("="*60)
    print(f"Total samples: {vf_df['sample'].nunique()}")
    print(f"Total virulence genes detected: {vf_df['GENE'].nunique()}")
    print(f"Total detections: {len(vf_df)}")
    print(f"Average genes per sample: {len(vf_df) / vf_df['sample'].nunique():.1f}")
    print("="*60)

if __name__ == '__main__':
    main()
