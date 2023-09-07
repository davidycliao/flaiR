#' .onAttach Function for the flaiR Package
#'
#' This function is called when the flaiR package is loaded. It provides messages
#' detailing the versions of Python and Flair being used, as well as other package details.
#'
#' @keywords internal
#' @importFrom reticulate py_config
#' @export
.onAttach <- function(...) {
  # header_footer <- "## ============================================================== ##"
  # message(header_footer)

  packageStartupMessage(sprintf(" flai\033[34mR\033[39m: An R Wrapper for Accessing Flair NLP Tagging Features %-5s", ""))

  # Check and report Python is installed
  if (check_python_installed()) {
    packageStartupMessage(sprintf(" Python : %-47s", reticulate::py_config()$version))
  } else {
    packageStartupMessage(sprintf(" Python : %-50s", paste0("\033[31m", "\u2717", "\033[39m")))
  }

  # Check and report  flair is installed
  if (reticulate::py_module_available("flair")) {
    packageStartupMessage(sprintf(" Flair: %-47s",  get_flair_version()))
  } else {
    packageStartupMessage(sprintf(" Flair: %-50s", paste0("\033[31m", "\u2717", "\033[39m")))
    packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
    system(paste(reticulate::py_config()$python, "-m pip install flair"))

  }

  # # Check for Available Python Environment
  # if (reticulate::py_available(initialize = TRUE)) {
  #   packageStartupMessage(sprintf(" py_config: %-47s", reticulate::py_config()$python))
  # } else {
  #   packageStartupMessage(sprintf(" py_config: %-46s", paste0("\033[31m", "\u2717", "\033[39m")))
  # }
  # message(header_footer)
}


