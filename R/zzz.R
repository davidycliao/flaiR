#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())


# Add gensim version to package constants
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

## Embeddings Verification -----------------------------------------------------
#' @title Embeddings Verification Function
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

## ANSI Color Codes ------------------------------------------------------------

.pkgenv$colors <- list(
  green = "\033[32m",
  red = "\033[31m",
  blue = "\033[34m",
  yellow = "\033[33m",
  reset = "\033[39m",
  bold = "\033[1m",
  reset_bold = "\033[22m"
)

## Initialize Module Storage ---------------------------------------------------
.pkgenv$modules <- list(
  flair = NULL,
  flair_embeddings = NULL,
  torch = NULL
)


## Check Docker ----------------------------------------------------------------
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


## Check Python Version --------------------------------------------------------

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


## Print Messages --------------------------------------------------------------
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


## Get System Information -----------------------------------------------------
#' Get System Information
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


##  Setup Clean Python Environment  --------------------------------------------
#' @title Setup Clean Python Environment for flaiR
#'
#' @param quiet Boolean to suppress status messages
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
setup_clean_environment <- function(quiet = FALSE) {
  # Helper function for logging
  log_msg <- function(msg, is_error = FALSE) {
    if (!quiet) {
      if (is_error) {
        message("Error: ", msg)
      } else {
        message(msg)
      }
    }
  }

  tryCatch({
    log_msg("Starting environment cleanup and setup...")

    if (!requireNamespace("reticulate", quietly = TRUE)) {
      log_msg("Installing reticulate package...")
      install.packages("reticulate")
    }

    # Remove existing environments
    envs_to_remove <- c("r-reticulate", "flair_env")
    for (env in envs_to_remove) {
      if (env %in% reticulate::virtualenv_list()) {
        log_msg(sprintf("Removing existing environment: %s", env))
        reticulate::virtualenv_remove(env)
      }
    }

    # Create new environment
    log_msg("Creating new r-reticulate environment...")
    reticulate::virtualenv_create("r-reticulate", python_version = "3.9")

    # Setup for M1/M2 Mac
    if (Sys.info()["sysname"] == "Darwin" &&
        Sys.info()["machine"] == "arm64") {
      log_msg("Setting up M1/M2 Mac specific configurations...")
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = "1")
      Sys.setenv(RETICULATE_PYTHON = file.path(Sys.getenv("HOME"),
                                               ".virtualenvs/r-reticulate/bin/python"))
    }

    reticulate::use_virtualenv("r-reticulate", required = TRUE)
    log_msg("Installing dependencies...")
    result <- install_dependencies(quiet = quiet)

    if (result) {
      log_msg("Environment setup completed successfully!")
      return(TRUE)
    } else {
      log_msg("Failed to install dependencies", TRUE)
      return(FALSE)
    }

  }, error = function(e) {
    log_msg(sprintf("Setup failed: %s", e$message), TRUE)
    return(FALSE)
  })
}


