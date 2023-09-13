#' @title Clear Flair Cache
#'
#' @description
#' This function clears the cache associated with the Flair Python library.
#' The cache directory is typically located at "~/.flair".
#' @param ... The argument passed to next.
#' @return Returns NULL invisibly. Messages are printed indicating whether
#' the cache was found and cleared.
#' @export
#'
#' @examples
#' \dontrun{
#' clear_flair_cache()
#' }
clear_flair_cache <- function(...) {
  # Define the flair cache directory
  flair_cache_dir <- file.path(path.expand("~"), ".flair")

  # Check if the directory exists
  if (!dir.exists(flair_cache_dir)) {
    cat("Flair cache directory does not exist.\n")
    return(NULL)
  }

  # List files in the flair cache directory
  cache_files <- list.files(flair_cache_dir)
  if(length(cache_files) > 0) {
    cat("Files in flair cache directory:\n")
    print(cache_files)
  } else {
    cat("No files in flair cache directory.\n")
  }

  # Remove the directory and its contents
  unlink(flair_cache_dir, recursive = TRUE)
  cat("Flair cache directory has been cleared.\n")

  return(invisible(NULL))
}

#' @title Create or use Python environment for Flair
#'
#' @description
#' This function checks whether the Flair Python library is installed in the
#' current Python environment. If it is not, it attempts to install it either
#' in the current conda environment or creates a new one.
#'
#' @param env The name of the conda environment to be used or
#' created (default is "r-reticulate").
#'
#' @return Nothing is returned. The function primarily ensures that the Python
#' library Flair is installed and available.
#' @export
#' @importFrom reticulate import py_config use_condaenv
#' @importFrom rstudioapi restartSession
create_flair_env <- function(env = "r-reticulate") {
  # check if flair is already installed in the current Python environment
  if (reticulate::py_module_available("flair")) {
    message("Environment creation stopped.", "\n", "Flair is already installed in ", reticulate::py_config()$python)
    message(sprintf("Using Flair:  %-48s", reticulate::import("flair")$`__version__`))
    return(invisible(NULL))
  }
  paths <- reticulate::conda_list()
  env_path <- paths[grep("envs/", paths$python), "python"][1]
  if (grepl("envs/", env_path)) {
    message("you already created:", length(paths[grep("envs/", paths$python), "python"]))
    message("you can run use_condaenv(",as.character(env_path),") to activate the enviroment in your R." )
    reticulate::use_condaenv(env)
  } else {
    # No conda environment found or active, so create one
    reticulate::conda_create(env)
    message("No conda environment found. Creating a new environment named '", env, "'. ", "After restarting the R session, please run create_flair_env() again.")
    rstudioapi::restartSession()
  }
}

