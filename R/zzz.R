

# Constants for version management
.PACKAGE_CONSTANTS <- new.env()
assign("PYTHON_MIN_VERSION", "3.9", envir = .PACKAGE_CONSTANTS)
assign("PYTHON_MAX_VERSION", "3.12", envir = .PACKAGE_CONSTANTS)
assign("NUMPY_VERSION", "1.26.4", envir = .PACKAGE_CONSTANTS)
assign("SCIPY_VERSION", "1.12.0", envir = .PACKAGE_CONSTANTS)
assign("FLAIR_MIN_VERSION", "0.11.3", envir = .PACKAGE_CONSTANTS)

# ANSI color codes for status messages
.COLORS <- list(
  GREEN = "\033[32m",
  RED = "\033[31m",
  BLUE = "\033[34m",
  YELLOW = "\033[33m",
  RESET = "\033[39m",
  BOLD = "\033[1m",
  RESET_BOLD = "\033[22m"
)

.onAttach <- function(...) {
  # 1. Enhanced Docker environment detection
  check_if_docker <- function() {
    docker_indicators <- c(
      "/.dockerenv",
      "/proc/1/cgroup"  # Additional check for Linux systems
    )
    tryCatch({
      any(sapply(docker_indicators, file.exists))
    }, error = function(e) {
      FALSE
    })
  }

  # 2. Status message utilities
  get_status_color <- function(status) {
    if (status) .COLORS$GREEN else .COLORS$RED
  }

  get_status_symbol <- function(status) {
    if (status) "\u2713" else "\u2717"
  }

  print_status <- function(component, version, status = TRUE, extra_message = NULL) {
    formatted_component <- switch(component,
                                  "Python" = sprintf("Python%-15s", ""),
                                  "flaiR" = sprintf("Flair NLP%-12s", ""),
                                  component
    )

    message <- sprintf("%s %s%s%s  %s",
                       formatted_component,
                       get_status_color(status),
                       get_status_symbol(status),
                       .COLORS$RESET,
                       if(!is.null(version)) version else ""
    )

    packageStartupMessage(message)
    if (!is.null(extra_message)) {
      packageStartupMessage(extra_message)
    }
  }

  # 3. Version comparison utility
  check_version_range <- function(version, min_version, max_version) {
    tryCatch({
      version <- numeric_version(version)
      min_version <- numeric_version(min_version)
      max_version <- numeric_version(max_version)
      version >= min_version && version <= max_version
    }, error = function(e) {
      FALSE
    })
  }

  # 4. Check RStudio Python environment
  check_rstudio_python <- function() {
    tryCatch({
      if (rstudioapi::isAvailable()) {
        # Get RStudio version
        rs_version <- rstudioapi::getVersion()

        # Check if reticulate is already configured
        py_config <- reticulate::py_discover_config()

        if (!is.null(py_config$python)) {
          # Verify if this Python installation meets our version requirements
          version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
          python_version <- paste(version_parts[1], version_parts[2], sep = ".")

          if (check_version_range(
            python_version,
            get("PYTHON_MIN_VERSION", envir = .PACKAGE_CONSTANTS),
            get("PYTHON_MAX_VERSION", envir = .PACKAGE_CONSTANTS)
          )) {
            return(list(
              status = TRUE,
              python_path = py_config$python,
              version = python_version
            ))
          }
        }
      }
      return(list(status = FALSE, python_path = NULL, version = NULL))
    }, error = function(e) {
      return(list(status = FALSE, python_path = NULL, version = NULL))
    })
  }

  is_docker <- check_if_docker()

  # 5. Configure basic settings
  suppressWarnings({
    options(reticulate.prompt = FALSE)
    if (Sys.info()["sysname"] == "Darwin") {
      Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
    }
  })

  # Main execution block
  tryCatch({
    # 6. Environment setup with RStudio check
    rstudio_env <- check_rstudio_python()

    if (is_docker) {
      python_path <- Sys.getenv("RETICULATE_PYTHON")
      if (python_path != "") {
        suppressWarnings(reticulate::use_python(python_path, required = TRUE))
      }
    } else if (rstudio_env$status) {
      # Use existing RStudio Python environment
      suppressWarnings(reticulate::use_python(rstudio_env$python_path, required = TRUE))
      packageStartupMessage(sprintf("Using exiting environment: %s", rstudio_env$python_path))
    } else {
      # Fall back to creating/using virtualenv
      home_dir <- path.expand("~")
      venv <- file.path(home_dir, "flair_env")

      if (!reticulate::virtualenv_exists(venv)) {
        suppressWarnings(reticulate::virtualenv_create(venv))
      }
      suppressWarnings(reticulate::use_virtualenv(venv, required = TRUE))
    }

    # 7. Version checks
    py_config <- reticulate::py_config()
    version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
    python_version <- paste(version_parts[1], version_parts[2], sep = ".")

    python_status <- check_version_range(
      python_version,
      get("PYTHON_MIN_VERSION", envir = .PACKAGE_CONSTANTS),
      get("PYTHON_MAX_VERSION", envir = .PACKAGE_CONSTANTS)
    )
    print_status("Python", python_version, python_status)

    if (python_status) {
      # 8. Check and install flair
      check_flair <- function() {
        tryCatch({
          flair <- reticulate::import("flair", delay_load = TRUE)
          version <- reticulate::py_get_attr(flair, "__version__")
          list(status = TRUE, version = version)
        }, error = function(e) {
          list(status = FALSE, version = NULL)
        })
      }

      flair_check <- check_flair()

      if (!flair_check$status && !is_docker) {
        suppressWarnings({
          reticulate::py_install(
            packages = c(
              paste0("numpy==", get("NUMPY_VERSION", envir = .PACKAGE_CONSTANTS)),
              paste0("scipy==", get("SCIPY_VERSION", envir = .PACKAGE_CONSTANTS)),
              paste0("flair[word-embeddings]>=", get("FLAIR_MIN_VERSION", envir = .PACKAGE_CONSTANTS))
            ),
            pip = TRUE,
            method = "auto"
          )
        })
        flair_check <- check_flair()
      }

      print_status("flaiR", flair_check$version, flair_check$status)

      if (flair_check$status) {
        packageStartupMessage(sprintf(
          "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
          .COLORS$BOLD, .COLORS$BLUE, .COLORS$RESET, .COLORS$RESET_BOLD,
          .COLORS$BOLD, .COLORS$YELLOW, flair_check$version, .COLORS$RESET, .COLORS$RESET_BOLD
        ))
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
