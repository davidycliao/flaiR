FROM rocker/r-ver:latest

# 系统依赖
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev

# 创建并使用 Python 虚拟环境
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python 安装
RUN /opt/venv/bin/pip install --no-cache-dir flair

# R 包安装 - 只安装核心依赖
RUN R -e "install.packages(c('remotes', 'reticulate'))" && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies = FALSE)"

CMD ["R"]
