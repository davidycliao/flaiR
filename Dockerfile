FROM r-base:latest
LABEL maintainer="Yen-Chieh Liao <davidycliao@gmail.com>"
# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

# 安裝 Python Flair NLP
RUN pip3 install flair

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
