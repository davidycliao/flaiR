#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Version constants
.pkgenv$package_constants <- list(
  python_min_version = "3.9",
  python_max_version = "3.12",
  numpy_version = "1.26.4",
  scipy_version = "1.12.0",
  flair_min_version = "0.11.3",
  torch_version = "2.2.0",  # Updated to match available versions
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

# Check Python -----------------------------------------------------------------

#' Compare version numbers
#'
#' @noRd
check_python_version <- function(version) {
  min_v <- .pkgenv$package_constants$python_min_version
  max_v <- .pkgenv$package_constants$python_max_version

  parse_version <- function(v) {
    as.numeric(strsplit(v, "\\.")[[1]][1:2])
  }

  ver <- parse_version(version)
  min_ver <- parse_version(min_v)
  max_ver <- parse_version(max_v)

  if (ver[1] < min_ver[1] || ver[1] > max_ver[1]) return(FALSE)
  if (ver[1] == min_ver[1] && ver[2] < min_ver[2]) return(FALSE)
  if (ver[1] == max_ver[1] && ver[2] > max_ver[2]) return(FALSE)

  return(TRUE)
}


# Print Messages ---------------------------------------------------------------

#' Print Formatted Messages
#'
#' @noRd
print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  symbol <- if (status) "\u2713" else "u2717"
  color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red

  formatted_component <- switch(
    component,
    "Python" = sprintf("%-20s", "Python"),
    "PyTorch" = sprintf("%-20s", "PyTorch"),
    "Transformers" = sprintf("%-20s", "Transformers"),
    "Flair NLP" = sprintf("%-20s", "Flair NLP"),
    "GPU" = sprintf("%-20s", "GPU"),
    "Conda" = sprintf("%-20s", "Conda"),
    "Docker" = sprintf("%-20s", "Docker"),
    sprintf("%-20s", component)
  )

  msg <- sprintf("%s %s%s%s  %s",
                 formatted_component,
                 color,
                 symbol,
                 .pkgenv$colors$reset,
                 if(!is.null(version)) version else "")

  packageStartupMessage(msg)
  if (!is.null(extra_message)) {
    packageStartupMessage(extra_message)
  }
}

# Get System Information -------------------------------------------------------
#' Get System Information
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

# Install Required Dependencies ------------------------------------------------

#' @title Install Required dependencies
#'
#' @noRd
install_dependencies <- function(venv) {
  tryCatch({
    in_docker <- is_docker()

    packageStartupMessage("Installing dependencies",
                          if(!is.null(venv)) sprintf(" in %s", venv) else "",
                          if(in_docker) " (Docker environment)" else "",
                          "...")

    if (in_docker) {
      # Docker environment installation
      pip_path <- "/opt/venv/bin/pip"

      # Install PyTorch packages
      system2(pip_path, c("install", "--no-cache-dir",
                          sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
                          "torchvision"))

      # Install other dependencies
      system2(pip_path, c("install", "--no-cache-dir",
                          sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
                          sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
                          sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
                          "sentencepiece>=0.1.97,<0.2.0"))

      # Install flair
      system2(pip_path, c("install", "--no-cache-dir",
                          sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)))
    } else {
      # Standard environment installation
      reticulate::py_install(
        packages = c(
          sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
          "torchvision"
        ),
        pip = TRUE,
        envname = venv
      )

      reticulate::py_install(
        packages = c(
          sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
          sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
          sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
          "sentencepiece>=0.1.97,<0.2.0"
        ),
        pip = TRUE,
        envname = venv
      )

      reticulate::py_install(
        packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version),
        pip = TRUE,
        envname = venv
      )
    }

    TRUE
  }, error = function(e) {
    packageStartupMessage("Error installing dependencies: ", e$message)
    FALSE
  })
}

# Check and Setup Conda --------------------------------------------------------
#' @title Check and setup conda environment
#'
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

  # Standard environment checks for non-Docker environments
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

# Initialize Required Modules --------------------------------------------------

#' Initialize Required Modules
#'
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

# FlaiR Package Initialization -------------------------------------------------

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

      # Welvome messeges
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
