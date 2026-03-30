process IQTREE {
    tag "phylogeny"
    publishDir "${params.outdir}/iqtree", mode: 'copy'
    container = 'quay.io/biocontainers/iqtree:2.2.2.7--0'

    input:
    path(alignment)  // Core genome alignment from Panaroo

    output:
    path("alignment.treefile"), emit: tree
    path("alignment.iqtree"), emit: report
    path("alignment.log"), emit: log
    path("alignment.contree"), emit: consensus_tree, optional: true
    path("alignment.splits.nex"), emit: splits, optional: true
    path "versions.yml", emit: versions

    script:
    def bootstrap = params.iqtree_bootstrap
    def model = params.iqtree_model
    def threads = task.cpus
    """
    # Check if alignment file exists and has content
    if [ ! -s ${alignment} ]; then
        echo "ERROR: Alignment file is empty or missing" >&2
        exit 1
    fi

    # Count sequences in alignment
    SEQ_COUNT=\$(grep -c "^>" ${alignment} || echo 0)
    if [ \$SEQ_COUNT -lt 4 ]; then
        echo "WARNING: IQ-TREE requires at least 4 sequences, found \$SEQ_COUNT"
        echo "Skipping phylogenetic tree construction"
        touch alignment.treefile alignment.iqtree alignment.log
        echo "Insufficient sequences (\$SEQ_COUNT < 4)" > alignment.iqtree
        echo '"IQTREE": {"status": "skipped", "reason": "insufficient_sequences"}' > versions.yml
        exit 0
    fi

    # Run IQ-TREE with model selection and bootstrap
    iqtree2 \\
        -s ${alignment} \\
        -m ${model} \\
        -bb ${bootstrap} \\
        -nt ${threads} \\
        --prefix alignment \\
        -redo

    # Verify tree was created
    if [ ! -f "alignment.treefile" ]; then
        echo "ERROR: IQ-TREE failed to generate tree file" >&2
        exit 1
    fi

    echo '"IQTREE": {"version": "2.2.2.7", "model": "${model}", "bootstrap": ${bootstrap}}' > versions.yml
    """
}

process IQTREE_MIDPOINT_ROOT {
    tag "root_tree"
    publishDir "${params.outdir}/iqtree", mode: 'copy'
    container = 'quay.io/biocontainers/python:3.9--1'

    input:
    path(tree)

    output:
    path("alignment.rooted.treefile"), emit: rooted_tree
    path("tree_statistics.txt"), emit: stats

    script:
    """
    #!/usr/bin/env python3
    from Bio import Phylo
    import sys

    try:
        # Read the tree
        tree = Phylo.read('${tree}', 'newick')

        # Calculate some basic statistics
        num_terminals = len(tree.get_terminals())
        tree_depth = tree.total_branch_length()

        # Midpoint rooting
        tree.root_at_midpoint()

        # Write rooted tree
        Phylo.write(tree, 'alignment.rooted.treefile', 'newick')

        # Write statistics
        with open('tree_statistics.txt', 'w') as f:
            f.write(f"Number of taxa: {num_terminals}\\n")
            f.write(f"Total tree length: {tree_depth:.6f}\\n")
            f.write(f"Tree rooted at midpoint\\n")

        print(f"✅ Tree rooted successfully ({num_terminals} taxa)")

    except Exception as e:
        print(f"ERROR: Failed to root tree: {e}", file=sys.stderr)
        # Create empty files so pipeline doesn't fail
        with open('alignment.rooted.treefile', 'w') as f:
            f.write(open('${tree}').read())  # Use original unrooted tree
        with open('tree_statistics.txt', 'w') as f:
            f.write(f"Rooting failed: {e}\\n")
        sys.exit(1)
    """
}

process VISUALIZE_TREE {
    tag "plot_tree"
    publishDir "${params.outdir}/iqtree", mode: 'copy'
    container = 'quay.io/biocontainers/python:3.9--1'

    input:
    path tree
    path metadata

    output:
    path("phylogenetic_tree.pdf"), emit: pdf, optional: true
    path("phylogenetic_tree.png"), emit: png, optional: true
    path("phylogenetic_tree.svg"), emit: svg, optional: true

    script:
    """
    #!/usr/bin/env python3
    from Bio import Phylo
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import sys

    try:
        # Read tree
        tree = Phylo.read('${tree}', 'newick')

        # Create figure
        fig, ax = plt.subplots(1, 1, figsize=(12, max(8, len(tree.get_terminals()) * 0.3)))

        # Draw tree
        Phylo.draw(tree, axes=ax, do_show=False)

        ax.set_title('Phylogenetic Tree (IQ-TREE Maximum Likelihood)', fontsize=14, fontweight='bold')
        ax.set_xlabel('Branch Length', fontsize=10)

        plt.tight_layout()

        # Save in multiple formats
        plt.savefig('phylogenetic_tree.pdf', dpi=300, bbox_inches='tight')
        plt.savefig('phylogenetic_tree.png', dpi=300, bbox_inches='tight')
        plt.savefig('phylogenetic_tree.svg', bbox_inches='tight')

        print(f"✅ Tree visualizations created")

    except Exception as e:
        print(f"WARNING: Failed to visualize tree: {e}", file=sys.stderr)
        # Create empty placeholder files
        with open('phylogenetic_tree.png', 'w') as f:
            f.write('')
        sys.exit(0)  # Don't fail pipeline if visualization fails
    """
}
