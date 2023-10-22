# flair_datasets returns the expected output
test_that("flair_datasets returns the expected output", {
  # Skip test if the "reticulate" library is not available
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Check that flair_datasets() returns the expected type of object
  result <- flair_datasets()
  expect_s3_class(result, "python.builtin.module")

  # Optional: Check that the returned module contains an expected attribute
  # expect_true("an_expected_attribute" %in% py_list_attributes(result))
})
