#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Version constants with full dependency specifications
.pkgenv$package_constants <- list(
  python = list(
    min_version = "3.9",
    max_version = "3.12"
  ),
  packages = list(
    # Core dependencies
    torch = list(min = "2.2.0", exclude = "1.8"),
    numpy = "1.26.4",
    scipy = "1.12.0",
    transformers = list(min = "4.37.2", extras = "sentencepiece"),
    flair = list(min = "0.11.3"),

    # Additional Flair dependencies
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
    sentencepiece = list(min = "0.1.97", max = "0.2.0")
  )
)

# ANSI color codes for status messages
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
  torch = NULL
)

# Check Docker -----------------------------------------------------------------
#' Check if running in Docker
#'
#' @noRd
is_docker <- function() {
  if (file.exists("/.dockerenv")) return(TRUE)

  if (Sys.info()["sysname"] == "Linux") {
    tryCatch({
      if (file.exists("/proc/1/cgroup")) {
        cgroup_content <- readLines("/proc/1/cgroup", n = 1)
        return(grepl("docker", cgroup_content))
      }
    }, error = function(e) FALSE)
  }
  FALSE
}

# Version Checking ------------------------------------------------------------
#' Compare version numbers
#'
#' @param version Character string of version number to check
#' @return logical TRUE if version is in supported range
#' @noRd
check_python_version <- function(version) {
  if (!is.character(version)) return(FALSE)

  version_info <- .pkgenv$package_constants$python
  min_v <- version_info$min_version
  max_v <- version_info$max_version

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

    TRUE
  }, error = function(e) FALSE)
}

# Status Messages ----------------------------------------------------------
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
  msg <- sprintf("%s %s%s%s  %s",
                 formatted_component,
                 color,
                 symbol,
                 .pkgenv$colors$reset,
                 if(!is.null(version)) version else "")

  if (component == "Python") {
    version_parts <- strsplit(version, "\\.")[[1]][1:2]
    ver_major <- as.numeric(version_parts[1])
    ver_minor <- as.numeric(version_parts[2])

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
        "\n%sWarning: Python 3.13+ has not been fully tested with current Flair NLP.%s\n%sStability issues may occur.%s",
        .pkgenv$colors$yellow,
        .pkgenv$colors$reset,
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

# System Information ------------------------------------------------------
#' Get System Information
#'
#' @return List containing system name and version
#' @noRd
get_system_info <- function() {
  os_name <- Sys.info()["sysname"]
  os_version <- switch(
    os_name,
    "Darwin" = tryCatch(system("sw_vers -productVersion", intern = TRUE)[1],
                        error = function(e) "Unknown"),
    "Windows" = tryCatch(system("ver", intern = TRUE)[1],
                         error = function(e) "Unknown"),
    tryCatch(system("cat /etc/os-release | grep PRETTY_NAME", intern = TRUE)[1],
             error = function(e) "Unknown")
  )

  list(name = os_name, version = os_version)
}

# Dependency Installation -------------------------------------------------
#' Install Required Dependencies
#'
#' @param venv Virtual environment name or NULL for system Python
#' @param max_retries Maximum number of retry attempts for failed installations
#' @param quiet Suppress status messages if TRUE
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
install_dependencies <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  # Installation order
  install_order <- c(
    "torch",
    "numpy",
    "scipy",
    "transformers",
    "sentencepiece",
    "boto3",
    "conllu",
    "deprecated",
    "ftfy",
    "gdown",
    "huggingface_hub",
    "flair"
  )

  # Version specification helper
  create_version_spec <- function(pkg_info) {
    if (is.character(pkg_info)) return(pkg_info)
    specs <- c()
    if (!is.null(pkg_info$min)) specs <- c(specs, sprintf(">=%s", pkg_info$min))
    if (!is.null(pkg_info$max)) specs <- c(specs, sprintf("<%s", pkg_info$max))
    if (!is.null(pkg_info$exclude)) specs <- c(specs, sprintf("!=%s", pkg_info$exclude))
    spec <- paste(specs, collapse=",")
    if (!is.null(pkg_info$extras)) spec <- sprintf("%s[%s]", spec, pkg_info$extras)
    spec
  }

  # Installation with retry
  install_package <- function(pkg_name) {
    for (attempt in 1:max_retries) {
      tryCatch({
        pkg_spec <- create_version_spec(.pkgenv$package_constants$packages[[pkg_name]])
        if (!quiet) packageStartupMessage(sprintf("Installing %s (%s)...", pkg_name, pkg_spec))

        if (is_docker()) {
          cmd <- "/opt/venv/bin/pip"
          args <- c("install", "--no-cache-dir", pkg_spec)
          system2(cmd, args)
        } else {
          reticulate::py_install(
            packages = pkg_spec,
            pip = TRUE,
            envname = venv
          )
        }
        return(TRUE)
      }, error = function(e) {
        if (attempt == max_retries) {
          if (!quiet) packageStartupMessage(sprintf("Failed to install %s: %s", pkg_name, e$message))
          return(FALSE)
        }
        Sys.sleep(2 ^ attempt)
      })
    }
    FALSE
  }

  # Main installation process
  for (pkg in install_order) {
    if (!install_package(pkg)) return(FALSE)
  }

  TRUE
}

