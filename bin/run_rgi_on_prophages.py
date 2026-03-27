#!/usr/bin/env python3
"""
Run RGI (CARD) on Prophage Sequences - Pinto et al. (2024) Approach

This implements the method from Pinto et al., Genes 16(5):656:
1. Extract prophage sequences identified by VIBRANT
2. Run RGI (Resistance Gene Identifier) on prophage sequences
3. Compare to whole-genome AMRFinder results

This answers: Do prophage sequences contain AMR genes when scanned
with the CARD database (as in the published paper)?

Usage:
    # Single sample
    python3 run_rgi_on_prophages.py <vibrant_dir> <sample_id> <output_file>

    # Returns TSV with: sample, gene, class, contig, mechanism
"""

import sys
import csv
import subprocess
import tempfile
import json
from pathlib import Path
from collections import defaultdict


def extract_prophage_sequences(vibrant_dir, sample_id):
    """
    Extract prophage sequences from VIBRANT output

    VIBRANT creates {sample_id}_phages.fna with all identified prophage sequences

    Returns: Path to prophage FASTA file (or None if not found)
    """
    # Try multiple possible locations for prophage sequences
    possible_paths = [
        vibrant_dir / f"{sample_id}_phages.fna",
        vibrant_dir / f"VIBRANT_{sample_id}" / f"{sample_id}_phages.fna",
        vibrant_dir / f"VIBRANT_{sample_id}_contigs" / f"{sample_id}_contigs_phages.fna",
    ]

    for phages_fasta in possible_paths:
        if phages_fasta.exists():
            # Check if file has content
            with open(phages_fasta) as f:
                content = f.read(100)
                if content.startswith('>'):
                    return phages_fasta

    return None


def run_rgi_on_fasta(fasta_file, output_prefix):
    """
    Run RGI (Resistance Gene Identifier) on a FASTA file

    Uses CARD database for AMR detection (as in Pinto et al. paper)

    Returns: Path to RGI output JSON (or None if failed)
    """
    output_json = f"{output_prefix}.json"
    output_txt = f"{output_prefix}.txt"

    cmd = [
        'rgi', 'main',
        '--input_sequence', str(fasta_file),
        '--output_file', str(output_prefix),
        '--input_type', 'contig',
        '--alignment_tool', 'BLAST',
        '--clean'
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        if result.returncode == 0 and Path(output_json).exists():
            return output_json
        else:
            # RGI might not be installed, return empty results
            return None

    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        return None


def parse_rgi_results(rgi_json):
    """
    Parse RGI output JSON

    Returns: list of dicts with {gene, class, mechanism, contig}
    """
    amr_genes = []

    if not rgi_json or not Path(rgi_json).exists():
        return amr_genes

    try:
        with open(rgi_json) as f:
            data = json.load(f)

        for gene_id, gene_data in data.items():
            if isinstance(gene_data, dict):
                amr_genes.append({
                    'gene': gene_data.get('Best_Hit_ARO', 'Unknown'),
                    'class': gene_data.get('Drug Class', ''),
                    'mechanism': gene_data.get('Resistance Mechanism', ''),
                    'contig': gene_data.get('ORF_ID', '').split()[0],
                    'identity': gene_data.get('Best_Identities', ''),
                    'model_type': gene_data.get('Model_type', '')
                })

    except Exception as e:
        print(f"    ⚠️  Could not parse RGI results: {e}", file=sys.stderr)

    return amr_genes


def analyze_sample(vibrant_dir, sample_id, output_file):
    """
    Run RGI on prophage sequences for a single sample

    Returns: dict with results or None if failed
    """
    # Find prophage sequences
    phages_fasta = extract_prophage_sequences(vibrant_dir, sample_id)

    if not phages_fasta:
        return {
            'sample': sample_id,
            'status': 'no_prophage_sequences',
            'prophage_amr_count': 0,
            'genes': []
        }

    # Run RGI on prophage sequences
    with tempfile.TemporaryDirectory() as tmpdir:
        output_prefix = Path(tmpdir) / f"{sample_id}_prophage_rgi"
        rgi_json = run_rgi_on_fasta(phages_fasta, output_prefix)

        if not rgi_json:
            return {
                'sample': sample_id,
                'status': 'rgi_failed',
                'prophage_amr_count': 0,
                'genes': []
            }

        # Parse results
        amr_genes = parse_rgi_results(rgi_json)

        # Write output
        write_output(output_file, sample_id, amr_genes)

        return {
            'sample': sample_id,
            'status': 'success',
            'prophage_amr_count': len(amr_genes),
            'genes': amr_genes
        }


def write_output(output_file, sample_id, amr_genes):
    """Write results to TSV file"""
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\t')

        # Header
        writer.writerow([
            'sample_id', 'gene', 'drug_class', 'mechanism',
            'contig', 'identity', 'model_type'
        ])

        # Data rows
        for gene in amr_genes:
            writer.writerow([
                sample_id,
                gene['gene'],
                gene['class'],
                gene['mechanism'],
                gene['contig'],
                gene.get('identity', ''),
                gene.get('model_type', '')
            ])

        # If no genes, write a row indicating no AMR found
        if not amr_genes:
            writer.writerow([sample_id, 'None', '', '', '', '', ''])


def main():
    if len(sys.argv) < 4:
        print("Usage: python3 run_rgi_on_prophages.py <vibrant_dir> <sample_id> <output_file>")
        sys.exit(1)

    vibrant_dir = Path(sys.argv[1])
    sample_id = sys.argv[2]
    output_file = sys.argv[3]

    if not vibrant_dir.exists():
        print(f"Error: VIBRANT directory not found: {vibrant_dir}", file=sys.stderr)
        sys.exit(1)

    # Analyze sample
    result = analyze_sample(vibrant_dir, sample_id, output_file)

    # Print status
    if result['status'] == 'success':
        print(f"✓ {sample_id}: {result['prophage_amr_count']} AMR genes in prophage (RGI/CARD)")
    elif result['status'] == 'no_prophage_sequences':
        print(f"⚠️  {sample_id}: No prophage sequences found")
    else:
        print(f"⚠️  {sample_id}: RGI analysis failed")


if __name__ == '__main__':
    main()
