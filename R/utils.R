#' @title Clear Flair Cache
#'
#' @description
#' This function clears the cache associated with the Flair Python library.
#' The cache directory is typically located at "~/.flair".
#' @param ... The argument passed to next.
#' @return Returns NULL invisibly. Messages are printed indicating whether
#' the cache was found and cleared.
#' @export
#'
#' @examples
#' \dontrun{
#' clear_flair_cache()
#' }
clear_flair_cache <- function(...) {
  # flair cache directory
  flair_cache_dir <- file.path(path.expand("~"), ".flair")

  # Check if the directory still exists
  if (!dir.exists(flair_cache_dir)) {
    cat("Flair cache directory does not exist.\n")
    return(NULL)
  }

  # List files in the flair cache directory
  cache_files <- list.files(flair_cache_dir)
  if(length(cache_files) > 0) {
    cat("Files in flair cache directory:\n")
    print(cache_files)
  } else {
    cat("No files in flair cache directory.\n")
  }

  # Remove the directory and its contents
  unlink(flair_cache_dir, recursive = TRUE)
  cat("Flair cache directory has been cleared.\n")

  return(invisible(NULL))
}


#' @title  Show Flair Cache Preloaed flair's Directory
#'
#' @description This function lists the contents of the flair cache directory
#' and returns them as a data frame.
#'
#' @return A data frame containing the file paths of the contents in the flair
#' cache directory. If the directory does not exist or is empty, NULL is returned.
#' @export
#' @examples
#' \dontrun{
#' show_flair_cache()
#' }
show_flair_cache <- function() {
  flair_cache_dir <- file.path(path.expand("~"), ".flair")

  # Check if the directory still exists
  if (!dir.exists(flair_cache_dir)) {
    cat("Flair cache directory does not exist.\n")
    return(NULL)
  }

  # List all files and directories in the flair cache directory
  cache_contents <- list.files(flair_cache_dir, full.names = TRUE, recursive = TRUE)

  if (length(cache_contents) > 0) {
    cat("Contents in flair cache directory:\n")

    # Create a data frame with the cache contents
    cache_df <- data.frame(FilePath = cache_contents, stringsAsFactors = FALSE)
    print(cache_df)

    # Ask user if they agree to proceed with deletion
    response <- tolower(readline("Do you agree to proceed? All downloaded models in the cache will be completely deleted. (yes/no): "))

    if (response == "yes") {
      cat("Deleting cached models...\n")
      unlink(flair_cache_dir, recursive = TRUE)
      cat("Cache cleared.\n")
    } else {
      cat("Clearance cancelled.\n")
    }

    return(cache_df)
  } else {
    cat("No contents in flair cache directory.\n")
    return(NULL)
  }
}

