
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

**flaiR** is an R wrapper for accessing the
[flairNLP/flair](flairNLP/flair) Python library, specifically designed
for R users in social and political science. flaiR provides convenient
access to the main functionalities of flairNLP for training word
embedding-based deep learning models and fine-tune state-of-the-art
transformers hosted on Hugging Face. This is the third-party package in
R maintained by [David Liao](https://davidycliao.github.io), [Stefan
Müller](https://muellerstefan.net) from [Next Generation Energy
Systems](https://www.nexsys-energy.ie) and friends at [Text and Policy
Research Group](https://text-and-policy.com) and [Connected_Politics
Lab](https://www.ucd.ie/connected_politics/) in UCD.

## Installation via <u>**`GitHub`**</u>

<div style="text-align: justify">

**flaiR** runs the Flair NLP backend in Python, thus requiring Python
installation. We have extensively tested flaiR using CI/CD with GitHub
Actions, conducting integration tests across various operating systems.
These tests includes integration between R versions 4.2.1, 4.3.2, and
4.2.0, along with Python 3.9 and 3.10.x. Additionally, the testing
includes environments with PyTorch, Flair NLP, and their dependencies in
both R and Python. For stable usage, we strongly recommend installing
these specific versions.

| OS      | R Versions          | Python Version |
|---------|---------------------|----------------|
| Mac     | 4.3.2, 4.2.0, 4.2.1 | 3.10.x         |
| Mac     | Latest              | 3.9            |
| Windows | 4.0.5               | 3.10.x         |
| Windows | Latest              | 3.9            |
| Ubuntu  | 4.3.2, 4.2.0, 4.2.1 | 3.10.x         |
| Ubuntu  | Latest              | 3.9            |

*[Anaconda](https://github.com/anaconda) or
[miniconda](https://github.com/conda/conda) (highly recommended) is the
best way to manage your working environment. In RStudio, the Python
(conda) environment can easily be managed by the reticulate R package,
or manually changed configuration via Tools -\> Global Options -\>
Python in Rstudio.*

## Tutorial for Finetune Transformers with FlaiR

<div style="text-align: justify">

We use Stefan’s data from as an example. Let’s assume we receive the
data for training from different times. First, suppose you have a
dataset of 1000 entries called . Additionally, we have another 1000
entries in a dataset called . Both subsets are from . We will show how
to fine-tune a transformer model with , and then continue with another
round of fine-tuning using .

``` r
library(flaiR)
```

### Fine-tuning a New Model

<u>**Step 1**</u> Load Necessary Modules from Flair

Load necessary classes from `flair` package.

``` r
# Sentence is a class for holding a text sentence
Sentence <- flair_data()$Sentence

# Corpus is a class for text corpora
Corpus <- flair_data()$Corpus

# TransformerDocumentEmbeddings is a class for loading transformer 
TransformerDocumentEmbeddings <- flair_embeddings()$TransformerDocumentEmbeddings

# TextClassifier is a class for text classification
TextClassifier <- flair_models()$TextClassifier

# ModelTrainer is a class for training and evaluating models
ModelTrainer <- flair_trainers()$ModelTrainer
```

We use purrr to help us split sentences using Sentence from
`flair_data()`, then use map2 to add labels, and finally use `Corpus` to
segment the data.

``` r
library(purrr)

data(cc_muller)
cc_muller_old <- cc_muller[1:1000,]

old_text <- map(cc_muller_old$text, Sentence)
old_labels <- as.character(cc_muller_old$class)

old_text <- map2(old_text, old_labels, ~ {
   
  .x$add_label("classification", .y)
  .x
})
```

``` r
print(length(old_text))
#> [1] 1000
```

``` r
set.seed(2046)
sample <- sample(c(TRUE, FALSE), length(old_text), replace=TRUE, prob=c(0.8, 0.2))
old_train  <- old_text[sample]
old_test   <- old_text[!sample]

test_id <- sample(c(TRUE, FALSE), length(old_test), replace=TRUE, prob=c(0.5, 0.5))
old_test   <- old_test[test_id]
old_dev   <- old_test[!test_id]
```

If you do not provide a development split (dev split) while using Flair,
it will automatically split the training data into training and
development datasets. The test set is used for training the model and
evaluating its final performance, whereas the development set (dev set)
is used for adjusting model parameters and preventing overfitting, or in
other words, for early stopping of the model.

``` r
old_corpus <- Corpus(train = old_train, test = old_test)
```

<u>**Step 3**</u> Load `distilbert` Transformer

``` r
document_embeddings <- TransformerDocumentEmbeddings('distilbert-base-uncased', fine_tune=TRUE)
```

First, `$make_label_dictionary` function is used to automatically create
a label dictionary for the classification task. The label dictionary is
a mapping from label to index, which is used to map the labels to a
tensor of label indices. expcept classifcation task, flair also supports
other label types for training custom model, such as `ner`, `pos` and
`sentiment`. From the cc_muller dataset: Future (seen 423 times),
Present (seen 262 times), Past (seen 131 times)

``` r
old_label_dict <- old_corpus$make_label_dictionary(label_type="classification")
#> 2024-05-01 21:22:38,318 Computing label dictionary. Progress:
#> 2024-05-01 21:22:38,388 Dictionary created for label 'classification' with 4 values: Future (seen 382 times), Present (seen 229 times), Past (seen 112 times)
```

`TextClassifier` is used to create a text classifier. The classifier
takes the document embeddings (importing from
`'distilbert-base-uncased'` from HugginFace) and the label dictionary as
input. The label type is also specified as classification.

``` r
old_classifier <- TextClassifier(document_embeddings,
                                 label_dictionary = old_label_dict, 
                                 label_type='classification')
```

<u>**Step 4**</u> Start Training

`ModelTrainer` is used to train the model.

``` r
old_trainer <- ModelTrainer(model = old_classifier, corpus = old_corpus)
```

``` r
old_trainer$train("muller-campaign-communication",  
                  learning_rate=0.02,              
                  mini_batch_size=8L,              
                  anneal_with_restarts = TRUE,
                  save_final_model=TRUE,
                  max_epochs=1L)   
#> 2024-05-01 21:22:38,446 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:38,447 Model: "TextClassifier(
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
#>   (decoder): Linear(in_features=768, out_features=4, bias=True)
#>   (dropout): Dropout(p=0.0, inplace=False)
#>   (locked_dropout): LockedDropout(p=0.0)
#>   (word_dropout): WordDropout(p=0.0)
#>   (loss_function): CrossEntropyLoss()
#>   (weights): None
#>   (weight_tensor) None
#> )"
#> 2024-05-01 21:22:38,447 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:38,447 Corpus: "Corpus: 723 train + 80 dev + 85 test sentences"
#> 2024-05-01 21:22:38,447 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:38,447 Parameters:
#> 2024-05-01 21:22:38,447  - learning_rate: "0.020000"
#> 2024-05-01 21:22:38,447  - mini_batch_size: "8"
#> 2024-05-01 21:22:38,447  - patience: "3"
#> 2024-05-01 21:22:38,447  - anneal_factor: "0.5"
#> 2024-05-01 21:22:38,448  - max_epochs: "1"
#> 2024-05-01 21:22:38,448  - shuffle: "True"
#> 2024-05-01 21:22:38,448  - train_with_dev: "False"
#> 2024-05-01 21:22:38,448  - batch_growth_annealing: "False"
#> 2024-05-01 21:22:38,448 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:38,448 Model training base path: "muller-campaign-communication"
#> 2024-05-01 21:22:38,448 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:38,448 Device: cpu
#> 2024-05-01 21:22:38,448 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:38,448 Embeddings storage mode: cpu
#> 2024-05-01 21:22:38,448 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:22:41,476 epoch 1 - iter 9/91 - loss 1.21330055 - time (sec): 3.03 - samples/sec: 23.78 - lr: 0.020000
#> 2024-05-01 21:22:44,195 epoch 1 - iter 18/91 - loss 1.07116950 - time (sec): 5.75 - samples/sec: 25.06 - lr: 0.020000
#> 2024-05-01 21:22:46,945 epoch 1 - iter 27/91 - loss 0.96526070 - time (sec): 8.50 - samples/sec: 25.42 - lr: 0.020000
#> 2024-05-01 21:22:49,583 epoch 1 - iter 36/91 - loss 0.87220202 - time (sec): 11.13 - samples/sec: 25.86 - lr: 0.020000
#> 2024-05-01 21:22:52,731 epoch 1 - iter 45/91 - loss 0.79436234 - time (sec): 14.28 - samples/sec: 25.21 - lr: 0.020000
#> 2024-05-01 21:22:55,439 epoch 1 - iter 54/91 - loss 0.76495454 - time (sec): 16.99 - samples/sec: 25.43 - lr: 0.020000
#> 2024-05-01 21:22:58,153 epoch 1 - iter 63/91 - loss 0.78872882 - time (sec): 19.71 - samples/sec: 25.58 - lr: 0.020000
#> 2024-05-01 21:23:00,801 epoch 1 - iter 72/91 - loss 0.76249154 - time (sec): 22.35 - samples/sec: 25.77 - lr: 0.020000
#> 2024-05-01 21:23:03,595 epoch 1 - iter 81/91 - loss 0.74236398 - time (sec): 25.15 - samples/sec: 25.77 - lr: 0.020000
#> 2024-05-01 21:23:06,279 epoch 1 - iter 90/91 - loss 0.71218656 - time (sec): 27.83 - samples/sec: 25.87 - lr: 0.020000
#> 2024-05-01 21:23:06,425 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:06,425 EPOCH 1 done: loss 0.7095 - lr 0.020000
#> 2024-05-01 21:23:07,405 Evaluating as a multi-label problem: False
#> 2024-05-01 21:23:07,413 DEV : loss 0.8366082906723022 - f1-score (micro avg)  0.7625
#> 2024-05-01 21:23:07,416 BAD EPOCHS (no improvement): 0
#> 2024-05-01 21:23:07,416 saving best model
#> 2024-05-01 21:23:09,393 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:12,913 Evaluating as a multi-label problem: False
#> 2024-05-01 21:23:12,919 0.7882   0.7882  0.7882  0.7882
#> 2024-05-01 21:23:12,919 
#> Results:
#> - F-score (micro) 0.7882
#> - F-score (macro) 0.7789
#> - Accuracy 0.7882
#> 
#> By class:
#>               precision    recall  f1-score   support
#> 
#>       Future     0.7321    0.9535    0.8283        43
#>      Present     0.8750    0.5185    0.6512        27
#>         Past     0.9231    0.8000    0.8571        15
#> 
#>     accuracy                         0.7882        85
#>    macro avg     0.8434    0.7573    0.7789        85
#> weighted avg     0.8112    0.7882    0.7771        85
#> 
#> 2024-05-01 21:23:12,920 ----------------------------------------------------------------------------------------------------
#> $test_score
#> [1] 0.7882353
#> 
#> $dev_score_history
#> [1] 0.7625
#> 
#> $train_loss_history
#> [1] 0.7094883
#> 
#> $dev_loss_history
#> [1] 0.8366083
```

### Continue Fine-tuning `muller-campaign-communication` Model with `Additional 2000 Pieces`

Now, we can continue to fine-tune the already fine-tuned model with an
additional 2000 pieces of data. First, let’s say we have another 2000
entries called cc_muller_new. We can fine-tune the previous model with
these 2000 entries. The steps are the same as before. For this case, we
don’t need to split the dataset again. We can use the entire 2000
entries as the training set and use the old_test set to evaluate how
well our refined model performs.

``` r
library(purrr)
cc_muller_new <- cc_muller[1001:3000,]
new_text <- map(cc_muller_new$text, Sentence)
new_labels <- as.character(cc_muller_new$class)

new_text <- map2(new_text, new_labels, ~ {
  .x$add_label("classification", .y)
  .x
})
```

``` r
new_corpus <- Corpus(train=new_text, test=old_test)
```

Load the model (`old_model`) we have already finetuned from previous
stage and let’s fine-tune it with the new data, `new_corpus`.

``` r
old_model <- TextClassifier$load("muller-campaign-communication/best-model.pt")
new_trainer <- ModelTrainer(old_model, new_corpus)
```

``` r
new_trainer$train("new-muller-campaign-communication",
                  learning_rate=0.002, 
                  mini_batch_size=8L,  
                  max_epochs=1L)    
#> 2024-05-01 21:23:16,705 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:16,706 Model: "TextClassifier(
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
#>   (decoder): Linear(in_features=768, out_features=4, bias=True)
#>   (dropout): Dropout(p=0.0, inplace=False)
#>   (locked_dropout): LockedDropout(p=0.0)
#>   (word_dropout): WordDropout(p=0.0)
#>   (loss_function): CrossEntropyLoss()
#>   (weights): None
#>   (weight_tensor) None
#> )"
#> 2024-05-01 21:23:16,706 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:16,706 Corpus: "Corpus: 1800 train + 200 dev + 85 test sentences"
#> 2024-05-01 21:23:16,706 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:16,706 Parameters:
#> 2024-05-01 21:23:16,706  - learning_rate: "0.002000"
#> 2024-05-01 21:23:16,706  - mini_batch_size: "8"
#> 2024-05-01 21:23:16,706  - patience: "3"
#> 2024-05-01 21:23:16,706  - anneal_factor: "0.5"
#> 2024-05-01 21:23:16,707  - max_epochs: "1"
#> 2024-05-01 21:23:16,707  - shuffle: "True"
#> 2024-05-01 21:23:16,707  - train_with_dev: "False"
#> 2024-05-01 21:23:16,707  - batch_growth_annealing: "False"
#> 2024-05-01 21:23:16,707 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:16,707 Model training base path: "new-muller-campaign-communication"
#> 2024-05-01 21:23:16,707 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:16,707 Device: cpu
#> 2024-05-01 21:23:16,707 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:16,707 Embeddings storage mode: cpu
#> 2024-05-01 21:23:16,707 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:23:22,887 epoch 1 - iter 22/225 - loss 0.51337095 - time (sec): 6.18 - samples/sec: 28.48 - lr: 0.002000
#> 2024-05-01 21:23:29,332 epoch 1 - iter 44/225 - loss 0.46051266 - time (sec): 12.62 - samples/sec: 27.88 - lr: 0.002000
#> 2024-05-01 21:23:36,203 epoch 1 - iter 66/225 - loss 0.47663777 - time (sec): 19.50 - samples/sec: 27.08 - lr: 0.002000
#> 2024-05-01 21:23:42,697 epoch 1 - iter 88/225 - loss 0.47514490 - time (sec): 25.99 - samples/sec: 27.09 - lr: 0.002000
#> 2024-05-01 21:23:49,746 epoch 1 - iter 110/225 - loss 0.45787836 - time (sec): 33.04 - samples/sec: 26.63 - lr: 0.002000
#> 2024-05-01 21:23:56,748 epoch 1 - iter 132/225 - loss 0.45039044 - time (sec): 40.04 - samples/sec: 26.37 - lr: 0.002000
#> 2024-05-01 21:24:03,990 epoch 1 - iter 154/225 - loss 0.43331979 - time (sec): 47.28 - samples/sec: 26.06 - lr: 0.002000
#> 2024-05-01 21:24:12,961 epoch 1 - iter 176/225 - loss 0.42440802 - time (sec): 56.25 - samples/sec: 25.03 - lr: 0.002000
#> 2024-05-01 21:24:20,592 epoch 1 - iter 198/225 - loss 0.42189943 - time (sec): 63.88 - samples/sec: 24.79 - lr: 0.002000
#> 2024-05-01 21:24:30,214 epoch 1 - iter 220/225 - loss 0.41358232 - time (sec): 73.51 - samples/sec: 23.94 - lr: 0.002000
#> 2024-05-01 21:24:31,796 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:24:31,796 EPOCH 1 done: loss 0.4092 - lr 0.002000
#> 2024-05-01 21:24:34,438 Evaluating as a multi-label problem: False
#> 2024-05-01 21:24:34,445 DEV : loss 0.37292125821113586 - f1-score (micro avg)  0.87
#> 2024-05-01 21:24:34,448 BAD EPOCHS (no improvement): 0
#> 2024-05-01 21:24:34,449 saving best model
#> 2024-05-01 21:24:36,200 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 21:24:40,425 Evaluating as a multi-label problem: False
#> 2024-05-01 21:24:40,431 0.8706   0.8706  0.8706  0.8706
#> 2024-05-01 21:24:40,431 
#> Results:
#> - F-score (micro) 0.8706
#> - F-score (macro) 0.8779
#> - Accuracy 0.8706
#> 
#> By class:
#>               precision    recall  f1-score   support
#> 
#>       Future     0.8837    0.8837    0.8837        43
#>      Present     0.7931    0.8519    0.8214        27
#>         Past     1.0000    0.8667    0.9286        15
#> 
#>     accuracy                         0.8706        85
#>    macro avg     0.8923    0.8674    0.8779        85
#> weighted avg     0.8755    0.8706    0.8718        85
#> 
#> 2024-05-01 21:24:40,431 ----------------------------------------------------------------------------------------------------
#> $test_score
#> [1] 0.8705882
#> 
#> $dev_score_history
#> [1] 0.87
#> 
#> $train_loss_history
#> [1] 0.409207
#> 
#> $dev_loss_history
#> [1] 0.3729213
```

More R tutorial and documentation see
[here](https://github.com/davidycliao/flaiR).

</div>

<br>

<br>

## Contribution and Open Source

<div style="text-align: justify">

R developers who want to contribute to `flaiR` are welcome – flaiR is an
open source project. I warmly invite R users who share similar interests
to join in contributing to this package. Please feel free to shoot me an
email to collaborate on the task. Contributions – whether they be
comments, code suggestions, tutorial examples, or forking the repository
– are greatly appreciated. Please note that the `flaiR` is released with
the [Contributor Code of
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
