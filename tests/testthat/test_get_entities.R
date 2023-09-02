test_that("get_entities throws an error for unsupported languages under no internet condition", {
  expect_equal(nrow(get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"),
    language  = "ner")),
    4)
})
