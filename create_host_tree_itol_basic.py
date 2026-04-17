#!/usr/bin/env python3
"""
Create basic iTOL color strip annotations for Fusobacterium host tree
Just using sample IDs for now - can enhance with metadata later
"""

def extract_samples_from_tree(tree_file):
    """Extract sample IDs from Newick tree"""
    with open(tree_file, 'r') as f:
        tree = f.read()

    # Extract all SRR accessions
    import re
    samples = re.findall(r'(SRR\w+?):', tree)
    return sorted(set(samples))

def create_basic_colorstrip(samples, output_file):
    """Create a simple color strip showing sample groups"""

    with open(output_file, 'w') as f:
        # iTOL header
        f.write("DATASET_COLORSTRIP\n")
        f.write("SEPARATOR TAB\n")
        f.write("DATASET_LABEL\tSample_Groups\n")
        f.write("COLOR\t#ff0000\n")
        f.write("LEGEND_TITLE\tSample Groups\n")
        f.write("LEGEND_SHAPES\t1\t1\t1\n")
        f.write("LEGEND_COLORS\t#1f77b4\t#ff7f0e\t#2ca02c\n")
        f.write("LEGEND_LABELS\tGroup_1\tGroup_2\tGroup_3\n")
        f.write("DATA\n")

        # Assign colors based on sample ID patterns
        # This is a simple heuristic - can be improved with actual metadata
        for sample in samples:
            # Extract numeric part to group samples
            num = ''.join(filter(str.isdigit, sample))

            if num:
                num_val = int(num)
                # Divide into 3 groups based on numeric value
                if num_val < 10000000:
                    color = "#1f77b4"  # Blue
                    label = "Group_1"
                elif num_val < 20000000:
                    color = "#ff7f0e"  # Orange
                    label = "Group_2"
                else:
                    color = "#2ca02c"  # Green
                    label = "Group_3"
            else:
                color = "#d62728"  # Red - unknown
                label = "Unknown"

            f.write(f"SRR{sample}\t{color}\t{label}\n")

    print(f"✓ Created basic color strip: {output_file}")

def create_sample_labels(samples, output_file):
    """Create iTOL labels file for sample IDs"""

    with open(output_file, 'w') as f:
        # iTOL header
        f.write("DATASET_TEXT\n")
        f.write("SEPARATOR TAB\n")
        f.write("DATASET_LABEL\tSample_IDs\n")
        f.write("COLOR\t#000000\n")
        f.write("DATA\n")

        for sample in samples:
            f.write(f"SRR{sample}\t{sample}\t-1\t#000000\tnormal\t1\t0\n")

    print(f"✓ Created sample labels: {output_file}")

def main():
    tree_file = "fusobacterium_host_tree.nwk"

    print("Extracting samples from host tree...")
    samples = extract_samples_from_tree(tree_file)
    print(f"Found {len(samples)} samples in tree")

    # Create basic annotations
    create_basic_colorstrip(samples, "host_tree_colorstrip_basic.txt")
    create_sample_labels(samples, "host_tree_labels.txt")

    print("\n" + "="*60)
    print("HOST TREE iTOL ANNOTATIONS CREATED")
    print("="*60)
    print(f"\nTree file: {tree_file}")
    print(f"Samples: {len(samples)}")
    print("\niTOL files ready:")
    print("  1. host_tree_colorstrip_basic.txt")
    print("  2. host_tree_labels.txt")
    print("\nTo use in iTOL:")
    print("  1. Upload fusobacterium_host_tree.nwk to iTOL")
    print("  2. Drag and drop the annotation files")
    print("  3. Customize colors and labels as needed")
    print("\nNOTE: These are basic annotations based on sample IDs.")
    print("For better annotations (species, host, isolation source),")
    print("run fetch_sra_metadata.py to get metadata from NCBI.")

if __name__ == "__main__":
    main()
