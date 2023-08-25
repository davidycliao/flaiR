#' @title Check for Active Internet Connection
#' This function checks if there's an active internet connection using
#' the `curl` package. In case of an error or no connection, it will return `FALSE`.
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

#' Create and setup the `r-reticulate` environment for Flair using reticulate.
#'
#' This function ensures that the `flair` Python module is installed in the
#' `r-reticulate` conda environment created by the `reticulate` R package.
#' If the `flair` module is already installed, the function prints its version
#' and exits without making any changes.
#'
#' @return NULL. The function is used for its side effects of setting up the conda environment.
#' @importFrom reticulate py_module_available py_config use_condaenv
#' @export
create_flair_env <- function(...) {
  # check if flair is already installed in the current Python environment
  if (reticulate::py_module_available("flair")) {
    message("Flair is already installed in the current Python environment. Environment creation stopped.")

    # Get Flair version
    flair_version <- reticulate::import("flair")$`__version__`
    message(sprintf("## Using Flair:  %-48s ##", flair_version))
    python_version <- reticulate::py_config()$version
    message(sprintf("## Using Python: %-48s ##", python_version))

    return()  # This will end the function without creating a new environment
  }
  # Check if reticulate R package is installed
  if (!"reticulate" %in% rownames(installed.packages())) {
    # If not installed, install the reticulate R package
    install.packages("reticulate")
  }

  # Load the reticulate library
  library(reticulate)

  # Switch to the desired conda environment
  use_condaenv("r-reticulate", required = TRUE)

  # Construct the pip command
  pip_command <- paste(py_config()$python, "-m pip install flair")

  # Execute the pip command
  system(pip_command)
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


