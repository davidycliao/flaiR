#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())


### Add Version Constants ------------------------------------------------------
.pkgenv$package_constants <- list(
  python_min_version = "3.9",
  python_max_version = "3.12",
  numpy_version = "1.26.4",
  scipy_version = "1.12.0",
  flair_min_version = "0.11.3",
  torch_version = "2.2.0",
  transformers_version = "4.37.2",
  gensim_version = "4.0.0",
  sentencepiece_version = "0.1.97",
  install_options = list(
    sentencepiece = "--no-deps"
  )
)

### Add installation state tracking
.pkgenv$installation_state <- new.env(parent = emptyenv())


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
### Embeddings Verification function -------------------------------------------
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

#' @title Check Docker
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


# Check Python Version ---------------------------------------------------------
#' @title Compare Version Numbers
#'
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


### Internal function for logging messages -------------------------------------
#' @title Internal function for logging messages
#'
#' @param msg Character string containing the message to log
#' @param is_error Logical indicating if this is an error message
#' @param show_status Logical indicating if status messages should be shown
#' @param quiet Logical indicating if non-error messages should be suppressed
#' @noRd
log_msg <- function(msg, is_error = FALSE, show_status = FALSE, quiet = FALSE) {
  # 顯示訊息的條件：
  # 1. 是錯誤訊息
  # 2. 在 show_status = TRUE 且不是 quiet 模式時顯示狀態訊息
  # 3. 匹配錯誤關鍵字且不是 quiet 模式
  should_show <- is_error ||
    (show_status && !quiet) ||
    (!quiet && grepl("error|Error|ERROR|failed|Failed|FAILED|Building wheel",
                     msg, ignore.case = TRUE))

  if (should_show) {
    packageStartupMessage(
      if (is_error) .pkgenv$colors$red else "",
      msg,
      if (is_error) .pkgenv$colors$reset else ""
    )
  }
}

### Print Messages -------------------------------------------------------------
#' @title Print Formatted Messages
#'
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


# Get System Information -----------------------------------------------------
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


#' Check if a Python package is installed and meets version requirements
#'
#' @param pkg_name Character string specifying the name of the Python package to check
#' @param required_version Character string specifying the minimum required version.
#'        Use empty string ("") to skip version checking.
#' @param quiet Logical indicating whether to suppress warning messages (default: FALSE)
#' @return Logical indicating whether the package is available and meets version requirements
#' @noRd
check_package_state <- function(pkg_name, required_version, quiet = FALSE) {
  tryCatch({
    # Special handling for sentencepiece on M1 Mac
    if (pkg_name == "sentencepiece" &&
        Sys.info()["sysname"] == "Darwin" &&
        Sys.info()["machine"] == "arm64") {
      if (reticulate::py_module_available("sentencepiece")) {
        return(TRUE)
      }
    }

    # Check cache state
    state_key <- paste0(pkg_name, "_", required_version)
    if (!is.null(.pkgenv$installation_state[[state_key]])) {
      return(TRUE)
    }

    # Check if module is available
    if (!reticulate::py_module_available(pkg_name)) {
      return(FALSE)
    }

    # Check version if required
    if (required_version != "") {
      # Use py_run_string instead of py_eval for more complex Python code
      version_check <- paste0(
        'import ', pkg_name, '; ',
        'version = getattr(', pkg_name, ', "__version__", None)'
      )

      installed <- reticulate::py_run_string(version_check)$get('version')

      if (is.null(installed)) return(FALSE)

      # Special handling for sentencepiece on M1 Mac
      if (pkg_name == "sentencepiece" &&
          Sys.info()["sysname"] == "Darwin" &&
          Sys.info()["machine"] == "arm64") {
        .pkgenv$installation_state[[state_key]] <- TRUE
        return(TRUE)
      }

      version_ok <- package_version(installed) >= package_version(required_version)
      if (version_ok) {
        .pkgenv$installation_state[[state_key]] <- TRUE
      }
      return(version_ok)
    }

    .pkgenv$installation_state[[state_key]] <- TRUE
    return(TRUE)

  }, error = function(e) {
    if (!quiet) {
      warning(sprintf("Error checking %s: %s", pkg_name, e$message))
    }
    return(FALSE)
  })
}

