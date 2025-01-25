# flair_embeddings returns an object
test_that("flair_embeddings returns an object", {
  skip_if_not_installed("reticulate")

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  embeddings_module <- flair_embeddings()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(embeddings_module))

  # Optionally: Additional tests to check if the imported object has expected attributes or methods
  # For example, if we expect embeddings_module to have a method named "FlairEmbeddings", we might test:
  expect_true("TransformerEmbeddings" %in% reticulate::py_list_attributes(embeddings_module))
})


# flair_embeddings.FlairEmbeddings gives messages and stops as expected
# test_that("flair_embeddings.FlairEmbeddings gives messages and stops as expected", {
#   # Skipping if necessary modules are not available
#   skip_if_not_installed("reticulate")
#   available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
#   skip_if_not(available, "Python or the 'flair' module is not available")
#
#   # Testing if the function issues the expected message
#   embedding <- flair_embeddings.FlairEmbeddings("news-forward")
#   expect_message(message( py_get_attr(embedding, "__class__")$`__name__`), "FlairEmbeddings")
#
#   # Testing if the function issues an error with invalid input
#   expect_error(flair_embeddings.FlairEmbeddings("invalid_type"),
#                "ValueError: The given model \"invalid_type\" is not available or is not a valid path.",
#                fixed = TRUE)
# })

# Function should raise an error if embeddings_list is not a list
test_that("function raises error for non-list input", {
  expect_error(flair_embeddings.StackedEmbeddings("not_a_list"),
               "embeddings_list should be a list of Flair embeddings.")
})


# flair_embeddings.WordEmbeddings runs without errors
# test_that("flair_embeddings.WordEmbeddings runs without errors", {
#   expect_silent(flair_embeddings.WordEmbeddings())
# })