## Install Dependencies --------------------------------------------------------
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
# install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
#   # Helper functions
#   log_msg <- function(msg, is_error = FALSE) {
#     if (!quiet) {
#       if (is_error) {
#         packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
#       } else {
#         packageStartupMessage(msg)
#       }
#     }
#   }
#
#   # Check package version
#   check_version <- function(pkg_name, required_version) {
#     tryCatch({
#       if(required_version == "") return(TRUE)
#       cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
#       installed <- reticulate::py_eval(cmd)
#       if(is.null(installed)) return(FALSE)
#       package_version(installed) >= package_version(required_version)
#     }, error = function(e) FALSE)
#   }
#
#   # Parse requirement function
#   parse_requirement <- function(pkg_req) {
#     if(grepl(">=|==|<=", pkg_req)) {
#       parts <- strsplit(pkg_req, ">=|==|<=")[[1]]
#       list(name = trimws(parts[1]), version = trimws(parts[2]))
#     } else {
#       list(name = trimws(pkg_req), version = "")
#     }
#   }
#
#   # Docker installation function
#   docker_install <- function(pkg_req) {
#     # 首先嘗試使用 sudo pip install
#     result <- system2("sudo", c("/opt/venv/bin/pip", "install",
#                                 "--force-reinstall",
#                                 "--no-deps",
#                                 pkg_req))
#
#     if (result != 0) {
#       # 如果失敗，嘗試使用 python -m pip
#       result <- system2("sudo", c("python3", "-m", "pip", "install",
#                                   "--force-reinstall",
#                                   "--no-deps",
#                                   pkg_req))
#     }
#
#     return(result == 0)
#   }
#
#   # Retry installation with backoff
#   retry_install <- function(install_fn, pkg_name) {
#     for (i in 1:max_retries) {
#       tryCatch({
#         if (i > 1) log_msg(sprintf("Retry attempt %d/%d for %s", i, max_retries, pkg_name))
#         result <- install_fn()
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
#   # Get installation sequence
#   get_install_sequence <- function() {
#     list(
#       torch = list(
#         name = "PyTorch",
#         packages = c(
#           sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#           "torchvision"
#         )
#       ),
#       core = list(
#         name = "Core dependencies",
#         packages = c(
#           sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#           sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#           sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
#         )
#       ),
#       flair = list(
#         name = "Flair Base",
#         packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#       )
#     )
#   }
#
#   # Main installation process
#   tryCatch({
#     # Check system type and set environment variables
#     is_arm_mac <- Sys.info()["sysname"] == "Darwin" &&
#       Sys.info()["machine"] == "arm64"
#     if(is_arm_mac) {
#       Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = "1")
#     }
#
#     in_docker <- is_docker()
#     env_msg <- if (!is.null(venv)) {
#       sprintf(" in %s", venv)
#     } else {
#       if (in_docker) " in Docker environment" else ""
#     }
#
#     log_msg(sprintf("Checking dependencies%s...", env_msg))
#     install_sequence <- get_install_sequence()
#
#     if (in_docker) {
#       for (pkg in install_sequence) {
#         log_msg(sprintf("Checking %s...", pkg$name))
#         for (pkg_req in pkg$packages) {
#           req <- parse_requirement(pkg_req)
#           if (!check_version(req$name, req$version)) {
#             log_msg(sprintf("Installing %s...", pkg_req))
#             result <- retry_install(function() {
#               docker_install(pkg_req)
#             }, pkg_req)
#             if (!result$success) {
#               log_msg(result$error, TRUE)
#               return(FALSE)
#             }
#           } else {
#             log_msg(sprintf("%s is already installed with required version", req$name))
#           }
#         }
#       }
#     } else {
#       for (pkg in install_sequence) {
#         log_msg(sprintf("Checking %s...", pkg$name))
#         for (pkg_req in pkg$packages) {
#           req <- parse_requirement(pkg_req)
#           if (!check_version(req$name, req$version)) {
#             log_msg(sprintf("Installing %s...", pkg_req))
#             result <- retry_install(function() {
#               reticulate::py_install(
#                 packages = pkg_req,
#                 pip = TRUE,
#                 envname = venv,
#                 ignore_installed = FALSE
#               )
#             }, pkg_req)
#             if (!result$success) {
#               log_msg(result$error, TRUE)
#               return(FALSE)
#             }
#           } else {
#             log_msg(sprintf("%s is already installed with required version", req$name))
#           }
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

# install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
#   # Helper functions
#   log_msg <- function(msg, is_error = FALSE) {
#     if (!quiet) {
#       if (is_error) {
#         packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
#       } else {
#         packageStartupMessage(msg)
#       }
#     }
#   }
#
#   # Check package version
#   check_version <- function(pkg_name, required_version) {
#     tryCatch({
#       if(required_version == "") return(TRUE)
#       cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
#       installed <- reticulate::py_eval(cmd)
#       if(is.null(installed)) return(FALSE)
#       package_version(installed) >= package_version(required_version)
#     }, error = function(e) FALSE)
#   }
#
#   # Parse requirement function
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
#         result <- install_fn()
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
#   # Get installation sequence
#   get_install_sequence <- function() {
#     list(
#       torch = list(
#         name = "PyTorch",
#         packages = c(
#           sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#           "torchvision"
#         )
#       ),
#       core = list(
#         name = "Core dependencies",
#         packages = c(
#           sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#           sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#           sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
#         )
#       ),
#       flair = list(
#         name = "Flair Base",
#         packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#       )
#     )
#   }
#
#   # Main installation process
#   tryCatch({
#     # Check system type and set environment variables
#     is_arm_mac <- Sys.info()["sysname"] == "Darwin" &&
#       Sys.info()["machine"] == "arm64"
#     if(is_arm_mac) {
#       Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = "1")
#     }
#
#     in_docker <- is_docker()
#     env_msg <- if (!is.null(venv)) {
#       sprintf(" in %s", venv)
#     } else {
#       if (in_docker) " in Docker environment" else ""
#     }
#
#     log_msg(sprintf("Checking dependencies%s...", env_msg))
#     install_sequence <- get_install_sequence()
#
#     if (in_docker) {
#       pip_path <- "/opt/venv/bin/pip"
#       for (pkg in install_sequence) {
#         log_msg(sprintf("Checking %s...", pkg$name))
#         for (pkg_req in pkg$packages) {
#           req <- parse_requirement(pkg_req)
#           if (!check_version(req$name, req$version)) {
#             log_msg(sprintf("Installing %s...", pkg_req))
#             result <- retry_install(function() {
#               system2(pip_path, c("install", pkg_req))
#             }, pkg_req)
#             if (!result$success) {
#               log_msg(result$error, TRUE)
#               return(FALSE)
#             }
#           } else {
#             log_msg(sprintf("%s is already installed with required version", req$name))
#           }
#         }
#       }
#     } else {
#       for (pkg in install_sequence) {
#         log_msg(sprintf("Checking %s...", pkg$name))
#         for (pkg_req in pkg$packages) {
#           req <- parse_requirement(pkg_req)
#           if (!check_version(req$name, req$version)) {
#             log_msg(sprintf("Installing %s...", pkg_req))
#             result <- retry_install(function() {
#               reticulate::py_install(
#                 packages = pkg_req,
#                 pip = TRUE,
#                 envname = venv,
#                 ignore_installed = FALSE
#               )
#             }, pkg_req)
#             if (!result$success) {
#               log_msg(result$error, TRUE)
#               return(FALSE)
#             }
#           } else {
#             log_msg(sprintf("%s is already installed with required version", req$name))
#           }
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

