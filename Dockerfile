FROM rocker/r-ver:latest

# Install minimum required system dependencies
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

# Set virtual environment
ENV VENV_PATH=/opt/venv
RUN python3 -m venv $VENV_PATH && \
    chown -R $USER:$USER $VENV_PATH && \
    echo "RETICULATE_PYTHON=$VENV_PATH/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "options(reticulate.prompt = FALSE)" >> /usr/local/lib/R/etc/Rprofile.site

# Install Python packages
RUN $VENV_PATH/bin/pip install --no-cache-dir torch flair scipy==1.12.0

# Install R packages
RUN R -e "install.packages(c('reticulate', 'remotes'), repos='https://cloud.r-project.org/', dependencies=TRUE)" && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies=TRUE)"

WORKDIR /home/$USER
EXPOSE 8787

USER $USER
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
