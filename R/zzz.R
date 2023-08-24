#' .onAttach Function for the flaiR Package
#'
#' This function is called when the flaiR package is loaded. It provides messages
#' detailing the versions of Python and Flair being used, as well as other package details.
#'
#' @keywords internal
#' @export
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


#' Check If Flair is Installed
#'
#' Determines if the Flair Python module is available in the current Python environment.
#'
#' @keywords internal
#' @export check_flair_installed
#' @return Logical. `TRUE` if Flair is installed, otherwise `FALSE`.
check_flair_installed <- function(...) {
  return(reticulate::py_module_available("flair"))
}

#' Retrieve Flair Version
#'
#' Gets the version of the installed Flair module in the current Python environment.
#'
#' @keywords internal
#' @export get_flair_version
#' @return Character string representing the version of Flair.
#' If Flair is not installed, this may return `NULL` or cause an error (based on `reticulate` behavior).
get_flair_version <- function(...) {
  flair <- reticulate::import("flair")
  # Assuming flair has an attribute `__version__` (this might not be true)
  return(flair$`__version__`)
}