# install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
#   # Helper functions
#   log_msg <- function(msg, is_error = FALSE) {
#     if (!quiet) {
#       if (is_error) {
#         packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
#       } else {
#         packageStartupMessage(msg)
#       }
#     }
#   }
#
#
#   # Check package version
#   check_version <- function(pkg_name, required_version) {
#     tryCatch({
#       if(required_version == "") return(TRUE)
#       cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
#       installed <- reticulate::py_eval(cmd)
#       if(is.null(installed)) return(FALSE)
#       package_version(installed) >= package_version(required_version)
#     }, error = function(e) FALSE)
#   }
#
#
#   # Get required version from package name
#   parse_requirement <- function(pkg_req) {
#     if(grepl(">=|==|<=", pkg_req)) {
#       parts <- strsplit(pkg_req, ">=|==|<=")[[1]]
#       list(name = trimws(parts[1]), version = trimws(parts[2]))
#     } else {
#       list(name = trimws(pkg_req), version = "")
#     }
#   }
#
#
#   # Retry installation with backoff
#   retry_install <- function(install_fn, pkg_name) {
#     for (i in 1:max_retries) {
#       tryCatch({
#         if (i > 1) log_msg(sprintf("Retry attempt %d/%d for %s", i, max_retries, pkg_name))
#         result <- install_fn()
#         return(list(success = TRUE))
#       }, error = function(e) {
#         if (i == max_retries) {
#           return(list(
#             success = FALSE,
#             error = sprintf("Failed to install %s: %s", pkg_name, e$message)
#           ))
#         }
#         Sys.sleep(2 ^ i) # Exponential backoff
#         NULL
#       })
#     }
#   }
#
#   # Modified installation sequence
#   get_install_sequence <- function() {
#     list(
#       torch = list(
#         name = "PyTorch",
#         packages = c(
#           sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#           "torchvision"
#         )
#       ),
#       core = list(
#         name = "Core dependencies",
#         packages = c(
#           sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#           sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#           sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
#           "sentencepiece>=0.1.97,<0.2.0"
#         )
#       ),
#       gensim = list(
#         name = "Gensim",
#         packages = sprintf("gensim>=%s", .pkgenv$package_constants$gensim_version)
#       ),
#       embeddings_deps = list(
#         name = "Embeddings Dependencies",
#         packages = c(
#           "smart-open>=1.8.1",
#           "wikipedia-api>=0.5.4"
#         )
#       ),
#       flair = list(
#         name = "Flair Base",
#         packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#       ),
#       flair_embeddings = list(
#         name = "Flair Word Embeddings",
#         packages = "flair[word-embeddings]"
#       )
#     )
#   }
#
#
#   # Main installation process
#   tryCatch({
#     in_docker <- is_docker()
#     env_msg <- if (!is.null(venv)) {
#       sprintf(" in %s", venv)
#     } else {
#       if (in_docker) " in Docker environment" else ""
#     }
#
#
#     log_msg(sprintf("Checking dependencies%s...", env_msg))
#
#
#     # Get installation sequence
#     install_sequence <- get_install_sequence()
#
#
#     if (in_docker) {
#       pip_path <- "/opt/venv/bin/pip"
#
#
#       # Install packages only if needed
#       for (pkg in install_sequence) {
#         log_msg(sprintf("Checking %s...", pkg$name))
#
#
#         for (pkg_req in pkg$packages) {
#           req <- parse_requirement(pkg_req)
#           if (!check_version(req$name, req$version)) {
#             log_msg(sprintf("Installing %s...", pkg_req))
#             result <- retry_install(function() {
#               system2(pip_path, c("install", pkg_req))
#             }, pkg_req)
#
#
#             if (!result$success) {
#               log_msg(result$error, TRUE)
#               return(FALSE)
#             }
#           } else {
#             log_msg(sprintf("%s is already installed with required version", req$name))
#           }
#         }
#       }
#
#
#     } else {
#       # Regular installation
#       for (pkg in install_sequence) {
#         log_msg(sprintf("Checking %s...", pkg$name))
#
#
#         for (pkg_req in pkg$packages) {
#           req <- parse_requirement(pkg_req)
#           if (!check_version(req$name, req$version)) {
#             log_msg(sprintf("Installing %s...", pkg_req))
#             result <- retry_install(function() {
#               reticulate::py_install(
#                 packages = pkg_req,
#                 pip = TRUE,
#                 envname = venv,
#                 ignore_installed = FALSE
#               )
#             }, pkg_req)
#
#
#             if (!result$success) {
#               log_msg(result$error, TRUE)
#               return(FALSE)
#             }
#           } else {
#             log_msg(sprintf("%s is already installed with required version", req$name))
#           }
#         }
#       }
#     }
#
#
#     log_msg("All dependencies are installed and up to date")
#     return(TRUE)
#
#
#   }, error = function(e) {
#     log_msg(sprintf(
#       "Error checking/installing dependencies: %s\nPlease check:\n1. Internet connection\n2. Pip availability\n3. Python environment permissions",
#       e$message
#     ), TRUE)
#     return(FALSE)
#   })
# }



