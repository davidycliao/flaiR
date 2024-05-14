# Test 1: get_pos_batch returns pos tags for three input texts using a custom tagger
test_that("get_pos_batch returns pos tags for three input texts using a custom tagger", {
  result <- get_pos_batch(
    texts = c("UCD is one of the best universities in Ireland.",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids = c("doc1", "doc2", "doc3"),
    tagger = load_tagger_pos(),
    language = "upos-fast",
    batch_size = 1
  )
  # Check that the number of rows in the result matches the number of tokens
  expect_equal(nrow(result), 25)
})

# Test 2: get_pos_batch returns pos tags for three input texts using a custom tagger
test_that("texts and doc_ids are 0 and get_pos_batch returns NA", {
  result <- get_pos_batch(
    texts = "",
    doc_ids = "",
    tagger = load_tagger_pos(),
    language = "upos-fast" ,
    batch_size = 1)
  # Check that the number of rows in the result matches the number of tokens
  expect_equal(nrow(result), 1)
})


# Test 2: test loading tagger in get_pos_batch works as expected

test_that("loading tagger works as expected", {
  # Assuming you have a valid tagger object for English
  valid_tagger <- load_tagger_pos("pos-fast")

  # Test 1: tagger is NULL and no language is specified
  expect_message(get_pos_batch("Hello Dublin", batch_size = 1, doc_ids = "doc1"), "Language is not specified. pos-fastin Flair is forceloaded. Please ensure that the internet connectivity is stable.", fixed = FALSE)

  # Test 2: tagger is NULL but a language is specified
  expect_equal(get_pos_batch(texts = "Hello Ireland", batch_size = 1, doc_ids = "doc1", language = "pos-fast")[1, "tag"]$tag, "UH")
  #
  # Test 3: a valid tagger object is passed
  expect_message(get_pos_batch("Hello Colchester",  batch_size = 1, doc_ids = "doc1", tagger = valid_tagger), "CPU is used.")
})
