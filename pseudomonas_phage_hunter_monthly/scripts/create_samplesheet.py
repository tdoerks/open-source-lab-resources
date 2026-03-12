#!/usr/bin/env python3
"""
Create COMPASS Samplesheet from Pseudomonas Monthly SRR Accessions

Reads the combined SRR list and creates a samplesheet compatible
with COMPASS pipeline's sra_list input mode.

Usage:
    python create_samplesheet.py
"""

import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(
        description='Create COMPASS samplesheet for Pseudomonas phage hunter project'
    )
    parser.add_argument(
        '--input',
        default='sra_accessions_pseudomonas_monthly_50_2020-2026.txt',
        help='Input SRR accession file'
    )
    parser.add_argument(
        '--output',
        default='samplesheet_pseudomonas_phage_hunter.txt',
        help='Output samplesheet file'
    )

    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}")
        print()
        print("Did you run the download script first?")
        print("  python3 scripts/fetch_pseudomonas_monthly.py")
        return 1

    # Read all SRR accessions
    with open(input_path, 'r') as f:
        accessions = [line.strip() for line in f if line.strip()]

    # Write samplesheet (one SRR per line)
    output_path = Path(args.output)
    with open(output_path, 'w') as f:
        for srr in accessions:
            f.write(f"{srr}\n")

    print("="*70)
    print("SAMPLESHEET CREATED")
    print("="*70)
    print(f"\nInput: {input_path}")
    print(f"Output: {output_path}")
    print(f"\nTotal samples: {len(accessions)}")
    print()
    print("Estimated analysis:")
    print(f"  Runtime: ~{len(accessions) * 6 / 60 / 24:.1f} days")
    print(f"  Storage: ~{len(accessions) * 0.5:.0f} GB")
    print()
    print("="*70)
    print("Next steps:")
    print(f"  1. Review: head {output_path}")
    print(f"  2. Submit: sbatch run_pseudomonas_phage_hunter.sh")
    print("="*70)

    return 0

if __name__ == '__main__':
    exit(main())
