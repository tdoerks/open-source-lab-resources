#!/usr/bin/env python3
"""
Analyze prophage integration sites from VIBRANT results and assemblies.

Identifies where prophages integrate into bacterial genomes:
- tRNA genes (common integration sites)
- Specific genes (e.g., recombinases, integrases)
- Intergenic regions
- Flanking sequences and direct repeats

Critical for understanding prophage mobility and host-prophage interactions.

Usage:
    python3 analyze_prophage_integration_sites.py \\
        --vibrant results/vibrant/ \\
        --assemblies results/assembly/ \\
        --output prophage_integration_sites.tsv \\
        --flanking-length 1000
"""

import argparse
import pandas as pd
import sys
from pathlib import Path
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from collections import defaultdict
import re

def parse_vibrant_results(vibrant_dir):
    """
    Parse VIBRANT prophage predictions.

    Args:
        vibrant_dir: Path to VIBRANT results directory

    Returns:
        Dictionary mapping sample IDs to prophage predictions
    """
    vibrant_path = Path(vibrant_dir)

    # Find all VIBRANT result directories
    sample_dirs = [d for d in vibrant_path.iterdir() if d.is_dir()]

    prophage_data = defaultdict(list)

    for sample_dir in sample_dirs:
        sample_id = sample_dir.name

        # Look for integrated prophage file
        integrated_file = sample_dir / f"{sample_id}_integrated_prophage_coordinates.tsv"

        if not integrated_file.exists():
            continue

        try:
            # Read prophage coordinates
            df = pd.read_csv(integrated_file, sep='\\t')

            for _, row in df.iterrows():
                prophage_data[sample_id].append({
                    'fragment': row.get('fragment', row.get('scaffold', 'unknown')),
                    'start': int(row.get('start', row.get('prophage start', 0))),
                    'end': int(row.get('end', row.get('prophage end', 0))),
                    'length': int(row.get('length', row.get('prophage length', 0))),
                    'quality': row.get('quality', 'unknown')
                })

        except Exception as e:
            print(f"WARNING: Could not parse VIBRANT results for {sample_id}: {e}", file=sys.stderr)
            continue

    print(f"Found prophages in {len(prophage_data)} samples")
    total_prophages = sum(len(v) for v in prophage_data.values())
    print(f"Total prophages detected: {total_prophages}")

    return prophage_data

def load_assembly(assembly_file):
    """
    Load assembly FASTA file.

    Args:
        assembly_file: Path to assembly FASTA

    Returns:
        Dictionary of SeqRecord objects indexed by contig name
    """
    try:
        contigs = {}
        for record in SeqIO.parse(assembly_file, "fasta"):
            contigs[record.id] = record
        return contigs
    except Exception as e:
        print(f"ERROR: Could not load assembly {assembly_file}: {e}", file=sys.stderr)
        return {}

def extract_flanking_sequence(contig, start, end, flank_len=1000):
    """
    Extract flanking sequences around prophage integration site.

    Args:
        contig: SeqRecord object
        start: Prophage start position
        end: Prophage end position
        flank_len: Length of flanking sequence to extract

    Returns:
        Dictionary with upstream and downstream flanking sequences
    """
    contig_len = len(contig.seq)

    # Extract upstream flank
    upstream_start = max(0, start - flank_len)
    upstream_seq = str(contig.seq[upstream_start:start])

    # Extract downstream flank
    downstream_end = min(contig_len, end + flank_len)
    downstream_seq = str(contig.seq[end:downstream_end])

    return {
        'upstream_seq': upstream_seq,
        'downstream_seq': downstream_seq,
        'upstream_len': len(upstream_seq),
        'downstream_len': len(downstream_seq)
    }

