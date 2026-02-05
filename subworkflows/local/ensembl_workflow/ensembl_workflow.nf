
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//modules for downloading databases from ENSEMBL
include { PYPGATK_ENSEMBL_DOWNLOAD } from '../../../modules/local/pypgatk/ensembl_downloader/main.nf'
include { CAT_CAT as CAT_DNA       } from '../../../modules/nf-core/cat/cat/main.nf'

//modules for optional database generation
include { PYPGATKDNA as PYPGATK_NCRNA       } from '../../../modules/local/pypgatk/dnaseq_to_proteindb/main.nf'
include { PYPGATKDNA as PYPGATK_PSEUDOGENES } from '../../../modules/local/pypgatk/dnaseq_to_proteindb/main.nf'
include { PYPGATKDNA as PYPGATK_ALRORFS     } from '../../../modules/local/pypgatk/dnaseq_to_proteindb/main.nf'

//modules for the generation of the main ENSEMBL database
include { CAT_CAT as CAT_VCF  } from '../../../modules/nf-core/cat/cat/main.nf'
include { PYPGATK_VCF         } from '../../../modules/local/pypgatk/vcf_to_proteindb/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        RUN ENSEMBLDB WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ENSEMBLDB {

take:

    //inputs from the main workflow 
    ensembl_downloader_config //channel: /path/to/ensembl downloader config
    species_name              //string: ENSEMBL species ID
    ensembl_config            //channel: /path/to/ensembl config
    altorfs_config            //channel: /path/to/altorfs config
    pseudogenes_config        //channel: /path/to/pseudogenes config
    ncrna_config              //channel: /path/to/ncrna config
    skip_proteome   
    skip_ncrna      
    skip_pseudogenes
    skip_altorfs   
    skip_ensembl_vcf

main:

    //creates empty channels for tool versions and the peptide database
    versions_ch     = Channel.empty()
    mixed_databases = Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        START OF ENSEMBL DOWNLOAD
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

    //creating empty channels used in the ENSEMBL download pathway
    cdna_mixed = Channel.empty()
    total_cdna = Channel.empty()

    //PYPGATK_ENSEMBL uses the ensembl species ID to downloads files from ENSEMBL
    PYPGATK_ENSEMBL_DOWNLOAD (
        ensembl_downloader_config,
        species_name,
        skip_ensembl_vcf
    )
    versions_ch = versions_ch.mix(PYPGATK_ENSEMBL_DOWNLOAD.out.versions).collect()
    cdna_mixed = PYPGATK_ENSEMBL_DOWNLOAD.out.cdna.mix(PYPGATK_ENSEMBL_DOWNLOAD.out.ncrna).collect()
        .map { [ [id: 'Total_cDNA' ], it ] }

    //CAT_DNA concatinates the cdna filed downloaded from ENSEMBL into a single file
    CAT_DNA (
        cdna_mixed
    )
    versions_ch = versions_ch.mix(CAT_DNA.out.versions_cat).collect()
    total_cdna = CAT_DNA.out.file_out.collect()
        .map { meta, it ->
            return [it] }


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        END OF ENSEMBL DOWNLOAD
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        START OF OPTIONAL DATABASE GENERATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//conditional execution based on if skip_proteome is true or false
if (!skip_proteome) {

    //creates an empty channel that will then be populated with the protein files downloaded from ENSEMBL
    reference_proteome = Channel.empty()
    reference_proteome = PYPGATK_ENSEMBL_DOWNLOAD.out.protein.collect()

    //adds the protein files downloaded from ENSEMBL to the mixed database channel
    mixed_databases = mixed_databases.mix(reference_proteome).collect()

}

else {
        //bypass the subworkflow
        log.info "proteome skipped."
    }

//conditional execution based on if skip_ncrna is true or false
if (!skip_ncrna) {

    //PYPGATK_NCRNA takes the total_cdna and the ncrna_config to generate a peptide database
    PYPGATK_NCRNA (
        total_cdna.map { [ [id: 'ncRNA'], it ] },
        ncrna_config
    )
    versions_ch = versions_ch.mix(PYPGATK_NCRNA.out.versions).collect()

    //adds the peptide database generated from ncrna data to the mixed database channel
    mixed_databases = mixed_databases.mix(PYPGATK_NCRNA.out.database).collect()

}

