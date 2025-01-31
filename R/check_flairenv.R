#' Check Flair Environment Status
#'
#' @title Check Flair Environment Status
#' @description Check and verify the status of Python and Flair NLP installation in the environment.
#'
#' @return A list containing environment status information:
#' \itemize{
#'   \item status: Logical indicating if environment check passed
#'   \item message: Status message
#'   \item path: Path to Python environment
#'   \item python_version: Installed Python version
#'   \item flair_version: Installed Flair version (if available)
#'   \item is_docker: Logical indicating if running in Docker
#' }
#'
#' @examples
#' \dontrun{
#' # Check environment status
#' env_status <- check_flairenv()
#'
#' # Print status information
#' print(env_status)
#' }
#'
#' @export
check_flairenv <- function() {
  # Print status utility
  print_status <- function(component, status, extra_info = NULL) {
    symbol <- if(status) "\u2713" else "\u2717"
    color <- if(status) "\033[32m" else "\033[31m"
    message <- sprintf("%s%s\033[39m %s", color, symbol, component)
    if (!is.null(extra_info)) {
      message <- paste0(message, ": ", extra_info)
    }
    packageStartupMessage(message)
  }

  # Check if running in Docker
  is_docker <- file.exists("/.dockerenv")

  # Check operating system
  os_name <- Sys.info()["sysname"]

  # Set environment variables for macOS
  if (os_name == "Darwin") {
    current_kmp <- Sys.getenv("KMP_DUPLICATE_LIB_OK")
    Sys.setenv(KMP_DUPLICATE_LIB_OK = "TRUE")
    print_status("KMP_DUPLICATE_LIB_OK", TRUE,
                 sprintf("%s -> TRUE", if(current_kmp == "") "not set" else current_kmp))
  }

  # Get Python path
  if (is_docker) {
    python_path <- Sys.getenv("RETICULATE_PYTHON")
    if (python_path == "") {
      python_cmd <- if(os_name == "Windows") "python" else "python3"
      python_path <- Sys.which(python_cmd)
      if (python_path == "") {
        return(list(
          status = FALSE,
          message = "No Python found in Docker environment",
          path = NULL,
          python_version = NULL,
          flair_version = NULL,
          is_docker = TRUE
        ))
      }
    }
    print_status("Environment", TRUE, "Docker detected")
  } else {
    # Local environment setup
    home_dir <- path.expand("~")
    venv_path <- file.path(home_dir, "flair_env")
    python_path <- if(os_name == "Windows") {
      file.path(venv_path, "Scripts", "python.exe")
    } else {
      file.path(venv_path, "bin", "python")
    }

    # Check if virtual environment exists
    if (!dir.exists(venv_path) || !file.exists(python_path)) {
      return(list(
        status = FALSE,
        message = "Virtual environment not found or incomplete",
        path = venv_path,
        python_version = NULL,
        flair_version = NULL,
        is_docker = FALSE
      ))
    }
  }

  # Check Python version
  tryCatch({
    cmd <- sprintf('"%s" -V', python_path)
    python_version <- system(cmd, intern = TRUE)

    # Extract version number
    version_match <- regexpr("Python ([0-9.]+)", python_version)
    if (version_match > 0) {
      version_str <- regmatches(python_version, version_match)[[1]]
      version_parts <- strsplit(gsub("Python ", "", version_str), "\\.")[[1]]
      major <- as.numeric(version_parts[1])
      minor <- as.numeric(version_parts[2])

      python_status <- (major == 3 && minor >= 9 && minor <= 12)
      if (!python_status) {
        return(list(
          status = FALSE,
          message = "Incompatible Python version",
          path = python_path,
          python_version = version_str,
          flair_version = NULL,
          is_docker = is_docker
        ))
      }
    }

    # Check Flair installation
    cmd <- sprintf('"%s" -c "import flair; print(flair.__version__)"', python_path)
    flair_version <- tryCatch({
      system(cmd, intern = TRUE)[1]
    }, error = function(e) NULL)

    if (is.null(flair_version)) {
      return(list(
        status = FALSE,
        message = "Flair not installed",
        path = python_path,
        python_version = python_version,
        flair_version = NULL,
        is_docker = is_docker
      ))
    }

    # All checks passed
    return(list(
      status = TRUE,
      message = "Environment check successful",
      path = python_path,
      python_version = python_version,
      flair_version = flair_version,
      is_docker = is_docker
    ))

  }, error = function(e) {
    return(list(
      status = FALSE,
      message = paste("Error checking environment:", e$message),
      path = python_path,
      python_version = NULL,
      flair_version = NULL,
      is_docker = is_docker
    ))
  })
}
