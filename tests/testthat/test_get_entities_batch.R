
test_that("batch_texts and batch_doc_ids lengths mismatch", {
  expect_error(get_entities_batch(texts = c("text1", "text2"),
                                  doc_ids = c("id1"),
                                  show.text_id = FALSE),
               "The lengths of texts and doc_ids do not match.")
})

test_that("NA values for text or doc_id", {
  result <- get_entities_batch(texts = c("text1", NA),
                               doc_ids = c("id1", "id2"),
                               show.text_id = FALSE)
  expect_equal(typeof(result$doc_id[2]), "character")
  expect_equal(result$entity[2], NA)
  expect_equal(result$tag[2], NA)
})

test_that("No entities detected", {
  # Assuming that the tagger returns no entities for "text_without_entity"
  result <- get_entities_batch(texts = "text_without_entity",
                               doc_ids = "id1",
                               show.text_id = FALSE)
  expect_equal(result$doc_id[1], "id1")
  expect_equal(result$entity[1], NA)
  expect_equal(result$tag[1], NA)
})

test_that("Inclusion of doc_id when show.text_id is TRUE", {
  result <- get_entities_batch(texts = "text1",
                               doc_ids = "id1",
                               show.text_id = TRUE)
  expect_true("text_id" %in% colnames(result))
  expect_equal(result$text_id[1], "text1")
})


test_that("Mismatched lengths of batch_texts and batch_doc_ids raise an error", {
  expect_error(get_entities_batch(c("Hello", "World"), "doc1", show.text_id = TRUE),
               "The lengths of texts and doc_ids do not match.")
})

test_that("show.text_id = TRUE adds a text_id column", {
  result <- get_entities_batch(c("Hello", "World"), c("doc1", "doc2"), show.text_id = TRUE)
  expect_true("text_id" %in% names(result))
})

test_that("show.text_id = FALSE does not add a text_id column", {
  result <- get_entities_batch(c("Hello", "World"), c("doc1", "doc2"), show.text_id = TRUE)
  expect_true("text_id" %in% colnames(result))
})

