#' @title Tagging Part-of-Speech Tagging with Flair Standard Models
#'
#' @description This function returns a data table of POS tags and other related data for the given texts.
#'
#' @param texts A character vector containing texts to be processed.
#' @param doc_ids A character vector containing document ids.
#' @param tagger A tagger object (default is NULL).
#' @param language The language of the texts (default is NULL).
#' @param show.text_id A logical value. If TRUE, includes the actual text from
#' which the entity was extracted in the resulting data table. Useful for
#' verification and traceability purposes but might increase the size of the output.
#' Default is FALSE.
#' @param gc.active A logical value. If TRUE, runs the garbage collector after
#' processing all texts. This can help in freeing up memory by releasing unused
#' memory space, especially when processing a large number of texts. Default is FALSE.
#' @return A data.table containing the following columns:
#' \describe{
#'   \item{\code{doc_id}}{The document identifier corresponding to each text.}
#'   \item{\code{token_id}}{The token number in the original text, indicating the position of the token.}
#'   \item{\code{text_id}}{The actual text input passed to the function.}
#'   \item{\code{token}}{The individual word or token from the text that was POS tagged.}
#'   \item{\code{tag}}{The part-of-speech tag assigned to the token by the Flair library.}
#'   \item{\code{precision}}{A confidence score (numeric) for the assigned POS tag.}
#' }
#'
#' @import reticulate
#' @export
#'
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(fliaR)
#' tagger_pos_fast = import("flair.nn")$Classifier$load('pos-fast')
#' texts <- c("UCD is one of the best universities in Ireland.",
#'            "Essex is not in the Russell Group, but it is famous for political science research.",
#'            "TCD is the oldest university in Ireland.")
#' doc_ids <- c("doc1", "doc2", "doc3")
#'
#' get_pos(texts, doc_ids, tagger_pos_fast)
#' }
get_pos <- function(texts, doc_ids, tagger = NULL, language = NULL,
                    show.text_id = FALSE, gc.active = FALSE ) {
  # Check environment pre-requisites
  flaiR::check_prerequisites()

  # Ensure the length of texts and doc_ids are the same
  if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }

  # Load the `Sentence` tokenizer from the Flair library in Python.
  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  Sentence <- flair$data$Sentence

  # Load tagger if null
  if (is.null(tagger)) {
    tagger <- load_tagger_pos(language)
  }

  process_text <- function(i) {
    if (is.na(texts[[i]]) || is.na(doc_ids[[i]])) {
      return(data.table(doc_id = NA,
                        token_id = NA,
                        text_id = ifelse(show.text_id, text, NA),
                        token = NA,
                        tag = NA,
                        precision = NA
                        ))
    }
    sentence <- Sentence(texts[[i]])
    tagger$predict(sentence)
    text <- sentence$text
    tag_list <- sentence$labels

    # Check if there are no pos tag in tag_list
    if (length(tag_list) == 0) {
      return(data.table(doc_id = doc_ids[[i]], token_id = NA, text_id = ifelse(show.text_id, text, NA), token = NA, pos = NA, precision = NA))
    } else {
      return(data.table(
        doc_id = rep(doc_ids[[i]], length(tag_list)),
        token_id = as.numeric(vapply(tag_list, function(x) gsub("^Token\\[([0-9]+)\\].*$", "\\1", x), character(1))),
        text_id = ifelse(show.text_id, text, NA),
        token = vapply(tag_list, function(x) gsub('^Token\\[\\d+\\]: "(.*)" .*', '\\1', x), character(1)),
        tag = vapply(tag_list, function(x) gsub('^Token\\[\\d+\\]: ".*" \u2192 (.*) \\(.*\\)', '\\1', x), character(1)),
        precision = as.numeric(vapply(tag_list, function(x) gsub(".*\\((.*)\\)", "\\1", x), character(1)))
      ))
    }
  }
  results_list <- lapply(1:length(texts), process_text)
  results_dt <- rbindlist(results_list, fill=TRUE)
  # activate garbage collection
  if (isTRUE(gc.active)) {
    gc()
    message("Garbage collection after processing all texts")}
  return(results_dt)
}

