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

# Utilities -----------------------------------------------------------------

### Embeddings Verification function
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

### Get System Information
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

### Check Docker
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

### Compare Version Numbers
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

### Message Handling
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


### check_conda_env
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
### Initialize Required Modules
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
