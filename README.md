# ![nf-core/pgdb](docs/images/nf-core-pgdb_logo.png)

The ProteoGenomics database generation workflow (**pgdb**) use the [pypgatk](https://github.com/bigbio/py-pgatk) and [nextflow](https://www.nextflow.io/) to create different protein databases for ProteoGenomics data analysis.

[![GitHub Actions CI Status](https://github.com/nf-core/pgdb/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/pgdb/actions)
[![GitHub Actions Linting Status](https://github.com/nf-core/pgdb/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/pgdb/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A520.04.0-brightgreen.svg)](https://www.nextflow.io/)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.4722661-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.4722661)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](https://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/pgdb.svg)](https://hub.docker.com/r/nfcore/pgdb)
[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23pgdb-4A154B?logo=slack)](https://nfcore.slack.com/channels/pgdb)

## Introduction

**nf-core/pgdb** is a bioinformatics pipeline to generate proteogenomics databases. pgdb allows users to create proteogenomics databases using EMSEMBL as the reference proteome database. Three different major databases can be attached to the final proteogenomics database:

* The reference proteome (ENSEMBL Reference proteome)
* Non canonical proteins: pseudo-genes, sORFs, lncRNA.
* Variants: COSMIC, cBioPortal, GENOMAD variants

The pipeline allows to estimate decoy proteins with different methods and attach them to the final proteogenomics database.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

1. Install [`nextflow`](https://nf-co.re/usage/installation)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_

3. Download the pipeline and test it on a minimal dataset with a single command (This run will download the canonical ENSEMBL reference proteome and create proteomics database with it):

    ```bash
    nextflow run nf-core/pgdb -profile test,<docker/singularity/podman/shifter/charliecloud/conda/institute>
    ```

    > Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.

4. Start running your own analysis!

    ```bash
    nextflow run nf-core/pgdb -profile <docker/singularity/podman/conda/institute> --ncrna true --pseudogenes true --altorfs true
    ```

    > This will create a proteogenomics database with the ENSEMBL reference proteome and non canonical proteins like pseudo genes, non coding rnas or alternative open reading frames.

See [usage docs](https://nf-co.re/pgdb/usage) for all of the available options when running the pipeline.

## Pipeline Summary

By default, the pipeline currently performs the following:

![ProteoGenomics Database](/docs/images/pgdb-databases.png)

* Download protein databases from ENSEMBL
* Translate from Genomics Variant databases into ProteoGenomics Databases (`COSMIC`, `GNOMAD`)
* Add to a Reference proteomics database, non-coding RNAs + pseudogenes.
* Compute Decoy for a proteogenomics databases

## Documentation

The nf-core/pgdb pipeline comes with documentation about the pipeline: [usage](https://nf-co.re/pgdb/usage) and [output](https://nf-co.re/pgdb/output).

## Credits

nf-core/pgdb was originally written by Husen M. Umer (EMBL-EBI) & Yasset Perez-Riverol (Karolinska Institute)

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#pgdb` channel](https://nfcore.slack.com/channels/pgdb) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  nf-core/pgdb for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
