test_that("get_pos throws an error for unsupported languages", {
  expect_equal(nrow(get_pos(
    texts = c("UCD is one of the best university in Ireland. ",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids= c("doc1", "doc2", "doc3"),
    language  = "upos-fast")),
    25)
})


test_that("get_pos throws an error for unsupported languages", {
  expect_equal(nrow(get_pos(
    texts = c("UCD is one of the best university in Ireland. ",
              "Essex is famous in social science research",
              "TCD is the oldest one in Ireland."),
    doc_ids= c("doc1", "doc2", "doc3"),
    load_tagger_pos())),
    25)
})
