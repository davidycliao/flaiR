#' @keywords internal
"_PACKAGE"

#' @import reticulate
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

#' Compare version numbers
#' @noRd
check_python_version <- function(version) {
  min_v <- .pkgenv$package_constants$python_min_version
  max_v <- .pkgenv$package_constants$python_max_version

  # Parse version strings to numeric vectors
  parse_version <- function(v) {
    as.numeric(strsplit(v, "\\.")[[1]][1:2])
  }

  ver <- parse_version(version)
  min_ver <- parse_version(min_v)
  max_ver <- parse_version(max_v)

  # Check version compatibility
  if (ver[1] < min_ver[1] || ver[1] > max_ver[1]) return(FALSE)
  if (ver[1] == min_ver[1] && ver[2] < min_ver[2]) return(FALSE)
  if (ver[1] == max_ver[1] && ver[2] > max_ver[2]) return(FALSE)

  return(TRUE)
}

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
    "Conda" = sprintf("%-20s", "Conda"),
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

#' Install required dependencies
#' @noRd
install_dependencies <- function(venv) {
  tryCatch({
    message("Installing dependencies in ", venv, "...")

    # Install base packages with conda
    reticulate::conda_install(
      envname = venv,
      packages = c(
        sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
        sprintf("scipy==%s", .pkgenv$package_constants$scipy_version)
      ),
      channel = "conda-forge"
    )

    # Install PyTorch
    reticulate::py_install(
      packages = "torch",
      pip = TRUE,
      envname = venv
    )

    # Install other dependencies
    reticulate::py_install(
      packages = c(
        sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
        "sentencepiece>=0.1.97,<0.2.0",
        sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
      ),
      pip = TRUE,
      envname = venv
    )

    # Verify installation
    reticulate::use_condaenv(venv, required = TRUE)
    if (!reticulate::py_module_available("flair")) {
      stop("Flair installation verification failed")
    }

    return(TRUE)
  }, error = function(e) {
    message("Error installing dependencies: ", e$message)
    return(FALSE)
  })
}

#' Check and setup conda environment
#' @noRd
check_conda_env <- function(show_status = FALSE) {
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (!conda_available$status) {
    if (show_status) {
      print_status("Conda", NULL, FALSE, "Conda not found")
    }
    return(FALSE)
  }

  if (show_status) {
    print_status("Conda", conda_available$path, TRUE)
  }

  # Check for flair_env
  has_flair_env <- "flair_env" %in% reticulate::conda_list()$name
  if (has_flair_env) {
    tryCatch({
      reticulate::use_condaenv("flair_env", required = TRUE)
      if (!reticulate::py_module_available("flair")) {
        message("Flair environment exists but modules are missing. Reinstalling...")
        if (!install_dependencies("flair_env")) {
          return(FALSE)
        }
      }
      return(TRUE)
    }, error = function(e) {
      message("Error using flair_env: ", e$message)
      has_flair_env <- FALSE
    })
  }

  if (!has_flair_env) {
    message("Creating new conda environment: flair_env")
    tryCatch({
      reticulate::conda_create("flair_env")
      if (!install_dependencies("flair_env")) {
        return(FALSE)
      }
      return(TRUE)
    }, error = function(e) {
      message("Failed to create conda environment: ", e$message)
      return(FALSE)
    })
  }

  return(TRUE)
}

