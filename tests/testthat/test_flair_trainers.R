# flair_trainers returns an object
test_that("flair_trainers returns an object", {
  skip_if_not_installed("reticulate")
  skip_on_cran()  # Optional: skip this test on CRAN

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  trainers <- flair_trainers()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(trainers))

  # Optionally: Additional tests to check if the imported object has expected attributes or methods
  # For example, if we expect trainers to have a method named "ModelTrainer", we might test:
  expect_true("ModelTrainer" %in% reticulate::py_list_attributes(trainers))
})


# flair_trainers returns expected object
test_that("flair_trainers returns expected object", {
  # Skip the test if the necessary modules are not available
  skip_if_not_installed("reticulate")
  skip_on_cran()
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  trainers <- flair_trainers()

  # Test that the function returns a non-null object
  expect_true(!is.null(trainers))

  # Test that the returned object is of the expected class
  expect_true(inherits(trainers, "python.builtin.module"))
})


# flair_trainers returns the trainers module with expected attributes
test_that("flair_trainers returns the trainers module with expected attributes", {
  trainers_module <- flair_trainers()

  # Check if the returned module is not NULL
  expect_true(!is.null(trainers_module))

  # Check if the module has expected attributes/classes
  # For example, let's assume you expect a 'ModelTrainer' class in the trainers module
  expect_true("ModelTrainer" %in% reticulate::py_list_attributes(trainers_module))
})


