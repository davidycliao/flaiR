##  <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>


<div style="text-align: justify">


flairR is R wrapper, built upon the reticulate architecture, offers streamlined access to the core features of FlairNLP in Python. FlairNLP is an advanced framework of NLP incorporating the latest techniques developed by [Humboldt University of Berlin](https://github.com/flairNLP/flair). For a deeper understanding of Flair's framwork, please find the research article '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)' and the official [mannual](https://flairnlp.github.io). The  features currently available in `flairR` includes __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. 

</div>

## Installation

The installation consists of two parts: First, install Python and `reticulate` in R. Then, use `reticulate` to install `flair` and install `flaiR in R` 


### STEP 1: Install Python `flair` Uisng `reticulate` in R

Use the reticulate package in R to install `flair` in R

```
install.packages("reticulate")
reticulate::use_condaenv("r-reticulate")
reticulate::py_install("flair")
```

### STEP 2: Install `flaiR` from GitHub

```
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
```
```
library(flaiR)
## flaiR: An R Wrapper for Accessing Flair NLP Tagging Features ##
## Using Python:    3.8                                         ##
## Using Flair : 0.12.2                                         ##
```

---


##  Cite the Work of `Flair`
```
@inproceedings{akbik2018coling,
  title={Contextual String Embeddings for Sequence Labeling},
  author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
  booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
  pages     = {1638--1649},
  year      = {2018}
}
```


