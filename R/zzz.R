#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

### Add gensim version to package constants ------------------------------------
.pkgenv$package_constants <- list(
  python_min_version = "3.9",
  python_max_version = "3.12",
  numpy_version = "1.26.4",
  scipy_version = "1.12.0",
  flair_min_version = "0.11.3",
  torch_version = "2.2.0",
  transformers_version = "4.37.2",
  gensim_version = "4.0.0"  # Add gensim version
)

### ANSI Color Codes -----------------------------------------------------------
.pkgenv$colors <- list(
  green = "\033[32m",
  red = "\033[31m",
  blue = "\033[34m",
  yellow = "\033[33m",
  reset = "\033[39m",
  bold = "\033[1m",
  reset_bold = "\033[22m"
)

### Initialize Module Storage --------------------------------------------------
.pkgenv$modules <- list(
  flair = NULL,
  flair_embeddings = NULL,
  torch = NULL
)

# Utilities  -------------------------------------------------------------------

### Embeddings Verification ---------------------------------------------------
#' @title Embeddings Verification
#' @noRd
verify_embeddings <- function(quiet = FALSE) {
  tryCatch({
    if(!quiet) packageStartupMessage("Verifying word embeddings support...")
    gensim <- reticulate::import("gensim.models")
    if(!quiet) packageStartupMessage("Word embeddings support verified")
    TRUE
  }, error = function(e) {
    if(!quiet) packageStartupMessage(
      sprintf("%sWarning: Word embeddings support not available%s",
              .pkgenv$colors$yellow,
              .pkgenv$colors$reset))
    FALSE
  })
}


### Check Docker ---------------------------------------------------------------
#' @title Check if running in Docker
#'
#' @noRd
is_docker <- function() {
  # First check for /.dockerenv file
  if (file.exists("/.dockerenv")) {
    return(TRUE)
  }


  # Then check cgroup on Linux systems only
  if (Sys.info()["sysname"] == "Linux") {
    tryCatch({
      if (file.exists("/proc/1/cgroup")) {
        cgroup_content <- readLines("/proc/1/cgroup", n = 1)
        return(grepl("docker", cgroup_content))
      }
    }, error = function(e) {
      return(FALSE)
    })
  }
  return(FALSE)
}


### Check Python Version -------------------------------------------------------
#' @title Compare Version Numbers
#' @param version Character string of version number to check
#' @return logical TRUE if version is in supported range
#' @noRd
check_python_version <- function(version) {
  if (!is.character(version)) {
    return(FALSE)
  }
  min_v <- .pkgenv$package_constants$python_min_version
  max_v <- .pkgenv$package_constants$python_max_version


  # Improved version parsing
  parse_version <- function(v) {
    ver_parts <- strsplit(v, "\\.")[[1]]
    if (length(ver_parts) < 2) return(c(0, 0))
    c(as.numeric(ver_parts[1]), as.numeric(ver_parts[2]))
  }


  # Handle potential errors
  tryCatch({
    ver <- parse_version(version)
    min_ver <- parse_version(min_v)
    max_ver <- parse_version(max_v)


    if (is.na(ver[1]) || is.na(ver[2])) return(FALSE)
    if (ver[1] < min_ver[1] || ver[1] > max_ver[1]) return(FALSE)
    if (ver[1] == min_ver[1] && ver[2] < min_ver[2]) return(FALSE)
    if (ver[1] == max_ver[1] && ver[2] > max_ver[2]) return(FALSE)


    return(TRUE)
  }, error = function(e) {
    return(FALSE)
  })
}


