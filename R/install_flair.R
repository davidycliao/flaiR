#' Install Flair NLP in Python environment
#'
#' This function installs Flair NLP and its dependencies in a Python virtual environment.
#' If Python is not found, it will provide instructions for installing Python.
#'
#' @param force Logical, whether to force reinstall packages. Default is FALSE.
#' @param python_version Character, specify Python version to install. Default is "3.10".
#' @param flair_version Character, specify Flair version to install. Use "latest" for the latest version.
#' @param pip_options Character, additional pip install options. Default is NULL.
#'
#' @return Invisible NULL, called for side effects
#' @export
#'
#' @examples
#' \dontrun{
#' # Install latest version
#' install_flair()
#'
#' # Install specific version
#' install_flair(flair_version = "0.11.3")
#'
#' # Force reinstall with specific Python version
#' install_flair(force = TRUE, python_version = "3.9")
#' }
install_flair <- function(force = FALSE,
                          python_version = "3.10",
                          flair_version = "latest",
                          pip_options = NULL) {
  # Print status function
  print_status <- function(component, status, extra_info = NULL) {
    symbol <- if(status) "\u2713" else "\u2717"  # checkmark or x
    color <- if(status) "\033[32m" else "\033[31m"  # green or red

    message <- sprintf("%s%s\033[39m %s", color, symbol, component)
    if (!is.null(extra_info)) {
      message <- paste0(message, ": ", extra_info)
    }
    message(message)
  }

  # Check if in Docker
  if (file.exists("/.dockerenv")) {
    stop("Cannot install in Docker environment. Please include Flair in your Docker image.")
  }

  # Function to get latest Flair version from PyPI
  get_latest_flair_version <- function() {
    tryCatch({
      # Using Python to get latest version from PyPI
      cmd <- "python3 -c \"import json, urllib.request; print(json.loads(urllib.request.urlopen('https://pypi.org/pypi/flair/json').read())['info']['version'])\""
      version <- system(cmd, intern = TRUE)
      if (length(version) > 0) return(version[1])
      return("0.11.3")  # Fallback version if can't get latest
    }, error = function(e) {
      message("Could not fetch latest version, using default version 0.11.3")
      return("0.11.3")
    })
  }

  # Determine Flair version to install
  if (flair_version == "latest") {
    flair_version <- get_latest_flair_version()
    print_status("Version", TRUE, paste("Latest Flair version:", flair_version))
  }

  # Try to find Python or help install it
  tryCatch({
    if (!requireNamespace("reticulate", quietly = TRUE)) {
      install.packages("reticulate")
    }

    # First try to find existing Python
    if (Sys.info()["sysname"] == "Windows") {
      python_cmd <- "python"
    } else {
      python_cmd <- "python3"
    }

    python_path <- Sys.which(python_cmd)

    # If Python not found, try to install it
    if (python_path == "") {
      message("Python not found. Attempting to install Python ", python_version, "...")
      reticulate::install_python(version = python_version)
    }

    # Setup virtual environment
    home_dir <- path.expand("~")
    venv_path <- file.path(home_dir, "flair_env")

    # Remove existing environment if force=TRUE
    if (force && dir.exists(venv_path)) {
      unlink(venv_path, recursive = TRUE)
      print_status("Environment", TRUE, "Removed existing environment")
    }

    # Create virtual environment
    if (!dir.exists(venv_path)) {
      reticulate::virtualenv_create(venv_path, version = python_version)
      print_status("Environment", TRUE, paste("Created at", venv_path))
    }

    # Activate virtual environment
    reticulate::use_virtualenv(venv_path, required = TRUE)

    # Install packages
    print_status("Installation", TRUE, "Installing required packages...")

    packages <- c(
      "numpy==1.26.4",
      "scipy==1.12.0",
      sprintf("flair[word-embeddings]==%s", flair_version)
    )

    for (pkg in packages) {
      cmd <- paste("install", pkg)
      if (force) cmd <- paste(cmd, "--force-reinstall")
      if (!is.null(pip_options)) cmd <- paste(cmd, pip_options)

      reticulate::py_install(cmd, pip = TRUE)
    }

    # Verify installation
    flair_check <- try({
      flair <- reticulate::import("flair")
      version <- reticulate::py_get_attr(flair, "__version__")
      list(status = TRUE, version = version)
    }, silent = TRUE)

    if (!inherits(flair_check, "try-error") && flair_check$status) {
      print_status("Flair NLP", TRUE,
                   paste("Successfully installed version", flair_check$version))
      message("\nPlease restart R session to use the newly installed environment")
    } else {
      print_status("Flair NLP", FALSE, "Installation failed")
      message("Please check the error messages above")
    }

  }, error = function(e) {
    print_status("Installation", FALSE, paste("Error:", e$message))
    message("\nIf the error persists, try:")
    message("1. Run install_flair(force = TRUE)")
    message("2. Check your Python installation")
    message("3. Check your internet connection")
  })

  invisible(NULL)
}
