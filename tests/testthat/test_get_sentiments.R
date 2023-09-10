# Test 1: get_sentiments returns sentiment scores for two input texts
test_that("get_sentiments returns sentiment scores for two input texts", {
  result <- get_sentiments(
    texts = c("UCD is one of the best universities in Ireland.",
              "TCD is less better than Oxford."),
    doc_ids = c("doc1", "doc2"),
    language = "sentiment"
  )
  # Check that the number of rows in the result matches the number of texts
  expect_equal(nrow(result), 2)
})


# Test 2: get_sentiments returns sentiment scores for two input texts
test_that("get_sentiments returns sentiment scores for two input texts", {
  result <- get_sentiments_batch(
    texts = c("UCD is one of the best universities in Ireland.",
              "TCD is less better than Oxford."),
    doc_ids = c("doc1", "doc2"),
    language = "sentiment"
  )
  # Check that the number of rows in the result matches the number of texts
  expect_equal(nrow(result), 2)
})

# Test 3: get_sentiments returns sentiment scores using a custom tagger
test_that("get_sentiments returns sentiment scores using a custom tagger", {
  result <- get_sentiments(
    texts = c("UCD is one of the best universities in Ireland.",
              "TCD is less better than Oxford."),
    doc_ids = c("doc1", "doc2"),
    tagger = load_tagger_sentiments(),
    language = "sentiment"
  )
  # Check that the number of rows in the result matches the number of texts
  expect_equal(nrow(result), 2)
})

# Test 4: get_sentiments throws an error for mismatched lengths of texts and doc_ids
test_that("get_sentiments throws an error for mismatched lengths of texts and doc_ids", {
  expect_error(
    get_sentiments(
      texts = "TCD in less better than Oxford",
      doc_ids = c("doc1", "doc2"),
      language = "sentiment"
    ),
    "The lengths of texts and doc_ids do not match."
  )
})

# Test 5: get_sentiments handles NA values and returns NA for sentiment scores
test_that("get_sentiments handles NA values and returns NA for sentiment scores", {
  result <- get_sentiments(
    texts = NA,
    doc_ids = NA,
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "sentiment"
  )
  # Check that the sentiment score is NA
  expect_true(is.na(result[1, "score"]$score))
})


# Test 6: get_sentiments returns "The lengths of texts and doc_ids do not match.
test_that("get_sentiments returns The lengths of texts and doc_ids do not match.", {

  expect_error(get_sentiments(
    texts = "TCD in less better than Oxford", "Essex is in Colchester",
    doc_ids = c("doc1", "doc2"),
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "sentiment"
  )
  , "The lengths of texts and doc_ids do not match.")
})

# Test 7: get_sentiments with empty input returns NA for score
test_that("get_sentiments with empty input returns NA for score", {
  # Call get_sentiments with empty input
  result <- get_sentiments(
    texts = "",
    doc_ids = "",
    show.text_id = TRUE,
    gc.active = TRUE,
    language = "sentiment"
  )
  # Check that the result has one row and the "score" column is NA
  expect_equal(nrow(result), 1)
  expect_true(is.na(result$score))
})
