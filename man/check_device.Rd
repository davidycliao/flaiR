% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{check_device}
\alias{check_device}
\title{Check the Device for Accelerating PyTorch}
\usage{
check_device(device)
}
\arguments{
\item{device}{A character string specifying the device type.}
}
\value{
A PyTorch device object.
}
\description{
This function verifies if the specified device is available for PyTorch.
If CUDA is not available, a message is shown. Additionally, if the system
is running on a Mac M1, MPS will be used instead of CUDA. Checks if the specified device is compatible with the current system's
hardware and operating system configuration, particularly for Mac systems
with Apple M1/M2 silicon using Metal Performance Shaders (MPS).
}
\details{
If MPS is available and the system meets the requirements, a device of type
MPS will be returned. Otherwise, a CPU device will be used. The requirements
for using MPS are as follows:\\cr
\itemize{
\item Mac computers with Apple silicon or AMD GPUs\\cr
\item macOS 12.3 or later\\cr
\item Python 3.7 or later\\cr
\item Xcode command-line tools installed (\code{xcode-select --install})\\cr
More information at: \url{https://developer.apple.com/metal/pytorch/}.
}
}
\keyword{internal}
