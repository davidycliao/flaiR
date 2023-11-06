#' @title Install Python Dependencies and Load the flaiR

#' @description .onAttach sets up a virtual environment, checks for Python availability,
#' and ensures the 'flair' module is installed in flair_env in Python.
#'
#' @param ... A character string specifying the name of the virtual environment.
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Checks if the virtual environment specified by \code{venv} exists.
#'         If not, it creates the environment.
#'   \item Activates the virtual environment.
#'   \item Checks for the availability of Python. If Python is not available,
#'         it displays an error message.
#'   \item Checks if the 'flair' Python module is available in the virtual
#'         environment. If not, it attempts to install 'flair'. If the
#'         installation fails, it prompts the user to install 'flair' manually.
#' }
#' @importFrom reticulate py_module_available
#' @importFrom reticulate py_install
.onAttach <- function(...) {

  # Check operating system, mac by default
  os_name <- Sys.info()["sysname"]

  # Depending on OS, determine Python command
  if (os_name == "Windows") {
    python_cmd <- "python"
    python_path <- normalizePath(Sys.which(python_cmd), winslash = "/", mustWork = TRUE)
    return(python_path)
  } else {
    # For Linux and macOS
    python_cmd <- "python3"
    python_path <- Sys.which(python_cmd)
  }

  # If Python path is empty, raise an error
  if (python_path == "") {
    stop(paste("Cannot locate the", python_cmd, "path. Ensure it's installed and in your system's path."))
  }

  # Try to get Python version and handle any errors
  tryCatch({
    python_version <- system(paste(python_path, "--version"), intern = TRUE)
  }, error = function(e) {
    stop(paste("Failed to get Python version with path:", python_path, "Error:", e$message))
  })

  # Check if Python version is 2 or 3
  if (!grepl("Python 3", python_version)) {
    warning("You seem to be using Python 2. This package may require Python 3. Consider installing or using Python 3.")
  }

  # # Check Python installation
  # if (reticulate::py_available()) {
  #   packageStartupMessage(sprintf(" Python: %-47s", reticulate::py_config()$version))
  # } else {
  #   packageStartupMessage(" Python is not installed. Please install Python 3.8.0 or higher.")
  # }

  venv <- "flair_env"
  # Create a new virtual environment if it doesn't exist
  if (!reticulate::virtualenv_exists(venv)) {
    reticulate::virtualenv_create(venv)
  }

  # Use the virtual environment
  reticulate::use_virtualenv(venv, required = TRUE)

  # Check and install flair if not available
  if (!reticulate::py_module_available("flair")) {
    packageStartupMessage("flair NLP is not installed.")
    packageStartupMessage("flair NLP is installing in virtual environment: ", venv)
    reticulate::py_install("flair", envname = venv)
    if (!reticulate::py_module_available("flair")) {
      packageStartupMessage("Failed to install flair NLP. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
    }
  } else {
    packageStartupMessage(sprintf(" \033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m",  get_flair_version(),"\033[39m\033[22m", sep = "")))
  }
}


