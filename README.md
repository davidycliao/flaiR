##  <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>

[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check.yaml)
[![coverage](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)


<div style="text-align: justify">


`flaiR` is a R wrapper of the FlairNLP for R users, particularly for social science researchers. It offers streamlined access to the core features of `FlairNLP` from Python. FlairNLP is an advanced NLP framework that incorporates the latest techniques developed by the Humboldt University of Berlin. For a deeper understanding of Flair's architecture, refer to the research article  '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)' and the official [mannual](https://flairnlp.github.io) in Python. The features currently available in `flairR` include __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. `flairR` returns tagging information directly in a data.table format. 



| __The Main Features:__                 | Loader                    | Supported Models                    |
|--------------------------------------------------|---------------------------|------------------------------------------------------------------------|
| `get_entities()`, `get_entities_batch()`         | `load_tagger_ner`         | en(English), fr (French), da (Danish), nl (Dutch), etc.          |
| `get_pos()`, `get_pos_batch()`                   | `load_tagger_pos`         | pos (English POS), fr-pos (French POS), de-pos(German POS), nl-pos (Dutch POS), etc. |
| `get_sentiments()`, `get_sentiments_batch()`     | `load_tagger_sentiments`  | sentiment (English) |





### Installation via `GitHub` 

The installation consists of two parts: First, install [Python 3.7](https://www.python.org/downloads/) or higher, and the [`reticulate`](https://rstudio.github.io/reticulate/) package in R. Additionally, you'll also need [`Anaconda`](Anaconda) to assist `reticulate` in setting up your Python environment via Rstudio, as well as enabling your R to identify the conda environment. 


```
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
library(flaiR)
```

```
 flaiR: An R Wrapper for Accessing Flair NLP Tagging Features      
 Python: 3.11                                           
 Flair: 0.12.2 
```


</div>


### Citing the Contributions of `Flair`

<div style="text-align: justify">

If you use this tool in academic research, we recommend citing the research article, [Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf) from `Flair` research team.

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

