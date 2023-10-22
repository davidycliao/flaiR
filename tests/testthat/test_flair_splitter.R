# flair_splitter.SegtokSentenceSplitter returns an object
test_that("flair_splitter.SegtokSentenceSplitter returns an object", {
  skip_if_not_installed("reticulate")
  skip_on_cran()  # Optional: skip this test on CRAN to avoid unnecessary failures

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  SegtokSentenceSplitter <- flair_splitter.SegtokSentenceSplitter()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(SegtokSentenceSplitter))
})

# flair_splitter.SegtokSentenceSplitter returns expected object
test_that("flair_splitter.SegtokSentenceSplitter returns expected object", {
  # Skip the test if the necessary modules are not available
  skip_if_not_installed("reticulate")
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  splitter <- flair_splitter.SegtokSentenceSplitter()

  # Test that the function returns a non-null object
  expect_true(!is.null(splitter))

  # Test that the returned object is of the expected class
  expect_true(inherits(splitter, "flair.splitter.SegtokSentenceSplitter"))
})


