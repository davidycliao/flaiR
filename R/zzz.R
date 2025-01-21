#' @title Initialize Python Environment and Load flaiR NLP
#' @description Sets up Python environment, manages virtual environment, and installs required flair NLP packages.
#'
#' @param ... Additional arguments passed to startup functions
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Checks for Docker environment
#'   \item Sets up operating system specific configurations:
#'     - Windows: Configures Python path
#'     - macOS: Sets KMP_DUPLICATE_LIB_OK environment variable
#'     - Linux: Uses system Python path
#'   \item Manages Python environment:
#'     - Detects existing Python installation
#'     - Provides installation guidance if Python not found
#'     - Supports Python versions 3.9 to 3.12
#'   \item Verifies and validates:
#'     - Python version compatibility
#'     - Flair NLP installation status
#'     - Package dependencies
#' }
#'
#' Error handling includes:
#' \itemize{
#'   \item Comprehensive environment checks
#'   \item Detailed error messages with installation guides
#'   \item System-specific troubleshooting suggestions
#' }
#'
#' Output includes:
#' \itemize{
#'   \item Environment status indicators
#'   \item Python version information
#'   \item Flair NLP version details
#'   \item Installation status and paths
#' }
#'
#' @section Virtual Environment:
#' The package uses a dedicated virtual environment ('flair_env') located in the user's home directory.
#' For Docker environments, it uses the pre-configured Python installation.
#'
#' @section Package Dependencies:
#' Required Python packages:
#' \itemize{
#'   \item numpy (version 1.26.4)
#'   \item scipy (version 1.12.0)
#'   \item flair (version 0.11.3 or higher)
#' }
#'
#' @section Operating System Support:
#' \itemize{
#'   \item Windows: Supports both standard Python and Anaconda installations
#'   \item macOS: Includes automatic KMP_DUPLICATE_LIB_OK configuration
#'   \item Linux: Compatible with system Python and virtual environments
#'   \item Docker: Supports pre-configured container environments
#' }
#'
#' @note
#' \itemize{
#'   \item Requires Python 3.9 or higher
#'   \item Creates 'flair_env' virtual environment if not exists
#'   \item Docker environments use pre-configured Python
#'   \item Restart R session after installation for changes to take effect
#' }
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{install_flair}} for manual installation
#'   \item \code{\link{check_flairenv}} for environment verification
#' }
#'
#' @return Invisible NULL, called for side effects
#' @keywords internal
#' @title Initialize Python Environment and Load flaiR NLP
#' @description Sets up Python environment, manages virtual environment, and installs required flair NLP packages.
#'
#' @param ... Additional arguments passed to startup functions
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Checks for Docker environment
#'   \item Sets up operating system specific configurations
#'   \item Manages Python environment
#'   \item Verifies and validates installations
#' }
#'
#' @return Invisible NULL, called for side effects
#' @keywords internal
.onAttach <- function(...) {
  # Print status function
  print_status <- function(component, status, extra_info = NULL) {
    symbol <- if(status) "\u2713" else "\u2717"  # checkmark or x
    color <- if(status) "\033[32m" else "\033[31m"  # green or red

    message <- sprintf("%s%s\033[39m %s", color, symbol, component)
    if (!is.null(extra_info)) {
      message <- paste0(message, ": ", extra_info)
    }
    packageStartupMessage(message)
  }

  # Check if running in Docker
  check_if_docker <- function() {
    tryCatch({
      if (file.exists("/.dockerenv")) {
        return(TRUE)
      }
      return(FALSE)
    }, error = function(e) {
      return(FALSE)
    })
  }

  is_docker <- check_if_docker()
  os_name <- Sys.info()["sysname"]

  # Python installation guide based on OS
  python_install_guide <- function(os_name) {
    if (os_name == "Windows") {
      return(paste(
        "To install Python:",
        "1. You can use reticulate: install.packages('reticulate'); reticulate::install_python(version = '3.10')",
        "2. Or download directly from https://www.python.org/downloads/",
        "3. Make sure to check 'Add Python to PATH' during installation",
        sep = "\n"
      ))
    } else if (os_name == "Darwin") {  # macOS
      return(paste(
        "To install Python:",
        "1. Using reticulate: install.packages('reticulate'); reticulate::install_python(version = '3.10')",
        "2. Or using Homebrew: brew install python@3.10",
        "3. Or download from https://www.python.org/downloads/macos",
        sep = "\n"
      ))
    } else {  # Linux
      return(paste(
        "To install Python:",
        "1. Using reticulate: install.packages('reticulate'); reticulate::install_python(version = '3.10')",
        "2. Or using apt: sudo apt-get update && sudo apt-get install python3.10",
        "3. Or using conda: conda install python=3.10",
        sep = "\n"
      ))
    }
  }

  # Set environment variables for macOS
  if (os_name == "Darwin") {
    current_kmp <- Sys.getenv("KMP_DUPLICATE_LIB_OK")
    Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
    print_status("KMP_DUPLICATE_LIB_OK", TRUE,
                 sprintf("%s -> TRUE", if(current_kmp == "") "not set" else current_kmp))
  }

  # Check Python environment
  if (is_docker) {
    python_path <- Sys.getenv("RETICULATE_PYTHON")
    if (python_path == "") {
      python_cmd <- if(os_name == "Windows") "python" else "python3"
      python_path <- Sys.which(python_cmd)
      if (python_path == "") {
        print_status("Python", FALSE, "Not found in Docker environment")
        packageStartupMessage("\nPlease ensure Python is installed in your Docker image")
        return(invisible(NULL))
      }
    }
    print_status("Environment", TRUE, sprintf("Docker (Python: %s)", python_path))
  } else {
    # Local environment setup
    if (os_name == "Windows") {
      python_cmd <- "python"
      tryCatch({
        python_path <- normalizePath(Sys.which(python_cmd), winslash = "/", mustWork = TRUE)
      }, error = function(e) {
        print_status("Python", FALSE, "Not found")
        packageStartupMessage("\n", python_install_guide(os_name))
        return(invisible(NULL))
      })
    } else {
      python_cmd <- "python3"
      python_path <- Sys.which(python_cmd)
    }

    if (python_path == "") {
      print_status("Python", FALSE, "Not found")
      packageStartupMessage("\n", python_install_guide(os_name))
      return(invisible(NULL))
    }
  }

  # Check Python version
  tryCatch({
    cmd <- sprintf('"%s" -V', python_path)
    python_version <- system(cmd, intern = TRUE)
    version_match <- regexpr("Python ([0-9.]+)", python_version)
    if (version_match > 0) {
      version_str <- regmatches(python_version, version_match)[[1]]
      version_parts <- strsplit(gsub("Python ", "", version_str), "\\.")[[1]]
      major <- as.numeric(version_parts[1])
      minor <- as.numeric(version_parts[2])

      python_status <- (major == 3 && minor >= 9 && minor <= 12)
      print_status("Python", python_status, version_str)

      if (!python_status) {
        packageStartupMessage("\nPython version not compatible. Please install Python 3.9-3.12")
        return(invisible(NULL))
      }
    }

    # Check Flair installation
    cmd <- sprintf('"%s" -c "import flair; print(flair.__version__)"', python_path)
    flair_version <- tryCatch({
      system(cmd, intern = TRUE)[1]
    }, error = function(e) NULL)

    if (is.null(flair_version)) {
      print_status("Flair NLP", FALSE, "Not installed")
      if (!is_docker) {
        packageStartupMessage("\nUse install_flair() to install Flair NLP")
      } else {
        packageStartupMessage("\nPlease ensure Flair is installed in your Docker image")
      }
    } else {
      print_status("Flair NLP", TRUE, paste("version", flair_version))
      packageStartupMessage(sprintf(
        "\n\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP %s\033[39m\033[22m",
        flair_version
      ))
    }

  }, error = function(e) {
    print_status("Environment", FALSE, paste("Error:", e$message))
  })

  invisible(NULL)
}
#
# .onAttach <- function(...) {
#   # 1. Check if running in Docker (safe check for all platforms)
#   check_if_docker <- function() {
#     tryCatch({
#       if (file.exists("/.dockerenv")) {
#         return(TRUE)
#       }
#       return(FALSE)
#     }, error = function(e) {
#       return(FALSE)
#     })
#   }
#
#   is_docker <- check_if_docker()
#
#   # 2. Configure basic settings and suppress warnings
#   suppressWarnings({
#     options(reticulate.prompt = FALSE)
#     if (Sys.info()["sysname"] == "Darwin") {
#       Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
#     }
#   })
#
#   # 3. Status printing utility with colored output
#   print_status <- function(component, version, status = TRUE, extra_message = NULL) {
#     if (status) {
#       symbol <- "\u2713"  # checkmark
#       color <- "\033[32m" # green
#     } else {
#       symbol <- "\u2717"  # x mark
#       color <- "\033[31m" # red
#     }
#
#     formatted_component <- switch(component,
#                                   "Python" = sprintf("Python%-15s", ""),
#                                   "flaiR" = sprintf("Flair NLP%-12s", ""),
#                                   component
#     )
#
#     message <- sprintf("%s %s%s\033[39m  %s",
#                        formatted_component,
#                        color,
#                        symbol,
#                        if(!is.null(version)) version else "")
#
#     packageStartupMessage(message)
#     if (!is.null(extra_message)) {
#       packageStartupMessage(extra_message)
#     }
#   }
#
#   # Main execution block
#   tryCatch({
#     if (is_docker) {
#       # In Docker environment, just use the pre-configured Python
#       python_path <- Sys.getenv("RETICULATE_PYTHON")
#       if (python_path != "") {
#         suppressWarnings({
#           reticulate::use_python(python_path, required = TRUE)
#         })
#       }
#     } else {
#       # Local environment setup
#       home_dir <- path.expand("~")
#       venv <- file.path(home_dir, "flair_env")
#
#       if (!reticulate::virtualenv_exists(venv)) {
#         suppressWarnings({
#           reticulate::virtualenv_create(venv)
#         })
#       }
#       suppressWarnings({
#         reticulate::use_virtualenv(venv, required = TRUE)
#       })
#     }
#
#     # Version checks
#     py_config <- reticulate::py_config()
#     version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
#     major <- as.numeric(version_parts[1])
#     minor <- as.numeric(version_parts[2])
#
#     # Python version check
#     python_status <- (major == 3 && minor >= 9 && minor <= 12)
#     print_status("Python", paste(major, minor, sep = "."), python_status)
#
#     if (python_status) {
#       # Check flair
#       flair_check <- tryCatch({
#         flair <- reticulate::import("flair", delay_load = TRUE)
#         version <- reticulate::py_get_attr(flair, "__version__")
#         list(status = TRUE, version = version)
#       }, error = function(e) {
#         list(status = FALSE, version = NULL)
#       })
#
#       # Only attempt installation in non-Docker environment
#       if (!flair_check$status && !is_docker) {
#         suppressWarnings({
#           reticulate::py_install(
#             packages = c(
#               "numpy==1.26.4",
#               "scipy==1.12.0",
#               "flair[word-embeddings]>=0.11.3"
#             ),
#             pip = TRUE,
#             method = "auto"
#           )
#         })
#         # Recheck flair after installation
#         flair_check <- tryCatch({
#           flair <- reticulate::import("flair", delay_load = TRUE)
#           version <- reticulate::py_get_attr(flair, "__version__")
#           list(status = TRUE, version = version)
#         }, error = function(e) {
#           list(status = FALSE, version = NULL)
#         })
#       }
#
#       print_status("flaiR", flair_check$version, flair_check$status)
#
#       if (flair_check$status) {
#         packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP %s\033[39m\033[22m",
#                                       flair_check$version))
#       }
#     }
#   }, error = function(e) {
#     packageStartupMessage("Error during initialization: ", e$message)
#   })
#
#   invisible(NULL)
# }

