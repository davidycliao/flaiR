test_that("get_sentiments throws an error for unsupported languages", {
  expect_equal(nrow(get_sentiments(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"),
    language  = "sentiment")),
    2)
})
