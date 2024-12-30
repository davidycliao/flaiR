FROM rocker/r-ver:latest

# 安装系统依赖和 RStudio Server
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev \
    gdebi-core \
    wget

# 安装 RStudio Server
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2023.12.0-369-amd64.deb && \
    gdebi -n rstudio-server-2023.12.0-369-amd64.deb && \
    rm rstudio-server-*.deb

# 创建并使用 Python 虚拟环境
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python 安装
RUN /opt/venv/bin/pip install --no-cache-dir flair

# R 包安装
RUN R -e "install.packages(c('remotes', 'reticulate'))" && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies = FALSE)"

# 暴露 RStudio Server 端口
EXPOSE 8787

# 创建用户
ENV USER=rstudio
ENV PASSWORD=rstudio

# 启动 RStudio Server
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