# check_package_state <- function(pkg_name, required_version, quiet = FALSE) {
#   tryCatch({
#     # 特殊处理 sentencepiece 在 M1 Mac 上的情况
#     if (pkg_name == "sentencepiece" &&
#         Sys.info()["sysname"] == "Darwin" &&
#         Sys.info()["machine"] == "arm64") {
#
#       # 如果已经有任何版本的 sentencepiece 存在，就认为它是可用的
#       if (reticulate::py_module_available("sentencepiece")) {
#         return(TRUE)
#       }
#     }
#
#     # 检查缓存状态
#     state_key <- paste0(pkg_name, "_", required_version)
#     if (!is.null(.pkgenv$installation_state[[state_key]])) {
#       return(TRUE)
#     }
#
#     # 尝试导入包
#     if (!reticulate::py_module_available(pkg_name)) {
#       return(FALSE)
#     }
#
#     # 检查版本
#     if (required_version != "") {
#       cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
#       installed <- reticulate::py_eval(cmd)
#       if (is.null(installed)) return(FALSE)
#
#       # 对于 sentencepiece，只要版本存在就接受
#       if (pkg_name == "sentencepiece" &&
#           Sys.info()["sysname"] == "Darwin" &&
#           Sys.info()["machine"] == "arm64") {
#         .pkgenv$installation_state[[state_key]] <- TRUE
#         return(TRUE)
#       }
#
#       version_ok <- package_version(installed) >= package_version(required_version)
#       if (version_ok) {
#         .pkgenv$installation_state[[state_key]] <- TRUE
#       }
#       return(version_ok)
#     }
#
#     .pkgenv$installation_state[[state_key]] <- TRUE
#     return(TRUE)
#   }, error = function(e) {
#     if (!quiet) {
#       warning(sprintf("Error checking %s: %s", pkg_name, e$message))
#     }
#     return(FALSE)
#   })
# }



