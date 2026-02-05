process PYPGATK_COSMICDB {
    tag "${meta.id}"
    label 'process_medium'
    label 'process_single_thread'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0f/0f734a98d2a7b9c84d988474c7e71aef2b0abb987b36fb83b17d52bec0d3babe/data' :
        'community.wave.seqera.io/library/pypgatk_pip:456a1305c1d65d3a' }"

    input:
    tuple val(meta), path(cosmic_genes)
    tuple val(meta), path(cosmic_mutations)
    path cosmic_config

    output:
    path '*.fa'           , emit: database
    path  "versions.yml"  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def name = "${prefix}.fa"

    """
    pypgatk_cli.py cosmic-to-proteindb \\
        --config_file ${cosmic_config} \\
        --input_mutation ${cosmic_mutations} \\
        --input_genes ${cosmic_genes} \\
        --output_db ${name} \\
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypgatk: \$(pypgatk --version | head -1 | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """

    touch ${prefix}.fa 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypgatk: \$(pypgatk --version | head -1 | cut -d ' ' -f 3)
    END_VERSIONS
    """
}