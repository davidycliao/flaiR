#' Install Flair NLP in Python environment
#'
#' @param force Logical, whether to force reinstall packages. Default is FALSE.
#' @param python_version Character, specify Python version to install. Default is "3.10".
#' @param flair_version Character, specify Flair version to install. Default is "0.11.3".
#' @param pip_options Character, additional pip install options. Default is NULL.
#'
#' @return Invisible NULL, called for side effects
#' @export
install_flair <- function(force = FALSE,
                          python_version = "3.10",
                          flair_version = "0.11.3",  # Changed default to fixed version
                          pip_options = NULL) {

  print_status <- function(component, status, extra_info = NULL) {
    symbol <- if(status) "\u2713" else "\u2717"
    color <- if(status) "\033[32m" else "\033[31m"
    message <- sprintf("%s%s\033[39m %s", color, symbol, component)
    if (!is.null(extra_info)) {
      message <- paste0(message, ": ", extra_info)
    }
    message(message)
  }

  # Initial cleanup
  Sys.unsetenv("RETICULATE_PYTHON")
  options(reticulate.python = NULL)

  # Make sure reticulate is available
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    install.packages("reticulate")
  }

  tryCatch({
    # Setup Python environment
    message("\nPython Configuration:")

    # Get Python path
    python_path <- if (Sys.info()["sysname"] == "Windows") {
      normalizePath(file.path(Sys.getenv("LOCALAPPDATA"), "Programs", "Python", python_version, "python.exe"))
    } else {
      "/usr/local/bin/python3.10"
    }

    # Use system Python
    if (file.exists(python_path)) {
      Sys.setenv(RETICULATE_PYTHON = python_path)
      reticulate::use_python(python_path, required = TRUE)
      print_status("Python", TRUE, python_path)
    } else {
      stop("Python not found at ", python_path)
    }

    # Print version info
    print_status("Version", TRUE, paste("Using Flair version:", flair_version))

    # Install packages
    print_status("Installation", TRUE, "Installing required packages...")

    # Install core packages
    reticulate::py_install(c("pip", "setuptools", "wheel"), pip = TRUE)

    # Install PyTorch and dependencies
    packages <- c(
      "numpy==1.26.4",
      "scipy==1.12.0",
      "torch>=2.0.0",
      "transformers>=4.30.0",
      sprintf("flair==%s", flair_version)
    )

    for (pkg in packages) {
      print_status("Package", TRUE, paste("Installing", pkg))
      tryCatch({
        reticulate::py_install(pkg, pip = TRUE)
      }, error = function(e) {
        print_status("Package", FALSE, paste("Failed to install", pkg))
        stop(e$message)
      })
    }

    # Verify installation
    flair_check <- try({
      flair <- reticulate::import("flair")
      version <- reticulate::py_get_attr(flair, "__version__")
      list(status = TRUE, version = version)
    }, silent = TRUE)

    if (!inherits(flair_check, "try-error") && flair_check$status) {
      print_status(
        "Flair NLP",
        TRUE,
        paste("Successfully installed version", flair_check$version)
      )
      message("\nIMPORTANT: Please restart R session to use the newly installed environment")
    } else {
      print_status("Flair NLP", FALSE, "Installation failed")
      message("\nTroubleshooting steps:")
      message("1. Try running install_flair(force = TRUE)")
      message("2. Check your Python installation")
      message("3. Check your internet connection")
    }

  }, error = function(e) {
    print_status("Installation", FALSE, paste("Error:", e$message))
    message("\nTroubleshooting steps:")
    message("1. Check if Python ", python_version, " is installed")
    message("2. Try installing Python manually")
    message("3. Make sure you have internet access")
  })

  invisible(NULL)
}
