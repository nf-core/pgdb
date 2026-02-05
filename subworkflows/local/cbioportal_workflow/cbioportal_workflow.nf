/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { WGET as WGET_GRCH38 } from '../../../modules/nf-core/wget/main.nf'
include { GUNZIP              } from '../../../modules/nf-core/gunzip/main.nf'
include { CBIOPORTAL_DOWNLOAD } from '../../../modules/local/cbioportal_downloader/main.nf'
include { PYPGATK_CBIOPORTAL  } from '../../../modules/local/pypgatk/cbioportal_to_proteindb/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        RUN CBIOPORTALDB WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CBIOPORTALDB {

take:

    //inputs from the main workflow    
    cbioportal_url       //string: cbioportal study url
    grch38_url           //string: gr38 url
    cbioportal_sample_id //string: cbioportal sample ID
    cbioportal_config    //channel: /path/to/cbioportal config

main:

    //creates empty channels for tool versions and the peptide database
    versions_ch         = Channel.empty()
    cbioportal_database = Channel.empty()

    //creating empty channels used in the cbioportaldb workflow
    grch38_ch       = Channel.empty()
    grch38_unzipped = Channel.empty()
    cbio_samples    = Channel.empty()
    cbio_mutations  = Channel.empty()

    //WGET_GRCH38 takes the link and downloads it off the internet
     WGET_GRCH38 (
        grch38_url.map { [ [id: 'grch38' ], it ] }
    )
    versions_ch = versions_ch.mix(WGET_GRCH38.out.versions).collect()
    grch38_ch = WGET_GRCH38.out.outfile.collect()

    //GUNZIP unzips the file downloaded using WGET_GRCH38 
    GUNZIP(
        grch38_ch
    )
    versions_ch = versions_ch.mix(GUNZIP.out.versions_gunzip).collect()
    grch38_unzipped = GUNZIP.out.gunzip.collect()

    //PYPGATK_CBIOPORTAL_DOWNLOAD downloads the specified samples fromt he cBioPortal database
    CBIOPORTAL_DOWNLOAD (
        cbioportal_url,
        cbioportal_sample_id
    )
    cbio_mutations = CBIOPORTAL_DOWNLOAD.out.cbio_mutations
    cbio_samples = CBIOPORTAL_DOWNLOAD.out.cbio_samples

    //PYPGATK_CBIOPORTAL generates a peptide database using the grch38, mutations, and samples files
    PYPGATK_CBIOPORTAL (
        grch38_unzipped,
        cbio_mutations.map { [ [id: 'cbio_mutations' ], it ] },
        cbio_samples.map { [ [id: 'cbio_samples' ], it ] },
        cbioportal_config
    )
    versions_ch = versions_ch.mix(PYPGATK_CBIOPORTAL.out.versions).collect()
    cbioportal_database = PYPGATK_CBIOPORTAL.out.cbioportal_proteindb.collect()

emit:
    
    //emits to the main workflow 
    cbioportal_database //channel: [ val(meta), [ database ] ]
    versions_ch         //channel: [ path(versions.yml) ]
 
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/