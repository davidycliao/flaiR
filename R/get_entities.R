#' @title Tagging Named Entities with Flair Models
#'
#' @description This function takes texts and their corresponding document IDs
#' as inputs, uses the Flair NLP library to extract named entities,
#' and returns a dataframe of the identified entities along with their tags.
#' When no entities are detected in a text, the function returns a data table
#' with NA values.
#'
#' @param texts A character vector containing the texts to process.
#' @param doc_ids A character or numeric vector containing the document IDs
#' corresponding to each text.
#' @param tagger An optional tagger object. If NULL (default), the function will
#'  load a Flair tagger based on the specified language.
#' @param language A character string indicating the language model to load.
#' Default is "en".
#' @param show.text_id A logical value. If TRUE, includes the actual text from
#' which the entity was extracted in the resulting data table. Useful for
#' verification and traceability purposes but might increase the size of
#' the output. Default is FALSE.
#' @param gc.active A logical value. If TRUE, runs the garbage collector after
#' processing all texts. This can help in freeing up memory by releasing unused
#' memory space, especially when processing a large number of texts.
#' Default is FALSE.
#' @return A data table with columns:
#' \describe{
#'   \item{doc_id}{The ID of the document from which the entity was extracted.}
#'   \item{text_id}{If TRUE, the actual text from which the entity
#'   was extracted.}
#'   \item{entity}{The named entity that was extracted from the text.}
#'   \item{tag}{The tag or category of the named entity. Common tags include:
#'   PERSON (names of individuals),
#'   ORG (organizations, institutions),
#'   GPE (countries, cities, states),
#'   LOCATION (mountain ranges, bodies of water),
#'   DATE (dates or periods),
#'   TIME (times of day),
#'   MONEY (monetary values),
#'   PERCENT (percentage values),
#'   FACILITY (buildings, airports),
#'   PRODUCT (objects, vehicles),
#'   EVENT (named events like wars or sports events),
#'   ART (titles of books)}}
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
#' results <- get_entities(texts, doc_ids, tagger_ner)
#' print(results)}
#'
#' @importFrom data.table data.table rbindlist
#' @importFrom reticulate import
#' @importFrom data.table :=
#' @export
get_entities <- function(texts, doc_ids, tagger = NULL, language = NULL,
                         show.text_id = FALSE, gc.active = FALSE) {

  # Check environment pre-requisites
  check_prerequisites()
  check_texts_and_ids(texts, doc_ids)
  check_show.text_id(show.text_id)

  # Load tagger if null
  if (is.null(tagger)) {
    tagger <- load_tagger_ner(language)
  }

  Sentence <- reticulate::import("flair")$data$Sentence

  # Process each text and extract entities
  process_text <- function(text, doc_id) {
    text_id <- NULL
    if (is.na(text) || is.na(doc_id)) {
      return(data.table(doc_id = NA, entity = NA, tag = NA))
    }

    sentence <- Sentence(text)
    tagger$predict(sentence)
    entities <- sentence$get_spans("ner")

    if (length(entities) == 0) {
      return(data.table(doc_id = doc_id, entity = NA, tag = NA))
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
  }
  # Activate garbage collection
  check_and_gc(gc.active)

  results_list <- lapply(seq_along(texts),
                         function(i) {process_text(texts[[i]], doc_ids[[i]])})
  rbindlist(results_list, fill = TRUE)
}
