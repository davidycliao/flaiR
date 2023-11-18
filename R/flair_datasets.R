#' @title Access the flair_datasets Module from Flair
#'
#' @description Utilizes the {reticulate} package to import the `flair.datasets`
#' dataset from Flair's datasets in Python, enabling the use of this dataset in
#' an R environment.
#'
#' @return
#' A Python Module(flair.datasets) from Flair, which can be utilized for NLP tasks.
#'
#' @examples \dontrun{
#' UD_ENGLISH <- flair_datasets()$UD_ENGLISH
#' corpus <- UD_ENGLISH()$downsample(0.1)}
#'
#' @importFrom reticulate import
#'
#' @references Python equivalent: \preformatted{
#' from flair.datasets import UD_ENGLISH
#' corpus = UD_ENGLISH().downsample(0.1)
#' }
#'
#' @seealso
#' <https://github.com/flairNLP/flair> for additional information on Flair's
#'  capabilities and datasets in NLP.
#'
#' @importFrom reticulate import
#' @examples
#' # print all the datasets from flair
#' names(flair_datasets())
#'
#' @export
flair_datasets <- function() {
  flair.datasets <- import("flair.datasets")
  return(flair.datasets)
}
