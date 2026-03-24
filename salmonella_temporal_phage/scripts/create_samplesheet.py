#!/usr/bin/env python3
"""
Create COMPASS samplesheet from Salmonella SRA accessions
Input: data/sra_accessions_salmonella_monthly_50_2020-2026.txt
Output: data/samplesheet_salmonella_temporal_phage.txt
"""

def main():
    input_file = "data/sra_accessions_salmonella_monthly_50_2020-2026.txt"
    output_file = "data/samplesheet_salmonella_temporal_phage.txt"

    print("="*70)
    print("Creating COMPASS Samplesheet for Salmonella Temporal Phage Study")
    print("="*70)

    # Read SRR accessions
    with open(input_file, 'r') as f:
        srr_accessions = [line.strip() for line in f if line.strip()]

    print(f"Read {len(srr_accessions)} SRR accessions from {input_file}")

    # Write samplesheet (just SRR IDs, one per line)
    with open(output_file, 'w') as f:
        for srr in srr_accessions:
            f.write(f"{srr}\n")

    print(f"Wrote samplesheet to {output_file}")
    print(f"Total samples: {len(srr_accessions)}")
    print()
    print("Next steps:")
    print(f"  1. Review: head {output_file}")
    print(f"  2. Run COMPASS: sbatch run_salmonella_temporal_phage.sh")
    print("="*70)

if __name__ == "__main__":
    main()
