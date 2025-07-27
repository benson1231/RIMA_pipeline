FROM bioconductor/bioconductor_docker:RELEASE_3_17

# 安裝 Miniconda（給 Snakemake --use-conda 用）
ENV CONDA_DIR=/home/rstudio/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda clean -afy
ENV PATH="$CONDA_DIR/bin:$PATH"

# Conda 設定與接受 TOS
RUN conda config --set channel_priority strict && \
    conda config --add channels defaults && \
    conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda tos accept --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --channel https://repo.anaconda.com/pkgs/r

# 安裝 Snakemake
RUN pip install --upgrade pip && pip install snakemake pandas pyyaml

# 安裝 CRAN R 套件
RUN R -e "install.packages(c( \
    'ggplot2', 'pheatmap', 'reshape2', 'optparse', 'ggnewscale', 'ggfortify', 'e1071', \
    'vegan', 'ggrepel', 'WGCNA', 'ggpubr', 'data.table', 'beeswarm', 'R.utils', 'tidyverse', \
    'seqinr', 'ape', 'dplyr', 'network', 'ggcorrplot', 'GGally', 'sna', 'corrplot', 'dendextend' \
), repos = 'https://cran.r-project.org')"

# 安裝 Bioconductor R 套件
RUN R -e "BiocManager::install(c( \
    'Biobase', 'DESeq2', 'tximport', 'sva', 'GSVA', 'GSEABase', 'limma', \
    'org.Hs.eg.db', 'clusterProfiler', 'preprocessCore', 'ComplexHeatmap', 'maftools', \
    'chimeraviz', 'ggtree', 'DO.db', 'msa' \
))"
