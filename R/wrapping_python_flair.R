#' Flair Data Import Function
#'
#' This function imports and returns the `data` module from the Flair package in Python.
#'
#' @return A reference to the `data` module of the Flair Python package.
#' @export
#' @references
#' From Flair's Python library: \code{from flair.data import *}
#'
flair_data <- function() {
  flair.data <- reticulate::import("flair.data")
  return(flair.data)
}


#' Import the flair.models Python module
#'
#' @description This function utilizes the reticulate package to import flair.models from the Flair NLP Python library.
#' Ensure that the Python environment is properly set up and the Flair package is installed.
#'
#' @return A Python module object representing flair.models.
#' @references
#' Python equivalent: \preformatted{
#' from flair.models import *
#' }
#' @export
flair_models <- function() {
  flair.models <- reticulate::import("flair.models")
  return(flair.models)
}


#' Retrieve TextClassifier from flair.models
#'
#' @description This function utilizes the reticulate package to directly import TextClassifier from flair.models in the Flair NLP Python library.
#' Ensure that the Python environment is properly set up and the Flair package is installed.
#'
#' @return A Python object representing flair.models.TextClassifier.
#' @export
#' @references
#' Python equivalent: \preformatted{
#' from flair.models import TextClassifier
#' }
#' @examples
#' \dontrun{
#' # Ensure reticulate is using the correct Python environment
#' # reticulate::use_python("path_to_your_python", required = TRUE)
#
#' # Load the TextClassifier
#' TextClassifier <- flair_models.TextClassifier()
#
#' # Load a pre-trained sentiment model
#' classifier <- TextClassifier$load('sentiment')
#'
#' # Create a sentence object
#' sentence <- flair_data.sentence("Flair is pretty neat!")
#'
#' # Predict the sentiment
#' classifier$predict(sentence)
#
#' # Display the sentiment
#' print(sentence$get_labels())
#' }
flair_models.TextClassifier <- function() {
  flair.models <- reticulate::import("flair.models")
  TextClassifier <- flair.models$TextClassifier
  return(TextClassifier)
}


#' Access the flair_datasets Module from Flair
#'
#' @description Utilizes the {reticulate} package to import the `flair.datasets`
#' dataset from Flair's datasets in Python, enabling the use of this dataset in
#' an R environment.
#'
#' @return
#' A Python Module(flair.datasets) from Flair, which can be utilized for NLP tasks.
#'
#' @examples
#' \dontrun{
#' UD_ENGLISH <- flair_datasets()$UD_ENGLISH
#' corpus <- UD_ENGLISH()$downsample(0.1)
#' }
#'
#' @importFrom reticulate import
#'
#' @references
#' Python equivalent: \preformatted{
#' from flair.datasets import UD_ENGLISH
#' corpus = UD_ENGLISH().downsample(0.1)
#' }
#'
#' @seealso
#' \url{https://github.com/flairNLP/flair} for additional information on Flair's
#'  capabilities and datasets in NLP.
#'
#' @importFrom reticulate import
#'
#' @export
flair_datasets <- function() {
  flair.datasets <- import("flair.datasets")
  return(flair.datasets)
}


#' Create a Flair Sentence Object
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
flair_data.sentence <- function(sentence_text) {
  flair_data <- import('flair.data')
  sentence <- flair_data$Sentence(sentence_text)
  return(sentence)
}


#' Create a Flair Classifier.load Object
#'
#' This function utilizes the {reticulate} package to interface with Python
#' and create a Classifier object from the Flair library.
#'
#' @param pre_trained A character string specifying the pre-trained model to use.
#' This parameter is defined but not used in the current function context.
#'
#' @return A Flair Classifier object.
#'
#' @examples
#' \dontrun{
#' classifier <- flair_nn.classifier_load("ner")
#' }
#'
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.nn import Classifier
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_nn.classifier_load <- function(pre_trained) {
  flair_nn <- import('flair.nn')
  classifier <- flair_nn$Classifier$load(pre_trained)
  return(classifier)
}


#' Flair Embeddings Importer
#'
#' @description This function imports and returns the \code{flair.embeddings} module from Flair.
#' It provides a convenient R interface to the Flair library's embedding functionalities.
#'
#' @return The \code{flair.embeddings} module from Flair.
#'
#' @examples
#' \dontrun{
#' flair_embeddings <- flair_embeddings()$FlairEmbeddings
#' }
#'
#' @references
#' In Python's Flair library:
#' \code{
#' from flair.embeddings import FlairEmbeddings
#' }
#'
#' @importFrom reticulate import
#' @export
flair_embeddings <- function() {
  flair_embeddings <- import('flair.embeddings')
  return(flair_embeddings)
}



#' Flair Embedding Initialization
#'
#' @description This function initializes Flair embeddings using Python's Flair
#' library.
#'
#' @references
#' FlairEmbeddings from Flair library in Python. Example usage in Python:
#' \preformatted{
#' flair_embedding_forward = FlairEmbeddings('news-forward')
#' flair_embedding_backward = FlairEmbeddings('news-backward')
#' }
#' @param embeddings_type Character, type of embeddings to initialize.
#' Options: "news-forward", "news-backward".
#' @return A Flair embeddings object from Python's Flair library.
#' @export
#' @examples
#' \dontrun{
#' flair_embedding_forward <- flair_embeddings.FlairEmbeddings("news-forward")
#' flair_embedding_backward <- flair_embeddings.FlairEmbeddings("news-backward")
#' }
#'
flair_embeddings.FlairEmbeddings <- function(embeddings_type = "news-forward") {
  flair_embeddings <- import('flair.embeddings')
  embeddings  <- flair_embeddings$FlairEmbeddings(embeddings_type)

  if (embeddings_type == "news-backward") {
    message("Initialized Flair backward embeddings")
  } else if (embeddings_type == "news-forward") {
    message("Initialized Flair forward embeddings")
  } else {
    stop("Invalid embeddings type. Choose `news-forward` or `news-backward`")
  }

  return(embeddings)
}


