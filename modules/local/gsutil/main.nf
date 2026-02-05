process GSUTIL {
    tag "${meta.id}"
    label 'process_medium'
    label 'process_single_thread'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/d4/d4602617631588087aeabd5baa8849a52aa947bcaaa89769ba12243a8c356d75/data' :
        'community.wave.seqera.io/library/gsutil:5.35--34de676970af02ec' }"

    input:
    tuple val(meta), path(url)

    output:
    tuple val(meta), path("*.vcf.bgz"), emit: vcf
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    gsutil cp \\
     ${url} \\
     ./${prefix}.vcf.bgz \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gsutil: \$(pypgatk --version | head -1 | cut -d ' ' -f 3)
    END_VERSIONS

    """

    stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.vcf.bgz 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gsutil: \$(pypgatk --version | head -1 | cut -d ' ' -f 3)
    END_VERSIONS
    """
}