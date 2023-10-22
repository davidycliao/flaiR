#' @title Import Flair's Neural Network Module
#'
#' @description
#' This function provides an interface to the `flair.nn` module of the Flair library. The module
#' contains neural network components, including models, classifiers, decoders, dropout techniques,
#' and more.
#'
#' The `flair.nn` module encompasses various sub-modules such as:
#' \itemize{
#'   \item decoder
#'   \item distance
#'   \item dropout
#'   \item loss
#'   \item model
#'   \item multitask
#'   \item recurrent
#' }
#' Furthermore, it provides access to classes like `Model`, `Classifier`, `PrototypicalDecoder`,
#' `LockedDropout`, and `WordDropout`, among others.
#'
#' @return A reference to Flair's neural network module (`flair.nn`).
#'
#' @export
#'
#' @importFrom reticulate import
#'
#' @examples
#' \dontrun{
#'   flair_nn_module <- flair_nn()
#'   Classifier <- flair_nn_module$Classifier
#' }
flair_nn <- function() {
  flair_nn_module <- import('flair.nn')
  return(flair_nn_module)
}


#' @title Initializing a Class for Flair Classifier
#'
#' @description This function interfaces with Python via the {reticulate} package
#' to create a Classifier object from the Flair library.
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
flair_nn.Classifier <- function() {
  flair_nn <- import('flair.nn')
  classifier <- flair_nn$Classifier
  return(classifier)
}

