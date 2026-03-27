#!/usr/bin/env python3
"""
Run AMRFinderPlus on Prophage Sequences

This script takes the most direct approach to finding AMR genes in prophages:
1. Extract prophage sequences identified by VIBRANT
2. Run AMRFinderPlus directly on those prophage sequences
3. Compare results to whole-genome AMRFinder results

This definitively answers: Do prophage sequences contain AMR genes when
scanned with AMR-specific detection tools?

Usage:
    # Single sample
    python3 run_amrfinder_on_prophages.py <results_dir> <sample_id>

    # All samples (will take a long time!)
    python3 run_amrfinder_on_prophages.py <results_dir>
"""

import sys
import csv
import subprocess
import tempfile
from pathlib import Path
from collections import Counter, defaultdict


def extract_prophage_sequences(vibrant_dir, sample_id):
    """
    Extract prophage sequences from VIBRANT output

    VIBRANT creates {sample_id}_phages.fna with all identified prophage sequences

    Returns: Path to prophage FASTA file (or None if not found)
    """
    phages_fasta = vibrant_dir / f"{sample_id}_phages.fna"

    if phages_fasta.exists():
        # Check if file has content
        with open(phages_fasta) as f:
            content = f.read(100)
            if content.startswith('>'):
                return phages_fasta

    return None


