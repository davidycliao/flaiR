#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Version constants
# .pkgenv$package_constants <- list(
#   python_min_version = "3.9",
#   python_max_version = "3.12",
#   numpy_version = "1.26.4",
#   scipy_version = "1.12.0",
#   flair_min_version = "0.11.3",
#   torch_version = "2.2.0",
#   transformers_version = "4.37.2"
# )

.pkgenv$package_constants <- list(
  python = list(
    python_min_version = "3.9",
    python_max_version = "3.12"
  ),
  packages = list(
    # 核心依賴
    torch = list(min = "1.5.0", exclude = "1.8"),
    numpy = "1.26.4",
    scipy = "1.12.0",
    flair = list(min = "0.11.3"),

    # Flair 相關依賴
    boto3 = list(min = "1.20.27"),
    conllu = list(min = "4.0", max = "7.0.0"),
    deprecated = list(min = "1.2.13"),
    ftfy = list(min = "6.1.0"),
    gdown = list(min = "4.4.0"),
    huggingface_hub = list(min = "0.10.0"),
    langdetect = list(min = "1.0.9"),
    lxml = list(min = "4.8.0"),
    matplotlib = list(min = "2.2.3"),
    more_itertools = list(min = "8.13.0"),
    mpld3 = list(min = "0.3"),
    pptree = list(min = "3.1"),
    python_dateutil = list(min = "2.8.2"),
    pytorch_revgrad = list(min = "0.2.0"),
    regex = list(min = "2022.1.18"),
    scikit_learn = list(min = "1.0.2"),
    segtok = list(min = "1.5.11"),
    sqlitedict = list(min = "2.0.0"),
    tabulate = list(min = "0.8.10"),
    tqdm = list(min = "4.63.0"),
    transformer_smaller_training_vocab = list(min = "0.2.3"),
    transformers = list(min = "4.25.0", max = "5.0.0", extras = "sentencepiece"),
    wikipedia_api = list(min = "0.5.7"),
    bioc = list(min = "2.0.0", max = "3.0.0")
  )
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

# Print Messages --------------------------------------------------------------
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

# Install Required Dependencies ------------------------------------------------
#' @title  Install Required Dependencies
#'
#' @param venv Virtual environment name or NULL for system Python
#' @param max_retries Maximum number of retry attempts for failed installations
#' @param quiet Suppress status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd

# 版本規格轉換函數
create_version_spec <- function(pkg_info) {
  if (is.character(pkg_info)) return(pkg_info)

  specs <- c()
  if (!is.null(pkg_info$min)) specs <- c(specs, sprintf(">=%s", pkg_info$min))
  if (!is.null(pkg_info$max)) specs <- c(specs, sprintf("<%s", pkg_info$max))
  if (!is.null(pkg_info$exclude)) specs <- c(specs, sprintf("!=%s", pkg_info$exclude))

  spec <- paste(specs, collapse=",")
  if (!is.null(pkg_info$extras)) {
    spec <- sprintf("%s[%s]", spec, pkg_info$extras)
  }

  spec
}

# 改進的安裝依賴函數
install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  # Helper function to log messages
  log_msg <- function(msg, is_error = FALSE) {
    if (!quiet) {
      if (is_error) {
        packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
      } else {
        packageStartupMessage(msg)
      }
    }
  }

  # 準備安裝規格
  pkg_specs <- lapply(.pkgenv$package_constants$packages, create_version_spec)

  # 建立安裝順序（某些包需要特定順序）
  install_order <- c(
    "torch",  # 基礎依賴
    "numpy",
    "scipy",
    setdiff(names(pkg_specs), c("torch", "numpy", "scipy", "flair")),
    "flair"   # 最後安裝 flair
  )

  # Helper function for installation retry logic
  retry_install <- function(pkg_name) {
    for (i in 1:max_retries) {
      if (i > 1) log_msg(sprintf("Retry attempt %d/%d for %s", i, max_retries, pkg_name))

      result <- tryCatch({
        spec <- pkg_specs[[pkg_name]]
        if (!is.null(spec)) {
          if (!is.null(venv)) {
            pip_path <- if (Sys.info()["sysname"] == "Windows") {
              file.path(venv, "Scripts", "pip.exe")
            } else {
              file.path(venv, "bin", "pip")
            }
            system2(pip_path, c("install", "--upgrade", "--no-deps", spec))
          } else {
            reticulate::py_install(
              packages = spec,
              pip = TRUE,
              envname = venv
            )
          }
        }
        TRUE
      }, error = function(e) {
        if (i == max_retries) {
          log_msg(sprintf("Failed to install %s: %s", pkg_name, e$message), TRUE)
          return(FALSE)
        }
        Sys.sleep(2 ^ i)  # Exponential backoff
        NULL
      })

      if (!is.null(result)) return(result)
    }
    FALSE
  }

  # 主安裝流程
  tryCatch({
    if (!is.null(venv)) {
      log_msg(sprintf("Using virtual environment '%s'", venv))
    }

    for (pkg_name in install_order) {
      if (!retry_install(pkg_name)) {
        log_msg(sprintf("Installation failed at package: %s", pkg_name), TRUE)
        return(FALSE)
      }
    }

    log_msg("Successfully installed all dependencies")
    return(TRUE)

  }, error = function(e) {
    log_msg(sprintf(
      "Error installing dependencies: %s\nPlease check:\n1. Internet connection\n2. Pip availability\n3. Python environment permissions",
      e$message
    ), TRUE)
    return(FALSE)
  })
}

