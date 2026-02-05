/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COSMIC_DOWNLOAD           } from '../../../modules/local/cosmic_downloader/main.nf'
include { PYPGATK_COSMICDB          } from '../../../modules/local/pypgatk/cosmic_to_proteindb/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        RUN COSMICDB WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow COSMICDB {

take:
    
    //inputs from the main workflow
    cosmic_config                  //channel: /path/to/cosmic config
    username_ch                    //string: COSMIC username
    password_ch                    //string: COSMIC password
    cosmic_url_genes               //string: cosmic genes url
    cosmic_url_mutations           //string: cosmic mutations url

main:

    //creates empty channels for tool versions and the peptide database
    versions_ch     = Channel.empty()
    cosmic_database = Channel.empty()

    //creating empty channels used in the cosmicdb workflow
    cosmic_genes        = Channel.empty()
    cosmic_mutations    = Channel.empty()

    //COSMIC_DOWNLOAD downlownloads data from the COSMIC database
    //by supplying a username, password, and the urls of the files
    COSMIC_DOWNLOAD (
        username_ch,
        password_ch,
        cosmic_url_genes,
        cosmic_url_mutations
    )
    cosmic_genes        = COSMIC_DOWNLOAD.out.cosmic_genes.collect()
    cosmic_mutations    = COSMIC_DOWNLOAD.out.cosmic_mutants.collect()

    //PYPGATK_COSMICDB generates a database using the COSMIC data downloaded
    PYPGATK_COSMICDB ( 
        cosmic_genes.map { [ [:], it ] },
        cosmic_mutations.map { [ [:], it ] },
        cosmic_config
    )   
    versions_ch = versions_ch.mix(PYPGATK_COSMICDB.out.versions).collect()
    cosmic_database = PYPGATK_COSMICDB.out.database.collect()

emit:

    cosmic_database //channel: [ val(meta), [ database ] ]
    versions_ch     //channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/