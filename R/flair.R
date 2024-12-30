#' @title Wrapper for the Flair Python Library
#'
#' @description
#' flair: a wrapper to access the Flair library from Python.
#'
#' Returns:
#' \itemize{
#'   \item list: A list of method as python module.
#'}
#'
#' \describe{
#'   \item{Environment and Configuration:}{
#'     \itemize{
#'       \item `os`: Pertains to operating system related functions, such as path
#'             handling, file operations, and more.
#'       \item `Path`: From pathlib, used for more convenient file path operations.
#'       \item `set_seed`: Functions to set the random seed.
#'       \item `hf_set_seed`: Functions to set the random seed.
#'       \item `set_proxies`: Used to configure network proxies.
#'     }
#'   }
#'   \item{Data and Data Loading:}{
#'     \itemize{
#'       \item `data`: Functions related to data handling and operations.
#'       \item `datasets`: Modules or methods to load and handle specific datasets.
#'       \item `file_utils`: Utilities for file operations.
#'     }
#'   }
#'   \item{Embeddings and Model Layers:}{
#'     \itemize{
#'       \item `embeddings`: About embeddings, including word embeddings,
#'             contextual embeddings, etc.
#'       \item `nn`: Related to neural network layers or operations.
#'       \item `models`: Different model architectures or structures.
#'     }
#'   }
#'   \item{Training and Optimization:}{
#'     \itemize{
#'       \item `trainers`: Related to training models.
#'       \item `training_utils`: Utility functions for the training process.
#'       \item `optim`: Optimization algorithms, like SGD, Adam.
#'     }
#'   }
#'   \item{Tokenization and Text Processing:}{
#'     \itemize{
#'       \item `tokenization`: To break text into tokens.
#'       \item `splitter`: For splitting datasets or texts.
#'     }
#'   }
#'   \item{Visualizations and Miscellaneous:}{
#'     \itemize{
#'       \item `visual`: Related to visualization.
#'       \item `torch`: The main PyTorch library.
#'       \item `cache_root`: Related to caching data or models.
#'     }
#'   }
#'}
#' @return An object that represents the Flair module from Python.
#'
#' @details This function relies on the reticulate package to import and
#' use the Flair module from Python. Ensure you have the Flair Python library
#' installed in the Python environment being used.
#'
#' @importFrom reticulate import
#'
#' @examples
#' \dontrun{
#' flair <- import_flair()
#'}
#' @export
import_flair <- function(){
  ## flair: a wrapper to access the Flair library from Python.
  ## Args:
  ##    empty: The path to the JSONL file.
  ##
  ## Returns:
  ##    list: A list of method as python module.
  ##
  ## - Environment and Configuration:
  ##   `os`            : Pertains to operating system related functions, such as path
  ##                     handling, file operations, and more.
  ##   `Path`          : From pathlib, used for more convenient file path operations.
  ##                     logger and logging: Responsible for logging functions,
  ##                     recording training processes, errors, and other information.
  ##   `set_seed`      : Functions to set the random seed.
  #    `hf_set_seed`   : Functions to set the random seed.
  ##   `set_proxies`   : Used to configure network proxies.
  ## - Data and Data Loading:
  ##   `data`          : Functions related to data handling and operations.
  ##   `datasets`      : Modules or methods to load and handle specific datasets.
  ##   `file_utils`    : Utilities for file operations, possibly involving reading/writing to files, and more.
  ## - Embeddings and Model Layers:
  ##   `embeddings`    : All about embeddings, which might include word embeddings,
  ##                     contextual embeddings, and other related operations.
  ##   `nn`            : Likely related to neural network layers or operations.
  ##   `models`        : Pertains to different model architectures or structures.
  ## - Training and Optimization:
  ##   `trainers`      : Methods and structures related to training models.
  ##   `training_utils`: Utility functions to assist during the training process.
  ##   `optim`         : Related to optimization algorithms, like SGD, Adam, etc.
  ## - Tokenization and Text Processing:
  ##   `tokenization`  : Functions to break text into tokens (words, subwords).
  ##   `splitter`      : Potentially for splitting datasets or texts.
  ## - Visualizations and Miscellaneous:
  ##   `visual`        : Functions and utilities related to visualization, maybe for embeddings or model results.
  ##   `torch`         : The main PyTorch library, which flair is based on, used for tensor operations, defining models, and more.
  ##   `cache_root`    : Possibly related to caching data or models for faster loading.
  flaiR <- import("flair")
  return(flaiR)
}
