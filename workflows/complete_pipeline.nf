/*
 * COMPLETE PIPELINE WORKFLOW
 * Main workflow that orchestrates all subworkflows for end-to-end analysis
 */

include { DATA_ACQUISITION } from '../subworkflows/data_acquisition'
include { ASSEMBLY } from '../subworkflows/assembly'
include { AMR_ANALYSIS } from '../subworkflows/amr_analysis'
include { PHAGE_ANALYSIS } from '../subworkflows/phage_analysis'
include { TYPING } from '../subworkflows/typing'
include { MOBILE_ELEMENTS } from '../subworkflows/mobile_elements'
include { COMPARATIVE_GENOMICS } from '../subworkflows/comparative_genomics'
include { COMBINE_RESULTS } from '../modules/combine_results'
include { COMPASS_SUMMARY } from '../modules/compass_summary'
include { MULTIQC } from '../modules/multiqc'
include { BUSCO } from '../modules/busco'
include { QUAST } from '../modules/quast'
include { CHECK_DATABASES } from '../modules/check_databases'
include { DOWNLOAD_ASSEMBLY } from '../modules/download_assembly'
include { PROPHAGE_AMR_INTERSECTION } from '../modules/prophage_amr'
include { PROPHAGE_AMR_COMPARISON } from '../modules/prophage_amr_comparison'
include { AGGREGATE_COMPARISON } from '../modules/prophage_amr_comparison'

