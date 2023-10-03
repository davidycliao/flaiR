
## <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>

[![R](https://github.com/davidycliao/flaiR/actions/workflows/r2.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r2.yml)
[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/r.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r.yml)
[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check2.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check2.yml)
[![coverage](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)

<!-- README.md is generated from README.Rmd. Please edit that file -->

<div style="text-align: justify">

`flaiR` is a R wrapper of the FlairNLP for R users, particularly for
social science researchers. It offers streamlined access to the core
features of `FlairNLP` from Python. FlairNLP is an advanced NLP
framework that incorporates the latest techniques developed by the
Humboldt University of Berlin. For a deeper understanding of Flair’s
architecture, refer to the research article ‘[Contextual String
Embeddings for Sequence
Labeling](https://aclanthology.org/C18-1139.pdf)’ and the official
[mannual](https://flairnlp.github.io) in Python.

<br>

**Integrating Modules and Classes from Python’s FlairNLP into R:**

| **Wrapped Functions**                          | **Corresponding Code in Python**                         |
|------------------------------------------------|----------------------------------------------------------|
| `flair_datasets()`                             | `from flair.datasets import *`                           |
| `flair_data.sentence()`                        | `from flair.data import Sentence`                        |
| `flair_nn.classifier_load()`                   | `from flair.nn import Classifier`                        |
| `flair.embeddings.TransformerWordEmbeddings()` | `from flair.embeddings import TransformerWordEmbeddings` |
| `flair_embeddings.WordEmbeddings()`            | `from flair.embeddings import WordEmbeddings`            |
| `segtok_sentence_splitter()`                   | `flair_splitter.SegtokSentenceSplitter`                  |
| `flair_models.sequencetagger()`                | `from flair.models import SequenceTagger`                |

<br>

`flairR` primarily consists of two main components. The first is a
wrapper function built on top of {reticulate}, enabling you to interact
directly with Python modules in R. Secondly, to facilitate more
efficient use for social science research, flairR wraps the Flair NLP
Python to extract features in a tidy and clean format using
[data.table.](https://cran.r-project.org/web/packages/data.table/index.html).
The features currently available in `flairR` include **part-of-speech
tagging**, **transformer-based sentiment analysis**, and **named entity
recognition**.

</div>

<br>

**Effortless Access to Core Tagging Features with flaiR Functions:**

| **The Features**                             | Loader                     | Supported Models                                                                                                        |
|----------------------------------------------|----------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `get_entities()`, `get_entities_batch()`     | `load_tagger_ner()`        | `en` (English), `fr` (French), `da` (Danish), `nl` (Dutch), and more.                                                   |
| `get_pos()`, `get_pos_batch()`               | `load_tagger_pos()`        | `pos` (English POS), `fr-pos` (French POS), `de-pos` (German POS), `nl-pos` (Dutch POS), and more.                      |
| `get_sentiments()`, `get_sentiments_batch()` | `load_tagger_sentiments()` | `sentiment` (English) , `sentiment-fast`(English) , `de-offensive-language` (German offensive language detection model) |

<br>

### Installation via <u>**`GitHub`**</u>

The installation consists of two parts: First, install [Python
3.7](https://www.python.org/downloads/) or higher, and [R
3.6.3](https://www.r-project.org) or higher. Although we have tested it
on Github Action with R 3.6.2, we strongly recommend installing R 4.2.1
to ensure compatibility between the R environment and {`reticulate`}. If
there are any issues with the installation, feel free to ask in the
<u>[Discussion](https://github.com/davidycliao/flaiR/discussions) </u>.

``` r
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
library(flaiR)
```

<!-- ## Example -->
<!-- ### NER with the State-of-the-Art German Pre-trained Model -->
<!-- ```{r} -->
<!-- library(flaiR) -->
<!-- data("de_immigration") -->
<!-- de_immigration <- de_immigration[5,] -->
<!-- tagger_ner <- load_tagger_ner("de-ner") -->
<!-- result <- get_entities(de_immigration$text, -->
<!--                        tagger = tagger_ner, -->
<!--                        show.text_id = FALSE -->
<!--                        ) -->
<!-- ``` -->
<!-- ```{r} -->
<!-- head(result, 5) -->
<!-- ``` -->
<!-- ### Coloring Entities  -->
<!-- ```{r} -->
<!-- highlighted_text <- highlight_text(text = de_immigration$text,  -->
<!--                                    entities_mapping = map_entities(result)) -->
<!-- highlighted_text -->
<!-- ``` -->

<br>

### Citing the Contributions of `Flair`

<div style="text-align: justify">

If you use this tool in academic research, we recommend citing the
research article, [Contextual String Embeddings for Sequence
Labeling](https://aclanthology.org/C18-1139.pdf) from `Flair` research
team.

</div>

    @inproceedings{akbik2018coling,
      title={Contextual String Embeddings for Sequence Labeling},
      author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
      booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
      pages     = {1638--1649},
      year      = {2018}
    }
