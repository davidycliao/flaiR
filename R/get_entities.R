#' @title Tagging Named Entities with Flair Standard Models
#'
#' @description This function takes texts and their corresponding document IDs as inputs, uses the Flair NLP library to extract named entities,
#' and returns a dataframe of the identified entities along with their tags.
#'
#' @param texts A character vector containing the texts to process.
#' @param doc_ids A character or numeric vector containing the document IDs corresponding to each text.
#' @param tagger An optional tagger object. If NULL (default), the function will load a Flair tagger based on the specified language.
#' @param language A character string indicating the language model to load. Default is "en".
#'
#' @return A data table with columns:
#' \describe{
#'   \item{doc_id}{The ID of the document from which the entity was extracted.}
#'   \item{text_id}{The actual text from which the entity was extracted.}
#'   \item{entity}{The named entity that was extracted from the text.}
#'   \item{tag}{The tag or category of the named entity (e.g., PERSON, ORGANIZATION).}
#' }
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(fliaR)
#'
#' texts <- c("UCD is one of the best universities in Ireland.",
#'            "UCD has a good campus but is very far from my apartment in Dublin.",
#'            "Essex is famous for social science research.",
#'            "Essex is not in the Russell Group, but it is famous for political science research.",
#'            "TCD is the oldest university in Ireland.",
#'            "TCD is similar to Oxford.")
#' doc_ids <- c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6")
#' # Load NER ("ner") model
#' tagger_ner <- import("flair.nn")$Classifier$load('ner')
#' results <- get_entities(texts, doc_ids, tagger_ner)
#' print(results)}
#'
#' @importFrom data.table data.table rbindlist
#' @importFrom reticulate import
#' @export
get_entities <- function(texts, doc_ids, tagger = NULL, language = NULL) {

  # Check Environment Pre-requisites
  check_prerequisites()

  # Ensure matching lengths for texts and doc_ids
  if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }
  # Load tagger if null
  if (is.null(tagger)) {
    tagger <- load_tagger_ner(language)
  }

  Sentence <- reticulate::import("flair")$data$Sentence

  # Process each text and extract entities
  process_text <- function(text, doc_id) {
    if (is.na(text) || is.na(doc_id)) {
      return(data.table(doc_id = NA, entity = NA, tag = NA))
    }

    sentence <- Sentence(text)
    tagger$predict(sentence)
    entities <- sentence$get_spans("ner")

    if (length(entities) == 0) {
      return(data.table(doc_id = doc_id, entity = NA, tag = NA))
    }

    data.table(
      doc_id = rep(doc_id, length(entities)),
      text_id = text,
      entity = vapply(entities, function(e) e$text, character(1)),
      tag = vapply(entities, function(e) e$tag, character(1))
    )
  }

  results_list <- lapply(seq_along(texts), function(i) {
    process_text(texts[[i]], doc_ids[[i]])
  })

  rbindlist(results_list)
}


# get_entities <- function(texts, doc_ids, tagger = NULL, language = "en") {
#
#   # Check Environment Pre-requisites
#   check_prerequisites()
#
#   # Ensure matching lengths for texts and doc_ids
#   if (length(texts) != length(doc_ids)) {
#     stop("The lengths of texts and doc_ids do not match.")
#   }
#
#   # Load tagger if null
#   if (is.null(tagger)) {
#
#     # Check if the language model is supported by Flair's available language models.
#     supported_lan_models <- c("ner", "de-ner", "fr-ner", "nl-ner", "da-ner", "ar-ner")
#     language_model_map <- c("en" = "ner", "de" = "de-ner", "fr" = "fr-ner", "nl" = "nl-ner", "da" = "da-ner", "ar" = "ar-ner")
#
#     # Translate language to model name if necessary
#     if (language %in% names(language_model_map)) {
#       language <- language_model_map[[language]]
#     }
#
#     # Ensure the model is supported
#     check_language_supported(language = language, supported_lan_models = supported_lan_models)
#
#     # Load the model
#     SequenceTagger <- reticulate::import("flair.models")$SequenceTagger
#     tagger <- SequenceTagger$load(language)
#   }
#
#   Sentence <- reticulate::import("flair")$data$Sentence
#
#   # Process each text and extract entities
#   results_list <- list()
#   for (i in 1:length(texts)) {
#     if (is.na(texts[[i]]) || is.na(doc_ids[[i]])) {
#       results_list[[i]] <- data.table(doc_id = NA, entity = NA, tag = NA)
#       next
#     }
#
#     sentence <- Sentence(texts[[i]])
#     tagger$predict(sentence)
#     entities <- sentence$get_spans("ner")
#
#     if (length(entities) == 0) {
#       df <- data.table(doc_id = doc_ids[[i]], entity = NA, tag = NA)
#     } else {
#       df <- data.table(
#         doc_id = rep(doc_ids[[i]], length(entities)),
#         text_id = texts[[i]],
#         entity = sapply(entities, function(e) e$text),
#         tag = sapply(entities, function(e) e$tag)
#       )
#     }
#     results_list[[i]] <- df
#   }
#   results_list <- do.call(rbind, results_list)
#   return(results_list)
# }

