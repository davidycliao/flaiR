#' @title Import Flair's Neural Network Module
#'
#' @description This function imports the neural network module from the
#' Flair library.
#'
#' @param pre_trained A parameter (currently not being used in the function body).
#'
#' @return A reference to Flair's neural network module.
#'
#' @export
#'
#' @importFrom reticulate import
#'
#' @examples
#' \dontrun{
#'   flair_nn <- flair_nn(pre_trained = TRUE)
#'   Classifier <- flair_nn$Classifier
#' }
flair_nn <- function(pre_trained) {
  flair_nn <- import('flair.nn')
  return(flair_nn)
}


#' @title Create a Flair `Classifier.load` Object.
#'
#' @description This function utilizes the {reticulate} package to interface
#' with Python and create a Classifier object from the Flair library.
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
