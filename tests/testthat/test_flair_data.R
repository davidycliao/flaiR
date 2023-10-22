# flair_data returns a module with Sentence attribute
test_that("flair_data returns a module with Sentence attribute", {
  flair_data_module <- flair_data()

  # Check if the module is not NULL
  expect_true(!is.null(flair_data_module))

  # Check if a specific attribute (i.e., 'Sentence') is available in the module
  expect_true("Sentence" %in% reticulate::py_list_attributes(flair_data_module))
})



# flair_data.Sentence returns expected output
test_that("flair_data.Sentence returns expected output", {
  # Skip test if the "reticulate" library is not available
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Expected use case
  result <- flair_data.Sentence("This is a sample sentence.")
  expect_s3_class(result, "python.builtin.object")
  # Additional checks can be added based on expected attributes of the output

  # Check behavior with empty string
  result_empty <- flair_data.Sentence("")
  expect_s3_class(result_empty, "python.builtin.object")

})

test_that("flair_data.sentence handles errors and unexpected input correctly", {
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Check that non-string input is handled appropriately
  expect_error(flair_data.Sentence(123), "TypeError: 'float' object is not subscriptable")
  expect_error(flair_data.Sentence(NULL), "TypeError: can only join an iterable")

  # Add more test cases for other types of unexpected input
})


