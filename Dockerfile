FROM rocker/r-ver:latest

# 系统依赖 - 只安装必要的
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    libcurl4-openssl-dev \
    libssl-dev

# Python 安装
RUN pip3 install --no-cache-dir flair

# R 包安装 - 只安装核心依赖
RUN R -e "install.packages(c('remotes', 'reticulate'))" && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies = FALSE)"

CMD ["R"]
