# Test 1: Ensure that `get_entities` provides the expected row count when
# provided with specific texts, doc_ids, and a pre-loaded tagger.
# test_that("get_entities throws an error for unsupported languages under no internet condition", {
#   expect_equal(nrow(get_entities(
#     texts = c("UCD is one of the best university in Ireland. ",
#               "TCD in less better than Oxford"),
#     doc_ids= c("doc1", "doc2"), load_tagger_ner("en"))),
#     4)
# })
#

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


# Test 13: check_and_gc does not throw error for logical input and collects garbage when TRUE

test_that("check_and_gc does not throw error for logical input and collects garbage when TRUE", {
  expect_silent(check_and_gc(FALSE))
  # Capture the message to ensure that gc() is called when gc.active is TRUE
  expect_message(check_and_gc(TRUE), "Garbage collection after processing all texts")
})

test_that("check_and_gc throws error for non-logical input", {
  expect_error(check_and_gc("not logical"), "should be a logical value")
  expect_error(check_and_gc(10), "should be a logical value")
  expect_error(check_and_gc(NULL), "should be a logical value")
  expect_error(check_and_gc(NA), "should be a logical value")
})


# Test 14: check_show.text_id correctly handles logical input
test_that("check_show.text_id correctly handles logical input", {
  expect_silent(check_show.text_id(TRUE))
  expect_silent(check_show.text_id(FALSE))
})

test_that("check_show.text_id throws error for non-logical input", {
  expect_error(check_show.text_id("not logical"), "should be a non-NA logical value")
  expect_error(check_show.text_id(10), "should be a non-NA logical value")
  expect_error(check_show.text_id(NULL), "should be a non-NA logical value")
  expect_error(check_show.text_id(NA), "should be a non-NA logical value")
})


test_that("check_texts_and_ids handles input correctly", {
  # Check that the function stops if texts is NULL or empty
  expect_error(check_texts_and_ids(NULL, c("id1", "id2")), "The texts cannot be NULL or empty.")
  expect_error(check_texts_and_ids(character(0), c("id1", "id2")), "The texts cannot be NULL or empty.")

  # Check that the function warns if doc_ids is NULL, and generates a sequence
  expect_warning(res <- check_texts_and_ids(c("text1", "text2"), NULL), "doc_ids is NULL. Auto-assigning doc_ids.")
  expect_equal(res$doc_ids, 1:2)

  # Check that the function stops if the lengths of texts and doc_ids do not match
  expect_error(check_texts_and_ids(c("text1", "text2"), "id1"), "The lengths of texts and doc_ids do not match.")

  # Check that the function returns correct output if inputs are valid
  expect_silent(res <- check_texts_and_ids(c("text1", "text2"), c("id1", "id2")))
  expect_equal(res$texts, c("text1", "text2"))
  expect_equal(res$doc_ids, c("id1", "id2"))
})


# Test 14: check_flair_installed identifies whether flair is available

test_that("check_flair_installed identifies whether flair is available", {
  # Mocking that the module is available
  with_mock(
    `reticulate::py_module_available` = function(...) TRUE,
    expect_true(check_flair_installed())
  )

  # Mocking that the module is not available
  with_mock(
    `reticulate::py_module_available` = function(...) FALSE,
    expect_false(check_flair_installed())
  )
})

