#' @title Full Flair Module
#'
#' @description This function is a wrapper for the Flair Python library.
#'
#' @return Flair Python module
#'
#' @references Python equivalent: \preformatted{
#' import flair
#' }
#'
#' @importFrom reticulate import
#'
#' @examples
#' \dontrun{
#' flair <- flair()
#'}
#' @export
flair <- function() {
  flair_module <- import("flair")
  return(flair_module)
}
