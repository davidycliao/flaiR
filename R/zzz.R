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
  # Check if running in Docker (safe check for all platforms)
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

  # Configure basic settings and suppress warnings
  suppressWarnings({
    options(reticulate.prompt = FALSE)
    if (Sys.info()["sysname"] == "Darwin") {
      Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
    }
  })

  # Status printing utility with colored output
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
        suppressWarnings({
          reticulate::use_python(python_path, required = TRUE)
        })
      }
    } else {
      # Local environment setup
      home_dir <- path.expand("~")
      venv <- file.path(home_dir, "flair_env")

      if (!reticulate::virtualenv_exists(venv)) {
        suppressWarnings({
          reticulate::virtualenv_create(venv)
        })
      }
      suppressWarnings({
        reticulate::use_virtualenv(venv, required = TRUE)
      })
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
        suppressWarnings({
          reticulate::py_install(
            packages = c(
              "numpy==1.26.4",
              "scipy==1.12.0",
              "flair[word-embeddings]>=0.11.3"
            ),
            pip = TRUE,
            method = "auto"
          )
        })
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
