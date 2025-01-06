
## <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Library <img src="man/figures/logo.png" align="right" width="180"/>

[![R-MacOS](https://github.com/davidycliao/flaiR/actions/workflows/r_macos.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r_macos.yml)
[![R-ubuntu](https://github.com/davidycliao/flaiR/actions/workflows/r_ubuntu.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r_ubuntu.yaml)
[![R-Windows](https://github.com/davidycliao/flaiR/actions/workflows/r_window.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r_window.yml)
[![R-CMD-Check](https://github.com/davidycliao/flaiR/actions/workflows/r.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r.yml)
[![flaiR-Installation-Check](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check.yml)
[![R](https://img.shields.io/badge/R-package-blue)](https://github.com/davidycliao/flaiR)
[![Docker
Image](https://img.shields.io/badge/Docker-ghcr.io-blue?logo=docker)](https://github.com/davidycliao/flaiR/pkgs/container/flair-rstudio)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)

<!-- [![flaiR-Docker](https://github.com/davidycliao/flaiR/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/docker-publish.yml) -->

<!-- <!-- ![ARM64](https://img.shields.io/badge/ARM64-M1|M2-success?logo=arm) -->

<!-- [![R](https://img.shields.io/badge/R-package-blue)](https://github.com/davidycliao/flaiR) -->

<!-- [![Docker Image](https://img.shields.io/badge/Docker-ghcr.io-blue?logo=docker)](https://github.com/davidycliao/flaiR/pkgs/container/flair) -->

<!-- README.md is generated from README.Rmd. Please edit that file -->

<div style="text-align: justify">

**flaiR** is an R package that provides convenient access to
[flairNLP/flair](https://github.com/flairNLP/flair), a powerful
Python-based NLP toolkit developed by Humboldt University of Berlin. The
R package is maintained by [Yen-Chieh
Liao](https://davidycliao.github.io) ([University of
Birmingham](https://www.birmingham.ac.uk/research/centres-institutes/centre-for-artificial-intelligence-in-government))
and [Stefan Müller](https://muellerstefan.net) from [Next Generation
Energy Systems](https://www.nexsys-energy.ie) and [Text and Policy
Research Group](https://text-and-policy.com) at UCD.

Through **flaiR**, R users can easily utilize and combine various word
embeddings, train deep learning models, and fine-tune the latest
transformer models from Hugging Face, bridging advanced NLP
functionality with popular quantitative text analysis toolkits like
quanteda in the R environment.

<!-- Our team trains and fine-tunes the models with Flair in [our projects](). -->

</div>

<br>

## Installation via <u>**`GitHub`**</u>

<div style="text-align: justify">

**Required Softwares**

- Python \>= 3.10
- R \>= 4.2.0
- Rstudio

**Operation Systems**

| OS      | R Versions                | Python Version |
|---------|---------------------------|----------------|
| Mac     | 4.3.2, 4.2.0, ~~4.2.1~~\* | 3.10.x, 3.9    |
| Windows | 4.0.5, Latest             | 3.10.x, 3.9    |
| Ubuntu  | 4.3.2, 4.2.0, 4.2.1       | 3.10.x, 3.9    |

\*: *On R 4.2.1, particularly when using the Matrix package on ARM 64
architecture Macs (M1/M2), compatibility issues with gfortran may occur.
It’s recommended to avoid this combination.*

<br>

``` r
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
```

``` r
library(flaiR)
```

``` r
#> flaiR: An R Wrapper for Accessing Flair NLP 0.13.1
```

<br>

## Installation with Docker

**Intel/AMD Processors:**

``` r
# Pull image
docker pull ghcr.io/davidycliao/flair-rstudio:latest

# Run container
docker run -d -p 8787:8787 --user root --name flair-rstudio ghcr.io/davidycliao/flair-rstudio:latest
```

**Apple Silicon (M1/M2 Mac):**

``` r
# Pull image
docker pull --platform linux/amd64 ghcr.io/davidycliao/flair-rstudio:latest

# Run container
docker run -d -p 8787:8787 --platform linux/amd64 --user root --name flair-rstudio ghcr.io/davidycliao/flair-rstudio:latest
```

After running these commands in terminal (or powershell), open your
browser and navigate to [`http://localhost:8787`](http://localhost:8787)
to access RStudio. For detailed installation instructions, please visit
[Quick Start
Guide](https://davidycliao.github.io/flaiR/articles/quickstart.html#flair-installation).

</div>

<br>

## Contribution and Open Source

<div style="text-align: justify">

R developers who want to contribute to `flaiR` are welcome – flaiR is an
open source project. We warmly invite R users who share similar
interests to join in contributing to this package. Please feel free to
shoot me an email us to collaborate on the task. Contributions – whether
they be comments, code suggestions, tutorial examples, or forking the
repository – are greatly appreciated. Please note that the `flaiR` is
released with the [Contributor Code of
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
