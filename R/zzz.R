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

#' Compare version numbers
#' @noRd
check_python_version <- function(version) {
  min_v <- .pkgenv$package_constants$python_min_version
  max_v <- .pkgenv$package_constants$python_max_version

  # Parse version strings to numeric vectors
  parse_version <- function(v) {
    as.numeric(strsplit(v, "\\.")[[1]][1:2])
  }

  ver <- parse_version(version)
  min_ver <- parse_version(min_v)
  max_ver <- parse_version(max_v)

  # Check version compatibility
  if (ver[1] < min_ver[1] || ver[1] > max_ver[1]) return(FALSE)
  if (ver[1] == min_ver[1] && ver[2] < min_ver[2]) return(FALSE)
  if (ver[1] == max_ver[1] && ver[2] > max_ver[2]) return(FALSE)

  return(TRUE)
}

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

#' Install required dependencies
#' @noRd
install_dependencies <- function(venv) {
  tryCatch({
    message("Installing dependencies in ", venv, "...")

    # Install base packages with conda
    reticulate::conda_install(
      envname = venv,
      packages = c(
        sprintf("numpy==%s", .pkgenv$package_constants$numpy_version),
        sprintf("scipy==%s", .pkgenv$package_constants$scipy_version)
      ),
      channel = "conda-forge"
    )

    # Install PyTorch
    reticulate::py_install(
      packages = "torch",
      pip = TRUE,
      envname = venv
    )

    # Install other dependencies
    reticulate::py_install(
      packages = c(
        sprintf("transformers==%s", .pkgenv$package_constants$transformers_version),
        "sentencepiece>=0.1.97,<0.2.0",
        sprintf("flair>=%s", .pkgenv$package_constants$flair_min_version)
      ),
      pip = TRUE,
      envname = venv
    )

    # Verify installation
    reticulate::use_condaenv(venv, required = TRUE)
    if (!reticulate::py_module_available("flair")) {
      stop("Flair installation verification failed")
    }

    return(TRUE)
  }, error = function(e) {
    message("Error installing dependencies: ", e$message)
    return(FALSE)
  })
}

#' Check and setup conda environment
#' @noRd
check_conda_env <- function(show_status = FALSE) {
  conda_available <- tryCatch({
    conda_bin <- reticulate::conda_binary()
    list(status = TRUE, path = conda_bin)
  }, error = function(e) {
    list(status = FALSE, error = e$message)
  })

  if (!conda_available$status) {
    if (show_status) {
      print_status("Conda", NULL, FALSE, "Conda not found")
    }
    return(FALSE)
  }

  if (show_status) {
    print_status("Conda", conda_available$path, TRUE)
  }

  # Check for flair_env
  has_flair_env <- "flair_env" %in% reticulate::conda_list()$name
  if (has_flair_env) {
    tryCatch({
      reticulate::use_condaenv("flair_env", required = TRUE)
      if (!reticulate::py_module_available("flair")) {
        message("Flair environment exists but modules are missing. Reinstalling...")
        if (!install_dependencies("flair_env")) {
          return(FALSE)
        }
      }
      return(TRUE)
    }, error = function(e) {
      message("Error using flair_env: ", e$message)
      has_flair_env <- FALSE
    })
  }

  if (!has_flair_env) {
    message("Creating new conda environment: flair_env")
    tryCatch({
      reticulate::conda_create("flair_env")
      if (!install_dependencies("flair_env")) {
        return(FALSE)
      }
      return(TRUE)
    }, error = function(e) {
      message("Failed to create conda environment: ", e$message)
      return(FALSE)
    })
  }

  return(TRUE)
}

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
  # 儲存原始環境設定
  original_python <- Sys.getenv("RETICULATE_PYTHON")
  original_virtualenv <- Sys.getenv("VIRTUALENV")

  # 在函數結束時恢復原始設定
  on.exit({
    if (original_python != "") Sys.setenv(RETICULATE_PYTHON = original_python)
    if (original_virtualenv != "") Sys.setenv(VIRTUALENV = original_virtualenv)
  })

  tryCatch({
    # 清除 Python 相關設定
    Sys.unsetenv("RETICULATE_PYTHON")
    Sys.unsetenv("VIRTUALENV")
    options(reticulate.python.initializing = TRUE)

    # 顯示系統資訊
    sys_info <- get_system_info()
    message("\nEnvironment Information:")
    message(sprintf("OS: %s (%s)",
                    as.character(sys_info$name),
                    as.character(sys_info$version)))

    # 檢查 conda
    conda_available <- tryCatch({
      conda_bin <- reticulate::conda_binary()
      list(status = TRUE, path = conda_bin)
    }, error = function(e) {
      list(status = FALSE, error = e$message)
    })

    if (conda_available$status) {
      print_status("Conda", conda_available$path, TRUE)
    }

    # 優先檢查已知工作的 Python 路徑
    known_working_paths <- c(
      "/Users/yenchiehliao/.venv/bin/python",
      "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3",
      Sys.which("python3"),
      Sys.which("python")
    )

    python_found <- FALSE
    for (python_path in known_working_paths) {
      if (file.exists(python_path)) {
        tryCatch({
          reticulate::use_python(python_path, required = TRUE)
          config <- reticulate::py_config()
          python_version <- as.character(config$version)
          print_status("Python", python_version, TRUE)
          message(sprintf("Using Python: %s", python_path))
          message("")
          python_found <- TRUE
          break
        }, error = function(e) NULL)
      }
    }

    if (!python_found) {
      message("No suitable Python environment found.")
      return(invisible(NULL))
    }

    # 初始化模組
    init_result <- initialize_modules()
    if (init_result$status) {
      print_status("PyTorch", init_result$versions$torch, TRUE)
      print_status("Transformers", init_result$versions$transformers, TRUE)
      print_status("Flair NLP", init_result$versions$flair, TRUE)

      # GPU 檢查邏輯
      cuda_info <- init_result$device$cuda
      mps_available <- init_result$device$mps

      # 檢查 GPU 狀態
      if (!is.null(cuda_info$available) && cuda_info$available) {
        # 如果有 CUDA GPU
        gpu_name <- if (!is.null(cuda_info$device_name)) {
          paste("CUDA", cuda_info$device_name)
        } else {
          "CUDA"
        }
        print_status("GPU", gpu_name, TRUE)
      } else if (!is.null(mps_available) && mps_available) {
        # 如果有 Mac MPS
        print_status("GPU", "Mac MPS", TRUE)
      } else {
        # 如果沒有 GPU
        print_status("GPU", "CPU Only", FALSE)
      }

      # 歡迎訊息
      msg <- sprintf(
        "%s%sflaiR%s%s: %s%sAn R Wrapper for Accessing Flair NLP %s%s%s",
        .pkgenv$colors$bold, .pkgenv$colors$blue,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold,
        .pkgenv$colors$bold, .pkgenv$colors$yellow,
        init_result$versions$flair,
        .pkgenv$colors$reset, .pkgenv$colors$reset_bold
      )
      message(msg)
    }
  }, error = function(e) {
    message("Error during initialization: ", as.character(e$message))
  }, finally = {
    options(reticulate.python.initializing = FALSE)
  })

  invisible(NULL)
}
