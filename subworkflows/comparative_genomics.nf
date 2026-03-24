/*
 * COMPARATIVE GENOMICS SUBWORKFLOW
 * Handles genome annotation and pangenome analysis for temporal/comparative studies
 */

include { PROKKA } from '../modules/prokka'
include { PANAROO; PANAROO_SUMMARY } from '../modules/panaroo'

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

    // Collect versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(PROKKA.out.versions)
    if (!params.skip_panaroo) {
        ch_versions = ch_versions.mix(PANAROO.out.versions.first())
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
    versions = ch_versions                          // channel: path(versions.yml)
}