# Install Required Dependencies -----------------------------------------------
#' @title Install Dependencies
#' @param venv Virtual environment name or NULL for system Python
#' @param max_retries Maximum number of retry attempts for failed installations
#' @param quiet Suppress status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  # Helper functions
  # log_msg <- function(msg, is_error = FALSE) {
  #   if (!quiet) {
  #     if (is_error) {
  #       packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
  #     } else {
  #       packageStartupMessage(msg)
  #     }
  #   }
  # }
    log_msg <- function(msg, is_error = FALSE) {
      if (!quiet) {
        # 只有在是錯誤信息時才顯示
        if (is_error || grepl("error|Error|ERROR|failed|Failed|FAILED|Building wheel", msg, ignore.case = TRUE)) {
          packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
        }
      }
    }

  # Docker installation function
  docker_install <- function(pkg_req) {
    # 指定 pip 路徑
    base_pip_path <- "/opt/venv/bin/pip"

    # 修復權限問題的函數
    fix_permissions <- function() {
      tryCatch({
        system2("sudo", c("chown", "-R", "rstudio:rstudio", "/opt/venv"))
        system2("sudo", c("chmod", "-R", "775", "/opt/venv"))
        TRUE
      }, error = function(e) FALSE)
    }

    # 清理無效的分發
    clean_invalid_dist <- function() {
      tryCatch({
        system2("sudo", c("rm", "-rf", "/opt/venv/lib/python3.12/site-packages/~*"))
        TRUE
      }, error = function(e) FALSE)
    }

    # 安裝嘗試序列
    install_attempts <- list(
      # 1. 使用 sudo pip install 並強制重新安裝
      function() {
        fix_permissions()
        clean_invalid_dist()
        system2("sudo", c(base_pip_path, "install", "--no-cache-dir",
                          "--force-reinstall", "--no-deps", pkg_req))
      },

      # 2. 使用 pip 安裝到用戶目錄
      function() {
        system2("sudo", c(base_pip_path, "install", "--no-cache-dir",
                          "--force-reinstall", "--user", pkg_req))
      },

      # 3. 使用 Python -m pip
      function() {
        fix_permissions()
        system2("sudo", c("/opt/venv/bin/python", "-m", "pip", "install",
                          "--no-cache-dir", "--force-reinstall", pkg_req))
      }
    )

    # 特別處理 sentencepiece 和 tokenizers
    if (grepl("sentencepiece|tokenizers", pkg_req)) {
      tryCatch({
        system2("sudo", c("apt-get", "update"))
        system2("sudo", c("apt-get", "install", "-y",
                          "pkg-config", "git", "cmake",
                          "build-essential", "g++"))
        fix_permissions()
      }, error = function(e) {
        warning("Failed to install build dependencies")
      })
    }

    # 在安裝前先清理
    clean_invalid_dist()

    # 逐一嘗試安裝方法
    for (attempt in install_attempts) {
      result <- tryCatch({
        attempt()
      }, error = function(e) 1)

      if (result == 0) {
        # 安裝成功後修復權限
        fix_permissions()
        return(TRUE)
      }
    }

    # 最後嘗試
    result <- tryCatch({
      fix_permissions()
      clean_invalid_dist()
      system2("sudo", c("pip3", "install", "--no-cache-dir",
                        "--force-reinstall", pkg_req))
    }, error = function(e) 1)

    fix_permissions()
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
        return(list(success = result))
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
    # 環境檢查和設置
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

    # 安裝流程
    if (in_docker) {
      # Docker 環境下先確保權限
      system2("sudo", c("chown", "-R", "rstudio:rstudio", "/opt/venv"))
      system2("sudo", c("chmod", "-R", "775", "/opt/venv"))

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
      # 非 Docker 環境的安裝
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

# install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
#   # Parse requirement string to name and version
#   parse_requirement <- function(pkg_req) {
#     if(grepl(">=|==|<=", pkg_req)) {
#       parts <- strsplit(pkg_req, ">=|==|<=")[[1]]
#       list(name = trimws(parts[1]), version = trimws(parts[2]))
#     } else {
#       list(name = trimws(pkg_req), version = "")
#     }
#   }
#
#   # Retry installation with backoff
#   retry_install <- function(install_fn, pkg_name) {
#     for (i in 1:max_retries) {
#       tryCatch({
#         if (i > 1) log_msg(sprintf("Retry attempt %d/%d for %s", i, max_retries, pkg_name),
#                            quiet = quiet)
#
#         # Special handling for sentencepiece
#         if (pkg_name == "sentencepiece") {
#           install_opts <- .pkgenv$package_constants$install_options$sentencepiece
#           result <- reticulate::py_install(
#             packages = pkg_name,
#             pip = TRUE,
#             envname = venv,
#             pip_options = install_opts
#           )
#         } else {
#           result <- install_fn()
#         }
#
#         return(list(success = TRUE))
#       }, error = function(e) {
#         if (i == max_retries) {
#           return(list(
#             success = FALSE,
#             error = sprintf("Failed to install %s: %s", pkg_name, e$message)
#           ))
#         }
#         Sys.sleep(2 ^ i)
#         NULL
#       })
#     }
#   }
#
#   # Get installation sequence based on system
#   get_install_sequence <- function() {
#     is_m1 <- Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64"
#
#     # 先準備 core packages
#     core_packages <- c(
#       sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#       sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#       sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
#     )
#
#     if (!is_m1) {
#       core_packages <- c(core_packages,
#                          sprintf("sentencepiece==%s", .pkgenv$package_constants$sentencepiece_version))
#     }
#
#     base_sequence <- list(
#       torch = list(
#         name = "PyTorch",
#         packages = if(is_m1) {
#           c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version))
#         } else {
#           c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#             "torchvision")
#         }
#       ),
#       core = list(
#         name = "Core dependencies",
#         packages = core_packages
#       ),
#       flair = list(
#         name = "Flair Base",
#         packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#       )
#     )
#
#     if (!is_m1) {
#       base_sequence$gensim <- list(
#         name = "Gensim",
#         packages = sprintf("gensim>=%s", .pkgenv$package_constants$gensim_version)
#       )
#     }
#
#     return(base_sequence)
#   }
#
#   # Main installation process
#   tryCatch({
#     in_docker <- is_docker()
#
#     # Quick check if all dependencies are already installed
#     install_sequence <- get_install_sequence()
#     all_installed <- TRUE
#     missing_packages <- character(0)
#
#     # Check all packages first
#     for (pkg in install_sequence) {
#       for (pkg_req in pkg$packages) {
#         req <- parse_requirement(pkg_req)
#         if (!check_package_state(req$name, req$version, quiet = TRUE)) {
#           all_installed <- FALSE
#           missing_packages <- c(missing_packages, pkg_req)
#         }
#       }
#     }
#
#     # If everything is installed, return early
#     if (all_installed) {
#       log_msg("All dependencies are already installed and up to date", quiet = quiet)
#       return(TRUE)
#     }
#
#     # If not all installed, proceed with installation
#     env_msg <- if (!is.null(venv)) {
#       sprintf(" in %s", venv)
#     } else {
#       if (in_docker) " in Docker environment" else ""
#     }
#
#     log_msg(sprintf("Installing missing dependencies%s: %s",
#                     env_msg,
#                     paste(missing_packages, collapse = ", ")),
#             quiet = quiet)
#
#     if (in_docker) {
#       pip_path <- "/opt/venv/bin/pip"
#
#       # Install missing packages
#       for (pkg_req in missing_packages) {
#         req <- parse_requirement(pkg_req)
#         log_msg(sprintf("Installing %s...", pkg_req), quiet = quiet)
#         result <- retry_install(function() {
#           system2("sudo", c("-H", "pip", "install", "--no-cache-dir", pkg_req))
#         }, req$name)
#
#         if (!result$success) {
#           log_msg(result$error, is_error = TRUE)
#           return(FALSE)
#         }
#       }
#     } else {
#       # Regular installation
#       for (pkg_req in missing_packages) {
#         req <- parse_requirement(pkg_req)
#         log_msg(sprintf("Installing %s...", pkg_req), quiet = quiet)
#         result <- retry_install(function() {
#           reticulate::py_install(
#             packages = pkg_req,
#             pip = TRUE,
#             envname = venv,
#             ignore_installed = FALSE
#           )
#         }, req$name)
#
#         if (!result$success) {
#           log_msg(result$error, is_error = TRUE)
#           return(FALSE)
#         }
#       }
#     }
#
#     log_msg("All dependencies are installed and up to date", quiet = quiet)
#     return(TRUE)
#
#   }, error = function(e) {
#     log_msg(sprintf(
#       "Error checking/installing dependencies: %s\nPlease check:\n1. Internet connection\n2. Pip availability\n3. Python environment permissions",
#       e$message
#     ), is_error = TRUE)
#     return(FALSE)
#   })
# }



# install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
#   # Helper functions
#   #  log_msg hide Python package info collection
#   log_msg <- function(msg, is_error = FALSE) {
#     if (!quiet) {
#       # 只有在是錯誤信息時才顯示
#       if (is_error || grepl("error|Error|ERROR|failed|Failed|FAILED|Building wheel", msg, ignore.case = TRUE)) {
#         packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
#       }
#     }
#   }
#
#   # Parse requirement string to name and version
#   parse_requirement <- function(pkg_req) {
#     if(grepl(">=|==|<=", pkg_req)) {
#       parts <- strsplit(pkg_req, ">=|==|<=")[[1]]
#       list(name = trimws(parts[1]), version = trimws(parts[2]))
#     } else {
#       list(name = trimws(pkg_req), version = "")
#     }
#   }
#
#   # Retry installation with backoff
#   retry_install <- function(install_fn, pkg_name) {
#     for (i in 1:max_retries) {
#       tryCatch({
#         if (i > 1) log_msg(sprintf("Retry attempt %d/%d for %s", i, max_retries, pkg_name))
#
#         # Special handling for sentencepiece
#         if (pkg_name == "sentencepiece") {
#           install_opts <- .pkgenv$package_constants$install_options$sentencepiece
#           result <- reticulate::py_install(
#             packages = pkg_name,
#             pip = TRUE,
#             envname = venv,
#             pip_options = install_opts
#           )
#         } else {
#           result <- install_fn()
#         }
#
#         return(list(success = TRUE))
#       }, error = function(e) {
#         if (i == max_retries) {
#           return(list(
#             success = FALSE,
#             error = sprintf("Failed to install %s: %s", pkg_name, e$message)
#           ))
#         }
#         Sys.sleep(2 ^ i)
#         NULL
#       })
#     }
#   }
#
#   # Get installation sequence based on system
#   get_install_sequence <- function() {
#     is_m1 <- Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64"
#
#     # 先準備 core packages
#     core_packages <- c(
#       sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#       sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#       sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
#     )
#
#     # 如果不是 M1，添加 sentencepiece
#     if (!is_m1) {
#       core_packages <- c(core_packages,
#                          sprintf("sentencepiece==%s", .pkgenv$package_constants$sentencepiece_version))
#     }
#
#     base_sequence <- list(
#       torch = list(
#         name = "PyTorch",
#         packages = if(is_m1) {
#           c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version))
#         } else {
#           c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#             "torchvision")
#         }
#       ),
#       core = list(
#         name = "Core dependencies",
#         packages = core_packages
#       ),
#       flair = list(
#         name = "Flair Base",
#         packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#       )
#     )
#
#     if (!is_m1) {
#       base_sequence$gensim <- list(
#         name = "Gensim",
#         packages = sprintf("gensim>=%s", .pkgenv$package_constants$gensim_version)
#       )
#     }
#
#     return(base_sequence)
#   }
#   # Main installation process
#   tryCatch({
#     in_docker <- is_docker()
#
#     # Quick check if all dependencies are already installed
#     install_sequence <- get_install_sequence()
#     all_installed <- TRUE
#     missing_packages <- character(0)
#
#     # Check all packages first
#     for (pkg in install_sequence) {
#       for (pkg_req in pkg$packages) {
#         req <- parse_requirement(pkg_req)
#         if (!check_package_state(req$name, req$version, quiet = TRUE)) {
#           all_installed <- FALSE
#           missing_packages <- c(missing_packages, pkg_req)
#         }
#       }
#     }
#
#     # If everything is installed, return early
#     if (all_installed) {
#       if (!quiet) log_msg("All dependencies are already installed and up to date")
#       return(TRUE)
#     }
#
#     # If not all installed, proceed with installation
#     env_msg <- if (!is.null(venv)) {
#       sprintf(" in %s", venv)
#     } else {
#       if (in_docker) " in Docker environment" else ""
#     }
#
#     log_msg(sprintf("Installing missing dependencies%s: %s",
#                     env_msg,
#                     paste(missing_packages, collapse = ", ")))
#
#     if (in_docker) {
#       pip_path <- "/opt/venv/bin/pip"
#
#       # Install missing packages
#       for (pkg_req in missing_packages) {
#         req <- parse_requirement(pkg_req)
#         log_msg(sprintf("Installing %s...", pkg_req))
#         result <- retry_install(function() {
#           system2("sudo", c("-H", "pip", "install", "--no-cache-dir", pkg_req))
#         }, req$name)
#
#         if (!result$success) {
#           log_msg(result$error, TRUE)
#           return(FALSE)
#         }
#       }
#     } else {
#       # Regular installation
#       for (pkg_req in missing_packages) {
#         req <- parse_requirement(pkg_req)
#         log_msg(sprintf("Installing %s...", pkg_req))
#         result <- retry_install(function() {
#           reticulate::py_install(
#             packages = pkg_req,
#             pip = TRUE,
#             envname = venv,
#             ignore_installed = FALSE
#           )
#         }, req$name)
#
#         if (!result$success) {
#           log_msg(result$error, TRUE)
#           return(FALSE)
#         }
#       }
#     }
#
#     log_msg("All dependencies are installed and up to date")
#     return(TRUE)
#
#   }, error = function(e) {
#     log_msg(sprintf(
#       "Error checking/installing dependencies: %s\nPlease check:\n1. Internet connection\n2. Pip availability\n3. Python environment permissions",
#       e$message
#     ), TRUE)
#     return(FALSE)
#   })
# }

# Check and Setup Conda --------------------------------------------------------
#' @title Check and setup conda environment
#'
#' @param show_status Show status messages if TRUE
#' @param force_check Force check and reinstall if needed
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
check_conda_env <- function(show_status = FALSE, force_check = FALSE, quiet = FALSE) {
  # Reset installation state if force check
  if (force_check) {
    .pkgenv$installation_state <- new.env(parent = emptyenv())
  }

  # Docker 環境檢查
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      log_msg(sprintf("Using Docker virtual environment: %s", docker_python),
              show_status = show_status, quiet = quiet)
      tryCatch({
        reticulate::use_python(docker_python, required = TRUE)
        if (force_check || !reticulate::py_module_available("flair")) {
          install_dependencies(NULL, quiet = quiet)
        }
        return(TRUE)
      }, error = function(e) {
        log_msg(sprintf("Error using Docker environment: %s", e$message),
                is_error = TRUE)
      })
    }
  }

  # 標準環境檢查
  current_python <- tryCatch({
    config <- reticulate::py_config()
    if (!force_check && reticulate::py_module_available("flair")) {
      list(status = TRUE, path = config$python)
    } else {
      list(status = FALSE)
    }
  }, error = function(e) {
    list(status = FALSE)
  })

  if (current_python$status) {
    log_msg(sprintf("Using Python: %s", current_python$path),
            show_status = show_status, quiet = quiet)
    return(TRUE)
  }

  # Conda 可用性檢查
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (conda_available$status) {
    if (show_status) {
      print_status("Conda", conda_available$path, TRUE)
    }

    conda_envs <- reticulate::conda_list()
    if ("flair_env" %in% conda_envs$name) {
      flair_envs <- conda_envs[conda_envs$name == "flair_env", ]
      miniconda_path <- grep("miniconda", flair_envs$python, value = TRUE)
      selected_env <- if (length(miniconda_path) > 0) {
        miniconda_path[1]
      } else {
        flair_envs$python[1]
      }

      if (file.exists(selected_env)) {
        log_msg(sprintf("Using environment: %s", selected_env),
                show_status = show_status, quiet = quiet)
        tryCatch({
          reticulate::use_python(selected_env, required = TRUE)
          if (force_check || !reticulate::py_module_available("flair")) {
            install_dependencies("flair_env", quiet = quiet)
          }
          return(TRUE)
        }, error = function(e) {
          log_msg(sprintf("Error using environment: %s", e$message),
                  is_error = TRUE)
          FALSE
        })
      }
    }
  }

  # 系統 Python 檢查
  log_msg("Using system Python...", show_status = show_status, quiet = quiet)
  python_path <- Sys.which("python3")
  if (python_path == "") python_path <- Sys.which("python")

  if (python_path != "" && file.exists(python_path)) {
    tryCatch({
      reticulate::use_python(python_path, required = TRUE)
      if (force_check || !reticulate::py_module_available("flair")) {
        install_dependencies(NULL, quiet = quiet)
      }
      return(TRUE)
    }, error = function(e) {
      log_msg(sprintf("Error using system Python: %s", e$message),
              is_error = TRUE)
      FALSE
    })
  }

  log_msg("No suitable Python installation found", is_error = TRUE)
  return(FALSE)
}

