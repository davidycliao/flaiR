FROM r-base:latest
LABEL maintainer="Yen-Chieh Liao <davidycliao@gmail.com>"

# dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev

# creation of env
RUN python3 -m venv /opt/venv

# Flair
RUN /opt/venv/bin/pip install flair

# CRAN mirror
RUN echo "options(repos = c(CRAN = 'https://cloud.r-project.org'))" >> /usr/lib/R/etc/Rprofile.site

RUN R -e "install.packages('remotes')"
RUN R -e "install.packages(c('httr', 'bslib'), dependencies=TRUE)"
RUN R -e "install.packages(c('data.table', 'reticulate', 'curl', 'attempt', 'htmltools', 'stringr'), dependencies=TRUE)"
RUN R -e "install.packages(c('knitr', 'rmarkdown', 'lsa', 'purrr', 'jsonlite', 'ggplot2', 'plotly', 'testthat'), dependencies=TRUE)"

RUN R -e "remotes::install_github('davidycliao/flaiR', force = TRUE)"

CMD ["R"]
