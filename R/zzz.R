.onLoad <- function(libname, pkgname) {
  python_version <- reticulate::py_config()$version
  if (python_version < "3.8") {
    stop("flaiR requires Python 3.7 or higher.")
  }
}

.onAttach <- function(libname, pkgname) {
  message("flaiR: An R Wrapper for Accessing Flair NLP Tagging Features")
  # Report Python version
  python_version <- reticulate::py_config()$version
  message("Using Python version: ", python_version)
}