# check_conda_env <- function(show_status = FALSE, force_check = FALSE, quiet = FALSE) {
#   # Reset installation state if force check
#   if (force_check) {
#     .pkgenv$installation_state <- new.env(parent = emptyenv())
#   }
#
#   # Docker 環境檢查
#   if (is_docker()) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
#     if (file.exists(docker_python)) {
#       log_msg(sprintf("Using Docker virtual environment: %s", docker_python),
#               show_status = show_status, quiet = quiet)
#       tryCatch({
#         reticulate::use_python(docker_python, required = TRUE)
#         if (force_check || !reticulate::py_module_available("flair")) {
#           install_dependencies(NULL, quiet = quiet)
#         }
#         return(TRUE)
#       }, error = function(e) {
#         log_msg(sprintf("Error using Docker environment: %s", e$message),
#                 is_error = TRUE)
#       })
#     }
#   }
#
#   # 標準環境檢查
#   current_python <- tryCatch({
#     config <- reticulate::py_config()
#     if (!force_check && reticulate::py_module_available("flair")) {
#       list(status = TRUE, path = config$python)
#     } else {
#       list(status = FALSE)
#     }
#   }, error = function(e) {
#     list(status = FALSE)
#   })
#
#   if (current_python$status) {
#     log_msg(sprintf("Using Python: %s", current_python$path),
#             show_status = show_status, quiet = quiet)
#     return(TRUE)
#   }
#
#   # Conda 可用性檢查
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#   if (conda_available$status) {
#     if (show_status) {
#       print_status("Conda", conda_available$path, TRUE)
#     }
#
#     conda_envs <- reticulate::conda_list()
#     if ("flair_env" %in% conda_envs$name) {
#       flair_envs <- conda_envs[conda_envs$name == "flair_env", ]
#       miniconda_path <- grep("miniconda", flair_envs$python, value = TRUE)
#       selected_env <- if (length(miniconda_path) > 0) {
#         miniconda_path[1]
#       } else {
#         flair_envs$python[1]
#       }
#
#       if (file.exists(selected_env)) {
#         log_msg(sprintf("Using environment: %s", selected_env),
#                 show_status = show_status, quiet = quiet)
#         tryCatch({
#           reticulate::use_python(selected_env, required = TRUE)
#           if (force_check || !reticulate::py_module_available("flair")) {
#             install_dependencies("flair_env", quiet = quiet)
#           }
#           return(TRUE)
#         }, error = function(e) {
#           log_msg(sprintf("Error using environment: %s", e$message),
#                   is_error = TRUE)
#           FALSE
#         })
#       }
#     }
#   }
#
#   # 系統 Python 檢查
#   log_msg("Using system Python...", show_status = show_status, quiet = quiet)
#   python_path <- Sys.which("python3")
#   if (python_path == "") python_path <- Sys.which("python")
#
#   if (python_path != "" && file.exists(python_path)) {
#     tryCatch({
#       reticulate::use_python(python_path, required = TRUE)
#       if (force_check || !reticulate::py_module_available("flair")) {
#         install_dependencies(NULL, quiet = quiet)
#       }
#       return(TRUE)
#     }, error = function(e) {
#       log_msg(sprintf("Error using system Python: %s", e$message),
#               is_error = TRUE)
#       FALSE
#     })
#   }
#
#   log_msg("No suitable Python installation found", is_error = TRUE)
#   return(FALSE)
# }

