
test_that("get_entities throws an error for unsupported languages under no internet condition", {
  expect_equal(nrow(get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"), load_tagger_ner("en"))),
    4)
})

test_that("get_entities throws an error for unsupported languages under no internet condition", {
  expect_equal(nrow(get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"), load_tagger_ner())),
    4)
})

test_that("is.character", {
  expect_equal(is.character(get_flair_version()), TRUE)
})


test_that("get_flair_version", {
  expect_equal(is.character(get_flair_version()), TRUE)
})

test_that("check_python_installed", {
  expect_equal(is.character(check_python_installed()), FALSE)
})


test_that("check_python_installed", {
  expect_equal(is.logical(check_python_installed()), TRUE)
})


test_that("check_python_installed", {
  expect_equal(is.function(clear_flair_cache), TRUE)
})


