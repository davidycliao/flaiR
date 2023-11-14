#' @title Import flair.data Module
#'
#' @description
#' The `flair.data` module provides essential utilities for text data
#' processing and representation in the Flair library. This function
#' gives access to various classes and utilities in the `flair.data` module,
#' most notably:
#' \itemize{
#'  \item \strong{BoundingBox(left, top, right, bottom)}: Bases: tuple (Python); list (R)
#'   \itemize{
#'      \item left - str. Alias for field number 0.
#'      \item top - int Alias for field number 1
#'      \item right - int Alias for field number 2
#'      \item bottom - int Alias for field number 3
#'   }
#'
#'   \item \strong{Sentence(text, use_tokenizer=True, language_code=None,
#'   start_position=0)}:A Sentence is a list of tokens and is used to
#'   represent a sentence or text fragment. `Sentence` can be imported by
#'   `flair_data()$Sentence` via {flaiR}.
#'   \itemize{
#'      \item text \code{Union[str, List[str], List[Token]]} - The original string (sentence), or a pre-tokenized list of tokens.
#'      \item use_tokenizer \code{Union[bool, Tokenizer]} - Specify a custom tokenizer to split the text into tokens. The default is \code{flair.tokenization.SegTokTokenizer}. If \code{use_tokenizer} is set to \code{False}, \code{flair.tokenization.SpaceTokenizer} will be used instead. The tokenizer will be ignored if \code{text} refers to pre-tokenized tokens.
#'      \item language_code \code{Optional[str]} - Language of the sentence. If not provided, \code{langdetect} will be called when the \code{language_code} is accessed for the first time.
#'      \item start_position \code{int} - Start character offset of the sentence in the superordinate document.
#'   }
#'   \item \strong{Span(tokens, tag=None, score=1.0)}: Bases: _PartOfSentence.
#'   A Span is a slice of a Sentence, consisting of a list of Tokens.
#'    `Span` can be imported by `flair_data()$Span`.
#'
#'   \item \strong{Token(text, head_id=None, whitespace_after=1, start_position=0, sentence=None)}:
#'   This class represents one word in a tokenized sentence.
#'   Each token may have any number of tags. It may also point to its head in a
#'   dependency tree. `Token` can be imported by `flair_data()$Token` via {flaiR}.
#'
#'   \item \strong{Corpus(train=None, dev=None, test=None, name='corpus', sample_missing_splits=True)}: Represents a collection of sentences,
#'   facilitating operations like splitting into train/test/development
#'    sets and applying transformations. It is particularly useful
#'    for training and evaluating models on custom datasets.
#'    `Corpus` can be imported by `flair_data()$Corpus` via {flaiR}.
#'
#'   \item \strong{Dictionary}: Represents a mapping between items and indices.
#'   It is useful for converting text into machine-readable formats.
#' }
#'
#' @return A Python module (`flair.data`). To access the classes and utilities.
#'
#' @seealso [flair.data](https://flairnlp.github.io/flair/master/api/flair.data.html#)
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
