FROM rocker/r-ver:latest

# 設置非互動模式
ENV DEBIAN_FRONTEND=noninteractive

# 系統更新和安裝安全性修補
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    python3-minimal \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev \
    gdebi-core \
    wget \
    sudo \
    psmisc && \  # 添加 psmisc 依賴
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安裝 RStudio Server
RUN apt-get update && \
    wget --no-verbose https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    rm rstudio-server-*.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Python 虛擬環境設置
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"

# 設置 R 環境
RUN echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site

# 安裝更新的 Python 包
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir \
    numpy>=1.26.4 \
    scipy>=1.12.0 \
    transformers \
    torch \
    flair

# 安裝 R 包
RUN install2.r --error --deps TRUE \
    reticulate \
    remotes && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies=TRUE)"

# 使用者設置（移除 ARG PASSWORD）
ENV DEFAULT_USER=rstudio
RUN useradd -m $DEFAULT_USER && \
    adduser $DEFAULT_USER sudo && \
    echo "$DEFAULT_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 設置權限
RUN mkdir -p /home/$DEFAULT_USER && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /opt/venv && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /usr/local/lib/R/etc/Renviron.site && \
    chmod 644 /usr/local/lib/R/etc/Renviron.site

# 清理
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 8787

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
