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
  torch_version = "2.1.2",
  transformers_version = "4.37.2",
  sentencepiece_version = "0.1.99"
)

# ANSI color codes
.pkgenv$colors <- list(
  check = "\u2713",
  cross = "\u2717",
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

# Helper Functions -------------------------------------------------------------

#' Print formatted status message
#' @noRd
print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  symbol <- if (status) .pkgenv$colors$check else .pkgenv$colors$cross
  color <- if (status) .pkgenv$colors$green else .pkgenv$colors$red

  formatted_component <- switch(
    component,
    "Python" = sprintf("%-20s", "Python"),
    "PyTorch" = sprintf("%-20s", "PyTorch"),
    "Transformers" = sprintf("%-20s", "Transformers"),
    "Flair NLP" = sprintf("%-20s", "Flair NLP"),
    "GPU" = sprintf("%-20s", "GPU"),
    "Conda" = sprintf("%-20s", "Conda"),
    sprintf("%-20s", component)
  )

  msg <- sprintf("%s %s%s%s  %s",
                 formatted_component,
                 color,
                 symbol,
                 .pkgenv$colors$reset,
                 if(!is.null(version)) version else "")

  message(msg)
  if (!is.null(extra_message)) {
    message(extra_message)
  }
}

#' Get system information
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

#' Install package dependencies in correct order
#' @noRd
install_dependencies <- function(venv) {
  tryCatch({
    message("Installing dependencies...")

    # First uninstall numpy to avoid version conflicts
    reticulate::py_install("pip --upgrade", pip = TRUE, envname = venv)
    system2(file.path(venv, "bin", "pip"), args = c("uninstall", "-y", "numpy"))

    # Install dependencies in specific order
    # 1. Base numpy and scipy first
    reticulate::py_install(
      packages = c(
        sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
        sprintf("scipy==%s", .pkgenv$package_constants$scipy_version)
      ),
      envname = venv,
      pip = TRUE
    )
    message("Base dependencies installed.")

    # 2. Install PyTorch
    reticulate::py_install(
      packages = sprintf("torch>=%s", .pkgenv$package_constants$torch_version),
      envname = venv,
      pip = TRUE
    )
    message("PyTorch installed.")

    # 3. Install transformers
    reticulate::py_install(
      packages = c(
        sprintf("transformers>=%s", .pkgenv$package_constants$transformers_version),
        sprintf("sentencepiece>=%s", .pkgenv$package_constants$sentencepiece_version)
      ),
      envname = venv,
      pip = TRUE
    )
    message("Transformers installed.")

    # 4. Finally install flair
    reticulate::py_install(
      packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version),
      envname = venv,
      pip = TRUE
    )
    message("Flair installed.")

    verify_installation(venv)
  }, error = function(e) {
    message("Error installing dependencies: ", e$message)
    return(FALSE)
  })
}

#' Verify package installation
#' @noRd
verify_installation <- function(venv) {
  tryCatch({
    message("\nVerifying installation...")

    # Get Python path
    python_config <- reticulate::py_config()
    message(sprintf("Using Python: %s", python_config$python))
    message("")

    # Rest of the verification code...
    numpy <- reticulate::import("numpy")
    numpy_version <- reticulate::py_get_attr(numpy, "__version__")
    print_status("NumPy", numpy_version, TRUE)

    torch <- reticulate::import("torch")
    torch_version <- reticulate::py_get_attr(torch, "__version__")
    print_status("PyTorch", torch_version, TRUE)

    transformers <- reticulate::import("transformers")
    transformers_version <- reticulate::py_get_attr(transformers, "__version__")
    print_status("Transformers", transformers_version, TRUE)

    flair <- reticulate::import("flair")
    flair_version <- reticulate::py_get_attr(flair, "__version__")
    print_status("Flair NLP", flair_version, TRUE)

    # GPU capabilities check...
    if (torch$cuda$is_available()) {
      cuda_version <- torch$version$cuda
      device_name <- tryCatch({
        props <- torch$cuda$get_device_properties(0)
        props$name
      }, error = function(e) NULL)

      gpu_info <- if (!is.null(device_name)) {
        sprintf("CUDA %s (%s)", cuda_version, device_name)
      } else {
        sprintf("CUDA %s", cuda_version)
      }
      print_status("GPU", gpu_info, TRUE)
    } else if (Sys.info()["sysname"] == "Darwin" && torch$backends$mps$is_available()) {
      print_status("GPU", "Apple MPS", TRUE)
    } else {
      print_status("GPU", "not available", FALSE)
    }

    message("")
    return(TRUE)
  }, error = function(e) {
    message("\nVerification failed: ", e$message)
    message("Python error details:")
    message(reticulate::py_last_error())
    return(FALSE)
  })
}

#' Check and setup conda environment
#' @noRd
check_conda_env <- function() {
  # Check conda existence
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (!conda_available$status) {
    print_status("Conda", NULL, FALSE, "Conda not found")
    return(FALSE)
  }
  print_status("Conda", conda_available$path, TRUE)

  # List conda environments
  conda_envs <- reticulate::conda_list()

  # Check for flair_env
  has_flair_env <- "flair_env" %in% conda_envs$name

  if (!has_flair_env) {
    message("\nCreating new conda environment: flair_env")
    tryCatch({
      reticulate::conda_create("flair_env")
      # Get and display environment path
      env_path <- conda_envs[conda_envs$name == "flair_env", "python"]
      message(sprintf("Environment path: %s", env_path))
      message("")
      install_dependencies("flair_env")
    }, error = function(e) {
      message("Failed to create environment: ", e$message)
      return(FALSE)
    })
  } else {
    # Get environment information
    env_info <- conda_envs[conda_envs$name == "flair_env", ]
    message("\nUsing existing environment: flair_env")
    message(sprintf("Environment path: %s", env_info$python[1]))

    tryCatch({
      reticulate::use_condaenv("flair_env", required = TRUE)
      message("")
      if (!verify_installation("flair_env")) {
        message("\nReinstalling dependencies...")
        install_dependencies("flair_env")
      }
    }, error = function(e) {
      message("Error using environment: ", e$message)
      return(FALSE)
    })
  }
}

# Package Initialization -------------------------------------------------------

#' @noRd
.onLoad <- function(libname, pkgname) {
  # Set essential environment variables
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  # Mac-specific settings
  if (Sys.info()["sysname"] == "Darwin") {
    if (Sys.info()["machine"] == "arm64") {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    }
    Sys.setenv(OMP_NUM_THREADS = 1)
    Sys.setenv(MKL_NUM_THREADS = 1)
  }

  # Disable reticulate prompt
  options(reticulate.prompt = FALSE)
}

#' @noRd
.onAttach <- function(libname, pkgname) {
  # Show environment information
  sys_info <- get_system_info()
  message("\nEnvironment Information:")
  message(sprintf("OS: %s (%s)", sys_info$name, sys_info$version))

  # Initialize Python environment
  tryCatch({
    check_conda_env()

    msg <- sprintf(
      "\n%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP%s%s",
      .pkgenv$colors$bold, .pkgenv$colors$blue,
      .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
      .pkgenv$colors$bold, .pkgenv$colors$yellow,
      .pkgenv$colors$reset, .pkgenv$colors$reset_bold
    )
    message(msg)
  }, error = function(e) {
    message("Error during initialization: ", e$message)
  })

  invisible(NULL)
}
