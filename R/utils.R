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
  # flair cache directory
  flair_cache_dir <- file.path(path.expand("~"), ".flair")

  # Check if the directory still exists
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


#' Show Flair Cache Preloaed flair's Directory
#'
#' @description This function lists the contents of the flair cache directory
#' and returns them as a data frame.
#'
#' @return A data frame containing the file paths of the contents in the flair
#' cache directory. If the directory does not exist or is empty, NULL is returned.
#' @export
#' @examples
#' \dontrun{
#' show_flair_cache()
#' }
show_flair_cache <- function() {
  flair_cache_dir <- file.path(path.expand("~"), ".flair")

  # Check if the directory still exists
  if (!dir.exists(flair_cache_dir)) {
    cat("Flair cache directory does not exist.\n")
    return(NULL)
  }

  # List all files and directories in the flair cache directory
  cache_contents <- list.files(flair_cache_dir, full.names = TRUE, recursive = TRUE)

  if (length(cache_contents) > 0) {
    cat("Contents in flair cache directory:\n")

    # Create a data frame with the cache contents
    cache_df <- data.frame(FilePath = cache_contents, stringsAsFactors = FALSE)
    print(cache_df)

    # Ask user if they agree to proceed with deletion
    response <- tolower(readline("Do you agree to proceed? All downloaded models in the cache will be completely deleted. (yes/no): "))

    if (response == "yes") {
      cat("Deleting cached models...\n")
      unlink(flair_cache_dir, recursive = TRUE)
      cat("Cache cleared.\n")
    } else {
      cat("Clearance cancelled.\n")
    }

    return(cache_df)
  } else {
    cat("No contents in flair cache directory.\n")
    return(NULL)
  }
}


#' @title Create or Use Python environment for Flair
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
#' @param language A character string indicating the desired language for the NER tagger.
#' If `NULL`, the function will default to the 'pos-fast' model.
#' Supported languages and their models include:
#' \itemize{
#'   \item `"en"` - English NER tagging (`ner`)
#'   \item `"de"` - German NER tagging (`de-ner`)
#'   \item `"fr"` - French NER tagging (`fr-ner`)
#'   \item `"nl"` - Dutch NER tagging (`nl-ner`)
#'   \item `"da"` - Danish NER tagging (`da-ner`)
#'   \item `"ar"` - Arabic NER tagging (`ar-ner`)
#'   \item `"ner-fast"` - English NER fast model (`ner-fast`)
#'   \item `"ner-large"` - English NER large mode (`ner-large`)
#'   \item `"de-ner-legal"` - NER (legal text) (`de-ner-legal`)
#'   \item `"nl"` - Dutch NER tagging (`nl-ner`)
#'   \item `"da"` - Danish NER tagging (`da-ner`)
#'   \item `"ar"` - Arabic NER tagging (`ar-ner`)
#'}
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
#' from the Flair library.
#'
#' @param language A character string specifying the language model to load.
#' Supported models include:
#' \itemize{
#'   \item "sentiment" - Sentiment analysis model
#'   \item "sentiment-fast" - Faster sentiment analysis model
#'   \item "de-offensive-language" - German offensive language detection model
#'} If not provided, the function will default to the "sentiment" model.
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

#' Check the Device for cccelerating PyTorch
#'
#' @description This function verifies if the specified device is available for PyTorch.
#' If CUDA is not available, a message is shown. Additionally, if the system
#' is running on a Mac M1, MPS will be used instead of CUDA.
#'
#' @param device Character. The device to be set for PyTorch.
#' @importFrom reticulate import
#' @keywords internal
check_device <- function(device) {
  pytorch <- reticulate::import("torch")
  system_info <- Sys.info()

  if (system_info["sysname"] == "Darwin" &&
      system_info["machine"] == "arm64" &&
      device == "mps") {

    os_version <- as.numeric(strsplit(system_info["release"], "\\.")[[1]][1])

    if (os_version >= 12.3) {
      message("MPS is used on Mac M1/M2.")
      return(pytorch$device(device))
    } else {
      warning("MPS requires macOS 12.3 or higher. Falling back to CPU.",
              "\nTo use MPS, ensure the following requirements are met:",
              "\n- Mac computers with Apple silicon or AMD GPUs",
              "\n- macOS 12.3 or later",
              "\n- Python 3.7 or later",
              "\n- Xcode command-line tools installed (xcode-select --install)",
              "\nMore information: https://developer.apple.com/metal/pytorch/")
      message("Using CPU.")
      return(pytorch$device("cpu"))
    }
  }
  else if (device == "cpu" ) {
    message("CPU is used.")
    return(pytorch$device(device))
  }
  else if (device != "mps" && !pytorch$cuda$is_available()) {
    message("CUDA is not available on this machine. Using CPU.")
    return(pytorch$device("cpu"))
  }
  else if (device == "cuda" && pytorch$cuda$is_available()) {
    message("CUDA is available and will be used.")
    return(pytorch$device(device))
  }
  else {
    warning("Unknown device specified. Falling back to use CPU.")
    return(pytorch$device("cpu"))
  }
}


