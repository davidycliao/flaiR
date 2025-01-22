#' @keywords internal
"_PACKAGE"

#' @import reticulate
NULL

# Package environment setup ----------------------------------------------
.pkgenv <- new.env(parent = emptyenv())

# Version constants
.pkgenv$package_constants <- list(
  python_min_version = "3.9",
  python_max_version = "3.12",
  numpy_version = "1.26.4",
  scipy_version = "1.12.0",
  flair_min_version = "0.11.3",
  torch_version = "2.1.2",
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

# Helper functions -----------------------------------------------------

#' Print formatted status message
#' @noRd
print_status <- function(component, version, status = TRUE, extra_message = NULL) {
  symbol <- if (status) "✓" else "✗"
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

#' Check and setup conda environment
#' @noRd
check_conda_env <- function() {
  # 先檢查系統 Python 版本
  system_python_version <- tryCatch({
    # 使用 system2 來執行 python3 -V
    py_ver <- system2("python3", args = "-V", stdout = TRUE)
    # 提取版本號
    gsub("Python ", "", py_ver)
  }, error = function(e) "3.10")  # 預設值

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
  conda_envs <- reticulate::conda_list()
  has_flair_env <- "flair_env" %in% conda_envs$name

  if (!has_flair_env) {
    message("Creating new conda environment: flair_env")
    tryCatch({
      # 使用系統檢測到的 Python 版本
      message(sprintf("Using system Python version: %s", system_python_version))
      reticulate::conda_create("flair_env", python_version = system_python_version)

      # 其他安裝步驟保持不變
      reticulate::conda_install(
        envname = "flair_env",
        packages = c(
          sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
          sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
          sprintf("torch==%s", .pkgenv$package_constants$torch_version),
          sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
        )
      )

      reticulate::py_install(
        packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version),
        pip = TRUE,
        conda = "flair_env"
      )
      return(TRUE)
    }, error = function(e) {
      message("Failed to create conda environment: ", e$message)
      return(FALSE)
    })
  }

  tryCatch({
    reticulate::use_condaenv("flair_env", required = TRUE)
    return(TRUE)
  }, error = function(e) {
    message("Error using conda environment: ", e$message)
    return(FALSE)
  })
}

# check_conda_env <- function() {
#   conda_available <- tryCatch({
#     conda_bin <- reticulate::conda_binary()
#     list(status = TRUE, path = conda_bin)
#   }, error = function(e) {
#     list(status = FALSE, error = e$message)
#   })
#
#   if (!conda_available$status) {
#     print_status("Conda", NULL, FALSE, "Conda not found")
#     return(FALSE)
#   }
#
#   print_status("Conda", conda_available$path, TRUE)
#
#   conda_envs <- reticulate::conda_list()
#   has_flair_env <- "flair_env" %in% conda_envs$name
#
#   if (!has_flair_env) {
#     message("Creating new conda environment: flair_env")
#     tryCatch({
#       reticulate::conda_create("flair_env", python_version = "3.10")
#       reticulate::conda_install(
#         envname = "flair_env",
#         packages = c(
#           sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
#           sprintf("scipy==%s", .pkgenv$package_constants$scipy_version),
#           sprintf("torch==%s", .pkgenv$package_constants$torch_version),
#           sprintf("transformers==%s", .pkgenv$package_constants$transformers_version)
#         )
#       )
#
#       reticulate::py_install(
#         packages = sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version),
#         pip = TRUE,
#         conda = "flair_env"
#       )
#       return(TRUE)
#     }, error = function(e) {
#       message("Failed to create conda environment: ", e$message)
#       return(FALSE)
#     })
#   }
#
#   tryCatch({
#     reticulate::use_condaenv("flair_env", required = TRUE)
#     return(TRUE)
#   }, error = function(e) {
#     message("Error using conda environment: ", e$message)
#     return(FALSE)
#   })
# }

#' Initialize required modules
#' @noRd
initialize_modules <- function() {
  tryCatch({
    # Import modules
    torch <- reticulate::import("torch", delay_load = TRUE)
    transformers <- reticulate::import("transformers", delay_load = TRUE)
    flair <- reticulate::import("flair", delay_load = TRUE)

    # Get versions
    torch_version <- reticulate::py_get_attr(torch, "__version__")
    transformers_version <- reticulate::py_get_attr(transformers, "__version__")
    flair_version <- reticulate::py_get_attr(flair, "__version__")

    # Check GPU capabilities
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

    # Store modules
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

# Package initialization ----------------------------------------------

#' @noRd
.onLoad <- function(libname, pkgname) {
  # Set essential environment variables first
  Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")

  # Mac-specific settings
  if (Sys.info()["sysname"] == "Darwin") {
    if (Sys.info()["machine"] == "arm64") {
      Sys.setenv(PYTORCH_ENABLE_MPS_FALLBACK = 1)
    }
    # Additional OpenMP settings for Mac
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
    # 首先檢查和設置 conda 環境
    conda_setup <- check_conda_env()
    if (!conda_setup) {
      packageStartupMessage("Attempting to use system Python...")
    }

    # Check Python version
    config <- reticulate::py_config()
    version_parts <- strsplit(as.character(config$version), "\\.")[[1]]
    python_version <- paste(version_parts[1], version_parts[2], sep = ".")

    python_status <- as.numeric(version_parts[1]) == 3 &&
      as.numeric(version_parts[2]) >= 9 &&
      as.numeric(version_parts[2]) <= 12

    print_status("Python", python_version, python_status)
    packageStartupMessage(sprintf("Using Python: %s", config$python))
    packageStartupMessage("")

    if (python_status) {
      init_result <- initialize_modules()

      if (init_result$status) {
        print_status("PyTorch", init_result$versions$torch, TRUE)
        print_status("Transformers", init_result$versions$transformers, TRUE)
        print_status("Flair NLP", init_result$versions$flair, TRUE)

        # Print GPU status
        cuda_info <- init_result$device$cuda
        if (cuda_info$available || init_result$device$mps) {
          print_status("GPU", "available", TRUE)

          if (cuda_info$available) {
            gpu_type <- if (!is.null(cuda_info$device_name)) {
              sprintf("CUDA (%s)", cuda_info$device_name)
            } else {
              "CUDA"
            }
            print_status(gpu_type, cuda_info$version, TRUE)
          }

          if (init_result$device$mps) {
            print_status("Mac MPS", "available", TRUE)
          }
        } else {
          print_status("GPU", "not available", FALSE)
        }

        # Print welcome message
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
    }
  }, error = function(e) {
    packageStartupMessage("Error during initialization: ", e$message)
  })

  invisible(NULL)
}



