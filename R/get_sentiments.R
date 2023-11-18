#' @title Tagging Sentiment with Flair Standard Models
#'
#' @description This function takes in texts and their associated document IDs
#' to predict sentiments using the flair Python library.
#'
#' @param texts A list or vector of texts for which sentiment prediction is
#' to be made.
#' @param doc_ids A list or vector of document IDs corresponding to the texts.
#' @param language A character string indicating the language of the texts.
#'   Currently supports "sentiment" (English), "sentiment-fast" (English), and
#'  "de-offensive-language" (German)
#' @param tagger An optional flair sentiment model. If NULL (default),
#'   the function loads the default model based on the language.
#' @param ... Additional arguments passed to next.
#' @param show.text_id A logical value. If TRUE, includes the actual text from
#' which the sentiment was predicted. Default is FALSE.
#' @param gc.active A logical value. If TRUE, runs the garbage collector after
#' processing all texts. This can help in freeing up memory by releasing unused
#' memory space, especially when processing a large number of texts.
#' Default is FALSE.
#'
#' @return A `data.table` containing three columns:
#'   \itemize{
#'     \item `doc_id`: The document ID from the input.
#'     \item `sentiment`: Predicted sentiment for the text.
#'     \item `score`: Score for the sentiment prediction.
#'   }
#'
#' @examples
#' \dontrun{
#' library(flaiR)
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
#' tagger_sent <- load_tagger_sentiments('sentiment')
#'
#' results <- get_sentiments(texts, doc_ids, tagger_sent)
#' print(results)
#' }
#'
#' @importFrom data.table data.table
#' @importFrom reticulate py_available py_module_available import
#' @importFrom data.table :=
#' @export
get_sentiments <- function(texts, doc_ids,
                           tagger = NULL,
                           ...,
                           language = NULL,
                           show.text_id = FALSE, gc.active = FALSE ) {
    # Check environment pre-requisites
    check_prerequisites()
    check_show.text_id(show.text_id)

    # Check and prepare texts and doc_ids
    texts_and_ids <- check_texts_and_ids(texts, doc_ids)
    texts <- texts_and_ids$texts
    doc_ids <- texts_and_ids$doc_ids

    # Load the Sentence tokenizer from the Flair library in Python.
    flair <- reticulate::import("flair")
    Classifier <- flair$nn$Classifier
    Sentence <- flair$data$Sentence

    # Load tagger if null
    if (is.null(tagger)) {
      tagger <- load_tagger_sentiments(language)
    }

    # Function to process each text
    process_text <- function(text, doc_id) {
      text_id <- NULL
      if (is.na(text)) {
        return(data.table(doc_id = doc_id, text_id = NA, sentiment = NA, score = NA))
      }

      # Create a sentence using provided text
      sentence <- Sentence(text)

      # Predict sentiment
      tagger$predict(sentence)

      # Check if there's a predicted label
      if (length(sentence$get_labels()) > 0) {
        sentiment_label <- sentence$get_labels()[[1]]$value
        sentiment_score <- sentence$get_labels()[[1]]$score
      } else {
        sentiment_label <- NA
        sentiment_score <- NA
      }

      dt <- data.table(doc_id = doc_id,
                       sentiment = sentiment_label,
                       score = sentiment_score)

      if (isTRUE(show.text_id)) {
        dt[, text_id := text]
      }

      return(dt)
    }

    results_list <- lapply(seq_along(texts), function(i) process_text(texts[i], doc_ids[i]))
    results_dt <- rbindlist(results_list, fill=TRUE)

    # Activate garbage collection
    check_and_gc(gc.active)
    return(results_dt)
  }
