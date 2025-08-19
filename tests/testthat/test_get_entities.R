test_that("get_entities works with standard NER model", {

  texts <- c(
    "John Smith works at Google in New York.",
    "The Eiffel Tower was built in 1889."
  )
  doc_ids <- c("doc1", "doc2")

  # 加載標準 NER 模型
  tagger_std <- load_tagger_ner('ner')

  # 基本功能測試
  results <- get_entities(
    texts = texts,
    doc_ids = doc_ids,
    tagger = tagger_std,
    batch_size = 2
  )

  # 測試返回值結構
  expect_true(is.data.frame(results))

  # 測試提取的實體
  expect_true(any(grepl("John Smith", results$entity)))
  expect_true(any(grepl("Google", results$entity)))
  expect_true(any(grepl("New York", results$entity)))

  expected_tags <- c("PER", "ORG", "LOC")
  expect_true(all(results$tag[results$tag != "O"] %in% expected_tags))
})

test_that("get_entities handles different parameters correctly", {

  text <- "John lives in Berlin."
  tagger_std <- load_tagger_ner('ner')

  result_with_text <- get_entities(
    texts = text,
    doc_ids = 1,
    tagger = tagger_std,
    show.text_id = TRUE
  )
  expect_true("text_id" %in% names(result_with_text))

  # 測試批次大小
  result_batch <- get_entities(
    texts = rep(text, 3),
    doc_ids = c(1, 2, 3),
    tagger = tagger_std,
    batch_size = 2
  )
  expect_true(nrow(result_batch) >= 2)

  result_with_ids <- get_entities(
    texts = text,
    doc_ids = "doc1",
    tagger = tagger_std
  )
  expect_equal(unique(result_with_ids$doc_id), "doc1")
})

test_that("get_entities error handling", {
  tagger_std <- load_tagger_ner('ner')

  expect_error(
    get_entities(texts = character(0), tagger = tagger_std),
    "texts cannot be NULL or empty."
  )

  # 測試 texts 和 doc_ids 長度不匹配
  expect_error(
    get_entities(
      texts = c("text1", "text2"),
      doc_ids = "doc1",
      tagger = tagger_std
    ),
    "The lengths of texts and doc_ids do not match."
  )

  expect_error(
    get_entities(
      texts = "text",
      tagger = tagger_std,
      batch_size = 0
    ),
    "Invalid batch size. It must be a positive integer."
  )
})
