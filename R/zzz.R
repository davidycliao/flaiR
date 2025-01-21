#' @keywords internal
"_PACKAGE"

#' @importFrom reticulate import py_get_attr py_config virtualenv_exists virtualenv_create use_virtualenv use_python py_install conda_list virtualenv_list
NULL

# Package environment setup ----------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Version constants
.pkgenv$package_constants <- list(
  python_min_version = "3.9",
  python_max_version = "3.12",
  numpy_version = "1.26.4",
  scipy_version = "1.12.0",
  flair_min_version = "0.11.3",
  torch_version = "2.1.2",
  transformers_version = "4.37.2"
)

# ANSI color codes
.pkgenv$colors <- list(
  green = "\033[32m",
  red = "\033[31m",
  blue = "\033[34m",
  yellow = "\033[33m",
  reset = "\033[39m",
  bold = "\033[1m",
  reset_bold = "\033[22m"
)

# Initialize module storage
.pkgenv$modules <- list(
  flair = NULL,
  flair_embeddings = NULL,
  torch = NULL
)

# Helper functions -----------------------------------------------------

#' Print formatted status message
#' @noRd
print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  symbol <- if (status) "✓" else "✗"
  color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red

  formatted_component <- switch(
    component,
    "Python" = sprintf("%-20s", "Python"),
    "PyTorch" = sprintf("%-20s", "PyTorch"),
    "Transformers" = sprintf("%-20s", "Transformers"),
    "Flair NLP" = sprintf("%-20s", "Flair NLP"),
    "GPU" = sprintf("%-20s", "GPU"),
    sprintf("%-20s", component)
  )

  msg <- sprintf("%s %s%s%s  %s",
                 formatted_component,
                 color,
                 symbol,
                 .pkgenv$colors$reset,
                 if(!is.null(version)) version else "")

  message(msg)
  if (!is.null(extra_message)) {
    message(extra_message)
  }
}

#' Get system information
#' @noRd
get_system_info <- function() {
  os_name <- Sys.info()["sysname"]
  os_version <- switch(
    os_name,
    "Darwin" = tryCatch(
      system("sw_vers -productVersion", intern = TRUE)[1],
      error = function(e) "Unknown"
    ),
    "Windows" = tryCatch(
      system("ver", intern = TRUE)[1],
      error = function(e) "Unknown"
    ),
    tryCatch(
      system("cat /etc/os-release | grep PRETTY_NAME", intern = TRUE)[1],
      error = function(e) "Unknown"
    )
  )

  list(name = os_name, version = os_version)
}

#' Check Python environment
#' @noRd
check_python_env <- function() {
  python_info <- tryCatch({
    config <- py_config()
    list(
      exists = TRUE,
      path = config$python,
      version = config$version
    )
  }, error = function(e) {
    list(exists = FALSE, path = NULL, version = NULL)
  })

  venv_info <- tryCatch({
    venvs <- virtualenv_list()
    if (length(venvs) > 0) {
      list(
        exists = TRUE,
        envs = venvs,
        current = Sys.getenv("VIRTUAL_ENV")
      )
    } else {
      list(exists = FALSE, envs = NULL, current = NULL)
    }
  }, error = function(e) {
    list(exists = FALSE, envs = NULL, current = NULL)
  })

  list(python = python_info, virtualenv = venv_info)
}

