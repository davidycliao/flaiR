#' @title Import Flair's ModelTrainer in R
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
