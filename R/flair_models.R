#' @title Import the flair.models Python module
#'
#' @description
#' This function imports the `flair.models` module from the Flair NLP Python
#' library, providing access to several powerful models tailored for NLP tasks.
#' Here are three primary methods available in this module:
#'
#' \itemize{
#'   \item **TextClassifier:** This method represents a neural network
#'   model designed for text classification tasks. Given a piece of text,
#'   it predicts a class label or category. For instance, it can be used
#'   to classify movie reviews as positive or negative.
#'   \item **SequenceTagger:** Tailored for tasks like Named Entity
#'   Recognition (NER) and Part-of-Speech (POS) tagging, this method
#'   annotates sequences of words. For NER, it could tag entities in a
#'   sentence such as locations, persons, or organizations. For POS tagging,
#'   it can label each word in a sentence with its grammatical role
#'   like noun, verb, adjective, etc.
#'
#'   \item **LanguageModel:** This method represents a model
#'   trained to predict the next word in a sequence, making it powerful
#'   for tasks like text generation and completion. It learns the
#'   statistical properties and structure of the language, and can be
#'   the base for transfer learning in other NLP tasks.
#' }
#'
#' @return A Python module object representing flair.models.
#'
#' @references
#' Python equivalent: \preformatted{
#' from flair.models import *
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_models <- function() {
  flair.models <- import("flair.models")
  return(flair.models)
}


#' @title Retrieve TextClassifier from flair.models
#'
#' @description This function utilizes the reticulate package to directly import
#' TextClassifier from flair.models in the Flair NLP Python library. Ensure that
#' the Python environment is properly set up and the Flair package is installed.
#'
#' @return A Python class representing flair.models.TextClassifier.
#'
#'
#' @references
#' Python equivalent: \preformatted{
#' from flair.models import TextClassifier
#' }
#'
#' @examples
#' # Load the TextClassifier
#' TextClassifier <- flair_models.TextClassifier()
#
#' # Load a pre-trained sentiment model
#' classifier <- TextClassifier$load('sentiment')
#'
#' # Create a sentence object
#' Sentence <- flair_data()$Sentence
#' sentence <- Sentence("Flair is pretty neat!")
#'
#' # Predict the sentiment
#' classifier$predict(sentence)
#
#' # Display the sentiment
#' print(sentence$get_labels())
#'
#' @importFrom reticulate import
#' @export
flair_models.TextClassifier <- function() {
  flair.models <- import("flair.models")
  TextClassifier <- flair.models$TextClassifier
  return(TextClassifier)
}


#' @title Access Flair's SequenceTagger
#'
#' @description
#' This function utilizes the reticulate package to import the `SequenceTagger`s
#' from Flair's models in Python, enabling interaction with Flair's sequence
#' tagging models in an R environment.
#'
#' @details
#' The function does not take any parameters and directly returns the
#' `SequenceTagger` when called, which can be used further for sequence tagging
#' tasks using pre-trained models from Flair.
#'
#' @return
#' A Python module (`SequenceTagger`) from Flair, which can be utilized to load
#' and use sequence tagging models.
#'
#' @examples
#' \dontrun{
#' sequence_tagger <- flair_models.sequencetagger()
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.models import SequenceTagger
#' }
#'
#' @seealso
#' <https://github.com/flairNLP/flair> for more information on Flair's
#' capabilities in NLP and sequence tagging.
#'
#' @export
flair_models.Sequencetagger <- function() {
  SequenceTagger <- import("flair.models")$SequenceTagger
  return(SequenceTagger)
}