#' @title Load the Named Entity Recognition (NER) Tagger
#'
#' @description A helper function to load the appropriate tagger based on the provided language.
#' This function supports a variety of languages/models.
#'
#' @param language Character string indicating the desired language for the NER tagger.
#' Supported languages include "en", "de", "fr", "nl", "da", and "ar".
#'
#' @return An instance of the Flair SequenceTagger for the specified language.
#' @details
#' Supported languages and their corresponding codes are:
#' * "en" - English: `ner`
#' * "de" - German: `de-ner`
#' * "fr" - French: `fr-ner`
#' * "nl" - Dutch: `nl-ner`
#' * "da" - Danish: `da-ner`
#' * "ar" - Arabic: `ar-ner`
#' @import reticulate
#' @importFrom stats setNames
#'
#' @examples
#' # Load the English NER tagger
#' tagger_en <- load_tagger_ner("en")
#'
#' @export
load_tagger_ner <- function(language = NULL) {
  supported_lan_models <- c("ner", "de-ner",
                            "fr-ner", "nl-ner",
                            "da-ner", "ar-ner",
                            "ner-fast", "ner-large",
                            "ner-pooled",  "ner-ontonotes",
                            "ner-ontonotes-fast", "ner-ontonotes-large",
                            "de-ner-large", "de-ner-germeval",
                            "de-ner-legal", "es-ner",
                            "nl-ner", "nl-ner-large",
                            "nl-ner-rnn", "ner-ukrainian")
  language_model_map <- setNames(supported_lan_models, c("en", "de",
                                                         "fr", "nl",
                                                         "da", "ar",
                                                         "ner-fast", "ner-large",
                                                         "ner-pooled", "ner-ontonotes",
                                                         "ner-ontonotes-fast", "ner-ontonotes-large",
                                                         "de-ner-large", "de-ner-germeval",
                                                         "de-ner-legal", "es-ner-large",
                                                         "nl-ner", "nl-ner-large",
                                                         "nl-ner-rnn", "ner-ukrainian")
  )

  if (is.null(language)) {
    language <- "en"
    message("Language is not specified. ", language, " in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
  }

  # Translate language to model name if necessary
  if (language %in% names(language_model_map)) {
    language <- language_model_map[[language]]
  }

  # Ensure the model is supported
  check_language_supported(language = language, supported_lan_models = supported_lan_models)

  # Load the model
  SequenceTagger <- reticulate::import("flair.models")$SequenceTagger
  SequenceTagger$load(language)
}

#' Load Flair POS Tagger
#'
#' This function loads the POS (part-of-speech) tagger model for a specified language
#' using the Flair library. If no language is specified, it defaults to 'pos-fast'.
#'
#' @param language A character string indicating the desired language model. If `NULL`,
#' the function will default to the 'pos-fast' model. Supported language models include:
#' \itemize{
#'   \item "pos" - General POS tagging
#'   \item "pos-fast" - Faster POS tagging
#'   \item "upos" - Universal POS tagging
#'   \item "upos-fast" - Faster Universal POS tagging
#'   \item "pos-multi" - Multi-language POS tagging
#'   \item "pos-multi-fast" - Faster Multi-language POS tagging
#'   \item "ar-pos" - Arabic POS tagging
#'   \item "de-pos" - German POS tagging
#'   \item "de-pos-tweets" - German POS tagging for tweets
#'   \item "da-pos" - Danish POS tagging
#'   \item "ml-pos" - Malayalam POS tagging
#'   \item "ml-upos" - Malayalam Universal POS tagging
#'   \item "pt-pos-clinical" - Clinical Portuguese POS tagging
#'   \item "pos-ukrainian" - Ukrainian POS tagging
#' }
#' @return A Flair POS tagger model corresponding to the specified (or default) language.
#'
#' @importFrom reticulate import
#' @export
#' @examples
#' \dontrun{
#' tagger <- load_tagger_pos("pos-fast")
#' }
load_tagger_pos <- function(language = NULL) {
  supported_lan_models <- c("pos", "pos-fast", "upos", "upos-fast",
                            "pos-multi", "pos-multi-fast", "ar-pos", "de-pos",
                            "de-pos-tweets", "da-pos", "ml-pos",
                            "ml-upos", "pt-pos-clinical", "pos-ukrainian")

  if (is.null(language)) {
    language <- "pos-fast"
    message("Language is not specified. ", language, "in Flair is forceloaded. Please ensure that the internet connectivity is stable. \n")
  }

  # Ensure the model is supported
  check_language_supported(language = language, supported_lan_models = supported_lan_models)

  # Load the model
  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  tagger <- Classifier$load(language)
}

#' @title Load a Sentiment or Language Tagger Model from Flair
#'
#' @description This function loads a pre-trained sentiment or language tagger
#' from the Flair library.  It allows you to specify the model language you wish to load.
#'
#' @param language Character string specifying the language model to load.
#'   Can be one of "sentiment", "sentiment-fast", or "de-offensive-language".
#'   Defaults to "sentiment" if not provided.
#'
#' @return An object of the loaded Flair model.
#'
#' @import reticulate
#' @examples
#' \dontrun{
#'   tagger <- load_tagger_sentiments("sentiment")
#' }
#'
#' @export
load_tagger_sentiments <- function(language = NULL) {
  supported_lan_models <- c("sentiment", "sentiment-fast", "de-offensive-language")

  if (is.null(language)) {
    language <- "sentiment"
    message("Language is not specified. ", language, " in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
  }

  # Ensure the model is supported
  check_language_supported(language = language, supported_lan_models = supported_lan_models)

  # Load the model
  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  tagger <- Classifier$load(language)
  return(tagger)
}

#' Check the specified device for PyTorch
#'
#' This function verifies if the specified device is available for PyTorch.
#' If CUDA is not available, a message is shown.
#'
#' @param device Character. The device to be set for PyTorch.
#' @importFrom reticulate import
#' @keywords internal
check_device <- function(device) {
  pytorch <- reticulate::import("torch")
  if (device != "cpu" && !pytorch$cuda$is_available()) {
    message("CUDA is not available on this machine.")
  }
  if (device == "cpu") {
    pytorch$device(device)
    message("CPU is used.")
  } else {
    pytorch$cuda$set_device(as.integer(device))
    message("CUDA is used.")
  }
}

#' Check the specified batch size
#'
#' Validates if the given batch size is a positive integer.
#'
#' @param batch_size Integer. The batch size to be checked.
#' @keywords internal

check_batch_size <- function(batch_size) {
  if (!is.numeric(batch_size) || batch_size <= 0 || (batch_size %% 1 != 0)) {
    stop("Invalid batch size. It must be a positive integer.")
  }
}

#' Check the texts and document IDs
#'
#' Validates if the given texts and document IDs are not NULL or empty.
#'
#' @param texts List. A list of texts.
#' @param doc_ids List. A list of document IDs.
#' @keywords internal

check_texts_and_ids <- function(texts, doc_ids) {
  if (is.null(texts) || length(texts) == 0) {
    stop("The texts cannot be NULL or empty.")
  }
  if (is.null(doc_ids) || length(doc_ids) == 0) {
    stop("The doc_ids cannot be NULL or empty.")
  }
  if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }
}


#' Check the `show.text_id` parameter
#'
#' Validates if the given `show.text_id` is a logical value.
#'
#' @param show.text_id Logical. The parameter to be checked.
#' @keywords internal

check_show.text_id <- function(show.text_id) {
  if (!is.logical(show.text_id)) {
    stop("show.text_id should be a logical value.")
  }
}

#' Perform Garbage Collection Based on Condition
#'
#' This function checks the value of `gc.active` to determine whether
#' or not to perform garbage collection. If `gc.active` is `TRUE`,
#' the function will perform garbage collection and then send a
#' message indicating the completion of this process.
#'
#' @param gc.active A logical value indicating whether or not to
#'     activate garbage collection.
#'
#' @return A message indicating that garbage collection was performed
#' if `gc.active` was `TRUE`. Otherwise, no action is taken or message is
#' displayed.
#'
#' @keywords internal
check_and_gc <- function(gc.active) {
  if (!is.logical(gc.active)) {
    stop("gc.active should be a logical value.")
  }
  if (isTRUE(gc.active)) {
    gc()
    message("Garbage collection after processing all texts")
  }
}

#' @title Check the Given Language Models against Supported Languages Models
#'
#' @description This function checks whether a provided language is supported. If it's not,
#' it stops the execution and returns a message indicating the supported languages.
#'
#' @param language The language to check.
#' @param supported_lan_models A vector of supported languages.
#'
#' @return This function does not return anything, but stops execution if the check fails.
#' @examples
#' # Assuming 'en' is a supported language and 'abc' is not:
#' check_language_supported("en", c("en", "de", "fr"))
#' # check_language_supported("abc", c("en", "de", "fr")) # will stop execution
#' @export
#' @keywords internal
check_language_supported <- function(language, supported_lan_models) {
  attempt::stop_if_all(
    !language %in% supported_lan_models,
    isTRUE,
    msg = paste0("Unsupported language. Supported languages are: ",
                 paste(supported_lan_models, collapse = ", "),
                 ".")
  )
}

#' @title Check Environment Pre-requisites
#' @description This function checks if Python is installed, if the flair module
#' is available in Python,
#' and if there's an active internet connection.
#' @param ... passing additional arguments.
#' @return A message detailing any missing pre-requisites.
#' @keywords internal
#' @importFrom attempt stop_if_all
check_prerequisites <- function(...) {
  # Check if Python is installed
  attempt::stop_if_all(
    check_python_installed(),
    isFALSE,
    msg = "Python is not installed in your R environment."
  )

  # Check if flair module is available in Python
  attempt::warn_if_all(
    reticulate::py_module_available("flair"),
    isFALSE,
    msg = paste(
      "flair is not installed at",
      reticulate::py_config()[[1]]
    )
  )

  # Check for an active internet connection
  attempt::warn_if_all(
    curl::has_internet(),
    isFALSE,
    msg = "Internet connection issue. Please check your network settings."
  )
  return("All pre-requisites met.")
}

#' @title Retrieve Flair Version
#'
#' @description
#' Gets the version of the installed Flair module in the current Python
#' environment.
#'
#' @keywords internal
#' @return Character string representing the version of Flair.
#' If Flair is not installed, this may return `NULL` or cause an error
#' (based on `reticulate` behavior).
get_flair_version <- function(...) {
  flair <- reticulate::import("flair")
  # Assuming flair has an attribute `__version__` (this might not be true)
  return(flair$`__version__`)
}

#' @title Check Flair
#'
#' @description
#' Determines if the Flair Python module is available in the current Python
#' environment.
#'
#' @keywords internal
#' @return Logical. `TRUE` if Flair is installed, otherwise `FALSE`.
check_flair_installed <- function(...) {
  return(reticulate::py_module_available("flair"))
}

#' @title Check for Available Python Installation
#'
#' @description
#' This function checks if any environment is installed on the R system.
#'
#' @param ... any param to run.
#' @return Logical. `TRUE` if Python is installed, `FALSE` otherwise.
#' Additionally, if installed, the path to the Python installation is printed.
#' @keywords internal
check_python_installed <- function(...) {
  # Check if running on Windows
  if (.Platform$OS.type == "windows") {
    command <- "where python"
  } else {
    command <- "which python3"
  }

  # Locate python path
  result <- system(command, intern = TRUE, ignore.stderr = TRUE)

  # Check if the result is a valid path
  if (length(result) > 0 && file.exists(result[1])) {
    # cat("Python is installed at:", result[1], "\n")
    return(TRUE)
  } else {
    # cat("Python is not installed on this system.\n")
    return(FALSE)
  }
}


check_python_installed <- function(...) {
  # Check if running on Windows
  if (.Platform$OS.type == "windows") {
    command <- "where python"
  } else {
    command <- "which python3"
  }

  # Locate python path
  result <- system(command, intern = TRUE, ignore.stderr = TRUE)

  # Check if the result is a valid path
  if (length(result) > 0 && file.exists(result[1])) {
    # cat("Python is installed at:", result[1], "\n")
    return(TRUE)
  } else {
    # cat("Python is not installed on this system.\n")
    return(FALSE)
  }
}




#' Ensure Either a Tagger Object or a Language is Specified
#'
#' This function checks if either a tagger object or a language is specified and throws an error if neither is provided.
#'
#' @param tagger A tagger object (default is NULL).
#' @param language The language of the texts (default is NULL).
#'
#' @return None. The function will throw a message if neither tagger nor language is specified.
#'
#' @keywords internal
# ensure_tagger_or_language <- function(tagger = NULL, language = NULL) {
#   if (is.null(tagger) && is.null(language)) {
#     message("Either a tagger object or a language did not specify.")
#   }
# }
ensure_tagger_or_language <- function(tagger = NULL, language = NULL, alternative = NULL) {
  if (is.null(tagger) && is.null(language)) {
    language <- alternative
    message("Language is not specified. A default language in Flair is force-loaded. Please ensure that the internet connectivity is stable.\n")
  } else if (is.null(tagger)) {
    message("Language is specified as '", language, "'. Flair is force-loading this language. Please ensure that the internet connectivity is stable. \n")
  }
  return(language)
}




