# Ensure highlight_text is correctly structured
test_that("highlight_text handles entities_mapping input correctly", {
  correct_structure <- list(
    list(
      words = "example",
      background_color = "blue",
      font_color = "white",
      label = "example label",
      label_color = "black"
    )
  )

  expect_silent(highlight_text("Some text", correct_structure))

  incorrect_structure <- list(
    list(
      words = c("example"),
      font_color = "white",
      label = "example label",
      label_color = "black"
    )
  )

  expect_error(highlight_text("Some text", incorrect_structure), "'entities_mapping' must be a list with specific structure.")
})

# Ensure font_family is a single character string
test_that("highlight_text handles font_family input correctly", {
  entities_mapping <- list(
    list(
      words = c("example"),
      background_color = "blue",
      font_color = "white",
      label = "example label",
      label_color = "black"
    )
  )

  expect_silent(highlight_text("Some text", entities_mapping, font_family = "Arial"))
  expect_error(highlight_text("Some text", entities_mapping, font_family = c("Arial", "Verdana")), "'font_family' must be a single character string.")
  expect_error(highlight_text("Some text", entities_mapping, font_family = 123), "'font_family' must be a single character string.")
})

# `highlight_text` correctly highlights and justifies text
test_that("highlight_text correctly highlights and justifies text", {
  # Creating a sample entity mapping
  entities_mapping <- list(
    ORG = list(words = c("Apple", "Google"),
               background_color = "yellow",
               font_color = "black",
               label = "ORG",
               label_color = "blue")
  )

  # Text to test
  test_text <- "Apple and Google are tech giants."

  # Running the function to get the output
  highlighted_text <- highlight_text(test_text, entities_mapping)

  # Convert HTML to character to perform checks
  highlighted_text_as_char <- as.character(highlighted_text)

  # Check 1: Test if the function adds the correct span tags around the specified words
  expect_true(grepl('<span style="background-color: yellow; color: black; font-family: Arial">Apple</span>', highlighted_text_as_char))
  expect_true(grepl('<span style="background-color: yellow; color: black; font-family: Arial">Google</span>', highlighted_text_as_char))

  # Check 2: Test if label and label colors are applied correctly
  expect_true(grepl('<span style="color: blue; font-family: Arial">\\(ORG\\)</span>', highlighted_text_as_char))

  # Check 3: Ensure that the returned text is justified and uses the correct font family
  expect_true(grepl('<div style="text-align: justify; font-family: Arial">', highlighted_text_as_char))

  # Check 4: Ensure that the input text and entity mapping do not change
  expect_equal(test_text, "Apple and Google are tech giants.")
  expect_equal(entities_mapping$ORG$words, c("Apple", "Google"))
})

