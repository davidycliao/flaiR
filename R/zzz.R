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

#' Print Formatted Message
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

#' Get System Information
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

#' Install Required Dependencies
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


##' Check and setup conda environment
#' @noRd
check_conda_env <- function(show_status = FALSE, auto_install = TRUE) {  # 預設 auto_install = TRUE
  # 清除任何現有的 Python 設定
  try({
    reticulate::py_clear_config()
    reticulate::use_python(NULL)
  }, silent = TRUE)

  # 清除環境變數
  Sys.unsetenv("RETICULATE_PYTHON")
  Sys.unsetenv("VIRTUALENV")
  Sys.unsetenv("PYTHONHOME")
  Sys.unsetenv("PYTHONPATH")

  # 檢查 conda
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  # 顯示 conda 狀態
  if (show_status) {
    if (conda_available$status) {
      print_status("Conda", conda_available$path, TRUE)
    } else {
      print_status("Conda", NULL, FALSE, "Conda not found")
    }
  }

  if (conda_available$status) {
    # 獲取所有 conda 環境
    conda_envs <- reticulate::conda_list()

    # 檢查 flair_env
    if ("flair_env" %in% conda_envs$name) {
      flair_envs <- conda_envs[conda_envs$name == "flair_env", ]

      if (nrow(flair_envs) > 1) {
        packageStartupMessage("\nMultiple flair_env environments found:")
        for (i in seq_len(nrow(flair_envs))) {
          packageStartupMessage(sprintf("%d. %s", i, flair_envs$python[i]))
        }

        # 優先選擇 miniconda 環境
        miniconda_env <- grep("miniconda", flair_envs$python, value = TRUE)

        if (length(miniconda_env) > 0) {
          packageStartupMessage("\nSelecting miniconda environment")
          selected_env <- miniconda_env[1]
        } else {
          packageStartupMessage("\nNo miniconda environment found, using first available")
          selected_env <- flair_envs$python[1]
        }

        packageStartupMessage(sprintf("Using environment: %s", selected_env))

        if (file.exists(selected_env)) {
          return(tryCatch({
            reticulate::use_python(selected_env, required = TRUE)
            # 自動安裝 flair 如果不存在
            if (!reticulate::py_module_available("flair")) {
              packageStartupMessage("Installing flair in selected environment...")
              install_dependencies("flair_env")
            }
            TRUE
          }, error = function(e) {
            packageStartupMessage(sprintf("Error using environment: %s", e$message))
            FALSE
          }))
        }
      } else {
        # 單一 flair_env 的情況
        env_path <- flair_envs$python[1]
        if (file.exists(env_path)) {
          return(tryCatch({
            reticulate::use_python(env_path, required = TRUE)
            if (!reticulate::py_module_available("flair")) {
              packageStartupMessage("Installing flair...")
              install_dependencies("flair_env")
            }
            TRUE
          }, error = function(e) {
            packageStartupMessage(sprintf("Error using environment: %s", e$message))
            FALSE
          }))
        }
      }
    }

    # 如果沒有 flair_env，使用其他環境
    if (nrow(conda_envs) > 0) {
      env_name <- conda_envs$name[1]
      packageStartupMessage(sprintf("\nUsing conda environment: %s", env_name))
      return(tryCatch({
        reticulate::use_condaenv(env_name, required = TRUE)
        if (!reticulate::py_module_available("flair")) {
          packageStartupMessage("Installing flair...")
          install_dependencies(env_name)
        }
        TRUE
      }, error = function(e) {
        packageStartupMessage(sprintf("Failed to use conda environment %s: %s", env_name, e$message))
        FALSE
      }))
    }
  }

  # 如果沒有 conda 環境，使用系統 Python
  packageStartupMessage("\nUsing system Python...")
  return(tryCatch({
    python_path <- Sys.which("python3")
    if (python_path == "") python_path <- Sys.which("python")

    if (python_path != "" && file.exists(python_path)) {
      reticulate::use_python(python_path, required = TRUE)
      if (!reticulate::py_module_available("flair")) {
        packageStartupMessage("Installing flair in system Python...")
        install_dependencies(NULL)
      }
      TRUE
    } else {
      packageStartupMessage("No Python installation found")
      FALSE
    }
  }, error = function(e) {
    packageStartupMessage(sprintf("Error using system Python: %s", e$message))
    FALSE
  }))
}
# check_conda_env <- function(show_status = FALSE) {
#   # 清除任何現有的 Python 設定
#   try({
#     reticulate::py_clear_config()
#     reticulate::use_python(NULL)
#   }, silent = TRUE)
#
#   # 清除環境變數
#   Sys.unsetenv("RETICULATE_PYTHON")
#   Sys.unsetenv("VIRTUALENV")
#   Sys.unsetenv("PYTHONHOME")
#   Sys.unsetenv("PYTHONPATH")
#
#   # 檢查 conda
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#   # 顯示 conda 狀態
#   if (show_status) {
#     if (conda_available$status) {
#       print_status("Conda", conda_available$path, TRUE)
#     } else {
#       print_status("Conda", NULL, FALSE, "Conda not found")
#     }
#   }
#
#   if (conda_available$status) {
#     # 獲取所有 conda 環境
#     conda_envs <- reticulate::conda_list()
#
#     # 檢查 flair_env
#     if ("flair_env" %in% conda_envs$name) {
#       flair_envs <- conda_envs[conda_envs$name == "flair_env", ]
#
#       if (nrow(flair_envs) > 1) {
#         packageStartupMessage("\nMultiple flair_env environments found:")
#         for (i in seq_len(nrow(flair_envs))) {
#           packageStartupMessage(sprintf("%d. %s", i, flair_envs$python[i]))
#         }
#
#         # 優先選擇 miniconda 環境
#         miniconda_env <- grep("miniconda", flair_envs$python, value = TRUE)
#
#         if (length(miniconda_env) > 0) {
#           packageStartupMessage("\nSelecting miniconda environment")
#           selected_env <- miniconda_env[1]
#         } else {
#           packageStartupMessage("\nNo miniconda environment found, using first available")
#           selected_env <- flair_envs$python[1]
#         }
#
#         packageStartupMessage(sprintf("Using environment: %s", selected_env))
#
#         if (file.exists(selected_env)) {
#           return(tryCatch({
#             # 直接使用 Python 路徑
#             reticulate::use_python(selected_env, required = TRUE)
#             if (!reticulate::py_module_available("flair")) {
#               packageStartupMessage("Installing flair in selected environment...")
#               install_dependencies("flair_env")
#             }
#             TRUE
#           }, error = function(e) {
#             packageStartupMessage(sprintf("Error using environment: %s", e$message))
#             FALSE
#           }))
#         }
#       } else {
#         # 只有一個 flair_env
#         env_path <- flair_envs$python[1]
#         if (file.exists(env_path)) {
#           packageStartupMessage(sprintf("Using single flair_env at: %s", env_path))
#           return(tryCatch({
#             reticulate::use_python(env_path, required = TRUE)
#             if (!reticulate::py_module_available("flair")) {
#               packageStartupMessage("Installing flair...")
#               install_dependencies("flair_env")
#             }
#             TRUE
#           }, error = function(e) {
#             packageStartupMessage(sprintf("Error using environment: %s", e$message))
#             FALSE
#           }))
#         }
#       }
#     }
#   }
#
#   # 如果以上都失敗，使用系統 Python
#   packageStartupMessage("\nUsing system Python...")
#   return(tryCatch({
#     python_path <- Sys.which("python3")
#     if (python_path == "") python_path <- Sys.which("python")
#
#     if (python_path != "" && file.exists(python_path)) {
#       reticulate::use_python(python_path, required = TRUE)
#       if (!reticulate::py_module_available("flair")) {
#         packageStartupMessage("Installing flair in system Python...")
#         install_dependencies(NULL)
#       }
#       TRUE
#     } else {
#       packageStartupMessage("No Python installation found")
#       FALSE
#     }
#   }, error = function(e) {
#     packageStartupMessage(sprintf("Error using system Python: %s", e$message))
#     FALSE
#   }))
# }

