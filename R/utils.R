#' @title Check the given language against supported languages
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
#'
#' @export
check_language_supported <- function(language, supported_lan_models) {
  attempt::stop_if_not(
    !language %in% supported_lan_models,
    isFALSE,
    msg =cat(paste("Unsupported language. Supported languages are:",
                   paste(supported_lan_models, collapse = ", ")), ".", sep = "")
  )
}

#' Load the Named Entity Recognition (NER) Tagger
#'
#' A helper function to load the appropriate tagger based on the provided language.
#' This function supports a variety of languages/models.
#'
#' @param language Character string indicating the desired language for the NER tagger.
#' Supported languages include "en", "de", "fr", "nl", "da", and "ar".
#'
#' @return An instance of the Flair SequenceTagger for the specified language.
#'
#' @import reticulate
#' @importFrom stats setNames
#'
#' @examples
#' # Load the English NER tagger
#' tagger_en <- load_tagger_ner("en")
#'
#' @export
load_tagger_ner <- function(language) {
  supported_lan_models <- c("ner", "de-ner", "fr-ner", "nl-ner", "da-ner", "ar-ner")
  language_model_map <- setNames(supported_lan_models, c("en", "de", "fr", "nl", "da", "ar"))

  if (is.null(language)) {
    language <- "en"
    message("Language is not specified.", language, "in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
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
#' "pos", "pos-fast", "upos", "upos-fast", "pos-multi", "pos-multi-fast", "ar-pos",
#' "de-pos", "de-pos-tweets", "da-pos", "ml-pos", "ml-upos", "pt-pos-clinical", "pos-ukrainian".
#'
#' @return A Flair POS tagger model corresponding to the specified (or default) language.
#'
#' @importFrom reticulate import
#' @export
#' @examples
#' \dontrun{
#' tagger <- load_tagger_pos("pos-fast")
#' }
load_tagger_pos <- function(language) {
  supported_lan_models <- c("pos", "pos-fast", "upos", "upos-fast",
                            "pos-multi", "pos-multi-fast", "ar-pos", "de-pos",
                            "de-pos-tweets", "da-pos", "ml-pos",
                            "ml-upos", "pt-pos-clinical", "pos-ukrainian")

  if (is.null(language)) {
    language <- "pos-fast"
    message("Language is not specified.", language, "in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
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
load_tagger_sentiments <- function(language) {
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



#' @title Check Environment Pre-requisites
#' @description This function checks if Python is installed, if the flair module is available in Python,
#' and if there's an active internet connection.
#' @param ... passing additional arguments.
#' @return A message detailing any missing pre-requisites.
#'
#' @importFrom attempt stop_if_all
#' @export
check_prerequisites <- function(...) {

  # Check if Python is installed
  attempt::stop_if_all(
    check_python_installed(),
    isFALSE,
    msg = "Python is not installed in your R environment."
  )

  # Check if flair module is available in Python
  attempt::stop_if_all(
    reticulate::py_module_available("flair"),
    isFALSE,
    msg = paste(
      "flair is not installed at",
      reticulate::py_config()[[1]]
    )
  )

  # Check for an active internet connection
  attempt::stop_if_all(
    curl::has_internet(),
    isFALSE,
    msg = "Internet connection issue. Please check your network settings."
  )

  return("All pre-requisites met.")
}



#' @title Check for Active Internet Connection
#'
#' @description
#' This function checks if there's an active internet connection using
#' the `curl` package. In case of an error or no connection, it will return `FALSE`.
#' @return Logical. TRUE if there's an active internet connection, otherwise FALSE.
#' @importFrom curl has_internet
#' @keywords internal
has_internet <- function() {
  tryCatch({
    curl::has_internet()
  }, error = function(e) {
    FALSE
  })
}


#' @title Retrieve Flair Version
#'
#' @description
#' Gets the version of the installed Flair module in the current Python environment.
#'
#' @keywords internal
#' @export get_flair_version
#' @return Character string representing the version of Flair.
#' If Flair is not installed, this may return `NULL` or cause an error (based on `reticulate` behavior).
get_flair_version <- function(...) {
  flair <- reticulate::import("flair")
  # Assuming flair has an attribute `__version__` (this might not be true)
  return(flair$`__version__`)
}

#' @title Check Flair
#'
#' @description
#' Determines if the Flair Python module is available in the current Python environment.
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
#' @return Logical. `TRUE` if Python is installed, `FALSE` otherwise. Additionally, if installed, the path to the Python installation is printed.
#' @export
check_python_installed <- function() {
  # Check if running on Windows
  if (.Platform$OS.type == "windows") {
    command <- "where python"
  } else {
    command <- "which python3"
  }

  # locate python path
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

#' @title Clear Flair Cache
#'
#' @description
#' This function clears the cache associated with the Flair Python library.
#' The cache directory is typically located at "~/.flair".
#' @param ... Additional arguments passed to next.
#' @return Returns NULL invisibly. Messages are printed indicating whether the cache was found and cleared.
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

#' @title Check for Available Python Environment
#'
#' @description
#' This function checks if a Python environment is available
#' and prints the path to the Python executable if it is.
#' @param ... Additional arguments passed to next.
#' @return Logical indicating if a Python environment is available.
#' @importFrom reticulate py_available
#' @export
check_python_environment <- function(...) {
  if (reticulate::py_available(initialize = TRUE)) {
    config <- reticulate::py_config()
    cat(config$python, "\n")
    return(TRUE)
  } else {
    # cat("No Python environment available.\n")
    return(FALSE)
  }
}


#' @title Create or use Python environment for Flair
#'
#' @description
#' This function checks whether the Flair Python library is installed in the current Python environment.
#' If it is not, it attempts to install it either in the current conda environment or creates a new one.
#'
#' @param env The name of the conda environment to be used or created (default is "r-reticulate").
#'
#' @return Nothing is returned. The function primarily ensures that the Python library Flair is installed and available.
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
  # paths <- reticulate::conda_list()$python
  # env_path <- paths[grepl("envs/", paths)][1]
  # check conda environment in R
  paths <- reticulate::conda_list()
  env_path <- paths[grep("envs/", paths$python), "python"][1]
  if (grepl("envs/", env_path)) {
    message("you already created:", length(paths[grep("envs/", paths$python), "python"]))
    message("you can run use_condaenv(",as.character(env_path),") to activate the enviroment in your R" )
    reticulate::use_condaenv(env)
    # if (grepl("env",  paths[grepl(env, paths)][1])) {
    #   reticulate::use_condaenv(paths[grepl(env, paths)][1], required = TRUE)
    # system(paste(reticulate::py_config()$python, "-m pip install flair"))
    # message("Flair is installed in the eviroment of ", paths )

  } else {
    # No conda environment found or active, so create one
    reticulate::conda_create(env)
    message("No conda environment found. Creating a new environment named '", env, "'.")
    message("After restarting the R session, please run create_flair_env() again.")
    rstudioapi::restartSession()
    # reticulate::use_condaenv(env, required = TRUE)
  }
}