def detect_trna_motif(sequence):
    """
    Detect potential tRNA gene motifs in sequence.

    tRNA genes often contain characteristic sequences:
    - TΨC loop: GTΨCRA (Ψ = pseudouridine, typically T)
    - D loop: various patterns
    - Acceptor stem: typically ends in CCA

    This is a simplified check for tRNA-like patterns.
    """
    sequence_upper = sequence.upper()

    # Look for tRNA-like patterns
    trna_patterns = [
        r'GG[AT]{2}CG[AT]{2}',  # D-loop like pattern
        r'GT[TC][CT]G[AG][AT]', # TΨC loop pattern
        r'CCA$',                 # 3' CCA tail
        r'GCC[AG]',              # Common acceptor stem
    ]

    matches = []
    for pattern in trna_patterns:
        if re.search(pattern, sequence_upper):
            matches.append(pattern)

    return len(matches) > 0, matches

def detect_direct_repeats(upstream, downstream, min_repeat=10, max_repeat=50):
    """
    Detect direct repeats at prophage boundaries.

    Direct repeats are common at integration sites.

    Args:
        upstream: Upstream flanking sequence
        downstream: Downstream flanking sequence
        min_repeat: Minimum repeat length
        max_repeat: Maximum repeat length

    Returns:
        Longest direct repeat found, or None
    """
    best_repeat = None
    best_length = 0

    # Check different repeat lengths
    for repeat_len in range(min_repeat, min(max_repeat, len(upstream), len(downstream))):
        # Get end of upstream and start of downstream
        upstream_end = upstream[-repeat_len:]
        downstream_start = downstream[:repeat_len]

        # Check for match
        if upstream_end.upper() == downstream_start.upper():
            if repeat_len > best_length:
                best_repeat = upstream_end
                best_length = repeat_len

    return best_repeat

def analyze_integration_sites(prophage_data, assembly_dir, flank_len=1000):
    """
    Analyze integration sites for all prophages.

    Args:
        prophage_data: Dictionary of prophage predictions
        assembly_dir: Directory containing assembly FASTA files
        flank_len: Length of flanking sequences to extract

    Returns:
        List of integration site analyses
    """
    assembly_path = Path(assembly_dir)
    integration_sites = []

    for sample_id, prophages in prophage_data.items():
        # Find assembly file
        assembly_files = list(assembly_path.glob(f"{sample_id}*.fasta")) + \
                        list(assembly_path.glob(f"{sample_id}*.fa")) + \
                        list(assembly_path.glob(f"{sample_id}*.fna"))

        if not assembly_files:
            print(f"WARNING: No assembly found for {sample_id}", file=sys.stderr)
            continue

        assembly_file = assembly_files[0]
        contigs = load_assembly(assembly_file)

        if not contigs:
            continue

        for i, prophage in enumerate(prophages):
            fragment = prophage['fragment']

            # Find matching contig
            if fragment not in contigs:
                # Try to find contig with partial match
                matching_contigs = [c for c in contigs.keys() if fragment in c or c in fragment]
                if matching_contigs:
                    fragment = matching_contigs[0]
                else:
                    print(f"WARNING: Contig {fragment} not found in {sample_id}", file=sys.stderr)
                    continue

            contig = contigs[fragment]

            # Extract flanking sequences
            flanks = extract_flanking_sequence(
                contig,
                prophage['start'],
                prophage['end'],
                flank_len
            )

            # Detect tRNA motifs
            upstream_trna, upstream_patterns = detect_trna_motif(flanks['upstream_seq'])
            downstream_trna, downstream_patterns = detect_trna_motif(flanks['downstream_seq'])

            has_trna = upstream_trna or downstream_trna
            trna_location = []
            if upstream_trna:
                trna_location.append('upstream')
            if downstream_trna:
                trna_location.append('downstream')

            # Detect direct repeats
            direct_repeat = detect_direct_repeats(
                flanks['upstream_seq'],
                flanks['downstream_seq']
            )

            # Classify integration site
            if has_trna:
                site_type = 'tRNA'
            elif direct_repeat:
                site_type = 'direct_repeat'
            else:
                site_type = 'intergenic'

            integration_sites.append({
                'sample': sample_id,
                'prophage_id': f"{sample_id}_prophage_{i+1}",
                'contig': fragment,
                'start': prophage['start'],
                'end': prophage['end'],
                'length': prophage['end'] - prophage['start'],
                'quality': prophage.get('quality', 'unknown'),
                'site_type': site_type,
                'trna_motif': 'Yes' if has_trna else 'No',
                'trna_location': ','.join(trna_location) if trna_location else '-',
                'direct_repeat_length': len(direct_repeat) if direct_repeat else 0,
                'direct_repeat_seq': direct_repeat if direct_repeat else '-',
                'upstream_flank_gc': round(calculate_gc(flanks['upstream_seq']), 2),
                'downstream_flank_gc': round(calculate_gc(flanks['downstream_seq']), 2)
            })

    return integration_sites

