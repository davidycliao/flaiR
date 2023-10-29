#' @title Import flair.data Module
#'
#' @description
#' The `flair.data` module provides essential utilities for text data
#' processing and representation in the Flair library. This function
#' gives access to various classes and utilities in the `flair.data` module,
#' most notably:
#' \itemize{
#'   \item \strong{Sentence}: Represents a sentence, which is a list of
#'   Tokens. This class provides various utilities for sentence
#'   manipulation, such as adding tokens, tagging with pre-trained models,
#'   and obtaining embeddings.
#'   \item \strong{Token}: Represents a word or a sub-word unit in a sentence.
#'   It can carry various annotations such as named entity tags, part-of-speech
#'   tags, and embeddings. Additionally, the token provides functionalities
#'   to retrieve or check its annotations.
#'   \item \strong{Corpus}: Represents a collection of sentences,
#'   facilitating operations like splitting into train/test/development
#'    sets and applying transformations. It is particularly useful
#'    for training and evaluating models on custom datasets.
#' }
#' Additionally, the module offers utilities for reading data in the CoNLL
#' format, a common format for NER, POS tagging, and more. It also contains
#' the `Dictionary` class for item-index mapping, facilitating the conversion
#' of text into machine-readable formats. This function provides a bridge
#' to access these functionalities directly from R.
#'
#' @return A Python module (`flair.data`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' Sentence <- flair_data()$Sentence
#' Token <- flair_data()$Token
#' Corpus <- flair_data()$Corpus
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python reference:
#' \preformatted{
#' from flair.data import Sentence
#' }
flair_data <- function() {
  flair_data <- import("flair.data")
  return(flair_data)
}


#' @title Create a Flair Sentence
#'
#' @description Flair is a powerful NLP framework that leverages state-of-the-art
#' embeddings for various natural language processing tasks.
#'
#' @param sentence_text A character string to be converted into a Flair Sentence
#' object.
#' @return A Flair Sentence object.
#'
#' @examples
#' \dontrun{
#' flair_data.Sentence("The quick brown fox jumps over the lazy dog.")}
#'
#' @references
#' Python equivalent: \preformatted{ from flair.data import Sentence
#' sentence = Sentence("The quick brown fox jumps over the lazy dog.")
#' }
#'
#' @seealso [Flair's GitHub Repository about Senetence object.](https://flairnlp.github.io/docs/tutorial-basics/basic-types)
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
