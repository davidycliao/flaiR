
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

**flaiR** is an R package for accessing the
[flairNLP/flair](flairNLP/flair) Python library, maintained by [David
Liao](https://davidycliao.github.io), [Stefan
Müller](https://muellerstefan.net) from [Next Generation Energy
Systems](https://www.nexsys-energy.ie) and friends at [Text and Policy
Research Group](https://text-and-policy.com) and [Connected_Politics
Lab](https://www.ucd.ie/connected_politics/) in UCD. flaiR provides
convenient access to the main functionalities of flairNLP for training
word embedding-based deep learning models and fine-tune state-of-the-art
transformers hosted on Hugging Face.

### Installation via <u>**`GitHub`**</u>

``` r
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
```

``` r
library(flaiR)
```

### Requirements

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

<!-- __Note__: [Anaconda](https://github.com/anaconda) or [miniconda](https://github.com/conda/conda) (highly recommended) is the best way to manage your working environment. In RStudio, the Python (conda) environment can easily be managed by the reticulate R package, or manually changed configuration via Tools -> Global Options -> Python in Rstudio. -->

<br>

### Contribution and Open Source

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