# Environment Setup ------------------------------------------------------
#' Check and setup Python environment
#'
#' @param venv Virtual environment name or NULL for system Python
#' @return logical TRUE if successful, FALSE otherwise
#' @noRd
setup_python_environment <- function(venv = NULL) {
  # Check for Docker first
  if (is_docker()) {
    docker_python <- Sys.getenv("RETICULATE_PYTHON", "/opt/venv/bin/python")
    if (file.exists(docker_python)) {
      packageStartupMessage(sprintf("Using Docker virtual environment: %s", docker_python))
      return(list(status = TRUE, path = docker_python))
    }
  }

  # Check existing Python
  current_python <- tryCatch({
    config <- reticulate::py_config()
    if (reticulate::py_module_available("flair")) {
      list(status = TRUE, path = config$python)
    } else {
      list(status = FALSE)
    }
  }, error = function(e) list(status = FALSE))

  if (current_python$status) {
    return(current_python)
  }

  # Create virtual environment if needed
  if (is.null(venv)) {
    venv <- file.path(Sys.getenv("HOME"), ".flair_env")
  }

  if (!dir.exists(venv)) {
    dir.create(venv, recursive = TRUE)
    system2("python3", c("-m", "venv", venv))
  }

  python_path <- if (Sys.info()["sysname"] == "Windows") {
    file.path(venv, "Scripts", "python.exe")
  } else {
    file.path(venv, "bin", "python")
  }

  if (file.exists(python_path)) {
    Sys.setenv(VIRTUAL_ENV = venv)
    list(status = TRUE, path = python_path)
  } else {
    list(status = FALSE)
  }
}

# Module Initialization -------------------------------------------------
#' Initialize Required Modules
#'
#' @return List containing version information and initialization status
#' @noRd
initialize_modules <- function() {
  tryCatch({
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)

    versions <- list(
      torch = reticulate::py_get_attr(torch, "__version__"),
      transformers = reticulate::py_get_attr(transformers, "__version__"),
      flair = reticulate::py_get_attr(flair, "__version__")
    )

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
      versions = versions,
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

# Package Initialization -----------------------------------------------
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
#' @noRd
.onAttach <- function(libname, pkgname) {
  # Store original environment settings
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  # Ensure environment restoration on exit
  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    # Clear Python-related environment variables
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # Display system information
    sys_info <- get_system_info()
    packageStartupMessage("\nEnvironment Information:")
    packageStartupMessage(sprintf("OS: %s (%s)",
                                  as.character(sys_info$name),
                                  as.character(sys_info$version)))

    # Check and display Docker status
    if (is_docker()) {
      print_status("Docker", "Enabled", TRUE)
    }

    # Set up Python environment
    env_result <- setup_python_environment()
    if (!env_result$status) {
      packageStartupMessage("Failed to set up Python environment")
      return(invisible(NULL))
    }

    # Configure Python
    reticulate::use_python(env_result$path, required = TRUE)

    # Check Python version and display path
    config <- reticulate::py_config()
    python_version <- as.character(config$version)
    python_path <- config$python
    version_ok <- check_python_version(python_version)

    # Display Python path message
    packageStartupMessage(sprintf("Using existing Python: %s", python_path))

    print_status("Python", python_version, version_ok)
    packageStartupMessage("")

    # Install dependencies if needed
    if (!reticulate::py_module_available("flair")) {
      if (!install_dependencies(venv = dirname(dirname(env_result$path)))) {
        packageStartupMessage("Failed to install dependencies")
        return(invisible(NULL))
      }
    }

    # Initialize modules and check status
    init_result <- initialize_modules()
    if (init_result$status) {
      # Display package versions
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # Check and display GPU status
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

      # Display welcome message
      msg <- sprintf(
        "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
        .pkgenv$colors$bold, .pkgenv$colors$blue,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
        .pkgenv$colors$bold, .pkgenv$colors$yellow,
        init_result$versions$flair,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold
      )
      packageStartupMessage(msg)
    } else {
      packageStartupMessage(sprintf("Failed to initialize modules: %s",
                                    init_result$error))
    }
  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}
