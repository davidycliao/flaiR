FROM rocker/r-ver:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    python3-venv \
    libssl-dev \
    gdebi-core \
    wget \
    sudo \
    curl

# Create rstudio user
ARG USER=rstudio
ARG PASSWORD=rstudio123
RUN useradd -m $USER && \
    echo "$USER:$PASSWORD" | chpasswd && \
    adduser $USER sudo && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install RStudio Server
RUN wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    rm rstudio-server-*.deb

# Create and configure Python virtual environment
RUN python3 -m venv /opt/venv && \
    chown -R $USER:$USER /opt/venv && \
    chmod -R 775 /opt/venv  # 添加執行權限

ENV PATH="/opt/venv/bin:$PATH"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"

# Setup R environment config
RUN mkdir -p /usr/local/lib/R/etc && \
    echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "options(reticulate.prompt = FALSE)" >> /usr/local/lib/R/etc/Rprofile.site

# Install Python packages as rstudio user
USER $USER
RUN /opt/venv/bin/pip install --no-cache-dir \
    numpy==1.26.4 \
    scipy==1.12.0 \
    transformers \
    torch \
    flair

# Install R packages
RUN R -e 'install.packages("reticulate", repos="https://cloud.r-project.org/", dependencies=TRUE)' && \
    R -e 'if(require(reticulate)) { \
          Sys.setenv(RETICULATE_PYTHON="/opt/venv/bin/python"); \
          reticulate::use_python("/opt/venv/bin/python", required=TRUE); \
          install.packages("remotes", repos="https://cloud.r-project.org/", dependencies=TRUE); \
          remotes::install_github("davidycliao/flaiR", dependencies=TRUE) \
        }'

WORKDIR /home/$USER
EXPOSE 8787
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
