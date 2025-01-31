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

  # Core Dependencies
  numpy_version = ">=1.22.4,<1.29.0",
  scipy_version = "1.12.0",

  # Core Python Packages
  torch_version = ">=2.0.0,<2.6.0",
  transformers_version = ">=4.30.0",
  flair_min_version = "0.15.0",
  gensim_version = ">=4.3.2",

  # transformers
  install_configs = list(
    transformers = list(
      name = "transformers[sentencepiece]",
      version = ">=4.30.0",
      options = NULL  # removed --no-deps
    )
  )
)

### Add installation state tracking
.pkgenv$installation_state <- new.env(parent = emptyenv())

### ANSI Color Codes
.pkgenv$colors <- list(
  green = "\033[32m",
  red = "\033[31m",
  blue = "\033[34m",
  yellow = "\033[33m",
  reset = "\033[39m",
  bold = "\033[1m",
  reset_bold = "\033[22m"
)

### Initialize Module Storage
.pkgenv$modules <- list(
  flair = NULL,
  flair_embeddings = NULL,
  torch = NULL
)

# Utilities --------------------------------------------------------------------

### Embeddings Verification ----------------------------------------------------
#' @title Embedding Verification
#'
#' @noRd
verify_embeddings <- function(quiet = TRUE) {
  tryCatch({
    if(!quiet) log_msg("Verifying word embeddings support...", show_status = TRUE)
    gensim <- reticulate::import("gensim.models")
    if(!quiet) log_msg("Word embeddings support verified", show_status = TRUE)
    TRUE
  }, error = function(e) {
    if(!quiet) log_msg(
      sprintf("%sWarning: Word embeddings support not available%s",
              .pkgenv$colors$yellow,
              .pkgenv$colors$reset),
      is_error = TRUE
    )
    FALSE
  })
}

### Get System Information -----------------------------------------------------

#' @title Get System Information
#'
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

