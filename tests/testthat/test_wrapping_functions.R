# lair_models returns a module with expected attribute

test_that("flair_models returns a module with expected attribute", {
  flair_models_module <- flair_models()

  # Check if the module is not NULL
  expect_true(!is.null(flair_models_module))

  # Check if a specific attribute (e.g., 'TextClassifier') is available in the module
  expect_true("TextClassifier" %in% reticulate::py_list_attributes(flair_models_module))
})



# flair_data returns a module with Sentence attribute
test_that("flair_data returns a module with Sentence attribute", {
  flair_data_module <- flair_data()

  # Check if the module is not NULL
  expect_true(!is.null(flair_data_module))

  # Check if a specific attribute (i.e., 'Sentence') is available in the module
  expect_true("Sentence" %in% reticulate::py_list_attributes(flair_data_module))
})


# flair_models.TextClassifier retrieves Python TextClassifier class

test_that("flair_models.TextClassifier retrieves Python TextClassifier class", {

  # Note: You may specify a Python environment if required using use_python or use_condaenv.
  # reticulate::use_python("path_to_python", required = TRUE)

  # Call the function
  TextClassifier <- flair_models.TextClassifier()

  # Test: Check if TextClassifier is indeed a Python Class from the flair.models module
  expect_s3_class(TextClassifier, "python.builtin.type")
  expect_true("load" %in% py_list_attributes(TextClassifier))

  # Optionally: Check if the TextClassifier can load a model (ensuring it's functional)
  # Note: This might require internet access and additional time.
  # skip_on_cran()  # Consider skipping this in CRAN checks
  #
  classifier <- TextClassifier$load('sentiment')
  expect_s3_class(classifier, "python.builtin.object")
  expect_true("predict" %in% py_list_attributes(classifier))
})

# flair_models returns the expected Python module
test_that("flair_models returns the expected Python module", {

  # Ensure reticulate uses the correct Python installation
  # You might specify a particular Python environment to ensure consistency
  # use_python("path/to/python", required = TRUE)

  flair.models <- flair_models()

  # Check if it is a Python Module and if it contains the expected attribute (TextClassifier)
  expect_s3_class(flair.models, "python.builtin.module")
  expect_true("TextClassifier" %in% py_list_attributes(flair.models))
})


# flair_datasets returns the expected output
test_that("flair_datasets returns the expected output", {
  # Skip test if the "reticulate" library is not available
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Check that flair_datasets() returns the expected type of object
  result <- flair_datasets()
  expect_s3_class(result, "python.builtin.module")

  # Optional: Check that the returned module contains an expected attribute
  # expect_true("an_expected_attribute" %in% py_list_attributes(result))
})

# flair_data.sentence returns expected output
test_that("flair_data.sentence returns expected output", {
  # Skip test if the "reticulate" library is not available
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Expected use case
  result <- flair_data.sentence("This is a sample sentence.")
  expect_s3_class(result, "python.builtin.object")
  # Additional checks can be added based on expected attributes of the output

  # Check behavior with empty string
  result_empty <- flair_data.sentence("")
  expect_s3_class(result_empty, "python.builtin.object")

})

test_that("flair_data.sentence handles errors and unexpected input correctly", {
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Check that non-string input is handled appropriately
  expect_error(flair_data.sentence(123), "TypeError: 'float' object is not subscriptable")
  expect_error(flair_data.sentence(NULL), "TypeError: can only join an iterable")

  # Add more test cases for other types of unexpected input
})


#flair_nn.classifier_load returns expected output
test_that("flair_nn.classifier_load returns expected output", {
  # Skip test if the "reticulate" library is not available
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Expected use case
  result <- flair_nn.classifier_load("ner")
  expect_s3_class(result, "python.builtin.object")
  # Add additional checks based on expected attributes of the output

  # Add more test cases as needed
})

test_that("flair_nn.classifier_load handles errors and unexpected input correctly", {
  skip_if_not_installed("reticulate")
  library(reticulate)

  # Check that non-string input is handled appropriately
  expect_error(flair_nn.classifier_load(123), "FileNotFoundError.*No such file or directory")
  expect_error(flair_nn.classifier_load(NULL), "FileNotFoundError.*No such file or directory")
  # Check behavior with invalid model name
  expect_error(flair_nn.classifier_load("non_existent_model"), "FileNotFoundError.*No such file or directory")

  # Add more test cases for other types of unexpected input
})



# flair_embeddings imports the Python module correctly
test_that("flair_embeddings imports the Python module correctly", {

  # Skip test if reticulate or Python is not available
  skip_if_not_installed("flaiR")

  # Check that the module import does not throw an error
  expect_silent(mod <- flair_embeddings())

  # Check that the imported module is not NULL
  expect_true(!is.null(mod))

  # Optionally, check for a known attribute or function in the imported module
  # to make sure it is the expected module
  expect_true("FlairEmbeddings" %in% names(mod))
})



# flair_embeddings.FlairEmbeddings initializes embeddings correctly


test_that("flair_embeddings.FlairEmbeddings initializes embeddings correctly", {
  skip_if_not_installed("reticulate")

  # Check no error with valid input and check message
  expect_message(f_e <- flair_embeddings.FlairEmbeddings("news-forward"), "Initialized Flair forward embeddings")

  # Optionally, check type of returned object
  # Depending on the object you might expect a list, a reticulate python object, etc.
  expect_true(inherits(f_e, "python.builtin.object"))

  # Check that an error is thrown with invalid input
  # Check that an error containing certain text is thrown with invalid input
  expect_error(
    flair_embeddings.FlairEmbeddings("invalid_type"),
    "ValueError.*invalid_type",
    fixed = FALSE  # because we're using a regular expression
  )

  })