#' Check the Specified Batch Size
#'
#' @description Validates if the given batch size is a positive integer.
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
#' @description Validates if the given texts and document IDs are not NULL or empty.
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
#' @description Validates if the given `show.text_id` is a logical value.
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
#' @description This function checks the value of `gc.active` to determine whether
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
#' @description This function checks whether a provided language is supported.
#' If it's not, it stops the execution and returns a message indicating the
#' supported languages.
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
#'
#' @description This function checks if Python is installed, if the flair module
#' is available in Python,
#'
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
#' @description Gets the version of the installed Flair module in the current
#' Python environment.
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

#' #' Ensure Either a Tagger Object or a Language is Specified
#' #'
#' #' @description This function checks if either a tagger object or a language is
#' #' specified and throws an error if neither is provided.
#' #'
#' #' @param tagger A tagger object (default is NULL).
#' #' @param language The language of the texts (default is NULL).
#' #'
#' #' @return None. The function will throw a message if neither tagger nor language is specified.
#' #'
#' #' @keywords internal
#' ensure_tagger_or_language <- function(tagger = NULL, language = NULL, alternative = NULL) {
#'   if (is.null(tagger) && is.null(language)) {
#'     language <- alternative
#'     message("Language is not specified. A default language in Flair is force-loaded. Please ensure that the internet connectivity is stable.")
#'   } else if (is.null(tagger)) {
#'     message("Language is specified as '", language, "'. Flair is force-loading this language. Please ensure that the internet connectivity is stable.")
#'   }
#'   return(language)
#' }

#' Create Mapping for NER Highlighting
#'
#' @description This function generates a mapping list for Named Entity Recognition (NER)
#' highlighting. The mapping list defines how different entity types should be
#' highlighted in text displays, defining the background color, font color, label, and label color
#' for each entity type.
#'
#' @param df A data frame containing at least two columns:
#'   \itemize{
#'     \item \code{entity}: A character vector of words/entities to be highlighted.
#'     \item \code{tag}: A character vector indicating the entity type of each word/entity.
#'   }
#' @param entity A character vector of entities annotated by the model.
#' @param tag A character vector of tags corresponding to the annotated entities.
#'
#' @return A list with mapping settings for each entity type, where each entity type
#' is represented as a list containing:
#'   \itemize{
#'     \item \code{words}: A character vector of words to be highlighted.
#'     \item \code{background_color}: A character string representing the background color for highlighting the words.
#'     \item \code{font_color}: A character string representing the font color for the words.
#'     \item \code{label}: A character string to label the entity type.
#'     \item \code{label_color}: A character string representing the font color for the label.
#'   }
#'
#' @examples
#'
#' \dontrun{
#'   sample_df <- data.frame(
#'     entity = c("Microsoft", "USA", "dollar", "Bill Gates"),
#'     tag = c("ORG", "LOC", "MISC", "PER"),
#'     stringsAsFactors = FALSE
#'   )
#'   mapping <- map_entities(sample_df)
#' }
#'
#' @export
map_entities <- function(df, entity = "entity", tag = "tag") {

  # Ensure 'entity' and 'tag' are valid column names in df
  if (!(entity %in% names(df)) || !(tag %in% names(df))) {
    stop("The specified entity or tag column names are not found in the data frame.")
  }

  entity_col <- df[[entity]]
  tag_col <- df[[tag]]

  # Ensure 'entity' and 'tag' are character vectors
  if (!is.character(entity_col) || !is.character(tag_col)) {
    stop("Entity and tag columns should be of type character.")
  }

  required_tags <- c("ORG", "LOC", "MISC", "PER")

  # Check if at least one required tag is present
  if (!any(required_tags %in% unique(tag_col))) {
    stop("The data frame must contain at least one named entity tag.")
  }

  coloring_entities <- list(
    ORG = list(words = unique(entity_col[tag_col == "ORG"]),
               background_color = "pink", font_color = "black",
               label = "ORG", label_color = "pink"),
    LOC = list(words = unique(entity_col[tag_col == "LOC"]),
               background_color = "lightblue", font_color = "black",
               label = "LOC", label_color = "blue"),
    MISC = list(words = unique(entity_col[tag_col == "MISC"]),
                background_color = "yellow", font_color = "black",
                label = "MISC", label_color = "orange"),
    PER = list(words = unique(entity_col[tag_col == "PER"]),
               background_color = "lightgreen", font_color = "black",
               label = "PER", label_color = "green")
  )

  return(coloring_entities)
}


