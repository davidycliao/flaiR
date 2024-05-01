
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

We use Stefan’s data from *The Temporal Focus of Campaign Communication
(JOP 2022)* as an example. First, suppose we have a dataset of 1000
entries called `cc_muller_old.` Additionally, we have another 1000
entries in a dataset called `cc_muller_new`. The both subset from
`data(cc_muller)` We will fine-tune a transformer model with each
dataset respectively, and then continue with another round of
fine-tuning using the new data.

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
#> 2024-05-01 12:39:39,356 Computing label dictionary. Progress:
#> 2024-05-01 12:39:39,402 Dictionary created for label 'classification' with 4 values: Future (seen 391 times), Present (seen 226 times), Past (seen 106 times)
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

specific computation devices on your local machine. If you have a GPU,
you can use `flair_gpu` to specify the GPU device. If you don’t have a
GPU, you can use `flaiR::flair_device` to specify the CPU device.

``` r
old_classifier$to(flair_device("cpu")) 
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
#>   (decoder): Linear(in_features=768, out_features=4, bias=True)
#>   (dropout): Dropout(p=0.0, inplace=False)
#>   (locked_dropout): LockedDropout(p=0.0)
#>   (word_dropout): WordDropout(p=0.0)
#>   (loss_function): CrossEntropyLoss()
#> )
```

`ModelTrainer` is used to train the model, which learns from the data
based on the grandstanding score.

``` r
old_trainer <- ModelTrainer(old_classifier, old_corpus)
```

``` r
old_trainer$train("muller-campaign-communication",  
                  learning_rate=0.02,              
                  mini_batch_size=8L,              
                  anneal_with_restarts = TRUE,
                  save_final_model=TRUE,
                  max_epochs=1L)   
#> 2024-05-01 12:39:39,466 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:39,467 Model: "TextClassifier(
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
#> 2024-05-01 12:39:39,467 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:39,467 Corpus: "Corpus: 723 train + 80 dev + 85 test sentences"
#> 2024-05-01 12:39:39,467 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:39,467 Parameters:
#> 2024-05-01 12:39:39,467  - learning_rate: "0.020000"
#> 2024-05-01 12:39:39,467  - mini_batch_size: "8"
#> 2024-05-01 12:39:39,467  - patience: "3"
#> 2024-05-01 12:39:39,467  - anneal_factor: "0.5"
#> 2024-05-01 12:39:39,467  - max_epochs: "1"
#> 2024-05-01 12:39:39,468  - shuffle: "True"
#> 2024-05-01 12:39:39,468  - train_with_dev: "False"
#> 2024-05-01 12:39:39,468  - batch_growth_annealing: "False"
#> 2024-05-01 12:39:39,468 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:39,468 Model training base path: "muller-campaign-communication"
#> 2024-05-01 12:39:39,468 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:39,468 Device: cpu
#> 2024-05-01 12:39:39,468 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:39,468 Embeddings storage mode: cpu
#> 2024-05-01 12:39:39,468 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:39:42,547 epoch 1 - iter 9/91 - loss 1.20670470 - time (sec): 3.08 - samples/sec: 23.38 - lr: 0.020000
#> 2024-05-01 12:39:45,791 epoch 1 - iter 18/91 - loss 1.05274305 - time (sec): 6.32 - samples/sec: 22.78 - lr: 0.020000
#> 2024-05-01 12:39:48,543 epoch 1 - iter 27/91 - loss 0.92276317 - time (sec): 9.07 - samples/sec: 23.80 - lr: 0.020000
#> 2024-05-01 12:39:51,253 epoch 1 - iter 36/91 - loss 0.85964204 - time (sec): 11.78 - samples/sec: 24.44 - lr: 0.020000
#> 2024-05-01 12:39:54,803 epoch 1 - iter 45/91 - loss 0.77357004 - time (sec): 15.33 - samples/sec: 23.48 - lr: 0.020000
#> 2024-05-01 12:39:57,653 epoch 1 - iter 54/91 - loss 0.74820041 - time (sec): 18.18 - samples/sec: 23.76 - lr: 0.020000
#> 2024-05-01 12:40:00,599 epoch 1 - iter 63/91 - loss 0.76554066 - time (sec): 21.13 - samples/sec: 23.85 - lr: 0.020000
#> 2024-05-01 12:40:03,366 epoch 1 - iter 72/91 - loss 0.75452504 - time (sec): 23.90 - samples/sec: 24.10 - lr: 0.020000
#> 2024-05-01 12:40:06,259 epoch 1 - iter 81/91 - loss 0.72694120 - time (sec): 26.79 - samples/sec: 24.19 - lr: 0.020000
#> 2024-05-01 12:40:08,930 epoch 1 - iter 90/91 - loss 0.71362353 - time (sec): 29.46 - samples/sec: 24.44 - lr: 0.020000
#> 2024-05-01 12:40:09,057 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:09,057 EPOCH 1 done: loss 0.7118 - lr 0.020000
#> 2024-05-01 12:40:09,995 Evaluating as a multi-label problem: False
#> 2024-05-01 12:40:10,003 DEV : loss 0.7796289324760437 - f1-score (micro avg)  0.7625
#> 2024-05-01 12:40:10,005 BAD EPOCHS (no improvement): 0
#> 2024-05-01 12:40:10,005 saving best model
#> 2024-05-01 12:40:11,845 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:15,597 Evaluating as a multi-label problem: False
#> 2024-05-01 12:40:15,604 0.8235   0.8235  0.8235  0.8235
#> 2024-05-01 12:40:15,604 
#> Results:
#> - F-score (micro) 0.8235
#> - F-score (macro) 0.8211
#> - Accuracy 0.8235
#> 
#> By class:
#>               precision    recall  f1-score   support
#> 
#>       Future     0.7959    0.9070    0.8478        43
#>      Present     0.8000    0.7407    0.7692        27
#>         Past     1.0000    0.7333    0.8462        15
#> 
#>     accuracy                         0.8235        85
#>    macro avg     0.8653    0.7937    0.8211        85
#> weighted avg     0.8332    0.8235    0.8226        85
#> 
#> 2024-05-01 12:40:15,604 ----------------------------------------------------------------------------------------------------
#> $test_score
#> [1] 0.8235294
#> 
#> $dev_score_history
#> [1] 0.7625
#> 
#> $train_loss_history
#> [1] 0.7117981
#> 
#> $dev_loss_history
#> [1] 0.7796289
```