### Check Docker  --------------------------------------------------------------
#' @title Check Docker
#'
#' @noRd
is_docker <- function() {
  if (file.exists("/.dockerenv")) {
    return(TRUE)
  }

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

### Compare Version Numbers ----------------------------------------------------
#' @title Compare Version Numbers
#'
#' @noRd
check_python_version <- function(version) {
  if (!is.character(version)) {
    return(FALSE)
  }

  min_v <- .pkgenv$package_constants$python_min_version
  max_v <- .pkgenv$package_constants$python_max_version

  parse_version <- function(v) {
    ver_parts <- strsplit(v, "\\.")[[1]]
    if (length(ver_parts) < 2) return(c(0, 0))
    c(as.numeric(ver_parts[1]), as.numeric(ver_parts[2]))
  }

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

### Message Handling  ----------------------------------------------------------

#' @title Log Message Handling
#'
#' @noRd
log_msg <- function(msg, is_error = FALSE, show_status = TRUE, quiet = FALSE) {
  should_show <- is_error ||
    (!quiet && show_status) ||
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

#' @title Print Status Messages
#'
#' @noRd
print_status <- function(component, version = NULL, status = TRUE,
                         extra_message = NULL, quiet = FALSE) {
  if (!quiet || !status) {
    symbol <- if (status) "\u2713" else "\u2717"
    color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red

    formatted_component <- sprintf("%-20s", paste0(component, ":"))

    msg <- sprintf("%s%s%s%s %s",
                   formatted_component,
                   color,
                   symbol,
                   .pkgenv$colors$reset,
                   if(!is.null(version)) version else "")

    if (component == "Python" && !is.null(version)) {
      ver_num <- as.numeric(strsplit(version, "\\.")[[1]][1:2])
      ver_major <- ver_num[1]
      ver_minor <- ver_num[2]

      if (ver_major == 3 && ver_minor < 9) {
        msg <- paste0(msg, sprintf(
          "\n%sWarning: Python 3.8 will be deprecated in future Flair NLP versions.%s",
          .pkgenv$colors$yellow,
          .pkgenv$colors$reset
        ))
      } else if (ver_major == 3 && ver_minor >= 13) {
        msg <- paste0(msg, sprintf(
          "\n%sWarning: Python 3.13+ compatibility not fully tested.%s",
          .pkgenv$colors$yellow,
          .pkgenv$colors$reset
        ))
      }
    }

    packageStartupMessage(msg)
    if (!is.null(extra_message) && (!quiet || !status)) {
      packageStartupMessage(extra_message)
    }
  }
}

# Install Required Dependencies ------------------------------------------------
#' @title Install Dependencies
#' @param venv Virtual environment name or NULL for system Python
#' @param max_retries Maximum number of retry attempts for failed installations
#' @param quiet Suppress status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
install_dependencies <- function(venv = NULL, quiet = TRUE) {
  # Docker installation function
  docker_install <- function(pkg_req) {
    base_pip_path <- "/opt/venv/bin/pip"

    # Fix permissions function
    fix_permissions <- function() {
      tryCatch({
        system2("sudo", c("chown", "-R", "rstudio:rstudio", "/opt/venv"))
        system2("sudo", c("chmod", "-R", "775", "/opt/venv"))
        TRUE
      }, error = function(e) FALSE)
    }

    # Clean invalid distributions
    clean_invalid_dist <- function() {
      tryCatch({
        system2("sudo", c("rm", "-rf", "/opt/venv/lib/python3.12/site-packages/~*"))
        TRUE
      }, error = function(e) FALSE)
    }

    # Installation attempts sequence
    install_attempts <- list(
      # 1. Use sudo pip install with force reinstall
      function() {
        fix_permissions()
        clean_invalid_dist()
        system2("sudo", c(base_pip_path, "install", "--no-cache-dir",
                          "--force-reinstall", "--no-deps", pkg_req))
      },
      # 2. Use pip install to user directory
      function() {
        system2("sudo", c(base_pip_path, "install", "--no-cache-dir",
                          "--force-reinstall", "--user", pkg_req))
      },
      # 3. Use Python -m pip
      function() {
        fix_permissions()
        system2("sudo", c("/opt/venv/bin/python", "-m", "pip", "install",
                          "--no-cache-dir", "--force-reinstall", pkg_req))
      }
    )

    # Clean before installation
    clean_invalid_dist()

    # Try installation methods sequentially
    for (attempt in install_attempts) {
      result <- tryCatch({
        attempt()
      }, error = function(e) 1)

      if (result == 0) {
        fix_permissions()
        return(TRUE)
      }
    }

    # Last attempt
    result <- tryCatch({
      fix_permissions()
      clean_invalid_dist()
      system2("sudo", c("pip3", "install", "--no-cache-dir",
                        "--force-reinstall", pkg_req))
    }, error = function(e) 1)

    fix_permissions()
    return(result == 0)
  }

  # Mac specialized installation function
  mac_install <- function(pkg_req) {
    if (grepl("sentencepiece", pkg_req)) {
      tryCatch({
        # Check if required tools are already installed
        tools_check <- list(
          cmake = system("which cmake", ignore.stdout = TRUE) == 0,
          pkg_config = system("which pkg-config", ignore.stdout = TRUE) == 0,
          protobuf = system("which protoc", ignore.stdout = TRUE) == 0
        )

        # Only install missing tools
        if (!all(unlist(tools_check))) {
          if (system("which brew", ignore.stdout = TRUE) != 0) {
            stop("Homebrew is required but not installed")
          }

          if (!tools_check$cmake || !tools_check$pkg_config) {
            system("brew install cmake pkg-config")
          }

          if (!tools_check$protobuf) {
            system("brew install protobuf")
          }
        }

        # Preserve existing environment settings
        current_target <- Sys.getenv("MACOSX_DEPLOYMENT_TARGET")
        if (current_target == "") {
          Sys.setenv(MACOSX_DEPLOYMENT_TARGET = "10.14")
        }

        # Try installation with compilation options
        install_cmd <- sprintf(
          "pip install --no-cache-dir %s --no-deps --no-build-isolation",
          pkg_req
        )

        if (system(install_cmd) != 0) {
          # Fallback to more lenient compilation
          install_cmd <- sprintf(
            "ARCHFLAGS='-arch x86_64' pip install --no-cache-dir %s --no-deps",
            pkg_req
          )
          if (system(install_cmd) != 0) {
            return(FALSE)
          }
        }

        return(TRUE)
      }, error = function(e) {
        warning(sprintf("Failed to install build dependencies: %s", e$message))
        return(FALSE)
      })
    }

    # Standard installation for other packages
    tryCatch({
      reticulate::py_install(
        packages = pkg_req,
        pip = TRUE,
        envname = venv,
        ignore_installed = FALSE
      )
      return(TRUE)
    }, error = function(e) {
      warning(sprintf("Failed to install %s: %s", pkg_req, e$message))
      return(FALSE)
    })
  }

  # Regular installation function
  standard_install <- function(pkg_req, venv) {
    tryCatch({
      reticulate::py_install(
        packages = pkg_req,
        pip = TRUE,
        envname = venv,
        ignore_installed = FALSE
      )
      return(TRUE)
    }, error = function(e) {
      log_msg(sprintf("Failed to install %s: %s", pkg_req, e$message), TRUE)
      return(FALSE)
    })
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

  # Parse requirement string
  parse_requirement <- function(pkg_req) {
    if(grepl(">=|==|<=", pkg_req)) {
      parts <- strsplit(pkg_req, ">=|==|<=")[[1]]
      list(name = trimws(parts[1]), version = trimws(parts[2]))
    } else {
      list(name = trimws(pkg_req), version = "")
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
          sprintf("transformers[sentencepiece]>=%s", .pkgenv$package_constants$transformers_version)
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
    # Environment check
    is_mac <- Sys.info()["sysname"] == "Darwin"
    is_arm_mac <- is_mac && Sys.info()["machine"] == "arm64"

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

    # Choose installation method based on environment
    if (is_mac) {
      # Mac system special handling
      for (pkg in install_sequence) {
        log_msg(sprintf("Checking %s...", pkg$name))
        for (pkg_req in pkg$packages) {
          req <- parse_requirement(pkg_req)
          if (!check_version(req$name, req$version)) {
            log_msg(sprintf("Installing %s...", pkg_req))
            result <- mac_install(pkg_req)
            if (!result) {
              log_msg(sprintf("Failed to install %s", pkg_req), TRUE)
              return(FALSE)
            }
          } else {
            log_msg(sprintf("%s is already installed with required version", req$name))
          }
        }
      }
    } else if (in_docker) {
      # Docker environment installation
      for (pkg in install_sequence) {
        log_msg(sprintf("Checking %s...", pkg$name))
        for (pkg_req in pkg$packages) {
          req <- parse_requirement(pkg_req)
          if (!check_version(req$name, req$version)) {
            log_msg(sprintf("Installing %s...", pkg_req))
            result <- docker_install(pkg_req)
            if (!result) {
              log_msg(sprintf("Failed to install %s", pkg_req), TRUE)
              return(FALSE)
            }
          } else {
            log_msg(sprintf("%s is already installed with required version", req$name))
          }
        }
      }
    } else {
      # Standard installation for other environments
      for (pkg in install_sequence) {
        log_msg(sprintf("Checking %s...", pkg$name))
        for (pkg_req in pkg$packages) {
          req <- parse_requirement(pkg_req)
          if (!check_version(req$name, req$version)) {
            log_msg(sprintf("Installing %s...", pkg_req))
            result <- standard_install(pkg_req, venv)
            if (!result) {
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

### Check Conda and Enviroment -------------------------------------------------

#' @title Check Conda and Enviroment
#'
#' @noRd
check_conda_env <- function(show_status = FALSE, force_check = FALSE, quiet = TRUE) {
  # Reset installation state if force check
  if (force_check) {
    .pkgenv$installation_state <- new.env(parent = emptyenv())
  }

  # Docker environment check
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
        return(FALSE)
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
    log_msg(sprintf("Using Python: %s", current_python$path),
            show_status = show_status, quiet = quiet)
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
    if (show_status) {
      print_status("Conda", conda_available$path, TRUE, quiet = quiet)
    }

    conda_envs <- reticulate::conda_list()
    if ("r-reticulate" %in% conda_envs$name) {
      flair_envs <- conda_envs[conda_envs$name == "r-reticulate", ]
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
            install_dependencies("r-reticulate", quiet = quiet)
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

  # Try system Python as last resort
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

### Initialize Required Modules ------------------------------------------------

#' @title Initialize Required Modules
#'
#' @noRd
#'
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

# Package Initialization ----------------------------------------------------

#' @noRd
.onLoad <- function(libname, pkgname) {
  .pkgenv$initialized <- FALSE

  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  if (Sys.info()["sysname"] == "Darwin" && Sys.info()["machine"] == "arm64") {
    Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    Sys.setenv(GRPC_PYTHON_BUILD_SYSTEM_OPENSSL = 1)
    Sys.setenv(GRPC_PYTHON_BUILD_SYSTEM_ZLIB = 1)
  }

  if (Sys.info()["sysname"] == "Darwin") {
    Sys.setenv(OMP_NUM_THREADS = 1)
    Sys.setenv(MKL_NUM_THREADS = 1)
  }

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
  # 儲存原始環境設定
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  # 結束時恢復原始環境設定
  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    # 檢查是否已經初始化，避免重複安裝
    if (!is.null(.pkgenv$initialized) && .pkgenv$initialized) {
      return(invisible(NULL))
    }

    # 清除環境變數，準備初始化
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # Python environment setup (靜默設置)
    env_setup <- check_conda_env(quiet = TRUE)
    if (!env_setup) {
      return(invisible(NULL))
    }

    # Environment Information
    packageStartupMessage(strrep("\n", 18))
    packageStartupMessage("Loading flaiR R package Configuration...")
    packageStartupMessage("----------------------------------------")
    packageStartupMessage("\nEnvironment Information:")

    # Docker status check
    if (is_docker()) {
      packageStartupMessage("")
      print_status("Docker", "Enabled", TRUE, quiet = FALSE)
    }

    sys_info <- get_system_info()
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

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
        print_status("GPU", gpu_name, TRUE, quiet = FALSE)
      } else if (!is.null(mps_available) && mps_available) {
        print_status("GPU", "Mac MPS", TRUE, quiet = FALSE)
      } else {
        print_status("GPU", "CPU Only", FALSE, quiet = FALSE)
      }

      # Python version check
      config <- reticulate::py_config()
      python_version <- as.character(config$version)
      python_path <- config$python
      print_status("Python", python_version, check_python_version(python_version), quiet = FALSE)
      packageStartupMessage(sprintf("Using Python: %s", python_path))

      # Core dependencies versions
      tryCatch({
        numpy <- reticulate::import("numpy")
        torch <- reticulate::import("torch")
        transformers <- reticulate::import("transformers")

        print_status("NumPy", reticulate::py_get_attr(numpy, "__version__"), TRUE, quiet = FALSE)
        print_status("PyTorch", reticulate::py_get_attr(torch, "__version__"), TRUE, quiet = FALSE)
        print_status("Transformers", reticulate::py_get_attr(transformers, "__version__"), TRUE, quiet = FALSE)
      }, error = function(e) {
        print_status("Core Dependencies", "Not all core packages are available", FALSE, quiet = FALSE)
      })

      # Word Embeddings status - 只檢查一次
      embeddings_status <- verify_embeddings(quiet = TRUE)  # 先靜默檢查
      gensim_version <- if (embeddings_status) {
        tryCatch({
          gensim <- reticulate::import("gensim")
          reticulate::py_get_attr(gensim, "__version__")
        }, error = function(e) NULL)
      } else NULL

      if (!is.null(gensim_version)) {
        print_status("Word Embeddings", sprintf("gensim %s", gensim_version), TRUE, quiet = FALSE)
      } else {
        print_status("Word Embeddings", "Unavailable", FALSE, quiet = FALSE,
                     extra_message = sprintf(
                       "Word embeddings feature is not detected.\n\nInstall with:\nIn R:\n  reticulate::py_install('flair[word-embeddings]', pip = TRUE)\n  system(paste(Sys.which('python3'), '-m pip install flair[word-embeddings]'))\n\nIn terminal:\n  pip install flair[word-embeddings]"
                     ))
      }

      # Welcome message
      packageStartupMessage("")
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
    packageStartupMessage("\nError during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}
