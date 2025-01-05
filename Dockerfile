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
ENV USER=rstudio
ENV PASSWORD=rstudio123
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
    chown -R $USER:$USER /opt/venv

ENV PATH="/opt/venv/bin:$PATH"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"

# Setup R environment config
RUN mkdir -p /usr/local/lib/R/etc && \
    echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    chown -R $USER:$USER /usr/local/lib/R/etc/Renviron.site && \
    chmod 644 /usr/local/lib/R/etc/Renviron.site

# Install Python packages
RUN /opt/venv/bin/pip install --no-cache-dir \
    numpy==1.26.4 \
    scipy==1.12.0 \
    transformers \
    torch \
    flair

# Install R packages
RUN R -e "install.packages('reticulate', repos='https://cloud.r-project.org/', dependencies=TRUE)" && \
    R -e "install.packages('remotes', repos='https://cloud.r-project.org/', dependencies=TRUE)" && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies=TRUE)"

# Set working directory
WORKDIR /home/$USER
RUN chown -R $USER:$USER /home/$USER

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8787/ || exit 1

# Expose port
EXPOSE 8787

# Run service as rstudio user
USER $USER
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]

