FROM rocker/r-ver:latest

# Install system dependencies and clean up cache
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    python3-venv \
    libssl-dev \
    gdebi-core \
    wget \
    sudo \
    curl \
    pkg-config \
    git \
    cmake \
    build-essential \
    g++ \
    protobuf-compiler \
    libprotobuf-dev \
    autoconf \
    automake \
    libtool \
    # R package compilation dependencies
    libxml2-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    # RStudio Server dependencies
    psmisc \
    lsof \
    libclang-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create rstudio user with sudo privileges
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
    chmod -R 775 /opt/venv

# Set environment variables for Python and reticulate
ENV PATH="/opt/venv/bin:$PATH" \
    RETICULATE_PYTHON="/opt/venv/bin/python"

# Dynamically set PYTHONPATH
RUN PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")') && \
    echo "export PYTHONPATH=\"/opt/venv/lib/python${PYTHON_VERSION}/site-packages\"" >> /etc/environment

# Configure R environment and library permissions
RUN mkdir -p /usr/local/lib/R/etc /usr/local/lib/R/site-library && \
    echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "options(reticulate.prompt = FALSE)" >> /usr/local/lib/R/etc/Rprofile.site && \
    chown -R $USER:$USER /usr/local/lib/R/site-library && \
    chmod -R 775 /usr/local/lib/R/site-library

# Install essential R packages
RUN R -e 'install.packages(c("remotes", "reticulate", "devtools"), repos="https://cloud.r-project.org/", dependencies=TRUE)'

# Install Python packages in virtual environment
RUN /opt/venv/bin/pip install --no-cache-dir \
    'numpy==1.26.4' \
    'scipy==1.12.0' \
    'torch>=2.0.0' \
    'transformers[sentencepiece]>=4.25.0,<5.0.0' \
    'flair>=0.11.3'

# Switch to rstudio user
USER $USER
WORKDIR /home/$USER

# Configure reticulate to use virtual environment Python
RUN R -e 'Sys.setenv(RETICULATE_PYTHON="/opt/venv/bin/python"); \
          reticulate::use_python("/opt/venv/bin/python", required=TRUE)'

# Expose RStudio Server port
EXPOSE 8787

# Switch back to root and start RStudio Server
USER root
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