### Continue Fine-tuning `muller-campaign-communication` Model with `Additional 2000 Pieces`

Now, we can continue to fine-tune the already fine-tuned model with an
additional 2000 pieces of data. First, we need to create a new corpus
with cc_muller_new. The steps are the same as before.

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
set.seed(2046)
new_corpus <- Corpus(train=new_text, test=old_test)
```

Load the model (`old_model`) we have already trained and let’s fine-tune
it using the new data.

``` r
old_model <- TextClassifier$load("muller-campaign-communication/best-model.pt")
new_trainer <- ModelTrainer(old_model, new_corpus)
```

``` r
new_trainer$train("new-muller-campaign-communication",
                  learning_rate=0.002, 
                  mini_batch_size=8L,  
                  max_epochs=1L)      
#> 2024-05-01 12:40:19,100 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:19,100 Model: "TextClassifier(
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
#> 2024-05-01 12:40:19,100 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:19,101 Corpus: "Corpus: 1800 train + 200 dev + 85 test sentences"
#> 2024-05-01 12:40:19,101 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:19,101 Parameters:
#> 2024-05-01 12:40:19,101  - learning_rate: "0.002000"
#> 2024-05-01 12:40:19,101  - mini_batch_size: "8"
#> 2024-05-01 12:40:19,101  - patience: "3"
#> 2024-05-01 12:40:19,101  - anneal_factor: "0.5"
#> 2024-05-01 12:40:19,101  - max_epochs: "1"
#> 2024-05-01 12:40:19,101  - shuffle: "True"
#> 2024-05-01 12:40:19,101  - train_with_dev: "False"
#> 2024-05-01 12:40:19,101  - batch_growth_annealing: "False"
#> 2024-05-01 12:40:19,101 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:19,101 Model training base path: "new-muller-campaign-communication"
#> 2024-05-01 12:40:19,101 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:19,101 Device: cpu
#> 2024-05-01 12:40:19,101 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:19,101 Embeddings storage mode: cpu
#> 2024-05-01 12:40:19,101 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:40:25,272 epoch 1 - iter 22/225 - loss 0.53992593 - time (sec): 6.17 - samples/sec: 28.52 - lr: 0.002000
#> 2024-05-01 12:40:32,060 epoch 1 - iter 44/225 - loss 0.49158928 - time (sec): 12.96 - samples/sec: 27.16 - lr: 0.002000
#> 2024-05-01 12:40:40,011 epoch 1 - iter 66/225 - loss 0.49081571 - time (sec): 20.91 - samples/sec: 25.25 - lr: 0.002000
#> 2024-05-01 12:40:47,672 epoch 1 - iter 88/225 - loss 0.49611578 - time (sec): 28.57 - samples/sec: 24.64 - lr: 0.002000
#> 2024-05-01 12:40:56,037 epoch 1 - iter 110/225 - loss 0.46774886 - time (sec): 36.94 - samples/sec: 23.83 - lr: 0.002000
#> 2024-05-01 12:41:04,182 epoch 1 - iter 132/225 - loss 0.46582140 - time (sec): 45.08 - samples/sec: 23.42 - lr: 0.002000
#> 2024-05-01 12:41:11,599 epoch 1 - iter 154/225 - loss 0.43794946 - time (sec): 52.50 - samples/sec: 23.47 - lr: 0.002000
#> 2024-05-01 12:41:20,457 epoch 1 - iter 176/225 - loss 0.41281759 - time (sec): 61.36 - samples/sec: 22.95 - lr: 0.002000
#> 2024-05-01 12:41:28,038 epoch 1 - iter 198/225 - loss 0.41347671 - time (sec): 68.94 - samples/sec: 22.98 - lr: 0.002000
#> 2024-05-01 12:41:37,951 epoch 1 - iter 220/225 - loss 0.40589899 - time (sec): 78.85 - samples/sec: 22.32 - lr: 0.002000
#> 2024-05-01 12:41:39,935 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:41:39,936 EPOCH 1 done: loss 0.4046 - lr 0.002000
#> 2024-05-01 12:41:42,519 Evaluating as a multi-label problem: False
#> 2024-05-01 12:41:42,528 DEV : loss 0.46994879841804504 - f1-score (micro avg)  0.845
#> 2024-05-01 12:41:42,535 BAD EPOCHS (no improvement): 0
#> 2024-05-01 12:41:42,535 saving best model
#> 2024-05-01 12:41:44,283 ----------------------------------------------------------------------------------------------------
#> 2024-05-01 12:41:48,039 Evaluating as a multi-label problem: False
#> 2024-05-01 12:41:48,046 0.8588   0.8588  0.8588  0.8588
#> 2024-05-01 12:41:48,046 
#> Results:
#> - F-score (micro) 0.8588
#> - F-score (macro) 0.8599
#> - Accuracy 0.8588
#> 
#> By class:
#>               precision    recall  f1-score   support
#> 
#>       Future     0.8837    0.8837    0.8837        43
#>      Present     0.7667    0.8519    0.8070        27
#>         Past     1.0000    0.8000    0.8889        15
#> 
#>     accuracy                         0.8588        85
#>    macro avg     0.8835    0.8452    0.8599        85
#> weighted avg     0.8671    0.8588    0.8603        85
#> 
#> 2024-05-01 12:41:48,046 ----------------------------------------------------------------------------------------------------
#> $test_score
#> [1] 0.8588235
#> 
#> $dev_score_history
#> [1] 0.845
#> 
#> $train_loss_history
#> [1] 0.4045972
#> 
#> $dev_loss_history
#> [1] 0.4699488
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