## Check Environment Status ----------------------------------------------------
#' @title Check Environment Status and Load Modules
#' @param quiet Boolean to suppress status messages
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
check_environment_status <- function(quiet = FALSE) {
  # Helper function for logging
  log_msg <- function(msg, is_error = FALSE) {
    if (!quiet) {
      if (is_error) {
        packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
      } else {
        packageStartupMessage(msg)
      }
    }
  }

  # Check core packages versions
  verify_core_packages <- function(python_path) {
    tryCatch({
      reticulate::use_python(python_path, required = TRUE)

      # 檢查各個核心包的版本
      pkg_checks <- list(
        torch = list(
          available = reticulate::py_module_available("torch"),
          version = .pkgenv$package_constants$torch_version
        ),
        transformers = list(
          available = reticulate::py_module_available("transformers"),
          version = .pkgenv$package_constants$transformers_version
        ),
        flair = list(
          available = reticulate::py_module_available("flair"),
          version = .pkgenv$package_constants$flair_min_version
        )
      )

      # 驗證所有包都可用且版本正確
      all(sapply(names(pkg_checks), function(pkg) {
        if (!pkg_checks[[pkg]]$available) return(FALSE)

        installed_version <- reticulate::py_eval(
          sprintf("import %s; print(%s.__version__)", pkg, pkg)
        )
        package_version(installed_version) >= package_version(pkg_checks[[pkg]]$version)
      }))
    }, error = function(e) FALSE)
  }

  # Get Python path based on environment
  get_python_path <- function() {
    # Docker 環境
    if (is_docker()) {
      docker_path <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
      if (file.exists(docker_path)) {
        return(list(path = docker_path, type = "docker"))
      }
    }

    # Conda 環境
    conda_available <- tryCatch({
      conda_bin <- reticulate::conda_binary()
      if ("flair_env" %in% reticulate::conda_list()$name) {
        flair_envs <- reticulate::conda_list()[reticulate::conda_list()$name == "flair_env", ]
        miniconda_path <- grep("miniconda", flair_envs$python, value = TRUE)
        list(
          path = if (length(miniconda_path) > 0) miniconda_path[1] else flair_envs$python[1],
          type = "conda"
        )
      } else NULL
    }, error = function(e) NULL)

    if (!is.null(conda_available)) return(conda_available)

    # 系統 Python
    system_python <- Sys.which("python3")
    if (system_python == "") system_python <- Sys.which("python")
    if (system_python != "") {
      return(list(path = system_python, type = "system"))
    }

    return(NULL)
  }

  # 主要檢查流程
  python_info <- get_python_path()
  if (is.null(python_info)) {
    log_msg("No suitable Python installation found", TRUE)
    return(FALSE)
  }

  log_msg(sprintf("Using %s Python: %s", python_info$type, python_info$path))

  if (!verify_core_packages(python_info$path)) {
    log_msg("Installing required packages...")
    if (!install_dependencies(if(python_info$type == "conda") "flair_env" else NULL)) {
      return(FALSE)
    }
  }

  return(TRUE)
}