# check_conda_env <- function(show_status = FALSE, force_check = FALSE) {
#   if (force_check) {
#     .pkgenv$installation_state <- new.env(parent = emptyenv())
#   }
#
#   # Docker 環境檢查
#   if (is_docker()) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
#     if (file.exists(docker_python)) {
#       log_msg(sprintf("Using Docker virtual environment: %s", docker_python),
#               show_status = show_status)
#       tryCatch({
#         reticulate::use_python(docker_python, required = TRUE)
#         if (force_check || !reticulate::py_module_available("flair")) {
#           install_dependencies(NULL)
#         }
#         return(TRUE)
#       }, error = function(e) {
#         log_msg(sprintf("Error using Docker environment: %s", e$message),
#                 is_error = TRUE)
#       })
#     }
#   }
#
#   # 標準環境檢查
#   current_python <- tryCatch({
#     config <- reticulate::py_config()
#     if (!force_check && reticulate::py_module_available("flair")) {
#       list(status = TRUE, path = config$python)
#     } else {
#       list(status = FALSE)
#     }
#   }, error = function(e) {
#     list(status = FALSE)
#   })
#
#   if (current_python$status) {
#     log_msg(sprintf("Using Python: %s", current_python$path),
#             show_status = show_status)
#     return(TRUE)
#   }
#
#   # Conda 可用性檢查
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#   if (conda_available$status) {
#     if (show_status) {
#       print_status("Conda", conda_available$path, TRUE)
#     }
#
#     conda_envs <- reticulate::conda_list()
#     if ("flair_env" %in% conda_envs$name) {
#       flair_envs <- conda_envs[conda_envs$name == "flair_env", ]
#       miniconda_path <- grep("miniconda", flair_envs$python, value = TRUE)
#       selected_env <- if (length(miniconda_path) > 0) {
#         miniconda_path[1]
#       } else {
#         flair_envs$python[1]
#       }
#
#       if (file.exists(selected_env)) {
#         log_msg(sprintf("Using environment: %s", selected_env),
#                 show_status = show_status)
#         tryCatch({
#           reticulate::use_python(selected_env, required = TRUE)
#           if (force_check || !reticulate::py_module_available("flair")) {
#             install_dependencies("flair_env")
#           }
#           return(TRUE)
#         }, error = function(e) {
#           log_msg(sprintf("Error using environment: %s", e$message),
#                   is_error = TRUE)
#           FALSE
#         })
#       }
#     }
#   }
#
#   # 系統 Python 檢查
#   log_msg("Using system Python...", show_status = show_status)
#   python_path <- Sys.which("python3")
#   if (python_path == "") python_path <- Sys.which("python")
#
#   if (python_path != "" && file.exists(python_path)) {
#     tryCatch({
#       reticulate::use_python(python_path, required = TRUE)
#       if (force_check || !reticulate::py_module_available("flair")) {
#         install_dependencies(NULL)
#       }
#       return(TRUE)
#     }, error = function(e) {
#       log_msg(sprintf("Error using system Python: %s", e$message),
#               is_error = TRUE)
#       FALSE
#     })
#   }
#
#   log_msg("No suitable Python installation found", is_error = TRUE)
#   return(FALSE)
# }

