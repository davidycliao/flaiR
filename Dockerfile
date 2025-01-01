FROM rocker/r-ver:latest

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev \
    gdebi-core \
    wget \
    sudo

# 安装 RStudio Server
RUN wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    rm rstudio-server-*.deb

# 创建并使用 Python 虚拟环境
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"

# 添加 RETICULATE_PYTHON 到 R 环境配置
RUN echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site

# 安装指定版本的 Python 包
RUN /opt/venv/bin/pip install --no-cache-dir \
    numpy==1.26.4 \
    scipy==1.12.0 \
    transformers \
    torch \
    flair

# 安装 R 包
RUN R -e "install.packages('reticulate', repos='https://cloud.r-project.org/', dependencies=TRUE)" && \
    R -e "install.packages('remotes', repos='https://cloud.r-project.org/', dependencies=TRUE)" && \
    R -e "remotes::install_github('davidycliao/flaiR', dependencies=TRUE)"

# 创建 rstudio 用户和设置密码
ENV USER=rstudio
ENV PASSWORD=rstudio123
RUN useradd -m $USER && \
    echo "$USER:$PASSWORD" | chpasswd && \
    adduser $USER sudo

# 设置工作目录权限
RUN mkdir -p /home/$USER && \
    chown -R $USER:$USER /home/$USER && \
    chown -R $USER:$USER /opt/venv

# 确保 R 环境配置文件的权限正确
RUN chown -R $USER:$USER /usr/local/lib/R/etc/Renviron.site && \
    chmod 644 /usr/local/lib/R/etc/Renviron.site

# 暴露 RStudio Server 端口
EXPOSE 8787

# 启动 RStudio Server
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