# .onAttach <- function(...) {
#   # 1. Initialize environment paths
#   # Set up the home directory and virtual environment path
#   home_dir <- path.expand("~")
#   venv <- file.path(home_dir, "flair_env")
#
#   # 2. Configure basic settings and suppress warnings
#   suppressWarnings({
#     options(reticulate.prompt = FALSE)
#     if (Sys.info()["sysname"] == "Darwin") {
#       Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
#     }
#   })
#
#   # 3. Python version compatibility check
#   check_python_version <- function() {
#     tryCatch({
#       py_config <- reticulate::py_config()
#       version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
#       major <- as.numeric(version_parts[1])
#       minor <- as.numeric(version_parts[2])
#
#       # Verify Python version is between 3.8-3.12 for PyTorch compatibility
#       status <- (major == 3 && minor >= 9 && minor <= 12)
#
#       if (!status) {
#         message <- paste0(
#           "\n",
#           "Warning: Python version ", major, ".", minor, " may cause compatibility issues.\n",
#           "Recommended Python versions for PyTorch 2.0+ and Flair NLP: 3.8-3.12\n",
#           "\n",
#           "To install compatible Python version:\n",
#           "1. install.packages('reticulate')\n",
#           "2. library(reticulate)\n",
#           "3. install_python(version = '3.10')\n"
#         )
#         return(list(
#           status = FALSE,
#           version = paste(major, minor, sep = "."),
#           message = message
#         ))
#       }
#
#       return(list(
#         status = TRUE,
#         version = paste(major, minor, sep = "."),
#         message = NULL
#       ))
#     }, error = function(e) {
#       return(list(
#         status = FALSE,
#         version = "unknown",
#         message = "Could not detect Python version"
#       ))
#     })
#   }
#
#   # 4. Check flair version and installation status
#   check_flair_version <- function() {
#     tryCatch({
#       flair <- reticulate::import("flair", delay_load = TRUE)
#       version <- reticulate::py_get_attr(flair, "__version__")
#       return(list(
#         status = TRUE,
#         version = version,
#         message = NULL
#       ))
#     }, error = function(e) {
#       return(list(
#         status = FALSE,
#         version = NULL,
#         message = "Failed to load flair"
#       ))
#     })
#   }
#
#   # 5. Status printing utility with colored output
#   print_status <- function(component, version, status = TRUE, extra_message = NULL) {
#     if (status) {
#       symbol <- "\u2713"  # checkmark
#       color <- "\033[32m" # green
#     } else {
#       symbol <- "\u2717"  # x mark
#       color <- "\033[31m" # red
#     }
#
#     # Standardize component names and padding
#     formatted_component <- switch(component,
#                                   "Python" = sprintf("Python%-15s", ""),
#                                   "flaiR" = sprintf("Flair NLP%-12s", ""),
#                                   component
#     )
#
#     message <- sprintf("%s %s%s\033[39m  %s", # 增加一個空格在 checkmark 後面
#                        formatted_component,
#                        color,
#                        symbol,
#                        if(!is.null(version)) version else "")
#
#     packageStartupMessage(message)
#     if (!is.null(extra_message)) {
#       packageStartupMessage(extra_message)
#     }
#   }
#
#   # 6. Main execution block
#   tryCatch({
#     # Initialize or verify virtual environment
#     if (!reticulate::virtualenv_exists(venv)) {
#       suppressWarnings({
#         reticulate::virtualenv_create(venv)
#       })
#     }
#
#     # Activate the virtual environment
#     suppressWarnings({
#       reticulate::use_virtualenv(venv, required = TRUE)
#     })
#
#     # Verify Python version compatibility
#     python_check <- check_python_version()
#     print_status("Python", python_check$version, python_check$status, python_check$message)
#
#     # Install and configure flair if Python version is compatible
#     if (python_check$status) {
#       flair_check <- check_flair_version()
#       if (!flair_check$status) {
#         suppressWarnings({
#           # First install numpy with specific version for scipy compatibility
#           reticulate::py_install(
#             packages = c("numpy>=1.22.4,<1.29.0"),
#             envname = venv,
#             pip = TRUE,
#             method = "auto"
#           )
#
#           # Then install flair and dependencies
#           reticulate::py_install(
#             packages = c(
#               "scipy==1.12.0",
#               "flair[word-embeddings]>=0.11.3"
#             ),
#             envname = venv,
#             pip = TRUE,
#             method = "auto"
#           )
#         })
#         flair_check <- check_flair_version()
#       } else {
#         # Check and install word-embeddings if needed
#         tryCatch({
#           reticulate::import("bpemb")
#         }, error = function(e) {
#           suppressWarnings({
#             reticulate::py_install(
#               packages = "flair[word-embeddings]",
#               envname = venv,
#               pip = TRUE,
#               method = "auto"
#             )
#           })
#         })
#       }
#
#       # Display final status
#       print_status("flaiR", flair_check$version, flair_check$status, flair_check$message)
#
#       if (flair_check$status) {
#         packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP %s\033[39m\033[22m",
#                                       flair_check$version))
#       }
#     }
#
#   }, error = function(e) {
#     packageStartupMessage("Error during initialization: ", e$message)
#   })
#
#   invisible(NULL)
# }