### Print Messages -------------------------------------------------------------
#' @title Print Formatted Messages
#' @param component Component name to display
#' @param version Version string to display
#' @param status Boolean indicating pass/fail status
#' @param extra_message Optional additional message
#' @noRd
print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  symbol <- if (status) "\u2713" else "\u2717"  # ✓ or ✗
  color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red


  formatted_component <- sprintf("%-20s", component)


  # Basic message
  msg <- sprintf("%s %s%s%s  %s",
                 formatted_component,
                 color,
                 symbol,
                 .pkgenv$colors$reset,
                 if(!is.null(version)) version else "")


  # Version-specific warnings
  if (component == "Python") {
    ver_num <- as.numeric(strsplit(version, "\\.")[[1]][1:2])
    ver_major <- ver_num[1]
    ver_minor <- ver_num[2]


    if (ver_major == 3 && ver_minor < 9) {
      msg <- paste0(msg, sprintf(
        "\n%sWarning: Python 3.8 will be deprecated in future Flair NLP versions.%s\n%sPlease consider upgrading to Python 3.9 or later.%s",
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset,
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset
      ))
    } else if (ver_major == 3 && ver_minor >= 13) {
      msg <- paste0(msg, sprintf(
        "\n%sWarning: Python 3.13+ has not been fully tested with current Flair NLP and compatible PyTorch versions.%s\n%sStability issues may occur. Python 3.9-3.12 is recommended for optimal compatibility.%s",
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset,
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset
      ))
    }


    if (!status) {
      msg <- paste0(msg, sprintf(
        "\n%sRecommended Python version: %s - %s for optimal stability%s",
        .pkgenv$colors$yellow,
        .pkgenv$package_constants$python_min_version,
        .pkgenv$package_constants$python_max_version,
        .pkgenv$colors$reset
      ))
    }
  }


  packageStartupMessage(msg)
  if (!is.null(extra_message)) {
    packageStartupMessage(extra_message)
  }
}


### Get System Information -----------------------------------------------------
#' @title Get System Information
#'
#' @return List containing system name and version
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


# Install Dependencies ---------------------------------------------------------
#' @title Install Required Dependencies
#'
#' @param venv Virtual environment name or NULL for system Python
#' @param max_retries Maximum number of retry attempts for failed installations
#' @param quiet Suppress status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd

install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  # Helper functions
  log_msg <- function(msg, is_error = FALSE) {
    if (!quiet) {
      if (is_error) {
        packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
      } else {
        packageStartupMessage(msg)
      }
    }
  }

  # Docker installation function
  docker_install <- function(pkg_req) {
    # 特別處理 sentencepiece
    if (grepl("sentencepiece", pkg_req)) {
      # 先安裝編譯工具
      system2("sudo", c("apt-get", "update"))
      system2("sudo", c("apt-get", "install", "-y",
                        "pkg-config", "git", "cmake",
                        "build-essential", "g++"))
    }

    # 首先嘗試使用 sudo pip install
    result <- system2("sudo", c("/opt/venv/bin/pip", "install",
                                "--force-reinstall",
                                "--no-deps",
                                pkg_req))

    if (result != 0) {
      # 如果失敗，嘗試使用 python -m pip
      result <- system2("sudo", c("python3", "-m", "pip", "install",
                                  "--force-reinstall",
                                  "--no-deps",
                                  pkg_req))
    }

    return(result == 0)
  }

  # Check package version
  check_version <- function(pkg_name, required_version) {
    tryCatch({
      if(required_version == "") return(TRUE)
      cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
      installed <- reticulate::py_eval(cmd)
      if(is.null(installed)) return(FALSE)
      package_version(installed) >= package_version(required_version)
    }, error = function(e) FALSE)
  }

  # Parse requirement function
  parse_requirement <- function(pkg_req) {
    if(grepl(">=|==|<=", pkg_req)) {
      parts <- strsplit(pkg_req, ">=|==|<=")[[1]]
      list(name = trimws(parts[1]), version = trimws(parts[2]))
    } else {
      list(name = trimws(pkg_req), version = "")
    }
  }

  # Retry installation with backoff
  retry_install <- function(install_fn, pkg_name) {
    for (i in 1:max_retries) {
      tryCatch({
        if (i > 1) log_msg(sprintf("Retry attempt %d/%d for %s", i, max_retries, pkg_name))
        result <- install_fn()
        return(list(success = TRUE))
      }, error = function(e) {
        if (i == max_retries) {
          return(list(
            success = FALSE,
            error = sprintf("Failed to install %s: %s", pkg_name, e$message)
          ))
        }
        Sys.sleep(2 ^ i)
        NULL
      })
    }
  }

  # Get installation sequence
  get_install_sequence <- function() {
    list(
      torch = list(
        name = "PyTorch",
        packages = c(
          sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
          "torchvision"
        )
      ),
      core = list(
        name = "Core dependencies",
        packages = c(
          sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
          sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
          sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
        )
      ),
      flair = list(
        name = "Flair Base",
        packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
      )
    )
  }

  # Main installation process
  tryCatch({
    # Check system type and set environment variables
    is_arm_mac <- Sys.info()["sysname"] == "Darwin" &&
      Sys.info()["machine"] == "arm64"
    if(is_arm_mac) {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = "1")
    }

    in_docker <- is_docker()
    env_msg <- if (!is.null(venv)) {
      sprintf(" in %s", venv)
    } else {
      if (in_docker) " in Docker environment" else ""
    }

    log_msg(sprintf("Checking dependencies%s...", env_msg))
    install_sequence <- get_install_sequence()

    if (in_docker) {
      for (pkg in install_sequence) {
        log_msg(sprintf("Checking %s...", pkg$name))
        for (pkg_req in pkg$packages) {
          req <- parse_requirement(pkg_req)
          if (!check_version(req$name, req$version)) {
            log_msg(sprintf("Installing %s...", pkg_req))
            result <- retry_install(function() {
              docker_install(pkg_req)
            }, pkg_req)
            if (!result$success) {
              log_msg(result$error, TRUE)
              return(FALSE)
            }
          } else {
            log_msg(sprintf("%s is already installed with required version", req$name))
          }
        }
      }
    } else {
      for (pkg in install_sequence) {
        log_msg(sprintf("Checking %s...", pkg$name))
        for (pkg_req in pkg$packages) {
          req <- parse_requirement(pkg_req)
          if (!check_version(req$name, req$version)) {
            log_msg(sprintf("Installing %s...", pkg_req))
            result <- retry_install(function() {
              reticulate::py_install(
                packages = pkg_req,
                pip = TRUE,
                envname = venv,
                ignore_installed = FALSE
              )
            }, pkg_req)
            if (!result$success) {
              log_msg(result$error, TRUE)
              return(FALSE)
            }
          } else {
            log_msg(sprintf("%s is already installed with required version", req$name))
          }
        }
      }
    }

    log_msg("All dependencies are installed and up to date")
    return(TRUE)

  }, error = function(e) {
    log_msg(sprintf(
      "Error checking/installing dependencies: %s\nPlease check:\n1. Internet connection\n2. Pip availability\n3. Python environment permissions",
      e$message
    ), TRUE)
    return(FALSE)
  })
}



