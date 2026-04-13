/*
 * COMPARATIVE GENOMICS SUBWORKFLOW
 * Handles genome annotation and pangenome analysis for temporal/comparative studies
 */

include { PROKKA } from '../modules/prokka'
include { PANAROO; PANAROO_SUMMARY } from '../modules/panaroo'
include { IQTREE; IQTREE_MIDPOINT_ROOT; VISUALIZE_TREE } from '../modules/iqtree'

workflow COMPARATIVE_GENOMICS {
    take:
    assemblies  // channel: [meta, fasta]

    main:
    // Annotate genomes with Prokka
    // Convert [meta, fasta] to [sample_id, fasta, organism]
    ch_prokka_input = assemblies.map { meta, fasta ->
        [meta.id, fasta, meta.organism ?: "Unknown"]
    }

    PROKKA(ch_prokka_input)

    // Pangenome analysis with Panaroo (only if enabled and multiple samples)
    ch_panaroo_results = Channel.empty()
    ch_panaroo_matrix = Channel.empty()
    ch_panaroo_alignment = Channel.empty()
    ch_panaroo_stats = Channel.empty()

    if (!params.skip_panaroo) {
        // Collect all GFF files for pangenome analysis
        ch_gff_collection = PROKKA.out.gff
            .map { sample_id, gff -> gff }
            .collect()

        PANAROO(ch_gff_collection)

        // Generate summary statistics if Panaroo produced results
        ch_panaroo_matrix = PANAROO.out.matrix
        ch_panaroo_alignment = PANAROO.out.core_alignment
        ch_panaroo_results = PANAROO.out.results

        // Create pangenome statistics
        PANAROO_SUMMARY(PANAROO.out.matrix)
        ch_panaroo_stats = PANAROO_SUMMARY.out.stats
    }

    // Phylogenetic tree construction with IQ-TREE (only if Panaroo produced alignment)
    ch_iqtree_tree = Channel.empty()
    ch_iqtree_rooted = Channel.empty()
    ch_iqtree_plot = Channel.empty()

    if (!params.skip_panaroo && !params.skip_iqtree) {
        // Build phylogenetic tree from Panaroo core genome alignment
        IQTREE(ch_panaroo_alignment)
        ch_iqtree_tree = IQTREE.out.tree

        // Root tree at midpoint for better visualization
        IQTREE_MIDPOINT_ROOT(IQTREE.out.tree)
        ch_iqtree_rooted = IQTREE_MIDPOINT_ROOT.out.rooted_tree

        // Visualize tree
        VISUALIZE_TREE(IQTREE_MIDPOINT_ROOT.out.rooted_tree, Channel.empty())
        ch_iqtree_plot = VISUALIZE_TREE.out.png
    }

    // Collect versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(PROKKA.out.versions)
    if (!params.skip_panaroo) {
        ch_versions = ch_versions.mix(PANAROO.out.versions.first())
    }
    if (!params.skip_panaroo && !params.skip_iqtree) {
        ch_versions = ch_versions.mix(IQTREE.out.versions.first())
    }

    emit:
    gff = PROKKA.out.gff              // channel: [sample_id, gff]
    proteins = PROKKA.out.proteins     // channel: [sample_id, faa]
    genes = PROKKA.out.genes           // channel: [sample_id, ffn]
    contigs = PROKKA.out.contigs       // channel: [sample_id, fna]
    results = PROKKA.out.results       // channel: path(prokka_dir)
    panaroo_results = ch_panaroo_results           // channel: path(panaroo_results/)
    panaroo_matrix = ch_panaroo_matrix             // channel: path(gene_presence_absence.csv)
    panaroo_alignment = ch_panaroo_alignment       // channel: path(core_gene_alignment.aln)
    panaroo_stats = ch_panaroo_stats               // channel: path(pangenome_statistics.tsv)
    iqtree_tree = ch_iqtree_tree                   // channel: path(alignment.treefile)
    iqtree_rooted = ch_iqtree_rooted               // channel: path(alignment.rooted.treefile)
    iqtree_plot = ch_iqtree_plot                   // channel: path(phylogenetic_tree.png)
    versions = ch_versions                          // channel: path(versions.yml)
}
