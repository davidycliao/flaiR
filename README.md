# `flairR`: An R Wrapper for Accessing Flair NLP Tagging Features

This R wrapper, built upon the reticulate architecture, offers streamlined access to the core features of FlairNLP in Python. FlairNLP is an advanced framework incorporating the latest techniques in Natural Language Processing. For a deeper understanding of Flair's training model architecture, please consult the article '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)'. The stable features currently available in `flairR` includes __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. 

The utility of flairR is limited to the pre-trained models provided by _Flair NLP_. `flairR` directly returns the tagging information in a data.table format. To utilize flairR, you need to use reticulate to install the Python flair library in your R environment. It is recommended to install __Python version 3.7 or higher__ for efficient operation of Flair NLP.


### Installation with `remotes`:
```
install.packages("remotes")
remotes::install_github("davidycliao/flair", force = TRUE)
```

```
library(flaiR)
## flaiR: An R Wrapper for Accessing Flair NLP Tagging Features ##
## Using Python:    3.8                                         ##
## Using Flair : 0.12.2                                         ##
```


### Lazy Installation for the Enviroment

`create_flair_env` automatically creates a new conda environment specifically in
the R session, and installs `flair`.

```
create_flair_env()
```

### Or, Install Python `flair` Uisng `reticulate` in R

Use the reticulate package in R to create a conda environment named  `flair_env` 
and install Python's `flair`.

```
reticulate::conda_create("flair_env")  
reticulate::conda_install("flair_env", packages = "flair")  
```




# 
# <br />
# <img src="https://raw.githack.com/yl17124/asmcjr/master/vignettes/book_image.jpg" width="200" align="center" />  
# &nbsp;
# 
# 








##  Cite
```
@inproceedings{akbik2018coling,
  title={Contextual String Embeddings for Sequence Labeling},
  author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
  booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
  pages     = {1638--1649},
  year      = {2018}
}
```


