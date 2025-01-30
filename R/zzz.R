#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Package Constants ----------------------------------------------------------
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

# ANSI Color Codes ----------------------------------------------------------
.pkgenv$colors <- list(
  green = "\033[32m",
  red = "\033[31m",
  blue = "\033[34m",
  yellow = "\033[33m",
  reset = "\033[39m",
  bold = "\033[1m",
  reset_bold = "\033[22m"
)

# Module Storage -----------------------------------------------------------
.pkgenv$modules <- list(
  flair = NULL,
  flair_embeddings = NULL,
  torch = NULL
)

# Utility Functions --------------------------------------------------------

#' @noRd
is_docker <- function() {
  if (file.exists("/.dockerenv")) return(TRUE)
  if (Sys.info()["sysname"] == "Linux") {
    if (file.exists("/proc/1/cgroup")) {
      cgroup_content <- readLines("/proc/1/cgroup", n = 1)
      return(grepl("docker", cgroup_content))
    }
  }
  return(FALSE)
}

#' @noRd
check_python_version <- function(version) {
  if (!is.character(version)) return(FALSE)

  parse_version <- function(v) {
    ver_parts <- strsplit(v, "\\.")[[1]]
    if (length(ver_parts) < 2) return(c(0, 0))
    c(as.numeric(ver_parts[1]), as.numeric(ver_parts[2]))
  }

  tryCatch({
    ver <- parse_version(version)
    min_ver <- parse_version(.pkgenv$package_constants$python_min_version)
    max_ver <- parse_version(.pkgenv$package_constants$python_max_version)

    if (is.na(ver[1]) || is.na(ver[2])) return(FALSE)
    if (ver[1] < min_ver[1] || ver[1] > max_ver[1]) return(FALSE)
    if (ver[1] == min_ver[1] && ver[2] < min_ver[2]) return(FALSE)
    if (ver[1] == max_ver[1] && ver[2] > max_ver[2]) return(FALSE)

    return(TRUE)
  }, error = function(e) FALSE)
}

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
        "\n%sWarning: Python 3.13+ not fully tested with current Flair NLP.%s",
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset
      ))
    }
  }

  packageStartupMessage(msg)
  if (!is.null(extra_message)) packageStartupMessage(extra_message)
}

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

# Core Functions ---------------------------------------------------------

#' @noRd
initialize_modules <- function() {
  required_modules <- c("torch", "transformers", "flair")
  missing_modules <- character(0)

  # Check availability
  for (module in required_modules) {
    if (!reticulate::py_module_available(module)) {
      missing_modules <- c(missing_modules, module)
    }
  }

  if (length(missing_modules) > 0) {
    return(list(
      status = FALSE,
      error = sprintf("Missing modules: %s", paste(missing_modules, collapse = ", ")),
      missing = missing_modules
    ))
  }

  # Load and check modules
  tryCatch({
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)

    versions <- list(
      torch = reticulate::py_get_attr(torch, "__version__"),
      transformers = reticulate::py_get_attr(transformers, "__version__"),
      flair = reticulate::py_get_attr(flair, "__version__")
    )

    # GPU support check
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
      status = TRUE,
      versions = versions,
      device = list(cuda = cuda_info, mps = mps_available),
      missing = character(0)
    )
  }, error = function(e) {
    list(status = FALSE, error = e$message, missing = missing_modules)
  })
}

#' @noRd
check_conda_env <- function(show_status = FALSE, missing_modules = NULL) {
  verify_modules <- function(python_path) {
    tryCatch({
      reticulate::use_python(python_path, required = TRUE)
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

  # Docker environment
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      verify_result <- verify_modules(docker_python)
      if (!verify_result$status) {
        success <- install_dependencies(NULL)
        if (!success) return(FALSE)
      }
      return(TRUE)
    }
  }

  # Check current Python
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
    packageStartupMessage(sprintf("Using Python: %s", current_python$path))
    return(TRUE)
  }

  # Conda environment
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (conda_available$status) {
    if (show_status) print_status("Conda", conda_available$path, TRUE)

    if ("flair_env" %in% reticulate::conda_list()$name) {
      packageStartupMessage("Using existing flair_env")
      reticulate::use_condaenv("flair_env")
    } else {
      packageStartupMessage("Creating flair_env...")
      reticulate::conda_create("flair_env", python_version = "3.9")
      reticulate::use_condaenv("flair_env")
    }

    success <- install_dependencies("flair_env")
    return(success)
  }

  # System Python
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

  packageStartupMessage("No suitable Python found")
  return(FALSE)
}