## Check and Setup Conda -------------------------------------------------------
#' @title Check and setup conda environment
#' @param show_status Show status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
check_conda_env <- function(show_status = FALSE) {
  # 簡化驗證函數
  verify_flair <- function(python_path) {
    tryCatch({
      # 只檢查模組是否存在，不做版本驗證
      reticulate::use_python(python_path, required = TRUE)
      reticulate::py_module_available("flair")
    }, error = function(e) FALSE)
  }

  # Docker environment check
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))

      # 檢查 flair 可用性
      if (!verify_flair(docker_python)) {
        # 檢查 r-reticulate 環境
        reticulate_env <- tryCatch({
          envs <- reticulate::virtualenv_list()
          if ("r-reticulate" %in% envs) {
            reticulate::use_virtualenv("r-reticulate")
            packageStartupMessage("Using existing r-reticulate environment")
            TRUE
          } else {
            packageStartupMessage("Creating new r-reticulate environment...")
            reticulate::virtualenv_create("r-reticulate", python_version = "3.9")
            reticulate::use_virtualenv("r-reticulate")
            TRUE
          }
        }, error = function(e) {
          packageStartupMessage(sprintf("Error with r-reticulate environment: %s", e$message))
          FALSE
        })

        # 根據環境狀態選擇安裝方式
        if (reticulate_env) {
          install_dependencies("r-reticulate")
        } else {
          install_dependencies(NULL)
        }
      }
      return(TRUE)
    }
  }

  # Standard environment checks
  current_python <- tryCatch({
    config <- reticulate::py_config()
    if (reticulate::py_module_available("flair")) {
      list(status = TRUE, path = config$python)
    } else {
      list(status = FALSE)
    }
  }, error = function(e) {
    list(status = FALSE)
  })

  if (current_python$status) {
    packageStartupMessage(sprintf("Using existing Python: %s", current_python$path))
    return(TRUE)
  }

  # Conda environment check
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (conda_available$status) {
    print_status("Conda", conda_available$path, TRUE)
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
        packageStartupMessage(sprintf("Using environment: %s", selected_env))
        if (!verify_flair(selected_env)) {
          install_dependencies("flair_env")
        }
        return(TRUE)
      }
    }
  }

  # System Python check
  packageStartupMessage("Using system Python...")
  python_path <- Sys.which("python3")
  if (python_path == "") python_path <- Sys.which("python")

  if (python_path != "" && file.exists(python_path)) {
    if (!verify_flair(python_path)) {
      install_dependencies(NULL)
    }
    return(TRUE)
  }

  packageStartupMessage("No suitable Python installation found")
  return(FALSE)
}

