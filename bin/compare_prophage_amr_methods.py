#!/usr/bin/env python3
"""
Compare Three Prophage-AMR Detection Methods

Runs and compares three different approaches to identifying AMR genes in prophages:
1. Method 1: Coordinate intersection (fast, integrated)
2. Method 2: Direct AMRFinder scan on prophage sequences (definitive)
3. Method 3: RGI scan on prophage sequences (Pinto et al. paper approach)

Generates comparison report showing agreement/disagreement between methods.

Usage:
    python3 compare_prophage_amr_methods.py \\
        --sample_id <sample> \\
        --vibrant_dir <path> \\
        --amr_results <path> \\
        --prophage_coords <path> \\
        --output_dir <path>
"""

import sys
import argparse
import subprocess
import csv
import json
from pathlib import Path
from collections import defaultdict
import tempfile


def run_method1_coordinate(sample_id, prophage_coords, amr_results, output_dir, terminal_buffer=5000):
    """
    Method 1: Coordinate intersection with terminal filtering

    Returns: dict with {method, gene_count, genes[]}
    """
    output_file = Path(output_dir) / f"{sample_id}_method1_coordinate.tsv"

    cmd = [
        'intersect_prophage_amr.py',
        '--prophage_coords', str(prophage_coords),
        '--amr_results', str(amr_results),
        '--output', str(output_file),
        '--sample_name', sample_id,
        '--terminal_buffer', str(terminal_buffer)
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)

        if result.returncode == 0 and output_file.exists():
            genes = parse_method1_output(output_file)
            return {
                'method': 'coordinate',
                'status': 'success',
                'gene_count': len(genes),
                'genes': genes,
                'output_file': str(output_file)
            }
        else:
            return {'method': 'coordinate', 'status': 'failed', 'gene_count': 0, 'genes': []}

    except Exception as e:
        return {'method': 'coordinate', 'status': 'error', 'gene_count': 0, 'genes': [], 'error': str(e)}


