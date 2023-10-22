#' @title Import Splitter Module
#'
#' @description A function to interface with the Python `flair.splitter` module.
#' It provides access to various sentence splitting strategies implemented in the Flair library:
#' 1. `NoSentenceSplitter`: Treats the entire text as a single sentence without splitting it.
#' 2. `SegtokSentenceSplitter`: Uses the `segtok` library to split text into sentences.
#' 3. `SpacySentenceSplitter`: Uses the `spaCy` library for sentence splitting.
#' 4. `TagSentenceSplitter`: Assumes specific tags in the text to indicate sentence boundaries.
#'
#' @return A Python module (`flair.splitter`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' SegtokSentenceSplitter <- flair_splitter$SegtokSentenceSplitter()
#' text <- "I am Taiwanese and come from Taiwan"
#' sentences <- splitter$split(text)
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' - Python reference for `SegtokSentenceSplitter`:
#' \preformatted{
#' from flair.splitter import SegtokSentenceSplitter
#' }
#' - Additional references for the other classes can be found within the Flair library documentation.
#'
flair_splitter <- function() {
  flair_splitter <- import("flair.splitter")
  return(flair_splitter)
}


#' @title Segtok Sentence Splitter
#'
#' @description Interface with the Python `flair.splitter` module to utilize the
#' `SegtokSentenceSplitter` class/method.
#'
#' @return An instance of the Python class `SegtokSentenceSplitter` from the
#' `flair.splitter` module.
#'
#' @examples
#' \dontrun{
#' splitter <- flair_splitter.SegtokSentenceSplitter()
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.splitter import SegtokSentenceSplitter
#' }
#'
#' @export
flair_splitter.SegtokSentenceSplitter <- function() {
  flair.splitter <- import("flair.splitter")
  SegtokSentenceSplitter <-  flair.splitter$SegtokSentenceSplitter()
  return(SegtokSentenceSplitter)
}