def calculate_gc(sequence):
    """Calculate GC content of sequence."""
    if not sequence:
        return 0
    sequence_upper = sequence.upper()
    gc_count = sequence_upper.count('G') + sequence_upper.count('C')
    return (gc_count / len(sequence)) * 100

def main():
    parser = argparse.ArgumentParser(
        description='Analyze prophage integration sites from VIBRANT and assemblies',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument(
        '--vibrant',
        required=True,
        help='Path to VIBRANT results directory'
    )

    parser.add_argument(
        '--assemblies',
        required=True,
        help='Path to directory containing assembly FASTA files'
    )

    parser.add_argument(
        '--output',
        required=True,
        help='Output TSV file for integration site analysis'
    )

    parser.add_argument(
        '--flanking-length',
        type=int,
        default=1000,
        help='Length of flanking sequences to analyze (default: 1000 bp)'
    )

    args = parser.parse_args()

    print("\\n" + "="*60)
    print("PROPHAGE INTEGRATION SITE ANALYSIS")
    print("="*60)

    # Parse VIBRANT prophage predictions
    print("\\n1. Parsing VIBRANT prophage predictions...")
    prophage_data = parse_vibrant_results(args.vibrant)

    if not prophage_data:
        print("\\nERROR: No prophages found in VIBRANT results")
        print("Make sure VIBRANT has been run and produced integrated prophage predictions")
        sys.exit(1)

    # Analyze integration sites
    print(f"\\n2. Analyzing integration sites (±{args.flanking_length} bp flanking sequences)...")
    integration_sites = analyze_integration_sites(
        prophage_data,
        args.assemblies,
        args.flanking_length
    )

    if not integration_sites:
        print("\\nERROR: No integration sites could be analyzed")
        print("Check that assembly files match VIBRANT sample IDs")
        sys.exit(1)

    # Create DataFrame and write output
    df = pd.DataFrame(integration_sites)
    df.to_csv(args.output, sep='\\t', index=False)

    print(f"\\n✅ Integration site analysis written to {args.output}")
    print(f"   Samples analyzed: {df['sample'].nunique()}")
    print(f"   Total prophages: {len(df)}")

    # Summary statistics
    print("\\n" + "="*60)
    print("INTEGRATION SITE SUMMARY")
    print("="*60)

    site_types = df['site_type'].value_counts()
    print("\\nIntegration site types:")
    for site_type, count in site_types.items():
        percentage = (count / len(df)) * 100
        print(f"  {site_type}: {count} ({percentage:.1f}%)")

    trna_count = (df['trna_motif'] == 'Yes').sum()
    print(f"\\ntRNA motifs detected: {trna_count} ({trna_count/len(df)*100:.1f}%)")

    repeat_count = (df['direct_repeat_length'] > 0).sum()
    print(f"Direct repeats found: {repeat_count} ({repeat_count/len(df)*100:.1f}%)")

    if repeat_count > 0:
        avg_repeat_len = df[df['direct_repeat_length'] > 0]['direct_repeat_length'].mean()
        print(f"Average repeat length: {avg_repeat_len:.1f} bp")

    print("="*60)
    print("\\n✅ Analysis complete!")

if __name__ == '__main__':
    main()
