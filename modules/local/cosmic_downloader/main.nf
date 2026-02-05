process COSMIC_DOWNLOAD {

    label 'process_medium'
    label 'process_single_thread'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c60c36ae45b5244cc9e4eb1353e7bd7380882779bd9ad3673427f2be75237b9/data':
        'community.wave.seqera.io/library/curl:8.18.0--e5bfe1597bbefb59' }"

    input:

        val username
        val password
        val download_url_genes
        val download_url_mutants

    output:
    
    path('cosmic_genes.fasta')     , emit: cosmic_genes            , optional:true
    path('cosmic_mutations.tsv')   , emit: cosmic_mutants          , optional:true
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: ""
    def name   = "${username}"

    """
    download_key_genes=`curl -u ${username}:${password} "${download_url_genes}"`
    curl "\${download_key_genes:8:-2}" --output cosmic_genes.tar
    tar -xvf cosmic_genes.tar
    genes_name=`ls *.fasta.gz`
    mv \$genes_name cosmic_genes.fasta.gz
    gunzip cosmic_genes.fasta.gz

    download_key_mutants=`curl -u ${username}:${password} "${download_url_mutants}"`
    curl "\${download_key_mutants:8:-2}" --output cosmic_mutations.tar
    tar -xf cosmic_mutations.tar
    mutations_name=`ls *.tsv.gz`
    mv \$mutations_name cosmic_mutations.tsv.gz
    gunzip cosmic_mutations.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        curl: \$(curl --version | head -1 | cut -d ' ' -f 2)
    END_VERSIONS

    """

    stub:
    def prefix = task.ext.prefix ?: ""
    
    """
    touch cosmic_genes.fasta
    touch cosmic_mutations.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        curl: \$(curl --version | head -1 | cut -d ' ' -f 2)
    END_VERSIONS

    """
}