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


#' @title Create or Use Python environment for Flair
#'
#' @description
#' This function checks whether the Flair Python library is installed in the
#' current Python environment. If it is not, it attempts to install it either
#' in the current conda environment or creates a new one.
#'
#' @param env The name of the conda environment to be used or
#' created (default is "r-reticulate").
#'
#' @return Nothing is returned. The function primarily ensures that the Python
#' library Flair is installed and available.
#' @export
#' @importFrom reticulate import py_config use_condaenv
#' @importFrom rstudioapi restartSession
create_flair_env <- function(env = "r-reticulate") {
  # check if flair is already installed in the current Python environment
  if (reticulate::py_module_available("flair")) {
    message("Environment creation stopped.", "\n", "Flair is already installed in ", reticulate::py_config()$python)
    message(sprintf("Using Flair:  %-48s", reticulate::import("flair")$`__version__`))
    return(invisible(NULL))
  }
  paths <- reticulate::conda_list()
  env_path <- paths[grep("envs/", paths$python), "python"][1]
  if (grepl("envs/", env_path)) {
    message("you already created:", length(paths[grep("envs/", paths$python), "python"]))
    message("you can run use_condaenv(",as.character(env_path),") to activate the enviroment in your R." )
    reticulate::use_condaenv(env)
  } else {
    # No conda environment found or active, so create one
    reticulate::conda_create(env)
    message("No conda environment found. Creating a new environment named '", env, "'. ", "After restarting the R session, please run create_flair_env() again.")
    rstudioapi::restartSession()
  }
}


#' @title Check the Device for ccelerating PyTorch
#'
#' @description This function verifies if the specified device is available for PyTorch.
#' If CUDA is not available, a message is shown. Additionally, if the system
#' is running on a Mac M1, MPS will be used instead of CUDA.
#'
#' @note Flair NLP operates under the [PyTorch](https://pytorch.org) framework.
#' As such, we can use the `$to` method to set the device for the Flair Python
#' library. `flair_device("cpu")`  allows you to select whether to use the CPU,
#' CUDA devices (like cuda:0, cuda:1, cuda:2), or specific MPS devices on Mac
#' (such as mps:0, mps:1, mps:2). For information on Accelerated PyTorch
#' training on Mac, please refer to https://developer.apple.com/metal/pytorch/.
#' For more about CUDA, please visit: https://developer.nvidia.com/cuda-zone.
#'
#' @param device Character. The device to be set for PyTorch.
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
      warning("MPS requires macOS 12.3 or higher. Falling back to CPU.",
              "\nTo use MPS, ensure the following requirements are met:",
              "\n- Mac computers with Apple silicon or AMD GPUs",
              "\n- macOS 12.3 or later",
              "\n- Python 3.7 or later",
              "\n- Xcode command-line tools installed (xcode-select --install)",
              "\nMore information: https://developer.apple.com/metal/pytorch/")
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

# check_texts_and_ids <- function(texts, doc_ids) {
#   if (is.null(texts) || length(texts) == 0) {
#     stop("The texts cannot be NULL or empty.")
#   }
#   if (is.null(doc_ids) || length(doc_ids) == 0) {
#     stop("The doc_ids cannot be NULL or empty.")
#   }
#   if (length(texts) != length(doc_ids)) {
#     stop("The lengths of texts and doc_ids do not match.")
#   }
# }
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