def run_method2_amrfinder(sample_id, vibrant_dir, amr_results, output_dir):
    """
    Method 2: Direct AMRFinder scan on prophage sequences

    Returns: dict with {method, gene_count, genes[]}
    """
    output_file = Path(output_dir) / f"{sample_id}_method2_amrfinder.tsv"

    # Extract prophage sequences
    phages_fasta = find_prophage_fasta(vibrant_dir, sample_id)
    if not phages_fasta:
        return {'method': 'amrfinder_direct', 'status': 'no_sequences', 'gene_count': 0, 'genes': []}

    # Run AMRFinder on prophage sequences
    with tempfile.TemporaryDirectory() as tmpdir:
        amr_output = Path(tmpdir) / f"{sample_id}_prophage_amr.tsv"

        cmd = [
            'amrfinder',
            '--nucleotide', str(phages_fasta),
            '--plus',
            '--output', str(amr_output)
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

            if result.returncode == 0 and amr_output.exists():
                genes = parse_amrfinder_output(amr_output)

                # Write to output file
                write_method2_output(output_file, sample_id, genes)

                return {
                    'method': 'amrfinder_direct',
                    'status': 'success',
                    'gene_count': len(genes),
                    'genes': genes,
                    'output_file': str(output_file)
                }
            else:
                return {'method': 'amrfinder_direct', 'status': 'failed', 'gene_count': 0, 'genes': []}

        except Exception as e:
            return {'method': 'amrfinder_direct', 'status': 'error', 'gene_count': 0, 'genes': [], 'error': str(e)}


def run_method3_rgi(sample_id, vibrant_dir, output_dir):
    """
    Method 3: RGI scan on prophage sequences (Pinto et al. approach)

    Returns: dict with {method, gene_count, genes[]}
    """
    output_file = Path(output_dir) / f"{sample_id}_method3_rgi.tsv"

    cmd = [
        'run_rgi_on_prophages.py',
        str(vibrant_dir),
        sample_id,
        str(output_file)
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

        if result.returncode == 0 and output_file.exists():
            genes = parse_rgi_output(output_file)
            return {
                'method': 'rgi_card',
                'status': 'success',
                'gene_count': len(genes),
                'genes': genes,
                'output_file': str(output_file)
            }
        else:
            return {'method': 'rgi_card', 'status': 'no_rgi', 'gene_count': 0, 'genes': []}

    except Exception as e:
        return {'method': 'rgi_card', 'status': 'error', 'gene_count': 0, 'genes': [], 'error': str(e)}


def find_prophage_fasta(vibrant_dir, sample_id):
    """Find prophage FASTA file from VIBRANT output"""
    possible_paths = [
        Path(vibrant_dir) / f"{sample_id}_phages.fna",
        Path(vibrant_dir) / f"VIBRANT_{sample_id}" / f"{sample_id}_phages.fna",
        Path(vibrant_dir) / f"VIBRANT_{sample_id}_contigs" / f"{sample_id}_contigs_phages.fna",
    ]

    for path in possible_paths:
        if path.exists():
            return path

    return None


def parse_method1_output(tsv_file):
    """Parse Method 1 coordinate intersection output"""
    genes = []
    with open(tsv_file) as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            if row.get('status') == 'retained':
                genes.append(row.get('gene', ''))
    return [g for g in genes if g and g != 'None']


def parse_amrfinder_output(tsv_file):
    """Parse AMRFinder output"""
    genes = []
    with open(tsv_file) as f:
        for line in f:
            if line.startswith('#') or line.startswith('Protein') or line.startswith('Contig'):
                continue
            parts = line.strip().split('\t')
            if len(parts) > 8:
                element_type = parts[8]
                gene = parts[5]
                if element_type == 'AMR' and gene != 'NA':
                    genes.append(gene)
    return genes


def parse_rgi_output(tsv_file):
    """Parse RGI output from Method 3 script"""
    genes = []
    with open(tsv_file) as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            gene = row.get('gene', '')
            if gene and gene != 'None':
                genes.append(gene)
    return genes


def write_method2_output(output_file, sample_id, genes):
    """Write Method 2 results to TSV"""
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\t')
        writer.writerow(['sample_id', 'gene', 'method'])
        if genes:
            for gene in genes:
                writer.writerow([sample_id, gene, 'amrfinder_direct'])
        else:
            writer.writerow([sample_id, 'None', 'amrfinder_direct'])


def generate_comparison_report(sample_id, results, output_file):
    """
    Generate comparison report showing agreement/disagreement

    Returns: dict with comparison metrics
    """
    method1_genes = set(results['method1']['genes'])
    method2_genes = set(results['method2']['genes'])
    method3_genes = set(results['method3']['genes'])

    all_genes = method1_genes | method2_genes | method3_genes

    comparison = {
        'sample_id': sample_id,
        'method1_count': len(method1_genes),
        'method2_count': len(method2_genes),
        'method3_count': len(method3_genes),
        'all_genes_detected': list(all_genes),
        'agreement': [],
        'disagreement': []
    }

    # Analyze each gene
    for gene in all_genes:
        in_m1 = gene in method1_genes
        in_m2 = gene in method2_genes
        in_m3 = gene in method3_genes

        gene_info = {
            'gene': gene,
            'method1': in_m1,
            'method2': in_m2,
            'method3': in_m3,
            'detected_by': sum([in_m1, in_m2, in_m3])
        }

        if gene_info['detected_by'] >= 2:
            comparison['agreement'].append(gene_info)
        else:
            comparison['disagreement'].append(gene_info)

    # Calculate agreement metrics
    comparison['total_genes'] = len(all_genes)
    comparison['agreed_genes'] = len(comparison['agreement'])
    comparison['disagreed_genes'] = len(comparison['disagreement'])

    if comparison['total_genes'] > 0:
        comparison['agreement_pct'] = round(100 * comparison['agreed_genes'] / comparison['total_genes'], 1)
    else:
        comparison['agreement_pct'] = 100.0  # No genes = perfect agreement

    # Write to file
    write_comparison_report(output_file, sample_id, results, comparison)

    return comparison


def write_comparison_report(output_file, sample_id, results, comparison):
    """Write human-readable comparison report"""
    with open(output_file, 'w') as f:
        f.write("=" * 80 + "\n")
        f.write(f"PROPHAGE-AMR METHOD COMPARISON: {sample_id}\n")
        f.write("=" * 80 + "\n\n")

        f.write("RESULTS BY METHOD:\n")
        f.write("-" * 80 + "\n")
        f.write(f"  Method 1 (Coordinate):      {results['method1']['gene_count']} genes - {results['method1']['status']}\n")
        f.write(f"  Method 2 (AMRFinder Direct): {results['method2']['gene_count']} genes - {results['method2']['status']}\n")
        f.write(f"  Method 3 (RGI/CARD):        {results['method3']['gene_count']} genes - {results['method3']['status']}\n\n")

        f.write("COMPARISON SUMMARY:\n")
        f.write("-" * 80 + "\n")
        f.write(f"  Total unique genes detected: {comparison['total_genes']}\n")
        f.write(f"  Genes detected by ≥2 methods: {comparison['agreed_genes']}\n")
        f.write(f"  Genes detected by 1 method:   {comparison['disagreed_genes']}\n")
        f.write(f"  Agreement: {comparison['agreement_pct']}%\n\n")

        if comparison['agreement']:
            f.write("GENES WITH AGREEMENT (detected by ≥2 methods):\n")
            f.write("-" * 80 + "\n")
            for gene in comparison['agreement']:
                methods = []
                if gene['method1']: methods.append('Coordinate')
                if gene['method2']: methods.append('AMRFinder')
                if gene['method3']: methods.append('RGI')
                f.write(f"  • {gene['gene']}: {', '.join(methods)}\n")
            f.write("\n")

        if comparison['disagreement']:
            f.write("GENES WITH DISAGREEMENT (detected by only 1 method):\n")
            f.write("-" * 80 + "\n")
            for gene in comparison['disagreement']:
                method = 'Coordinate' if gene['method1'] else ('AMRFinder' if gene['method2'] else 'RGI')
                f.write(f"  • {gene['gene']}: Only detected by {method}\n")
            f.write("\n")

        if comparison['total_genes'] == 0:
            f.write("✓ No prophage-encoded AMR genes detected by any method\n")
            f.write("  (This is the expected result for most samples)\n\n")


def write_tsv_summary(output_file, sample_id, results, comparison):
    """Write machine-readable TSV summary"""
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\t')

        # Header
        writer.writerow([
            'sample_id', 'gene', 'method1_coordinate', 'method2_amrfinder',
            'method3_rgi', 'detected_by_count', 'agreement_category'
        ])

        # Data rows
        if comparison['total_genes'] > 0:
            all_gene_data = comparison['agreement'] + comparison['disagreement']
            for gene in all_gene_data:
                category = 'agreement' if gene['detected_by'] >= 2 else 'disagreement'
                writer.writerow([
                    sample_id,
                    gene['gene'],
                    'Yes' if gene['method1'] else 'No',
                    'Yes' if gene['method2'] else 'No',
                    'Yes' if gene['method3'] else 'No',
                    gene['detected_by'],
                    category
                ])
        else:
            writer.writerow([sample_id, 'None', 'No', 'No', 'No', 0, 'no_genes'])


def main():
    parser = argparse.ArgumentParser(description='Compare three prophage-AMR detection methods')
    parser.add_argument('--sample_id', required=True, help='Sample identifier')
    parser.add_argument('--vibrant_dir', required=True, help='VIBRANT output directory')
    parser.add_argument('--amr_results', required=True, help='AMRFinder results TSV')
    parser.add_argument('--prophage_coords', required=True, help='VIBRANT prophage coordinates TSV')
    parser.add_argument('--output_dir', required=True, help='Output directory for results')
    parser.add_argument('--terminal_buffer', type=int, default=5000, help='Terminal region buffer (bp)')

    args = parser.parse_args()

    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n{'='*80}")
    print(f"COMPARING PROPHAGE-AMR METHODS: {args.sample_id}")
    print(f"{'='*80}\n")

    # Run all three methods
    results = {}

    print("Running Method 1: Coordinate Intersection...")
    results['method1'] = run_method1_coordinate(
        args.sample_id,
        args.prophage_coords,
        args.amr_results,
        output_dir,
        args.terminal_buffer
    )
    print(f"  → {results['method1']['gene_count']} genes ({results['method1']['status']})\n")

    print("Running Method 2: Direct AMRFinder Scan...")
    results['method2'] = run_method2_amrfinder(
        args.sample_id,
        args.vibrant_dir,
        args.amr_results,
        output_dir
    )
    print(f"  → {results['method2']['gene_count']} genes ({results['method2']['status']})\n")

    print("Running Method 3: RGI/CARD Scan...")
    results['method3'] = run_method3_rgi(
        args.sample_id,
        args.vibrant_dir,
        output_dir
    )
    print(f"  → {results['method3']['gene_count']} genes ({results['method3']['status']})\n")

    # Generate comparison report
    print("Generating comparison report...")
    comparison_txt = output_dir / f"{args.sample_id}_comparison_report.txt"
    comparison_tsv = output_dir / f"{args.sample_id}_comparison_summary.tsv"

    comparison = generate_comparison_report(args.sample_id, results, comparison_txt)
    write_tsv_summary(comparison_tsv, args.sample_id, results, comparison)

    print(f"\n{'='*80}")
    print("COMPARISON COMPLETE")
    print(f"{'='*80}")
    print(f"  Total genes: {comparison['total_genes']}")
    print(f"  Agreement: {comparison['agreement_pct']}%")
    print(f"\n  Reports:")
    print(f"    • {comparison_txt}")
    print(f"    • {comparison_tsv}")
    print(f"{'='*80}\n")


if __name__ == '__main__':
    main()
