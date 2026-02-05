# nf-core/proteogenomicsdb: Output

## Introduction

This document describes the output produced by the pipeline. The main output of the proteogenomicsdb pipeline is the protein sequence database. Protein databases are use for peptide and protein [identification algorithms](https://pubmed.ncbi.nlm.nih.gov/27975215/). In most of the proteomics experiments, researchers tried to quantified the peptides and proteins using canonical protein databases such as ENSEMBL or UNIPROT.

[Proteogenomics](https://www.nature.com/articles/nmeth.3144) is the field of research at the interface of proteomics and genomics. In this approach, "customized" protein sequence databases generated using genomic and transcriptomic information are used to help identify "novel" peptides (not present in reference/canonical protein sequence databases) from mass spectrometry–based proteomic data; in turn, the proteomic data can be used to provide protein-level evidence of gene expression and to help refine gene models. In recent years, owing to the emergence of new sequencing technologies such as RNA-seq and dramatic improvements in the depth and throughput of mass spectrometry–based proteomics, the pace of proteogenomic research has greatly accelerated.

proteogenomicsdb allows researchers to create custom proteogenomic databses using different sources such as COSMIC, cBioPortal, ENSEMBL variants of gNOMAD.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and aim to create a final protein database by adding different protein sequences depending of the options provided by the user/researcher. The pipeline will handle the download from the different sources and perform the operations in the data like translation from genome and transcript sequences into protein sequences, etc.

The main source of canonical protein sequence in proteogenomicsdb is ENSEMBL. The user can then attach to the proteogenomic database protein vairants from COSMIC or cBioPortal. In addition, the pseudogenes, lncRNAs and other novel translation events can be configure to get novel protein sequences. The main sources of sequences are:

* [Ensembl](#ensembl) - Download the Ensembl databases proteins and add canonical proteins.
* [Ensemblnoncanonical](#ensemblnoncanonical) - ENSEMBL non canonical proteins
* [Variants](#variants) - Add the COSMIC and cPortal variant databases.
* [Decoy](#decoys) - Add decoy proteins to the final database.
* [Output](#output) - Output results including clean databases and decoy generation

## Pipeline modes

### Ensembl

The pipeline will download the the ENSEMBL protein reference proteome, this will be added to the final protein database. The protein database is downloaded from [ENSEMBL FTP](http://www.ensembl.org/info/data/ftp/index.html).

### Ensembl non canonical

The Ensembl non canonical includes the pseudogenes, lncRNAs, etc. The accessions of each type of kind of novel protein is predefined by the [pypgatk tool](https://github.com/bigbio/py-pgatk).

* `ncRNA_ENST00000456688` - non coding RNA transcript.
* `altorf_ENST00000310473` - alternative open reading frame
* `pseudo_ENST00000436135` - pseudo gene translation

### Variants

The COSMIC or cBioPortal variants are downloaded automatically from these resources. The accessions of those proteins are:

* `COSMIC:ANXA3_ENST00000503570:p.A67T:Substitution-Missense` - Accession of the protein includes the position of the amino acid variant.

### Decoy

Decoy can be added to the final database. Decoys accessions are prefix with `DECOY_` by default, but they can be configured by the users.

## Output files

The nf-core/proteogenomicsdb pipeline produces one single output file: `/final_proteinDB.fa` _(or whatever `params.final_database_protein` is set to)_.

This FASTA database includes all of the protein sequences including the reference proteomes, variants, pseudo-genes, etc.

A directory called `pipeline_info` is also created with logs and reports from the pipeline execution.