#' Create a Flair TransformerWordEmbeddings Object
#'
#' @description This function interfaces with Python via {reticulate} to create
#' a `TransformerWordEmbeddings` object using the Flair library.
#'
#' @param pre_trained_model A character string specifying the pre-trained model to use.
#' Defaults to 'bert-base-uncased'.
#' @return A Flair TransformerWordEmbeddings object.
#' @examples
#' \dontrun{
#' embedding <- flair_embeddings.TransformerWordEmbeddings("bert-base-uncased")
#' }
#'
#' @references
#' Python equivalent: \preformatted{
#' from flair.embeddings import TransformerWordEmbeddings
#' embedding = TransformerWordEmbeddings('bert-base-uncased')
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_embeddings.TransformerWordEmbeddings <- function(pre_trained_model = 'bert-base-uncased') {
  flair_embeddings <- import('flair.embeddings')
  TransformerWordEmbeddings <- flair_embeddings$TransformerWordEmbeddings
  embedding <- TransformerWordEmbeddings(pre_trained_model)
  return(embedding)
}


#' Create a Flair WordEmbeddings Object
#'
#' @description This function interfaces with Python via {reticulate} to create
#' a `WordEmbeddings` object using the Flair library.
#'
#' @param pre_trained A character string specifying the pre-trained model to use.
#' Defaults to "`glove`".
#' @return A Flair WordEmbeddings object.
#'
#' @examples
#' \dontrun{
#' embedding <- flair_embeddings.WordEmbeddings("glove")
#' }
#'
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.embeddings import WordEmbeddings
#' embedding = WordEmbeddings('glove')
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_embeddings.WordEmbeddings <- function(pre_trained = "glove") {
  flair_embeddings <- import("flair.embeddings")
  WordEmbeddings <- flair_embeddings$WordEmbeddings
  embedding <- WordEmbeddings(pre_trained)
  return(embedding)
}

#' TransformerDocumentEmbeddings Function
#'
#' This function initializes and returns a Transformer Document Embedding model from the Flair library.
#' It takes a pre-trained model name as an argument and returns the respective embedding model.
#'
#' @param pre_trained A string specifying the name of a pre-trained transformer model.
#' @return An instance of the TransformerDocumentEmbeddings model from the Flair library.
#'
#' @examples
#' \dontrun{
#' embedding <- flair_embeddings.TransformerDocumentEmbeddings(pre_trained = "bert-base-uncased")
#' }
#'
#' @references
#' In Python's Flair library:
#' \code{
#' from flair.embeddings import TransformerDocumentEmbeddings
#' embedding = TransformerDocumentEmbeddings('bert-base-uncased')
#' }
#'
#' @importFrom reticulate import
#' @export
flair_embeddings.TransformerDocumentEmbeddings <- function(pre_trained = "bert-base-uncased") {
  flair_embeddings <- import("flair.embeddings")
  TransformerDocumentEmbeddings <- flair_embeddings$TransformerDocumentEmbeddings
  embedding <- TransformerDocumentEmbeddings(pre_trained)
  return(embedding)
}


#' Segtok Sentence Splitter
#'
#' A function to interface with the Python `flair.splitter` module, specifically
#' utilizing the `SegtokSentenceSplitter` class/method.
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


#' Access Flair's SequenceTagger
#'
#' @description
#' This function utilizes the {reticulate} package to import the `SequenceTagger`s from Flair's models in Python,
#' enabling interaction with Flair's sequence tagging models in an R environment.
#'
#' @details
#' The function does not take any parameters and directly returns the `SequenceTagger` when called, which can be used further
#' for sequence tagging tasks using pre-trained models from Flair.
#'
#' @return
#' A Python module (`SequenceTagger`) from Flair, which can be utilized to load and use sequence tagging models.
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
#' \url{https://github.com/flairNLP/flair} for more information on Flair's capabilities in NLP and sequence tagging.
#'
#' @export
flair_models.sequencetagger <- function() {
  SequenceTagger <- import("flair.models")$SequenceTagger
  return(SequenceTagger)
}


#' Import Flair's ModelTrainer in R
#'
#' @description This function provides R access to Flair's ModelTrainer Python class using the {reticulate} package.
#'
#' @return A Python Module(flair.trainers) object allowing access to Flair's trainers in R.
#'
#' @references
#' \href{https://github.com/flairNLP/flair}{Flair GitHub}
#' Python equivalent:
#' \preformatted{
#' from flair.trainers import ModelTrainer
#' }
#'
#' @examples
#' \dontrun{
#' trainers <- flair_trainers()
#' model_trainer <- trainers$ModelTrainer
#' }
#' @importFrom reticulate import
#'
#' @export
flair_trainers <- function() {
  trainers <- reticulate::import('flair.trainers')
  return(trainers)
}
