#'@title Tagging Sentiment with Flair Standard Models
#' This function takes in texts and their associated document IDs to predict sentiments
#' using the flair Python library.
#'
#' @param texts A list or vector of texts for which sentiment prediction is to be made.
#' @param doc_ids A list or vector of document IDs corresponding to the texts.
#' @param language A character string indicating the language of the texts.
#'   Currently supports "en" (English), "en-fast" (Fast English), and "de" (German).
#'   Default is "en".
#' @param tagger An optional flair sentiment model. If NULL (default),
#'   the function loads the default model based on the language.
#' @param ... Additional arguments passed to next.
#'
#' @return A \code{data.table} containing three columns:
#'   \itemize{
#'     \item \code{doc_iid}: The document ID from the input.
#'     \item \code{sentiment}: Predicted sentiment for the text.
#'     \item \code{score}: score for the sentiment prediction.
#'   }
#'
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(fliaR)
#'
#'
#' texts <- c("UCD is one of the best universities in Ireland.",
#'            "UCD has a good campus but is very far from my apartment in Dublin.",
#'            "Essex is famous for social science research.",
#'            "Essex is not in the Russell Group, but it is famous for political science research.",
#'            "TCD is the oldest university in Ireland.",
#'            "TCD is similar to Oxford.")
#'
#' doc_ids <- c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6")
#'
#' # Load re-trained sentiment ("sentiment") model
#' tagger_sent <- import("flair.nn")$Classifier$load('sentiment')
#'
#' results <- get_sentiments(texts, doc_ids, tagger_sent)
#' print(results)
#' }
#'
#' @importFrom data.table data.table
#' @importFrom reticulate py_available py_module_available import
#'
#' @export
get_sentiments <- function(texts, doc_ids,
                              tagger = NULL, ... , language = NULL) {

  # Ensure that lengths of texts and doc_ids are the same
  if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }

  # Ensure Python and flair library are available
  if (!py_available(initialize = TRUE)) {
    stop("Python is not available in the current R session.")
  }

  if (!py_module_available("flair")) {
    stop("flair is not installed in the current Python environment.")
  }

  Classifier <- import("flair")$nn$Classifier
  Sentence <- import("flair")$data$Sentence

  # Only load Flair and the sentiment model if tagger is NULL
  if (is.null(tagger)) {
    # Check if 'language' is null and assign default value
    if (is.null(language)) {
      language <- "en"
      cat("\n language is not specified.", language, "in Flair is force-loaded. Please ensure that the internet connectivity is stable.")
    }
    # Define supported languages
    supported_languages <- c("en", "en-fast", "de")
    if (!language %in% supported_languages) {
      stop(paste("Unsupported language. Supported languages are:", paste(supported_languages, collapse = ", ")))
    }
    # Select the appropriate model based on available language models
    model_name <- switch(language,
                         "en" = "sentiment",
                         "en-fast" = "sentiment-fast",
                         "de" = "de-offensive-language",
                         stop(paste("Unsupported language:", language))
    )

    # Load the sentiment model
    tagger <- Classifier$load(model_name)
  }

  # Process each text
  results_list <- list()
  for (i in 1:length(texts)) {

    if (is.na(texts[[i]])) {
      results_list[[i]] <- data.table(doc_id = doc_ids[[i]],
                                      text_id = NA,
                                      sentiment = NA,
                                      score = NA)
      next
    }

    # Create a sentence using provided text
    sentence <- Sentence(texts[[i]])

    # Predict sentiment
    tagger$predict(sentence)

    # Check if there's a predicted label
    if (length(sentence$get_labels()) > 0) {
      # Extract predicted sentiment and score
      sentiment_label <- sentence$get_labels()[[1]]$value
      sentiment_score <- sentence$get_labels()[[1]]$score
    } else {
      sentiment_label <- NA
      sentiment_score <- NA
    }

    df <- data.table(doc_id = doc_ids[[i]],
                     text_id = texts[[i]],
                     sentiment = sentiment_label,
                     score = sentiment_score)

    results_list[[i]] <- df
  }

  results_list <- do.call(rbind, results_list)
  return(results_list)
}
