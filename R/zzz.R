#' #' @export .onAttach
#' .onAttach <- function(...) {
#'   message("## flaiR: An R Wrapper for Accessing Flair NLP Tagging Features   ##")
#'   # Report Python version
#'   python_version <- reticulate::py_config()$version
#'   message("## Using Python:    ", python_version, "                                           ##")
#'
#'   # Check if flair is installed
#'   if (check_flair_installed()) {
#'     flair_version <- get_flair_version()
#'     message("## Using Flair : ", flair_version, "                                           ##")
#'   } else {
#'     message("## Using Flair : ", "not installed in the current Python environment.    ##")
#'   }
#' }

#' @export .onAttach
.onAttach <- function(...) {
  header_footer <- "## ============================================================== ##"
  message(header_footer)

  message(sprintf("## flaiR: An R Wrapper for Accessing Flair NLP Tagging Features   ##"))

  # Report Python version
  python_version <- reticulate::py_config()$version
  message(sprintf("## Using Python: %-48s ##", python_version))

  # Check if flair is installed
  if (check_flair_installed()) {
    flair_version <- get_flair_version()
    message(sprintf("## Using Flair:  %-48s ##", flair_version))

  } else {
    message(sprintf("## Using Flair:  %-47s ##", "not installed in the current Python environment."))
  }

  message(header_footer)
}


#' @export check_flair_installed
check_flair_installed <- function(...) {
  return(reticulate::py_module_available("flair"))
}

#' @export get_flair_version
get_flair_version <- function(...) {
  flair <- reticulate::import("flair")
  # Assuming flair has an attribute `__version__` (this might not be true)
  return(flair$`__version__`)
}
