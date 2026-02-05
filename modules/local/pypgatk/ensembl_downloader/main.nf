process PYPGATK_ENSEMBL_DOWNLOAD {

    label 'process_medium'
    label 'process_single_thread'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0f/0f734a98d2a7b9c84d988474c7e71aef2b0abb987b36fb83b17d52bec0d3babe/data' :
        'community.wave.seqera.io/library/pypgatk_pip:456a1305c1d65d3a' }"

    input:
    path ensembl_downloader_config
    val species_taxonomy
    val skip_ensembl_vcf

    output:

    path "*.pep.all.fa" , emit: protein, optional:true
    path "*cdna.all.fa" , emit: cdna   , optional:true
    path "*ncrna.fa",     emit: ncrna  , optional:true
    path "*.dna*.fa",     emit: fasta  , optional:true
    path "*.gtf",         emit: gtf    , optional:true
    path "*.vcf",         emit: vcf    , optional:true
    path  "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def vcf  = ''
    
    if (skip_ensembl_vcf) {
        vcf = '-sv' 
        }
                
    """
    pypgatk_cli.py ensembl-downloader \\
        --config_file ${ensembl_downloader_config} \\
        --output_directory . \\
        --taxonomy ${species_taxonomy} \\
        -sc ${vcf}
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypgatk: \$(pypgatk --version | head -1 | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    
    """
    touch ensembl.pep.all.fa
    touch ensembl_cdna.all.fa
    touch ensembl_ncrna.fa
    touch ensembl.dna_test.fa
    touch ensembl.gtf
    touch ensembl.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypgatk: \$(pypgatk --version | head -1 | cut -d ' ' -f 3)
    END_VERSIONS
    """
}
