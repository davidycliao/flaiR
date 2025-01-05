#' @title Install Python Dependencies and Load the flaiRnlp
#' @description .onAttach sets up a virtual environment, checks for Python availability,
#' and ensures the 'flair' module is installed in flair_env in Python.
#'
#' @param ... A character string specifying the name of the virtual environment.
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Checks if the virtual environment specified by `venv` exists.
#'         If not, it creates the environment.
#'   \item Activates the virtual environment.
#'   \item Checks for the availability of Python. If Python is not available,
#'         it displays an error message.
#'   \item Checks if the 'flair' Python module is available in the virtual
#'         environment. If not, it attempts to install 'flair'. If the
#'         installation fails, it prompts the user to install 'flair' manually.
#' }
#' @importFrom reticulate py_module_available
#' @importFrom reticulate py_install
#' @keywords internal
# .onAttach <- function(...) {
#   # Determine Python command
#   python_cmd <- if (Sys.info()["sysname"] == "Windows") "python" else "python3"
#   python_path <- Sys.which(python_cmd)
#
#   # Check Python path
#   if (python_path == "") {
#     packageStartupMessage(paste("Cannot locate the", python_cmd, "executable. Ensure it's installed and in your system's PATH. flaiR functionality requiring Python will not be available."))
#     return(invisible(NULL))  # Exit .onAttach without stopping package loading
#   }
#
#   # Check Python versio Try to get Python version
#   tryCatch({
#     python_version <- system(paste(python_path, "--version"), intern = TRUE)
#     if (!grepl("Python 3", python_version)) {
#       packageStartupMessage("Python 3 is required, but a different version was found. Please install Python 3. flaiR functionality requiring Python will not be available.")
#       return(invisible(NULL))  # Exit .onAttach without stopping package loading
#     }
#   }, error = function(e) {
#     packageStartupMessage(paste("Failed to get Python version with path:", python_path, "Error:", e$message, ". flaiR functionality requiring Python will not be available."))
#     return(invisible(NULL))   # Exit .onAttach without stopping package loading
#   })
#
#   # Check if PyTorch is installed
#   check_torch_version <- function() {
#     # torch_version_command <- paste(python_path, "-c 'import torch; print(torch.__version__)'")
#     torch_version_command <- paste(python_path, "-c \"import torch; print(torch.__version__)\"")
#     result <- system(torch_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("PyTorch", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     return(list(paste("PyTorch", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE, result[1]))
#   }
#
#   # Check if flair is installed
#   check_flair_version <- function() {
#     # flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
#     flair_version_command <- paste(python_path, "-c \"import flair; print(flair.__version__)\"")
#     result <- system(flair_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     return(list(paste("flair", paste0("\033[32m", "\u2713", "\033[39m"),result[1], sep = " "), TRUE, result[1]))
#   }
#
#   flair_version <- check_flair_version()
#   torch_version <- check_torch_version()
#
#   if (isFALSE(flair_version[[2]])) {
#     packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
#
#     commands <- c(
#       paste(python_path, "-m pip install --upgrade pip"),
#       paste(python_path, "-m pip install torch"),
#       paste(python_path, "-m pip install flair"),
#       paste(python_path, "-m pip install scipy==1.12.0")
#     )
#     command_statuses <- vapply(commands, system, FUN.VALUE = integer(1))
#
#     flair_check_again <- check_flair_version()
#     if (isFALSE(flair_check_again[[2]])) {
#       packageStartupMessage("Failed to install Flair. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m", flair_version[[3]], "\033[39m\033[22m", sep = "")))
#   }
# }
.onAttach <- function(...) {
  # Docker 環境檢查及 Python 設置
  in_docker <- file.exists("/.dockerenv")

  if (in_docker) {
    # Docker 環境使用固定路徑
    python_path <- "/opt/venv/bin/python3"
    Sys.setenv(RETICULATE_PYTHON = python_path)
  } else {
    # 非 Docker 環境
    python_cmd <- if (Sys.info()["sysname"] == "Windows") "python" else "python3"
    python_path <- Sys.which(python_cmd)
  }

  # 檢查 Python 路徑
  if (python_path == "") {
    packageStartupMessage("Cannot locate Python executable. Ensure Python is installed and in PATH.")
    return(invisible(NULL))
  }

  # 檢查 Python 版本
  tryCatch({
    python_version <- system2(python_path, "--version", stdout = TRUE, stderr = TRUE)
    if (!any(grepl("Python 3", python_version))) {
      packageStartupMessage("Python 3 is required.")
      return(invisible(NULL))
    }
  }, error = function(e) {
    packageStartupMessage(sprintf("Failed to check Python version: %s", e$message))
    return(invisible(NULL))
  })

  # 檢查 PyTorch 版本
  check_torch_version <- function() {
    tryCatch({
      cmd <- sprintf("%s -c 'import torch; print(torch.__version__)'", python_path)
      result <- system(cmd, intern = TRUE)
      if (length(result) > 0 && !is.na(result[1])) {
        return(list(
          status = paste("PyTorch", "\u2713", result[1]),
          success = TRUE,
          version = result[1]
        ))
      }
    }, error = function(e) NULL)
    return(list(status = paste("PyTorch", "\u2717"), success = FALSE))
  }

  # 檢查 Flair 版本
  check_flair_version <- function() {
    tryCatch({
      cmd <- sprintf("%s -c 'import flair; print(flair.__version__)'", python_path)
      result <- system(cmd, intern = TRUE)
      if (length(result) > 0 && !is.na(result[1])) {
        return(list(
          status = paste("Flair", "\u2713", result[1]),
          success = TRUE,
          version = result[1]
        ))
      }
    }, error = function(e) NULL)
    return(list(status = paste("Flair", "\u2717"), success = FALSE))
  }

  # 執行版本檢查
  flair_check <- check_flair_version()
  torch_check <- check_torch_version()

  # 如果 Flair 未安裝，嘗試安裝
  if (!flair_check$success) {
    packageStartupMessage("Installing Flair and dependencies...")

    # 安裝命令
    install_commands <- if (in_docker) {
      c(
        sprintf("%s -m pip install --no-cache-dir numpy==1.26.4", python_path),
        sprintf("%s -m pip install --no-cache-dir torch", python_path),
        sprintf("%s -m pip install --no-cache-dir flair", python_path),
        sprintf("%s -m pip install --no-cache-dir scipy==1.12.0", python_path)
      )
    } else {
      c(
        sprintf("%s -m pip install --upgrade pip", python_path),
        sprintf("%s -m pip install torch", python_path),
        sprintf("%s -m pip install flair", python_path),
        sprintf("%s -m pip install scipy==1.12.0", python_path)
      )
    }

    # 執行安裝
    install_status <- vapply(install_commands, function(cmd) {
      tryCatch({
        system(cmd)
        TRUE
      }, error = function(e) FALSE)
    }, logical(1))

    # 重新檢查安裝
    flair_check <- check_flair_version()
    if (!flair_check$success) {
      packageStartupMessage("Failed to install Flair. Please install manually.")
      return(invisible(NULL))
    }
  }

  # 顯示啟動訊息
  packageStartupMessage(sprintf(
    "flaiR: An R Wrapper for Accessing Flair NLP %s",
    if (flair_check$success) flair_check$version else ""
  ))
}
