FROM rocker/rstudio:4.4.1

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-minimal \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    sudo \
    pkg-config \
    build-essential \
    g++ \
    cmake \
    protobuf-compiler \
    libprotobuf-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
 && rm -rf /var/lib/apt/lists/*

# ========= 使用者設定 =========
ARG USER=rstudio
ARG PASSWORD=rstudio123
RUN echo "$USER:$PASSWORD" | chpasswd && \
    usermod -aG sudo $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN python3 -m venv /opt/venv && \
    chown -R $USER:$USER /opt/venv && \
    chmod -R 775 /opt/venv

ENV PATH="/opt/venv/bin:${PATH}"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"

RUN mkdir -p /usr/local/lib/R/etc && \
    echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "options(reticulate.prompt = FALSE)" >> /usr/local/lib/R/etc/Rprofile.site

RUN R -e 'install.packages(c("remotes", "reticulate", "devtools"), repos="https://cloud.r-project.org/", dependencies=TRUE)'

# ========= Python 套件安裝 =========
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/venv/bin/pip install --no-cache-dir \
        "numpy==1.26.4" \
        "scipy==1.12.0" \
        "torch>=2.0.0" \
        "transformers[sentencepiece]>=4.25.0,<5.0.0" \
        "flair>=0.11.3"

USER $USER
WORKDIR /home/$USER

RUN R -e 'Sys.setenv(RETICULATE_PYTHON="/opt/venv/bin/python"); reticulate::use_python("/opt/venv/bin/python", required=TRUE); reticulate::py_config()'

EXPOSE 8787

USER root
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]


