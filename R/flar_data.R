#' @title Import flair.data Module
#'
#' @description A function to interface with the Python `flair.splitter` module,
#' specifically to load the `SegtokSentenceSplitter` class/method.
#'
#' @return A Python module (`flair.splitter`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' Sentence <- flair_data()$Sentence
#' sentences <- Sentence("I am Taiwanese and come from Taiwan.")
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python reference:
#' \preformatted{
#' from flair.data import Sentence
#' }
flair_data <- function(load = TRUE) {
  flair_data <- import("flair.data")
  return(flair_data)
}

#' @title Create a Flair Sentence
#'
#' @description Flair is a powerful NLP framework that leverages state-of-the-art embeddings for various natural language processing tasks.
#' This function uses the {reticulate} package to interface with Python and
#' create a Flair Sentence object.
#'
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
#' @seealso \link{https://flairnlp.github.io/docs/tutorial-basics/basic-types}, [Flair's GitHub Repository about `Senetence`](https://flairnlp.github.io/docs/tutorial-basics/basic-types)
#'
#' @note Ensure the input string is in a language compatible with the intended
#' Flair model. In R, when processing multiple text, you can use purrr or
#' the basic R functions lapply and sapply.
#'
#' @importFrom reticulate import
#'
#' @export
flair_data.Sentence <- function(sentence_text) {
  flair_data <- import('flair.data')
  sentence <- flair_data$Sentence(sentence_text)
  return(sentence)
}

