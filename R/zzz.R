# zzz.R
.pkgenv <- new.env(parent = emptyenv())

# Constants for version management
.pkgenv$PACKAGE_CONSTANTS <- list(
  PYTHON_MIN_VERSION = "3.9",
  PYTHON_MAX_VERSION = "3.12",
  NUMPY_VERSION = "1.26.4",
  SCIPY_VERSION = "1.12.0",
  FLAIR_MIN_VERSION = "0.11.3",
  TORCH_VERSION = "2.1.2",
  TRANSFORMERS_VERSION = "4.37.2"
)

# ANSI color codes for status messages
.pkgenv$COLORS <- list(
  GREEN = "\033[32m",
  RED = "\033[31m",
  BLUE = "\033[34m",
  YELLOW = "\033[33m",
  RESET = "\033[39m",
  BOLD = "\033[1m",
  RESET_BOLD = "\033[22m"
)

# Initialize module storage
.pkgenv$modules <- list(
  flair = NULL,
  flair_embeddings = NULL,
  torch = NULL
)

.onLoad <- function(libname, pkgname) {
  # Set environment variables first
  if (Sys.info()["sysname"] == "Darwin" &&
      Sys.info()["machine"] == "arm64") {
    Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
  }
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  # Initialize reticulate configuration
  options(reticulate.prompt = FALSE)
}

print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  if (status) {
    symbol <- "✓"
    color <- .pkgenv$COLORS$GREEN
  } else {
    symbol <- "✗"
    color <- .pkgenv$COLORS$RED
  }

  formatted_component <- switch(component,
                                "Python" = sprintf("%-20s", "Python"),
                                "PyTorch" = sprintf("%-20s", "PyTorch"),
                                "Transformers" = sprintf("%-20s", "Transformers"),
                                "Flair NLP" = sprintf("%-20s", "Flair NLP"),
                                "GPU" = sprintf("%-20s", "GPU"),
                                sprintf("%-20s", component)
  )

  message <- sprintf("%s %s%s%s  %s",
                     formatted_component,
                     color,
                     symbol,
                     .pkgenv$COLORS$RESET,
                     if(!is.null(version)) version else "")

  packageStartupMessage(message)
  if (!is.null(extra_message)) {
    packageStartupMessage(extra_message)
  }
}

initialize_modules <- function() {
  tryCatch({
    # Import modules
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)
    flair_embeddings <- reticulate::import("flair.embeddings", delay_load = TRUE)

    # Get version information
    torch_version <- reticulate::py_get_attr(torch, "__version__")
    transformers_version <- reticulate::py_get_attr(transformers, "__version__")
    flair_version <- reticulate::py_get_attr(flair, "__version__")

    # Check CUDA information
    cuda_info <- list(
      available = torch$cuda$is_available(),
      device_count = if (torch$cuda$is_available()) torch$cuda$device_count() else 0,
      device_name = if (torch$cuda$is_available()) {
        tryCatch({
          device_props <- torch$cuda$get_device_properties(0)
          device_props$name
        }, error = function(e) NULL)
      } else NULL,
      version = tryCatch(torch$version$cuda, error = function(e) NULL)
    )

    # Check MPS availability
    mps_available <- if(Sys.info()["sysname"] == "Darwin") {
      torch$backends$mps$is_available()
    } else FALSE

    # Store modules in package environment
    .pkgenv$modules$flair <- flair
    .pkgenv$modules$flair_embeddings <- flair_embeddings
    .pkgenv$modules$torch <- torch

    list(
      versions = list(
        torch = torch_version,
        transformers = transformers_version,
        flair = flair_version
      ),
      device = list(
        cuda = cuda_info,
        mps = mps_available
      ),
      status = TRUE
    )
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })
}

print_device_status <- function(init_result) {
  # Check system and device type
  is_mac <- Sys.info()["sysname"] == "Darwin"
  is_mac_arm <- is_mac && Sys.info()["machine"] == "arm64"

  # GPU status
  cuda_info <- init_result$device$cuda
  if (cuda_info$available || init_result$device$mps) {
    print_status("GPU", "available", TRUE)

    # CUDA information
    if (cuda_info$available) {
      gpu_type <- if (!is.null(cuda_info$device_name)) {
        sprintf("CUDA (%s)", cuda_info$device_name)
      } else {
        "CUDA"
      }
      print_status(gpu_type, cuda_info$version, TRUE)
    }

    # MPS information (Mac ARM only)
    if (is_mac_arm && init_result$device$mps) {
      print_status("Mac MPS", "available", TRUE)
    }
  } else {
    print_status("GPU", "not available", FALSE)
  }
}

.onAttach <- function(libname, pkgname) {
  # Check if running in Docker
  is_docker <- file.exists("/.dockerenv")
  if (is_docker) {
    packageStartupMessage("Docker environment detected")
  }

  tryCatch({
    if (is_docker) {
      # Docker environment setup
      python_path <- Sys.getenv("RETICULATE_PYTHON")
      if (python_path != "") {
        suppressWarnings(reticulate::use_python(python_path, required = TRUE))
      }
    } else {
      # Local environment setup
      home_dir <- path.expand("~")
      venv <- file.path(home_dir, "flair_env")

      if (!reticulate::virtualenv_exists(venv)) {
        suppressWarnings(reticulate::virtualenv_create(venv))
      }
      suppressWarnings(reticulate::use_virtualenv(venv, required = TRUE))
    }

    # Check Python version
    py_config <- reticulate::py_config()
    version_parts <- strsplit(as.character(py_config$version), "\\.")[[1]]
    python_version <- paste(version_parts[1], version_parts[2], sep = ".")

    python_status <- as.numeric(version_parts[1]) == 3 &&
      as.numeric(version_parts[2]) >= 9 &&
      as.numeric(version_parts[2]) <= 12

    print_status("Python", python_version, python_status)

    if (python_status) {
      # Initialize and install components
      init_result <- initialize_modules()

      if (!init_result$status && !is_docker) {
        # Install required packages
        suppressWarnings({
          reticulate::py_install(
            packages = c(
              paste0("torch==", .pkgenv$PACKAGE_CONSTANTS$TORCH_VERSION),
              paste0("numpy==", .pkgenv$PACKAGE_CONSTANTS$NUMPY_VERSION),
              paste0("scipy==", .pkgenv$PACKAGE_CONSTANTS$SCIPY_VERSION),
              paste0("transformers==", .pkgenv$PACKAGE_CONSTANTS$TRANSFORMERS_VERSION),
              paste0("flair>=", .pkgenv$PACKAGE_CONSTANTS$FLAIR_MIN_VERSION)
            ),
            pip = TRUE,
            method = "auto"
          )
        })
        # Reinitialize
        init_result <- initialize_modules()
      }

      if (init_result$status) {
        # Print component status
        print_status("PyTorch", init_result$versions$torch, TRUE)
        print_status("Transformers", init_result$versions$transformers, TRUE)
        print_status("Flair NLP", init_result$versions$flair, TRUE)

        # Print device status
        print_device_status(init_result)

        # Print welcome message
        packageStartupMessage(sprintf("%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
                                      .pkgenv$COLORS$BOLD, .pkgenv$COLORS$BLUE,
                                      .pkgenv$COLORS$RESET, .pkgenv$COLORS$RESET_BOLD,
                                      .pkgenv$COLORS$BOLD, .pkgenv$COLORS$YELLOW,
                                      init_result$versions$flair,
                                      .pkgenv$COLORS$RESET, .pkgenv$COLORS$RESET_BOLD))
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