# .onAttach <- function(...) {
#   # Prevent reticulate from asking about Python environment
#   options(reticulate.prompt = TRUE)
#   # suppressWarnings({
#   #   options(reticulate.prompt = FALSE)
#   # })
#   # Set OpenMP environment variable for Mac systems
#   if (Sys.info()["sysname"] == "Darwin") {
#     current_value <- Sys.getenv("KMP_DUPLICATE_LIB_OK")
#     if (current_value == "") {
#       Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
#       packageStartupMessage("Set KMP_DUPLICATE_LIB_OK=TRUE to handle OpenMP runtime conflicts")
#     }
#   }
#
#   # Check and set Python environment
#   home_dir <- path.expand("~")
#   venv <- file.path(home_dir, "flair_env")
#
#   # Define version check function
#   check_flair_version <- function() {
#     tryCatch({
#       flair <- reticulate::import("flair", delay_load = TRUE)
#       version <- reticulate::py_get_attr(flair, "__version__")
#       return(list(
#         message = paste("flair", paste0("\033[32m", "\u2713", "\033[39m"), version, sep = " "),
#         status = TRUE,
#         version = version
#       ))
#     }, error = function(e) {
#       return(list(
#         message = paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "),
#         status = FALSE,
#         version = NULL
#       ))
#     })
#   }
#
#   # Check if in Docker environment
#   in_docker <- file.exists("/.dockerenv")
#
#   if (in_docker) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON")
#     if (docker_python != "" && file.exists(docker_python)) {
#       packageStartupMessage("Using Docker Python environment: ", docker_python)
#       tryCatch({
#         reticulate::use_python(docker_python, required = TRUE)
#         flair_status <- suppressMessages(check_flair_version())
#         if (flair_status$status) {
#           packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                         paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#         }
#       }, error = function(e) {
#         packageStartupMessage("Failed to initialize Docker Python environment: ", e$message)
#       })
#       return(invisible(NULL))
#     }
#   } else {
#     # Get Python path for local environment
#     python_path <- tryCatch({
#       if (Sys.info()["sysname"] == "Windows") {
#         file.path(venv, "Scripts", "python.exe")
#       } else {
#         file.path(venv, "bin", "python")
#       }
#     }, error = function(e) {
#       packageStartupMessage("Cannot locate Python in virtual environment.")
#       return(invisible(NULL))
#     })
#
#     # Check if virtual environment exists
#     if (reticulate::virtualenv_exists(venv)) {
#       packageStartupMessage("Using created virtual environment: ", venv)
#       tryCatch({
#         reticulate::use_virtualenv(venv, required = TRUE)
#
#         # Check flair in existing environment
#         flair_status <- suppressMessages(check_flair_version())
#         if (!flair_status$status) {
#           packageStartupMessage("Installing missing flair and dependencies in existing environment...")
#           reticulate::py_install(
#             packages = c(
#               "numpy>=1.26.4",
#               "torch>=2.0.0",
#               "transformers>=4.30.0",
#               "flair>=0.11.3",
#               "scipy==1.12.0",
#               "sentencepiece>=0.1.99"
#             ),
#             envname = venv,
#             pip = TRUE,
#             method = "auto")
#           flair_status <- suppressMessages(check_flair_version())
#         }
#
#         if (flair_status$status) {
#           packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                         paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#         }
#       }, error = function(e) {
#         packageStartupMessage("Error in virtual environment setup: ", e$message)
#       })
#     } else {
#       # Create new virtual environment
#       packageStartupMessage("Creating virtual environment: ", venv)
#       tryCatch({
#         reticulate::virtualenv_create(venv)
#         reticulate::use_virtualenv(venv, required = TRUE)
#
#         packageStartupMessage("Installing flair NLP and dependencies in new environment...")
#         reticulate::py_install(
#           packages = c(
#             "torch>=2.0.0",
#             "transformers>=4.30.0",
#             "flair>=0.11.3",
#             "scipy==1.12.0",
#             "sentencepiece>=0.1.99"
#           ),
#           envname = venv,
#           pip = TRUE,
#           method = "auto")
#
#         flair_status <- suppressMessages(check_flair_version())
#         if (flair_status$status) {
#           packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                         paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#         }
#       }, error = function(e) {
#         packageStartupMessage("Failed to create virtual environment: ", e$message)
#       })
#     }
#   }
#
#   # If we get here and flair_status doesn't exist, something went wrong
#   if (!exists("flair_status") || !flair_status$status) {
#     packageStartupMessage("Failed to load flair. Please install manually.")
#     return(invisible(NULL))
#   }
# }
#