#' Initialize required modules
#' @noRd
initialize_modules <- function() {
  tryCatch({
    # Import modules
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)

    # Get versions
    torch_version <- reticulate::py_get_attr(torch, "__version__")
    transformers_version <- reticulate::py_get_attr(transformers, "__version__")
    flair_version <- reticulate::py_get_attr(flair, "__version__")

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

# Package initialization ----------------------------------------------

#' @noRd
.onLoad <- function(libname, pkgname) {
  # Set essential environment variables
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  # Mac-specific settings
  if (Sys.info()["sysname"] == "Darwin") {
    if (Sys.info()["machine"] == "arm64") {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    }
    Sys.setenv(OMP_NUM_THREADS = 1)
    Sys.setenv(MKL_NUM_THREADS = 1)
  }

  # Disable reticulate prompt
  options(reticulate.prompt = FALSE)
}

#' @noRd
#' @noRd
.onAttach <- function(libname, pkgname) {
  # 保存原始環境設定
  original_env <- list(
    RETICULATE_PYTHON = Sys.getenv("RETICULATE_PYTHON"),
    VIRTUALENV = Sys.getenv("VIRTUALENV"),
    RETICULATE_PYTHON_ENV = Sys.getenv("RETICULATE_PYTHON_ENV")
  )

  # 確保在函數結束時恢復設定
  on.exit({
    for (name in names(original_env)) {
      if (original_env[[name]] != "") {
        Sys.setenv(!!name := original_env[[name]])
      }
    }
    options(reticulate.python.initializing = FALSE)
  })

  tryCatch({
    # 清除現有 Python 設定
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    Sys.unsetenv("RETICULATE_PYTHON_ENV")
    options(reticulate.python.initializing = TRUE)

    # 顯示系統資訊
    sys_info <- get_system_info()
    message("\nEnvironment Information:")
    message(sprintf("OS: %s (%s)",
                    as.character(sys_info$name),
                    as.character(sys_info$version)))

    # 檢查 conda
    conda_available <- tryCatch({
      conda_bin <- reticulate::conda_binary()
      list(status = TRUE, path = conda_bin)
    }, error = function(e) {
      list(status = FALSE, error = e$message)
    })

    if (!conda_available$status) {
      print_status("Conda", NULL, FALSE, "Conda not found")
      message("Will attempt to use system Python...")
    } else {
      print_status("Conda", conda_available$path, TRUE)

      # 列出所有 conda 環境
      conda_envs <- reticulate::conda_list()
      has_flair_env <- "flair_env" %in% conda_envs$name

      if (!has_flair_env && nrow(conda_envs) > 0) {
        message("\nNo flair_env found. Available conda environments:")
        for (i in seq_len(nrow(conda_envs))) {
          message(sprintf("%d. %s (%s)",
                          i,
                          conda_envs$name[i],
                          conda_envs$python[i]))
        }

        # 使用第一個可用的環境
        selected_env <- conda_envs$name[1]
        message(sprintf("\nUsing conda environment: %s", selected_env))

        tryCatch({
          reticulate::use_condaenv(selected_env, required = TRUE)
          if (!reticulate::py_module_available("flair")) {
            message(sprintf("Installing flair in %s...", selected_env))
            install_dependencies(selected_env)
          }
        }, error = function(e) {
          message(sprintf("Error using conda environment %s: %s",
                          selected_env, e$message))
        })
      }
    }

    # 取得 Python 配置
    config <- tryCatch({
      reticulate::py_config()
    }, error = function(e) {
      message("Error getting Python configuration: ", e$message)
      return(NULL)
    })

    if (!is.null(config)) {
      python_version <- as.character(config$version)
      python_status <- check_python_version(python_version)

      print_status("Python", python_version, python_status)
      message(sprintf("Using Python: %s", config$python))
      message("")

      # 初始化模組
      init_result <- initialize_modules()

      if (init_result$status) {
        # 驗證所需模組
        required_modules <- c("torch", "transformers", "flair")
        missing_modules <- required_modules[!sapply(required_modules, reticulate::py_module_available)]

        if (length(missing_modules) == 0) {
          print_status("PyTorch", init_result$versions$torch, TRUE)
          print_status("Transformers", init_result$versions$transformers, TRUE)
          print_status("Flair NLP", init_result$versions$flair, TRUE)

          # GPU 狀態
          cuda_info <- init_result$device$cuda
          if (!is.null(cuda_info$available) &&
              (cuda_info$available || init_result$device$mps)) {
            print_status("GPU", "available", TRUE)

            if (cuda_info$available) {
              gpu_type <- if (!is.null(cuda_info$device_name)) {
                sprintf("CUDA (%s)", cuda_info$device_name)
              } else {
                "CUDA"
              }
              print_status(gpu_type, cuda_info$version, TRUE)
            }

            if (!is.null(init_result$device$mps) && init_result$device$mps) {
              print_status("Mac MPS", "available", TRUE)
            }
          } else {
            print_status("GPU", "not available", FALSE)
          }

          # 歡迎訊息
          msg <- sprintf(
            "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
            .pkgenv$colors$bold, .pkgenv$colors$blue,
            .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
            .pkgenv$colors$bold, .pkgenv$colors$yellow,
            init_result$versions$flair,
            .pkgenv$colors$reset, .pkgenv$colors$reset_bold
          )
          message(msg)
        } else {
          message(sprintf("Warning: Required modules missing: %s",
                          paste(missing_modules, collapse = ", ")))
        }
      }
    }
  }, error = function(e) {
    message("Error during initialization: ", as.character(e$message))
  })

  invisible(NULL)
}

#' #' @keywords internal
#' "_PACKAGE"
#'
#' #' @import reticulate
#' NULL
#'
#' # Package environment setup ----------------------------------------------
#' .pkgenv <- new.env(parent = emptyenv())
#'
#' # Version constants
#' .pkgenv$package_constants <- list(
#'   python_min_version = "3.9",
#'   python_max_version = "3.12",
#'   numpy_version = "1.26.4",
#'   scipy_version = "1.12.0",
#'   flair_min_version = "0.11.3",
#'   torch_version = "2.1.2",
#'   transformers_version = "4.37.2"
#' )
#'
#' # ANSI color codes
#' .pkgenv$colors <- list(
#'   green = "\033[32m",
#'   red = "\033[31m",
#'   blue = "\033[34m",
#'   yellow = "\033[33m",
#'   reset = "\033[39m",
#'   bold = "\033[1m",
#'   reset_bold = "\033[22m"
#' )
#'
#' # Initialize module storage
#' .pkgenv$modules <- list(
#'   flair = NULL,
#'   flair_embeddings = NULL,
#'   torch = NULL
#' )
#'
#' # Helper Functions -----------------------------------------------------
#'
#' #' Compare version numbers
#' #' @noRd
#' compare_versions <- function(version_str1, version_str2) {
#'   v1 <- as.numeric(strsplit(version_str1, "\\.")[[1]][1:2])
#'   v2 <- as.numeric(strsplit(version_str2, "\\.")[[1]][1:2])
#'
#'   # Compare major version
#'   if (v1[1] != v2[1]) return(v1[1] - v2[1])
#'   # Compare minor version
#'   if (length(v1) >= 2 && length(v2) >= 2) return(v1[2] - v2[2])
#'   return(0)
#' }
#'
#' #' Check if Python version is supported
#' #' @noRd
#' check_python_version <- function(version) {
#'   min_v <- .pkgenv$package_constants$python_min_version
#'   max_v <- .pkgenv$package_constants$python_max_version
#'
#'   if (compare_versions(version, min_v) < 0 ||
#'       compare_versions(version, max_v) > 0) {
#'     return(FALSE)
#'   }
#'   return(TRUE)
#' }
#'
#' #' Install required dependencies in specified environment
#' #' @noRd
#' install_dependencies <- function(venv) {
#'   tryCatch({
#'     message("Installing dependencies in ", venv, "...")
#'
#'     # 確保使用 conda 環境
#'     conda_path <- reticulate::conda_binary()
#'     if (is.null(conda_path)) {
#'       stop("Conda not found. Please install Miniconda or Anaconda.")
#'     }
#'
#'     # 確保環境存在
#'     if (!venv %in% reticulate::conda_list()$name) {
#'       message("Creating conda environment: ", venv)
#'       reticulate::conda_create(venv)
#'     }
#'
#'     # 先啟用環境
#'     reticulate::use_condaenv(venv, required = TRUE)
#'
#'     # 使用 conda 安裝基礎套件
#'     message("Installing base packages with conda...")
#'     reticulate::conda_install(
#'       envname = venv,
#'       packages = c(
#'         "python>=3.9",
#'         sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#'         sprintf("scipy==%s", .pkgenv$package_constants$scipy_version)
#'       ),
#'       channel = c("conda-forge", "defaults")
#'     )
#'
#'     # 使用 reticulate 的 py_install 安裝所有依賴
#'     message("Installing PyTorch and other dependencies...")
#'     reticulate::py_install(
#'       packages = c(
#'         "torch",
#'         sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
#'         "sentencepiece<0.2.0",
#'         sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#'       ),
#'       pip = TRUE,
#'       envname = venv
#'     )
#'
#'     # 驗證安裝
#'     reticulate::use_condaenv(venv, required = TRUE)
#'     required_packages <- c("torch", "transformers", "flair")
#'     missing_packages <- required_packages[!sapply(required_packages, reticulate::py_module_available)]
#'
#'     if (length(missing_packages) > 0) {
#'       stop(sprintf("Installation verification failed for: %s",
#'                    paste(missing_packages, collapse = ", ")))
#'     }
#'
#'     return(TRUE)
#'   }, error = function(e) {
#'     message("Error installing dependencies: ", e$message)
#'     return(FALSE)
#'   })
#' }
#'
#' #' Check and setup conda environment
#' #' @noRd
#' check_conda_env <- function(show_status = FALSE) {
#'   # Check if conda exists
#'   conda_available <- tryCatch({
#'     conda_bin <- reticulate::conda_binary()
#'     list(status = TRUE, path = conda_bin)
#'   }, error = function(e) {
#'     list(status = FALSE, error = e$message)
#'   })
#'
#'   if (!conda_available$status) {
#'     if (show_status) {
#'       print_status("Conda", NULL, FALSE, "Conda not found")
#'     }
#'     return(FALSE)
#'   }
#'
#'   if (show_status) {
#'     print_status("Conda", conda_available$path, TRUE)
#'   }
#'
#'   # List conda environments
#'   conda_envs <- reticulate::conda_list()
#'
#'   # Check for flair_env
#'   has_flair_env <- "flair_env" %in% conda_envs$name
#'   if (has_flair_env) {
#'     tryCatch({
#'       reticulate::use_condaenv("flair_env", required = TRUE)
#'       if (!reticulate::py_module_available("flair")) {
#'         message("Flair environment exists but modules are missing. Reinstalling...")
#'         if (!install_dependencies("flair_env")) {
#'           return(FALSE)
#'         }
#'       }
#'       return(TRUE)
#'     }, error = function(e) {
#'       message("Error using existing flair_env: ", e$message)
#'       has_flair_env <- FALSE
#'     })
#'   }
#'
#'   if (!has_flair_env) {
#'     message("Creating new conda environment: flair_env")
#'     tryCatch({
#'       # Create environment without specifying Python version
#'       reticulate::conda_create("flair_env")
#'
#'       # Install dependencies
#'       if (!install_dependencies("flair_env")) {
#'         return(FALSE)
#'       }
#'
#'       # Verify Python version
#'       python_config <- reticulate::py_config()
#'       if (!check_python_version(python_config$version)) {
#'         message(sprintf(
#'           "Warning: Python version %s is outside the supported range (%s-%s)",
#'           python_config$version,
#'           .pkgenv$package_constants$python_min_version,
#'           .pkgenv$package_constants$python_max_version
#'         ))
#'       }
#'
#'       return(TRUE)
#'     }, error = function(e) {
#'       message("Failed to create conda environment: ", e$message)
#'       return(FALSE)
#'     })
#'   }
#'
#'   return(TRUE)
#' }
#'
#' #' Verify package installation
#' #' @noRd
#' verify_installation <- function(venv) {
#'   message("\nVerifying installation...")
#'
#'   # List of required packages and their import names
#'   required_packages <- list(
#'     list(name = "numpy", import = "numpy"),
#'     list(name = "torch", import = "torch"),
#'     list(name = "transformers", import = "transformers"),
#'     list(name = "flair", import = "flair")
#'   )
#'
#'   # Check each package
#'   for (pkg in required_packages) {
#'     if (!reticulate::py_module_available(pkg$import)) {
#'       message(sprintf("Package %s not found, attempting reinstallation...", pkg$name))
#'       reticulate::py_install(pkg$name, pip = TRUE, envname = venv)
#'
#'       if (!reticulate::py_module_available(pkg$import)) {
#'         stop(sprintf("Failed to install %s", pkg$name))
#'       }
#'     }
#'
#'     # Try importing the module to verify it works
#'     tryCatch({
#'       module <- reticulate::import(pkg$import)
#'       version <- reticulate::py_get_attr(module, "__version__")
#'       message(sprintf("✓ %s version %s successfully installed", pkg$name, version))
#'     }, error = function(e) {
#'       stop(sprintf("Error importing %s: %s", pkg$name, e$message))
#'     })
#'   }
#'
#'   # Verify flair can be imported and used
#'   tryCatch({
#'     flair <- reticulate::import("flair")
#'     # Try accessing a basic class to ensure the import worked
#'     sentence_class <- flair$data$Sentence
#'     message("✓ Flair functionality verified")
#'   }, error = function(e) {
#'     stop(sprintf("Error verifying flair functionality: %s", e$message))
#'   })
#' }
#'
#' #' Print formatted status message
#' #' @noRd
#' print_status <- function(component, version, status = TRUE, extra_message = NULL) {
#'   symbol <- if (status) "✓" else "✗"
#'   color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red
#'
#'   formatted_component <- switch(
#'     component,
#'     "Python" = sprintf("%-20s", "Python"),
#'     "PyTorch" = sprintf("%-20s", "PyTorch"),
#'     "Transformers" = sprintf("%-20s", "Transformers"),
#'     "Flair NLP" = sprintf("%-20s", "Flair NLP"),
#'     "GPU" = sprintf("%-20s", "GPU"),
#'     "Conda" = sprintf("%-20s", "Conda"),
#'     sprintf("%-20s", component)
#'   )
#'
#'   msg <- sprintf("%s %s%s%s  %s",
#'                  formatted_component,
#'                  color,
#'                  symbol,
#'                  .pkgenv$colors$reset,
#'                  if(!is.null(version)) version else "")
#'
#'   message(msg)
#'   if (!is.null(extra_message)) {
#'     message(extra_message)
#'   }
#' }
#'
#' #' Get system information
#' #' @noRd
#' get_system_info <- function() {
#'   os_name <- Sys.info()["sysname"]
#'   os_version <- switch(
#'     os_name,
#'     "Darwin" = tryCatch(
#'       system("sw_vers -productVersion", intern = TRUE)[1],
#'       error = function(e) "Unknown"
#'     ),
#'     "Windows" = tryCatch(
#'       system("ver", intern = TRUE)[1],
#'       error = function(e) "Unknown"
#'     ),
#'     tryCatch(
#'       system("cat /etc/os-release | grep PRETTY_NAME", intern = TRUE)[1],
#'       error = function(e) "Unknown"
#'     )
#'   )
#'
#'   list(name = os_name, version = os_version)
#' }
#'
#'
#' #' Initialize required modules
#' #' @noRd
#' initialize_modules <- function() {
#'   tryCatch({
#'     # Import modules
#'     torch <- reticulate::import("torch", delay_load = TRUE)
#'     transformers <- reticulate::import("transformers", delay_load = TRUE)
#'     flair <- reticulate::import("flair", delay_load = TRUE)
#'
#'     # Get versions
#'     torch_version <- reticulate::py_get_attr(torch, "__version__")
#'     transformers_version <- reticulate::py_get_attr(transformers, "__version__")
#'     flair_version <- reticulate::py_get_attr(flair, "__version__")
#'
#'     # Check GPU capabilities
#'     cuda_info <- list(
#'       available = torch$cuda$is_available(),
#'       device_name = if (torch$cuda$is_available()) {
#'         tryCatch({
#'           props <- torch$cuda$get_device_properties(0)
#'           props$name
#'         }, error = function(e) NULL)
#'       } else NULL,
#'       version = tryCatch(torch$version$cuda, error = function(e) NULL)
#'     )
#'
#'     mps_available <- if(Sys.info()["sysname"] == "Darwin") {
#'       torch$backends$mps$is_available()
#'     } else FALSE
#'
#'     # Store modules
#'     .pkgenv$modules$flair <- flair
#'     .pkgenv$modules$torch <- torch
#'
#'     list(
#'       versions = list(
#'         torch = torch_version,
#'         transformers = transformers_version,
#'         flair = flair_version
#'       ),
#'       device = list(
#'         cuda = cuda_info,
#'         mps = mps_available
#'       ),
#'       status = TRUE
#'     )
#'   }, error = function(e) {
#'     list(status = FALSE, error = e$message)
#'   })
#' }
#'
#' # Package Initialization ----------------------------------------------
#'
#' #' @noRd
#' .onLoad <- function(libname, pkgname) {
#'   # Set essential environment variables
#'   Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
#'
#'   # Mac-specific settings
#'   if (Sys.info()["sysname"] == "Darwin") {
#'     if (Sys.info()["machine"] == "arm64") {
#'       Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
#'     }
#'     Sys.setenv(OMP_NUM_THREADS = 1)
#'     Sys.setenv(MKL_NUM_THREADS = 1)
#'   }
#'
#'   # Disable reticulate prompt
#'   options(reticulate.prompt = FALSE)
#' }
#'
#'
#' #' @noRd
#' .onAttach <- function(libname, pkgname) {
#'   tryCatch({
#'     # Reset Python environment variables
#'     Sys.unsetenv("VIRTUAL_ENV")
#'     Sys.unsetenv("PYTHONPATH")
#'
#'     # Show environment information
#'     sys_info <- get_system_info()
#'     message("\nEnvironment Information:")
#'     message(sprintf("OS: %s (%s)",
#'                     as.character(sys_info$name),
#'                     as.character(sys_info$version)))
#'
#'     # Check conda installation and print status
#'     conda_path <- reticulate::conda_binary()
#'     if (is.null(conda_path)) {
#'       print_status("Conda", NULL, FALSE, "Conda not found")
#'       message("Please install Miniconda or Anaconda.")
#'       return(invisible(NULL))
#'     }
#'     print_status("Conda", conda_path, TRUE)
#'
#'     # Initialize Python environment (without showing conda status again)
#'     conda_setup <- check_conda_env(show_status = FALSE)
#'     if (!conda_setup) {
#'       message("Attempting to use system Python...")
#'       return(invisible(NULL))
#'     }
#'
#'     # Rest of the initialization code...
#'     config <- tryCatch({
#'       reticulate::py_config()
#'     }, error = function(e) {
#'       message("Error getting Python configuration: ", e$message)
#'       return(NULL)
#'     })
#'
#'     if (is.null(config)) {
#'       return(invisible(NULL))
#'     }
#'
#'     python_version <- tryCatch({
#'       version_str <- as.character(config$version)
#'       if (is.null(version_str) || !nzchar(version_str)) {
#'         stop("Invalid Python version")
#'       }
#'       version_str
#'     }, error = function(e) {
#'       message("Error processing Python version: ", e$message)
#'       return(NULL)
#'     })
#'
#'     if (is.null(python_version)) {
#'       return(invisible(NULL))
#'     }
#'
#'     python_status <- check_python_version(python_version)
#'     print_status("Python", python_version, python_status)
#'
#'     python_path <- tryCatch({
#'       as.character(config$python)
#'     }, error = function(e) {
#'       "Unknown Python path"
#'     })
#'     message(sprintf("Using Python: %s", python_path))
#'     message("")
#'
#'     # Rest of the code remains the same...
#'   }, error = function(e) {
#'     message("Error during initialization: ", as.character(e$message))
#'   })
#'
#'   invisible(NULL)
#' }
