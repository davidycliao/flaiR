#' @title Segtok Sentence Splitter
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
#' splitter <- flair_splitter.SegtokSentenceSplitter()
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python reference:
#' \preformatted{
#' from flair.splitter import SegtokSentenceSplitter
#' }
flair_splitter.SegtokSentenceSplitter <- function() {
  SegtokSentenceSplitter <- reticulate::import("flair.splitter")
  return(SegtokSentenceSplitter)
}
