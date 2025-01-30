FROM rocker/r-ver:latest

# 系統依賴
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
    g++

# 創建 rstudio 用戶
ARG USER=rstudio
ARG PASSWORD=rstudio123
RUN useradd -m $USER && \
    echo "$USER:$PASSWORD" | chpasswd && \
    adduser $USER sudo && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 安裝 RStudio Server
RUN wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    rm rstudio-server-*.deb

# 創建並配置 Python 虛擬環境
RUN python3 -m venv /opt/venv && \
    chown -R $USER:$USER /opt/venv && \
    chmod -R 775 /opt/venv

# 設置環境變量
ENV PATH="/opt/venv/bin:$PATH"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"
ENV PYTHONPATH="/opt/venv/lib/python3.12/site-packages"

# 設置 R 環境配置
RUN mkdir -p /usr/local/lib/R/etc && \
    echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "options(reticulate.prompt = FALSE)" >> /usr/local/lib/R/etc/Rprofile.site

# 創建並設置 R 庫目錄權限
RUN mkdir -p /usr/local/lib/R/site-library && \
    chown -R $USER:$USER /usr/local/lib/R/site-library && \
    chmod -R 775 /usr/local/lib/R/site-library

# 切換到 root 用戶安裝 Python 包
RUN /opt/venv/bin/pip install --no-cache-dir \
    numpy==1.26.4 \
    scipy==1.12.0 \
    torch>=2.0.0 \
    transformers>=4.30.0 \
    flair>=0.11.3 \
    sentencepiece>=0.1.99

# 切換到 rstudio 用戶安裝 R 包
USER $USER
RUN R -e 'install.packages("reticulate", repos="https://cloud.r-project.org/", dependencies=TRUE)' && \
    R -e 'if(require(reticulate)) { \
          Sys.setenv(RETICULATE_PYTHON="/opt/venv/bin/python"); \
          reticulate::use_python("/opt/venv/bin/python", required=TRUE); \
          install.packages("remotes", repos="https://cloud.r-project.org/", dependencies=TRUE); \
          remotes::install_github("davidycliao/flaiR", dependencies=TRUE) \
        }'

# 設置工作目錄
WORKDIR /home/$USER

# 暴露 RStudio Server 端口
EXPOSE 8787

# 切換回 root 運行 RStudio Server
USER root
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
