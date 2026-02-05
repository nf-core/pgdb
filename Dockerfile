FROM nfcore/base:1.13.3
LABEL authors="Husen M. Umer & Yasset Perez-Riverol & Alistair Rice & Hyewll Dunn-Davies" \
      description="Docker image containing all software requirements for the nf-core/proteogenomicsdb pipeline"

# Install the conda environment
COPY environment.yml /
RUN conda env create --quiet -f /environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/nf-core-proteogenomicsdb-2.0.0/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nf-core-proteogenomicsdb-2.0.0 > nf-core-proteogenomcisdb-2.0.0.yml
