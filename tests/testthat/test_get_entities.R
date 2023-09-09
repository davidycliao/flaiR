# test_that("get_entities throws an error for unsupported languages under no internet condition", {
#   expect_equal(nrow(get_entities(
#     texts = c("UCD is one of the best university in Ireland. ",
#               "TCD in less better than Oxford"),
#     doc_ids= c("doc1", "doc2"),
#     language  = "ner")),
#     4)
# })
#
#
#
#
#
# test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
#   expect_error(
#     get_entities(
#       texts = c("TCD in less better than Oxford"),
#       doc_ids= c("doc1", "doc2"),
#       language  = "ner"
#     ),
#     "The lengths of texts and doc_ids do not match."
#   )
# })
#
#
# test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     is.na(get_entities(
#       texts = c("TCD in less better than Oxford"),
#       doc_ids= c("doc1"),
#       language  = "ner"
#     )[3,"tag"]$tag),
#     TRUE
#   )
# })
#
#
# test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     get_entities(
#       texts = c("xxxxxxxxx"),
#       doc_ids= c("doc1"),
#       language  = "ner"
#     )[1,"tag"]$tag,
#     NA
#   )
# })
#
# test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     get_entities(
#       texts = c(NA),
#       doc_ids= c(NA),
#       language  = "ner",
#     )[1,"tag"]$tag,
#     NA
#   )
# })
#
#
#
# test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     get_entities(
#       texts = c(NA),
#       doc_ids= c(NA),
#       show.text_id = TRUE,
#       gc.active = TRUE,
#       language  = "ner",
#     )[1,"tag"]$tag,
#     NA
#   )
# })
#
#
#
# test_that("get_entities", {
#   expect_equal(
#     get_entities(
#       texts = c("TCD in less better than Oxford"),
#       doc_ids= c("doc1"),
#       show.text_id = TRUE,
#       gc.active = TRUE,
#       language  = "ner",
#     )[1,"tag"]$tag,
#     "ORG"
#   )
# })
#




# Test 1: get_entities returns four entities for two input texts using "ner"
test_that("get_entities returns four entities for two input texts using 'ner'", {
  result <- get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids = c("doc1", "doc2"),
    language = "ner"
  )
  # Check that the number of rows in the result matches the expected number of entities
  expect_equal(nrow(result), 4)
})

# Test 2: get_entities throws an error for mismatched lengths of texts and doc_ids
test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_entities(
      texts = c("TCD in less better than Oxford"),
      doc_ids = c("doc1", "doc2"),
      language = "ner"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})

# Test 3: get_entities returns NA for the "tag" field when there are mismatched lengths of texts and doc_ids
test_that("get_entities returns NA for the 'tag' field when there are mismatched lengths of texts and doc_ids", {
  result <- get_entities(
    texts = c("TCD in less better than Oxford"),
    doc_ids = c("doc1"),
    language = "ner"
  )
  # Check that the "tag" field is NA
  expect_true(is.na(result[3, "tag"]$tag))
})

# Test 4: get_entities returns NA for the "tag" field when the input text does not contain entities
test_that("get_entities returns NA for the 'tag' field when the input text does not contain entities", {
  result <- get_entities(
    texts = c("xxxxxxxxx"),
    doc_ids = c("doc1"),
    language = "ner"
  )
  # Check that the "tag" field is NA
  expect_true(is.na(result[1, "tag"]$tag))
})

# Test 5: get_entities returns NA for the "tag" field when the input text is NA
test_that("get_entities returns NA for the 'tag' field when the input text is NA", {
  result <- get_entities(
    texts = c(NA),
    doc_ids = c(NA),
    language = "ner"
  )
  # Check that the "tag" field is NA
  expect_true(is.na(result[1, "tag"]$tag))
})

# Test 6: get_entities returns NA for the "tag" field when the input text is NA and show.text_id is TRUE
test_that("get_entities returns NA for the 'tag' field when the input text is NA and show.text_id is TRUE", {
  result <- get_entities(
    texts = c(NA),
    doc_ids = c(NA),
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "ner"
  )
  # Check that the "tag" field is NA
  expect_true(is.na(result[1, "tag"]$tag))
})

# Test 7: get_entities returns the correct entity tag "ORG" for an input text
test_that("get_entities returns the correct entity tag 'ORG' for an input text", {
  result <- get_entities(
    texts = c("TCD in less better than Oxford"),
    doc_ids = c("doc1"),
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "ner"
  )
  # Check that the entity tag is "ORG"
  expect_equal(result[1, "tag"]$tag, "ORG")
})






