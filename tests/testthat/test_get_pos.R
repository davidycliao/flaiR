test_that("get_pos throws an error for unsupported languages", {
  expect_equal(nrow(get_pos(
    texts = c("UCD is one of the best university in Ireland. ",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids= c("doc1", "doc2", "doc3"),
    language  = "upos-fast")),
    25)
})


test_that("get_pos throws an error for unsupported languages", {
  expect_equal(nrow(get_pos(
    texts = c("UCD is one of the best university in Ireland. ",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids= c("doc1", "doc2", "doc3"),
    load_tagger_pos())),
    25)
})



test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_pos(
      texts = c(NA),
      doc_ids= c(NA),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "pos",
    )[1,"tag"]$tag,
    NA
  )
})


test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_pos(
      texts = c(""),
      doc_ids= c("  "),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "pos",
    )[1,"token"]$token,
    NA
  )
})


test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_pos(
      texts = c("TCD in less better than Oxford"),
      doc_ids= c("doc1", "doc2"),
      language  = "pos"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})

test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_pos(
      texts = c(NA),
      doc_ids= c(NA),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "pos",
    )[1,"tag"]$tag,
    NA
  )
})