## Check and Setup Conda -------------------------------------------------------
#' @title Check and setup conda environment
#' @param show_status Show status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
check_conda_env <- function(show_status = FALSE, missing_modules = NULL) {
  # 更新驗證函數以檢查所有必要模組
  verify_modules <- function(python_path) {
    tryCatch({
      reticulate::use_python(python_path, required = TRUE)
      # 檢查所有必要模組
      required_modules <- c("torch", "transformers", "flair")
      missing <- character(0)
      for (module in required_modules) {
        if (!reticulate::py_module_available(module)) {
          missing <- c(missing, module)
        }
      }
      list(status = length(missing) == 0, missing = missing)
    }, error = function(e) {
      list(status = FALSE, missing = required_modules)
    })
  }

  # 安裝依賴的輔助函數
  install_dependencies <- function(env_name = NULL) {
    packageStartupMessage("Installing required packages...")

    # 定義基本依賴包
    base_packages <- c(
      "numpy==1.26.4",
      "torch>=2.0.0",
      "transformers>=4.30.0",
      "flair>=0.11.3",
      "scipy==1.12.0"
      # "sentencepiece>=0.1.99"
    )

    # 如果提供了特定的缺失模組，只安裝那些模組
    if (!is.null(missing_modules) && length(missing_modules) > 0) {
      packages_to_install <- base_packages[sapply(missing_modules, function(m) {
        any(grepl(m, base_packages, ignore.case = TRUE))
      })]
      if (length(packages_to_install) == 0) {
        packages_to_install <- base_packages  # 如果沒找到對應的包，安裝所有基本包
      }
    } else {
      packages_to_install <- base_packages
    }

    tryCatch({
      reticulate::py_install(
        packages = packages_to_install,
        envname = env_name,
        pip = TRUE,
        method = "auto"
      )
      TRUE
    }, error = function(e) {
      packageStartupMessage(sprintf("Installation failed: %s", e$message))
      FALSE
    })
  }

  # Docker 環境檢查
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
      # 檢查必要模組
      verify_result <- verify_modules(docker_python)
      if (!verify_result$status) {
        # 在 Docker 環境中直接安裝
        success <- install_dependencies(NULL)
        if (!success) {
          return(FALSE)
        }
      }
      return(TRUE)
    }
  }

  # 檢查現有 Python 環境
  current_python <- tryCatch({
    config <- reticulate::py_config()
    verify_result <- verify_modules(config$python)
    list(
      status = verify_result$status,
      path = config$python,
      missing = verify_result$missing
    )
  }, error = function(e) {
    list(status = FALSE, missing = character(0))
  })

  if (current_python$status) {
    packageStartupMessage(sprintf("Using existing Python: %s", current_python$path))
    return(TRUE)
  }

  # Conda 環境檢查
  if (!is.null(missing_modules)) {
    packageStartupMessage(sprintf("Missing modules detected: %s",
                                  paste(missing_modules, collapse = ", ")))
  }

  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (conda_available$status) {
    if (show_status) print_status("Conda", conda_available$path, TRUE)

    # 檢查或創建 flair_env
    if ("flair_env" %in% reticulate::conda_list()$name) {
      packageStartupMessage("Using existing flair_env conda environment")
      reticulate::use_condaenv("flair_env")
    } else {
      packageStartupMessage("Creating new flair_env conda environment...")
      reticulate::conda_create("flair_env", python_version = "3.9")
      reticulate::use_condaenv("flair_env")
    }

    # 安裝缺失的包
    success <- install_dependencies("flair_env")
    return(success)
  }

  # 使用系統 Python
  packageStartupMessage("Using system Python...")
  python_path <- Sys.which("python3")
  if (python_path == "") python_path <- Sys.which("python")

  if (python_path != "" && file.exists(python_path)) {
    verify_result <- verify_modules(python_path)
    if (!verify_result$status) {
      success <- install_dependencies(NULL)
      return(success)
    }
    return(TRUE)
  }

  packageStartupMessage("No suitable Python installation found")
  return(FALSE)
}


