#!/usr/bin/env python3
"""
Create Master Results Table
============================

Combines all COMPASS pipeline outputs into a single comprehensive table
for easy analysis, visualization, and publication.

Integrates:
- Assembly stats (QUAST)
- Quality control (BUSCO)
- Typing (MLST, SISTR serotyping)
- Prophages (VIBRANT)
- Plasmids (MOB-suite)
- AMR genes (AMRFinder)
- Metadata (if available)

Outputs single TSV with one row per sample, all results in columns.

Usage:
    python3 create_master_results_table.py \\
        --results-dir results/ \\
        --output master_results_table.tsv

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

def parse_quast_reports(results_dir):
    """
    Parse QUAST assembly statistics

    Returns: dict[sample_id] = {n50, total_length, contigs, gc_pct}
    """
    quast_data = {}
    quast_path = Path(results_dir) / 'quast'

    if not quast_path.exists():
        print("Warning: QUAST results not found", file=sys.stderr)
        return quast_data

    for sample_dir in quast_path.iterdir():
        if not sample_dir.is_dir():
            continue

        sample_id = sample_dir.name
        report_file = sample_dir / 'report.tsv'

        if not report_file.exists():
            continue

        try:
            # Read QUAST report (two-column format)
            df = pd.read_csv(report_file, sep='\t', header=None, names=['metric', 'value'])
            metrics = dict(zip(df['metric'], df['value']))

            quast_data[sample_id] = {
                'n50': metrics.get('N50', 0),
                'total_length': metrics.get('Total length', 0),
                'contigs': metrics.get('# contigs', 0),
                'gc_pct': metrics.get('GC (%)', 0.0)
            }
        except Exception as e:
            print(f"Warning: Could not parse QUAST for {sample_id}: {e}", file=sys.stderr)

    return quast_data

def parse_busco_summaries(results_dir):
    """
    Parse BUSCO quality assessment

    Returns: dict[sample_id] = {complete, fragmented, missing, duplicated}
    """
    busco_data = {}
    busco_path = Path(results_dir) / 'busco'

    if not busco_path.exists():
        print("Warning: BUSCO results not found", file=sys.stderr)
        return busco_data

    for sample_dir in busco_path.iterdir():
        if not sample_dir.is_dir():
            continue

        sample_id = sample_dir.name

        # Find short_summary file
        summary_files = list(sample_dir.glob('**/short_summary*.txt'))

        if not summary_files:
            continue

        try:
            with open(summary_files[0], 'r') as f:
                content = f.read()

            # Parse percentages using regex
            complete = re.search(r'C:(\d+\.?\d*)%', content)
            fragmented = re.search(r'F:(\d+\.?\d*)%', content)
            missing = re.search(r'M:(\d+\.?\d*)%', content)
            duplicated = re.search(r'D:(\d+\.?\d*)%', content)

            busco_data[sample_id] = {
                'busco_complete_pct': float(complete.group(1)) if complete else 0.0,
                'busco_fragmented_pct': float(fragmented.group(1)) if fragmented else 0.0,
                'busco_missing_pct': float(missing.group(1)) if missing else 0.0,
                'busco_duplicated_pct': float(duplicated.group(1)) if duplicated else 0.0
            }
        except Exception as e:
            print(f"Warning: Could not parse BUSCO for {sample_id}: {e}", file=sys.stderr)

    return busco_data

def parse_mlst_results(results_dir):
    """
    Parse MLST typing results

    Returns: dict[sample_id] = {scheme, st}
    """
    mlst_data = {}
    mlst_path = Path(results_dir) / 'mlst'

    if not mlst_path.exists():
        print("Warning: MLST results not found", file=sys.stderr)
        return mlst_data

    for mlst_file in mlst_path.glob('*_mlst.tsv'):
        sample_id = mlst_file.stem.replace('_mlst', '')

        try:
            df = pd.read_csv(mlst_file, sep='\t')

            if len(df) > 0:
                mlst_data[sample_id] = {
                    'mlst_scheme': df.iloc[0].get('SCHEME', df.iloc[0][1] if len(df.columns) > 1 else '-'),
                    'mlst_st': df.iloc[0].get('ST', df.iloc[0][2] if len(df.columns) > 2 else '-')
                }
        except Exception as e:
            print(f"Warning: Could not parse MLST for {sample_id}: {e}", file=sys.stderr)

    return mlst_data

def parse_sistr_results(results_dir):
    """
    Parse SISTR serotyping results (Salmonella)

    Returns: dict[sample_id] = {serovar, serogroup, h1, h2, o_antigen}
    """
    sistr_data = {}
    sistr_path = Path(results_dir) / 'sistr'

    if not sistr_path.exists():
        return sistr_data

    for sistr_file in sistr_path.glob('*/*_sistr.tsv'):
        sample_id = sistr_file.stem.replace('_sistr', '')

        try:
            df = pd.read_csv(sistr_file, sep='\t')

            if len(df) > 0:
                row = df.iloc[0]
                sistr_data[sample_id] = {
                    'serovar': row.get('serovar', '-'),
                    'serogroup': row.get('serogroup', '-'),
                    'h1': row.get('h1', '-'),
                    'h2': row.get('h2', '-'),
                    'o_antigen': row.get('o_antigen', '-')
                }
        except Exception as e:
            print(f"Warning: Could not parse SISTR for {sample_id}: {e}", file=sys.stderr)

    return sistr_data

def count_vibrant_prophages(results_dir):
    """
    Count prophages from VIBRANT results

    Returns: dict[sample_id] = prophage_count
    """
    prophage_counts = {}
    vibrant_path = Path(results_dir) / 'vibrant'

    if not vibrant_path.exists():
        print("Warning: VIBRANT results not found", file=sys.stderr)
        return prophage_counts

    for sample_dir in vibrant_path.iterdir():
        if not sample_dir.is_dir():
            continue

        sample_id = sample_dir.name.replace('_vibrant', '')

        # Count from results file
        phages_dir = list(sample_dir.glob('VIBRANT_phages_*'))

        if phages_dir:
            results_file = list(phages_dir[0].glob('VIBRANT_results_*.txt'))
            if results_file:
                try:
                    with open(results_file[0], 'r') as f:
                        count = sum(1 for line in f if line.strip() and not line.startswith('#'))
                    prophage_counts[sample_id] = count
                except:
                    prophage_counts[sample_id] = 0

    return prophage_counts

def count_mobsuite_plasmids(results_dir):
    """
    Count plasmids from MOB-suite results

    Returns: dict[sample_id] = plasmid_count
    """
    plasmid_counts = {}
    mobsuite_path = Path(results_dir) / 'mobsuite'

    if not mobsuite_path.exists():
        print("Warning: MOB-suite results not found", file=sys.stderr)
        return plasmid_counts

    for sample_dir in mobsuite_path.iterdir():
        if not sample_dir.is_dir():
            continue

        sample_id = sample_dir.name.replace('_mobsuite', '')

        # Count plasmid FASTA files
        plasmid_files = list(sample_dir.glob('plasmid_*.fasta'))
        plasmid_counts[sample_id] = len(plasmid_files)

    return plasmid_counts

def count_amr_genes(results_dir):
    """
    Count AMR genes from AMRFinder results

    Returns: dict[sample_id] = {amr_count, amr_classes}
    """
    amr_data = {}
    amrfinder_path = Path(results_dir) / 'amrfinder'

    if not amrfinder_path.exists():
        print("Warning: AMRFinder results not found", file=sys.stderr)
        return amr_data

    # AMRFinder files are directly in amrfinder/ directory, not in subdirs
    for amr_file in amrfinder_path.glob('*_amr.tsv'):
        sample_id = amr_file.stem.replace('_amr', '')

        try:
            df = pd.read_csv(amr_file, sep='\t')

            amr_classes = df.get('Class', df.get('Subclass', [])).dropna().unique()
            amr_classes_str = ','.join(sorted(amr_classes)) if len(amr_classes) > 0 else 'None'

            amr_data[sample_id] = {
                'amr_gene_count': len(df),
                'amr_classes': amr_classes_str
            }
        except Exception as e:
            print(f"Warning: Could not parse AMRFinder for {sample_id}: {e}", file=sys.stderr)

    return amr_data

def create_master_table(results_dir):
    """
    Combine all results into master table

    Returns: pandas DataFrame
    """
    print("Parsing QUAST assembly statistics...")
    quast_data = parse_quast_reports(results_dir)

    print("Parsing BUSCO quality assessments...")
    busco_data = parse_busco_summaries(results_dir)

    print("Parsing MLST typing results...")
    mlst_data = parse_mlst_results(results_dir)

    print("Parsing SISTR serotyping results...")
    sistr_data = parse_sistr_results(results_dir)

    print("Counting VIBRANT prophages...")
    prophage_counts = count_vibrant_prophages(results_dir)

    print("Counting MOB-suite plasmids...")
    plasmid_counts = count_mobsuite_plasmids(results_dir)

    print("Parsing AMRFinder results...")
    amr_data = count_amr_genes(results_dir)

    # Get all unique sample IDs
    all_samples = set()
    all_samples.update(quast_data.keys())
    all_samples.update(busco_data.keys())
    all_samples.update(mlst_data.keys())
    all_samples.update(sistr_data.keys())
    all_samples.update(prophage_counts.keys())
    all_samples.update(plasmid_counts.keys())
    all_samples.update(amr_data.keys())

    print(f"\nFound {len(all_samples)} unique samples")

    # Build master table
    rows = []

    for sample_id in sorted(all_samples):
        row = {'sample_id': sample_id}

        # Assembly stats
        if sample_id in quast_data:
            row.update(quast_data[sample_id])
        else:
            row.update({'n50': 0, 'total_length': 0, 'contigs': 0, 'gc_pct': 0.0})

        # BUSCO
        if sample_id in busco_data:
            row.update(busco_data[sample_id])
        else:
            row.update({'busco_complete_pct': 0.0, 'busco_fragmented_pct': 0.0,
                       'busco_missing_pct': 0.0, 'busco_duplicated_pct': 0.0})

        # MLST
        if sample_id in mlst_data:
            row.update(mlst_data[sample_id])
        else:
            row.update({'mlst_scheme': '-', 'mlst_st': '-'})

        # SISTR
        if sample_id in sistr_data:
            row.update(sistr_data[sample_id])
        else:
            row.update({'serovar': '-', 'serogroup': '-', 'h1': '-', 'h2': '-', 'o_antigen': '-'})

        # Prophages
        row['prophage_count'] = prophage_counts.get(sample_id, 0)

        # Plasmids
        row['plasmid_count'] = plasmid_counts.get(sample_id, 0)

        # AMR
        if sample_id in amr_data:
            row.update(amr_data[sample_id])
        else:
            row.update({'amr_gene_count': 0, 'amr_classes': 'None'})

        rows.append(row)

    return pd.DataFrame(rows)

def print_summary(df):
    """
    Print summary statistics of master table
    """
    print("\n" + "="*70)
    print("MASTER RESULTS TABLE SUMMARY")
    print("="*70)

    print(f"\nTotal samples: {len(df)}")
    print(f"Total columns: {len(df.columns)}")

    print("\n" + "-"*70)
    print("Assembly Quality:")
    print("-"*70)
    print(f"  Average N50: {df['n50'].mean():.0f} bp")
    print(f"  Average genome size: {df['total_length'].mean():.0f} bp")
    print(f"  Average contigs: {df['contigs'].mean():.1f}")
    print(f"  Average GC%: {df['gc_pct'].mean():.2f}%")

    if 'busco_complete_pct' in df.columns:
        print("\n" + "-"*70)
        print("BUSCO Completeness:")
        print("-"*70)
        print(f"  Average complete: {df['busco_complete_pct'].mean():.2f}%")
        print(f"  Average missing: {df['busco_missing_pct'].mean():.2f}%")

    if 'prophage_count' in df.columns:
        print("\n" + "-"*70)
        print("Mobile Elements:")
        print("-"*70)
        print(f"  Average prophages: {df['prophage_count'].mean():.2f}")
        print(f"  Average plasmids: {df['plasmid_count'].mean():.2f}")
        print(f"  Average AMR genes: {df['amr_gene_count'].mean():.2f}")

    print("\n" + "="*70)

def main():
    parser = argparse.ArgumentParser(
        description='Create master results table combining all COMPASS outputs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage
    python3 create_master_results_table.py \\
        --results-dir results/ \\
        --output master_results_table.tsv

    # With custom output
    python3 create_master_results_table.py \\
        --results-dir /path/to/compass/results/ \\
        --output /path/to/my_master_table.tsv

Output columns:
    - sample_id: Sample identifier
    - n50: Assembly N50 (bp)
    - total_length: Genome size (bp)
    - contigs: Number of contigs
    - gc_pct: GC percentage
    - busco_complete_pct: BUSCO complete (%)
    - busco_fragmented_pct: BUSCO fragmented (%)
    - busco_missing_pct: BUSCO missing (%)
    - busco_duplicated_pct: BUSCO duplicated (%)
    - mlst_scheme: MLST scheme
    - mlst_st: MLST sequence type
    - serovar: Salmonella serovar (if applicable)
    - serogroup: Salmonella serogroup (if applicable)
    - h1, h2, o_antigen: Salmonella antigens (if applicable)
    - prophage_count: Number of prophages
    - plasmid_count: Number of plasmids
    - amr_gene_count: Number of AMR genes
    - amr_classes: AMR resistance classes (comma-separated)
        """
    )

    parser.add_argument('--results-dir', required=True,
                        help='COMPASS pipeline results directory')
    parser.add_argument('--output', default='master_results_table.tsv',
                        help='Output TSV file (default: master_results_table.tsv)')

    args = parser.parse_args()

    # Validate input
    if not os.path.isdir(args.results_dir):
        print(f"Error: Results directory not found: {args.results_dir}", file=sys.stderr)
        sys.exit(1)

    print("Creating master results table...")
    master_df = create_master_table(args.results_dir)

    if master_df.empty:
        print("Error: No results found to compile", file=sys.stderr)
        sys.exit(1)

    # Write output
    master_df.to_csv(args.output, sep='\t', index=False)
    print(f"\nMaster table written to: {args.output}")
    print(f"Rows: {len(master_df)}")
    print(f"Columns: {len(master_df.columns)}")

    # Print summary
    print_summary(master_df)

if __name__ == '__main__':
    main()
