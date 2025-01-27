#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package Environment Setup ----------------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

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

# Installation tracking environment
.pkgenv$installation_info <- new.env(parent = emptyenv())

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

# Installation Status Management ---------------------------------------------

#' Save installation status
#' @noRd
save_installation_status <- function() {
  status_file <- file.path(system.file(package = "flaiR"), "installation_status.rds")
  saveRDS(
    list(
      versions = .pkgenv$installation_info$versions,
      python_path = .pkgenv$installation_info$python_path,
      last_check = .pkgenv$installation_info$last_check,
      installation_date = .pkgenv$installation_info$installation_date
    ),
    status_file
  )
}

#' Load installation status
#' @noRd
load_installation_status <- function() {
  status_file <- file.path(system.file(package = "flaiR"), "installation_status.rds")
  if (file.exists(status_file)) {
    status <- readRDS(status_file)
    .pkgenv$installation_info$versions <- status$versions
    .pkgenv$installation_info$python_path <- status$python_path
    .pkgenv$installation_info$last_check <- status$last_check
    .pkgenv$installation_info$installation_date <- status$installation_date
    return(TRUE)
  }
  return(FALSE)
}


#' Check installed versions
#' @noRd
check_installed_versions <- function(quiet = FALSE) {
  tryCatch({
    versions <- list()
    required_modules <- list(
      torch = .pkgenv$package_constants$torch_version,
      transformers = .pkgenv$package_constants$transformers_version,
      flair = .pkgenv$package_constants$flair_min_version,
      gensim = .pkgenv$package_constants$gensim_version
    )

    all_available <- TRUE
    all_versions_match <- TRUE
    version_details <- list()

    for (module_name in names(required_modules)) {
      if (reticulate::py_module_available(module_name)) {
        mod <- reticulate::import(module_name)
        current_version <- reticulate::py_get_attr(mod, "__version__")
        versions[[module_name]] <- current_version

        # Version comparison
        req_version <- required_modules[[module_name]]
        if (!is.null(req_version)) {
          version_match <- safe_version_compare(current_version, req_version, quiet)
          version_details[[module_name]] <- list(
            installed = current_version,
            required = req_version,
            matches = version_match
          )

          if (!version_match) {
            all_versions_match <- FALSE
            if (!quiet) {
              packageStartupMessage(sprintf(
                "Version mismatch: %s (installed=%s, required=%s)",
                module_name, current_version, req_version
              ))
            }
          } else if (!quiet) {
            packageStartupMessage(sprintf(
              "Version check passed: %s (installed=%s)",
              module_name, current_version
            ))
          }
        }
      } else {
        all_available <- FALSE
        if (!quiet) {
          packageStartupMessage(sprintf("Module %s is not installed", module_name))
        }
      }
    }

    # Save detailed information
    .pkgenv$installation_info$versions <- versions
    .pkgenv$installation_info$version_details <- version_details
    .pkgenv$installation_info$last_check <- Sys.time()

    save_installation_status()

    return(all_available && all_versions_match)

  }, error = function(e) {
    if (!quiet) {
      packageStartupMessage(sprintf("Error checking versions: %s", e$message))
    }
    return(FALSE)
  })
}


# Environment Check and Setup -----------------------------------------------

#' Check Python environment
#' @noRd
check_python_env <- function(quiet = FALSE) {
  # Try to load saved status first
  if (load_installation_status()) {
    # Check if last verification was recent (within 24 hours)
    if (difftime(Sys.time(), .pkgenv$installation_info$last_check, units="hours") < 24) {
      if (!quiet) packageStartupMessage("Using cached environment status")
      return(TRUE)
    }
  }

  # Verify current Python installation
  current_python <- tryCatch({
    config <- reticulate::py_config()
    python_version <- as.character(config$version)

    if (check_python_version(python_version) && check_installed_versions()) {
      .pkgenv$installation_info$python_path <- config$python
      save_installation_status()
      return(TRUE)
    }
    FALSE
  }, error = function(e) FALSE)

  if (!current_python) {
    if (!quiet) packageStartupMessage("Environment verification failed, need to install dependencies")
    return(FALSE)
  }

  TRUE
}

# Installation Functions ---------------------------------------------------