# flair_embeddings.TransformerWordEmbeddings returns an embedding

test_that("flair_embeddings.TransformerWordEmbeddings returns an embedding", {
  skip_if_not_installed("flaiR")

  embedding <- flair_embeddings.TransformerWordEmbeddings("bert-base-uncased")

  # Testing for expected class hierarchy
  expect_true("flair.embeddings.token.TransformerWordEmbeddings" %in% class(embedding))
})



# flair_embeddings.WordEmbeddings returns an embedding

test_that("flair_embeddings.WordEmbeddings returns an embedding", {
  skip_if_not_installed("flaiR")

  embedding <- flair_embeddings.WordEmbeddings("glove")

  # Testing for expected class hierarchy
  expect_true("flair.embeddings.WordEmbeddings" %in% class(embedding) ||
                "flair.embeddings.token.WordEmbeddings" %in% class(embedding))
})



# flair_embeddings.TransformerDocumentEmbeddings returns an embedding

test_that("flair_embeddings.TransformerDocumentEmbeddings returns an embedding", {
  skip_if_not_installed("flaiR")

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  embedding <- flair_embeddings.TransformerDocumentEmbeddings("bert-base-uncased")

  # Testing for expected class hierarchy
  expect_true("flair.embeddings.TransformerDocumentEmbeddings" %in% class(embedding) ||
                "flair.embeddings.document.TransformerDocumentEmbeddings" %in% class(embedding))
})


# flair_splitter.SegtokSentenceSplitter returns an object

test_that("flair_splitter.SegtokSentenceSplitter returns an object", {
  skip_if_not_installed("reticulate")
  skip_on_cran()  # Optional: skip this test on CRAN to avoid unnecessary failures

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  SegtokSentenceSplitter <- flair_splitter.SegtokSentenceSplitter()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(SegtokSentenceSplitter))
})


# flair_models.sequencetagger returns an object
test_that("flair_models.sequencetagger returns an object", {
  skip_if_not_installed("reticulate")
  skip_on_cran()  # Optional: skip this test on CRAN

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  SequenceTagger <- flair_models.sequencetagger()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(SequenceTagger))

  # Optionally: Additional tests to check if the imported object has expected attributes or methods
  # For example, if we expect SequenceTagger to have a method named "load", we might test:
  # expect_true("load" %in% names(reticulate::py_list_attributes(SequenceTagger)))
})


# flair_trainers returns an object
test_that("flair_trainers returns an object", {
  skip_if_not_installed("reticulate")
  skip_on_cran()  # Optional: skip this test on CRAN

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  trainers <- flair_trainers()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(trainers))

  # Optionally: Additional tests to check if the imported object has expected attributes or methods
  # For example, if we expect trainers to have a method named "ModelTrainer", we might test:
  # expect_true("ModelTrainer" %in% names(reticulate::py_list_attributes(trainers)))
})


# flair_embeddings returns an object
test_that("flair_embeddings returns an object", {
  skip_if_not_installed("reticulate")

  # Check if Python and the necessary Python module are available
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  embeddings_module <- flair_embeddings()

  # Testing for expected class
  expect_true("python.builtin.object" %in% class(embeddings_module))

  # Optionally: Additional tests to check if the imported object has expected attributes or methods
  # For example, if we expect embeddings_module to have a method named "FlairEmbeddings", we might test:
  expect_true("TransformerEmbeddings" %in% reticulate::py_list_attributes(embeddings_module))
})


# flair_embeddings.FlairEmbeddings gives messages and stops as expected
test_that("flair_embeddings.FlairEmbeddings gives messages and stops as expected", {
  # Skipping if necessary modules are not available
  skip_if_not_installed("reticulate")
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  # Testing if the function issues the expected message
  expect_message(flair_embeddings.FlairEmbeddings("news-forward"), "Initialized Flair forward embeddings")
  expect_message(flair_embeddings.FlairEmbeddings("news-backward"), "Initialized Flair backward embeddings")

  # Testing if the function issues an error with invalid input
  expect_error(flair_embeddings.FlairEmbeddings("invalid_type"),
               "ValueError.*invalid_type",
               fixed = FALSE  # because we're using a regular expression
  )
})


# flair_splitter.SegtokSentenceSplitter returns expected object
test_that("flair_splitter.SegtokSentenceSplitter returns expected object", {
  # Skip the test if the necessary modules are not available
  skip_if_not_installed("reticulate")
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  splitter <- flair_splitter.SegtokSentenceSplitter()

  # Test that the function returns a non-null object
  expect_true(!is.null(splitter))

  # Test that the returned object is of the expected class
  expect_true(inherits(splitter, "python.builtin.module"))
})



# flair_models.sequencetagger returns expected object
test_that("flair_models.sequencetagger returns expected object", {
  # Skip the test if the necessary modules are not available
  skip_if_not_installed("reticulate")
  skip_on_cran()
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  seq_tagger <- flair_models.sequencetagger()

  # Test that the function returns a non-null object
  expect_true(!is.null(seq_tagger))

  # Test that the returned object is of the expected class
  expect_true(inherits(seq_tagger, "python.builtin.type"))
})


# flair_trainers returns expected object
test_that("flair_trainers returns expected object", {
  # Skip the test if the necessary modules are not available
  skip_if_not_installed("reticulate")
  skip_on_cran()
  available <- requireNamespace("reticulate") && reticulate::py_module_available("flair")
  skip_if_not(available, "Python or the 'flair' module is not available")

  trainers <- flair_trainers()

  # Test that the function returns a non-null object
  expect_true(!is.null(trainers))

  # Test that the returned object is of the expected class
  expect_true(inherits(trainers, "python.builtin.module"))
})


