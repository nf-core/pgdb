
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        IMPORT MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { RNASEQDB        } from '../subworkflows/local/rnaseq_workflow/rnaseq_workflow.nf'
include { ENSEMBLDB       } from '../subworkflows/local/ensembl_workflow/ensembl_workflow.nf'
include { COSMICDB        } from '../subworkflows/local/cosmic_workflow/cosmic_workflow.nf'
include { GENECODEDB      } from '../subworkflows/local/genecode_workflow/genecode_workflow.nf'
include { CBIOPORTALDB    } from '../subworkflows/local/cbioportal_workflow/cbioportal_workflow.nf'
include { MERGEDB         } from '../subworkflows/local/merge_workflow/merge_workflow.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DATABASE_GENERATION {

take:
    //inputs rnaseqdb subworkflow
    bam_file               //channel: /path/to/bam alignment file
    bam_index              //channel: /path/to/bam index file
    reference              //channel: /path/to/reference genome
    annotation             //channel: /path/to/genome annotation
    transcripts            //channel: /path/to/cdna transcripts
    custom_config          //channel: /path/to/custom config file
    dna_config             //channel: /path/to/dna config file
    faidx_get_genome_sizes //boolean: whether FAIDX gets genome sizes

    //inputs for ensembldb subworkflow
    ensembl_downloader_config //channel: /path/to/ensembl downloader config
    species_id                //string: ENSEMBL species ID
    ensembl_config            //channel: /path/to/ensembl config
    altorfs_config            //channel: /path/to/altorfs config
    pseudogenes_config        //channel: /path/to/pseudogenes config
    ncrna_config              //channel: /path/to/ncrna config

    //inputs for cosmicdb subworkflow
    cosmic_config                  //channel: /path/to/cosmic config
    username                       //string: COSMIC username
    password                       //string: COSMIC password 
    cosmic_genes_url               //string: cosmic genes url
    cosmic_mutations_url           //string: cosmic mutations url

    //inuts for genecodedb subworkflow
    genecode_transcripts_url //string: genecode transcripts url
    genecode_annotations_url //string: genecode annotations url
    gnomad_url               //string: gnomad vcf url
    genecode_config          //channel: /path/to/genecode config

    //inputs for cbioportaldb subworkflow 
    cbioportal_url       //string: cbioportal study url
    grch38_url           //string: gr38 url
    cbioportal_sample_id //string: cbioportal sample ID 
    cbioportal_config    //channel: /path/to/cbioportal config

    //inputs for mergedb subworkflow
    clean_config //channel: /path/to/clean config
    decoy_config //channel: /path/to/decoy config

    //input additional database
    additional_database //channel: /path/to/an additional database

    //input skip options
    skip_rnaseqdb
    skip_dnaseq 
    skip_vcf   
    skip_ensembldb 
    skip_proteome   
    skip_ncrna      
    skip_pseudogenes
    skip_altorfs   
    skip_ensembl_vcf
    skip_cosmicdb   
    skip_genecodedb  
    skip_cbioportaldb
    skip_decoy 
    skip_additional_database

