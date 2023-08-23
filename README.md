# `flairR`: An R Wrapper for Accessing Flair NLP Tagging Features

This R wrapper, built upon the reticulate architecture, offers streamlined access to the core features of FlairNLP in Python. FlairNLP is an advanced framework incorporating the latest techniques in Natural Language Processing. For a deeper understanding of Flair's training model architecture, please consult the article '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)'. The stable features currently available in `flairR` includes __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. 

The utility of flairR is limited to the pre-trained models provided by _Flair NLP_. `flairR` directly returns the tagging information in a data.table format. To utilize flairR, you need to use reticulate to install the Python flair library in your R environment. It is recommended to install __Python version 3.7 or higher__ for efficient operation of Flair NLP.


## Installation
"The installation consists of two parts: First, install Python and then download the package. Create an environment within the R setting and interface with Flair.

### Get Started with `remotes`:

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

## Quick Use

### Tagging Parts-of-Speech with Flair Models
Load the pretrained model "pos-fast". For more pretrained models, see https://flairnlp.github.io/docs/tutorial-basics/part-of-speech-tagging#-in-english.

```
library(reticulate)
library(data.table)
texts <- c("UCD is one of the best university in Ireland. ", 
           "UCD is good and a bit less better than Trinity.",
           "Essex is famous in social science research",
           "Essex is not in Russell Group but it is not bad in politics", 
           "TCD is the oldest one in Ireland.",
           "TCD in less better than Oxford")
doc_ids <- c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6")
tagger_pos = import("flair.nn")$Classifier$load('pos-fast')
results <- get_pos(texts, doc_ids, tagger_pos)
print(results)
```

<br />
<img src="https://raw.githack.com/davidycliao/flaiR/main/inst/figures/pos.png" width="1000" align="center" />
&nbsp;




### Tagging Entities with Flair Models
Load the pretrained model "ner". For more pretrained models, see https://flairnlp.github.io/docs/tutorial-basics/tagging-entities.

```
library(reticulate)
library(data.table)
tagger_ner = import("flair.nn")$Classifier$load('ner')
results <- get_entities(texts, doc_ids, tagger_ner)
print(results)
```

<br />
<img src="https://raw.githack.com/davidycliao/flaiR/main/inst/figures/ent.png" width="1000" align="center" />
&nbsp;





### Tagging Sentiment 
Load the pretrained model "sentiment".  The pre-trained models of "sentiment", "sentiment-fast", and "de-offensive-language" are currently available. For more pretrained models, see https://flairnlp.github.io/docs/tutorial-basics/tagging-sentiment.

```
library(reticulate)
library(data.table)
tagger_ner = import("flair.nn")$Classifier$load('sentiment')
results <- get_sentiments(texts, doc_ids, tagger_sent)
print(results)
```


<br />
<img src="https://raw.githack.com/davidycliao/flaiR/main/inst/figures/sent.png" width="1000" align="center" />
&nbsp;



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