#' Initialize required modules
#' @noRd
initialize_modules <- function() {
  tryCatch({
    # Import modules
    torch <- import("torch", delay_load = TRUE)
    transformers <- import("transformers", delay_load = TRUE)
    flair <- import("flair", delay_load = TRUE)
    flair_embeddings <- import("flair.embeddings", delay_load = TRUE)

    # Get versions
    torch_version <- py_get_attr(torch, "__version__")
    transformers_version <- py_get_attr(transformers, "__version__")
    flair_version <- py_get_attr(flair, "__version__")

    # Check GPU capabilities
    cuda_info <- list(
      available = torch$cuda$is_available(),
      device_name = if (torch$cuda$is_available()) {
        tryCatch({
          props <- torch$cuda$get_device_properties(0)
          props$name
        }, error = function(e) NULL)
      } else NULL,
      version = tryCatch(torch$version$cuda, error = function(e) NULL)
    )

    mps_available <- if(Sys.info()["sysname"] == "Darwin") {
      torch$backends$mps$is_available()
    } else FALSE

    # Store modules
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

#' Check for existing flair environment
#' @noRd
check_flair_env <- function() {
  venv_path <- file.path(path.expand("~"), "flair_env")
  venv_python <- file.path(venv_path, "bin", "python")

  if (dir.exists(venv_path) && file.exists(venv_python)) {
    # 檢查是否已安裝所需套件
    tryCatch({
      reticulate::use_virtualenv(venv_path, required = TRUE)
      py <- reticulate::import("sys", convert = TRUE)
      packages <- reticulate::py_list_packages()

      required_packages <- c("torch", "transformers", "flair")
      missing_packages <- required_packages[!required_packages %in% packages$package]

      list(
        exists = TRUE,
        path = venv_python,
        missing_packages = missing_packages
      )
    }, error = function(e) {
      list(
        exists = TRUE,
        path = venv_python,
        error = e$message
      )
    })
  } else {
    list(exists = FALSE, path = NULL)
  }
}

# 修改 .onLoad 函數
.onLoad <- function(libname, pkgname) {
  # Mac 特定設置優化
  if (Sys.info()["sysname"] == "Darwin" &&
      Sys.info()["machine"] == "arm64") {
    # M1/M2/M3 優化設置
    Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    Sys.setenv(PYTORCH_MPS_HIGH_WATERMARK_RATIO = 0.0)
    Sys.setenv(TORCH_NCCL_DEBUG = "INFO")
    Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
  }

  # 基本設置
  options(reticulate.prompt = FALSE)

  # 檢查現有環境
  env_check <- check_flair_env()
  if (env_check$exists) {
    message(sprintf("Found existing flair environment at: %s", env_check$path))

    # 使用現有環境
    Sys.setenv(RETICULATE_PYTHON = env_check$path)
    options(reticulate.python = env_check$path)
    reticulate::use_virtualenv(dirname(dirname(env_check$path)), required = TRUE)

    # 檢查缺少的套件
    if (length(env_check$missing_packages) > 0) {
      message("Installing missing packages: ", paste(env_check$missing_packages, collapse = ", "))
      for (pkg in env_check$missing_packages) {
        tryCatch({
          if (pkg == "torch" && Sys.info()["sysname"] == "Darwin" &&
              Sys.info()["machine"] == "arm64") {
            # 針對 Apple Silicon 的 PyTorch 安裝
            message("Installing PyTorch for Apple Silicon...")
            reticulate::py_install("torch", pip = TRUE)
          } else {
            version <- .pkgenv$package_constants[[paste0(pkg, "_version")]]
            if (!is.null(version)) {
              reticulate::py_install(paste0(pkg, "==", version), pip = TRUE)
            } else {
              reticulate::py_install(pkg, pip = TRUE)
            }
          }
        }, error = function(e) {
          warning(sprintf("Failed to install %s: %s", pkg, e$message))
        })
      }
    }
  } else {
    # 創建新環境
    venv_path <- file.path(path.expand("~"), "flair_env")
    message("Creating new virtual environment at: ", venv_path)

    tryCatch({
      if (Sys.info()["sysname"] == "Darwin" &&
          Sys.info()["machine"] == "arm64") {
        # 使用系統 Python 創建虛擬環境
        python_path <- "/usr/local/bin/python3.10"
        if (!file.exists(python_path)) {
          python_path <- "/usr/bin/python3"
        }
        reticulate::virtualenv_create(venv_path, python = python_path)

        # 立即設置必要的環境變量
        venv_python <- file.path(venv_path, "bin", "python")
        Sys.setenv(RETICULATE_PYTHON = venv_python)
        options(reticulate.python = venv_python)
        reticulate::use_virtualenv(venv_path, required = TRUE)

        # 先安裝 PyTorch
        message("Installing PyTorch for Apple Silicon...")
        reticulate::py_install("torch", pip = TRUE)
      } else {
        reticulate::virtualenv_create(venv_path)
        venv_python <- file.path(venv_path, "bin", "python")
        Sys.setenv(RETICULATE_PYTHON = venv_python)
        options(reticulate.python = venv_python)
        reticulate::use_virtualenv(venv_path, required = TRUE)
      }
    }, error = function(e) {
      stop("Failed to create virtual environment: ", e$message)
    })
  }
}

#' @noRd
.onAttach <- function(libname, pkgname) {
  # 顯示環境信息
  sys_info <- get_system_info()

  message("\nEnvironment Information:")
  message(sprintf("OS: %s (%s)", sys_info$name, sys_info$version))

  # 獲取當前 Python 路徑
  current_python <- tryCatch({
    config <- reticulate::py_config()
    message(sprintf("Using virtual environment: %s", config$python))
    config$python
  }, error = function(e) {
    message("Error getting Python configuration: ", e$message)
    NULL
  })

  message("")

  # Initialize Python environment
  tryCatch({
    # Set up virtual environment
    venv <- file.path(path.expand("~"), "flair_env")
    if (!virtualenv_exists(venv)) {
      suppressWarnings(virtualenv_create(venv))
    }
    suppressWarnings(use_virtualenv(venv, required = TRUE))

    # Check Python version
    config <- py_config()
    version_parts <- strsplit(as.character(config$version), "\\.")[[1]]
    python_version <- paste(version_parts[1], version_parts[2], sep = ".")

    python_status <- as.numeric(version_parts[1]) == 3 &&
      as.numeric(version_parts[2]) >= 9 &&
      as.numeric(version_parts[2]) <= 12

    print_status("Python", python_version, python_status)

    if (python_status) {
      init_result <- initialize_modules()

      if (!init_result$status) {
        # Install required packages
        suppressWarnings({
          py_install(
            packages = c(
              paste0("torch==", .pkgenv$package_constants$torch_version),
              paste0("numpy==", .pkgenv$package_constants$numpy_version),
              paste0("scipy==", .pkgenv$package_constants$scipy_version),
              paste0("transformers==",
                     .pkgenv$package_constants$transformers_version),
              paste0("flair>=", .pkgenv$package_constants$flair_min_version)
            ),
            pip = TRUE,
            method = "auto"
          )
        })
        init_result <- initialize_modules()
      }

      if (init_result$status) {
        # Print component status
        print_status("PyTorch", init_result$versions$torch, TRUE)
        print_status("Transformers", init_result$versions$transformers, TRUE)
        print_status("Flair NLP", init_result$versions$flair, TRUE)

        # Print GPU status
        cuda_info <- init_result$device$cuda
        if (cuda_info$available || init_result$device$mps) {
          print_status("GPU", "available", TRUE)

          if (cuda_info$available) {
            gpu_type <- if (!is.null(cuda_info$device_name)) {
              sprintf("CUDA (%s)", cuda_info$device_name)
            } else {
              "CUDA"
            }
            print_status(gpu_type, cuda_info$version, TRUE)
          }

          if (init_result$device$mps) {
            print_status("Mac MPS", "available", TRUE)
          }
        } else {
          print_status("GPU", "not available", FALSE)
        }

        # Print welcome message
        msg <- sprintf(
          "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
          .pkgenv$colors$bold, .pkgenv$colors$blue,
          .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
          .pkgenv$colors$bold, .pkgenv$colors$yellow,
          init_result$versions$flair,
          .pkgenv$colors$reset, .pkgenv$colors$reset_bold
        )
        message(msg)
      }
    }
  }, error = function(e) {
    message("Error during initialization: ", e$message)
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