# .onAttach <- function(...) {
#   # Prevent reticulate from asking about Python environment
#   options(reticulate.prompt = FALSE)
#
#   # Check and set Python environment
#   home_dir <- path.expand("~")
#   venv <- file.path(home_dir, "flair_env")
#
#   # Define version check function
#   check_flair_version <- function() {
#     tryCatch({
#       flair <- reticulate::import("flair", delay_load = TRUE)
#       version <- reticulate::py_get_attr(flair, "__version__")
#       return(list(
#         message = paste("flair", paste0("\033[32m", "\u2713", "\033[39m"), version, sep = " "),
#         status = TRUE,
#         version = version
#       ))
#     }, error = function(e) {
#       return(list(
#         message = paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "),
#         status = FALSE,
#         version = NULL
#       ))
#     })
#   }
#
#   # Check if in Docker environment
#   in_docker <- file.exists("/.dockerenv")
#
#   if (in_docker) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON")
#     if (docker_python != "" && file.exists(docker_python)) {
#       packageStartupMessage("Using Docker Python environment: ", docker_python)
#       tryCatch({
#         reticulate::use_python(docker_python, required = TRUE)
#         flair_status <- suppressMessages(check_flair_version())
#         if (flair_status$status) {
#           packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                         paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#         }
#       }, error = function(e) {
#         packageStartupMessage("Failed to initialize Docker Python environment: ", e$message)
#       })
#       return(invisible(NULL))
#     }
#   } else {
#     # Get Python path for local environment
#     python_path <- tryCatch({
#       if (Sys.info()["sysname"] == "Windows") {
#         file.path(venv, "Scripts", "python.exe")
#       } else {
#         file.path(venv, "bin", "python")
#       }
#     }, error = function(e) {
#       packageStartupMessage("Cannot locate Python in virtual environment.")
#       return(invisible(NULL))
#     })
#
#     # Check if virtual environment exists
#     if (reticulate::virtualenv_exists(venv)) {
#       packageStartupMessage("Using existing virtual environment: ", venv)
#       tryCatch({
#         reticulate::use_virtualenv(venv, required = TRUE)
#
#         # Check flair in existing environment
#         flair_status <- suppressMessages(check_flair_version())
#         if (!flair_status$status) {
#           packageStartupMessage("Installing missing flair in existing environment...")
#           reticulate::py_install(c("torch", "flair", "scipy==1.12.0"),
#                                  envname = venv,
#                                  pip = TRUE,
#                                  method = "auto")
#           flair_status <- suppressMessages(check_flair_version())
#         }
#
#         if (flair_status$status) {
#           packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                         paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#         }
#       }, error = function(e) {
#         packageStartupMessage("Error in virtual environment setup: ", e$message)
#       })
#     } else {
#       # Create new virtual environment
#       packageStartupMessage("Creating new virtual environment: ", venv)
#       tryCatch({
#         reticulate::virtualenv_create(venv)
#         reticulate::use_virtualenv(venv, required = TRUE)
#
#         packageStartupMessage("Installing flair NLP in new environment...")
#         reticulate::py_install(c("torch", "flair", "scipy==1.12.0"),
#                                envname = venv,
#                                pip = TRUE,
#                                method = "auto")
#
#         flair_status <- suppressMessages(check_flair_version())
#         if (flair_status$status) {
#           packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                         paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#         }
#       }, error = function(e) {
#         packageStartupMessage("Failed to create virtual environment: ", e$message)
#       })
#     }
#   }
#
#   # If we get here and flair_status doesn't exist, something went wrong
#   if (!exists("flair_status") || !flair_status$status) {
#     packageStartupMessage("Failed to load flair. Please install manually.")
#     return(invisible(NULL))
#   }
# }






