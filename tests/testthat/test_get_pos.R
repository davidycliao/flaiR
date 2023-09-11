# Test 1: get_pos returns pos tags for three input texts using "upos-fast"
test_that("get_pos returns pos tags for three input texts using 'upos-fast'", {
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

# Test 2: get_pos returns pos tags for three input texts using a custom tagger
test_that("get_pos returns pos tags for three input texts using a custom tagger", {
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

# Test 3: get_pos handles NA values and returns NA for pos tags
test_that("get_pos handles NA values and returns NA for pos tags", {
  result <- get_pos(
    texts = NA,
    doc_ids = NA,
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "pos"
  )
  # Check that the part-of-speech tag is NA
  expect_true(is.na(result[1, "tag"]$tag))
})

# Test 4: get_pos throws an error for mismatched lengths of texts and doc_ids
test_that("get_pos throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_pos(
      texts = "TCD in less better than Oxford",
      doc_ids = c("doc1", "doc2"),
      language = "pos"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})


# Test 5: get_pos handles NA values and returns NA for part-of-speech tags
test_that("get_pos handles NA values and returns NA for part-of-speech tags", {
  result <- get_pos(
    texts = NA,
    doc_ids = NA,
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "pos"
  )
  # Check that the part-of-speech tag is NA
  expect_true(is.na(result[1, "tag"]$tag))
})

# Test 6: get_pos throws batch_size should be a positive integer.
test_that("get_pos_batch throws an error for no valid texts provided.", {
  expect_identical(
    print(get_pos(
      texts = "NA",
      doc_ids = "NA",
      language = "pos",
      gc.active = FALSE)[1, "tag"]$tag),
    "NNP"
  )
})

# Test 7: get_pos throws batch_size should be a positive integer.

test_that("get_pos_batch throws an error for no valid texts provided.", {
  expect_identical(
    print(get_pos(
      texts = "",
      doc_ids = "",
      language = "pos",
      gc.active = FALSE)[1, "tag"]$tag),
    NA
  )
})

# Test 8: test loading tagger works as expected

test_that("loading tagger works as expected", {
  # Assuming you have a valid tagger object for English
  valid_tagger <- load_tagger_pos("pos-fast")

  # Test 1: tagger is NULL and no language is specified
  expect_message(get_pos("Hello World", "doc1"), "Language is not specified. pos-fastin Flair is forceloaded. Please ensure that the internet connectivity is stable.")

# Test 2: tagger is NULL but a language is specified
expect_silent(get_pos("Hello World", "doc1", language = "pos"))
#
# Test 3: a valid tagger object is passed
expect_silent(get_pos("Hello World", "doc1", tagger = valid_tagger))
})

# Test 9:
