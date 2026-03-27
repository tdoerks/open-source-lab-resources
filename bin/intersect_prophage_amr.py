#!/usr/bin/env python3
"""
Intersect Prophage and AMR Gene Coordinates

This script identifies antimicrobial resistance (AMR) genes that are encoded within
prophage regions, excluding terminal regions that may represent host contamination.

Inspired by methodology from:
Genes 2024, 16(5), 656; https://doi.org/10.3390/genes16050656

Author: COMPASS Pipeline
Date: 2026-03-27
"""

import argparse
import pandas as pd
from pathlib import Path
import sys
from collections import defaultdict

def parse_args():
    parser = argparse.ArgumentParser(
        description='Identify AMR genes within prophage regions'
    )
    parser.add_argument(
        '--prophage_coords',
        required=True,
        help='VIBRANT integrated prophage coordinates TSV'
    )
    parser.add_argument(
        '--amr_results',
        required=True,
        help='AMRFinder results TSV'
    )
    parser.add_argument(
        '--output',
        default='prophage_amr_intersect.tsv',
        help='Output file for prophage-encoded AMR genes'
    )
    parser.add_argument(
        '--terminal_buffer',
        type=int,
        default=5000,
        help='Exclude AMR genes within N bp of prophage termini (default: 5000)'
    )
    parser.add_argument(
        '--sample_name',
        default='sample',
        help='Sample name for reporting'
    )
    return parser.parse_args()


def load_prophage_coords(prophage_file):
    """
    Load VIBRANT prophage coordinates

    Expected columns:
    - scaffold
    - fragment
    - nucleotide start
    - nucleotide stop
    - nucleotide length
    """
    try:
        df = pd.read_csv(prophage_file, sep='\t')

        # Check for required columns
        required_cols = ['scaffold', 'nucleotide start', 'nucleotide stop']

        # Handle different possible column names
        col_mapping = {}
        for col in df.columns:
            col_lower = col.lower().strip()
            if 'scaffold' in col_lower or 'contig' in col_lower:
                col_mapping['scaffold'] = col
            elif 'nucleotide start' in col_lower or 'start' in col_lower:
                col_mapping['nucleotide start'] = col
            elif 'nucleotide stop' in col_lower or 'stop' in col_lower or 'end' in col_lower:
                col_mapping['nucleotide stop'] = col
            elif 'fragment' in col_lower:
                col_mapping['fragment'] = col

        # Rename columns
        df = df.rename(columns=col_mapping)

        # Verify we have the essential columns
        if 'scaffold' not in df.columns or 'nucleotide start' not in df.columns or 'nucleotide stop' not in df.columns:
            print(f"ERROR: Could not find required columns in {prophage_file}", file=sys.stderr)
            print(f"Available columns: {df.columns.tolist()}", file=sys.stderr)
            return pd.DataFrame()

        # Add fragment column if missing
        if 'fragment' not in df.columns:
            df['fragment'] = [f"prophage_{i+1}" for i in range(len(df))]

        print(f"✓ Loaded {len(df)} prophage regions from {prophage_file}")
        return df

    except FileNotFoundError:
        print(f"WARNING: Prophage coordinates file not found: {prophage_file}", file=sys.stderr)
        return pd.DataFrame()
    except Exception as e:
        print(f"ERROR loading prophage coordinates: {e}", file=sys.stderr)
        return pd.DataFrame()


def load_amr_results(amr_file):
    """
    Load AMRFinder results

    Expected columns:
    - Contig id
    - Start
    - Stop
    - Gene symbol
    - Class
    - Subclass
    """
    try:
        df = pd.read_csv(amr_file, sep='\t')

        # Check for required columns
        required_cols = ['Contig id', 'Start', 'Stop', 'Gene symbol']

        # Verify columns exist
        missing = [col for col in required_cols if col not in df.columns]
        if missing:
            print(f"ERROR: Missing columns in AMR file: {missing}", file=sys.stderr)
            print(f"Available columns: {df.columns.tolist()}", file=sys.stderr)
            return pd.DataFrame()

        print(f"✓ Loaded {len(df)} AMR genes from {amr_file}")
        return df

    except FileNotFoundError:
        print(f"WARNING: AMR results file not found: {amr_file}", file=sys.stderr)
        return pd.DataFrame()
    except Exception as e:
        print(f"ERROR loading AMR results: {e}", file=sys.stderr)
        return pd.DataFrame()


def intersect_coordinates(prophage_df, amr_df, terminal_buffer=5000):
    """
    Find AMR genes that overlap with prophage regions

    Parameters:
    - prophage_df: DataFrame with prophage coordinates
    - amr_df: DataFrame with AMR gene coordinates
    - terminal_buffer: Exclude genes within N bp of prophage termini (default: 5000)

    Returns:
    - DataFrame with AMR genes found in prophage regions
    """
    if prophage_df.empty or amr_df.empty:
        print("⚠️  No prophage regions or AMR genes to intersect")
        return pd.DataFrame()

    intersections = []

    for _, prophage in prophage_df.iterrows():
        scaffold = prophage['scaffold']
        phage_start = prophage['nucleotide start']
        phage_stop = prophage['nucleotide stop']
        fragment = prophage.get('fragment', 'unknown')

        # Find AMR genes on the same contig
        contig_amr = amr_df[amr_df['Contig id'] == scaffold]

        for _, amr in contig_amr.iterrows():
            amr_start = amr['Start']
            amr_stop = amr['Stop']

            # Check if AMR gene overlaps with prophage region
            if (amr_start >= phage_start and amr_start <= phage_stop) or \
               (amr_stop >= phage_start and amr_stop <= phage_stop) or \
               (amr_start <= phage_start and amr_stop >= phage_stop):

                # Calculate distance from prophage termini
                dist_from_start = amr_start - phage_start
                dist_from_end = phage_stop - amr_stop

                # Determine location category
                if dist_from_start < terminal_buffer:
                    location = "terminal_start"
                    exclude = True
                elif dist_from_end < terminal_buffer:
                    location = "terminal_end"
                    exclude = True
                else:
                    location = "internal"
                    exclude = False

                # Record the intersection
                intersections.append({
                    'scaffold': scaffold,
                    'prophage_fragment': fragment,
                    'prophage_start': phage_start,
                    'prophage_stop': phage_stop,
                    'prophage_length': phage_stop - phage_start,
                    'amr_gene': amr['Gene symbol'],
                    'amr_start': amr_start,
                    'amr_stop': amr_stop,
                    'amr_class': amr.get('Class', 'NA'),
                    'amr_subclass': amr.get('Subclass', 'NA'),
                    'element_type': amr.get('Element type', 'NA'),
                    'sequence_name': amr.get('Sequence name', 'NA'),
                    'location_in_prophage': location,
                    'dist_from_start': dist_from_start,
                    'dist_from_end': dist_from_end,
                    'excluded': exclude,
                    'exclusion_reason': 'terminal_region' if exclude else 'retained'
                })

    if not intersections:
        print("ℹ️  No AMR genes found within prophage regions")
        return pd.DataFrame()

    result_df = pd.DataFrame(intersections)

    # Summary statistics
    total = len(result_df)
    retained = len(result_df[~result_df['excluded']])
    excluded = len(result_df[result_df['excluded']])

    print(f"\n📊 Prophage-AMR Intersection Results:")
    print(f"  Total AMR genes in prophage regions: {total}")
    print(f"  Retained (internal): {retained}")
    print(f"  Excluded (terminal <{terminal_buffer}bp): {excluded}")

    if retained > 0:
        print(f"\n⚠️  PROPHAGE-ENCODED AMR GENES DETECTED:")
        for _, row in result_df[~row['excluded']].iterrows():
            print(f"    - {row['amr_gene']} ({row['amr_class']}) in {row['prophage_fragment']}")

    return result_df


def write_results(result_df, output_file, sample_name):
    """Write intersection results to file"""

    if result_df.empty:
        # Write empty file with headers
        with open(output_file, 'w') as f:
            f.write("# No prophage-encoded AMR genes found\n")
            f.write("sample\tmessage\n")
            f.write(f"{sample_name}\tNo intersections found\n")
        print(f"\n✓ Results written to {output_file}")
        return

    # Add sample name column
    result_df.insert(0, 'sample', sample_name)

    # Write full results
    result_df.to_csv(output_file, sep='\t', index=False)

    # Write summary file
    summary_file = output_file.replace('.tsv', '_summary.txt')
    with open(summary_file, 'w') as f:
        f.write(f"Prophage-AMR Intersection Summary\n")
        f.write(f"Sample: {sample_name}\n")
        f.write(f"=" * 60 + "\n\n")

        total = len(result_df)
        retained = len(result_df[~result_df['excluded']])
        excluded = len(result_df[result_df['excluded']])

        f.write(f"Total AMR genes in prophage regions: {total}\n")
        f.write(f"Retained (internal): {retained}\n")
        f.write(f"Excluded (terminal): {excluded}\n\n")

        if retained > 0:
            f.write("PROPHAGE-ENCODED AMR GENES (RETAINED):\n")
            f.write("-" * 60 + "\n")
            for _, row in result_df[~row['excluded']].iterrows():
                f.write(f"\nGene: {row['amr_gene']}\n")
                f.write(f"  Class: {row['amr_class']}\n")
                f.write(f"  Subclass: {row['amr_subclass']}\n")
                f.write(f"  Prophage: {row['prophage_fragment']}\n")
                f.write(f"  Position: {row['amr_start']}-{row['amr_stop']}\n")
                f.write(f"  Distance from start: {row['dist_from_start']} bp\n")
                f.write(f"  Distance from end: {row['dist_from_end']} bp\n")

    print(f"✓ Results written to {output_file}")
    print(f"✓ Summary written to {summary_file}")


def main():
    args = parse_args()

    print("=" * 60)
    print("Prophage-AMR Intersection Analysis")
    print("=" * 60)
    print(f"Sample: {args.sample_name}")
    print(f"Terminal buffer: {args.terminal_buffer} bp")
    print()

    # Load data
    prophage_df = load_prophage_coords(args.prophage_coords)
    amr_df = load_amr_results(args.amr_results)

    # Perform intersection
    result_df = intersect_coordinates(prophage_df, amr_df, args.terminal_buffer)

    # Write results
    write_results(result_df, args.output, args.sample_name)

    print("\n✓ Analysis complete!")


if __name__ == '__main__':
    main()
