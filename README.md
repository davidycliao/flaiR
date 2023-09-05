##  <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>

[![coverage](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)


___The improved version will be updated in the beta 0.0.2.___

<div style="text-align: justify">


`flairR` is R wrapper, built upon the reticulate architecture, offers streamlined access to the core features of FlairNLP in Python. FlairNLP is an advanced framework of NLP incorporating the latest techniques developed by [Humboldt University of Berlin](https://github.com/flairNLP/flair). For a deeper understanding of Flair's framwork, please find the research article '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)' and the official [mannual](https://flairnlp.github.io). The  features currently available in `flairR` includes __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. The `flairR` returns the tagging information directly in a data.table format. Note that using the transformed base NLP toolkit can be computationally intensive. Therefore, implementing parallel computing is advised to enhance the performance of NLP tasks.



### Installation via `GitHub` 


This package is built on top of the [`reticulate`](https://rstudio.github.io/reticulate/) and incorporates key features of the Flair library, returning data in a tidy and efficient[`data.table`](https://cran.r-project.org/web/packages/data.table/index.html) format. The installation consists of two parts: First, install [Python 3.7](https://www.python.org/downloads/) or higher, and the [`reticulate`](https://rstudio.github.io/reticulate/) package in R. Additionally, you'll also need [`Anaconda`](Anaconda) to assist `reticulate` in setting up your Python environment via Rstudio, as well as enabling your R to identify the conda environment. 



```
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
library(flaiR)
```

```
 flaiR: An R Wrapper for Accessing Flair NLP Tagging Features      
 Python : 3.11   
```


</div>


### Citing the Contributions of `Flair`

<div style="text-align: justify">

This R wrapper is built upon the work of the `Flair` research team at Humboldt University of Berlin. If you use this tool in academic research, we recommend citing their research article, [Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf).

</div>

```
@inproceedings{akbik2018coling,
  title={Contextual String Embeddings for Sequence Labeling},
  author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
  booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
  pages     = {1638--1649},
  year      = {2018}
}
```

