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
#'
.onAttach <- function(...) {
  # Prevent reticulate from asking about Python environment
  options(reticulate.prompt = FALSE)

  # Check and set Python environment
  home_dir <- path.expand("~")
  venv <- file.path(home_dir, "flair_env")

  # Define version check function
  check_flair_version <- function() {
    tryCatch({
      flair <- reticulate::import("flair", delay_load = TRUE)
      version <- reticulate::py_get_attr(flair, "__version__")
      return(list(
        message = paste("flair", paste0("\033[32m", "\u2713", "\033[39m"), version, sep = " "),
        status = TRUE,
        version = version
      ))
    }, error = function(e) {
      return(list(
        message = paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "),
        status = FALSE,
        version = NULL
      ))
    })
  }

  # Check if in Docker environment
  in_docker <- file.exists("/.dockerenv")

  if (in_docker) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON")
    if (docker_python != "" && file.exists(docker_python)) {
      packageStartupMessage("Using Docker Python environment: ", docker_python)
      tryCatch({
        reticulate::use_python(docker_python, required = TRUE)
        flair_status <- suppressMessages(check_flair_version())
        if (flair_status$status) {
          packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
                                        paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
        }
      }, error = function(e) {
        packageStartupMessage("Failed to initialize Docker Python environment: ", e$message)
      })
      return(invisible(NULL))
    }
  } else {
    # Get Python path for local environment
    python_path <- tryCatch({
      if (Sys.info()["sysname"] == "Windows") {
        file.path(venv, "Scripts", "python.exe")
      } else {
        file.path(venv, "bin", "python")
      }
    }, error = function(e) {
      packageStartupMessage("Cannot locate Python in virtual environment.")
      return(invisible(NULL))
    })

    # Check if virtual environment exists
    if (reticulate::virtualenv_exists(venv)) {
      packageStartupMessage("Using existing virtual environment: ", venv)
      tryCatch({
        reticulate::use_virtualenv(venv, required = TRUE)

        # Check flair in existing environment
        flair_status <- suppressMessages(check_flair_version())
        if (!flair_status$status) {
          packageStartupMessage("Installing missing flair in existing environment...")
          reticulate::py_install(c("torch", "flair", "scipy==1.12.0"),
                                 envname = venv,
                                 pip = TRUE,
                                 method = "auto")
          flair_status <- suppressMessages(check_flair_version())
        }

        if (flair_status$status) {
          packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
                                        paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
        }
      }, error = function(e) {
        packageStartupMessage("Error in virtual environment setup: ", e$message)
      })
    } else {
      # Create new virtual environment
      packageStartupMessage("Creating new virtual environment: ", venv)
      tryCatch({
        reticulate::virtualenv_create(venv)
        reticulate::use_virtualenv(venv, required = TRUE)

        packageStartupMessage("Installing flair NLP in new environment...")
        reticulate::py_install(c("torch", "flair", "scipy==1.12.0"),
                               envname = venv,
                               pip = TRUE,
                               method = "auto")

        flair_status <- suppressMessages(check_flair_version())
        if (flair_status$status) {
          packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s",
                                        paste("\033[1m\033[33m", flair_status$version, "\033[39m\033[22m", sep = "")))
        }
      }, error = function(e) {
        packageStartupMessage("Failed to create virtual environment: ", e$message)
      })
    }
  }

  # If we get here and flair_status doesn't exist, something went wrong
  if (!exists("flair_status") || !flair_status$status) {
    packageStartupMessage("Failed to load flair. Please install manually.")
    return(invisible(NULL))
  }
}

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