#' @title Check the Device for Accelerating PyTorch
#'
#' @description This function verifies if the specified device is available for PyTorch.
#' If CUDA is not available, a message is shown. Additionally, if the system
#' is running on a Mac M1, MPS will be used instead of CUDA. Checks if the specified device is compatible with the current system's
#' hardware and operating system configuration, particularly for Mac systems
#' with Apple M1/M2 silicon using Metal Performance Shaders (MPS).
#'
#' @details
#' If MPS is available and the system meets the requirements, a device of type
#' MPS will be returned. Otherwise, a CPU device will be used. The requirements
#' for using MPS are as follows:\\cr
#' - Mac computers with Apple silicon or AMD GPUs\\cr
#' - macOS 12.3 or later\\cr
#' - Python 3.7 or later\\cr
#' - Xcode command-line tools installed (`xcode-select --install`)\\cr
#' More information at: \url{https://developer.apple.com/metal/pytorch/}.
#'
#' @param device A character string specifying the device type.
#'
#' @return A PyTorch device object.
#'
#' @importFrom reticulate import
#' @keywords internal
check_device <- function(device) {
  pytorch <- reticulate::import("torch")
  system_info <- Sys.info()

  if (system_info["sysname"] == "Darwin" &&
      system_info["machine"] == "arm64" &&
      device == "mps") {

    os_version <- as.numeric(strsplit(system_info["release"], "\\.")[[1]][1])

    if (os_version >= 12.3) {
      message("MPS is used on Mac M1/M2.")
      return(pytorch$device(device))
    } else {
      warning("MPS requires macOS 12.3 or higher. Falling back to CPU.\\cr
         To use MPS, ensure the following requirements are met:\\cr
         - Mac computers with Apple silicon or AMD GPUs\\cr
         - macOS 12.3 or later\\cr
         - Python 3.7 or later\\cr
         - Xcode command-line tools installed (xcode-select --install)\\cr
         More information: https://developer.apple.com/metal/pytorch/")
      message("Using CPU.")
      return(pytorch$device("cpu"))
    }
  }
  else if (device == "cpu" ) {
    message("CPU is used.")
    return(pytorch$device(device))
  }
  else if (device != "mps" && !pytorch$cuda$is_available()) {
    message("CUDA is not available on this machine. Using CPU.")
    return(pytorch$device("cpu"))
  }
  else if (device == "cuda" && pytorch$cuda$is_available()) {
    message("CUDA is available and will be used.")
    return(pytorch$device(device))
  }
  else {
    warning("Unknown device specified. Falling back to use CPU.")
    return(pytorch$device("cpu"))
  }
}

#' @title Check the Specified Batch Size
#'
#' @description Validates if the given batch size is a positive integer.
#'
#' @param batch_size Integer. The batch size to be checked.
#' @keywords internal
check_batch_size <- function(batch_size) {
  if (!is.numeric(batch_size) || batch_size <= 0 || (batch_size %% 1 != 0)) {
    stop("Invalid batch size. It must be a positive integer.")
  }
}


#' @title Check the texts and document IDs
#'
#' @description Validates if the given texts and document IDs are not NULL or empty.
#'
#' @param texts List. A list of texts.
#' @param doc_ids List. A list of document IDs.
#' @keywords internal
check_texts_and_ids <- function(texts, doc_ids) {
  if (is.null(texts) || length(texts) == 0) {
    stop("The texts cannot be NULL or empty.")
  }

  if (is.null(doc_ids)) {
    warning("doc_ids is NULL. Auto-assigning doc_ids.")
    doc_ids <- seq_along(texts)
  } else if (length(texts) != length(doc_ids)) {
    stop("The lengths of texts and doc_ids do not match.")
  }
  list(texts = texts, doc_ids = doc_ids)
}


#' @title Check the `show.text_id` Parameter
#'
#' @description Validates if the given `show.text_id` is a logical value.
#'
#' @param show.text_id Logical. The parameter to be checked.
#' @keywords internal
check_show.text_id <- function(show.text_id) {
  if (!is.logical(show.text_id) || is.na(show.text_id)) {
    stop("show.text_id should be a non-NA logical value.")
  }
}


#' @title  Perform Garbage Collection Based on Condition
#'
#' @description This function checks the value of `gc.active` to determine whether
#' or not to perform garbage collection. If `gc.active` is `TRUE`,
#' the function will perform garbage collection and then send a
#' message indicating the completion of this process.
#'
#' @param gc.active A logical value indicating whether or not to
#'     activate garbage collection.
#'
#' @return A message indicating that garbage collection was performed
#' if `gc.active` was `TRUE`. Otherwise, no action is taken or message is
#' displayed.
#'
#' @keywords internal
check_and_gc <- function(gc.active) {
  if (!is.logical(gc.active) || is.na(gc.active)) {
    stop("gc.active should be a logical value.")
  }

  if (isTRUE(gc.active)) {
    gc()
    message("Garbage collection after processing all texts")
  }
}


#' @title Check the Given Language Models against Supported Languages Models
#'
#' @description This function checks whether a provided language is supported.
#' If it's not, it stops the execution and returns a message indicating the
#' supported languages.
#'
#' @param language The language to check.
#' @param supported_lan_models A vector of supported languages.
#'
#' @return This function does not return anything, but stops execution if the
#' check fails.
#'
#' @examples
#' # Assuming 'en' is a supported language and 'abc' is not:
#' check_language_supported("en", c("en", "de", "fr"))
#' # check_language_supported("abc", c("en", "de", "fr")) # will stop execution
#' @export
#' @keywords internal
check_language_supported <- function(language, supported_lan_models) {
  attempt::stop_if_all(
    !language %in% supported_lan_models,
    isTRUE,
    msg = paste0("Unsupported language. Supported languages are: ",
                 paste(supported_lan_models, collapse = ", "),
                 ".")
  )
}


#' @title Check Environment Pre-requisites
#'
#' @description This function checks if Python is installed, if the flair module
#' is available in Python,
#'
#' and if there's an active internet connection.
#' @param ... passing additional arguments.
#' @return A message detailing any missing pre-requisites.
#' @keywords internal
#' @importFrom attempt stop_if_all
check_prerequisites <- function(...) {
  # Check if Python is installed
  attempt::stop_if_all(
    check_python_installed(),
    isFALSE,
    msg = "Python is not installed in your R environment."
  )

  # Check if flair module is available in Python
  attempt::warn_if_all(
    reticulate::py_module_available("flair"),
    isFALSE,
    msg = paste(
      "flair is not installed at",
      reticulate::py_config()[[1]]
    )
  )

  # Check for an active internet connection
  attempt::warn_if_all(
    curl::has_internet(),
    isFALSE,
    msg = "Internet connection issue. Please check your network settings."
  )
  return("All pre-requisites met.")
}


#' @title Retrieve Flair Version
#'
#' @description Gets the version of the installed Flair module in the current
#' Python environment.
#'
#' @keywords internal
#' @return Character string representing the version of Flair. If Flair is not
#' installed, this may return `NULL` or cause an error.
get_flair_version <- function(...) {
  flair <- reticulate::import("flair")
  # Assuming flair has an attribute `__version__` (this might not be true)
  return(flair$`__version__`)
}


#' @title Check Flair
#'
#' @description
#' Determines if the Flair Python module is available in the current Python
#' environment.
#'
#' @keywords internal
#' @return Logical. `TRUE` if Flair is installed, otherwise `FALSE`.
check_flair_installed <- function(...) {
  return(reticulate::py_module_available("flair"))
}


#' @title Check for Available Python Installation
#'
#' @description
#' This function checks if any environment is installed on the R system.
#'
#' @param ... any param to run.
#' @return Logical. `TRUE` if Python is installed, `FALSE` otherwise.
#' Additionally, if installed, the path to the Python installation is printed.
#' @keywords internal
check_python_installed <- function(...) {
  # Check if running on Windows
  if (.Platform$OS.type == "windows") {
    command <- "where python"
  } else {
    command <- "which python3"
  }

  # Locate python path
  result <- system(command, intern = TRUE, ignore.stderr = TRUE)

  # Check if the result is a valid path
  if (length(result) > 0 && file.exists(result[1])) {
    # cat("Python is installed at:", result[1], "\n")
    return(TRUE)
  } else {
    # cat("Python is not installed on this system.\n")
    return(FALSE)
  }
}


#' @title Install a Specific Python Package and Return Its Version
#'
#' @description This function checks for the Python interpreter's location (either
#' specified by the user or automatically located), compares it with the current
#' R session's Python setting, installs a specified Python package using the identified
#' Python interpreter, and returns the package version and installation environment.
#'
#' @param package_name The name of the Python package to install.
#' @param package_version The version of the Python package to install. If `NULL`,
#'  the latest version is installed.
#' @param python_path The path to the Python interpreter to be used for
#' installation. If not provided, it defaults to the result of `Sys.which("python3")`.
#' @return A list containing the package name, installed version, and the path
#' to the Python interpreter used for installation.
#'
#' @examples
#' \dontrun{
#' install_python_package(package_name ="flair", package_version ="0.12")
#' }
#' @export
install_python_package <- function(package_name, package_version = NULL, python_path = Sys.which("python3")) {
  # Check if a path is given or found by Sys.which
  if (python_path == "") {
    stop("Python is not installed, not found in the system PATH, or an incorrect path was provided.")
  } else {
    message("Using Python at: ", python_path)
  }


  # Define the full package reference
  if (is.null(package_version)) {
    package_ref <- package_name
    warning(paste("The version of the Python package is not defined. Flair will automatically install the current version of ", "package_name", sep = " " ))
  } else {
    package_ref <- paste(package_name, "==", package_version, sep = "")
  }

  # Find Python path
  python_path <- Sys.which("python3")

  # Check if Python is found
  if (python_path == "") {
    stop("Python is not installed or not found in the system PATH.")
  } else {
    message("Python found at: ", python_path)
  }

  # Check if Python location is the same as the current session
  sys_py <- system2(python_path, "-c 'import sys; print(sys.executable)'", stdout = TRUE)
  r_py <- Sys.getenv("RETICULATE_PYTHON")
  if (r_py != "" && normalizePath(sys_py) != normalizePath(r_py)) {
    warning("Python location is not the same as the current R session.")
  } else {
    message("Python location is consistent with the current R session.")
  }

  # Install the specified package
  install_command <- paste(python_path, "-m pip install", package_ref)
  update_pip_first <- paste(python_path, "-m pip install --upgrade pip")
  system(update_pip_first)
  system(install_command)

  # Check if the package is installed and get the version
  check_version_command <- paste(python_path, "-c 'import", package_name, "; print(", package_name, ".__version__)'", sep=" ")
  package_version_installed <- system(check_version_command, intern = TRUE)

  if (length(package_version_installed) > 0 && !startsWith(package_version_installed, "Traceback")) {
    message("Package '", package_name, "' installed successfully, version: ", package_version_installed)
    return(list(
      package_name = package_name,
      package_version = package_version_installed,
      python_path = python_path
    ))
  } else {
    stop("Failed to install the package or retrieve the version.")
  }
}


# install_python_package <- function(package_name, package_version = NULL, python_path = Sys.which("python3")) {
#   if (python_path == "") {
#     stop("Python is not installed, not found in the system PATH, or an incorrect path was provided.")
#   } else {
#     message("Using Python at: ", python_path)
#   }
#
#   if (is.null(package_version)) {
#     package_ref <- package_name
#     warning("The version of the Python package is not defined. The latest version of the package will be installed.")
#   } else {
#     package_ref <- paste(package_name, "==", package_version, sep = "")
#   }
#
#   # Upgrade pip before installing the package
#   update_pip_command <- paste(python_path, "-m pip install --upgrade pip")
#   if (system(update_pip_command, intern = TRUE) != 0) {
#     warning("Failed to upgrade pip. Please check your Python installation.")
#   }
#
#   # Install the specified package
#   install_command <- paste(python_path, "-m pip install", package_ref)
#   if (system(install_command, intern = TRUE) != 0) {
#     stop("Failed to install the package. Please check the command and try again.")
#   }
#
#   # Check if the package is installed and get the version
#   check_version_command <- paste(python_path, "-c 'import", package_name, "; print(", package_name, ".__version__)'")
#   package_version_installed <- tryCatch({
#     system(check_version_command, intern = TRUE)
#   }, error = function(e) {
#     NA
#   })
#
#   if (is.na(package_version_installed)) {
#     stop("Failed to install the package or retrieve the version.")
#   }
#
#   message("Package '", package_name, "' installed successfully, version: ", package_version_installed)
#   return(list(
#     package_name = package_name,
#     package_version = package_version_installed,
#     python_path = python_path
#   ))
# }

#' @title Uninstall a Python Package
#'
#' @description `uninstall_python_package` function uninstalls a specified Python
#' package using the system's Python installation. It checks if Python is
#' installed and accessible, then proceeds to uninstall the package. Finally,
#' `uninstall_python_package` verifies that the package has been successfully uninstalled.
#'
#' @param package_name The name of the Python package to uninstall.
#' @param python_path The path to the Python executable. If not provided, it uses the system's default Python path.
#'
#' @return Invisibly returns TRUE if the package is successfully uninstalled, otherwise it stops with an error message.
#' @export
#'
#' @examples
#' \dontrun{
#' uninstall_python_package("numpy")
#' }
uninstall_python_package <- function(package_name, python_path = Sys.which("python3")) {
  # Check if Python is installed or found in the system PATH
  if (python_path == "") {
    stop("Python is not installed, not found in the system PATH, or an incorrect path was provided.")
  } else {
    message("Using Python at: ", python_path)
  }

  # Uninstall the specified package
  uninstall_command <- paste(python_path, "-m pip uninstall -y", package_name)
  system(uninstall_command)

  # Check if the package is still installed
  check_uninstall_command <- paste(python_path, "-c 'import ", package_name, "'", sep="")
  package_uninstall_check <- try(system(check_uninstall_command, intern = TRUE, ignore.stderr = TRUE), silent = TRUE)

  if (inherits(package_uninstall_check, "try-error")) {
    message("Package '", package_name, "' was successfully uninstalled.")
    invisible(TRUE)
  } else {
    stop("Failed to uninstall the package. It may still be installed.")
  }
}
