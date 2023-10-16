#' @title Batch Process of Part-of-Speech Tagging
#'
#' @description This function returns a data table of POS tags and other related
#' data for the given texts using batch processing.
#'
#' @param texts A character vector containing texts to be processed.
#' @param doc_ids A character vector containing document ids.
#' @param tagger A tagger object (default is NULL).
#' @param language The language of the texts (default is NULL).
#' @param show.text_id A logical value. If TRUE, includes the actual text from
#' which the entity was extracted in the resulting data table. Useful for
#' verification and traceability purposes but might increase the size of
#' the output. Default is FALSE.
#' @param gc.active A logical value. If TRUE, runs the garbage collector after
#' processing all texts. This can help in freeing up memory by releasing unused
#' memory space, especially when processing a large number of texts.
#' Default is FALSE.
#' @param batch_size An integer specifying the size of each batch. Default is 5.
#' @param device A character string specifying the computation device.
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
#' @return A data.table containing the following columns:
#' \describe{
#'   \item{\code{doc_id}}{The document identifier corresponding to each text.}
#'   \item{\code{token_id}}{The token number in the original text,
#'   indicating the position of the token.}
#'   \item{\code{text_id}}{The actual text input passed to the function (if show.text_id is TRUE).}
#'   \item{\code{token}}{The individual word or token from the text that was
#'   POS tagged.}
#'   \item{\code{tag}}{The part-of-speech tag assigned to the token by
#'   the Flair library.}
#'   \item{\code{precision}}{A confidence score (numeric) for the
#'   assigned POS tag.}
#' }
#'
#' @import reticulate
#' @export
#'
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(fliaR)
#' tagger_pos_fast <- load_tagger_pos('pos-fast')
#' texts <- c("UCD is one of the best universities in Ireland.",
#'            "Essex is not in the Russell Group, but it is famous for political science research.",
#'            "TCD is the oldest university in Ireland.")
#' doc_ids <- c("doc1", "doc2", "doc3")
#'
#' # Using the batch_size parameter
#' get_pos_batch(texts, doc_ids, tagger_pos_fast, batch_size = 2)
#' }

get_pos_batch <- function(texts, doc_ids, tagger = NULL, language = NULL,
                          show.text_id = FALSE, gc.active = FALSE,
                          batch_size = 5, device = "cpu", verbose = TRUE) {

  # Check environment pre-requisites and parameters
  check_prerequisites()
  check_texts_and_ids(texts, doc_ids)
  check_show.text_id(show.text_id)
  check_device(device)
  check_batch_size(batch_size)

  # Import the `Sentence` tokenizer and `Classifier` from Python's Flair
  flair <- reticulate::import("flair")
  Sentence <- flair$data$Sentence

  # Load tagger if null
  if (is.null(tagger)) {
    tagger <- load_tagger_pos(language)
  }

  # Function to process a single sentence
  process_single_sentence <- function(sentence, doc_id) {
    text <- sentence$text
    tag_list <- sentence$labels

    # Check if there are no pos tag in tag_list if tag_list empty returns NAs
    if (length(tag_list) == 0) {
      return(data.table(doc_id = doc_id,
                        token_id = NA,
                        text_id = ifelse(show.text_id, text, NA),
                        token = NA,
                        tag = NA,
                        precision = NA))
    } else {
      return(data.table(
        doc_id = rep(doc_id, length(tag_list)),
        token_id = as.numeric(vapply(tag_list, function(x) gsub("^Token\\[([0-9]+)\\].*$", "\\1", x), character(1))),
        text_id = ifelse(show.text_id, text, NA),
        token = vapply(tag_list, function(x) gsub('^Token\\[\\d+\\]: "(.*)" .*', '\\1', x), character(1)),
        tag = vapply(tag_list, function(x) gsub('^Token\\[\\d+\\]: ".*" \u2192 (.*) \\(.*\\)', '\\1', x), character(1)),
        precision = as.numeric(vapply(tag_list, function(x) gsub(".*\\((.*)\\)", "\\1", x), character(1)))
      ))
    }
  }

  process_batch <- function(start_idx) {
    if (verbose) {
      cat(paste("Processing batch starting at index:", start_idx, "\n"))
    }

    batch_texts <- texts[start_idx:(start_idx+batch_size-1)]
    batch_ids <- doc_ids[start_idx:(start_idx+batch_size-1)]
    batch_sentences <- lapply(batch_texts, Sentence)
    lapply(batch_sentences, tagger$predict)

    dt_list <- lapply(seq_along(batch_sentences), function(i) {
      process_single_sentence(batch_sentences[[i]], batch_ids[[i]])
    })

    return(rbindlist(dt_list, fill = TRUE)) # Bind the results within this batch together
  }

  # Split the data into batches and process each batch
  n <- length(texts)
  idxs <- seq(1, n, by = batch_size)
  results_list <- lapply(idxs, process_batch)

  # Combine the results from all batches
  results_dt <- rbindlist(results_list, fill = TRUE)

  check_and_gc(gc.active)

  return(results_dt)
}
