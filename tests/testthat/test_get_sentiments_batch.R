# Test 1: Ensure the length of texts and doc_ids are the same.

test_that("Ensure the length of texts and doc_ids are the same", {
  expect_error(get_sentiments_batch(texts = c("text1", "text2"),
                                    doc_ids = "id1"),
               "The lengths of texts and doc_ids do not match.")
})

# Test 2: Check if texts is empty after removing NAs and empty texts
test_that("Check if texts is empty after removing NAs and empty texts", {
  expect_message(get_sentiments_batch(texts = c("", NA, NA),
                                    doc_ids = c("id1", "id2", "id3")),
                 "CPU is used.", fixed = FALSE)
})

# Test 3: Check sentiment and score for specific input text

test_that("Check sentiment and score for specific input text", {
  result <- get_sentiments_batch(texts = "some_text_without_sentiment",
                                 doc_ids = "id1")

  expect_equal(result$sentiment[1], "NEGATIVE")
  expect_equal(result$score[1], 0.9968621, tolerance = 0.0001)
})

# Test 4. text_id` is added to the result only if `show.text_id` is TRUE
test_that("`text_id` is added to the result only if `show.text_id` is TRUE", {
  result_with_text_id <- get_sentiments_batch(texts = "some_text",
                                              doc_ids = "id1",
                                              show.text_id = TRUE)
  expect_true("text_id" %in% names(result_with_text_id))

  result_without_text_id <- get_sentiments_batch(texts = "some_text",
                                                 doc_ids = "id1",
                                                 show.text_id = FALSE)
  expect_false("text_id" %in% names(result_without_text_id))
})