## Initialize Required Modules -------------------------------------------------
#' @title Initialize Required Modules
#'
#' @return List containing version information and initialization status
#' @noRd
initialize_modules <- function() {
  # 定義必要的模組
  required_modules <- c("torch", "transformers", "flair")
  missing_modules <- character(0)

  # 先檢查每個模組是否可用
  for (module in required_modules) {
    if (!reticulate::py_module_available(module)) {
      missing_modules <- c(missing_modules, module)
    }
  }

  # 如果有缺失的模組，直接返回狀態
  if (length(missing_modules) > 0) {
    return(list(
      status = FALSE,
      error = sprintf("Missing required modules: %s",
                      paste(missing_modules, collapse = ", ")),
      missing = missing_modules
    ))
  }

  # 如果所有模組都存在，進行詳細檢查
  tryCatch({
    # 載入模組
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)

    # 獲取版本信息
    torch_version <- reticulate::py_get_attr(torch, "__version__")
    transformers_version <- reticulate::py_get_attr(transformers, "__version__")
    flair_version <- reticulate::py_get_attr(flair, "__version__")

    # GPU 支援檢查
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

    # MPS 支援檢查 (for Apple Silicon)
    mps_available <- if(Sys.info()["sysname"] == "Darwin") {
      torch$backends$mps$is_available()
    } else FALSE

    # 儲存到 package environment
    .pkgenv$modules$flair <- flair
    .pkgenv$modules$torch <- torch

    # 返回完整狀態
    list(
      status = TRUE,
      versions = list(
        torch = torch_version,
        transformers = transformers_version,
        flair = flair_version
      ),
      device = list(
        cuda = cuda_info,
        mps = mps_available
      ),
      missing = character(0)  # 加入空的 missing 列表以保持一致性
    )
  }, error = function(e) {
    list(
      status = FALSE,
      error = e$message,
      missing = missing_modules
    )
  })
}
# initialize_modules <- function() {
#   tryCatch({
#     torch <- reticulate::import("torch", delay_load = TRUE)
#     transformers <- reticulate::import("transformers", delay_load = TRUE)
#     flair <- reticulate::import("flair", delay_load = TRUE)
#
#
#     torch_version <- reticulate::py_get_attr(torch, "__version__")
#     transformers_version <- reticulate::py_get_attr(transformers, "__version__")
#     flair_version <- reticulate::py_get_attr(flair, "__version__")
#
#
#     cuda_info <- list(
#       available = torch$cuda$is_available(),
#       device_name = if (torch$cuda$is_available()) {
#         tryCatch({
#           props <- torch$cuda$get_device_properties(0)
#           props$name
#         }, error = function(e) NULL)
#       } else NULL,
#       version = tryCatch(torch$version$cuda, error = function(e) NULL)
#     )
#
#
#     mps_available <- if(Sys.info()["sysname"] == "Darwin") {
#       torch$backends$mps$is_available()
#     } else FALSE
#
#
#     .pkgenv$modules$flair <- flair
#     .pkgenv$modules$torch <- torch
#
#
#     list(
#       versions = list(
#         torch = torch_version,
#         transformers = transformers_version,
#         flair = flair_version
#       ),
#       device = list(
#         cuda = cuda_info,
#         mps = mps_available
#       ),
#       status = TRUE
#     )
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
# }


