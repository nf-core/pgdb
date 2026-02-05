/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//modules involved in the generation of a database from a DNA sequence
include { STRINGTIE_STRINGTIE } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/nf-core/stringtie/stringtie/main.nf'
include { SAMTOOLS_FAIDX      } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/nf-core/samtools/faidx/main.nf'
include { GFFCOMPARE          } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/nf-core/gffcompare/main.nf'
include { GFFREAD             } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/nf-core/gffread/main.nf'
include { PYPGATKDNA          } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/local/pypgatk/dnaseq_to_proteindb/main.nf'

//modules involved in the generation of a database from a VCF file
include { FREEBAYES            } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/nf-core/freebayes/main.nf'
include { GUNZIP as GUNZIP_VCF } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/nf-core/gunzip/main.nf'
include { PYPGATK_VCF         } from '/exports/eddie/scratch/s2215490/proteogenomicsdb/modules/local/pypgatk/vcf_to_proteindb/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RNASEQDB {

take:

    //inputs from the main workflow
    bam
    bai
    annotation             //channel: /path/to/genome annotation
    reference              //channel: /path/to/reference genome
    config                 //channel: /path/to/custom config file
    dna_config             //channel: /path/to/dna config file
    cdna                   //channel: /path/to/cdna transcripts
    faidx_get_genome_sizes //boolean: whether FAIDX gets genome sizes
    skip_dnaseq
    skip_vcf

main:

    merged_databases_ch = Channel.empty()
    versions_ch         = Channel.empty()
    
    fasta_fai_ch        = Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        START OF THE DNA DATABASE GENERATION PATHWAY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

    bam.map { bam ->
    def meta = [id: "bam" ]
    return [meta, bam ]
    }
    .set { bam_sorted_ch }
    .collect()

    annotation.map { genome ->
        def meta = [ id: 'Genome' ]
        return [ meta, genome ] }
    .set { annotation_ch}
    .collect()

    //applies a map to the genome reference

    reference.map { genome ->
        def meta = [ id: 'genome' ]
        return [ meta, genome ] }
    .set{ reference_ch }
    .collect()

    //SAMTOOLS_FAIDX takes the reference genome (fasta) 
    //and generates a fasta index file (fai)
    SAMTOOLS_FAIDX (
        reference_ch,
        [ [], [] ],
        false  
    )
    versions_ch = versions_ch.mix(SAMTOOLS_FAIDX.out.versions_samtools)
    fasta_fai_ch = SAMTOOLS_FAIDX.out.fai.collect()

//conditional execution based on if skip_dnaseq is true or false
if (!skip_dnaseq) {

    //creating empty channels used in the dna database generation pathway
    stringtie_gtf_ch        = Channel.empty()
    gffcompare_ch           = Channel.empty()
    gffout                  = Channel.empty()

    //STRINGTIE is taking the genome annotation and the HISAT2 Bam file 
    //to assemble the RNA-seq alignments into a potential transcript
    STRINGTIE_STRINGTIE (
        bam_sorted_ch,
        annotation
    )
    versions_ch = versions_ch.mix(STRINGTIE_STRINGTIE.out.versions_stringtie)
    stringtie_gtf_ch = STRINGTIE_STRINGTIE.out.transcript_gtf

    //cerates an empty channel that will combine the 
    //genome fasta and genome fasta index channels
    fasta_meta_fai_ch = Channel.empty()
    fasta_meta_fai_ch = reference_ch.combine(fasta_fai_ch)
        .map { map1, fasta, map2, fai ->
            def meta = [ id: 'fasta', description: 'Genome FASTA with index' ]
            return [ meta, fasta, fai ] }


    //GFFCOMPARE is taking the genome fasta, genome annotation, and the 
    //output of StringTie to evaluate the assembly
    GFFCOMPARE (
        stringtie_gtf_ch,
        fasta_meta_fai_ch,
        annotation_ch
    )
    versions_ch = versions_ch.mix(GFFCOMPARE.out.versions)
    gffcompare_ch = GFFCOMPARE.out.annotated_gtf.collect()
            .map { meta, gtf_file ->
            def meta1 = [ id: 'gtf_file', single_end:true ]
            return [ meta1, gtf_file ] }

    //GFFREAD takes the GFFCOMPARE output (gtf) and using 
    //the reference genome converts it into transcript sequences
    GFFREAD (
        gffcompare_ch,
        reference
    )
    versions_ch = versions_ch.mix(GFFREAD.out.versions_gffread)
    gffout = GFFREAD.out.gffread_fasta.collect()

    //PYPGATK takes the GFFREAD output (FASTA) and using the dna_config 
    //file generates a database from the fasta transcripts 
    PYPGATKDNA (
        gffout,
        dna_config
    )
    versions_ch = versions_ch.mix(PYPGATKDNA.out.versions)

    //adds the DNA database to the merged_databases_ch
    merged_databases_ch = merged_databases_ch.mix(PYPGATKDNA.out.database).collect()

}

else {
        //bypass the subworkflow
        log.info "rna-seq dna database skipped."
    }
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        END OF THE DNA DATABASE GENERATION PATHWAY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        START OF THE VCF DATABASE GENERATION PATHWAY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//conditional execution based on if skip_vcf is true or false
if (!skip_vcf) {
        
    genome_bam_bai_ch = Channel.empty()
    freebayes_ch      = Channel.empty()

    //combines the bam and bam index files into a single channel
    genome_bam_bai_ch = bam_sorted_ch.combine(bai)
        .map { meta, bam, bai ->
            return [ meta, bam, bai, [], [], [] ] }

    //FREEBAYES takes the bam, bam index, and fasta index files to generate a vcf file 
    FREEBAYES (
    genome_bam_bai_ch,
    reference_ch,
    fasta_fai_ch,
    [ [], [] ],
    [ [], [] ],
    [ [], [] ]
    )
    versions_ch = versions_ch.mix(FREEBAYES.out.versions)
    freebayes_ch = FREEBAYES.out.vcf.collect()

    //GUNZIP_VCF unzips the vcf file generated by FREEBAYES
    GUNZIP_VCF (
        freebayes_ch
    )
    versions_ch = versions_ch.mix(GUNZIP_VCF.out.versions_gunzip)

    //creates an empty channel that will be populated with the unzipped vcf file generated by FREEBAYES
    vcf_unzipped = Channel.empty()
    vcf_unzipped = GUNZIP_VCF.out.gunzip.collect()

    //applies a map to the cdna file
    cdna.map { genome ->
        def meta = [ id: 'cdna' ]
        return [ meta, genome ] }
    .set{ cdna_ch }
    .collect()

    //PYPGATKCUSTOM takes the vcf file generated by FREEBAYES and using cdna 
    //transcripts and the genome annotation it generates a variant peptide database
    PYPGATK_VCF (
        vcf_unzipped,
        annotation_ch,
        cdna_ch,
        config
    )
    versions_ch = versions_ch.mix(PYPGATK_VCF.out.versions)

    //takes the database generated with PYPGATK and combines it with the other database
    merged_databases_ch = merged_databases_ch.mix(PYPGATK_VCF.out.database).collect()

}

else {
    //bypass the subworkflow
    log.info "rna-seq vcf database skipped."
}

/*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        END OF THE VCF DATABASE GENERATION PATHWAY
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

emit:

    //emits to the main workflow
    merged_databases_ch //channel: [ val(meta), [ database ] ]
    versions_ch         //channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/