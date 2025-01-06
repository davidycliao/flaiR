#' @title Initialize Python Environment and Load flaiR NLP
#' @description Sets up Python environment, manages virtual environment, and installs required flair NLP packages.
#'
#' @param ... Additional arguments passed to startup functions
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Clears any existing Python environment variables
#'   \item Detects Python installation based on operating system (Windows/Unix)
#'   \item Manages 'flair_env' virtual environment:
#'     - Uses existing environment if available
#'     - Creates new environment if needed
#'   \item Verifies and installs required packages:
#'     - torch
#'     - flair
#'     - scipy (version 1.12.0)
#'   \item Validates flair installation and displays version information
#' }
#'
#' The function includes comprehensive error handling and provides status messages
#' throughout the initialization process.
#'
#' @note
#' Requires Python 3.x installed on the system. Will create a virtual environment
#' named 'flair_env' if it doesn't exist.
#'
#' @importFrom reticulate virtualenv_exists virtualenv_create use_virtualenv py_install
#' @keywords internal

.onAttach <- function(...) {
  # Check and set Python environment
  Sys.unsetenv("RETICULATE_PYTHON")
  venv <- "flair_env"

  # Get Python path based on OS
  python_path <- tryCatch({
    if (Sys.info()["sysname"] == "Windows") {
      normalizePath(Sys.which("python"), winslash = "/", mustWork = TRUE)
    } else {
      Sys.which("python3")
    }
  }, error = function(e) {
    packageStartupMessage("Cannot locate Python. Please install Python 3.")
    return(invisible(NULL))
  })

  # Define version check function
  check_flair_version <- function() {
    flair_version_command <- paste(python_path, "-c \"import flair; print(flair.__version__)\"")
    result <- system(flair_version_command, intern = TRUE)
    if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
      return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
    }
    return(list(paste("flair", paste0("\033[32m", "\u2713", "\033[39m"), result[1], sep = " "), TRUE, result[1]))
  }

  # Check if flair_env exists
  if (reticulate::virtualenv_exists(venv)) {
    packageStartupMessage("Using existing virtual environment: ", venv)
    reticulate::use_virtualenv(venv, required = TRUE)

    # Check flair in existing environment
    flair_status <- suppressMessages(check_flair_version())
    if (!flair_status[[2]]) {
      packageStartupMessage("Installing missing flair in existing environment...")
      tryCatch({
        reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
      }, error = function(e) {
        packageStartupMessage("Failed to install flair: ", e$message)
        return(invisible(NULL))
      })
      flair_status <- suppressMessages(check_flair_version())
    }
  } else {
    # Create new virtual environment
    packageStartupMessage("Creating new virtual environment: ", venv)
    reticulate::virtualenv_create(venv)
    reticulate::use_virtualenv(venv, required = TRUE)

    # Install in new environment
    packageStartupMessage("Installing flair NLP in new environment...")
    tryCatch({
      reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
    }, error = function(e) {
      packageStartupMessage("Failed to install flair: ", e$message)
      return(invisible(NULL))
    })
    flair_status <- suppressMessages(check_flair_version())
  }

  # Display final status
  if (flair_status[[2]]) {
    packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
                                  paste("\033[1m\033[33m", flair_status[[3]], "\033[39m\033[22m", sep = "")))
  } else {
    packageStartupMessage("Failed to load flair. Please install manually.")
  }
}






#'
# .onAttach <- function(...) {
#   # Determine Python command
#   python_cmd <- if (Sys.info()["sysname"] == "Windows") "python" else "python3"
#   python_path <- Sys.which(python_cmd)
#
#   # Check Python path
#   if (python_path == "") {
#     packageStartupMessage(paste("Cannot locate the", python_cmd, "executable. Ensure it's installed and in your system's PATH. flaiR functionality requiring Python will not be available."))
#     return(invisible(NULL))  # Exit .onAttach without stopping package loading
#   }
#
#   # Check Python versio Try to get Python version
#   tryCatch({
#     python_version <- system(paste(python_path, "--version"), intern = TRUE)
#     if (!grepl("Python 3", python_version)) {
#       packageStartupMessage("Python 3 is required, but a different version was found. Please install Python 3. flaiR functionality requiring Python will not be available.")
#       return(invisible(NULL))  # Exit .onAttach without stopping package loading
#     }
#   }, error = function(e) {
#     packageStartupMessage(paste("Failed to get Python version with path:", python_path, "Error:", e$message, ". flaiR functionality requiring Python will not be available."))
#     return(invisible(NULL))   # Exit .onAttach without stopping package loading
#   })
#
#   # Check if PyTorch is installed
#   check_torch_version <- function() {
#     # torch_version_command <- paste(python_path, "-c 'import torch; print(torch.__version__)'")
#     torch_version_command <- paste(python_path, "-c \"import torch; print(torch.__version__)\"")
#     result <- system(torch_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("PyTorch", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     return(list(paste("PyTorch", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE, result[1]))
#   }
#
#   # Check if flair is installed
  # check_flair_version <- function() {
  #   # flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
  #   flair_version_command <- paste(python_path, "-c \"import flair; print(flair.__version__)\"")
  #   result <- system(flair_version_command, intern = TRUE)
  #   if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
  #     return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
  #   }
  #   # Return flair version
  #   return(list(paste("flair", paste0("\033[32m", "\u2713", "\033[39m"),result[1], sep = " "), TRUE, result[1]))
  # }

#   flair_version <- check_flair_version()
#   torch_version <- check_torch_version()
#
#   if (isFALSE(flair_version[[2]])) {
#     packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
#
#     commands <- c(
#       paste(python_path, "-m pip install --upgrade pip"),
#       paste(python_path, "-m pip install torch"),
#       paste(python_path, "-m pip install flair"),
#       paste(python_path, "-m pip install scipy==1.12.0")
#     )
#     command_statuses <- vapply(commands, system, FUN.VALUE = integer(1))
#
#     flair_check_again <- check_flair_version()
#     if (isFALSE(flair_check_again[[2]])) {
#       packageStartupMessage("Failed to install Flair. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m", flair_version[[3]], "\033[39m\033[22m", sep = "")))
#   }
# }

