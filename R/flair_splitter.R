#' @title Imort Splitter Module
#'
#' @description A function to interface with the Python `flair.splitter` module,
#' specifically utilizing the `SegtokSentenceSplitter` class/method.
#'
#' @return A Python module (`flair.splitter`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' SegtokSentenceSplitter <- flair_splitter.SegtokSentenceSplitter()
#' text <- "I am Taiwanese and come from Taiwan"
#' sentences <- splitter$split(text)
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python reference:
#' \preformatted{
#' from flair.splitter import SegtokSentenceSplitter
#' }
flair_splitter <- function(load = TRUE) {
  flair_splitter <- reticulate::import("flair.splitter")
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
  flair.splitter <- reticulate::import("flair.splitter")
  SegtokSentenceSplitter <-  flair.splitter$SegtokSentenceSplitter()
  return(SegtokSentenceSplitter)
}