# check_conda_env <- function(show_status = FALSE, force_check = FALSE) {
#   # Reset installation state if force check
#   if (force_check) {
#     .pkgenv$installation_state <- new.env(parent = emptyenv())
#   }
#
#   # Check for Docker environment first
#   if (is_docker()) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
#     if (file.exists(docker_python)) {
#       packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
#       tryCatch({
#         reticulate::use_python(docker_python, required = TRUE)
#         # Force check or check if flair is not available
#         if (force_check || !reticulate::py_module_available("flair")) {
#           install_dependencies(NULL)
#         }
#         return(TRUE)
#       }, error = function(e) {
#         packageStartupMessage(sprintf("Error using Docker environment: %s", e$message))
#       })
#     }
#   }
#
#   # Standard environment checks
#   current_python <- tryCatch({
#     config <- reticulate::py_config()
#     if (!force_check && reticulate::py_module_available("flair")) {
#       list(status = TRUE, path = config$python)
#     } else {
#       list(status = FALSE)
#     }
#   }, error = function(e) {
#     list(status = FALSE)
#   })
#
#   if (current_python$status) {
#     packageStartupMessage(sprintf("Using Python: %s", current_python$path))
#     return(TRUE)
#   }
#
#   # Check Conda availability
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#   if (conda_available$status) {
#     print_status("Conda", conda_available$path, TRUE)
#     conda_envs <- reticulate::conda_list()
#
#     if ("flair_env" %in% conda_envs$name) {
#       flair_envs <- conda_envs[conda_envs$name == "flair_env", ]
#       miniconda_path <- grep("miniconda", flair_envs$python, value = TRUE)
#       selected_env <- if (length(miniconda_path) > 0) {
#         miniconda_path[1]
#       } else {
#         flair_envs$python[1]
#       }
#
#       if (file.exists(selected_env)) {
#         packageStartupMessage(sprintf("Using environment: %s", selected_env))
#         tryCatch({
#           reticulate::use_python(selected_env, required = TRUE)
#           if (force_check || !reticulate::py_module_available("flair")) {
#             install_dependencies("flair_env")
#           }
#           return(TRUE)
#         }, error = function(e) {
#           packageStartupMessage(sprintf("Error using environment: %s", e$message))
#           FALSE
#         })
#       }
#     }
#   }
#
#   # Try system Python as last resort
#   packageStartupMessage("Using system Python...")
#   python_path <- Sys.which("python3")
#   if (python_path == "") python_path <- Sys.which("python")
#
#   if (python_path != "" && file.exists(python_path)) {
#     tryCatch({
#       reticulate::use_python(python_path, required = TRUE)
#       if (force_check || !reticulate::py_module_available("flair")) {
#         install_dependencies(NULL)
#       }
#       return(TRUE)
#     }, error = function(e) {
#       packageStartupMessage(sprintf("Error using system Python: %s", e$message))
#       FALSE
#     })
#   }
#
#   packageStartupMessage("No suitable Python installation found")
#   return(FALSE)
# }


