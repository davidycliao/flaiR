FROM r-base:latest
LABEL maintainer="Yen-Chieh Liao <davidycliao@gmail.com>"

# 系统依赖
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

# 创建虚拟环境
RUN python3 -m venv /opt/venv

# 安装 Flair
RUN /opt/venv/bin/pip install flair

# 设置 CRAN mirror
RUN echo "options(repos = c(CRAN = 'https://cloud.r-project.org'))" >> /usr/lib/R/etc/Rprofile.site

# 分阶段安装 R 包
RUN R -e "install.packages('remotes')"
RUN R -e "install.packages(c('httr', 'bslib'), dependencies=TRUE)"
RUN R -e "install.packages(c('data.table', 'reticulate', 'curl', 'attempt', 'htmltools', 'stringr'), dependencies=TRUE)"
RUN R -e "install.packages(c('knitr', 'rmarkdown', 'lsa', 'purrr', 'jsonlite', 'ggplot2', 'plotly', 'testthat'), dependencies=TRUE)"

RUN R -e "remotes::install_github('davidycliao/flaiR', force = TRUE)"

CMD ["R"]