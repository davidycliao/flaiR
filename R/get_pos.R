#' @title Tagging Part-of-Speech Tagging with Flair Standard Models
#' This function returns a data table of POS tags and other related data for the given texts.
#'
#' @param texts A character vector containing texts to be processed.
#' @param doc_ids A character vector containing document ids.
#' @param tagger A tagger object (default is NULL).
#' @param language The language of the texts (default is NULL).
#' @return A `data.table` containing the following columns:
#' \describe{
#'   \item{\code{doc_id}}{The document identifier corresponding to each text.}
#'   \item{\code{token_id}}{The token number in the original text, indicating the position of the token.}
#'   \item{\code{text_id}}{The actual text input passed to the function.}
#'   \item{\code{token}}{The individual word or token from the text that was POS tagged.}
#'   \item{\code{tag}}{The part-of-speech tag assigned to the token by the Flair library.}
#'   \item{\code{precision}}{A confidence score (numeric) for the assigned POS tag.}
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(data.table)
#' tagger_pos_fast = import("flair.nn")$Classifier$load('pos-fast')
#' texts <- c("UCD is one of the best university in Ireland.",
#'            "UCD is good less better than Trinity.",
#'            "Essex is famous in social science research",
#'            "Essex is not in Russell Group but it is not bad in politics",
#'            "TCD is the oldest one in Ireland.",
#'            "TCD is less better than Oxford")
#' doc_ids <- c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6")
#'
#' get_pos(texts, doc_ids, tagger_pos_fast)
#' }
get_pos <- function(texts, doc_ids,
                    tagger = NULL, ...,language = NULL) {

  # Ensure Python and flair library are available
  if (!reticulate::py_available(initialize = TRUE)) {
    stop("Python is not available in the current R session.")
  }

  if (!reticulate::py_module_available("flair")) {
    stop("flair is not installed in the current Python environment.")
  }

  # Ensure the length of texts and doc_ids are the same
  if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }

  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  Sentence <- flair$data$Sentence

  # Only load Flair and the POS model if tagger is NULL
  if (is.null(tagger)) {

    # Check if 'language' is null and assign default value
    if (is.null(language)) {
      language <- "pos"
      cat("language is not specified", language, "is laoding.")
    }

    # Define supported languages
    supported_lan_models <- c("pos", "pos-fast", "upos", "upos-fast",
                              "pos-multi", "pos-multi-fast", "ar-pos", "de-pos",
                              "de-pos-tweets", "da-pos", "ml-pos",
                              "ml-upos", "pt-pos-clinical", "pos-ukrainian")

    if (!language %in% supported_lan_models) {
      stop(paste("Unsupported language. Supported languages are:", paste(supported_lan_models, collapse = ", ")))
    }

    tagger <- Classifier$load(language)
  }

  # Process each text
  results_list <- list()
  for (i in 1:length(texts)) {

    if (is.na(texts[[i]]) || is.na(doc_ids[[i]])) {
      results_list[[i]] <- data.table(doc_id = NA, Entity = NA, Label = NA)
      next
    }

    sentence <- Sentence(texts[[i]])
    tagger$predict(sentence)
    text <- sentence$text
    tag_list <- sentence$labels

    # Check if there are no pos tag in tag_list
    if (length(tag_list) == 0) {
      df <- data.table(doc_id = doc_ids[[i]], token_id = NA, text_id = NA, token = NA, pos = NA, precision = NA)
    } else {
      df <- data.table(
        doc_id = rep(doc_ids[[i]], length(tag_list)),
        token_id = as.numeric(sapply(tag_list, function(x) gsub("^Token\\[([0-9]+)\\].*$", "\\1", x))),
        text_id = text,
        token = sapply(tag_list, function(x) gsub('^Token\\[\\d+\\]: "(.*)" .*', '\\1', x)),
        tag = sapply(tag_list, function(x) gsub('^Token\\[\\d+\\]: ".*" → (.*) \\(.*\\)', '\\1', x)),
        precision = as.numeric(sapply(tag_list, function(x) gsub(".*\\((.*)\\)", "\\1", x)))
      )
    }
    results_list[[i]] <- df
  }
  results_list <- do.call(rbind, results_list)
  return(results_list)
}
