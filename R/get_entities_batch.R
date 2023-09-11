
#' Extract Named Entities from a Batch of Texts
#'
#' This function processes batches of texts and extracts named entities.
#'
#' @param texts A character vector of texts to process.
#' @param doc_ids A vector of document IDs corresponding to each text.
#' @param tagger A pre-loaded Flair NER tagger. Default is NULL, and the tagger is loaded based on the provided language.
#' @param language A character string specifying the language of the texts. Default is "en" (English).
#' @param show.text_id Logical, whether to include the text ID in the output. Default is FALSE.
#' @param gc.active Logical, whether to activate garbage collection after processing each batch. Default is FALSE.
#' @param batch_size An integer specifying the size of each batch. Default is 5.
#' @param device A character string specifying the computation device.
#' It can be either "cpu" or a string representation of a GPU device number.
#' For instance, "0" corresponds to the first GPU. If a GPU device number
#' is provided, it will attempt to use that GPU. The default is "cpu".
#' \itemize{
#'  \item{"cuda" or "cuda:0"}{Refers to the first GPU in the system. If
#'       there's only one GPU, specifying "cuda" or "cuda:0" will allocate
#'       computations to this GPU.}
#'  \item{"cuda:1"}{Refers to the second GPU in the system, allowing allocation
#'       of specific computations to this GPU.}
#'  \item{"cuda:2"}{Refers to the third GPU in the system, and so on for systems
#'       with more GPUs.}
#' }
#'
#' @return A data.table containing the extracted entities, their corresponding
#' tags, and document IDs.
#'
#' @importFrom data.table data.table rbindlist
#' @importFrom reticulate import
#' @importFrom data.table :=
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(fliaR)
#'
#' texts <- c("UCD is one of the best universities in Ireland.",
#'            "UCD has a good campus but is very far from
#'            my apartment in Dublin.",
#'            "Essex is famous for social science research.",
#'            "Essex is not in the Russell Group, but it is
#'            famous for political science research.",
#'            "TCD is the oldest university in Ireland.",
#'            "TCD is similar to Oxford.")
#' doc_ids <- c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6")
#' # Load NER ("ner") model
#' tagger_ner <- load_tagger_ner('ner')
#' results <- get_entities_batch(texts, doc_ids, tagger_ner)
#' print(results)}
#' @export
get_entities_batch <- function(texts, doc_ids, tagger = NULL, language = "en",
                               show.text_id = FALSE, gc.active = FALSE,
                               batch_size = 5, device = "cpu") {

  # Check environment pre-requisites and parameters
  check_prerequisites()
  check_device(device)
  check_batch_size(batch_size)
  check_texts_and_ids(texts, doc_ids)
  check_show.text_id(show.text_id)

  # Load tagger if null
  if (is.null(tagger)) {
    tagger <- load_tagger_ner(language)
  }

  Sentence <- reticulate::import("flair")$data$Sentence

  # Entity Extraction function to process multiple texts in one call
  process_texts_batch <- function(batch_texts, batch_doc_ids) {
    text_id <- NULL
    if (length(batch_texts) != length(batch_doc_ids)) {
      stop("The lengths of batch_texts and batch_doc_ids do not match.")
    }

    results_list <- lapply(seq_along(batch_texts), function(i) {
      text <- batch_texts[[i]]
      doc_id <- batch_doc_ids[[i]]

      if (is.na(text) || is.na(doc_id)) {
        return(data.table(doc_id = NA,
                          entity = NA,
                          tag = NA,
                          text_id = ifelse(show.text_id, text, NA))
               )
      }

      sentence <- Sentence(text)
      tagger$predict(sentence)
      entities <- sentence$get_spans("ner")

      if (length(entities) == 0) {
        return(data.table(doc_id = doc_id,
                          entity = NA,
                          tag = NA,
                          text_id = ifelse(show.text_id, text, NA)))
      }

      # Unified data table creation process
      dt <- data.table(
        doc_id = rep(doc_id, length(entities)),
        entity = vapply(entities, function(e) e$text, character(1)),
        tag = vapply(entities, function(e) e$tag, character(1))
      )

      if (isTRUE(show.text_id)) {
        dt[, text_id := text]
      }

      return(dt)
    })

    return(rbindlist(results_list, fill = TRUE)) # Return the combined result for this batch

  }

  # Batch processing
  num_batches <- ceiling(length(texts) / batch_size)
  batched_results <- lapply(1:num_batches, function(b) {
    start_idx <- (b - 1) * batch_size + 1
    end_idx <- min(b * batch_size, length(texts))
    process_texts_batch(texts[start_idx:end_idx], doc_ids[start_idx:end_idx])
  })


  # Activate garbage collection
  check_and_gc(gc.active)

  return(rbindlist(batched_results, fill = TRUE))
}
