process PANAROO {
    tag "pangenome"
    publishDir "${params.outdir}/panaroo", mode: 'copy'
    container = 'quay.io/biocontainers/panaroo:1.5.0--pyhdfd78af_0'

    input:
    path(gff_files)  // Collection of all Prokka GFF files

    output:
    path("panaroo_results/"), emit: results
    path("panaroo_results/gene_presence_absence.csv"), emit: matrix, optional: true
    path("panaroo_results/core_gene_alignment.aln"), emit: core_alignment, optional: true
    path("panaroo_results/pan_genome_reference.fa"), emit: pan_genome, optional: true
    path("panaroo_results/summary_statistics.txt"), emit: summary, optional: true
    path("panaroo_results/gene_data.csv"), emit: gene_data, optional: true
    path "versions.yml", emit: versions

    script:
    def gff_count = gff_files instanceof List ? gff_files.size() : 1
    """
    # Panaroo requires at least 2 genomes for pangenome analysis
    if [ ${gff_count} -lt 2 ]; then
        echo "WARNING: Panaroo requires at least 2 genomes, found ${gff_count}"
        echo "Skipping pangenome analysis - creating empty output directory"
        mkdir -p panaroo_results
        echo "Insufficient samples (${gff_count} < 2)" > panaroo_results/skipped.txt
        echo '"PANAROO": {"status": "skipped", "reason": "insufficient_samples"}' > versions.yml
        exit 0
    fi

    # Run Panaroo pangenome analysis
    panaroo \\
        -i ${gff_files} \\
        -o panaroo_results \\
        --clean-mode strict \\
        --remove-invalid-genes \\
        --alignment core \\
        --aligner mafft \\
        --core_threshold 0.95 \\
        -t ${task.cpus}

    # Verify outputs were created
    if [ ! -f "panaroo_results/gene_presence_absence.csv" ]; then
        echo "ERROR: Panaroo failed to create gene_presence_absence.csv" >&2
        exit 1
    fi

    echo '"PANAROO": {"version": "1.5.0", "samples": ${gff_count}}' > versions.yml
    """
}

process PANAROO_SUMMARY {
    tag "pangenome_stats"
    publishDir "${params.outdir}/panaroo", mode: 'copy'
    container = 'quay.io/biocontainers/python:3.9--1'

    input:
    path(gene_presence_absence)

    output:
    path("pangenome_statistics.tsv"), emit: stats
    path("pangenome_plot_data.tsv"), emit: plot_data

    script:
    """
    #!/usr/bin/env python3
    import pandas as pd
    import sys

    # Read gene presence/absence matrix
    try:
        df = pd.read_csv('${gene_presence_absence}')
    except Exception as e:
        print(f"ERROR: Failed to read gene_presence_absence.csv: {e}", file=sys.stderr)
        sys.exit(1)

    # Calculate pangenome statistics
    num_samples = len([col for col in df.columns if not col.startswith('Gene') and
                                                      not col.startswith('Non-unique') and
                                                      not col.startswith('Annotation')])

    total_genes = len(df)

    # Core genes: present in >= 95% of genomes
    core_threshold = 0.95 * num_samples
    core_genes = sum(df.iloc[:, 3:].sum(axis=1) >= core_threshold)

    # Soft-core: 95% >= x >= 90%
    softcore_threshold = 0.90 * num_samples
    softcore_genes = sum((df.iloc[:, 3:].sum(axis=1) >= softcore_threshold) &
                        (df.iloc[:, 3:].sum(axis=1) < core_threshold))

    # Shell: 15% <= x < 90%
    shell_low = 0.15 * num_samples
    shell_genes = sum((df.iloc[:, 3:].sum(axis=1) >= shell_low) &
                     (df.iloc[:, 3:].sum(axis=1) < softcore_threshold))

    # Cloud: < 15%
    cloud_genes = sum(df.iloc[:, 3:].sum(axis=1) < shell_low)

    # Write summary statistics
    with open('pangenome_statistics.tsv', 'w') as out:
        out.write("metric\\tvalue\\n")
        out.write(f"total_samples\\t{num_samples}\\n")
        out.write(f"total_genes\\t{total_genes}\\n")
        out.write(f"core_genes_95pct\\t{core_genes}\\n")
        out.write(f"softcore_genes_90-95pct\\t{softcore_genes}\\n")
        out.write(f"shell_genes_15-90pct\\t{shell_genes}\\n")
        out.write(f"cloud_genes_lt15pct\\t{cloud_genes}\\n")
        out.write(f"core_percentage\\t{100*core_genes/total_genes:.2f}\\n")
        out.write(f"accessory_genes\\t{total_genes - core_genes}\\n")
        out.write(f"pangenome_size\\t{total_genes}\\n")

    # Create data for pangenome size plot
    with open('pangenome_plot_data.tsv', 'w') as out:
        out.write("category\\tgene_count\\tpercentage\\n")
        out.write(f"Core (≥95%)\\t{core_genes}\\t{100*core_genes/total_genes:.2f}\\n")
        out.write(f"Soft-core (90-95%)\\t{softcore_genes}\\t{100*softcore_genes/total_genes:.2f}\\n")
        out.write(f"Shell (15-90%)\\t{shell_genes}\\t{100*shell_genes/total_genes:.2f}\\n")
        out.write(f"Cloud (<15%)\\t{cloud_genes}\\t{100*cloud_genes/total_genes:.2f}\\n")

    print(f"✅ Pangenome statistics calculated for {num_samples} samples")
    print(f"   Total genes: {total_genes}")
    print(f"   Core genes: {core_genes} ({100*core_genes/total_genes:.1f}%)")
    print(f"   Accessory genes: {total_genes - core_genes} ({100*(total_genes-core_genes)/total_genes:.1f}%)")
    """
}
