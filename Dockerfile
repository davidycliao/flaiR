FROM rocker/r-ver:latest

# Install system dependencies for R packages
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    python3-venv \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    gdebi-core \
    wget \
    sudo \
    curl \
    virtualenv

# Create rstudio user (using ARG instead of ENV for build-time variables)
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

# Set virtual environment path
ENV VENV_PATH=/home/rstudio/flair_env
RUN python3 -m venv $VENV_PATH && \
    chown -R rstudio:rstudio $VENV_PATH

# Update environment variables
ENV PATH="$VENV_PATH/bin:$PATH"
ENV RETICULATE_PYTHON="$VENV_PATH/bin/python"

# Install Python packages
RUN $VENV_PATH/bin/pip install --no-cache-dir \
    numpy==1.26.4 \
    scipy==1.12.0 \
    transformers \
    torch \
    flair

# Install R packages with error checking
RUN Rscript -e 'if (!requireNamespace("reticulate", quietly = TRUE)) { install.packages("reticulate", repos="https://cloud.r-project.org/", dependencies=TRUE) }' && \
    Rscript -e 'if (!requireNamespace("remotes", quietly = TRUE)) { install.packages("remotes", repos="https://cloud.r-project.org/", dependencies=TRUE) }' && \
    Rscript -e 'options(timeout=600); Sys.setenv(RETICULATE_PYTHON=Sys.getenv("VENV_PATH")); tryCatch({ library(reticulate); use_virtualenv(Sys.getenv("VENV_PATH"), required=TRUE); remotes::install_github("davidycliao/flaiR", dependencies=TRUE) }, error=function(e) { message("Error: ", e$message); quit(status=1) })'

# Setup R environment config
RUN mkdir -p /usr/local/lib/R/etc && \
    echo "options(reticulate.prompt = FALSE)" >> /usr/local/lib/R/etc/Rprofile.site && \
    echo "RETICULATE_PYTHON=$VENV_PATH/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    chown -R rstudio:rstudio /usr/local/lib/R/etc

# Set working directory
WORKDIR /home/rstudio
RUN chown -R rstudio:rstudio /home/rstudio

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8787/ || exit 1

# Expose port
EXPOSE 8787

# Run service as rstudio user
USER rstudio
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
