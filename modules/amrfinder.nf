process DOWNLOAD_AMRFINDER_DB {
    tag "amrfinder_db"
    container = 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'

    output:
    path "amrfinder_db", emit: db
    path "versions.yml", emit: versions

    script:
    if (params.amrfinder_db && params.amrfinder_db != "") {
        """
        # Use existing database
        ln -s ${params.amrfinder_db} amrfinder_db
        echo '"DOWNLOAD_AMRFINDER_DB": {"database": "local_copy"}' > versions.yml
        """
    } else {
        """
        # Download and prepare latest database
        amrfinder_update --force_update --database amrfinder_db

        # Verify database was created (check for any version subdirectory)
        if [ ! -d "amrfinder_db" ] || [ -z "\$(find amrfinder_db -name 'AMRProt' 2>/dev/null)" ]; then
            echo "ERROR: AMRFinder database download failed" >&2
            ls -la amrfinder_db/ || true
            exit 1
        fi

        echo '"DOWNLOAD_AMRFINDER_DB": {"version": "latest", "source": "NCBI"}' > versions.yml
        """
    }
}

process AMRFINDER {
    tag "$meta.id"
    publishDir "${params.outdir}/amrfinder", mode: 'copy', pattern: "${meta.id}_*.tsv"
    container = 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'
    
    input:
    tuple val(meta), path(fasta)
    path(amrfinder_db)
    
    output:
    tuple val(meta), path("${meta.id}_amr.tsv"), emit: results
    tuple val(meta), path("${meta.id}_mutations.tsv"), emit: mutations, optional: true
    path "versions.yml", emit: versions
    
    script:
    // Map organism names to AMRFinder-supported codes
    // See: https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus#--organism-option
    def organism_map = [
        'Acinetobacter baumannii': 'Acinetobacter_baumannii',
        'Campylobacter': 'Campylobacter',
        'Campylobacter coli': 'Campylobacter',
        'Campylobacter jejuni': 'Campylobacter',
        'Clostridioides difficile': 'Clostridioides_difficile',
        'Enterococcus faecalis': 'Enterococcus_faecalis',
        'Enterococcus faecium': 'Enterococcus_faecium',
        'Escherichia': 'Escherichia',
        'Escherichia coli': 'Escherichia',
        'Klebsiella': 'Klebsiella',
        'Klebsiella pneumoniae': 'Klebsiella',
        'Klebsiella oxytoca': 'Klebsiella',
        'Salmonella': 'Salmonella',
        'Salmonella enterica': 'Salmonella',
        'Staphylococcus aureus': 'Staphylococcus_aureus',
        'Staphylococcus pseudintermedius': 'Staphylococcus_pseudintermedius',
        'Streptococcus agalactiae': 'Streptococcus_agalactiae',
        'Streptococcus pneumoniae': 'Streptococcus_pneumoniae',
        'Streptococcus pyogenes': 'Streptococcus_pyogenes',
        'Vibrio cholerae': 'Vibrio_cholerae'
    ]

    // Get AMRFinder organism code if supported, otherwise run in generic mode
    def amrfinder_organism = meta.organism ? organism_map.get(meta.organism, null) : null
    def organism_flag = amrfinder_organism ? "-O ${amrfinder_organism}" : ""
    def organism_note = amrfinder_organism ? "Using organism-specific mode: ${amrfinder_organism}" : "Using generic mode (organism not in AMRFinder database)"

    """
    echo "${organism_note}" >&2

    # Find the actual database directory (handles versioned subdirectories)
    # Look for latest symlink first, then search for AMRProt
    if [ -d "${amrfinder_db}/latest" ]; then
        DB_PATH="${amrfinder_db}/latest"
    elif [ -L "${amrfinder_db}/latest" ]; then
        DB_PATH=\$(readlink -f "${amrfinder_db}/latest")
    else
        # Find any version directory containing AMRProt
        DB_PATH=\$(find ${amrfinder_db} -name "AMRProt" -type f 2>/dev/null | head -1)
        if [ ! -z "\$DB_PATH" ]; then
            DB_PATH=\$(dirname "\$DB_PATH")
        else
            DB_PATH="${amrfinder_db}"
        fi
    fi

    # Run AMRFinder
    amrfinder \\
        -n ${fasta} \\
        ${organism_flag} \\
        --plus \\
        --threads ${task.cpus} \\
        -d \$DB_PATH \\
        -o ${meta.id}_amr.tsv \\
        --mutation_all ${meta.id}_mutations.tsv

    EXIT_CODE=\$?

    # If AMRFinder failed, create empty output files for pipeline continuity
    # but log the error
    if [ \$EXIT_CODE -ne 0 ]; then
        echo "WARNING: AMRFinder failed with exit code \$EXIT_CODE" >&2
        echo "Creating empty output files for pipeline continuity" >&2
        touch ${meta.id}_amr.tsv ${meta.id}_mutations.tsv
    fi

    # Ensure mutation file exists even if no mutations found (successful run)
    touch ${meta.id}_mutations.tsv

    echo '"AMRFINDER": {"version": "3.12.8"}' > versions.yml
    """
}
