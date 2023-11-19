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
#
#   # Check operating system, mac by default
#   os_name <- Sys.info()["sysname"]
#
#   # Depending on OS, determine Python command
#   if (os_name == "Windows") {
#     python_cmd <- "python"
#     python_path <- normalizePath(Sys.which(python_cmd), winslash = "/", mustWork = TRUE)
#     return(python_path)
#   } else {
#     # For Linux and macOS
#     python_cmd <- "python3"
#     python_path <- Sys.which(python_cmd)
#   }
#
#   # If Python path is empty, raise an error
#   if (python_path == "") {
#     stop(paste("Cannot locate the", python_cmd, "path. Ensure it's installed and in your system's path."))
#   }
#
#   # Try to get Python version and handle any errors
#   tryCatch({
#     python_version <- system(paste(python_path, "--version"), intern = TRUE)
#   }, error = function(e) {
#     stop(paste("Failed to get Python version with path:", python_path, "Error:", e$message))
#   })
#
#   # Check if Python version is 2 or 3
#   if (!grepl("Python 3", python_version)) {
#     warning("You seem to be using Python 2. This package may require Python 3. Consider installing or using Python 3.")
#   }
#
#   # # Check Python installation
#   # if (reticulate::py_available()) {
#   #   packageStartupMessage(sprintf(" Python: %-47s", reticulate::py_config()$version))
#   # } else {
#   #   packageStartupMessage(" Python is not installed. Please install Python 3.8.0 or higher.")
#   # }
#
#   venv <- "flair_env"
#   # Create a new virtual environment if it doesn't exist
#   if (!reticulate::virtualenv_exists(venv)) {
#     reticulate::virtualenv_create(venv)
#   }
#
#   # Use the virtual environment
#   reticulate::use_virtualenv(venv, required = TRUE)
#
#   # Print Python configuration information
#   # packageStartupMessage("Current Python Configuration:")
#   # print(reticulate::py_config())
#
#   # Check and install flair if not available
#   if (!reticulate::py_module_available("flair")) {
#     packageStartupMessage("flair NLP is not installed.")
#     packageStartupMessage("flair NLP is installing in virtual environment: ", venv)
#     reticulate::py_install("flair", envname = venv)
#     if (!reticulate::py_module_available("flair")) {
#       packageStartupMessage("Failed to install flair NLP. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m",  get_flair_version(),"\033[39m\033[22m", sep = "")))
#   }
# }
#
# .onAttach <- function(...) {
#
#   # Determine Python command
#   python_cmd <- if (Sys.info()["sysname"] == "Windows") "python" else "python3"
#   python_path <- Sys.which(python_cmd)
#
#   # Check Python path
#   if (python_path == "") {
#     stop(paste("Cannot locate the", python_cmd, "executable. Ensure it's installed and in your system's PATH."))
#   }
#
#   # Try to get Python version
#   tryCatch({
#     python_version <- system(paste(python_path, "--version"), intern = TRUE)
#     if (!grepl("Python 3", python_version)) {
#       stop("Python 3 is required, but a different version was found. Please install Python 3.")
#     }
#   }, error = function(e) {
#     stop(paste("Failed to get Python version with path:", python_path, "Error:", e$message))
#   })
#
#   # Create and use virtual environment
#   venv <- "flair_env"
#   if (!reticulate::virtualenv_exists(venv)) {
#     reticulate::virtualenv_create(venv)
#   }
#   reticulate::use_virtualenv(venv, required = TRUE)
#
#   # Print Python configuration information
#   packageStartupMessage("Current Python Configuration:")
#   print(reticulate::py_config())
#
#   # Check and install 'flair' module
#   if (!reticulate::py_module_available("flair")) {
#     packageStartupMessage("Attempting to install the 'flair' Python module...")
#     tryCatch({
#       reticulate::py_install("flair", envname = venv)
#     }, error = function(e) {
#       stop("Failed to install 'flair'. Error: ", e$message)
#     })
#     if (!reticulate::py_module_available("flair")) {
#       stop("Installation of 'flair' failed. Please install it manually in the Python environment.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m",  get_flair_version(),"\033[39m\033[22m", sep = "")))
#   }
# }