else {
        //bypass the subworkflow
        log.info "ncrna database skipped."
    }

//conditional execution based on if skip_pseudogenes is true or false
if (!skip_pseudogenes) {

    //PYPGATK_PSEUDOGENES takes the total_cdna and the pseudogenes_config to generate a peptide database
    PYPGATK_PSEUDOGENES (
        total_cdna.map { [ [id: 'pseudogenes'], it ] },
        pseudogenes_config
    )
    versions_ch = versions_ch.mix(PYPGATK_PSEUDOGENES.out.versions).collect()

    //adds the peptide database generated from pseudogenes data to the mixed database channel
    mixed_databases = mixed_databases.mix(PYPGATK_PSEUDOGENES.out.database).collect()

}

else {
        //bypass the subworkflow
        log.info "pseudogenes database skipped."
    }

//conditional execution based on if skip_altorfs is true or false
if (!skip_altorfs) {

    //creates an empty channel that will then be populated with the cdna files downloaded from ENSEMBL
    cdna_database = Channel.empty()
    cdna_database = PYPGATK_ENSEMBL_DOWNLOAD.out.cdna.collect()
        .map { [ [id: 'Altorfs_database'], it ] }

    //PYPGATK_ALTORFS takes the cdna files and the altorfs_config to generate a peptide database
    PYPGATK_ALRORFS (
        cdna_database,
        altorfs_config
    )
    versions_ch = versions_ch.mix(PYPGATK_ALRORFS.out.versions).collect()

    //adds the peptide database generated from altorfs data to the mixed database channel
    mixed_databases = mixed_databases.mix(PYPGATK_ALRORFS.out.database).collect()
}

else {
        //bypass the subworkflow
        log.info "altorfs database skipped."
    }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        END OF OPTIONAL DATABASE GENERATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        START OF ENSEMBL VCF DATABASE GENERATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//conditional execution based on if skip_ensembl_vcf is true or false
if (!skip_ensembl_vcf) {

    //creating empty channels used in the ENSEMBL vcf database generation pathway
    ensembl_vcf = Channel.empty()
    total_vcf   = Channel.empty()
    ensembl_gtf = Channel.empty()

    //populates ensembl_vcf with the vcf file downloaded from ENSEMBL
    ensembl_vcf = ensembl_vcf.mix(PYPGATK_ENSEMBL_DOWNLOAD.out.vcf).collect()
        .map { [ [id: 'concatenated_vcf' ], it ] }
    
    //populates ensembl_gtf with the gtf file downloaded from ENSEMBL 
    ensembl_gtf = PYPGATK_ENSEMBL_DOWNLOAD.out.gtf.collect()
        .map { [ [id: 'gtf' ], it ] } 

    //CAT_VCF concatenates the vcf files downloaded from ENSEMBL into a single file 
    CAT_VCF (
        ensembl_vcf
    )
    versions_ch = versions_ch.mix(CAT_VCF.out.versions_cat).collect()
    total_vcf = CAT_VCF.out.file_out.collect()

    //PYPGATK takes the concatenated vcf file, the gtf file, and the 
    //concatenated cDNA along with the ensembl_config to generate a peptide database
    PYPGATK_VCF (
        total_vcf,
        ensembl_gtf,
        total_cdna.map { [ [id: 'ensembl_vcf'], it ] },
        ensembl_config
    )
    versions_ch = versions_ch.mix(PYPGATK_VCF.out.versions).collect()

    //adds the peptide database generated from the vcf file to the mixed database channel
    mixed_databases = mixed_databases.mix(PYPGATK_VCF.out.database).collect()
}

else {
        //bypass the subworkflow
        log.info "ensembl vcf database skipped."
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        END OF MAIN ENSEMBL DATABASE GENERATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


emit:
    
    //emits to the main workflow
    mixed_databases //channel: [ val(meta), [ database ] ]
    versions_ch     //channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/