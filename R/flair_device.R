#' @title Set Flair Device
#'
#' @description This function sets the device for the Flair Python library.
#' It allows you to set the device to use CPU, GPU (such as coda:0, coda:1,
#' and coda:3), or specific MPS devices on Mac (such as mps:0, mps:1, mps:2).
#'
#' @param device A character string specifying the device.
#' Valid options include: "cpu", "cuda", "mps:0", "mps:1", "mps:2", etc.
#'
#' @return The set device for Flair.
#'
#' @importFrom reticulate import
#'
#' @export
#'
#' @examples
#' \dontrun{
#' flair_device("cpu")    # Set device to CPU
#' flair_device("cuda")   # Set device to GPU (if available)
#' flair_device("mps:0")  # Set device to MPS device 0 (if available on Mac)
#' }
flair_device <- function(device = "cpu") {
  ##
  ##
  torch <- import("torch")
  flair$device <- flair$torch$device(device)
  return(flair$device)
}
