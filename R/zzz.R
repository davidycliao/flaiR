#' @title .onAttach Function for the flaiR Package
#'
#' @description This function is called when the flaiR package is loaded. \
#' It provides messages detailing the versions of Python and Flair being used, a
#' s well as other package details.
#'
#' @keywords internal
#' @importFrom reticulate py_config
#' @export
# .onAttach <- function(...) {
#   packageStartupMessage(sprintf(" flai\033[34mR\033[39m: An R Wrapper for Accessing Flair NLP Tagging Features %-5s", ""))
#
#   # Check and report Python is installed
#   if (check_python_installed()) {
#     packageStartupMessage(sprintf(" Python: %-47s", reticulate::py_config()$version))
#   } else {
#     packageStartupMessage(sprintf(" Python: %-50s", paste0("\033[31m", "\u2717", "\033[39m")))
#   }
#
#   # Check and report  flair is installed
#   if (reticulate::py_module_available("flair")) {
#     packageStartupMessage(sprintf(" Flair: %-47s",  get_flair_version()))
#   } else {
#     packageStartupMessage(sprintf(" Flair: %-50s", paste0("\033[31m", "\u2717", "\033[39m")))
#     packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
#     system(paste(reticulate::py_config()$python, "-m pip install flair"))
#   }
# }
#
.onAttach <- function(...) {
  packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", ""))
  if (check_python_installed()) {
    packageStartupMessage(sprintf("Python: %-47s", reticulate::py_config()$version))
  } else {
    stop("Python is not installed. This package requires Python to run Flair.")
  }
  if (!reticulate::py_module_available("flair")) {
    packageStartupMessage("Attempting to install Flair in Python...")
    reticulate::py_install("flair==0.12")
    if (!reticulate::py_module_available("flair")) {
      packageStartupMessage("Failed to install Flair. This package requires Flair. Please ensure Flair is installed in Python manually.")
    } else {
      packageStartupMessage(sprintf("Flair: %-47s", get_flair_version()))
    }
  } else {
    packageStartupMessage(sprintf("Flair: %-47s", get_flair_version()))
    packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
  }
}
#
# .onAttach <- function(...) {
#   # Specify Python path explicitly
#   python_path <- Sys.which("python3")
#   if (python_path == "") {
#     stop("Cannot locate the Python 3 path. Ensure Python 3 is installed and in your system's path.")
#   }
#
#   # Check Python version
#   python_version <- system(paste(python_path, "--version"), intern = TRUE)
#   packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", ""))
#
#   if (!grepl("Python 3", python_version)) {
#     warning("You seem to be using Python 2. This package may require Python 3. Consider installing or using Python 3.")
#   }
#   packageStartupMessage(python_version)
#
#   # Check if flair is genuinely installed and its version
#   check_flair_version <- function() {
#     flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
#     result <- system(flair_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR") {
#       return(FALSE)
#     }
#     # Return flair version
#     return(result[1])
#   }
#
#   flair_version <- check_flair_version()
#   if (is.logical(flair_version) && !flair_version) {
#     warning("flaiR is installed in R.\n  Flair NLP is not installed in Python and cannot be imported in R. Consider installing it manually.")
#   } else {
#     packageStartupMessage("Flair ", flair_version)
#     packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
#   }
#
#   # 3. Test the command manually
#   # test_flair_command <- paste(python_path, "-c 'import flair'")
#   # test_result <- try(system(test_flair_command, intern = TRUE, ignore.stderr = TRUE), silent = TRUE)
#
#   # if (inherits(test_result, "try-error")) {
#   #   warning("There was an issue while manually testing the flair import. This might mean flair isn't installed in Python.")
#   # } else {
#   #   packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
#   # }
# }
#
#
#
