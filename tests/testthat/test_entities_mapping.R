# map_entities returns correct mapping

test_that("map_entities returns correct mapping", {
  # Creating a sample data frame
  sample_df <- data.frame(entity = c("Paris", "OpenAI", "John Doe", "Unknown"),
                          tag = c("LOC", "ORG", "PER", "MISC"),
                          stringsAsFactors = FALSE)

  # Running map_entities to get the entities mapping
  entities_mapping <- map_entities(sample_df)

  # Checking that the mapping contains correct words for each tag
  expect_equal(entities_mapping$ORG$words, "OpenAI")
  expect_equal(entities_mapping$LOC$words, "Paris")
  expect_equal(entities_mapping$PER$words, "John Doe")
  expect_equal(entities_mapping$MISC$words, "Unknown")

  # Checking that the mapping contains correct background color for each tag
  expect_equal(entities_mapping$ORG$background_color, "pink")
  expect_equal(entities_mapping$LOC$background_color, "lightblue")
  expect_equal(entities_mapping$PER$background_color, "lightgreen")
  expect_equal(entities_mapping$MISC$background_color, "yellow")
})

test_that("map_entities handles errors correctly", {
  # Creating a sample data frame without necessary columns
  incorrect_df <- data.frame(entity = c("Paris", "OpenAI", "John Doe", "Unknown"),
                             stringsAsFactors = FALSE)

  # Expecting an error when running map_entities with incorrect input
  expect_error(map_entities(incorrect_df), "The specified entity or tag column names are not found in the data frame.")
})