# check_conda_env <- function(show_status = FALSE) {
#   # 簡化驗證函數
#   verify_flair <- function(python_path) {
#     tryCatch({
#       # 只檢查模組是否存在，不做版本驗證
#       reticulate::use_python(python_path, required = TRUE)
#       reticulate::py_module_available("flair")
#     }, error = function(e) FALSE)
#   }
#
#   # Check Docker first
#   if (is_docker()) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
#     if (file.exists(docker_python)) {
#       packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
#       if (!verify_flair(docker_python)) {
#         install_dependencies(NULL)
#       }
#       return(TRUE)
#     }
#   }
#
#   # Standard environment checks
#   current_python <- tryCatch({
#     config <- reticulate::py_config()
#     if (reticulate::py_module_available("flair")) {
#       list(status = TRUE, path = config$python)
#     } else {
#       list(status = FALSE)
#     }
#   }, error = function(e) {
#     list(status = FALSE)
#   })
#
#   if (current_python$status) {
#     packageStartupMessage(sprintf("Using existing Python: %s", current_python$path))
#     return(TRUE)
#   }
#
#   # Check Conda
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
#         if (!verify_flair(selected_env)) {
#           install_dependencies("flair_env")
#         }
#         return(TRUE)
#       }
#     }
#   }
#
#   # Try system Python
#   packageStartupMessage("Using system Python...")
#   python_path <- Sys.which("python3")
#   if (python_path == "") python_path <- Sys.which("python")
#
#   if (python_path != "" && file.exists(python_path)) {
#     if (!verify_flair(python_path)) {
#       install_dependencies(NULL)
#     }
#     return(TRUE)
#   }
#
#   packageStartupMessage("No suitable Python installation found")
#   return(FALSE)
# }
# check_conda_env <- function(show_status = FALSE) {
#   # Check for Docker environment first
#   if (is_docker()) {
#     docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
#     if (file.exists(docker_python)) {
#       packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
#       tryCatch({
#         reticulate::use_python(docker_python, required = TRUE)
#         if (!reticulate::py_module_available("flair")) {
#           install_dependencies(NULL)
#         }
#         return(TRUE)
#       }, error = function(e) {
#         packageStartupMessage(sprintf("Error using Docker environment: %s", e$message))
#       })
#     }
#   }
#
#
#   # Standard environment checks
#   current_python <- tryCatch({
#     config <- reticulate::py_config()
#     if (reticulate::py_module_available("flair")) {
#       list(status = TRUE, path = config$python)
#     } else {
#       list(status = FALSE)
#     }
#   }, error = function(e) {
#     list(status = FALSE)
#   })
#
#
#   if (current_python$status) {
#     packageStartupMessage(sprintf("Using existing Python: %s", current_python$path))
#     return(TRUE)
#   }
#
#
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#
#   if (conda_available$status) {
#     print_status("Conda", conda_available$path, TRUE)
#     conda_envs <- reticulate::conda_list()
#
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
#
#       if (file.exists(selected_env)) {
#         packageStartupMessage(sprintf("Using environment: %s", selected_env))
#         tryCatch({
#           reticulate::use_python(selected_env, required = TRUE)
#           if (!reticulate::py_module_available("flair")) {
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
#
#   packageStartupMessage("Using system Python...")
#   python_path <- Sys.which("python3")
#   if (python_path == "") python_path <- Sys.which("python")
#
#
#   if (python_path != "" && file.exists(python_path)) {
#     tryCatch({
#       reticulate::use_python(python_path, required = TRUE)
#       if (!reticulate::py_module_available("flair")) {
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


## Initialize Required Modules -------------------------------------------------
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


# Package Initialization -------------------------------------------------------

## .onLoad() -------------------------------------------------------------------
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
    # 先嘗試初始化模組
    init_result <- initialize_modules()

    if (init_result$status) {
      # 如果初始化成功，直接顯示資訊
      sys_info <- get_system_info()
      packageStartupMessage("\nEnvironment Information:")
      packageStartupMessage(sprintf("OS: %s (%s)",
                                    as.character(sys_info$name),
                                    as.character(sys_info$version)))

      if (is_docker()) {
        print_status("Docker", "Enabled", TRUE)
      }

      # 顯示 Python 版本
      config <- reticulate::py_config()
      python_version <- as.character(config$version)
      print_status("Python", python_version, check_python_version(python_version))

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

      packageStartupMessage("")
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # 檢查 Word Embeddings
      if (verify_embeddings(quiet = TRUE)) {
        gensim_version <- tryCatch({
          gensim <- reticulate::import("gensim")
          reticulate::py_get_attr(gensim, "__version__")
        }, error = function(e) "Unknown")
        print_status("Word Embeddings", gensim_version, TRUE)
      } else {
        print_status("Word Embeddings", "Not Available", FALSE,
                     sprintf("Word embeddings feature is not detected..."))
      }
    } else {
      # 如果初始化失敗，執行完整安裝流程
      Sys.unsetenv("RETICULATE_PYTHON")
      Sys.unsetenv("VIRTUALENV")
      options(reticulate.python.initializing = TRUE)

      # 執行環境設置
      env_setup <- check_conda_env()
      if (!env_setup) {
        return(invisible(NULL))
      }
    }

    # 歡迎訊息
    packageStartupMessage("")
    msg <- sprintf("%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
                   .pkgenv$colors$bold, .pkgenv$colors$blue,
                   .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
                   .pkgenv$colors$bold, .pkgenv$colors$yellow,
                   init_result$versions$flair,
                   .pkgenv$colors$reset, .pkgenv$colors$reset_bold)
    packageStartupMessage(msg)

  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}

