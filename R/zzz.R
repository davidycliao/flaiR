#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Initialize package cache and flags
.pkgenv$version_cache <- new.env(parent = emptyenv())
.pkgenv$is_docker_cache <- NULL
.pkgenv$env_setup_complete <- FALSE

# Package constants
.pkgenv$package_constants <- list(
  python_min_version = "3.9",
  python_max_version = "3.12",
  numpy_version = "1.26.4",
  scipy_version = "1.12.0",
  flair_min_version = "0.11.3",
  torch_version = "2.2.0",
  transformers_version = "4.37.2",
  gensim_version = "4.0.0"
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

# Utility Functions ----------------------------------------------------------

#' Safe Environment Variable Setting
#' @noRd
safe_setenv <- function(name, value) {
  current <- Sys.getenv(name, unset = NA)
  if (is.na(current) || current != value) {
    # 使用最基本的方式設置環境變量
    do.call(Sys.setenv, stats::setNames(list(value), name))
    return(TRUE)
  }
  return(FALSE)
}

#' Check if running in Docker
#' @noRd
is_docker <- function() {
  if (!is.null(.pkgenv$is_docker_cache)) {
    return(.pkgenv$is_docker_cache)
  }

  result <- FALSE
  if (file.exists("/.dockerenv")) {
    result <- TRUE
  } else if (Sys.info()["sysname"] == "Linux") {
    tryCatch({
      if (file.exists("/proc/1/cgroup")) {
        cgroup_content <- readLines("/proc/1/cgroup", n = 1)
        result <- grepl("docker", cgroup_content)
      }
    }, error = function(e) {
      result <- FALSE
    })
  }

  .pkgenv$is_docker_cache <- result
  return(result)
}

#' Print Formatted Messages
#' @noRd
print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  symbol <- if (status) "\u2713" else "\u2717"
  color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red
  formatted_component <- sprintf("%-20s", component)

  msg <- sprintf("%s %s%s%s  %s",
                 formatted_component,
                 color,
                 symbol,
                 .pkgenv$colors$reset,
                 if(!is.null(version)) version else "")

  if (component == "Python") {
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
        "\n%sWarning: Python 3.13+ has not been fully tested with current Flair NLP versions.%s",
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset
      ))
    }
  }

  packageStartupMessage(msg)
  if (!is.null(extra_message)) {
    packageStartupMessage(extra_message)
  }
}

#' Get System Information
#' @noRd
get_system_info <- function() {
  os_name <- Sys.info()["sysname"]
  os_version <- switch(
    os_name,
    "Darwin" = system("sw_vers -productVersion", intern = TRUE)[1],
    "Windows" = system("ver", intern = TRUE)[1],
    system("cat /etc/os-release | grep PRETTY_NAME", intern = TRUE)[1]
  )
  list(name = os_name, version = os_version)
}

#' Compare version numbers
#' @noRd
check_version <- function(pkg_name, required_version) {
  cache_key <- paste(pkg_name, required_version, sep = "_")

  if (exists(cache_key, envir = .pkgenv$version_cache)) {
    return(get(cache_key, envir = .pkgenv$version_cache))
  }

  result <- tryCatch({
    if(required_version == "") return(TRUE)
    cmd <- sprintf("import %s; print(%s.__version__)", pkg_name, pkg_name)
    installed <- reticulate::py_eval(cmd)
    if(is.null(installed)) return(FALSE)
    package_version(installed) >= package_version(required_version)
  }, error = function(e) FALSE)

  assign(cache_key, result, envir = .pkgenv$version_cache)
  return(result)
}

#' Install Dependencies
#' @noRd
install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  if (!is.null(.pkgenv$env_setup_complete) && .pkgenv$env_setup_complete) {
    return(TRUE)
  }

  log_msg <- function(msg, is_error = FALSE) {
    if (!quiet) {
      if (is_error) {
        packageStartupMessage(.pkgenv$colors$red, msg, .pkgenv$colors$reset)
      } else {
        packageStartupMessage(msg)
      }
    }
  }

  # Check if all required packages are installed with correct versions
  required_packages <- list(
    torch = .pkgenv$package_constants$torch_version,
    numpy = .pkgenv$package_constants$numpy_version,
    transformers = .pkgenv$package_constants$transformers_version,
    flair = .pkgenv$package_constants$flair_min_version
  )

  needs_install <- FALSE
  for (pkg_name in names(required_packages)) {
    if (!check_version(pkg_name, required_packages[[pkg_name]])) {
      needs_install <- TRUE
      break
    }
  }

  if (!needs_install) {
    .pkgenv$env_setup_complete <- TRUE
    return(TRUE)
  }

  # Existing installation logic...
  # [Your existing installation code here]

  .pkgenv$env_setup_complete <- TRUE
  return(TRUE)
}

#' Initialize Required Modules
#' @noRd
initialize_modules <- function() {
  if (!is.null(.pkgenv$modules$initialized)) {
    return(.pkgenv$modules)
  }

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
    .pkgenv$modules$initialized <- TRUE

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
  # Set environment variables only if needed
  safe_setenv("KMP_DUPLICATE_LIB_OK", "TRUE")

  if (is_docker()) {
    safe_setenv("PYTHONNOUSERSITE", "1")
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      safe_setenv("RETICULATE_PYTHON", docker_python)
    }
  }

  if (Sys.info()["sysname"] == "Darwin") {
    if (Sys.info()["machine"] == "arm64") {
      safe_setenv("PYTORCH_ENABLE_MPS_FALLBACK", "1")
    }
    safe_setenv("OMP_NUM_THREADS", "1")
    safe_setenv("MKL_NUM_THREADS", "1")
  }

  options(reticulate.prompt = FALSE)
}

#' @noRd
#' @noRd
.onAttach <- function(libname, pkgname) {
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  on.exit({
    if (original_python != "") safe_setenv("RETICULATE_PYTHON", original_python)
    if (original_virtualenv != "") safe_setenv("VIRTUALENV", original_virtualenv)
  })

  tryCatch({
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # 環境資訊
    sys_info <- get_system_info()
    packageStartupMessage("\nEnvironment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # 檢查現有的 Python 環境
    current_python <- tryCatch({
      config <- reticulate::py_config()
      if (reticulate::py_module_available("flair") &&
          reticulate::py_module_available("torch") &&
          reticulate::py_module_available("transformers")) {
        packageStartupMessage(sprintf("Using existing Python: %s", config$python))
        list(status = TRUE, path = config$python, version = config$version)
      } else {
        list(status = FALSE)
      }
    }, error = function(e) {
      list(status = FALSE)
    })

    # Python 版本檢查
    if (current_python$status) {
      python_version <- as.character(current_python$version)
      print_status("Python", python_version, check_python_version(python_version))
    } else {
      # 如果沒有現有環境，進行環境設置
      env_setup <- check_conda_env()
      if (!env_setup) {
        return(invisible(NULL))
      }
      config <- reticulate::py_config()
      python_version <- as.character(config$version)
      print_status("Python", python_version, check_python_version(python_version))
    }

    # 模組初始化與狀態檢查
    init_result <- initialize_modules()
    if (init_result$status) {
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

      # 套件版本資訊
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # Word Embeddings 狀態
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

      # 歡迎訊息
      msg <- sprintf(
        "\n%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
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
