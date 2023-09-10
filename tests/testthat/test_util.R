# Test 1: Ensure that `get_entities` provides the expected row count when
# provided with specific texts, doc_ids, and a pre-loaded tagger.
test_that("get_entities throws an error for unsupported languages under no internet condition", {
  expect_equal(nrow(get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"), load_tagger_ner("en"))),
    4)
})


# Test 2: Similar test as above, but without explicitly specifying the language
# for the tagger. This tests the default behavior.
test_that("get_entities throws an error for unsupported languages", {
  expect_equal(nrow(get_entities(
    texts = c("UCD is one of the best university in Ireland. ",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2"), load_tagger_ner())),
    4)
})

# Test 3: Test the `get_flair_version` function to ensure it returns a character type.
test_that("is.character", {
  expect_equal(is.character(get_flair_version()), TRUE)
})

# Test 4: Duplicate of the above test; testing `get_flair_version`
# for character type return.
test_that("get_flair_version", {
  expect_equal(is.character(get_flair_version()), TRUE)
})

# Test 5: Check if the `check_python_installed` function returns a non-character.
test_that("check_python_installed", {
  expect_equal(is.character(check_python_installed()), FALSE)
})

# Test 6: Test to see if `check_python_installed` is a function.
test_that("check_python_installed", {
  expect_equal(is.function(check_python_installed), TRUE)
})

# Test 7: Ensure `clear_flair_cache` is recognized as a function.
test_that("clear_flair_cache", {
  expect_equal(is.function(clear_flair_cache), TRUE)
})

# Test 8: Ensure `check_and_gc` is recognized as a function.
test_that("check_and_gc", {
  expect_equal(is.function(check_and_gc), TRUE)
})

# Test 9: Ensure `check_device` returns "CPU is in use."
test_that("Ensure `check_device` returns 'CPU is use'", {
  expect_message(check_device("cpu"), "CPU is use")
})

# Test 10: Ensure `check_batch_size` returns an error when provided with characters.
test_that("check_batch_size", {
  expect_error(check_batch_size("1"), "Invalid batch size. It must be a positive integer.")
})

# Test 11: Ensure `check_batch_size` returns an error when provided with characters.
test_that("check_batch_size", {
  expect_error(check_texts_and_ids(NULL, NULL), "texts cannot be NULL or empty.")
})
