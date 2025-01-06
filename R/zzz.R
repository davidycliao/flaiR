#' @title Install Python Dependencies and Load the flaiRnlp
#' @description .onAttach sets up a virtual environment, checks for Python availability,
#' and ensures the 'flair' module is installed in flair_env in Python.
#'
#' @param ... A character string specifying the name of the virtual environment.
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Checks if the virtual environment specified by `venv` exists.
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
#' @keywords internal
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

  # Create/use virtual environment
  if (!reticulate::virtualenv_exists(venv)) {
    reticulate::virtualenv_create(venv)
  }
  reticulate::use_virtualenv(venv, required = TRUE)

  # Check flair and install if needed
  if (!reticulate::py_module_available("flair")) {
    packageStartupMessage("Installing flair NLP in virtual environment: ", venv)
    tryCatch({
      reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
    }, error = function(e) {
      packageStartupMessage("Failed to install flair: ", e$message)
      return(invisible(NULL))
    })
  }

  # Get flair version
  version <- tryCatch({
    reticulate::py_eval("import flair; flair.__version__")
  }, error = function(e) {
    return(NULL)
  })

  if (!is.null(version)) {
    packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
                                  paste("\033[1m\033[33m", version, "\033[39m\033[22m", sep = "")))
  } else {
    packageStartupMessage("Failed to load flair. Please install manually.")
  }
}
