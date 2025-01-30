#' @keywords internal
"_PACKAGE"


#' @import reticulate
NULL


# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())


# Add version constants
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

# Add installation state tracking
.pkgenv$installation_state <- new.env(parent = emptyenv())

# Embeddings Verification function ---------------------------------------------
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


# Check Docker -----------------------------------------------------------------
#' Check if running in Docker
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
#' Compare version numbers
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


# Print Messages ---------------------------------------------------------------
#' Print Formatted Messages
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


#' Check package installation state
#' @noRd
check_package_state <- function(pkg_name, required_version, quiet = FALSE) {
  tryCatch({
    # 特殊处理 sentencepiece 在 M1 Mac 上的情况
    if (pkg_name == "sentencepiece" &&
        Sys.info()["sysname"] == "Darwin" &&
        Sys.info()["machine"] == "arm64") {

      # 如果已经有任何版本的 sentencepiece 存在，就认为它是可用的
      if (reticulate::py_module_available("sentencepiece")) {
        return(TRUE)
      }
    }

    # 检查缓存状态
    state_key <- paste0(pkg_name, "_", required_version)
    if (!is.null(.pkgenv$installation_state[[state_key]])) {
      return(TRUE)
    }

    # 尝试导入包
    if (!reticulate::py_module_available(pkg_name)) {
      return(FALSE)
    }

    # 检查版本
    if (required_version != "") {
      cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
      installed <- reticulate::py_eval(cmd)
      if (is.null(installed)) return(FALSE)

      # 对于 sentencepiece，只要版本存在就接受
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
#     # First check if we have a cached state
#     state_key <- paste0(pkg_name, "_", required_version)
#     if (!is.null(.pkgenv$installation_state[[state_key]])) {
#       return(TRUE)
#     }
#
#     # Try importing the package
#     if (!reticulate::py_module_available(pkg_name)) {
#       return(FALSE)
#     }
#
#     # Check version if required
#     if (required_version != "") {
#       cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
#       installed <- reticulate::py_eval(cmd)
#       if (is.null(installed)) return(FALSE)
#
#       version_ok <- package_version(installed) >= package_version(required_version)
#       if (version_ok) {
#         # Cache the successful state
#         .pkgenv$installation_state[[state_key]] <- TRUE
#       }
#       return(version_ok)
#     }
#
#     # If no version specified, just cache that it's available
#     .pkgenv$installation_state[[state_key]] <- TRUE
#     return(TRUE)
#   }, error = function(e) {
#     if (!quiet) {
#       warning(sprintf("Error checking %s: %s", pkg_name, e$message))
#     }
#     return(FALSE)
#   })
# }

#' Install Required Dependencies
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

  # Parse requirement string to name and version
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

        # Special handling for sentencepiece
        if (pkg_name == "sentencepiece") {
          install_opts <- .pkgenv$package_constants$install_options$sentencepiece
          result <- reticulate::py_install(
            packages = pkg_name,
            pip = TRUE,
            envname = venv,
            pip_options = install_opts
          )
        } else {
          result <- install_fn()
        }

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

  # Get installation sequence based on system
  # 在 install_dependencies 函数中修改 get_install_sequence
  # 在 install_dependencies 函数中修改 get_install_sequence
  get_install_sequence <- function() {
    is_m1 <- Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64"

    # 先準備 core packages
    core_packages <- c(
      sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
      sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
      sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
    )

    # 如果不是 M1，添加 sentencepiece
    if (!is_m1) {
      core_packages <- c(core_packages,
                         sprintf("sentencepiece==%s", .pkgenv$package_constants$sentencepiece_version))
    }

    base_sequence <- list(
      torch = list(
        name = "PyTorch",
        packages = if(is_m1) {
          c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version))
        } else {
          c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
            "torchvision")
        }
      ),
      core = list(
        name = "Core dependencies",
        packages = core_packages
      ),
      flair = list(
        name = "Flair Base",
        packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
      )
    )

    if (!is_m1) {
      base_sequence$gensim <- list(
        name = "Gensim",
        packages = sprintf("gensim>=%s", .pkgenv$package_constants$gensim_version)
      )
    }

    return(base_sequence)
  }
  # get_install_sequence <- function() {
  #   is_m1 <- Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64"
  #
  #   base_sequence <- list(
  #     torch = list(
  #       name = "PyTorch",
  #       packages = if(is_m1) {
  #         c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version))
  #       } else {
  #         c(sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
  #           "torchvision")
  #       }
  #     ),
  #     core = list(
  #       name = "Core dependencies",
  #       packages = c(
  #         sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
  #         sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
  #         sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
  #         sprintf("sentencepiece==%s", .pkgenv$package_constants$sentencepiece_version)
  #       )
  #     ),
  #     flair = list(
  #       name = "Flair Base",
  #       packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
  #     )
  #   )
  #
  #   if (!is_m1) {
  #     base_sequence$gensim <- list(
  #       name = "Gensim",
  #       packages = sprintf("gensim>=%s", .pkgenv$package_constants$gensim_version)
  #     )
  #   }
  #
  #   return(base_sequence)
  # }

  # Main installation process
  tryCatch({
    in_docker <- is_docker()

    # Quick check if all dependencies are already installed
    install_sequence <- get_install_sequence()
    all_installed <- TRUE
    missing_packages <- character(0)

    # Check all packages first
    for (pkg in install_sequence) {
      for (pkg_req in pkg$packages) {
        req <- parse_requirement(pkg_req)
        if (!check_package_state(req$name, req$version, quiet = TRUE)) {
          all_installed <- FALSE
          missing_packages <- c(missing_packages, pkg_req)
        }
      }
    }

    # If everything is installed, return early
    if (all_installed) {
      if (!quiet) log_msg("All dependencies are already installed and up to date")
      return(TRUE)
    }

    # If not all installed, proceed with installation
    env_msg <- if (!is.null(venv)) {
      sprintf(" in %s", venv)
    } else {
      if (in_docker) " in Docker environment" else ""
    }

    log_msg(sprintf("Installing missing dependencies%s: %s",
                    env_msg,
                    paste(missing_packages, collapse = ", ")))

    if (in_docker) {
      pip_path <- "/opt/venv/bin/pip"

      # Install missing packages
      for (pkg_req in missing_packages) {
        req <- parse_requirement(pkg_req)
        log_msg(sprintf("Installing %s...", pkg_req))
        result <- retry_install(function() {
          system2("sudo", c("-H", "pip", "install", "--no-cache-dir", pkg_req))
        }, req$name)

        if (!result$success) {
          log_msg(result$error, TRUE)
          return(FALSE)
        }
      }
    } else {
      # Regular installation
      for (pkg_req in missing_packages) {
        req <- parse_requirement(pkg_req)
        log_msg(sprintf("Installing %s...", pkg_req))
        result <- retry_install(function() {
          reticulate::py_install(
            packages = pkg_req,
            pip = TRUE,
            envname = venv,
            ignore_installed = FALSE
          )
        }, req$name)

        if (!result$success) {
          log_msg(result$error, TRUE)
          return(FALSE)
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

# Check and Setup Conda -----------------------------------------------------
#' Check and setup conda environment
#'
#' @param show_status Show status messages if TRUE
#' @param force_check Force check and reinstall if needed
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
check_conda_env <- function(show_status = FALSE, force_check = FALSE) {
  # Reset installation state if force check
  if (force_check) {
    .pkgenv$installation_state <- new.env(parent = emptyenv())
  }

  # Check for Docker environment first
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
      tryCatch({
        reticulate::use_python(docker_python, required = TRUE)
        # Force check or check if flair is not available
        if (force_check || !reticulate::py_module_available("flair")) {
          install_dependencies(NULL)
        }
        return(TRUE)
      }, error = function(e) {
        packageStartupMessage(sprintf("Error using Docker environment: %s", e$message))
      })
    }
  }

  # Standard environment checks
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
    packageStartupMessage(sprintf("Using Python: %s", current_python$path))
    return(TRUE)
  }

  # Check Conda availability
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
        tryCatch({
          reticulate::use_python(selected_env, required = TRUE)
          if (force_check || !reticulate::py_module_available("flair")) {
            install_dependencies("flair_env")
          }
          return(TRUE)
        }, error = function(e) {
          packageStartupMessage(sprintf("Error using environment: %s", e$message))
          FALSE
        })
      }
    }
  }

  # Try system Python as last resort
  packageStartupMessage("Using system Python...")
  python_path <- Sys.which("python3")
  if (python_path == "") python_path <- Sys.which("python")

  if (python_path != "" && file.exists(python_path)) {
    tryCatch({
      reticulate::use_python(python_path, required = TRUE)
      if (force_check || !reticulate::py_module_available("flair")) {
        install_dependencies(NULL)
      }
      return(TRUE)
    }, error = function(e) {
      packageStartupMessage(sprintf("Error using system Python: %s", e$message))
      FALSE
    })
  }

  packageStartupMessage("No suitable Python installation found")
  return(FALSE)
}


# Initialize Required Modules -----------------------------------------------
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
      packageStartupMessage("\n\n")
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