# Initialize Required Modules --------------------------------------------------
#' @title Initialize Required Modules
#'
#' @return List containing version information and initialization status
#' @noRd
initialize_modules <- function() {
  tryCatch({
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)


    torch_version <- reticulate::py_get_attr(torch, "__version__")
    transformers_version <- reticulate::py_get_attr(transformers, "__version__")
    flair_version <- reticulate::py_get_attr(flair, "__version__")


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


# Package Initialization --------------------------------------------------

#' @noRd
.onLoad <- function(libname, pkgname) {
  # 初始化標記
  .pkgenv$initialized <- FALSE

  # Set KMP duplicate lib environment variable
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  # M1 Mac specific settings
  if (Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64") {
    Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    # Add additional M1-specific environment variables
    Sys.setenv(GRPC_PYTHON_BUILD_SYSTEM_OPENSSL = 1)
    Sys.setenv(GRPC_PYTHON_BUILD_SYSTEM_ZLIB = 1)
  }

  # General Mac settings
  if (Sys.info()["sysname"] == "Darwin") {
    Sys.setenv(OMP_NUM_THREADS = 1)
    Sys.setenv(MKL_NUM_THREADS = 1)
  }

  # Docker specific settings
  if (is_docker()) {
    Sys.setenv(PYTHONNOUSERSITE = "1")
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      Sys.setenv(RETICULATE_PYTHON = docker_python)
    }
  }

  options(reticulate.prompt = FALSE)
}

#' @noRd
.onAttach <- function(libname, pkgname) {
  # Store original environment settings
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    # 檢查是否已經初始化，避免重複安裝
    if (!is.null(.pkgenv$initialized) && .pkgenv$initialized) {
      return(invisible(NULL))
    }

    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # Environment Information
    sys_info <- get_system_info()
    packageStartupMessage("\nEnvironment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # M1 Mac specific message
    # if (Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64") {
    #   packageStartupMessage(sprintf(
    #     "%sDetected Apple Silicon (M1/M2). MPS acceleration enabled.%s",
    #     .pkgenv$colors$green,
    #     .pkgenv$colors$reset
    #   ))
    # }

    # Docker status check
    if (is_docker()) {
      print_status("Docker", "Enabled", TRUE)
    }

    # Python environment setup
    env_setup <- check_conda_env()
    if (!env_setup) {
      return(invisible(NULL))
    }

    # Python version check
    config <- reticulate::py_config()
    python_version <- as.character(config$version)
    print_status("Python", python_version, check_python_version(python_version))

    # Module initialization and status check
    init_result <- initialize_modules()
    if (init_result$status) {
      # GPU status check
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

      # Add blank line before package info
      packageStartupMessage("")

      # Main package version info
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # Word Embeddings status
      if (verify_embeddings(quiet = TRUE)) {
        gensim_version <- tryCatch({
          gensim <- reticulate::import("gensim")
          reticulate::py_get_attr(gensim, "__version__")
        }, error = function(e) "Unknown")
        print_status("Word Embeddings", gensim_version, TRUE)
      } else {
        print_status("Word Embeddings", "Not Available", FALSE,
                     sprintf(
                       "Word embeddings feature is not detected.\n\nInstall with:\nIn R:\n  reticulate::py_install('flair[word-embeddings]', pip = TRUE)\n  system(paste(Sys.which('python3'), '-m pip install flair[word-embeddings]'))\n\nIn terminal:\n  pip install flair[word-embeddings]"
                     ))
      }

      # Welcome message
      packageStartupMessage("\n")
      msg <- sprintf(
        "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
        .pkgenv$colors$bold, .pkgenv$colors$blue,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
        .pkgenv$colors$bold, .pkgenv$colors$yellow,
        init_result$versions$flair,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold
      )
      packageStartupMessage(msg)

      # 設置初始化標記
      .pkgenv$initialized <- TRUE
    }
  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}

