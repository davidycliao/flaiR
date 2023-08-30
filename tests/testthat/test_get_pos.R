test_that("get_pos throws an error for unsupported languages", {
  expect_error(get_pos(
    texts = c("UCD is one of the best university in Ireland. ",
              "UCD is good and a bit less better than Trinity.",
              "Essex is famous in social science research",
              "Essex is not in Russell Group but it is not bad in politics",
              "TCD is the oldest one in Ireland.",
              "TCD in less better than Oxford"),
    doc_ids= c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6"),
    language  = "chinese"),
    "Unsupported language. Supported languages are: pos, pos-fast, upos, upos-fast, pos-multi, pos-multi-fast, ar-pos, de-pos, de-pos-tweets, da-pos, ml-pos, ml-upos, pt-pos-clinical, pos-ukrainian.")
})