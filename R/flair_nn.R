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
#'   flair_nn <- flair_nn(load = TRUE)
#'   Classifier <- flair_nn$Classifier
#' }
flair_nn <- function() {
  flair_nn <- import('flair.nn')
  return(flair_nn)
}


#' @title Initializing a Class for Flair Classifier
#'
#' @description This function interfaces with Python via the {reticulate} package
#' to create a Classifier object from the Flair library.
#'
#' @param load Logical. Indicates if the classifier should be loaded. Default is TRUE.
#' This parameter is currently defined but not actively used in the function context.
#'
#' @return A Flair Classifier class instance.
#'
#' @examples
#' \dontrun{
#' classifier <- flair_nn.Classifier()
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
flair_nn.Classifier <- function(load = TRUE) {
  flair_nn <- import('flair.nn')
  classifier <- flair_nn$Classifier
  return(classifier)
}

