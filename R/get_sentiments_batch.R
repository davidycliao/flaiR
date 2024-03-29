#' @title Batch Process of Tagging Sentiment with Flair Models
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
#' @param batch_size An integer specifying the number of texts to be processed
#' at once. It can help optimize performance by leveraging parallel processing.
#' Default is 5.
#' @param device A character string specifying the computation device.
#' It can be either "cpu" or a string representation of a GPU device number.
#' For instance, "0" corresponds to the first GPU. If a GPU device number
#' is provided, it will attempt to use that GPU. The default is "cpu".
#' \itemize{
#'  \item{"cuda" or "cuda:0" ("mps" or "mps:0" in Mac M1/M2 )}{Refers to the first GPU in the system. If
#'       there's only one GPU, specifying "cuda" or "cuda:0" will allocate
#'       computations to this GPU.}
#'  \item{"cuda:1" ("mps:1")}{Refers to the second GPU in the system, allowing allocation
#'       of specific computations to this GPU.}
#'  \item{"cuda:2" ("mps:2)}{Refers to the third GPU in the system, and so on for systems
#'       with more GPUs.}
#' }
#'
#' @param verbose A logical value. If TRUE, the function prints batch processing
#' progress updates. Default is TRUE.
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
#' tagger_sent <- load_tagger_sentiments('sentiment')
#'
#' results <- get_sentiments_batch(texts, doc_ids, tagger_sent, batch_size = 3)
#' print(results)
#' }
#'
#' @importFrom data.table data.table
#' @importFrom reticulate py_available py_module_available import
#' @importFrom data.table :=
#' @export
get_sentiments_batch <- function(texts, doc_ids,
                                 tagger = NULL, ..., language = NULL,
                                 show.text_id = FALSE, gc.active = FALSE,
                                 batch_size = 5, device = "cpu", verbose = FALSE) {
  # Check environment pre-requisites and parameters
  check_prerequisites()
  check_device(device)
  check_batch_size(batch_size)
  check_texts_and_ids(texts, doc_ids)
  check_show.text_id(show.text_id)

  # Load the Sentence tokenizer from the Flair library in Python.
  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  Sentence <- flair$data$Sentence

  # Load tagger if null
  if (is.null(tagger)) {
    tagger <- load_tagger_sentiments(language)
  }

  # `process_batch` to batch process
  process_batch <- function(texts_batch, doc_ids_batch) {
    text_id <- NULL
    sentences <- lapply(texts_batch, flair$data$Sentence)

    # Predict sentiments for the entire batch
    tagger$predict(sentences)

    results <- lapply(seq_along(sentences), function(i) {
      sentence <- sentences[[i]]
      doc_id <- doc_ids_batch[i]

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
        dt[, text_id := texts_batch[i]]
      }
      dt
    })

    return(rbindlist(results, fill = TRUE))
  }

  # Split texts into batches and process
  num_batches <- ceiling(length(texts) / batch_size)
  results_list <- lapply(1:num_batches, function(i) {
    start_idx <- (i-1)*batch_size + 1
    end_idx <- min(i*batch_size, length(texts))

    if (isTRUE(verbose)) {
      cat(sprintf("Processing batch %d out of %d...\n", i, num_batches))
    }

    process_batch(texts[start_idx:end_idx], doc_ids[start_idx:end_idx])
  })

  results_dt <- rbindlist(results_list, fill = TRUE)

  # Activate garbage collection
  check_and_gc(gc.active)

  return(results_dt)
}

