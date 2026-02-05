#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/proteogenomicsdb
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/proteogenomicsdb
    Website: https://nf-co.re/proteogenomicsdb
    Slack  : https://nfcore.slack.com/channels/proteogenomicsdb
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { DATABASE_GENERATION     } from './workflows/database_generation.nf'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_proteogenomicsdb_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_proteogenomicsdb_pipeline'
include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_proteogenomicsdb_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TODO nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
params.reference = getGenomeAttribute('fasta')
params.annotation = getGenomeAttribute('gtf')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow {

    //
    // WORKFLOW: Run pipeline
    //
    DATABASE_GENERATION (
        //RNASEQDB paramiters
        params.input,
        params.bam_index,       //
        params.reference,       //
        params.annotation,      //
        params.transcripts,     //
        params.custom_config,   //path to the custom_config
        params.dna_config,      //path to the dna_config              
        params.faidx_get_genome_sizes,

        //ENSEMBLDB paramaters
        params.ensembl_downloader_config,   //path to the ensembl_downloader_config
        params.species_id,                  //species id to download from ensembl
        params.ensembl_config,              //path to the ensembl_config
        params.altorfs_config,              //path to the altorfs_config
        params.pseudogenes_config,          //path to the pseudogenes_config
        params.ncrna_config,                //path to the ncrna_config
        
        //COSMICDB paramiters
        params.cosmic_config,   //path to the cosmic_config
        params.username,        //            
        params.password, 
        params.cosmic_genes_url,
        params.cosmic_mutations_url,

        //GENECODEDB paramaters
        params.genecode_transcripts_url,    //
        params.genecode_annotations_url,    //
        params.gnomad_url,                  //
        params.genecode_config,               //path to the gnomad_config
        
        //CBIOPORTALDB paramaters
        params.cbioportal_url,
        params.grch38_url,      //      
        params.cbio_study,
        params.cbio_config,     //path to the cbioportal_config
        
        //MERGEDB paramaters
        params.clean_config,     //
        params.decoy_config,     //path to the decoy_config
        params.additional_database,
        
        //skip options
        params.skip_rnaseqdb,
        params.skip_dnaseq, 
        params.skip_vcf,   
        params.skip_ensembldb, 
        params.skip_proteome,   
        params.skip_ncrna,      
        params.skip_pseudogenes,
        params.skip_altorfs,   
        params.skip_ensembl_vcf,
        params.skip_cosmicdb,   
        params.skip_genecodedb,  
        params.skip_cbioportaldb,
        params.skip_decoy, 
        params.skip_additional_database

    )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.help,
        params.help_full,
        params.show_hidden
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url     
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