# check_conda_env <- function(show_status = FALSE) {
#   # 獲取作業系統類型
#   os_type <- Sys.info()["sysname"]
#
#   # 設定作業系統特定的路徑模式
#   path_pattern <- switch(os_type,
#                          "Windows" = list(
#                            separator = "\\",
#                            miniconda = "\\\\miniconda",
#                            conda = "\\\\(miniforge|anaconda)",
#                            python_names = c("python.exe", "python3.exe")
#                          ),
#                          list(
#                            separator = "/",
#                            miniconda = "/miniconda",
#                            conda = "/(miniforge|anaconda)",
#                            python_names = c("python3", "python")
#                          )
#   )
#
#   # 1. 檢查 conda 是否可用
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#   # 顯示 conda 狀態
#   if (show_status) {
#     if (conda_available$status) {
#       print_status("Conda", conda_available$path, TRUE)
#     } else {
#       print_status("Conda", NULL, FALSE, "Conda not found")
#     }
#   }
#
#   if (conda_available$status) {
#     # 2. 獲取所有 conda 環境
#     conda_envs <- reticulate::conda_list()
#
#     # 3. 檢查 flair_env
#     if ("flair_env" %in% conda_envs$name) {
#       # 找出所有 flair_env 實例
#       flair_envs <- conda_envs[conda_envs$name == "flair_env", ]
#
#       if (nrow(flair_envs) > 1) {
#         message("\nMultiple flair_env environments found:")
#         for (i in seq_len(nrow(flair_envs))) {
#           message(sprintf("%d. %s", i, flair_envs$python[i]))
#         }
#
#         # 優先選擇 miniconda 環境，考慮作業系統特定路徑
#         miniconda_env <- grep(path_pattern$miniconda,
#                               flair_envs$python,
#                               value = TRUE,
#                               ignore.case = TRUE)
#         conda_env <- grep(path_pattern$conda,
#                           flair_envs$python,
#                           value = TRUE,
#                           ignore.case = TRUE)
#
#         # 設定優先順序：miniconda > conda
#         selected_env <- if (length(miniconda_env) > 0) {
#           message("\nSelecting miniconda environment")
#           miniconda_env[1]
#         } else if (length(conda_env) > 0) {
#           message("\nSelecting conda environment")
#           conda_env[1]
#         } else {
#           message("\nSelecting first available environment")
#           flair_envs$python[1]
#         }
#
#         message(sprintf("Using environment: %s", selected_env))
#
#         if (file.exists(selected_env)) {
#           return(tryCatch({
#             reticulate::use_python(selected_env, required = TRUE)
#             if (!reticulate::py_module_available("flair")) {
#               message("Installing flair in selected environment...")
#               install_dependencies("flair_env")
#             }
#             TRUE
#           }, error = function(e) {
#             message(sprintf("Error using environment: %s", e$message))
#             FALSE
#           }))
#         }
#       } else {
#         # 只有一個 flair_env
#         env_path <- flair_envs$python[1]
#         if (file.exists(env_path)) {
#           message(sprintf("Using single flair_env at: %s", env_path))
#           return(tryCatch({
#             reticulate::use_python(env_path, required = TRUE)
#             if (!reticulate::py_module_available("flair")) {
#               message("Installing flair...")
#               install_dependencies("flair_env")
#             }
#             TRUE
#           }, error = function(e) {
#             message(sprintf("Error using environment: %s", e$message))
#             FALSE
#           }))
#         }
#       }
#     }
#
#     # 4. 如果沒有可用的 flair_env，嘗試其他環境
#     if (nrow(conda_envs) > 0) {
#       message("\nNo suitable flair_env found. Checking other environments...")
#
#       # 優先選擇 miniconda 環境，考慮作業系統特定路徑
#       all_envs <- conda_envs$python
#       miniconda_env <- grep(path_pattern$miniconda, all_envs, value = TRUE, ignore.case = TRUE)
#       conda_env <- grep(path_pattern$conda, all_envs, value = TRUE, ignore.case = TRUE)
#
#       try_envs <- c(miniconda_env, conda_env, all_envs)
#       try_envs <- unique(try_envs)  # 移除重複項
#
#       for (env_path in try_envs) {
#         if (file.exists(env_path)) {
#           message(sprintf("\nTrying environment: %s", env_path))
#           result <- tryCatch({
#             reticulate::use_python(env_path, required = TRUE)
#             if (!reticulate::py_module_available("flair")) {
#               message("Installing flair...")
#               install_dependencies(conda_envs$name[conda_envs$python == env_path])
#             }
#             TRUE
#           }, error = function(e) FALSE)
#
#           if (result) return(TRUE)
#         }
#       }
#     }
#   }
#
#   # 5. 使用系統 Python 作為最後選項
#   message("\nAttempting to use system Python...")
#   return(tryCatch({
#     # 根據作業系統嘗試不同的 Python 命令
#     python_path <- NULL
#     for (cmd in path_pattern$python_names) {
#       path <- Sys.which(cmd)
#       if (path != "" && file.exists(path)) {
#         python_path <- path
#         break
#       }
#     }
#
#     if (!is.null(python_path)) {
#       message(sprintf("Found system Python: %s", python_path))
#       reticulate::use_python(python_path, required = TRUE)
#       if (!reticulate::py_module_available("flair")) {
#         message("Installing flair in system Python...")
#         install_dependencies(NULL)
#       }
#       TRUE
#     } else {
#       message("No suitable Python installation found")
#       FALSE
#     }
#   }, error = function(e) {
#     message(sprintf("Error using system Python: %s", e$message))
#     FALSE
#   }))
# }


