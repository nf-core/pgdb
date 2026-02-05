
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CAT_CAT       } from '../../../modules/nf-core/cat/cat/main.nf'
include { PYPGATK_CLEAN } from '../../../modules/local/pypgatk/ensembl_check/main.nf'
include { PYPGATK_DECOY } from '../../../modules/local/pypgatk/generate_decoy/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        RUN MERGEDB WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MERGEDB {

take:

    // inputs from the main workflow
    mixed_databases     //channel: [ [ val(meta), [ database ] ], ... , [ val(meta), database ] ]
    clean_config        //channel: /path/to/clean config
    decoy_config        //channel: /path/to/decoy config
    skip_decoy

main:

    //creates empty channels for tool versions and the decoy database
    versions_ch = Channel.empty()
    decoy       = Channel.empty()

    //creating empty channels used in the mergedb workflow
    flat_databases      = Channel.empty()
    collected_databases = Channel.empty()
    databases           = Channel.empty()

    //this takes the databases generated in the previous workflows and flattens them into a list
    //this is to remove the metadata from each database
    flat_databases = mixed_databases.flatten().filter{it instanceof java.nio.file.Path && it.isFile()}

    //this collects the flattened databases 
    collected_databases = flat_databases.collect()

    //CAT_CAT concatenates all of the databases into a single database
    CAT_CAT (
        collected_databases.map { [ [id: 'final_database'], it ] }
    )
    versions_ch = versions_ch.mix(CAT_CAT.out.versions_cat).collect()
    databases = CAT_CAT.out.file_out.collect()
        .map { meta, it ->
            return [it] }

    //PYPGATK_CLEAN takes the concatenated database and cleans it
    PYPGATK_CLEAN (
        databases.map { [ [id: 'cleaned_database'], it ] },
        clean_config
    )
    databases = PYPGATK_CLEAN.out.clean_database.collect()
    versions_ch = versions_ch.mix(PYPGATK_CLEAN.out.versions).collect()

//conditional execution based on if skip_decoy is true or false
if (!skip_decoy) {

    //PYPGATK_DECOY generates a decoy database from the cleaned database using the decoy_config
    PYPGATK_DECOY (
        databases.map { [ [id: 'Decoy_database'], it ] },
        decoy_config
    )
    versions_ch = versions_ch.mix(PYPGATK_DECOY.out.versions).collect()
    decoy       = PYPGATK_DECOY.out.decoy_database.collect()

}

else {
        //bypass the subworkflow
        log.info "decoy generation skipped."
    }
    //creates an empty channel that will then be populated with the decoy database 

emit:

    // emits to the main workflow
    databases   //channel: [ val(meta), [ database ] ]
    decoy       //channel: [ val(meta), [ decoy ] ] 
    versions_ch //channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/