#' @title Check for Active Internet Connection
#' This function checks if there's an active internet connection using
#' the `curl` package. In case of an error or no connection, it will return `FALSE`.
#'
#' @return Logical. TRUE if there's an active internet connection, otherwise FALSE.
#' @importFrom curl has_internet
has_internet <- function() {
  tryCatch({
    curl::has_internet()
  }, error = function(e) {
    FALSE
  })
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
create_flair_env <- function(env_name = "flair_env", python_ver = "3.8") {
  # Create the conda environment
  python_path <- reticulate::conda_create(env_name, python_version = python_ver)
  cat(paste("Python path for the new environment:", python_path), sep="\n")

  # Restart the R session
  if (interactive()) {
    message("Restarting R session...")
    rstudioapi::restartSession()
  } else {
    warning("Not in an interactive session. R session was not restarted.")
  }

  # Activate the conda environment
  reticulate::use_condaenv(env_name)

  # Install Flair using pip
  reticulate::py_install("flair", pip = TRUE)
  return(python_path)
}


clear_flair_cache <- function() {
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