#' Initialize Required Modules
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

# Package Initialization ----------------------------------------------

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
.onAttach <- function(libname, pkgname) {
  # 儲存原始環境設定
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  # 在函數結束時恢復設定
  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    # 清除環境變數
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # 顯示系統資訊
    sys_info <- get_system_info()
    packageStartupMessage("\nEnvironment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # 檢查 conda
    conda_available <- tryCatch({
      conda_bin <- reticulate::conda_binary()
      list(status = TRUE, path = conda_bin)
    }, error = function(e) {
      list(status = FALSE, error = e$message)
    })

    if (conda_available$status) {
      print_status("Conda", conda_available$path, TRUE)

      # 直接檢查所有 flair_env
      conda_envs <- reticulate::conda_list()
      flair_envs <- conda_envs[conda_envs$name == "flair_env", ]

      if (nrow(flair_envs) > 0) {
        # 優先使用 miniconda 路徑
        miniconda_path <- grep("miniconda", flair_envs$python, value = TRUE)
        if (length(miniconda_path) > 0 && file.exists(miniconda_path[1])) {
          python_path <- miniconda_path[1]
        } else {
          python_path <- flair_envs$python[1]  # 使用第一個可用的
        }

        if (file.exists(python_path)) {
          packageStartupMessage(sprintf("Using Python: %s", python_path))
          reticulate::use_python(python_path, required = TRUE)
        }
      }
    }

    # 檢查 Python 設定
    config <- reticulate::py_config()
    python_version <- as.character(config$version)
    print_status("Python", python_version, TRUE)
    packageStartupMessage("")

    # 初始化模組
    init_result <- initialize_modules()
    if (init_result$status) {
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # GPU 檢查邏輯
      cuda_info <- init_result$device$cuda
      mps_available <- init_result$device$mps

      if (!is.null(cuda_info$available) && cuda_info$available) {
        gpu_name <- if (!is.null(cuda_info$device_name)) {
          paste("CUDA", cuda_info$device_name)
        } else {
          "CUDA"
        }
        print_status("GPU", gpu_name, TRUE)
      } else if (!is.null(mps_available) && mps_available) {
        print_status("GPU", "Mac MPS", TRUE)
      } else {
        print_status("GPU", "CPU Only", FALSE)
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
    }
  }, error = function(e) {
    message("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}

# .onAttach <- function(libname, pkgname) {
#   # 儲存原始環境設定
#   original_python <- Sys.getenv("RETICULATE_PYTHON")
#   original_virtualenv <- Sys.getenv("VIRTUALENV")
#
#   # 在函數結束時恢復設定
#   on.exit({
#     if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
#     if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
#   })
#
#   tryCatch({
#     # 清除環境變數
#     Sys.unsetenv("RETICULATE_PYTHON")
#     Sys.unsetenv("VIRTUALENV")
#     Sys.unsetenv("PYTHON_PATH")
#     options(reticulate.python.initializing = TRUE)
#
#     # 顯示系統資訊
#     sys_info <- get_system_info()
#     message("\nEnvironment Information:")
#     message(sprintf("OS: %s (%s)",
#                    as.character(sys_info$name),
#                    as.character(sys_info$version)))
#
#     # 作業系統特定路徑設定
#     os_type <- Sys.info()["sysname"]
#     known_working_paths <- switch(os_type,
#       "Windows" = c(
#         file.path(Sys.getenv("USERPROFILE"), "Python311", "python.exe"),
#         file.path(Sys.getenv("ProgramFiles"), "Python311", "python.exe"),
#         Sys.which("python.exe")
#       ),
#       "Linux" = c(
#         "/usr/bin/python3",
#         "/usr/local/bin/python3",
#         Sys.which("python3"),
#         Sys.which("python")
#       ),
#       # macOS (Darwin)
#       c(
#         "/usr/local/bin/python3",
#         "/opt/homebrew/bin/python3",
#         "/usr/bin/python3",
#         Sys.which("python3"),
#         Sys.which("python")
#       )
#     )
#
#     # 檢查 conda
#     conda_available <- tryCatch({
#       conda_bin <- reticulate::conda_binary()
#       list(status = TRUE, path = conda_bin)
#     }, error = function(e) {
#       list(status = FALSE, error = e$message)
#     })
#
#     if (conda_available$status) {
#       print_status("Conda", conda_available$path, TRUE)
#
#       # 檢查 conda 環境
#       conda_envs <- reticulate::conda_list()
#       has_flair_env <- "flair_env" %in% conda_envs$name
#
#       if (has_flair_env) {
#         message("Found flair_env, attempting to use it...")
#         reticulate::use_condaenv("flair_env", required = TRUE)
#         if (!reticulate::py_module_available("flair")) {
#           message("Installing flair in existing flair_env...")
#           install_dependencies("flair_env")
#         }
#       } else if (nrow(conda_envs) > 0) {
#         env_name <- conda_envs$name[1]
#         message(sprintf("Using conda environment: %s", env_name))
#         reticulate::use_condaenv(env_name, required = TRUE)
#         if (!reticulate::py_module_available("flair")) {
#           message(sprintf("Installing flair in %s...", env_name))
#           install_dependencies(env_name)
#         }
#       }
#     } else {
#       # 使用系統 Python
#       python_found <- FALSE
#       for (python_path in known_working_paths) {
#         if (file.exists(python_path)) {
#           tryCatch({
#             reticulate::use_python(python_path, required = TRUE)
#             config <- reticulate::py_config()
#             python_version <- as.character(config$version)
#
#             if (!reticulate::py_module_available("flair")) {
#               message("Installing flair in system Python...")
#               install_dependencies(NULL)
#             }
#
#             print_status("Python", python_version, TRUE)
#             message(sprintf("Using Python: %s", python_path))
#             message("")
#
#             python_found <- TRUE
#             break
#           }, error = function(e) NULL)
#         }
#       }
#
#       if (!python_found) {
#         message("No suitable Python environment found.")
#         return(invisible(NULL))
#       }
#     }
#
#     # 初始化模組
#     init_result <- initialize_modules()
#     if (init_result$status) {
#       print_status("PyTorch", init_result$versions$torch, TRUE)
#       print_status("Transformers", init_result$versions$transformers, TRUE)
#       print_status("Flair NLP", init_result$versions$flair, TRUE)
#
#       # GPU 檢查
#       cuda_info <- init_result$device$cuda
#       mps_available <- init_result$device$mps
#
#       if (!is.null(cuda_info$available) && cuda_info$available) {
#         gpu_name <- if (!is.null(cuda_info$device_name)) {
#           paste("CUDA", cuda_info$device_name)
#         } else {
#           "CUDA"
#         }
#         print_status("GPU", gpu_name, TRUE)
#       } else if (!is.null(mps_available) && mps_available) {
#         print_status("GPU", "Mac MPS", TRUE)
#       } else {
#         print_status("GPU", "CPU Only", FALSE)
#       }
#
#       # 歡迎訊息
#       msg <- sprintf(
#         "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
#         .pkgenv$colors$bold, .pkgenv$colors$blue,
#         .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
#         .pkgenv$colors$bold, .pkgenv$colors$yellow,
#         init_result$versions$flair,
#         .pkgenv$colors$reset, .pkgenv$colors$reset_bold
#       )
#       message(msg)
#     }
#   }, error = function(e) {
#     message("Error during initialization: ", as.character(e$message))
#   }, finally = {
#     options(reticulate.python.initializing = FALSE)
#   })
#
#   invisible(NULL)
# }
#' #' @noRd
#' .onAttach <- function(libname, pkgname) {
#'   # 儲存原始環境設定
#'   original_python <- Sys.getenv("RETICULATE_PYTHON")
#'   original_virtualenv <- Sys.getenv("VIRTUALENV")
#'
#'   # 在函數結束時恢復原始設定
#'   on.exit({
#'     if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
#'     if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
#'   })
#'
#'   tryCatch({
#'     # 清除 Python 相關設定
#'     Sys.unsetenv("RETICULATE_PYTHON")
#'     Sys.unsetenv("VIRTUALENV")
#'     options(reticulate.python.initializing = TRUE)
#'
#'     # 顯示系統資訊
#'     sys_info <- get_system_info()
#'     message("\nEnvironment Information:")
#'     message(sprintf("OS: %s (%s)",
#'                     as.character(sys_info$name),
#'                     as.character(sys_info$version)))
#'
#'     # 檢查 conda
#'     conda_available <- tryCatch({
#'       conda_bin <- reticulate::conda_binary()
#'       list(status = TRUE, path = conda_bin)
#'     }, error = function(e) {
#'       list(status = FALSE, error = e$message)
#'     })
#'
#'     if (conda_available$status) {
#'       print_status("Conda", conda_available$path, TRUE)
#'     }
#'
#'     # 優先檢查已知工作的 Python 路徑
#'     known_working_paths <- c(
#'       Sys.which("python3"),
#'       Sys.which("python")
#'     )
#'
#'     python_found <- FALSE
#'     for (python_path in known_working_paths) {
#'       if (file.exists(python_path)) {
#'         tryCatch({
#'           reticulate::use_python(python_path, required = TRUE)
#'           config <- reticulate::py_config()
#'           python_version <- as.character(config$version)
#'           print_status("Python", python_version, TRUE)
#'           message(sprintf("Using Python: %s", python_path))
#'           message("")
#'           python_found <- TRUE
#'           break
#'         }, error = function(e) NULL)
#'       }
#'     }
#'
#'     if (!python_found) {
#'       message("No suitable Python environment found.")
#'       return(invisible(NULL))
#'     }
#'
#'     # 初始化模組
#'     init_result <- initialize_modules()
#'     if (init_result$status) {
#'       print_status("PyTorch", init_result$versions$torch, TRUE)
#'       print_status("Transformers", init_result$versions$transformers, TRUE)
#'       print_status("Flair NLP", init_result$versions$flair, TRUE)
#'
#'       # GPU 檢查邏輯
#'       cuda_info <- init_result$device$cuda
#'       mps_available <- init_result$device$mps
#'
#'       # 檢查 GPU 狀態
#'       if (!is.null(cuda_info$available) && cuda_info$available) {
#'         # 如果有 CUDA GPU
#'         gpu_name <- if (!is.null(cuda_info$device_name)) {
#'           paste("CUDA", cuda_info$device_name)
#'         } else {
#'           "CUDA"
#'         }
#'         print_status("GPU", gpu_name, TRUE)
#'       } else if (!is.null(mps_available) && mps_available) {
#'         # 如果有 Mac MPS
#'         print_status("GPU", "Mac MPS", TRUE)
#'       } else {
#'         # 如果沒有 GPU
#'         print_status("GPU", "CPU Only", FALSE)
#'       }
#'
#'       # 歡迎訊息
#'       msg <- sprintf(
#'         "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
#'         .pkgenv$colors$bold, .pkgenv$colors$blue,
#'         .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
#'         .pkgenv$colors$bold, .pkgenv$colors$yellow,
#'         init_result$versions$flair,
#'         .pkgenv$colors$reset, .pkgenv$colors$reset_bold
#'       )
#'       message(msg)
#'     }
#'   }, error = function(e) {
#'     message("Error during initialization: ", as.character(e$message))
#'   }, finally = {
#'     options(reticulate.python.initializing = FALSE)
#'   })
#'
#'   invisible(NULL)
#' }
