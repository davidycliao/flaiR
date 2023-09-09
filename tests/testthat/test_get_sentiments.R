test_that("get_sentiments throws an error for unsupported languages", {
  expect_equal(nrow(get_sentiments(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"),
    language  = "sentiment")),
    2)
})


test_that("get_sentiments throws an error for unsupported languages", {
  expect_equal(nrow(get_sentiments(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"), load_tagger_sentiments())),
    2)
})


test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_sentiments(
      texts = c("TCD in less better than Oxford"),
      doc_ids= c("doc1", "doc2"),
      language  = "sentiment"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})

test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_sentiments(
      texts = c(NA),
      doc_ids= c(NA),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "sentiment",
    )[1,"sentiment"]$sentiment,
    NA
  )
})

test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_sentiments(
      texts = c("TCD in less better than Oxford", "Essex is in Colchester"),
      doc_ids= c("doc1", "doc2"),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "sentiment",
    )[1,"sentiment"]$sentiment,
    "NEGATIVE"
  )
})



