FROM r-base:latest
LABEL maintainer="Yen-Chieh Liao <davidycliao@gmail.com>"
LABEL org.opencontainers.image.description="flaiR: An R Docker Image for Natural Language Processing with Flair. This image includes R, Python with Flair NLP library, and essential dependencies for text analysis. Supports both standard NER and OntoNotes models, with batch processing capabilities."


RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

# 創建虛擬環境
RUN python3 -m venv /opt/venv

# 在虛擬環境中安裝 Flair
RUN /opt/venv/bin/pip install flair

# 安裝 R 依賴項 和 flaiR 包
RUN R -e "install.packages(c('remotes', \
    'data.table', 'reticulate', 'curl', 'attempt', 'htmltools', 'stringr', \
    'knitr', 'rmarkdown', 'lsa', 'purrr', 'jsonlite', 'ggplot2', 'plotly', 'testthat'), \
    repos='https://cloud.r-project.org/')" && \
    R -e "remotes::install_github('davidycliao/flaiR', force = TRUE)"

# 複製你的 R 包源碼到容器中
COPY . /pkg
WORKDIR /pkg

# 從本地安裝套件（如果需要）
# RUN R -e "remotes::install_local('/pkg', force = TRUE)"  # 注释掉这行，因为我们已经从 GitHub 安装了

# 設定預設命令
CMD ["R"]
