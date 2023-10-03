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
#' @references
#'
#' Python equivalent:
#' \preformatted{
#' from flair.datasets import UD_ENGLISH
#' corpus = UD_ENGLISH().downsample(0.1)
#' }
#'
#' @seealso
#' \url{https://github.com/flairNLP/flair} for additional information on Flair's capabilities and datasets in NLP.
#'
#' @export
flair_datasets <- function() {
  flair.datasets <- reticulate::import("flair.datasets")
  return(flair.datasets)
}


#' Create a Flair Sentence Object
#'
#' @description  This function uses the {reticulate} package to interface with Python and
#' create a Flair Sentence object.
#'
#' @param sentence_text A character string to be converted into a Flair Sentence object.
#' @return A Flair Sentence object.
#' @examples
#' \dontrun{
#' flair_data_sentence("The quick brown fox jumps over the lazy dog.")
#' }
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.data import Sentence
#' sentence = Sentence("The quick brown fox jumps over the lazy dog.")
#' }
#' @export
flair_data.sentence <- function(sentence_text) {
  flair_data <- reticulate::import('flair.data')
  sentence <- flair_data$Sentence(sentence_text)
  return(sentence)
}


#' Create a Flair Classifier.load Object
#'
#' This function utilizes the {reticulate} package to interface with Python
#' and create a Classifier object from the Flair library.
#'
#' @param pre_trained_model A character string specifying the pre-trained model to use.
#' This parameter is defined but not used in the current function context.
#' @return A Flair Classifier object.
#' @examples
#' \dontrun{
#' classifier <- flair_nn_classifier_load("ner")
#' }
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.nn import Classifier
#' }
#' @export
flair_nn.classifier_load <- function(pre_trained_model = 'ner') {
  flair_nn <- reticulate::import('flair.nn')
  classifier <- flair_nn$Classifier$load(pre_trained_model)
  return(classifier)
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
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.embeddings import TransformerWordEmbeddings
#' embedding = TransformerWordEmbeddings('bert-base-uncased')
#' }
#' @export
flair_embeddings.TransformerWordEmbeddings <- function(pre_trained_model = 'bert-base-uncased') {
  flair_embeddings <- reticulate::import('flair.embeddings')
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
#' embedding <- word_embeddings("glove")
#' }
#'
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.embeddings import WordEmbeddings
#' glove_embedding = WordEmbeddings('glove')
#' }
#' @export
flair_embeddings.WordEmbeddings <- function(pre_trained = "glove") {
  flair_embeddings <- reticulate::import("flair.embeddings")
  WordEmbeddings <- flair_embeddings$WordEmbeddings
  embedding <- WordEmbeddings(pre_trained)
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
#' splitter <- segtok_sentence_splitter()
#' }
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
  SequenceTagger <- reticulate::import("flair.models")$SequenceTagger
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
#' @examples
#' \dontrun{
#' trainers <- flair_trainers()
#' model_trainer <- trainers$ModelTrainer
#' }
#' @export
flair_trainers <- function() {
  trainers <- reticulate::import('flair.trainers')
  return(trainers)
}