def run_amrfinder_on_fasta(fasta_file, output_file, organism='Salmonella'):
    """
    Run AMRFinderPlus on a FASTA file

    Returns: True if successful, False otherwise
    """
    cmd = [
        'amrfinder',
        '--nucleotide', str(fasta_file),
        '--organism', organism,
        '--plus',
        '--output', str(output_file)
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        if result.returncode == 0:
            return True
        else:
            print(f"    ⚠️  AMRFinder failed: {result.stderr[:200]}")
            return False

    except subprocess.TimeoutExpired:
        print(f"    ⚠️  AMRFinder timed out after 5 minutes")
        return False
    except FileNotFoundError:
        print(f"    ❌ AMRFinder not found - is it installed and in PATH?")
        return False
    except Exception as e:
        print(f"    ⚠️  Error running AMRFinder: {e}")
        return False


def parse_amrfinder_results(amr_file):
    """
    Parse AMRFinderPlus output

    Returns: list of dicts with {gene, class, subclass, contig, element_type}
    """
    amr_genes = []

    if not Path(amr_file).exists():
        return amr_genes

    try:
        with open(amr_file) as f:
            # Skip to data (file may have headers or be empty)
            lines = f.readlines()
            if not lines:
                return amr_genes

            # Find header line (starts with "Protein identifier" or "Contig id")
            header_idx = 0
            for i, line in enumerate(lines):
                if line.startswith('#') or line.startswith('Protein') or line.startswith('Contig'):
                    header_idx = i
                    break

            # Parse data rows
            for line in lines[header_idx + 1:]:
                if line.startswith('#') or not line.strip():
                    continue

                parts = line.strip().split('\t')
                if len(parts) < 11:
                    continue

                gene_symbol = parts[5]
                element_type = parts[8]

                # Only AMR genes
                if element_type != 'AMR' or gene_symbol == 'NA':
                    continue

                amr_genes.append({
                    'gene': gene_symbol,
                    'class': parts[10] if len(parts) > 10 else '',
                    'subclass': parts[11] if len(parts) > 11 else '',
                    'contig': parts[1],
                    'element_type': element_type,
                    'method': parts[7] if len(parts) > 7 else ''
                })

    except Exception as e:
        print(f"    ⚠️  Could not parse AMRFinder results: {e}")

    return amr_genes


def get_whole_genome_amr(amr_dir, sample_id):
    """Get AMR genes from whole-genome analysis"""
    amr_file = amr_dir / f"{sample_id}_amr.tsv"
    return parse_amrfinder_results(amr_file)


def analyze_sample(results_dir, sample_id, temp_dir):
    """
    Analyze a single sample:
    1. Extract prophage sequences
    2. Run AMRFinder on prophage sequences
    3. Compare to whole-genome results
    """
    results_dir = Path(results_dir)
    vibrant_dir = results_dir / "vibrant"
    amr_dir = results_dir / "amrfinder"

    print(f"\n{'='*80}")
    print(f"ANALYZING SAMPLE: {sample_id}")
    print(f"{'='*80}")

    # Step 1: Get whole-genome AMR results
    whole_genome_amr = get_whole_genome_amr(amr_dir, sample_id)
    print(f"\n  📊 Whole-genome AMRFinder: {len(whole_genome_amr)} AMR genes detected")

    if whole_genome_amr:
        gene_names = [g['gene'] for g in whole_genome_amr[:10]]
        print(f"     Sample genes: {', '.join(gene_names)}")
        if len(whole_genome_amr) > 10:
            print(f"     ... and {len(whole_genome_amr) - 10} more")

    # Step 2: Extract prophage sequences
    prophage_fasta = extract_prophage_sequences(vibrant_dir, sample_id)

    if not prophage_fasta:
        print(f"\n  ❌ No prophage sequences found (VIBRANT output missing)")
        return None

    # Count prophage regions
    with open(prophage_fasta) as f:
        prophage_count = sum(1 for line in f if line.startswith('>'))

    print(f"\n  🦠 VIBRANT identified {prophage_count} prophage/phage regions")
    print(f"     Prophage sequences: {prophage_fasta}")

    # Step 3: Run AMRFinder on prophage sequences
    prophage_amr_output = Path(temp_dir) / f"{sample_id}_prophage_amr.tsv"

    print(f"\n  🔍 Running AMRFinderPlus on prophage sequences...")
    print(f"     (This may take 1-2 minutes per sample)")

    success = run_amrfinder_on_fasta(prophage_fasta, prophage_amr_output)

    if not success:
        print(f"  ❌ AMRFinder failed on prophage sequences")
        return None

    # Step 4: Parse prophage AMR results
    prophage_amr = parse_amrfinder_results(prophage_amr_output)

    print(f"\n  ✅ AMRFinder on prophage DNA: {len(prophage_amr)} AMR genes detected")

    if prophage_amr:
        print(f"\n  🎯 AMR GENES FOUND IN PROPHAGES:")
        for gene in prophage_amr:
            print(f"     • {gene['gene']} ({gene['class']}) - {gene['method']}")
    else:
        print(f"\n  ❌ No AMR genes detected in prophage sequences")

    # Step 5: Compare results
    print(f"\n  📊 COMPARISON:")
    print(f"     Whole genome: {len(whole_genome_amr)} AMR genes")
    print(f"     Prophage DNA: {len(prophage_amr)} AMR genes")

    if len(prophage_amr) > 0:
        pct = (len(prophage_amr) / len(whole_genome_amr) * 100) if whole_genome_amr else 0
        print(f"     Prophage carries {pct:.1f}% of total AMR genes")

    # Return results
    return {
        'sample': sample_id,
        'whole_genome_amr_count': len(whole_genome_amr),
        'prophage_amr_count': len(prophage_amr),
        'prophage_count': prophage_count,
        'prophage_amr_genes': prophage_amr,
        'whole_genome_amr_genes': whole_genome_amr
    }


def export_results(all_results, output_csv):
    """Export results to CSV"""

    # Create detailed CSV with one row per prophage AMR gene
    detailed_rows = []

    for result in all_results:
        if result is None:
            continue

        sample = result['sample']

        if result['prophage_amr_genes']:
            # Add each prophage AMR gene
            for gene in result['prophage_amr_genes']:
                detailed_rows.append({
                    'sample': sample,
                    'gene': gene['gene'],
                    'class': gene['class'],
                    'subclass': gene['subclass'],
                    'method': gene['method'],
                    'prophage_contig': gene['contig'],
                    'whole_genome_amr_count': result['whole_genome_amr_count'],
                    'prophage_count': result['prophage_count']
                })
        else:
            # Sample with no prophage AMR genes
            detailed_rows.append({
                'sample': sample,
                'gene': 'None',
                'class': '',
                'subclass': '',
                'method': '',
                'prophage_contig': '',
                'whole_genome_amr_count': result['whole_genome_amr_count'],
                'prophage_count': result['prophage_count']
            })

    with open(output_csv, 'w', newline='') as f:
        fieldnames = ['sample', 'gene', 'class', 'subclass', 'method',
                     'prophage_contig', 'whole_genome_amr_count', 'prophage_count']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(detailed_rows)

    print(f"\n✅ Results exported to: {output_csv}")


def print_summary(all_results):
    """Print summary statistics"""

    # Filter out None results
    valid_results = [r for r in all_results if r is not None]

    if not valid_results:
        print("\n❌ No valid results to summarize")
        return

    print(f"\n{'='*80}")
    print(f"SUMMARY - AMR GENES IN PROPHAGES (DIRECT AMRFINDER SCAN)")
    print(f"{'='*80}")

    total_samples = len(valid_results)
    samples_with_prophage_amr = sum(1 for r in valid_results if r['prophage_amr_count'] > 0)
    total_prophage_amr_genes = sum(r['prophage_amr_count'] for r in valid_results)
    total_whole_genome_amr = sum(r['whole_genome_amr_count'] for r in valid_results)

    print(f"\n📊 Overall Statistics:")
    print(f"  Total samples analyzed: {total_samples}")
    print(f"  Samples with AMR genes in prophages: {samples_with_prophage_amr}")
    print(f"  Total AMR genes in prophages: {total_prophage_amr_genes}")
    print(f"  Total AMR genes in whole genomes: {total_whole_genome_amr}")

    if total_whole_genome_amr > 0:
        pct = (total_prophage_amr_genes / total_whole_genome_amr * 100)
        print(f"\n  🎯 {pct:.2f}% of AMR genes are located in prophage DNA")

    if total_prophage_amr_genes > 0:
        # Count genes
        gene_counts = Counter()
        class_counts = Counter()

        for result in valid_results:
            for gene in result['prophage_amr_genes']:
                gene_counts[gene['gene']] += 1
                class_counts[gene['class']] += 1

        print(f"\n🧬 Top AMR Genes in Prophages:")
        for gene, count in gene_counts.most_common(10):
            print(f"  {gene}: {count} occurrences")

        print(f"\n💊 Drug Classes in Prophages:")
        for drug_class, count in class_counts.most_common(10):
            print(f"  {drug_class}: {count} occurrences")

        print(f"\n✅ CONCLUSION:")
        print(f"   AMRFinderPlus detected {total_prophage_amr_genes} AMR genes when scanning")
        print(f"   prophage sequences directly in {samples_with_prophage_amr} samples.")
        print(f"   This definitively shows prophages DO carry resistance genes!")

    else:
        print(f"\n❌ CONCLUSION:")
        print(f"   AMRFinderPlus found NO AMR genes when scanning prophage DNA directly.")
        print(f"   This confirms prophages in this dataset do not carry resistance genes.")

    print(f"\n{'='*80}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 run_amrfinder_on_prophages.py <results_dir> [sample_id]")
        print("\nExamples:")
        print("  # Single sample:")
        print("  python3 run_amrfinder_on_prophages.py /path/to/results SRR13928113")
        print()
        print("  # All samples (WARNING: This will take HOURS for large datasets!):")
        print("  python3 run_amrfinder_on_prophages.py /path/to/results")
        print()
        print("⚠️  NOTE: Each sample requires running AMRFinderPlus (1-2 min per sample)")
        sys.exit(1)

    results_dir = Path(sys.argv[1])

    if not results_dir.exists():
        print(f"❌ Error: Results directory not found: {results_dir}")
        sys.exit(1)

    vibrant_dir = results_dir / "vibrant"
    if not vibrant_dir.exists():
        print(f"❌ Error: VIBRANT directory not found: {vibrant_dir}")
        sys.exit(1)

    # Create temporary directory for AMRFinder outputs
    temp_dir = tempfile.mkdtemp(prefix="prophage_amr_")
    print(f"\n📁 Temporary AMRFinder outputs: {temp_dir}")

    all_results = []

    # Single sample mode
    if len(sys.argv) > 2:
        sample_id = sys.argv[2]
        result = analyze_sample(results_dir, sample_id, temp_dir)
        all_results.append(result)

    # All samples mode
    else:
        print(f"\n⚠️  WARNING: Running AMRFinder on all samples will take HOURS!")
        print(f"   Each sample requires ~1-2 minutes to process.")
        print(f"   Consider testing on a single sample first.\n")

        response = input("Continue with all samples? [y/N]: ")
        if response.lower() != 'y':
            print("Aborted.")
            sys.exit(0)

        # Find all samples with prophage data
        phage_files = sorted(vibrant_dir.glob("*_phages.fna"))
        print(f"\n🔬 Found {len(phage_files)} samples with prophage data")

        for i, phage_file in enumerate(phage_files, 1):
            sample_id = phage_file.stem.replace('_phages', '')

            print(f"\n[{i}/{len(phage_files)}] Processing {sample_id}...")

            result = analyze_sample(results_dir, sample_id, temp_dir)
            all_results.append(result)

    # Print summary
    print_summary(all_results)

    # Export results
    output_csv = Path.home() / "prophage_amr_direct_scan.csv"
    export_results(all_results, output_csv)

    print(f"\n✅ Analysis complete!")
    print(f"   Temporary files in: {temp_dir}")
    print(f"   (You can delete this directory when done)")


if __name__ == "__main__":
    main()
