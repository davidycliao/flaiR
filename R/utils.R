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

#' Create or use Python environment for Flair
#'
#' This function checks whether the Flair Python library is installed in the current Python environment.
#' If it is not, it attempts to install it either in the current conda environment or creates a new one.
#'
#' @param env The name of the conda environment to be used or created (default is "r-reticulate").
#'
#' @return Nothing is returned. The function primarily ensures that the Python library Flair is installed and available.
#' @export
#'
#' @examples
#' \dontrun{
#'   create_flair_env()
#' }
create_flair_env <- function(env = "r-reticulate") {

  # check if flair is already installed in the current Python environment
  if (reticulate::py_module_available("flair")) {
    message("Environment creation stopped.", "\n", "Flair is already installed in ", reticulate::py_config()$python)
    message(sprintf("Using Flair:  %-48s", reticulate::import("flair")$`__version__`))
    return(invisible(NULL))
  }
  # paths <- reticulate::conda_list()$python
  # env_path <- paths[grepl("envs/", paths)][1]
  # check conda environment in R
  paths <- reticulate::conda_list()
  env_path <- paths[grep("envs/", paths$python), "python"][1]
  if (grepl("envs/", env_path)) {
    message("you already created:", length(paths[grep("envs/", paths$python), "python"]))
    message("you can run use_condaenv(",as.character(env_path),") to activate the enviroment in your R" )
    reticulate::use_condaenv(env)
    # if (grepl("env",  paths[grepl(env, paths)][1])) {
    #   reticulate::use_condaenv(paths[grepl(env, paths)][1], required = TRUE)
    # system(paste(reticulate::py_config()$python, "-m pip install flair"))
    # message("Flair is installed in the eviroment of ", paths )

  } else {
    # No conda environment found or active, so create one
    reticulate::conda_create(env)
    message("No conda environment found. Creating a new environment named '", env, "'.")
    message("After restarting the R session, please run create_flair_env() again.")
    .rs.restartR()
    # reticulate::use_condaenv(env, required = TRUE)
  }
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