#
# install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
#   # Helper function to log messages
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
#   # Helper function for installation retry logic
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
#   # Check Python environment
#   check_python_environment <- function() {
#     tryCatch({
#       # Get Python config
#       py_config <- reticulate::py_config()
#       if (is.null(py_config)) {
#         log_msg("Error: Could not detect Python configuration", TRUE)
#         return(FALSE)
#       }
#
#       # Check version
#       python_version <- as.character(py_config$version)
#       if (!check_python_version(python_version)) {
#         log_msg(sprintf(
#           "Warning: Python version %s might have compatibility issues",
#           python_version
#         ), TRUE)
#       }
#
#       # Check pip availability
#       pip_version <- tryCatch({
#         if (in_docker) {
#           system2("/opt/venv/bin/pip", "--version", stdout = TRUE)
#         } else {
#           reticulate::py_eval("import pip; pip.__version__", convert = TRUE)
#         }
#         TRUE
#       }, error = function(e) {
#         log_msg("Error: pip is not available in the Python environment", TRUE)
#         FALSE
#       })
#
#       if (!pip_version) return(FALSE)
#
#       return(TRUE)
#     }, error = function(e) {
#       log_msg(sprintf("Error checking Python environment: %s", e$message), TRUE)
#       return(FALSE)
#     })
#   }
#
#   # Main installation process
#   tryCatch({
#     if (!check_python_environment()) {
#       return(FALSE)
#     }
#
#     in_docker <- is_docker()
#     env_msg <- if (!is.null(venv)) {
#       sprintf(" in %s", venv)
#     } else {
#       if (in_docker) " in Docker environment" else ""
#     }
#
#     log_msg(sprintf("Installing dependencies%s...", env_msg))
#
#     if (in_docker) {
#       # Docker environment installation
#       pip_path <- "/opt/venv/bin/pip"
#
#       # Install PyTorch packages
#       torch_result <- retry_install(function() {
#         system2(pip_path, c("install", "--no-cache-dir",
#                             sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#                             "torchvision"))
#       }, "PyTorch")
#
#       if (!torch_result$success) {
#         log_msg(torch_result$error, TRUE)
#         return(FALSE)
#       }
#
#       # Install other dependencies
#       deps_result <- retry_install(function() {
#         system2(pip_path, c("install", "--no-cache-dir",
#                             sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#                             sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#                             sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
#                             "sentencepiece>=0.1.97,<0.2.0"))
#       }, "Core dependencies")
#
#       if (!deps_result$success) {
#         log_msg(deps_result$error, TRUE)
#         return(FALSE)
#       }
#
#       # Install flair
#       flair_result <- retry_install(function() {
#         system2(pip_path, c("install", "--no-cache-dir",
#                             sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)))
#       }, "Flair")
#
#       if (!flair_result$success) {
#         log_msg(flair_result$error, TRUE)
#         return(FALSE)
#       }
#
#     } else {
#       # Standard environment installation
#       packages <- list(
#         torch = c(
#           sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
#           "torchvision"
#         ),
#         core = c(
#           sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#           sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#           sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
#           "sentencepiece>=0.1.97,<0.2.0"
#         ),
#         flair = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
#       )
#
#       for (pkg_type in names(packages)) {
#         result <- retry_install(function() {
#           reticulate::py_install(
#             packages = packages[[pkg_type]],
#             pip = TRUE,
#             envname = venv
#           )
#         }, pkg_type)
#
#         if (!result$success) {
#           log_msg(result$error, TRUE)
#           return(FALSE)
#         }
#       }
#     }
#
#     log_msg("Successfully installed all dependencies")
#     return(TRUE)
#
#   }, error = function(e) {
#     log_msg(sprintf(
#       "Error installing dependencies: %s\nPlease check:\n1. Internet connection\n2. Pip availability\n3. Python environment permissions",
#       e$message
#     ), TRUE)
#     return(FALSE)
#   })
# }
#


# Check and Setup Conda -----------------------------------------------------
#' Check and setup conda environment
#'
#' @param show_status Show status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
check_conda_env <- function(show_status = FALSE) {
  # Check for Docker environment first
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
      tryCatch({
        reticulate::use_python(docker_python, required = TRUE)
        if (!reticulate::py_module_available("flair")) {
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
            if (!reticulate::py_module_available("flair")) {
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

    packageStartupMessage("Using system Python...")
    python_path <- Sys.which("python3")
    if (python_path == "") python_path <- Sys.which("python")

    if (python_path != "" && file.exists(python_path)) {
      tryCatch({
        reticulate::use_python(python_path, required = TRUE)
        if (!reticulate::py_module_available("flair")) {
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
#' Initialize Required Modules
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

#' @noRd
.onAttach <- function(libname, pkgname) {
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    sys_info <- get_system_info()
    packageStartupMessage("\nEnvironment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # Print Docker status if in Docker environment
    if (is_docker()) {
      print_status("Docker", "Enabled", TRUE)
    }

    env_setup <- check_conda_env()
    if (!env_setup) {
      return(invisible(NULL))
    }

    config <- reticulate::py_config()
    python_version <- as.character(config$version)
    print_status("Python", python_version, check_python_version(python_version))
    packageStartupMessage("")

    init_result <- initialize_modules()
    if (init_result$status) {
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # GPU check
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

      # Welcome messages
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