main:

    //creates empty channels for tool versions, the peptide database, and the multiqc report
    versions_ch        = Channel.empty()
    mixed_databases_ch = Channel.empty()

    //conditional execution based on if skip_rnaseqdb is true or false
    if (!skip_rnaseqdb) {

        //inputs for the rnaseqdb workflow 
        bam_file_ch            = Channel.fromPath(bam_file)
        bam_index_ch           = Channel.fromPath(bam_index)
        reference_ch           = Channel.fromPath(reference)
        annotation_ch          = Channel.fromPath(annotation)
        transcripts_ch         = Channel.fromPath(transcripts)
        custom_config_ch       = Channel.fromPath(custom_config)
        dna_config_ch          = Channel.fromPath(dna_config)

        //pass the channels into the RNASEQDB subworkflow - this takes rna sequencing data and produce a protein database
        RNASEQDB (
            bam_file_ch,
            bam_index_ch,
            annotation_ch,
            reference_ch,
            custom_config_ch,
            dna_config_ch,
            transcripts_ch,               
            faidx_get_genome_sizes,
            skip_dnaseq, 
            skip_vcf
        )
        //extract tool versions, the peptide database, and the multiqc report from rnaseqdb
        versions_ch        = versions_ch.mix(RNASEQDB.out.versions_ch).collect()
        mixed_databases_ch = mixed_databases_ch.mix(RNASEQDB.out.merged_databases_ch).collect()

    } 

    else {
        //bypass the subworkflow
        log.info "rnaseqdb subworkflow skipped."
    }

    //conditional execution based on if skip_ensembldb is true or false
    if (!skip_ensembldb) {

        //inputs for the ensembldb workflow
        ensembl_downloader_config_ch = Channel.fromPath(ensembl_downloader_config)        
        ensembl_config_ch            = Channel.fromPath(ensembl_config)    
        altorfs_config_ch            = Channel.fromPath(altorfs_config)
        pseudogenes_config_ch        = Channel.fromPath(pseudogenes_config)
        ncrna_config_ch              = Channel.fromPath(ncrna_config)
        species_id_ch                = Channel.from(species_id)

        //pass the channels into the ENSEMBLDB subworkflow - this downloads data FROM ENSEMBL to create a protein database
        ENSEMBLDB (
            ensembl_downloader_config_ch,
            species_id_ch,
            ensembl_config_ch,
            altorfs_config_ch,
            pseudogenes_config_ch,
            ncrna_config_ch,
            skip_proteome,   
            skip_ncrna,      
            skip_pseudogenes,
            skip_altorfs,   
            skip_ensembl_vcf
        )
        //extract tool versions and the peptide database from ensembldb
        versions_ch = versions_ch.mix(ENSEMBLDB.out.versions_ch).collect()
        mixed_databases_ch = mixed_databases_ch.mix(ENSEMBLDB.out.mixed_databases).collect()

    }

    else {
        //bypass the subworkflow
        log.info "ensembldb subworkflow skipped."
    }

    //conditional execution based on if skip_cosmicdb is true or false
    if (!skip_cosmicdb) {
    
        //inputs for the cosmicdb workflow
        cosmic_config         = Channel.fromPath(cosmic_config)
        username_ch           = Channel.from(username) 
        password_ch           = Channel.from(password)
        cosmic_url_genes      = Channel.from(cosmic_genes_url)
        cosmic_url_mutations  = Channel.from(cosmic_mutations_url)

        //pass the channels into the COSMICDB subworkflow - this downloads data FROM COSMIC to create a protein database
        COSMICDB (
            cosmic_config,
            username_ch,
            password_ch,
            cosmic_url_genes,
            cosmic_url_mutations
        )
        //extract tool versions and the peptide database from cosmicdb
        versions_ch = versions_ch.mix(COSMICDB.out.versions_ch).collect()   
        mixed_databases_ch = mixed_databases_ch.mix(COSMICDB.out.cosmic_database).collect()

    }

    else {
        //bypass the subworkflow
        log.info "cosmicdb subworkflow skipped."
    }
    
    //conditional execution based on if skip_genecodedb is true or false
    if (!skip_genecodedb) {

        //inputs for the genecodedb workflow
        genecode_transcripts_url_ch = Channel.from(genecode_transcripts_url)
        genecode_annotations_url_ch = Channel.from(genecode_annotations_url)        
        gnomad_url_ch               = Channel.from(gnomad_url)
        genecode_config_ch          = Channel.fromPath(genecode_config)
        
        //pass the channels into the GENECODEDB subworkflow - this downloads data FROM GENECODE and GNOMAD to create a protein database
        GENECODEDB (
            genecode_transcripts_url_ch,
            genecode_annotations_url_ch,
            gnomad_url_ch,
            genecode_config_ch
        )
        //extract tool versions and the peptide database from genecodedb
        versions_ch = versions_ch.mix(GENECODEDB.out.versions_ch).collect()
        mixed_databases_ch = mixed_databases_ch.mix(GENECODEDB.out.genecode_database).collect()

    }

    else {
        //bypass the subworkflow
        log.info "genecodedb subworkflow skipped."
    }

    //conditional execution based on if skip_cbioportaldb is true or false
    if (!skip_cbioportaldb) {

        //inputs for the cbioportaldb workflow
        cbioportal_url_ch    = Channel.from(cbioportal_url)
        grch38_url_ch        = Channel.from(grch38_url)
        cbioportal_study_ch  = Channel.from(cbioportal_sample_id)
        cbioportal_config_ch = Channel.fromPath(cbioportal_config)
        
        //pass the channels into the CBIOPORTALDB subworkflow - this downloads data FROM CBIOPORTAL to create a protein database
        CBIOPORTALDB (
            cbioportal_url_ch,
            grch38_url_ch,
            cbioportal_study_ch,
            cbioportal_config_ch
        )
        //extract tool versions and the peptide database from cbioportaldb
        versions_ch = versions_ch.mix(CBIOPORTALDB.out.versions_ch).collect()
        mixed_databases_ch = mixed_databases_ch.mix(CBIOPORTALDB.out.cbioportal_database).collect()

    }
    
    else {
        //bypass the subworkflow
        log.info "cbioportaldb subworkflow skipped."
    }

    //conditional execution based on if skip_additional_database is true or false
    if (!skip_additional_database) {

        //create a channel to contain the additional database
        additional_database_ch = Channel.from(additional_database)
            ..map { database ->
            def meta = [ id: 'addtional database' ]
            return [ meta, database ] }
        
        //add additional database to the mixed database channel
        mixed_databases_ch = mixed_databases_ch.mip(additional_database_ch) 

    }

    else {
        //bypass the process
        log.info "additional database skipped."
    }


        //inputs for the mergedb workflow
        clean_config_ch   = Channel.from(clean_config)
        decoy_config_ch   = Channel.fromPath(decoy_config)
        decoy_database_ch = Channel.empty()

    //pass the channels into the MERGEDB subworkflow - this merges all of the databases together
    MERGEDB (
        mixed_databases_ch,
        clean_config_ch,
        decoy_config_ch,
        skip_decoy
    )
        //extract tool versions, the peptide database, and the decoy database from mergedb
    versions_ch = versions_ch.mix(MERGEDB.out.versions_ch).collect()
    mixed_databases_ch = MERGEDB.out.databases.collect()
    decoy_database_ch = MERGEDB.out.decoy.collect()


emit:

    //emit the final files from the workflow
    mixed_databases_ch //channel: [ val(meta), [ database ] ]
    decoy_database_ch  //channel: [ val(meta), [ decoy ] ]
    versions_ch        //channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