# .onAttach <- function(libname, pkgname) {
#   original_python <- Sys.getenv("RETICULATE_PYTHON")
#   original_virtualenv <- Sys.getenv("VIRTUALENV")
#   on.exit({
#     if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
#     if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
#   })
#
#   tryCatch({
#     Sys.unsetenv("RETICULATE_PYTHON")
#     Sys.unsetenv("VIRTUALENV")
#     options(reticulate.python.initializing = TRUE)
#
#     # 環境資訊
#     sys_info <- get_system_info()
#     packageStartupMessage("\n")
#     packageStartupMessage("\nEnvironment Information:")
#     packageStartupMessage(sprintf("OS: %s (%s)",
#                                   as.character(sys_info$name),
#                                   as.character(sys_info$version)))
#
#     # 打印當前 Python 環境信息
#     # current_env <- tryCatch({
#     #   py_config <- reticulate::py_config()
#     #   sprintf("\nCurrent Python Environment:\n  - Path: %s\n  - Type: %s\n  - Version: %s",
#     #           py_config$python,
#     #           if(!is.null(py_config$virtualenv)) "virtualenv" else
#     #             if(!is.null(py_config$conda)) "conda" else "system",
#     #           py_config$version)
#     # }, error = function(e) "\nUnable to detect Python environment")
#     # current_env <- tryCatch({
#     #   py_config <- reticulate::py_config()
#     #   sprintf("\nCurrent Python Environment:\n  - Path: %s\n  - Type: %s\n  - Version: %s",
#     #           py_config$python,
#     #           if(!is.null(py_config$virtualenv)) "virtualenv" else
#     #             if(!is.null(py_config$conda)) "conda" else "system",
#     #           py_config$version)
#     # }, error = function(e) "\nUnable to detect Python environment")
#
#     # packageStartupMessage(current_env)
#
#     # Docker 狀態檢查
#     if (is_docker()) {
#       print_status("Docker", "Enabled", TRUE)
#     }
#
#     # Python enviroment setting
#     env_setup <- check_conda_env()
#     if (!env_setup) {
#       return(invisible(NULL))
#     }
#
#     # Python version check
#     config <- reticulate::py_config()
#     python_version <- as.character(config$version)
#     print_status("Python", python_version, check_python_version(python_version))
#
#     # init modules and status check
#     init_result <- initialize_modules()
#     if (init_result$status) {
#       # 1. GPU status check
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
#       packageStartupMessage("")
#       # version information
#       print_status("PyTorch", init_result$versions$torch, TRUE)
#       print_status("Transformers", init_result$versions$transformers, TRUE)
#       print_status("Flair NLP", init_result$versions$flair, TRUE)
#
#       # Word Embeddings status check
#       if (verify_embeddings(quiet = TRUE)) {
#         gensim_version <- tryCatch({
#           gensim <- reticulate::import("gensim")
#           reticulate::py_get_attr(gensim, "__version__")
#         }, error = function(e) "Unknown")
#         print_status("Word Embeddings", gensim_version, TRUE)
#       } else {
#         print_status("Word Embeddings", "Not Available", FALSE,
#                      sprintf("Word embeddings feature is not detected.\n\nInstall with:\nIn R:\n  reticulate::py_install('flair[word-embeddings]', pip = TRUE)\n  system(paste(Sys.which('python3'), '-m pip install flair[word-embeddings]'))\n\nIn terminal:\n  pip install flair[word-embeddings]"))
#       }
#
#       packageStartupMessage("")
#       # Welcome messeges
#       msg <- sprintf(
#         "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
#         .pkgenv$colors$bold, .pkgenv$colors$blue,
#         .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
#         .pkgenv$colors$bold, .pkgenv$colors$yellow,
#         init_result$versions$flair,
#         .pkgenv$colors$reset, .pkgenv$colors$reset_bold
#       )
#       packageStartupMessage(msg)
#     }
#   }, error = function(e) {
#     packageStartupMessage("Error during initialization: ", as.character(e$message))
#   }, finally = {
#     options(reticulate.python.initializing = FALSE)
#   })
#
#   invisible(NULL)
# }
# .onAttach <- function(libname, pkgname) {
#   original_python <- Sys.getenv("RETICULATE_PYTHON")
#   original_virtualenv <- Sys.getenv("VIRTUALENV")
#
#   on.exit({
#     if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
#     if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
#   })
#
#   tryCatch({
#     Sys.unsetenv("RETICULATE_PYTHON")
#     Sys.unsetenv("VIRTUALENV")
#     options(reticulate.python.initializing = TRUE)
#
#     # 環境信息
#     sys_info <- get_system_info()
#     packageStartupMessage("\nEnvironment Information:")
#     packageStartupMessage(sprintf("OS: %s (%s)",
#                                   as.character(sys_info$name),
#                                   as.character(sys_info$version)))
#
#     # Docker 狀態檢查
#     if (is_docker()) {
#       print_status("Docker", "Enabled", TRUE)
#     }
#
#     # 設置和檢查環境
#     env_setup <- check_environment_status()
#     if (!env_setup) {
#       return(invisible(NULL))
#     }
#
#     # Python 版本檢查
#     config <- reticulate::py_config()
#     python_version <- as.character(config$version)
#     print_status("Python", python_version, check_python_version(python_version))
#
#     # 初始化模組和檢查狀態
#     init_result <- initialize_modules()
#     if (init_result$status) {
#       # 這裡保持其他初始化代碼不變
#     }
#   }, error = function(e) {
#     packageStartupMessage("Error during initialization: ", as.character(e$message))
#   }, finally = {
#     options(reticulate.python.initializing = FALSE)
#   })
#
#   invisible(NULL)
# }

