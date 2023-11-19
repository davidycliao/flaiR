
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

<br>

## Installation via <u>**`GitHub`**</u>

<div style="text-align: justify">

The installation consists of two parts: First, install [Python
3.8](https://www.python.org/downloads/) or higher, and [R
3.6.3](https://www.r-project.org) or higher. Although we have tested it
on Github Action with R 3.6.2, we strongly recommend installing [R 4.0.0
or above](https://github.com/davidycliao/flaiR/actions/runs/6416611291)
to ensure compatibility between the R environment and Python. When first
installed, {`flaiR`} automatically detects whether you have Python 3.8
or higher. If not, it will skip the automatic installation of Python and
flair NLP. In this case, you will need to mannually install it yourself
and reload {`flaiR`} again. If you have Python 3.8 or higher alreadt
installed, the installer of {`flaiR`} will automatically install flair
Python NLP in your global environment. If you are using {reticulate},
{flaiR} will typically assume the **r-reticulate** environment by
default. At the same time, you can use py_config() to check the location
of your environment. Please note that flaiR will directly install flair
NLP in the Python environment that your R is using. This environment can
be adjusted through *RStudio* by navigating to
`Tools -> Global Options -> Python`. If there are any issues with the
installation, feel free to ask in the
<u>[Discussion](https://github.com/davidycliao/flaiR/discussions) </u>.

</div>

``` r
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
```

``` r
library(flaiR)
#> flaiR: An R Wrapper for Accessing Flair NLP 0.13.0
```

<br>

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

Secondly, to facilitate more efficient use for social science research,
{`flairR`} expands {`flairNLP/flair`}’s core functionality for working
with three major functions to extract features in a tidy and fast
format–
[data.table](https://cran.r-project.org/web/packages/data.table/index.html)
in R.

###### **Performing NLP Tasks in R**

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

###### **Training Models with HuggingFace via flaiR**

The following example offers a straightforward introduction on how to
fully train your own model using the Flair framework and import a `BERT`
model from [HuggingFace 🤗](https://github.com/huggingface). This
example utilizes grandstanding score as training data from Julia Park’s
paper (*[When Do Politicians Grandstand? Measuring Message Politics in
Committee
Hearings](https://www.journals.uchicago.edu/doi/abs/10.1086/709147?journalCode=jop&mobileUi=0)*)
and trains the model using Transformer-based models via flair NLP
through `{flaiR}`.

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
#> 2023-11-19 18:09:33,774 No dev split found. Using 0% (i.e. 282 samples) of the train split as dev data
```

**Step 3** Create Classifier Using Transformer

``` r
document_embeddings <- TransformerDocumentEmbeddings('distilbert-base-uncased', fine_tune=TRUE)
```

``` r
label_dict <- corpus$make_label_dictionary(label_type="classification")
#> 2023-11-19 18:09:35,280 Computing label dictionary. Progress:
#> 2023-11-19 18:09:35,328 Dictionary created for label 'classification' with 2 values: 0 (seen 1337 times), 1 (seen 1197 times)
classifier <- TextClassifier(document_embeddings,
                             label_dictionary=label_dict, 
                             label_type='classification')
```

**Step** 4 Start Training

specific computation devices on your local machine.

``` r
classifier$to(flair_device("mps")) 
#> TextClassifier(
#>   (embeddings): TransformerDocumentEmbeddings(
#>     (model): DistilBertModel(
#>       (embeddings): Embeddings(
#>         (word_embeddings): Embedding(30523, 768)
#>         (position_embeddings): Embedding(512, 768)
#>         (LayerNorm): LayerNorm((768,), eps=1e-12, elementwise_affine=True)
#>         (dropout): Dropout(p=0.1, inplace=False)
#>       )
#>       (transformer): Transformer(
#>         (layer): ModuleList(
#>           (0-5): 6 x TransformerBlock(
#>             (attention): MultiHeadSelfAttention(
#>               (dropout): Dropout(p=0.1, inplace=False)
#>               (q_lin): Linear(in_features=768, out_features=768, bias=True)
#>               (k_lin): Linear(in_features=768, out_features=768, bias=True)
#>               (v_lin): Linear(in_features=768, out_features=768, bias=True)
#>               (out_lin): Linear(in_features=768, out_features=768, bias=True)
#>             )
#>             (sa_layer_norm): LayerNorm((768,), eps=1e-12, elementwise_affine=True)
#>             (ffn): FFN(
#>               (dropout): Dropout(p=0.1, inplace=False)
#>               (lin1): Linear(in_features=768, out_features=3072, bias=True)
#>               (lin2): Linear(in_features=3072, out_features=768, bias=True)
#>               (activation): GELUActivation()
#>             )
#>             (output_layer_norm): LayerNorm((768,), eps=1e-12, elementwise_affine=True)
#>           )
#>         )
#>       )
#>     )
#>   )
#>   (decoder): Linear(in_features=768, out_features=2, bias=True)
#>   (dropout): Dropout(p=0.0, inplace=False)
#>   (locked_dropout): LockedDropout(p=0.0)
#>   (word_dropout): WordDropout(p=0.0)
#>   (loss_function): CrossEntropyLoss()
#> )
```

Start the training process using the classifier, which learns from the
data based on the grandstanding score.

``` r
trainer <- ModelTrainer(classifier, corpus)
```

</div>

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
