# flair_models.Sequencetagger returns the SequenceTagger object
test_that("flair_models.sequencetagger returns the SequenceTagger object", {
  SequenceTagger <- flair_models.Sequencetagger()

  # Check if the returned object is not NULL
  expect_true(!is.null(SequenceTagger))

  # Check if the returned object has expected attribute/method
  # e.g., predict - replace this with an actual method if it's not correct
  expect_true("predict" %in% reticulate::py_list_attributes(SequenceTagger))
})

# flair_models returns a module with expected attribute
test_that("flair_models returns a module with expected attribute", {
  flair_models_module <- flair_models()

  # Check if the module is not NULL
  expect_true(!is.null(flair_models_module))

  # Check if a specific attribute (e.g., 'TextClassifier') is available in the module
  expect_true("TextClassifier" %in% reticulate::py_list_attributes(flair_models_module))
})


# flair_models.TextClassifier retrieves Python TextClassifier class
test_that("flair_models.TextClassifier retrieves Python TextClassifier class", {

  # Note: You may specify a Python environment if required using use_python or use_condaenv.
  # reticulate::use_python("path_to_python", required = TRUE)

  # Call the function
  TextClassifier <- flair_models.TextClassifier()

  # Test: Check if TextClassifier is indeed a Python Class from the flair.models module
  expect_s3_class(TextClassifier, "python.builtin.type")
  expect_true("load" %in% py_list_attributes(TextClassifier))

  # Optionally: Check if the TextClassifier can load a model (ensuring it's functional)
  # Note: This might require internet access and additional time.
  # skip_on_cran()  # Consider skipping this in CRAN checks
  #
  classifier <- TextClassifier$load('sentiment')
  expect_s3_class(classifier, "python.builtin.object")
  expect_true("predict" %in% py_list_attributes(classifier))
})

# flair_models returns the expected Python module
test_that("flair_models returns the expected Python module", {

  # Ensure reticulate uses the correct Python installation
  # You might specify a particular Python environment to ensure consistency
  # use_python("path/to/python", required = TRUE)

  flair.models <- flair_models()

  # Check if it is a Python Module and if it contains the expected attribute (TextClassifier)
  expect_s3_class(flair.models, "python.builtin.module")
  expect_true("TextClassifier" %in% py_list_attributes(flair.models))
})

# flair_models.Sequencetagger returns an object
test_that("flair_models.Sequencetagger returns an object", {
  skip_if_not_installed("reticulate")
  skip_on_cran()  # Optional: skip this test on CRAN

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  SequenceTagger <- flair_models.Sequencetagger()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(SequenceTagger))

  # Optionally: Additional tests to check if the imported object has expected attributes or methods
  # For example, if we expect SequenceTagger to have a method named "load", we might test:
  expect_true("load" %in% names(SequenceTagger))
})


# flair_models.Sequencetagger returns expected object
test_that("flair_models.Sequencetagger returns expected object", {
  # Skip the test if the necessary modules are not available
  skip_if_not_installed("reticulate")
  skip_on_cran()
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  seq_tagger <- flair_models.Sequencetagger()

  # Test that the function returns a non-null object
  expect_true(!is.null(seq_tagger))

  # Test that the returned object is of the expected class
  expect_true(inherits(seq_tagger, "python.builtin.type"))
})

