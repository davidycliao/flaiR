.onLoad <- function(libname, pkgname) {
  python_version <- reticulate::py_config()$version
  if (python_version < "3.8") {
    stop("flaiR requires Python 3.7 or higher.")
  }
}

.onAttach <- function(libname, pkgname) {
  message("## flaiR: An R Wrapper for Accessing Flair NLP Tagging Features ##")
  # Report Python version
  python_version <- reticulate::py_config()$version
  message("## Using Python:    ", python_version, "                                         ##")

  # Check if flair is installed
  if (check_flair_installed()) {
    flair_version <- get_flair_version()
    message("## Using Flair : ", flair_version, "                                         ##")
  } else {
    message("Flair is not installed in the current Python environment.")
  }
}

check_flair_installed <- function() {
  return(reticulate::py_module_available("flair"))
}

get_flair_version <- function() {
  flair <- reticulate::import("flair")
  # Assuming flair has an attribute `__version__` (this might not be true)
  return(flair$`__version__`)
}
