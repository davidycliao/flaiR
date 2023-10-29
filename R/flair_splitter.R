#' @title Import flair.splitter Module in R
#'
#' @description
#' A function to interface with the Python \code{flair.splitter} module. This function provides access to various
#' sentence splitting strategies implemented in the Flair library:
#' \itemize{
#'   \item \code{NoSentenceSplitter}: Treats the entire text as a single sentence without splitting it.
#'   \item \code{SegtokSentenceSplitter}: Uses the \code{segtok} library to split text into sentences.
#'   \item \code{SpacySentenceSplitter}: Uses the \code{spaCy} library for sentence splitting.
#'   \item \code{TagSentenceSplitter}: Assumes specific tags in the text to indicate sentence boundaries.
#' }
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
#' Python reference for `SegtokSentenceSplitter`:
#' \preformatted{
#' from flair.splitter import *
#' }
#' Additional references for the other classes can be found within the Flair
#' library documentation.
#' \href{https://github.com/flairNLP/flair/blob/master/flair/splitter.py}{Flair GitHub}
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