# .onAttach <- function(libname, pkgname) {
#   original_python <- Sys.getenv("RETICULATE_PYTHON")
#   original_virtualenv <- Sys.getenv("VIRTUALENV")
#
#   on.exit({
#     if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
#     if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
#   })
#
#   tryCatch({
#     Sys.unsetenv("RETICULATE_PYTHON")
#     Sys.unsetenv("VIRTUALENV")
#     options(reticulate.python.initializing = TRUE)
#
#
#     # 環境資訊
#     sys_info <- get_system_info()
#     packageStartupMessage("\n")
#     packageStartupMessage("\nEnvironment Information:")
#     packageStartupMessage(sprintf("OS: %s (%s)",
#                                   as.character(sys_info$name),
#                                   as.character(sys_info$version)))
#
#
#     # Docker 狀態檢查
#     if (is_docker()) {
#       print_status("Docker", "Enabled", TRUE)
#     }
#     # Python enviroment setting
#     env_setup <- check_conda_env()
#     if (!env_setup) {
#       return(invisible(NULL))
#     }
#
#
#     # Python version check
#     config <- reticulate::py_config()
#     python_version <- as.character(config$version)
#     print_status("Python", python_version, check_python_version(python_version))
#
#
#     # init modules and status check
#     init_result <- initialize_modules()
#     if (init_result$status) {
#       # 1. GPU status check
#       cuda_info <- init_result$device$cuda
#       mps_available <- init_result$device$mps
#
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
#       packageStartupMessage("")
#
#       # version information
#       print_status("PyTorch", init_result$versions$torch, TRUE)
#       print_status("Transformers", init_result$versions$transformers, TRUE)
#       print_status("Flair NLP", init_result$versions$flair, TRUE)
#
#
#       # Word Embeddings status check
#       if (verify_embeddings(quiet = TRUE)) {
#         gensim_version <- tryCatch({
#           gensim <- reticulate::import("gensim")
#           reticulate::py_get_attr(gensim, "__version__")
#         }, error = function(e) "Unknown")
#         print_status("Word Embeddings", gensim_version, TRUE)
#       } else {
#         print_status("Word Embeddings", "Not Available", FALSE,
#                      sprintf("Word embeddings feature is not detected.\n\nInstall with:\nIn R:\n  reticulate::py_install('flair[word-embeddings]', pip = TRUE)\n  system(paste(Sys.which('python3'), '-m pip install flair[word-embeddings]'))\n\nIn terminal:\n  pip install flair[word-embeddings]"))
#       }
#
#       packageStartupMessage("")
#       # Welcome messeges
#       msg <- sprintf(
#         "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
#         .pkgenv$colors$bold, .pkgenv$colors$blue,
#         .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
#         .pkgenv$colors$bold, .pkgenv$colors$yellow,
#         init_result$versions$flair,
#         .pkgenv$colors$reset, .pkgenv$colors$reset_bold
#       )
#       packageStartupMessage(msg)
#     }
#   }, error = function(e) {
#     packageStartupMessage("Error during initialization: ", as.character(e$message))
#   }, finally = {
#     options(reticulate.python.initializing = FALSE)
#   })
#
#
#   invisible(NULL)
# }
