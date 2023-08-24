#' @title Check for Active Internet Connection
#' This function checks if there's an active internet connection using
#' the `curl` package. In case of an error or no connection, it will return `FALSE`.
#'
#' @return Logical. TRUE if there's an active internet connection, otherwise FALSE.
#' @importFrom curl has_internet
#' @keywords internal
has_internet <- function() {
  tryCatch({
    curl::has_internet()
  }, error = function(e) {
    FALSE
  })
}


#' Check If Flair is Installed
#'
#' Determines if the Flair Python module is available in the current Python environment.
#'
#' @keywords internal
#' @export check_flair_installed
#' @return Logical. `TRUE` if Flair is installed, otherwise `FALSE`.
check_flair_installed <- function(...) {
  return(reticulate::py_module_available("flair"))
}


#' Create an environment to interface with Python for Flair.
#' This function creates a new conda environment specifically for Flair, restarts
#' the R session, and installs Flair using pip.
#'
#' @param env_name Name of the conda environment. Defaults to "flair_env".
#' @param python_ver Python version to be used in the conda environment. Defaults to "3.8".
#'
#' @return The path to the Python executable in the new environment.
#' @importFrom reticulate conda_create use_condaenv py_install
#' @importFrom rstudioapi restartSession
#' @export
# create_flair_env <- function(env_name = "flair_env", python_ver = "3.8") {
#   # Create the conda environment
#   python_path <- reticulate::conda_create(env_name, python_version = python_ver)
#   cat(paste("Python path for the new environment:", python_path), sep="\n")
#
#   # Restart the R session
#   if (interactive()) {
#     message("Restarting R session...")
#     rstudioapi::restartSession()
#   } else {
#     warning("Not in an interactive session. R session was not restarted.")
#   }
#
#   # Activate the conda environment
#   reticulate::use_condaenv(env_name)
#   message(sprintf("## Using Python: %-48s ##", python_version))
#   message(sprintf("## Using Flair:  %-48s ##", flair_version))
#   # Install Flair using pip
#   reticulate::py_install("flair", pip = TRUE)
#   return(python_path)
# }

# create_flair_env <- function(env_name = "flair_env", python_ver = "3.7") {
#   # Create the conda environment
#   python_path <- reticulate::conda_create(env_name, python_version = python_ver)
#   cat(paste("Python path for the new environment:", python_path), sep="\n")
#   # Restart the R session
#   if (interactive()) {
#     message("Restarting R session...")
#     rstudioapi::restartSession()
#   } else {
#     warning("Not in an interactive session. R session was not restarted.")
#   }
#
#   # Activate the conda environment
#   reticulate::use_condaenv(env_name, required = TRUE)
#
#   # Install Flair using pip
#   reticulate::conda_install("flair_env", packages = "flair")
#
#   # Report Python version
#   python_version <- reticulate::py_config()$version
#   message(sprintf("## Using Python: %-48s ##", python_version))
#
#   # Check if flair is installed
#   if (reticulate::py_module_available("flair")) {
#     # Get Flair version
#     flair_version <- reticulate::import("flair")$`__version__`
#     message(sprintf("## Using Flair:  %-48s ##", flair_version))
#   } else {
#     message(sprintf("## Using Flair:  %-47s ##", "not installed in the current Python environment."))
#   }
#
#   return(python_path)
# }
#

create_flair_env <- function(env_name = "flair_env", python_ver = "3.7") {
  # Create the conda environment
  python_path <- reticulate::conda_create(env_name, python_version = python_ver)
  cat(paste("Created new Conda environment at:", python_path), sep="\n")

  # Restart the R session

  if (interactive()) {
    message("Restarting R session...")
    rstudioapi::restartSession()
  } else {
    warning("This is not an interactive session. R session was not restarted.")
  }

  # Activate the conda environment
  reticulate::use_condaenv(env_name, required = TRUE)

  # Install Flair using pip
  reticulate::conda_install("flair_env", packages = "flair")

  # Print a separator for clarity
  message(rep("-", 60))

  # Report Python version
  python_version <- reticulate::py_config()$version
  message(sprintf("Python Version: %s", python_version))

  # Check if flair is installed
  if (reticulate::py_module_available("flair")) {
    # Get Flair version
    flair_version <- reticulate::import("flair")$`__version__`
    message(sprintf("Flair Version:  %s", flair_version))
  } else {
    message("Flair not installed in the current Python environment.")
  }

  # Print a separator for clarity
  message(rep("-", 60))

  return(python_path)
}


#' Clear Flair Cache
#'
#' This function clears the cache associated with the Flair Python library.
#' The cache directory is typically located at "~/.flair".
#'
#' @return Returns NULL invisibly. Messages are printed indicating whether the cache was found and cleared.
#' @export
#'
#' @examples
#' \dontrun{
#' clear_flair_cache()
#' }
clear_flair_cache <- function(...) {
  # Define the flair cache directory
  flair_cache_dir <- file.path(path.expand("~"), ".flair")

  # Check if the directory exists
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


