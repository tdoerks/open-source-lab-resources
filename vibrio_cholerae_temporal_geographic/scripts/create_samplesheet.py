#!/usr/bin/env python3
"""
Generate COMPASS samplesheet from Vibrio cholerae SRA accessions

Reads combined_vibrio_accessions.txt and creates samplesheet for COMPASS pipeline
"""

from pathlib import Path

def main():
    # Input/output paths
    data_dir = Path('data')
    accession_file = data_dir / 'combined_vibrio_accessions.txt'
    samplesheet_file = Path('samplesheet_vibrio_cholerae.txt')

    if not accession_file.exists():
        print(f"❌ ERROR: {accession_file} not found!")
        print("   Run fetch_vibrio_geographic.py first")
        return

    # Read SRR accessions
    with open(accession_file) as f:
        srr_list = [line.strip() for line in f if line.strip()]

    print(f"Read {len(srr_list)} SRR accessions from {accession_file}")

    # Write samplesheet (simple format: one SRR per line)
    with open(samplesheet_file, 'w') as f:
        for srr in srr_list:
            f.write(f"{srr}\n")

    print(f"✅ Wrote samplesheet: {samplesheet_file}")
    print(f"   Total samples: {len(srr_list)}")
    print()
    print("Next step:")
    print("  sbatch run_vibrio_cholerae.sh")
    print()


if __name__ == '__main__':
    main()
