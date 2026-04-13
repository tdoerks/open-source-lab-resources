#!/usr/bin/env python3
"""
Generate COMPASS samplesheet for STEC study
"""

def main():
    # Check for temporal file
    try:
        input_file = "data/sra_accessions_stec_temporal_100_2020-2026.txt"
        with open(input_file, 'r') as f:
            pass
    except FileNotFoundError:
        # Try all STEC file
        input_file = "data/sra_accessions_stec_all.txt"

    output_file = "data/samplesheet_stec.txt"

    print("="*70)
    print("Generating COMPASS Samplesheet")
    print("="*70)

    # Read SRR accessions
    with open(input_file, 'r') as f:
        accessions = [line.strip() for line in f if line.strip()]

    print(f"Read {len(accessions)} accessions from {input_file}")

    # Generate samplesheet
    with open(output_file, 'w') as f:
        for acc in accessions:
            f.write(f"{acc}\n")

    print(f"✓ Saved samplesheet to {output_file}")
    print(f"✓ Total samples: {len(accessions)}")
    print()
    print("="*70)
    print("Next step:")
    print("  Submit COMPASS job: sbatch run_stec_prophage.sh")
    print("="*70)

if __name__ == "__main__":
    main()
