
<u>`<span style="color:orangered;">flair</span>`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>


<div style="text-align: justify">


flairR is R wrapper, built upon the reticulate architecture, offers streamlined access to the core features of FlairNLP in Python. FlairNLP is an advanced framework of NLP incorporating the latest techniques developed by [Humboldt University of Berlin](https://github.com/flairNLP/flair). For a deeper understanding of Flair's framwork, please find the research article '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)' and the official [mannual](https://flairnlp.github.io). The  features currently available in `flairR` includes __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. 

</div>

## Installation

The installation consists of two parts: First, install [Python 3.7](https://www.python.org/downloads/) or higher, and the reticulate package in R.

### Install `flaiR` from GitHub

```
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
library(flaiR)
```
```
 flaiR: An R Wrapper for Accessing Flair NLP Tagging Features      
 Python : 3.11                                           
 Flair: 0.12.2                                         
 py_config: /xxxx/xxxxxx/.virtualenvs/r-reticulate/bin/python
```


### Lazy Installation from Using `create_flair_env()` from __flaiR__ 

```
create_flair_env()
```

### Or,  Install Python flair Uisng reticulate in R

```
library(reticulate)
reticulate::py_install("flair")
```


### Citing the Contributions of `Flair`

This R wrapper is built upon the work of the `Flair` research team at Humboldt University of Berlin. If you use this tool in academic research, I recommend citing their research article, [Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf).

```
@inproceedings{akbik2018coling,
  title={Contextual String Embeddings for Sequence Labeling},
  author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
  booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
  pages     = {1638--1649},
  year      = {2018}
}
```