# Package Initialization -------------------------------------------------------

## .onLoad ---------------------------------------------------------------------
#' @noRd
.onLoad <- function(libname, pkgname) {
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  if (is_docker()) {
    Sys.setenv(PYTHONNOUSERSITE = "1")
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      Sys.setenv(RETICULATE_PYTHON = docker_python)
    }
  }

  if (Sys.info()["sysname"] == "Darwin") {
    if (Sys.info()["machine"] == "arm64") {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    }
    Sys.setenv(OMP_NUM_THREADS = 1)
    Sys.setenv(MKL_NUM_THREADS = 1)
  }
  options(reticulate.prompt = FALSE)
}

## .onAttach -------------------------------------------------------------------
#' @noRd

.onAttach <- function(libname, pkgname) {
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")
  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    options(reticulate.python.initializing = TRUE)

    # 先檢查是否已經有可用的環境
    modules_available <- tryCatch({
      # 檢查核心模組是否已載入且可用
      torch_ok <- reticulate::py_module_available("torch")
      flair_ok <- reticulate::py_module_available("flair")
      transformers_ok <- reticulate::py_module_available("transformers")

      all(c(torch_ok, flair_ok, transformers_ok))
    }, error = function(e) FALSE)

    # 環境資訊
    sys_info <- get_system_info()
    packageStartupMessage("\n")
    packageStartupMessage("\nEnvironment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # 顯示 Python 環境信息
    current_env <- tryCatch({
      py_config <- reticulate::py_config()
      sprintf("\nPython Environment:\n  - Path: %s\n  - Type: %s\n  - Version: %s",
              py_config$python,
              if(!is.null(py_config$virtualenv)) "virtualenv" else
                if(!is.null(py_config$conda)) "conda" else "system",
              py_config$version)
    }, error = function(e) "\nUnable to detect Python environment")

    packageStartupMessage(current_env)

    # Docker 狀態檢查
    if (is_docker()) {
      print_status("Docker", "Enabled", TRUE)
    }

    if (modules_available) {
      # 如果模組已安裝，初始化並顯示資訊
      init_result <- initialize_modules()
      if (init_result$status) {
        # Python 版本檢查
        config <- reticulate::py_config()
        python_version <- as.character(config$version)
        print_status("Python", python_version, check_python_version(python_version))

        # 主要模組版本資訊
        packageStartupMessage("\nCore Modules Status:")
        print_status("PyTorch", init_result$versions$torch, TRUE)
        print_status("Transformers", init_result$versions$transformers, TRUE)
        print_status("Flair NLP", init_result$versions$flair, TRUE)

        # GPU 狀態檢查
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

        # Word Embeddings 狀態檢查
        if (verify_embeddings(quiet = TRUE)) {
          gensim_version <- tryCatch({
            gensim <- reticulate::import("gensim")
            reticulate::py_get_attr(gensim, "__version__")
          }, error = function(e) "Unknown")
          print_status("Word Embeddings", gensim_version, TRUE)
        } else {
          print_status("Word Embeddings", "Not Available", FALSE,
                       sprintf("Word embeddings feature is not detected.\n\nInstall with:\nIn R:\n  reticulate::py_install('flair[word-embeddings]', pip = TRUE)\n  system(paste(Sys.which('python3'), '-m pip install flair[word-embeddings]'))\n\nIn terminal:\n  pip install flair[word-embeddings]"))
        }
      }
    } else {
      # 如果模組未安裝，執行安裝流程
      packageStartupMessage("\nRequired modules not found. Installing dependencies...")
      env_setup <- check_conda_env()
      if (!env_setup) {
        packageStartupMessage("Failed to set up environment.")
        return(invisible(NULL))
      }

      # 重新初始化模組
      init_result <- initialize_modules()
    }

    # 歡迎訊息
    packageStartupMessage("\n")
    if (init_result$status) {
      msg <- sprintf(
        "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
        .pkgenv$colors$bold, .pkgenv$colors$blue,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
        .pkgenv$colors$bold, .pkgenv$colors$yellow,
        init_result$versions$flair,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold
      )
      packageStartupMessage(msg)
    }

  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}
