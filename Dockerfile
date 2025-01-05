FROM rocker/r-ver:latest

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
    sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安裝 RStudio Server
RUN wget --progress=dot:giga https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    rm rstudio-server-*.deb

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

# 使用者設置（使用 ARG 而不是 ENV 來處理敏感資訊）
ARG USER=rstudio
ARG PASSWORD=rstudio123
RUN useradd -m $USER && \
    echo "$USER:$PASSWORD" | chpasswd && \
    adduser $USER sudo

# 設置權限
RUN mkdir -p /home/$USER && \
    chown -R $USER:$USER /home/$USER && \
    chown -R $USER:$USER /opt/venv && \
    chown -R $USER:$USER /usr/local/lib/R/etc/Renviron.site && \
    chmod 644 /usr/local/lib/R/etc/Renviron.site

# 清理
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 8787

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