#' @noRd
install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  # Docker specific installation
  docker_install <- function(pkg_req) {
    if (grepl("sentencepiece", pkg_req)) {
      system2("sudo", c("apt-get", "update"))
      system2("sudo", c("apt-get", "install", "-y",
                        "pkg-config", "git", "cmake",
                        "build-essential", "g++"))
    }

    install_methods <- list(
      list(cmd = "sudo", args = c("/opt/venv/bin/pip", "install", "--force-reinstall", pkg_req)),
      list(cmd = "sudo", args = c("python3", "-m", "pip", "install", "--force-reinstall", pkg_req))
    )

    for (method in install_methods) {
      if (system2(method$cmd, method$args) == 0) return(TRUE)
    }
    return(FALSE)
  }

  # Package installation sequence
  install_sequence <- list(
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

  # Installation process
  tryCatch({
    is_arm_mac <- Sys.info()["sysname"] == "Darwin" &&
      Sys.info()["machine"] == "arm64"
    if (is_arm_mac) {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = "1")
    }

    in_docker <- is_docker()
    env_msg <- if (!is.null(venv)) {
      sprintf(" in %s", venv)
    } else {
      if (in_docker) " in Docker" else ""
    }

    if (!quiet) packageStartupMessage(sprintf("Installing%s...", env_msg))

    if (in_docker) {
      for (pkg in install_sequence) {
        for (pkg_req in pkg$packages) {
          if (!quiet) packageStartupMessage(sprintf("Installing %s...", pkg_req))
          if (!docker_install(pkg_req)) return(FALSE)
        }
      }
    } else {
      for (pkg in install_sequence) {
        for (pkg_req in pkg$packages) {
          if (!quiet) packageStartupMessage(sprintf("Installing %s...", pkg_req))
          reticulate::py_install(
            packages = pkg_req,
            pip = TRUE,
            envname = venv,
            ignore_installed = FALSE
          )
        }
      }
    }

    if (!quiet) packageStartupMessage("Installation complete")
    return(TRUE)

  }, error = function(e) {
    if (!quiet) packageStartupMessage(sprintf("Installation failed: %s", e$message))
    return(FALSE)
  })
}

# Package Initialization -------------------------------------------------
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
    options(reticulate.python.initializing = TRUE)

    # 1. Display Environment Information
    sys_info <- get_system_info()
    packageStartupMessage("\n")
    packageStartupMessage("Environment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # 2. Display Python Environment
    current_env <- tryCatch({
      py_config <- reticulate::py_config()
      sprintf("\nPython Environment:\n  - Path: %s\n  - Type: %s\n  - Version: %s",
              py_config$python,
              if(!is.null(py_config$virtualenv)) "virtualenv" else
                if(!is.null(py_config$conda)) "conda" else "system",
              py_config$version)
    }, error = function(e) "\nUnable to detect Python environment")

    packageStartupMessage(current_env)

    # 3. Check Docker Status
    if (is_docker()) {
      print_status("Docker", "Enabled", TRUE)
    }

    # 4. Initialize and Check Modules
    init_result <- initialize_modules()
    if (!init_result$status) {
      packageStartupMessage("\nRequired modules check failed. Starting installation...")

      # Install missing packages
      env_setup <- check_conda_env(missing_modules = init_result$missing)
      if (!env_setup) {
        packageStartupMessage("Failed to install required packages.")
        return(invisible(NULL))
      }

      # Recheck modules
      init_result <- initialize_modules()
      if (!init_result$status) {
        packageStartupMessage("Module installation failed. Please check your Python environment.")
        return(invisible(NULL))
      }
    }

    # 5. Display Python Version Status
    config <- reticulate::py_config()
    python_version <- as.character(config$version)
    print_status("Python", python_version, check_python_version(python_version))

    # 6. Display Core Module Status
    packageStartupMessage("\nCore Modules Status:")
    print_status("PyTorch", init_result$versions$torch, TRUE)
    print_status("Transformers", init_result$versions$transformers, TRUE)
    print_status("Flair NLP", init_result$versions$flair, TRUE)

    # 7. Check and Display GPU Status
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

    # 8. Check Word Embeddings Status
    packageStartupMessage("\nOptional Features:")
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

    # 9. Display Welcome Message
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

  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}

# Function to verify embeddings support
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
