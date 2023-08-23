#' @title Tagging Named Entities with Flair Standard Models
#' @description Extract named entities from a given text using the flair package.
#'
#' @param texts A character vector of texts from which to extract named entities.
#' @param doc_ids A character vector of document IDs corresponding to the texts.
#' @param tagger An optional tagger object. If NULL, the function will attempt to load the appropriate tagger based on the provided language.
#' @param language A character string indicating the language of the texts. Default is "en" (English).
#' @return A data table containing the document ID, entity, and entity label for each named entity extracted from the texts.
#'
#' @examples
#' \dontrun{
#' texts <- c("UCD is the best university in Ireland.", "Trinity is good too.")
#' doc_ids <- c("doc1", "doc2")
#' results <- get_named_entities_df(texts, doc_ids)
#' print(results)
#' }
#'
#' @importFrom data.table data.table
#' @importFrom reticulate import
#' @importFrom R.utils withTimeout
#' @export
get_ner <- function(texts, doc_ids,
                    tagger = NULL, ..., language = NULL){

  # Check if flair is installed
  if (!check_flair_installed()) {
    stop("flair is required but not installed in the Python environment.")
  }

  # Check internet connection
  if (!has_internet()) {
    stop("Internet connection issue. Please check your network settings.")
  }

  # Ensure matching lengths for texts and doc_ids
  if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }

  # Load tagger if null
  if (is.null(tagger)) {
    # Check if 'language' is null and assign default value
    if (is.null(language)) {
      language <- "en"
      cat("language is not specified", language, "is laoding.")
    }
    # Define supported languages
    supported_languages <- c("en", "de", "nl", "ar", "fr", "da")
    if (!language %in% supported_languages) {
      stop(paste("Unsupported language. Supported languages are:", paste(supported_languages, collapse = ", ")))
    }
    model_name <- switch(language,
                         "en" = "ner",
                         "de" = "de-ner",
                         "fr" = "fr-ner",
                         "nl" = "nl-ner",
                         "da" = "da-ner",
                         "ar" = "ar-ner")
    # Ensure R.utils is available
    if (!require(R.utils)) {
      stop("R.utils is required for the withTimeout function.")
    }

    result <- withTimeout({
      tryCatch({
        SequenceTagger <- reticulate::import("flair.models")$SequenceTagger
        tagger <- SequenceTagger$load(model_name)
        "Success"
      }, error = function(e) {
        if (grepl("ReadTimeoutError", e$message) || grepl("HTTPSConnectionPool", e$message)) {
          return("Timeout error during model loading. The server took too long to respond.")
        } else {
          return("Error during model loading.")
        }
      })
    }, timeout = 10)  # Adjusted timeout value

    if (result != "Success") {
      stop(result)
    }
  }

  Sentence <- reticulate::import("flair")$data$Sentence

  # Process each text
  results_list <- list()
  for (i in 1:length(texts)) {

    if (is.na(texts[[i]]) || is.na(doc_ids[[i]])) {
      results_list[[i]] <- data.table(Doc_ID = NA, Entity = NA, Label = NA)
      next
    }

    sentence <- Sentence(texts[[i]])
    tagger$predict(sentence)
    entities <- sentence$get_spans("ner")

    # Check if there are no entities
    if (length(entities) == 0) {
      df <- data.table(Doc_ID = doc_ids[[i]], Entity = NA, Label = NA)
    } else {
      df <- data.table(
        Doc_ID = rep(doc_ids[[i]], length(entities)),
        Entity = sapply(entities, function(e) e$text),
        Label = sapply(entities, function(e) e$tag)
      )
    }
    results_list[[i]] <- df
  }
  results_list <- do.call(rbind, results_list)
  return(results_list)
}
