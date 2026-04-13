process PROPHAGE_AMR_INTERSECTION {
    tag "$sample_id"
    publishDir "${params.outdir}/prophage_amr", mode: 'copy'
    container = 'quay.io/biocontainers/pandas:1.5.2'

    input:
    tuple val(sample_id), path(prophage_coords), path(amr_results)

    output:
    tuple val(sample_id), path("${sample_id}_prophage_amr.tsv"), emit: results, optional: true
    path("${sample_id}_prophage_amr_summary.txt"), emit: summary, optional: true
    path "versions.yml", emit: versions

    script:
    def terminal_buffer = params.prophage_amr_terminal_buffer ?: 5000
    """
    # Check if prophage coordinates file exists and has content
    if [ ! -s ${prophage_coords} ]; then
        echo "No prophage coordinates found for ${sample_id}" >&2
        echo "Creating empty output files for pipeline continuity"
        touch ${sample_id}_prophage_amr.tsv
        echo '"PROPHAGE_AMR_INTERSECTION": {"status": "skipped", "reason": "no_prophage_coords"}' > versions.yml
        exit 0
    fi

    # Check if AMR results file exists and has content
    if [ ! -s ${amr_results} ]; then
        echo "No AMR results found for ${sample_id}" >&2
        echo "Creating empty output files for pipeline continuity"
        touch ${sample_id}_prophage_amr.tsv
        echo '"PROPHAGE_AMR_INTERSECTION": {"status": "skipped", "reason": "no_amr_results"}' > versions.yml
        exit 0
    fi

    # Run prophage-AMR intersection analysis
    intersect_prophage_amr.py \\
        --prophage_coords ${prophage_coords} \\
        --amr_results ${amr_results} \\
        --output ${sample_id}_prophage_amr.tsv \\
        --sample_name ${sample_id} \\
        --terminal_buffer ${terminal_buffer}

    # Create versions file
    echo '"PROPHAGE_AMR_INTERSECTION": {"version": "1.0.0", "method": "Pinto et al. 2024, Genes 16(5):656"}' > versions.yml
    """
}
