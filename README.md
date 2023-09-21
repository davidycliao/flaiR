## <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>

[![R](https://github.com/davidycliao/flaiR/actions/workflows/r2.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r2.yml)
[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/r.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r.yml)
[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check2.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check2.yml)
[![coverage](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)

<div style="text-align: justify">


`flaiR` is a R wrapper of the FlairNLP for R users, particularly for social science researchers. It offers streamlined access to the core features of `FlairNLP` from Python. FlairNLP is an advanced NLP framework that incorporates the latest techniques developed by the Humboldt University of Berlin. For a deeper understanding of Flair's architecture, refer to the research article  '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)' and the official [mannual](https://flairnlp.github.io) in Python. The features currently available in `flairR` include __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. `flairR` returns tagging information directly in a data.table format. 



| **The Main Features in R**                   | Loader                   | Supported Models                                                                     |
|----------------------------------------------|--------------------------|--------------------------------------------------------------------------------------|
| `get_entities()`, `get_entities_batch()`     | `load_tagger_ner()`        | en(English), fr (French), da (Danish), nl (Dutch), etc.                              |
| `get_pos()`, `get_pos_batch()`               | `load_tagger_pos()`        | pos (English POS), fr-pos (French POS), de-pos(German POS), nl-pos (Dutch POS), etc. |
| `get_sentiments()`, `get_sentiments_batch()` | `load_tagger_sentiments()` | sentiment (English) , sentiment-fast (English) , de-offensive-language (German offensive language detection model) |



### Installation via `GitHub` 


The installation consists of two parts: First, install[Python3.7](https://www.python.org/downloads/) or higher, and [R version 3.6.3](https://www.r-project.org) or higher.


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

<br>

| **The Main Features in R**                   | Loader                     | Supported Models                                                                      |
|----------------------------------------------|----------------------------|---------------------------------------------------------------------------------------|
| `get_entities()`, `get_entities_batch()`     | `load_tagger_ner()`        | en (English), fr (French), da (Danish), nl (Dutch), etc.                              |
| `get_pos()`, `get_pos_batch()`               | `load_tagger_pos()`        | pos (English POS), fr-pos (French POS), de-pos(German POS), nl-pos (Dutch POS), etc.  |
| `get_sentiments()`, `get_sentiments_batch()` | `load_tagger_sentiments()` | sentiment (English) and                                                               |

<br>

### Installation via `GitHub`
<div style="text-align: justify">


The installation process is two-fold: Firstly, you'll need to install [Python3.7](https://www.python.org/downloads/) or a higher version, as well as R. `flaiR` is built upon the [`reticulate`](https://rstudio.github.io/reticulate/)  to interact with FlairNLP in Python. When installing `flaiR`, it automatically sets up a Python conda environment and installs Flair in Python. If you encounter any installation issues, please feel free to raise them in the [discussion](https://github.com/davidycliao/flaiR/discussions).
</div>

``` r
library(flaiR)
#>  flaiR: An R Wrapper for Accessing Flair NLP Tagging Features 
#>  Python: 3.11
#>  Flair: 0.12.2
```

<br>

### NER with the State-of-the-Art German Pre-trained Model

``` r
data("de_immigration")
de_immigration <- head(de_immigration, 1)
```

``` r
tagger_pos <- flaiR::load_tagger_ner("de-ner")
#> 2023-09-17 05:54:08,193 SequenceTagger predicts: Dictionary with 19 tags: O, S-LOC, B-LOC, E-LOC, I-LOC, S-PER, B-PER, E-PER, I-PER, S-ORG, B-ORG, E-ORG, I-ORG, S-MISC, B-MISC, E-MISC, I-MISC, <START>, <STOP>
```

``` r
results <- get_entities(de_immigration$text, 
                        de_immigration$speaker, tagger_pos, 
                        show.text_id = TRUE,
                        gc.active = FALSE)
```

``` r
head(results, 10)