#' Safely compare package versions
#' @noRd
safe_version_compare <- function(current, required, quiet = FALSE) {
  tryCatch({
    # Remove all whitespace
    current <- trimws(current)
    required <- trimws(required)

    # Check version format
    if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", current)) {
      if (!quiet) packageStartupMessage(sprintf("Warning: Invalid installed version format: %s", current))
      return(FALSE)
    }

    # Handle version requirement format
    if (grepl("^>=", required)) {
      min_version <- trimws(sub("^>=", "", required))
      if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", min_version)) {
        if (!quiet) packageStartupMessage(sprintf("Warning: Invalid required version format: %s", required))
        return(FALSE)
      }
      return(package_version(current) >= package_version(min_version))
    } else {
      # Remove == from version number if exists
      exact_version <- trimws(sub("^==", "", required))
      if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", exact_version)) {
        if (!quiet) packageStartupMessage(sprintf("Warning: Invalid required version format: %s", required))
        return(FALSE)
      }
      return(package_version(current) >= package_version(exact_version))
    }
  }, error = function(e) {
    if (!quiet) packageStartupMessage(sprintf("Version comparison error: %s", e$message))
    return(FALSE)
  })
}


#' Display environment information
#' @noRd
display_environment_info <- function(init_result) {
  # System information
  sys_info <- get_system_info()
  packageStartupMessage("\nEnvironment Information:")
  packageStartupMessage(sprintf("OS: %s (%s)",
                                as.character(sys_info$name),
                                as.character(sys_info$version)))

  # Docker status
  if (is_docker()) {
    print_status("Docker", "Enabled", TRUE)
  }

  # Python version check
  config <- reticulate::py_config()
  python_version <- as.character(config$version)
  print_status("Python", python_version, check_python_version(python_version))

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

  # Add space before package info
  packageStartupMessage("")

  # Package version information
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
                 sprintf("Word embeddings feature is not detected.\n\nInstall with:\nIn R:\n  reticulate::py_install('flair[word-embeddings]', pip = TRUE)\n  system(paste(Sys.which('python3'), '-m pip install flair[word-embeddings]'))\n\nIn terminal:\n  pip install flair[word-embeddings]"))
  }

  # Welcome message
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


#' Install dependencies with verification
#' @noRd
install_deps_with_verify <- function(venv = NULL, max_retries = 3, quiet = FALSE) {
  if (!install_dependencies(venv, max_retries, quiet)) {
    return(FALSE)
  }

  verify_success <- check_installed_versions(quiet)
  if (!verify_success) {
    if (!quiet) {
      packageStartupMessage("\nPackages installed but version verification failed")
      packageStartupMessage("Installed versions:")
      if (!is.null(.pkgenv$installation_info$version_details)) {
        for (pkg in names(.pkgenv$installation_info$version_details)) {
          details <- .pkgenv$installation_info$version_details[[pkg]]
          status <- if(details$matches) "✓" else "✗"
          packageStartupMessage(sprintf("  %s %s: installed=%s, required=%s",
                                        status, pkg, details$installed, details$required))
        }
      }
    }
    return(FALSE)
  }

  .pkgenv$installation_info$installation_date <- Sys.time()
  save_installation_status()

  return(TRUE)
}


# Package Hooks ----------------------------------------------------------

#' @noRd
.onLoad <- function(libname, pkgname) {
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  # Platform-specific settings
  if (Sys.info()["sysname"] == "Darwin") {
    if (Sys.info()["machine"] == "arm64") {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    }
    Sys.setenv(OMP_NUM_THREADS = 1)
    Sys.setenv(MKL_NUM_THREADS = 1)
  }

  # Initialize installation info if needed
  if (is.null(.pkgenv$installation_info)) {
    .pkgenv$installation_info <- new.env(parent = emptyenv())
  }

  options(reticulate.prompt = FALSE)
}

#' @noRd
.onAttach <- function(libname, pkgname) {
  # Save original environment settings
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    # Clean environment for setup
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # Check environment
    if (!check_python_env()) {
      # Only install if verification fails
      if (!install_deps_with_verify()) {
        return(invisible(NULL))
      }
    }

    # Initialize modules and display status
    init_result <- initialize_modules()
    if (init_result$status) {
      # Display environment information
      display_environment_info(init_result)
    }

  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}
