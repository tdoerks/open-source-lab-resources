#!/usr/bin/env python3
"""
Generate COMPASS samplesheet for Fusobacterium genus study
"""

def main():
    input_file = "data/sra_accessions_fusobacterium_all.txt"
    output_file = "data/samplesheet_fusobacterium.txt"

    print("="*70)
    print("Generating COMPASS Samplesheet")
    print("="*70)

    # Read SRR accessions
    with open(input_file, 'r') as f:
        accessions = [line.strip() for line in f if line.strip()]

    print(f"Read {len(accessions)} accessions from {input_file}")

    # Generate samplesheet format
    with open(output_file, 'w') as f:
        for acc in accessions:
            # COMPASS samplesheet format: sample_id
            f.write(f"{acc}\n")

    print(f"✓ Saved samplesheet to {output_file}")
    print(f"✓ Total samples: {len(accessions)}")
    print()
    print("="*70)
    print("Next step:")
    print("  Submit COMPASS job: sbatch run_fusobacterium.sh")
    print("="*70)

if __name__ == "__main__":
    main()