# .onAttach <- function(...) {
#   # Check and set Python environment
#   # Sys.unsetenv("RETICULATE_PYTHON")
#   home_dir <- path.expand("~")
#   venv <- file.path(home_dir, "flair_env")
#
#   # check docker env
#   in_docker <- file.exists("/.dockerenv")
#
#   # bring it to docker
#   if (in_docker) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON")
#     if (docker_python != "" && file.exists(docker_python)) {
#       packageStartupMessage("Using Docker Python environment: ", docker_python)
#       Sys.setenv(RETICULATE_PYTHON = docker_python)
#       reticulate::use_python(docker_python, required = TRUE)
#       return(invisible(NULL))
#     }
#   }
#
#   # Get Python path from virtual environment
#   python_path <- tryCatch({
#     if (Sys.info()["sysname"] == "Windows") {
#       file.path(venv, "Scripts", "python.exe")
#     } else {
#       file.path(venv, "bin", "python")
#     }
#   }, error = function(e) {
#     packageStartupMessage("Cannot locate Python in virtual environment.")
#     return(invisible(NULL))
#   })
#
#   # Define version check function
#   check_flair_version <- function() {
#     tryCatch({
#       reticulate::use_virtualenv(venv, required = TRUE)
#       flair <- reticulate::import("flair", delay_load = TRUE)
#       version <- reticulate::py_get_attr(flair, "__version__")
#       return(list(
#         message = paste("flair", paste0("\033[32m", "\u2713", "\033[39m"), version, sep = " "),
#         status = TRUE,
#         version = version
#       ))
#     }, error = function(e) {
#       return(list(
#         message = paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "),
#         status = FALSE,
#         version = NULL
#       ))
#     })
#   }
#
#   # Initialize Python environment (only if not in Docker)
#   if (!in_docker) {
#     Sys.setenv(RETICULATE_PYTHON = python_path)
#
#     # Check if flair_env exists
#     if (reticulate::virtualenv_exists(venv)) {
#       packageStartupMessage("Using existing virtual environment: ", venv)
#       reticulate::use_virtualenv(venv, required = TRUE)
#
#       # Check flair in existing environment
#       flair_status <- suppressMessages(check_flair_version())
#       if (!flair_status$status) {
#         packageStartupMessage("Installing missing flair in existing environment...")
#         tryCatch({
#           reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
#         }, error = function(e) {
#           packageStartupMessage("Failed to install flair: ", e$message)
#           return(invisible(NULL))
#         })
#         flair_status <- suppressMessages(check_flair_version())
#       }
#     } else {
#       # Create new virtual environment
#       packageStartupMessage("Creating new virtual environment: ", venv)
#       reticulate::virtualenv_create(venv)
#       reticulate::use_virtualenv(venv, required = TRUE)
#
#       # Install in new environment
#       packageStartupMessage("Installing flair NLP in new environment...")
#       tryCatch({
#         reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
#       }, error = function(e) {
#         packageStartupMessage("Failed to install flair: ", e$message)
#         return(invisible(NULL))
#       })
#       flair_status <- suppressMessages(check_flair_version())
#     }
#
#     # Display final status
#     if (flair_status$status) {
#       packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                     paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#     } else {
#       packageStartupMessage("Failed to load flair. Please install manually.")
#     }
#   }
# }

