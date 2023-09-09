# test_that("get_pos throws an error for unsupported languages", {
#   expect_equal(nrow(get_pos(
#     texts = c("UCD is one of the best university in Ireland. ",
#               "Essex is famous in social science research",
#               "TCD is the oldest one in Ireland."),
#     doc_ids= c("doc1", "doc2", "doc3"),
#     language  = "upos-fast")),
#     25)
# })
#
#
# test_that("get_pos throws an error for unsupported languages", {
#   expect_equal(nrow(get_pos(
#     texts = c("UCD is one of the best university in Ireland. ",
#               "Essex is famous in social science research",
#               "TCD is the oldest one in Ireland."),
#     doc_ids= c("doc1", "doc2", "doc3"),
#     load_tagger_pos())),
#     25)
# })
#
#
#
# test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     get_pos(
#       texts = c(NA),
#       doc_ids= c(NA),
#       show.text_id = TRUE,
#       gc.active = TRUE,
#       language  = "pos",
#     )[1,"tag"]$tag,
#     NA
#   )
# })
#
#
# test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     get_pos(
#       texts = c(""),
#       doc_ids= c("  "),
#       show.text_id = TRUE,
#       gc.active = TRUE,
#       language  = "pos",
#     )[1,"token"]$token,
#     NA
#   )
# })
#
#
# test_that("get_entities throws an error for mismatched lengths of texts and doc_ids", {
#   expect_error(
#     get_pos(
#       texts = c("TCD in less better than Oxford"),
#       doc_ids= c("doc1", "doc2"),
#       language  = "pos"
#     ),
#     "The lengths of texts and doc_ids do not match."
#   )
# })
#
# test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
#   expect_equal(
#     get_pos(
#       texts = c(NA),
#       doc_ids= c(NA),
#       show.text_id = TRUE,
#       gc.active = TRUE,
#       language  = "pos",
#     )[1,"tag"]$tag,
#     NA
#   )
# })
#

# Test 1: get_pos returns part-of-speech tags for three input texts using "upos-fast"
test_that("get_pos returns part-of-speech tags for three input texts using 'upos-fast'", {
  result <- get_pos(
    texts = c("UCD is one of the best universities in Ireland.",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids = c("doc1", "doc2", "doc3"),
    language = "upos-fast"
  )
  # Check that the number of rows in the result matches the number of tokens
  expect_equal(nrow(result), 25)
})

# Test 2: get_pos returns part-of-speech tags for three input texts using a custom tagger
test_that("get_pos returns part-of-speech tags for three input texts using a custom tagger", {
  result <- get_pos(
    texts = c("UCD is one of the best universities in Ireland.",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids = c("doc1", "doc2", "doc3"),
    tagger = load_tagger_pos(),
    language = "upos-fast"
  )
  # Check that the number of rows in the result matches the number of tokens
  expect_equal(nrow(result), 25)
})

# Test 3: get_pos handles NA values and returns NA for part-of-speech tags
test_that("get_pos handles NA values and returns NA for part-of-speech tags", {
  result <- get_pos(
    texts = c(NA),
    doc_ids = c(NA),
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "pos"
  )
  # Check that the part-of-speech tag is NA
  expect_true(is.na(result[1, "tag"]$tag))
})

# Test 4: get_pos handles empty texts and returns NA for part-of-speech tags
test_that("get_pos handles empty texts and returns NA for part-of-speech tags", {
  result <- get_pos(
    texts = c(""),
    doc_ids = c("  "),
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "pos"
  )
  # Check that the part-of-speech tag is NA
  expect_true(is.na(result[1, "token"]$token))
})

# Test 5: get_pos throws an error for mismatched lengths of texts and doc_ids
test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_pos(
      texts = c("TCD in less better than Oxford"),
      doc_ids = c("doc1", "doc2"),
      language = "pos"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})

# Test 6: get_pos handles NA values and returns NA for part-of-speech tags
test_that("get_pos handles NA values and returns NA for part-of-speech tags", {
  result <- get_pos(
    texts = c(NA),
    doc_ids = c(NA),
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "pos"
  )
  # Check that the part-of-speech tag is NA
  expect_true(is.na(result[1, "tag"]$tag))
})



