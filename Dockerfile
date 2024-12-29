FROM r-base:latest
LABEL maintainer="Yen-Chieh Liao <davidycliao@gmail.com>"

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

# 創建並激活虛擬環境
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 在虛擬環境中安裝 Flair
RUN /opt/venv/bin/pip install --no-cache-dir flair

# 安裝 R 依賴項
RUN R -e "install.packages('remotes')"
RUN R -e "install.packages(c('data.table', 'reticulate', 'curl', 'attempt', 'htmltools', 'stringr'))"
RUN R -e "install.packages(c('knitr', 'rmarkdown', 'lsa', 'purrr', 'jsonlite', 'ggplot2', 'plotly', 'testthat'))"

# 複製 R 套件到容器中
COPY . /usr/src/my_pkg
WORKDIR /usr/src/my_pkg

# 安裝 R 套件
RUN R -e "remotes::install_local(force = TRUE)"

# 清理不必要的文件
RUN rm -rf /usr/src/my_pkg

# 設定預設命令
CMD ["R"]