#' Highlight Entities with Specified Colors and Tag
#'
#' @description This function highlights specified entities in a text string
#' with specified background colors, font colors, and optional labels.
#' Additionally, it allows setting a specific font type for highlighted text.
#'
#' @param text A character string containing the text to highlight.
#' @param entities_mapping A named list of lists, with each sub-list containing:
#'   \itemize{
#'     \item \code{words}: A character vector of words to highlight.
#'     \item \code{background_color}: A character string specifying the CSS color for the highlight background.
#'     \item \code{font_color}: A character string specifying the CSS color for the highlighted text.
#'     \item \code{label}: A character string specifying a label to append after each highlighted word.
#'     \item \code{label_color}: A character string specifying the CSS color for the label text.
#'   }
#' @param font_family A character string specifying the CSS font family for
#' the highlighted text and label. Default is "Arial".
#'
#' @return An HTML object containing the text with highlighted entities.
#'
#' @examples
#' \dontrun{
#'   entities_mapping <- list(
#'     ORG = list(words = c("ORG1", "ORG2"),
#'                background_color = "pink", font_color = "black",
#'                label = "ORG", label_color = "pink")
#'   )
#'   highlighted_text <- highlight_text("Example text with ORG1 and ORG2.", entities_mapping)
#' }
#'
#' @importFrom htmltools HTML
#' @importFrom stringr str_replace_all
#' @export

# highlight_text <- function(text, entities_mapping, font_family = "Arial") {
#   # Ensure 'entities_mapping' and 'font_family' are not used directly without being checked
#   if(!is.list(entities_mapping) || !all(c("words", "background_color", "font_color", "label", "label_color") %in% names(entities_mapping[[1]]))) {
#     stop("'entities_mapping' must be a list with specific structure.")
#   }
#
#   if(!is.character(font_family) || length(font_family) != 1) {
#     stop("'font_family' must be a single character string.")
#   }
#
#   # Keeping track of replaced words+tags to ensure they are highlighted only once
#   already_replaced <- c()
#
#   for (category in names(entities_mapping)) {
#     words_to_highlight <- entities_mapping[[category]]$words
#     background_color <- entities_mapping[[category]]$background_color
#     font_color <- entities_mapping[[category]]$font_color
#     label <- entities_mapping[[category]]$label
#     label_color <- entities_mapping[[category]]$label_color
#
#     for (word in words_to_highlight) {
#       # Create a unique identifier for each word+tag combination
#       word_tag_identifier <- paste(word, label, sep = "_")
#
#       # Check if this word+tag has not been replaced already
#       if(!(word_tag_identifier %in% already_replaced)) {
#         replacement <- sprintf('<span style="background-color: %s; color: %s; font-family: %s">%s</span> <span style="color: %s; font-family: %s">(%s)</span>', background_color, font_color, font_family, word, label_color, font_family, label)
#
#         # Replace only whole words using word boundaries "\\b"
#         text <- gsub(paste0("\\b", word, "\\b"), replacement, text)
#
#         already_replaced <- c(already_replaced, word_tag_identifier)
#       }
#     }
#   }
#   return(HTML(text))
# }
#
#
#
highlight_text <- function(text, entities_mapping, font_family = "Arial") {
  # Ensure 'entities_mapping' and 'font_family' are not used directly without being checked
  if(!is.list(entities_mapping) || !all(c("words", "background_color", "font_color", "label", "label_color") %in% names(entities_mapping[[1]]))) {
    stop("'entities_mapping' must be a list with specific structure.")
  }

  if(!is.character(font_family) || length(font_family) != 1) {
    stop("'font_family' must be a single character string.")
  }

  # Keeping track of replaced words+tags to ensure they are highlighted only once
  already_replaced <- c()

  for (category in names(entities_mapping)) {
    words_to_highlight <- entities_mapping[[category]]$words
    background_color <- entities_mapping[[category]]$background_color
    font_color <- entities_mapping[[category]]$font_color
    label <- entities_mapping[[category]]$label
    label_color <- entities_mapping[[category]]$label_color

    for (word in words_to_highlight) {
      # Create a unique identifier for each word+tag combination
      word_tag_identifier <- paste(word, label, sep = "_")

      # Check if this word+tag has not been replaced already
      if(!(word_tag_identifier %in% already_replaced)) {
        replacement <- sprintf('<span style="background-color: %s; color: %s; font-family: %s">%s</span> <span style="color: %s; font-family: %s">(%s)</span>', background_color, font_color, font_family, word, label_color, font_family, label)
        text <- gsub(paste0("\\b", word, "\\b"), replacement, text)

        already_replaced <- c(already_replaced, word_tag_identifier)
      }
    }
  }

  # Justify the text
  justified_text <- sprintf('<div style="text-align: justify; font-family: %s">%s</div>', font_family, text)

  return(HTML(justified_text))
}

