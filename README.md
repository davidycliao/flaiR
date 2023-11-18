
## <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Library <img src="man/figures/logo.png" align="right" width="180"/>

[![R-MacOS](https://github.com/davidycliao/flaiR/actions/workflows/r_macos.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r_macos.yml)
[![R-ubuntu](https://github.com/davidycliao/flaiR/actions/workflows/r_ubuntu.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r_ubuntu.yaml)
[![R-Windows](https://github.com/davidycliao/flaiR/actions/workflows/r_window.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r_window.yml)

[![R-CMD-Check](https://github.com/davidycliao/flaiR/actions/workflows/r.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r.yml)
[![coverage](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)

<!-- README.md is generated from README.Rmd. Please edit that file -->

<div style="text-align: justify">

`{flaiR}` is an R wrapper for the
[{flairNLP/flair}](https://github.com/flairnlp/flair) library in Python,
designed specifically for R users, especially those in the social
sciences. It provides easy access to the main functionalities of
`{flairNLP}`. Developed by Developed by [Zalando
Research](https://engineering.zalando.com/posts/2018/11/zalando-research-releases-flair.html)
in Berlin, Flair NLP offers intuitive interfaces and exceptional
multilingual support, particularly for various embedding frameworks and
state-of-the-art natural language processing models to analyze your
text, such as named entity recognition, sentiment analysis,
part-of-speech tagging, biomedical data, sense disambiguation, and
classification, with support for a rapidly growing number of languages
in the community. For a comprehensive understanding of the
`{flairNLP/flair}` architecture, you can refer to the research article
‘[Contextual String Embeddings for Sequence
Labeling](https://aclanthology.org/C18-1139.pdf)’ and the official
[manual](https://flairnlp.github.io) written for its Python
implementation.

For R users, {`flairR`} primarily consists of two main components. The
first is wrapper functions in {`flaiR`} built on top of {`reticulate`},
which enables you to interact directly with Python modules in R and
provides seamless support for documents and [tutorial (in
progress)](https://davidycliao.github.io/flaiR/articles/tutorial.html)
in the R community. The {flaiR} package enables R users to leverage
Flair’s capabilities to train their own models using the Flair framework
and state-of-the-art NLP models without the need to interact directly
with Python.

Flair offers a simpler and more intuitive approach for training custom
NLP models compared to using Transformer-based models directly. With
Flair, data loading and preprocessing are streamlined, facilitating the
easy integration of various pre-trained embeddings, including both
traditional and Transformer-based types like BERT. The training process
in Flair is condensed to just a few lines of code, with automatic
handling of fundamental preprocessing steps. Evaluation and optimization
are also made user-friendly with accessible tools. In addition, Flair
NLP provides an easy framework for training language models and is
compatible with HuggingFace.

The following example offers a straightforward introduction on how to
fully train your own model using the Flair framework and import a BERT
model from Hugging Face, and then use that model for predictions. This
example utilizes data from Julia Park’s paper and trains the model using
Transformer-based models via flair NLP through `{flaiR}`.

**Step 1** Split Data into Train and Test Sets with Senetence Object

``` r
# load training data: grandstanding score from Julia Park's paper
library(flaiR)
data(gs_score) 
```

``` r
# load flair functions via flaiR
Sentence <- flair_data()$Sentence
Corpus <- flair_data()$Corpus
TransformerDocumentEmbeddings <- flair_embeddings()$TransformerDocumentEmbeddings
TextClassifier <- flair_models()$TextClassifier
ModelTrainer <- flair_trainers()$ModelTrainer
```

``` r
# split the data
text <- lapply(gs_score$speech, Sentence)
labels <- as.character(gs_score$rescaled_gs)

for (i in 1:length(text)) {
  text[[i]]$add_label("classification", labels[[i]])
}

set.seed(2046)
sample <- sample(c(TRUE, FALSE), length(text), replace=TRUE, prob=c(0.8, 0.2))
train  <- text[sample]
test   <- text[!sample]
```

**Step 2** Preprocess Data and Corpus Object

``` r
corpus <- Corpus(train=train, test=test)
#> 2023-11-18 17:01:15,956 No dev split found. Using 0% (i.e. 282 samples) of the train split as dev data
```

**Step 3** Create Classifier Using Transformer

``` r
document_embeddings <- TransformerDocumentEmbeddings('distilbert-base-uncased', fine_tune=TRUE)
```

``` r
label_dict <- corpus$make_label_dictionary(label_type="classification")
#> 2023-11-18 17:01:17,400 Computing label dictionary. Progress:
#> 2023-11-18 17:01:17,457 Dictionary created for label 'classification' with 2 values: 0 (seen 1335 times), 1 (seen 1199 times)
classifier <- TextClassifier(document_embeddings,
                             label_dictionary=label_dict, 
                             label_type='classification')
```

**Step** 4 Start Training using the Classifier

``` r
trainer <- ModelTrainer(classifier, corpus)
```

Secondly, to facilitate more efficient use for social science research,
{`flairR`} expands {`flairNLP/flair`}’s core functionality for working
with three major functions to extract features in a tidy and fast
format–
[data.table](https://cran.r-project.org/web/packages/data.table/index.html)
in R.

The expanded features (and examples) can be found:

- [**part-of-speech
  tagging**](https://davidycliao.github.io/flaiR/articles/get_pos.html)
- [**named entity
  recognition**](https://davidycliao.github.io/flaiR/articles/get_entities.html)
- [**transformer-based sentiment
  analysis**](https://davidycliao.github.io/flaiR/articles/get_sentiments.html)

In addition, to handle the load on RAM when dealing with larger corpus,
{`flairR`} supports batch processing to handle texts in batches, which
is especially useful when dealing with large datasets, to optimize
memory usage and performance. The implementation of batch processing can
also utilize GPU acceleration for faster computations.

</div>

<br>

### Installation via <u>**`GitHub`**</u>

<div style="text-align: justify">

The installation consists of two parts: First, install [Python
3.7](https://www.python.org/downloads/) or higher, and [R
3.6.3](https://www.r-project.org) or higher. Although we have tested it
on Github Action with R 3.6.2, we strongly recommend installing [R 4.0.0
or above](https://github.com/davidycliao/flaiR/actions/runs/6416611291)
to ensure compatibility between the R environment and {`reticulate`}.
When first installed, {flaiR} automatically creates a virtual
environment named `flair_env` through {reticulate} in R. The purpose of
this is to prevent conflicts with dependencies required by flair that
might arise from other packages installed on your system, and to ensure
that pip can successfully collect all the dependencies needed for Flair
NLP. If there are any issues with the installation, feel free to ask in
the <u>[Discussion](https://github.com/davidycliao/flaiR/discussions)
</u>.

</div>

``` r
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
```

``` r
library(flaiR)
#> flaiR: An R Wrapper for Accessing Flair NLP 0.12
```

<br>

## Contribution and Open Source Support

<div style="text-align: justify">

`{flaiR}` is maintained and developed by [David
Liao](https://davidycliao.github.io) and friends. R developers who want
to contribute to {`flaiR`} are welcome – {`flaiR`} is an open source
project. I warmly invite R users who share similar interests to join in
contributing to this package. Please feel free to shoot me an email to
collaborate on the task. Contributions – whether they be comments, code
suggestions, tutorial examples, or forking the repository – are greatly
appreciated. Please note that the `flaiR` is released with the
[Contributor Code of
Conduct](https://github.com/davidycliao/flaiR/blob/master/CONDUCT.md).
By contributing to this project, you agree to abide by its terms.

The primary communication channel for R users can be found
[here](https://github.com/davidycliao/flaiR/discussions). Please feel
free to share your insights on the
[Discussion](https://github.com/davidycliao/flaiR/discussions) page and
report any issues related to the R interface in the
[Issue](https://github.com/davidycliao/flaiR/issues) section. If the
issue pertains to the actual implementation of Flair in Python, please
submit a pull request to the offical [flair
NLP](https://github.com/flairnlp/flair).

</div>

<br>
