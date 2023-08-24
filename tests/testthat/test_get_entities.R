
test_that("get_pos throws an error for unsupported languages", {
  expect_error(get_pos(
    texts = c("UCD is one of the best university in Ireland. ",
              "UCD is good and a bit less better than Trinity.",
              "Essex is famous in social science research",
              "Essex is not in Russell Group but it is not bad in politics",
              "TCD is the oldest one in Ireland.",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6"),
    language  = "chinese"),
    regexp = "flair is not installed in the current Python environment.")
})


#
#
# # Define a test
# library(testthat)
# test_that("get_pos throws an error for unsupported languages and Flair not installed", {
#   # Test unsupported language error
#   expect_error(
#     get_pos(
#       texts = c("UCD is one of the best university in Ireland."),
#       doc_ids = c("doc1"),
#       language = "chinese"
#     ),
#     regexp = "Unsupported language."
#   )
#
#   # Test Flair not installed error
#   # Assume that the error message for Flair not installed is "flair is not installed in the current Python environment."
#   expect_error(
#     get_pos(
#       texts = c("UCD is one of the best university in Ireland."),
#       doc_ids = c("doc1"),
#       language = "chinese"
#     ),
#     regexp = "flair is not installed in the current Python environment."
#   )
# })