workflow COMPLETE_PIPELINE {
    take:
    input_mode     // val: 'fasta', 'metadata', 'sra_list', or 'assembly'
    input_data     // channel: depends on mode

    main:
    // Validate required databases before starting pipeline
    // Fails fast with helpful error messages if databases are missing
    CHECK_DATABASES()

    ch_assemblies = Channel.empty()
    ch_versions = Channel.empty()
    ch_metadata_file = Channel.empty()
    ch_sra_runinfo = Channel.empty()

    ch_qc_outputs = Channel.empty()
    ch_has_assembly_qc = false

    if (input_mode == 'fasta') {
        // Direct FASTA input: [meta, fasta]
        // Expected input format from samplesheet: sample, organism, fasta
        ch_assemblies = input_data

        // Run assembly QC on pre-assembled genomes
        // Convert [meta, fasta] to [sample_id, fasta] for QC tools
        ch_assemblies_for_qc = ch_assemblies.map { meta, fasta -> [meta.id, fasta] }

        // BUSCO (optional)
        if (!params.skip_busco) {
            BUSCO(ch_assemblies_for_qc)
            ch_busco_summary = BUSCO.out.summary
            ch_versions = ch_versions.mix(BUSCO.out.versions)
        } else {
            ch_busco_summary = Channel.empty()
        }

        // QUAST
        QUAST(ch_assemblies_for_qc)
        ch_quast_report = QUAST.out.report
        ch_quast_dirs = QUAST.out.results_dir  // Use directories for MultiQC
        ch_versions = ch_versions.mix(QUAST.out.versions)

    } else if (input_mode == 'metadata') {
        // NARMS metadata mode: download metadata, filter, download SRA, assemble
        DATA_ACQUISITION('metadata', Channel.empty())

        // Assemble the downloaded reads
        ASSEMBLY(
            DATA_ACQUISITION.out.reads,
            DATA_ACQUISITION.out.metadata
        )

        ch_assemblies = ASSEMBLY.out.assemblies
        ch_qc_outputs = ASSEMBLY.out
        ch_busco_summary = ASSEMBLY.out.busco_summary
        ch_quast_report = ASSEMBLY.out.quast_report
        ch_quast_dirs = ASSEMBLY.out.quast_dirs  // Use directories for MultiQC
        ch_metadata_file = DATA_ACQUISITION.out.metadata_file
        ch_sra_runinfo = DATA_ACQUISITION.out.sra_runinfo  // Full SRA runinfo CSV for COMPASS_SUMMARY
        ch_versions = ch_versions.mix(DATA_ACQUISITION.out.versions)
        ch_versions = ch_versions.mix(ASSEMBLY.out.versions.first())

    } else if (input_mode == 'sra_list') {
        // SRA accession list mode: download SRA, assemble
        DATA_ACQUISITION('sra_list', input_data)

        // Assemble the downloaded reads
        ASSEMBLY(
            DATA_ACQUISITION.out.reads,
            Channel.empty()
        )

        ch_assemblies = ASSEMBLY.out.assemblies
        ch_qc_outputs = ASSEMBLY.out
        ch_busco_summary = ASSEMBLY.out.busco_summary
        ch_quast_report = ASSEMBLY.out.quast_report
        ch_quast_dirs = ASSEMBLY.out.quast_dirs  // Use directories for MultiQC
        ch_versions = ch_versions.mix(DATA_ACQUISITION.out.versions)
        ch_versions = ch_versions.mix(ASSEMBLY.out.versions.first())

    } else if (input_mode == 'assembly') {
        // Assembly accession mode: download assemblies via NCBI Entrez Direct
        // Expected input: [sample, organism, assembly_accession]
        DOWNLOAD_ASSEMBLY(input_data)

        // Transform downloaded assemblies to standard format: [meta, fasta]
        ch_assemblies = DOWNLOAD_ASSEMBLY.out.assembly.map { sample, organism, fasta ->
            def meta = [:]
            meta.id = sample
            meta.organism = organism
            return [meta, fasta]
        }

        // Run assembly QC on downloaded genomes
        // Convert [meta, fasta] to [sample_id, fasta] for QC tools
        ch_assemblies_for_qc = ch_assemblies.map { meta, fasta -> [meta.id, fasta] }

        // BUSCO (optional)
        if (!params.skip_busco) {
            BUSCO(ch_assemblies_for_qc)
            ch_busco_summary = BUSCO.out.summary
            ch_versions = ch_versions.mix(BUSCO.out.versions)
        } else {
            ch_busco_summary = Channel.empty()
        }

        // QUAST
        QUAST(ch_assemblies_for_qc)
        ch_quast_report = QUAST.out.report
        ch_quast_dirs = QUAST.out.results_dir  // Use directories for MultiQC
        ch_versions = ch_versions.mix(QUAST.out.versions)
        ch_versions = ch_versions.mix(DOWNLOAD_ASSEMBLY.out.versions)
    }

    // Make assemblies channel reusable for multiple downstream processes
    // Use multiMap to split channel for parallel consumption without batching
    // This allows samples to flow through independently as they complete assembly
    ch_assemblies
        .multiMap { meta, fasta ->
            amr: [meta, fasta]
            phage: [meta, fasta]
            typing: [meta, fasta]
            mobile: [meta, fasta]
            annotation: [meta, fasta]
        }
        .set { ch_assemblies_split }

    // Run genome annotation (Prokka) if enabled - optional for comparative genomics
    if (!params.skip_prokka) {
        COMPARATIVE_GENOMICS(ch_assemblies_split.annotation)
        ch_versions = ch_versions.mix(COMPARATIVE_GENOMICS.out.versions)
    }

    // Run AMR analysis - samples processed as they arrive
    AMR_ANALYSIS(ch_assemblies_split.amr)
    ch_versions = ch_versions.mix(AMR_ANALYSIS.out.versions)

    // Run Phage analysis - samples processed as they arrive
    PHAGE_ANALYSIS(ch_assemblies_split.phage)
    ch_versions = ch_versions.mix(PHAGE_ANALYSIS.out.versions)

    // Run Typing analysis (MLST, serotyping) - samples processed as they arrive
    TYPING(ch_assemblies_split.typing)
    ch_versions = ch_versions.mix(TYPING.out.versions)

    // Run Mobile Elements analysis (plasmids) - samples processed as they arrive
    MOBILE_ELEMENTS(ch_assemblies_split.mobile)
    ch_versions = ch_versions.mix(MOBILE_ELEMENTS.out.versions)

    // Run Prophage-AMR intersection analysis (if enabled)
    // Joins VIBRANT prophage coordinates with AMRFinder results to identify
    // AMR genes encoded within prophage regions
    if (!params.skip_prophage_amr) {
        // Extract prophage coordinates from VIBRANT results
        // VIBRANT.out.results format: [sample_id, vibrant_results_dir]
        ch_prophage_coords = PHAGE_ANALYSIS.out.vibrant_results
            .map { sample_id, vibrant_dir ->
                // Find prophage coordinates file in VIBRANT output directory
                def coords_file = file("${vibrant_dir}/VIBRANT_*_contigs/VIBRANT_results_*_contigs/VIBRANT_integrated_prophage_coordinates_*.tsv")
                if (!coords_file.exists()) {
                    // Try alternative directory structures
                    coords_file = file("${vibrant_dir}/VIBRANT_*/VIBRANT_results_*/VIBRANT_integrated_prophage_coordinates_*.tsv")
                }
                return [sample_id, coords_file]
            }

        // Extract sample_id from AMR results for joining
        // AMR_ANALYSIS.out.results format: [meta, amr_results_file]
        ch_amr_for_join = AMR_ANALYSIS.out.results
            .map { meta, amr_file -> [meta.id, amr_file] }

        // Join prophage coordinates with AMR results by sample_id
        ch_prophage_amr_input = ch_prophage_coords
            .join(ch_amr_for_join, by: 0)  // Join on sample_id (first element)

        // Run prophage-AMR intersection
        PROPHAGE_AMR_INTERSECTION(ch_prophage_amr_input)
        ch_versions = ch_versions.mix(PROPHAGE_AMR_INTERSECTION.out.versions)
        ch_prophage_amr_results = PROPHAGE_AMR_INTERSECTION.out.results

        // Optional: Run 3-method comparison for validation (SLOW - adds 1-2 min per sample)
        if (params.prophage_amr_comparison) {
            // Prepare input for comparison: [sample_id, vibrant_dir, prophage_coords, amr_results]
            ch_comparison_input = PHAGE_ANALYSIS.out.vibrant_results
                .map { sample_id, vibrant_dir -> [sample_id, vibrant_dir] }
                .join(ch_prophage_coords, by: 0)
                .join(ch_amr_for_join, by: 0)

            // Run all 3 methods and compare
            PROPHAGE_AMR_COMPARISON(ch_comparison_input)
            ch_versions = ch_versions.mix(PROPHAGE_AMR_COMPARISON.out.versions)

            // Aggregate comparison results across all samples
            AGGREGATE_COMPARISON(PROPHAGE_AMR_COMPARISON.out.summary.collect())
            ch_versions = ch_versions.mix(AGGREGATE_COMPARISON.out.versions)
            ch_comparison_results = AGGREGATE_COMPARISON.out.aggregate_summary
        } else {
            ch_comparison_results = Channel.empty()
        }
    } else {
        ch_prophage_amr_results = Channel.empty()
        ch_comparison_results = Channel.empty()
    }

    // Combine all results - runs after all analyses complete
    // Filter out failed samples that emit sample IDs instead of files
    COMBINE_RESULTS(
        AMR_ANALYSIS.out.results.filter { it[1] instanceof Path || it[1] instanceof java.io.File }.map { it[1] }.collect().ifEmpty([]),
        PHAGE_ANALYSIS.out.vibrant_results.filter { it[1] instanceof Path || it[1] instanceof java.io.File }.map { it[1] }.collect().ifEmpty([]),
        PHAGE_ANALYSIS.out.diamond_results.filter { it[1] instanceof Path || it[1] instanceof java.io.File }.map { it[1] }.collect().ifEmpty([]),
        Channel.empty().collect().ifEmpty([]),  // abricate_summary
        ch_quast_report.collect().ifEmpty([]),  // quast_reports
        ch_busco_summary.filter { it instanceof Path || it instanceof java.io.File }.collect().ifEmpty([]), // busco_summaries (filter failed samples)
        TYPING.out.mlst_results.filter { it[1] instanceof Path || it[1] instanceof java.io.File }.map { it[1] }.collect().ifEmpty([]),     // mlst_results
        TYPING.out.sistr_results.filter { it instanceof List && (it[1] instanceof Path || it[1] instanceof java.io.File) }.map { it[1] }.collect().ifEmpty([]),    // sistr_results (filter skipped non-Salmonella)
        ch_metadata_file.ifEmpty(file('NO_FILE'))    // metadata file (single path)
    )
    ch_versions = ch_versions.mix(COMBINE_RESULTS.out.versions)

    // Collect all QC outputs for MultiQC
    ch_multiqc = Channel.empty()

    if (input_mode != 'fasta' && input_mode != 'assembly') {
        // Include read QC when we assembled from reads (metadata or sra_list modes)
        ch_multiqc = ch_multiqc
            .mix(ch_qc_outputs.fastqc_html.collect().ifEmpty([]))
            .mix(ch_qc_outputs.fastp_json.collect().ifEmpty([]))
    }

    // Always include assembly QC (BUSCO and QUAST)
    // Use QUAST directories instead of individual report.tsv files to avoid name collisions
    // Filter BUSCO summaries to exclude any failed samples
    ch_multiqc = ch_multiqc
        .mix(ch_busco_summary.filter { it instanceof Path || it instanceof java.io.File }.collect().ifEmpty([]))
        .mix(ch_quast_dirs.collect().ifEmpty([]))

    // Run MultiQC to aggregate all QC reports
    MULTIQC(ch_multiqc.collect())
    ch_versions = ch_versions.mix(MULTIQC.out.versions)
    ch_multiqc_report = MULTIQC.out.report

    // Generate comprehensive COMPASS summary after all analyses complete
    // Wait for COMBINE_RESULTS and MultiQC to finish before generating summary
    ch_summary_ready = COMBINE_RESULTS.out.summary
        .concat(ch_multiqc_report)
        .collect()
        .map { 'ready' }

    COMPASS_SUMMARY(
        ch_sra_runinfo.ifEmpty(file('NO_FILE')),  // Pass full SRA runinfo CSV (40+ fields) not filtered_samples.csv
        ch_summary_ready
    )
    ch_versions = ch_versions.mix(COMPASS_SUMMARY.out.versions)

    emit:
    summary = COMBINE_RESULTS.out.summary
    report = COMBINE_RESULTS.out.report
    compass_summary_tsv = COMPASS_SUMMARY.out.tsv
    compass_summary_html = COMPASS_SUMMARY.out.html
    amr_results = AMR_ANALYSIS.out.results
    phage_results = PHAGE_ANALYSIS.out.vibrant_results
    diamond_results = PHAGE_ANALYSIS.out.diamond_results
    // checkv_results = PHAGE_ANALYSIS.out.checkv_results  // CheckV not currently emitted by PHAGE_ANALYSIS
    phanotate_results = PHAGE_ANALYSIS.out.phanotate_results
    mlst_results = TYPING.out.mlst_results
    sistr_results = TYPING.out.sistr_results
    mobsuite_results = MOBILE_ELEMENTS.out.mobsuite_results
    plasmids = MOBILE_ELEMENTS.out.plasmids
    prophage_amr_results = ch_prophage_amr_results
    prophage_amr_comparison = ch_comparison_results
    multiqc_report = ch_multiqc_report
    versions = ch_versions.unique()
}
