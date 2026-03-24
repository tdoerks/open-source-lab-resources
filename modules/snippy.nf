process SNIPPY {
    tag "$meta.id"
    publishDir "${params.outdir}/snippy", mode: 'copy'
    container = 'quay.io/biocontainers/snippy:4.6.0--hdfd78af_2'

    input:
    tuple val(meta), path(reads)
    path(reference)

    output:
    tuple val(meta), path("${meta.id}/"), emit: results
    tuple val(meta), path("${meta.id}/${meta.id}.vcf"), emit: vcf
    tuple val(meta), path("${meta.id}/${meta.id}.aligned.fa"), emit: alignment
    tuple val(meta), path("${meta.id}/${meta.id}.tab"), emit: summary
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    # Run Snippy variant calling against reference
    snippy \\
        --outdir ${prefix} \\
        --ref ${reference} \\
        --R1 ${reads[0]} \\
        --R2 ${reads[1]} \\
        --cpus ${task.cpus} \\
        --prefix ${prefix} \\
        --force

    # Verify outputs were created
    if [ ! -f "${prefix}/${prefix}.vcf" ]; then
        echo "ERROR: Snippy failed to create VCF file" >&2
        exit 1
    fi

    echo '"SNIPPY": {"version": "4.6.0", "sample": "${meta.id}"}' > versions.yml
    """
}

process SNIPPY_CORE {
    tag "core_snps"
    publishDir "${params.outdir}/snippy", mode: 'copy'
    container = 'quay.io/biocontainers/snippy:4.6.0--hdfd78af_2'

    input:
    path(reference)
    path(snippy_dirs)  // Collection of all Snippy output directories

    output:
    path("core.aln"), emit: alignment
    path("core.vcf"), emit: vcf
    path("core.tab"), emit: summary
    path("core.txt"), emit: stats
    path "versions.yml", emit: versions

    script:
    def dir_count = snippy_dirs instanceof List ? snippy_dirs.size() : 1
    """
    # Check if we have enough samples
    if [ ${dir_count} -lt 2 ]; then
        echo "WARNING: Snippy-core requires at least 2 samples, found ${dir_count}"
        echo "Skipping core SNP alignment"
        touch core.aln core.vcf core.tab core.txt
        echo "Insufficient samples (${dir_count} < 2)" > core.txt
        echo '"SNIPPY_CORE": {"status": "skipped", "reason": "insufficient_samples"}' > versions.yml
        exit 0
    fi

    # Run snippy-core to create core SNP alignment
    snippy-core \\
        --ref ${reference} \\
        --prefix core \\
        ${snippy_dirs}

    # Verify core alignment was created
    if [ ! -f "core.aln" ]; then
        echo "ERROR: Snippy-core failed to create alignment" >&2
        exit 1
    fi

    # Count SNPs in core alignment
    SNP_COUNT=\$(grep -v "^>" core.aln | head -1 | wc -c)
    echo "Core SNP alignment created with \$SNP_COUNT positions"
    echo "Samples included: ${dir_count}" >> core.txt

    echo '"SNIPPY_CORE": {"version": "4.6.0", "samples": ${dir_count}}' > versions.yml
    """
}

process SNIPPY_CLEAN_ALIGNMENT {
    tag "clean_core"
    publishDir "${params.outdir}/snippy", mode: 'copy'
    container = 'quay.io/biocontainers/snp-sites:2.5.1--hed695b0_0'

    input:
    path(core_aln)

    output:
    path("core.clean.aln"), emit: clean_alignment
    path("core.snps.aln"), emit: snps_only
    path("snp_statistics.txt"), emit: stats

    script:
    """
    # Remove invariant sites and keep only SNP positions
    snp-sites \\
        -c \\
        -o core.clean.aln \\
        ${core_aln}

    # Extract only SNP sites (no constant/invariant sites)
    snp-sites \\
        -o core.snps.aln \\
        ${core_aln}

    # Count SNPs
    TOTAL_SITES=\$(grep -v "^>" ${core_aln} | head -1 | wc -c)
    SNP_SITES=\$(grep -v "^>" core.snps.aln | head -1 | wc -c)
    INVARIANT_SITES=\$((TOTAL_SITES - SNP_SITES))

    # Write statistics
    echo "SNP Analysis Statistics" > snp_statistics.txt
    echo "======================" >> snp_statistics.txt
    echo "Total alignment length: \$TOTAL_SITES bp" >> snp_statistics.txt
    echo "Variable (SNP) sites: \$SNP_SITES" >> snp_statistics.txt
    echo "Invariant sites: \$INVARIANT_SITES" >> snp_statistics.txt
    echo "SNP density: \$(echo "scale=4; \$SNP_SITES / \$TOTAL_SITES * 100" | bc)%" >> snp_statistics.txt

    echo "✅ Cleaned alignment: \$SNP_SITES SNP sites retained"
    """
}

process SNP_DISTANCE_MATRIX {
    tag "snp_distances"
    publishDir "${params.outdir}/snippy", mode: 'copy'
    container = 'quay.io/biocontainers/snp-dists:0.8.2--h5bf99c6_0'

    input:
    path(snp_alignment)

    output:
    path("snp_distance_matrix.tsv"), emit: matrix
    path("snp_distance_summary.txt"), emit: summary

    script:
    """
    # Calculate pairwise SNP distances
    snp-dists \\
        ${snp_alignment} > snp_distance_matrix.tsv

    # Calculate summary statistics
    echo "SNP Distance Summary" > snp_distance_summary.txt
    echo "===================" >> snp_distance_summary.txt

    # Extract distances (skip header and first column)
    tail -n +2 snp_distance_matrix.tsv | cut -f2- | \\
        awk '{for(i=1;i<=NF;i++) if(\$i>0) print \$i}' | \\
        awk '{
            sum+=\$1;
            count++;
            if(NR==1 || \$1<min) min=\$1;
            if(NR==1 || \$1>max) max=\$1;
        }
        END {
            print "Minimum SNP distance: " min;
            print "Maximum SNP distance: " max;
            print "Average SNP distance: " sum/count;
            print "Total pairwise comparisons: " count;
        }' >> snp_distance_summary.txt

    echo "✅ SNP distance matrix calculated"
    """
}
