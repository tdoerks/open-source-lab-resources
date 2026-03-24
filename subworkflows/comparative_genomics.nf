/*
 * COMPARATIVE GENOMICS SUBWORKFLOW
 * Handles genome annotation and pangenome analysis for temporal/comparative studies
 */

include { PROKKA } from '../modules/prokka'

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

    emit:
    gff = PROKKA.out.gff              // channel: [sample_id, gff]
    proteins = PROKKA.out.proteins     // channel: [sample_id, faa]
    genes = PROKKA.out.genes           // channel: [sample_id, ffn]
    contigs = PROKKA.out.contigs       // channel: [sample_id, fna]
    results = PROKKA.out.results       // channel: path(prokka_dir)
    versions = PROKKA.out.versions     // channel: path(versions.yml)
}
