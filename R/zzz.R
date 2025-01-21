#' @title Initialize Python Environment and Load flaiR NLP
#' @description Sets up Python environment, manages virtual environment, and installs required flair NLP packages.
#'
#' @param ... Additional arguments passed to startup functions
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Clears any existing Python environment variables
#'   \item Detects Python installation based on operating system (Windows/Unix)
#'   \item Manages 'flair_env' virtual environment:
#'     - Uses existing environment if available
#'     - Creates new environment if needed
#'   \item Verifies and installs required packages:
#'     - torch
#'     - flair
#'     - scipy (version 1.12.0)
#'   \item Validates flair installation and displays version information
#' }
#'
#' The function includes comprehensive error handling and provides status messages
#' throughout the initialization process.
#'
#' @note
#' Requires Python 3.x installed on the system. Will create a virtual environment
#' named 'flair_env' if it doesn't exist.
#'
#' @importFrom reticulate virtualenv_exists virtualenv_create use_virtualenv py_install
#' @keywords internal
.onAttach <- function(...) {
  # 1. Check if running in Docker (safe check for all platforms)
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

  # 2. Configure basic settings
  options(reticulate.prompt = FALSE)
  if (Sys.info()["sysname"] == "Darwin") {
    Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
  }

  # 3. Status printing utility with colored output
  print_status <- function(component, version, status = TRUE, extra_message = NULL) {
    if (status) {
      symbol <- "\u2713"  # checkmark
      color <- "\033[32m" # green
    } else {
      symbol <- "\u2717"  # x mark
      color <- "\033[31m" # red
    }

    formatted_component <- switch(component,
                                  "Python" = sprintf("Python%-15s", ""),
                                  "flaiR" = sprintf("Flair NLP%-12s", ""),
                                  component
    )

    message <- sprintf("%s %s%s\033[39m  %s",
                       formatted_component,
                       color,
                       symbol,
                       if(!is.null(version)) version else "")

    packageStartupMessage(message)
    if (!is.null(extra_message)) {
      packageStartupMessage(extra_message)
    }
  }

  # Main execution block
  tryCatch({
    if (is_docker) {
      # In Docker environment, just use the pre-configured Python
      python_path <- Sys.getenv("RETICULATE_PYTHON")
      if (python_path != "") {
        reticulate::use_python(python_path, required = TRUE)
      }
    } else {
      # Local environment setup
      home_dir <- path.expand("~")
      venv <- file.path(home_dir, "flair_env")

      if (!reticulate::virtualenv_exists(venv)) {
        reticulate::virtualenv_create(venv)
      }
      reticulate::use_virtualenv(venv, required = TRUE)
    }

    # Version checks
    py_config <- reticulate::py_config()
    version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
    major <- as.numeric(version_parts[1])
    minor <- as.numeric(version_parts[2])

    # Python version check
    python_status <- (major == 3 && minor >= 9 && minor <= 12)
    print_status("Python", paste(major, minor, sep = "."), python_status)

    if (python_status) {
      # Check flair
      flair_check <- tryCatch({
        flair <- reticulate::import("flair", delay_load = TRUE)
        version <- reticulate::py_get_attr(flair, "__version__")
        list(status = TRUE, version = version)
      }, error = function(e) {
        list(status = FALSE, version = NULL)
      })

      # Only attempt installation in non-Docker environment
      if (!flair_check$status && !is_docker) {
        reticulate::py_install(
          packages = c(
            "numpy==1.26.4",
            "scipy==1.12.0",
            "flair[word-embeddings]>=0.11.3"
          ),
          pip = TRUE,
          method = "auto"
        )
        # Recheck flair after installation
        flair_check <- tryCatch({
          flair <- reticulate::import("flair", delay_load = TRUE)
          version <- reticulate::py_get_attr(flair, "__version__")
          list(status = TRUE, version = version)
        }, error = function(e) {
          list(status = FALSE, version = NULL)
        })
      }

      print_status("flaiR", flair_check$version, flair_check$status)

      if (flair_check$status) {
        packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP %s\033[39m\033[22m",
                                      flair_check$version))
      }
    }
  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", e$message)
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
