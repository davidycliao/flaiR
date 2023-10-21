#' @title Flair Data Import Function
#'
#' @description This function imports and returns the `data` module from the
#' Flair package in Python.
#'
#' @return A reference to the `data` module of the Flair Python package.
#'
#' @export
#'
#' @references
#' From Flair's Python library: \code{from flair.data import *}
#'
#' @importFrom reticulate import
flair_data <- function() {
  flair.data <- import("flair.data")
  return(flair.data)
}


#' @title Create a Flair Sentence Object
#'
#' @description  This function uses the {reticulate} package to interface with Python and
#' create a Flair Sentence object.
#'
#' @param sentence_text A character string to be converted into a Flair Sentence object.
#' @return A Flair Sentence object.
#'
#' @examples
#' \dontrun{
#' flair_data.sentence("The quick brown fox jumps over the lazy dog.")
#' }
#'
#' @references
#' Python equivalent: \preformatted{
#' from flair.data import Sentence
#' sentence = Sentence("The quick brown fox jumps over the lazy dog.")
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_data.Sentence <- function(sentence_text) {
  flair_data <- import('flair.data')
  sentence <- flair_data$Sentence(sentence_text)
  return(sentence)
}