# .onAttach <- function(...) {
#   # Determine Python
#   python_cmd <- if (Sys.info()["sysname"] == "Windows") "python" else "python3"
#   python_path <- Sys.which(python_cmd)
#
#   # Check Python path
#   if (python_path == "") {
#     stop(paste("Cannot locate the", python_cmd, "executable. Ensure it's installed and in your system's PATH."))
#   }
#
#   # Try to get Python version
#   tryCatch({
#     python_version <- system(paste(python_path, "--version"), intern = TRUE)
#     if (!grepl("Python 3", python_version)) {
#       stop("Python 3 is required, but a different version was found. Please install Python 3.")
#     }
#   }, error = function(e) {
#     stop(paste("Failed to get Python version with path:", python_path, "Error:", e$message))
#   })
#
#   # 创建并使用虚拟环境
#   venv <- "flair_env"
#   venv_created <- TRUE
#   if (!reticulate::virtualenv_exists(venv)) {
#     tryCatch({
#       reticulate::virtualenv_create(venv)
#       packageStartupMessage("Created 'flair_env' virtual environment for flair project.")
#     }, error = function(e) {
#       venv_created <- FALSE
#       packageStartupMessage("Failed to create 'flair_env' for flair project. Attempting to load 'flair' in default Python environment.")
#     })
#   }
#
#   if (venv_created) {
#     reticulate::use_virtualenv(venv, required = TRUE)
#     packageStartupMessage("Initialized 'flair_env' virtual environment.")
#
#   } else {
#     tryCatch({
#       # Print Python configuration information
#       reticulate::use_python(python_path, required = TRUE)
#       packageStartupMessage("Current Python Configuration:")
#       print(reticulate::py_config())
#     }, error = function(e) {
#       packageStartupMessage("Failed to use the default Python environment. Please manually create a virtual environment using reticulate or Anaconda and install 'flair' within that environment.")
#       return(invisible(NULL)) # 退出 .onAttach，但不停止加载包
#     })
#   }
#
#   # Check and install 'flair' module
#   if (!reticulate::py_module_available("flair")) {
#     packageStartupMessage("Attempting to install the 'flair' Python module...")
#     tryCatch({
#       reticulate::py_install("flair", envname = venv)
#     }, error = function(e) {
#       stop("Failed to install 'flair'. Error: ", e$message)
#     })
#     if (!reticulate::py_module_available("flair")) {
#       stop("Installation of 'flair' failed. Please install it manually in the Python environment.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m",  get_flair_version(),"\033[39m\033[22m", sep = "")))
#   }
# }
.onAttach <- function(...) {
  # Specify Python path explicitly
  # python_path <- Sys.which("python3")
  # if (python_path == "") {
  #   stop("Cannot locate the Python 3 path. Ensure Python 3 is installed and in your system's path.")
  # }

  # Determine Python command
  python_cmd <- if (Sys.info()["sysname"] == "Windows") "python" else "python3"
  python_path <- Sys.which(python_cmd)

  # Check Python path
  if (python_path == "") {
    packageStartupMessage(paste("Cannot locate the", python_cmd, "executable. Ensure it's installed and in your system's PATH. flaiR functionality requiring Python will not be available."))
    return(invisible(NULL))  # Exit .onAttach without stopping package loading
  }

  # Check Python versio Try to get Python version
  tryCatch({
    python_version <- system(paste(python_path, "--version"), intern = TRUE)
    if (!grepl("Python 3", python_version)) {
      packageStartupMessage("Python 3 is required, but a different version was found. Please install Python 3. flaiR functionality requiring Python will not be available.")
      return(invisible(NULL))  # Exit .onAttach without stopping package loading
    }
  }, error = function(e) {
    packageStartupMessage(paste("Failed to get Python version with path:", python_path, "Error:", e$message, ". flaiR functionality requiring Python will not be available."))
    return(invisible(NULL))  # Exit .onAttach without stopping package loading
  })

  # Check if PyTorch is installed
  check_torch_version <- function() {
    torch_version_command <- paste(python_path, "-c 'import torch; print(torch.__version__)'")
    result <- system(torch_version_command, intern = TRUE)
    if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
      return(list(paste("PyTorch", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
    }
    # Return flair version
    return(list(paste("PyTorch", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
  }

  # Check if flair is installed
  check_flair_version <- function() {
    flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
    result <- system(flair_version_command, intern = TRUE)
    if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
      return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
    }
    # Return flair version
    return(list(paste("flair", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
  }

  flair_version <- check_flair_version()
  torch_version <- check_torch_version()

  if (isFALSE(flair_version[[2]])) {
    packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))

    commands <- c(
      paste(python_path, "-m pip install --upgrade pip"),
      paste(python_path, "-m pip install torch"),
      paste(python_path, "-m pip install flair")
    )

    vapply(commands, system)
    flair_check_again <- check_flair_version()

    if (isFALSE(flair_check_again[[2]])) {
      packageStartupMessage("Failed to install Flair. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
    }
  } else {
    packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m", get_flair_version(), "\033[39m\033[22m", sep = "")))
  }

  # 3. Test the command manually
  # test_flair_command <- paste(python_path, "-c 'import flair'")
  # test_result <- try(system(test_flair_command, intern = TRUE, ignore.stderr = TRUE), silent = TRUE)

  # if (inherits(test_result, "try-error")) {
  #   warning("There was an issue while manually testing the flair import. This might mean flair isn't installed in Python.")
  # } else {
  #   packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
  # }
}
