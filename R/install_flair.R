#' Install Flair NLP in Python environment
#'
#' @param force Logical, whether to force reinstall packages. Default is FALSE.
#' @param flair_version Character, specify Flair version to install. Default is "0.11.3".
#' @param pip_options Character, additional pip install options. Default is NULL.
#'
#' @return Invisible NULL, called for side effects
#' @export
install_flair <- function(force = FALSE,
                          flair_version = "0.11.3",
                          pip_options = NULL) {
  print_status <- function(component, status, extra_info = NULL) {
    symbol <- if(status) "\u2713" else "\u2717"
    color <- if(status) "\033[32m" else "\033[31m"
    message <- sprintf("%s%s\033[39m %s", color, symbol, component)
    if (!is.null(extra_info)) {
      message <- paste0(message, ": ", extra_info)
    }
    message(message)
  }

  if (!requireNamespace("reticulate", quietly = TRUE)) {
    install.packages("reticulate")
  }

  tryCatch({
    message("\nPython Configuration:")
    py_config <- reticulate::py_config()
    print_status("Python", TRUE, py_config$python)

    print_status("Version", TRUE, paste("Using Flair version:", flair_version))
    print_status("Installation", TRUE, "Installing required packages...")

    # 升級 pip 和基礎工具
    reticulate::py_install(c("pip", "setuptools", "wheel"), pip = TRUE)

    # 安裝基礎依賴（按順序）
    packages <- list(
      base = c(
        "numpy==1.26.4",
        "scipy==1.12.0"
      ),
      torch = "torch>=2.0.0",
      nlp = c(
        "sentencepiece==0.1.99",  # 指定穩定版本
        "transformers>=4.30.0",
        "tokenizers>=0.13.3"
      ),
      flair = sprintf("flair==%s", flair_version)
    )

    # 安裝基礎包
    for (pkg in packages$base) {
      print_status("Package", TRUE, paste("Installing", pkg))
      reticulate::py_install(pkg, pip = TRUE)
    }

    # 安裝 PyTorch
    print_status("Package", TRUE, "Installing PyTorch")
    reticulate::py_install(packages$torch, pip = TRUE)

    # 安裝 NLP 相關包
    for (pkg in packages$nlp) {
      print_status("Package", TRUE, paste("Installing", pkg))
      reticulate::py_install(pkg, pip = TRUE)
    }

    # 安裝 Flair
    print_status("Package", TRUE, paste("Installing Flair", flair_version))
    reticulate::py_install(packages$flair, pip = TRUE)

    # 驗證安裝
    flair_check <- try({
      flair <- reticulate::import("flair")
      version <- reticulate::py_get_attr(flair, "__version__")
      list(status = TRUE, version = version)
    }, silent = TRUE)

    if (!inherits(flair_check, "try-error") && flair_check$status) {
      print_status(
        "Flair NLP",
        TRUE,
        paste("Successfully installed version", flair_check$version)
      )
    } else {
      print_status("Flair NLP", FALSE, "Installation failed")
      message("\nTroubleshooting steps:")
      message("1. Try: pip install --no-build-isolation sentencepiece==0.1.99")
      message("2. Then run install_flair(force = TRUE)")
      message("3. If issues persist, install system dependencies:")
      message("   brew install pkg-config cmake")
    }
  }, error = function(e) {
    print_status("Installation", FALSE, paste("Error:", e$message))
    message("\nTroubleshooting steps:")
    message("1. Try installing sentencepiece manually:")
    message("   pip install --no-build-isolation sentencepiece==0.1.99")
    message("2. Check system dependencies:")
    message("   brew install pkg-config cmake")
  })

  invisible(NULL)
}
