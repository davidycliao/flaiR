#' @name flaiR-package
#' @title Initialize Python Environment for flaiR NLP Package
#' @description Initializes Python environment and sets up flair NLP with a visual progress display.
#'
#' @section Progress Stages:
#' The initialization process is displayed with a progress bar showing three main stages:
#' \enumerate{
#'   \item Setting up Python environment
#'   \item Installing dependencies
#'   \item Initializing Flair NLP
#' }
#'
#' @section Python Requirements:
#' \itemize{
#'   \item Python version 3.9-3.12
#'   \item Key dependencies:
#'     \itemize{
#'       \item numpy (1.26.4)
#'       \item scipy (1.12.0)
#'       \item flair (>=0.11.3)
#'     }
#' }
#'
#' @section Status Display:
#' The package provides visual feedback during initialization:
#' \preformatted{
#' [==========>              ] Setting up Python environment...
#' [====================>    ] Installing dependencies...
#' [==============================>] Initializing Flair NLP...
#' Ready!
#' }
#'
#' @note
#' The package automatically detects and uses the appropriate Python installation.
#' If initialization fails, please ensure you have a compatible Python version installed
#' and restart your R session.
#'
#' @importFrom reticulate use_python py_config import py_get_attr py_install
"_PACKAGE"

.onLoad <- function(libname, pkgname) {
  # Try to detect and use the flair_env Python if it exists
  flair_env_python <- file.path(path.expand("~"), "flair_env", "bin", "python")

  if (file.exists(flair_env_python)) {
    Sys.setenv(RETICULATE_PYTHON = flair_env_python)
    options(reticulate.python = flair_env_python)
  }
}

.onAttach <- function(libname, pkgname) {
  # Progress bar styling function
  show_progress <- function(stage, length = 40) {
    progress_char <- "="
    arrow <- ">"
    empty_char <- " "

    stages <- list(
      "python" = list(progress = 10, message = "Setting up Python environment..."),
      "deps" = list(progress = 20, message = "Installing dependencies..."),
      "flair" = list(progress = 30, message = "Initializing Flair NLP...")
    )

    current <- stages[[stage]]
    filled <- paste(rep(progress_char, current$progress), collapse = "")
    remaining <- paste(rep(empty_char, length - current$progress), collapse = "")
    bar <- sprintf("[%s%s%s] %s", filled, arrow, remaining, current$message)

    packageStartupMessage(bar)
  }

  # Initialize Python
  tryCatch({
    show_progress("python")

    # Basic settings
    options(reticulate.prompt = FALSE)
    if (Sys.info()["sysname"] == "Darwin") {
      Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
    }

    # Check Python version
    py_config <- reticulate::py_config()
    version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
    major <- as.numeric(version_parts[1])
    minor <- as.numeric(version_parts[2])

    if (!(major == 3 && minor >= 9 && minor <= 12)) {
      stop("Incompatible Python version. Python 3.9-3.12 required")
    }

    # Install dependencies
    show_progress("deps")
    flair_check <- tryCatch({
      flair <- reticulate::import("flair", delay_load = TRUE)
      version <- reticulate::py_get_attr(flair, "__version__")
      list(status = TRUE, version = version)
    }, error = function(e) {
      list(status = FALSE, version = NULL)
    })

    if (!flair_check$status) {
      reticulate::py_install(
        packages = c(
          "numpy==1.26.4",
          "scipy==1.12.0",
          "flair[word-embeddings]>=0.11.3"
        ),
        pip = TRUE,
        method = "auto"
      )
    }

    # Initialize Flair
    show_progress("flair")
    flair_check <- tryCatch({
      flair <- reticulate::import("flair", delay_load = TRUE)
      version <- reticulate::py_get_attr(flair, "__version__")
      list(status = TRUE, version = version)
    }, error = function(e) {
      list(status = FALSE, version = NULL)
    })

    if (!flair_check$status) {
      stop("Failed to initialize Flair")
    }

    # Show ready message
    packageStartupMessage("Ready!")

  }, error = function(e) {
    packageStartupMessage("\nError: ", e$message)
    return(invisible(NULL))
  })

  invisible(NULL)
}
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
#   # 2. Configure basic settings
#   options(reticulate.prompt = FALSE)
#   if (Sys.info()["sysname"] == "Darwin") {
#     Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
#   }
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
#         reticulate::use_python(python_path, required = TRUE)
#       }
#     } else {
#       # Local environment setup
#       home_dir <- path.expand("~")
#       venv <- file.path(home_dir, "flair_env")
#
#       if (!reticulate::virtualenv_exists(venv)) {
#         reticulate::virtualenv_create(venv)
#       }
#       reticulate::use_virtualenv(venv, required = TRUE)
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
#         reticulate::py_install(
#           packages = c(
#             "numpy==1.26.4",
#             "scipy==1.12.0",
#             "flair[word-embeddings]>=0.11.3"
#           ),
#           pip = TRUE,
#           method = "auto"
#         )
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
