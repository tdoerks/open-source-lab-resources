/*
 * PROPHAGE-AMR METHOD COMPARISON MODULE
 * Compares three different approaches to detect AMR genes in prophages
 */

process PROPHAGE_AMR_COMPARISON {
    tag "$sample_id"
    label 'process_medium'
    publishDir "${params.outdir}/prophage_amr_comparison", mode: 'copy'

    // Use AMRFinder container (has Python, AMRFinder, and basic tools)
    // Note: RGI requires separate installation - if not available, Method 3 will be skipped
    container = 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'

    input:
    tuple val(sample_id), path(vibrant_dir), path(prophage_coords), path(amr_results)

    output:
    tuple val(sample_id), path("${sample_id}_comparison_summary.tsv"), emit: summary
    path("${sample_id}_comparison_report.txt"), emit: report
    path("${sample_id}_method*.tsv"), emit: method_results, optional: true
    path "versions.yml", emit: versions

    script:
    def terminal_buffer = params.prophage_amr_terminal_buffer ?: 5000
    """
    # Run comparison script
    python compare_prophage_amr_methods.py \\
        --sample_id ${sample_id} \\
        --vibrant_dir ${vibrant_dir} \\
        --amr_results ${amr_results} \\
        --prophage_coords ${prophage_coords} \\
        --output_dir . \\
        --terminal_buffer ${terminal_buffer}

    # Generate versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        amrfinder: \$(amrfinder --version 2>&1 | grep -oP '\\d+\\.\\d+\\.\\d+' | head -1 || echo "unknown")
        rgi: \$(rgi main --version 2>&1 | grep -oP '\\d+\\.\\d+\\.\\d+' || echo "not installed")
    END_VERSIONS
    """

    stub:
    """
    # Create stub outputs for testing
    echo -e "sample_id\\tgene\\tmethod1_coordinate\\tmethod2_amrfinder\\tmethod3_rgi\\tdetected_by_count\\tagreement_category" > ${sample_id}_comparison_summary.tsv
    echo -e "${sample_id}\\tNone\\tNo\\tNo\\tNo\\t0\\tno_genes" >> ${sample_id}_comparison_summary.tsv

    echo "PROPHAGE-AMR METHOD COMPARISON: ${sample_id}" > ${sample_id}_comparison_report.txt
    echo "Stub mode - no real analysis performed" >> ${sample_id}_comparison_report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "stub"
        amrfinder: "stub"
        rgi: "stub"
    END_VERSIONS
    """
}

/*
 * AGGREGATE COMPARISON RESULTS
 * Combines comparison results from all samples into summary statistics
 */
process AGGREGATE_COMPARISON {
    label 'process_low'
    publishDir "${params.outdir}/prophage_amr_comparison", mode: 'copy'

    container = 'quay.io/biocontainers/pandas:1.5.2'

    input:
    path(comparison_summaries)  // All sample comparison TSVs

    output:
    path("comparison_aggregate_summary.tsv"), emit: aggregate_summary
    path("comparison_aggregate_report.txt"), emit: aggregate_report
    path "versions.yml", emit: versions

    script:
    """
    #!/usr/bin/env python3
    import pandas as pd
    from pathlib import Path
    import csv

    # Read all comparison summaries
    summaries = []
    for f in Path('.').glob('*_comparison_summary.tsv'):
        try:
            df = pd.read_csv(f, sep='\\t')
            summaries.append(df)
        except:
            pass

    if summaries:
        all_data = pd.concat(summaries, ignore_index=True)
    else:
        all_data = pd.DataFrame()

    # Calculate aggregate statistics
    total_samples = len(set(all_data['sample_id'])) if not all_data.empty else 0
    samples_with_genes = len(set(all_data[all_data['gene'] != 'None']['sample_id'])) if not all_data.empty else 0

    # Count agreement patterns
    if not all_data.empty and 'gene' in all_data.columns:
        genes_data = all_data[all_data['gene'] != 'None']
        agreement_stats = genes_data['agreement_category'].value_counts().to_dict()
        method_counts = {
            'method1': genes_data['method1_coordinate'].value_counts().get('Yes', 0),
            'method2': genes_data['method2_amrfinder'].value_counts().get('Yes', 0),
            'method3': genes_data['method3_rgi'].value_counts().get('Yes', 0)
        }
    else:
        agreement_stats = {}
        method_counts = {'method1': 0, 'method2': 0, 'method3': 0}

    # Write aggregate summary TSV
    with open('comparison_aggregate_summary.tsv', 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\\t')
        writer.writerow(['metric', 'value'])
        writer.writerow(['total_samples', total_samples])
        writer.writerow(['samples_with_prophage_amr', samples_with_genes])
        writer.writerow(['method1_coordinate_detections', method_counts['method1']])
        writer.writerow(['method2_amrfinder_detections', method_counts['method2']])
        writer.writerow(['method3_rgi_detections', method_counts['method3']])
        writer.writerow(['agreed_genes', agreement_stats.get('agreement', 0)])
        writer.writerow(['disagreed_genes', agreement_stats.get('disagreement', 0)])

    # Write human-readable report
    with open('comparison_aggregate_report.txt', 'w') as f:
        f.write("=" * 80 + "\\n")
        f.write("PROPHAGE-AMR METHOD COMPARISON - AGGREGATE RESULTS\\n")
        f.write("=" * 80 + "\\n\\n")

        f.write(f"Total samples analyzed: {total_samples}\\n")
        f.write(f"Samples with prophage-AMR: {samples_with_genes}\\n\\n")

        f.write("DETECTIONS BY METHOD:\\n")
        f.write("-" * 80 + "\\n")
        f.write(f"  Method 1 (Coordinate):       {method_counts['method1']} genes\\n")
        f.write(f"  Method 2 (AMRFinder Direct): {method_counts['method2']} genes\\n")
        f.write(f"  Method 3 (RGI/CARD):         {method_counts['method3']} genes\\n\\n")

        f.write("AGREEMENT ANALYSIS:\\n")
        f.write("-" * 80 + "\\n")
        f.write(f"  Genes detected by ≥2 methods: {agreement_stats.get('agreement', 0)}\\n")
        f.write(f"  Genes detected by 1 method:   {agreement_stats.get('disagreement', 0)}\\n\\n")

        if samples_with_genes == 0:
            f.write("✓ No prophage-encoded AMR genes detected across all samples\\n")
            f.write("  This is the expected result for most bacterial populations.\\n")

    # Versions
    with open('versions.yml', 'w') as f:
        f.write(f'"{task.process}":\\n')
        f.write(f'    pandas: {pd.__version__}\\n')
    """

    stub:
    """
    echo -e "metric\\tvalue" > comparison_aggregate_summary.tsv
    echo -e "total_samples\\t0" >> comparison_aggregate_summary.tsv

    echo "AGGREGATE COMPARISON - STUB MODE" > comparison_aggregate_report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: "stub"
    END_VERSIONS
    """
}
