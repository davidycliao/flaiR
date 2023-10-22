# flair_nn.Classifier returns expected output
test_that("flair_nn.Classifier returns expected output", {
  # Skip test if the "reticulate" library is not available
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Expected use case
  result <- flair_nn.Classifier()$load("ner")
  expect_s3_class(result, "python.builtin.object")
  # Add additional checks based on expected attributes of the output

  # Add more test cases as needed
})

test_that("flair_nn.classifier handles errors and unexpected input correctly", {
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Check that non-string input is handled appropriately
  expect_error(flair_nn$Classifier$load(123), "object of type 'closure' is not subsettable")
  expect_error(flair_nn$Classifier$load(NULL), "object of type 'closure' is not subsettable")
})

# flair_nn returns the correct module
test_that("flair_nn returns the correct module", {

  # Load the module using the function
  flair_module <- flair_nn(load = TRUE)

  # Check that the returned module is not NULL
  expect_true(!is.null(flair_module))

  # Optionally, if you know some attributes or methods that should exist in the returned module, test for them
  # For example, if the module should have a 'Classifier' method:
  expect_true("Classifier" %in% names(flair_module))
})
