/*
 * SNP ANALYSIS SUBWORKFLOW
 * Handles variant calling and SNP-based phylogenetics for outbreak investigation
 */

include { SNIPPY; SNIPPY_CORE; SNIPPY_CLEAN_ALIGNMENT; SNP_DISTANCE_MATRIX } from '../modules/snippy'

workflow SNP_ANALYSIS {
    take:
    reads       // channel: [meta, [R1, R2]]
    reference   // path: reference genome for mapping

    main:
    // Run Snippy variant calling for each sample
    SNIPPY(reads, reference)

    // Collect all Snippy output directories for core SNP analysis
    ch_snippy_dirs = SNIPPY.out.results
        .map { meta, dir -> dir }
        .collect()

    // Create core SNP alignment across all samples
    SNIPPY_CORE(reference, ch_snippy_dirs)

    // Clean alignment and extract SNPs only
    SNIPPY_CLEAN_ALIGNMENT(SNIPPY_CORE.out.alignment)

    // Calculate pairwise SNP distances
    SNP_DISTANCE_MATRIX(SNIPPY_CLEAN_ALIGNMENT.out.snps_only)

    // Collect versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(SNIPPY.out.versions)
    ch_versions = ch_versions.mix(SNIPPY_CORE.out.versions.first())

    emit:
    vcf = SNIPPY.out.vcf                           // channel: [meta, vcf]
    alignment = SNIPPY.out.alignment               // channel: [meta, aligned.fa]
    core_alignment = SNIPPY_CORE.out.alignment     // channel: path(core.aln)
    clean_alignment = SNIPPY_CLEAN_ALIGNMENT.out.clean_alignment  // channel: path(core.clean.aln)
    snps_only = SNIPPY_CLEAN_ALIGNMENT.out.snps_only              // channel: path(core.snps.aln)
    snp_matrix = SNP_DISTANCE_MATRIX.out.matrix    // channel: path(snp_distance_matrix.tsv)
    snp_stats = SNIPPY_CLEAN_ALIGNMENT.out.stats   // channel: path(snp_statistics.txt)
    versions = ch_versions                          // channel: path(versions.yml)
}
