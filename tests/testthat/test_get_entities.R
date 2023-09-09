test_that("get_entities throws an error for unsupported languages under no internet condition", {
  expect_equal(nrow(get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"),
    language  = "ner")),
    4)
})





test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_entities(
      texts = c("TCD in less better than Oxford"),
      doc_ids= c("doc1", "doc2"),
      language  = "ner"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})


test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    is.na(get_entities(
      texts = c("TCD in less better than Oxford"),
      doc_ids= c("doc1"),
      language  = "ner"
    )[3,"tag"]$tag),
    TRUE
  )
})


test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_entities(
      texts = c("xxxxxxxxx"),
      doc_ids= c("doc1"),
      language  = "ner"
    )[1,"tag"]$tag,
    NA
  )
})

test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_entities(
      texts = c(NA),
      doc_ids= c(NA),
      language  = "ner",
    )[1,"tag"]$tag,
    NA
  )
})



test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_equal(
    get_entities(
      texts = c(NA),
      doc_ids= c(NA),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "ner",
    )[1,"tag"]$tag,
    NA
  )
})



test_that("get_entities", {
  expect_equal(
    get_entities(
      texts = c("TCD in less better than Oxford"),
      doc_ids= c("doc1"),
      show.text_id = TRUE,
      gc.active = TRUE,
      language  = "ner",
    )[1,"tag"]$tag,
    "ORG"
  )
})