#
# .onAttach <- function(...) {
#   # Check and set Python environment
#   Sys.unsetenv("RETICULATE_PYTHON")
#   home_dir <- path.expand("~")
#   venv <- file.path(home_dir, "flair_env")
#
#   # Get Python path from virtual environment
#   python_path <- tryCatch({
#     if (Sys.info()["sysname"] == "Windows") {
#       file.path(venv, "Scripts", "python.exe")
#     } else {
#       file.path(venv, "bin", "python")
#     }
#   }, error = function(e) {
#     packageStartupMessage("Cannot locate Python in virtual environment.")
#     return(invisible(NULL))
#   })
#
#   # Define version check function
#   check_flair_version <- function() {
#     tryCatch({
#       reticulate::use_virtualenv(venv, required = TRUE)
#       flair <- reticulate::import("flair", delay_load = TRUE)
#       version <- reticulate::py_get_attr(flair, "__version__")
#       return(list(
#         message = paste("flair", paste0("\033[32m", "\u2713", "\033[39m"), version, sep = " "),
#         status = TRUE,
#         version = version
#       ))
#     }, error = function(e) {
#       return(list(
#         message = paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "),
#         status = FALSE,
#         version = NULL
#       ))
#     })
#   }
#
#   # Initialize Python environment
#   Sys.setenv(RETICULATE_PYTHON = python_path)
#
#   # Check if flair_env exists
#   if (reticulate::virtualenv_exists(venv)) {
#     packageStartupMessage("Using existing virtual environment: ", venv)
#     reticulate::use_virtualenv(venv, required = TRUE)
#
#     # Check flair in existing environment
#     flair_status <- suppressMessages(check_flair_version())
#     if (!flair_status$status) {
#       packageStartupMessage("Installing missing flair in existing environment...")
#       tryCatch({
#         reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
#       }, error = function(e) {
#         packageStartupMessage("Failed to install flair: ", e$message)
#         return(invisible(NULL))
#       })
#       flair_status <- suppressMessages(check_flair_version())
#     }
#   } else {
#     # Create new virtual environment
#     packageStartupMessage("Creating new virtual environment: ", venv)
#     reticulate::virtualenv_create(venv)
#     reticulate::use_virtualenv(venv, required = TRUE)
#
#     # Install in new environment
#     packageStartupMessage("Installing flair NLP in new environment...")
#     tryCatch({
#       reticulate::py_install(c("torch", "flair", "scipy==1.12.0"), envname = venv)
#     }, error = function(e) {
#       packageStartupMessage("Failed to install flair: ", e$message)
#       return(invisible(NULL))
#     })
#     flair_status <- suppressMessages(check_flair_version())
#   }
#
#   # Display final status
#   if (flair_status$status) {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
#                                   paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
#   } else {
#     packageStartupMessage("Failed to load flair. Please install manually.")
#   }
# }
