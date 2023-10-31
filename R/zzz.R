#' @title .onAttach Function for the flaiR Package
#'
#' @description The provided R code describes the \code{.onAttach} function for the \code{flaiR} package.
#' This function is automatically invoked when the \code{flaiR} package is loaded. Its primary purpose
#' is to set up and check the environment for the package and to display startup messages.
#' .onAttach is triggered when the flaiR package gets loaded. It produces
#' messages indicating the versions of Python and Flair in use and provides o
#' ther details related to the package.
#' @details
#' \itemize{
#'   \item \strong{Specifying Python Path:} The function starts by looking for the path of Python 3.
#'   If it doesn't find it, it stops the package load with an error message.
#'   \item \strong{Checking Python Version:} Next, the function checks whether the identified version
#'   of Python is Python 3. If it's not, it emits a warning.
#'   \item \strong{Checking PyTorch Version:} The function then checks if PyTorch is correctly installed
#'   and fetches its version information.
#'   \item \strong{Checking Flair Version:} It also checks if Flair is correctly installed and fetches
#'   its version.
#'   \item \strong{Installation Status of Flair:} If Flair isn't installed, the function attempts to install
#'   PyTorch and Flair automatically using pip commands. If the installation fails, it produces an error message.
#'   \item \strong{Success Message:} If all the checks pass, a message is displayed indicating that Flair can
#'   be successfully imported in R via \code{flaiR}.
#'   \item \strong{Specifying Python Version for Use:} Lastly, the function specifies which version of Python
#'   to use within R using the \code{reticulate} package.
#' }
#' @keywords internal
#' @importFrom reticulate py_config
#' @importFrom reticulate use_python
#' @export
.onAttach <- function(...) {
  # Check operating system
  os_name <- Sys.info()["sysname"]

  # Depending on OS, determine Python command
  if (os_name == "Windows") {
    python_cmd <- "python"
  } else {
    # For Linux and macOS
    python_cmd <- "python3"
  }

  # Specify Python path explicitly
  python_path <- Sys.which(python_cmd)

  # Specify Python path explicitly
  python_path <- Sys.which("python3")
  if (python_path == "") {
    stop("Cannot locate the Python 3 path. Ensure Python 3 is installed and in your system's path.")
  }

  # Check Python version
  python_version <- system(paste(python_path, "--version"), intern = TRUE)
  if (!grepl("Python 3", python_version)) {
    warning("You seem to be using Python 2. This package may require Python 3. Consider installing or using Python 3.")
  }

  # Check if PyTorch is genuinely installed and its version
  check_torch_version <- function() {
    torch_version_command <- paste(python_path, "-c 'import torch; print(torch.__version__)'")
    result <- system(torch_version_command, intern = TRUE)
    if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
      return(list(paste("PyTorch", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
    }
    # Return flair version
    return(list(paste("PyTorch", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
  }

  # Check if flair is genuinely installed and its version
  check_flair_version <- function() {
    flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
    result <- system(flair_version_command, intern = TRUE)
    if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
      return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
    }
    # Return flair version
    return(list(paste("flair", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
  }

  flair_version <- suppressWarnings(check_flair_version())
  torch_version <- suppressWarnings(check_torch_version())

  if (isFALSE(flair_version[[2]])) {
    packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
    commands <- c(
      paste(python_path, "-m pip install --upgrade pip"),
      paste(python_path, "-m pip install torch"),
      paste(python_path, "-m pip install flair")
    )

    vapply(commands, system, FUN.VALUE = integer(1))

    re_installation <- suppressWarnings(check_flair_version())
    if (isFALSE(re_installation[[2]])) {
      packageStartupMessage("Failed to install Flair. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
    }
  } else {
    packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", ""))
    packageStartupMessage(paste(flair_version[[1]], torch_version[[1]], sep = " | "))
    packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
    reticulate::use_python(Sys.which("python3"))
    }
}

# .onAttach <- function(...) {
#   # Specify Python path explicitly
#   python_path <- Sys.which("python3")
#   if (python_path == "") {
#     stop("Cannot locate the Python 3 path. Ensure Python 3 is installed and in your system's path.")
#   }
#
#   # Check Python version
#   python_version <- system(paste(python_path, "--version"), intern = TRUE)
#   if (!grepl("Python 3", python_version)) {
#     warning("You seem to be using Python 2. This package may require Python 3. Consider installing or using Python 3.")
#   }
#
#   # Check if PyTorch is genuinely installed and its version
#   check_torch_version <- function() {
#     torch_version_command <- paste(python_path, "-c 'import torch; print(torch.__version__)'")
#     result <- system(torch_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("PyTorch", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     return(list(paste("PyTorch", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
#   }
#
#   # Check if flair is genuinely installed and its version
#   check_flair_version <- function() {
#     flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
#     result <- system(flair_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     return(list(paste("flair", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
#   }
#
#   flair_version <- suppressWarnings(check_flair_version())
#   torch_version <- suppressWarnings(check_torch_version())
#
#   if (isFALSE(flair_version[[2]])) {
#     packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
#     commands <- c(
#       paste(python_path, "-m pip install --upgrade pip"),
#       paste(python_path, "-m pip install torch"),
#       paste(python_path, "-m pip install flair")
#     )
#
#     vapply(commands, system, FUN.VALUE = integer(1))
#
#     re_installation <- suppressWarnings(check_flair_version())
#     if (isFALSE(re_installation[[2]])) {
#       packageStartupMessage("Failed to install Flair. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", ""))
#     packageStartupMessage(paste(flair_version[[1]], torch_version[[1]], sep = " | "))
#     packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
#     reticulate::use_python(Sys.which("python3"))
#   }
# }

#  V1
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
#     # system(paste(reticulate::py_config()$python, "-m pip install flair"))
#   }
# }

# Current
# .onAttach <- function(...) {
#   packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", ""))
#   if (check_python_installed()) {
#     packageStartupMessage(sprintf("Python: %-47s", reticulate::py_config()$version))
#   } else {
#     stop("Python is not installed. This package requires Python to run Flair.")
#   }
#   if (!reticulate::py_module_available("flair")) {
#     packageStartupMessage("Attempting to install Flair in Python...")
#     system(paste(reticulate::py_config()$python, "-m pip3 install torch torchvision torchaudio"))
#     if (!reticulate::py_module_available("flair")) {
#       packageStartupMessage("Failed to install Flair. This package requires Flair. Please ensure Flair is installed in Python manually.")
#     } else {
#       packageStartupMessage(sprintf("Flair: %-47s", get_flair_version()))
#     }
#   } else {
#     packageStartupMessage(sprintf("Flair: %-47s", get_flair_version()))
#     packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
#   }
# }
