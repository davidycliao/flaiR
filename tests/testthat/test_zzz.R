# test_that("Python installation is checked", {
#
#   local_mock(
#     check_python_installed = function() FALSE
#   )
#
#   expect_error(flaiR:::.onAttach(), "Python is not installed. This package requires Python to run Flair.")
#
# })
#

# test_that("Flair's availability in Python is checked", {
#
#   # Mock no Flair installation
#   local_mock(
#     `reticulate::py_module_available` = function(module) ifelse(module == "flair", FALSE, TRUE)
#   )
#
#   output <- capture.output(flaiR:::.onAttach())
#   # print(output)
#   expect_error(output)
#
#   # Mock Flair being installed
#   # local_mock(
#   #   `reticulate::py_module_available` = function(module) ifelse(module == "flair", TRUE, FALSE),
#   #   get_flair_version = function() "1.0" # Assuming a mocked version
#   # )
#   #
#   # output <- capture.output(flaiR:::.onAttach(), type = "message")
#   # expect_equal("Flair: 1.0" %in%   trimws(output[3]))
#
# })

# test_that("Package's name is displayed", {
#
#   output <- capture.output(.onAttach())
#   expect_true("flai\\033[34mR\\033[39m: An R Wrapper for Accessing Flair NLP Tagging Features" %in% output)
#
# })
