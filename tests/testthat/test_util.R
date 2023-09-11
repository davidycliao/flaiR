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



# Test 12: Test create_flair_env works in virtual environment

test_that("create_flair_env works correctly", {

  # Scenario 1: Flair is already installed
  with_mock(
    `reticulate::py_module_available` = function(x) TRUE,
    `reticulate::py_config` = function() list(python = "python_path"),
    `reticulate::import` = function(x) list(`__version__` = "flair_version"),

    {
      expect_message(flaiR::create_flair_env(), "Flair is already installed in python_path")
      expect_message(flaiR::create_flair_env(), "Using Flair:  flair_version")
    }
  )


  # Scenario 2: No Conda environment exists
  with_mock(
    `reticulate::py_module_available` = function(x) FALSE,
    `reticulate::conda_list` = function(conda = NULL) {
      data.frame(python = "python_path")
    },
    `reticulate::conda_create` = function(envname, python_version = NULL, ...) {
      # Simulate creating the conda environment by doing nothing
      NULL
    },
    `reticulate::use_condaenv` = function(envname, required = TRUE) {
      if (envname != "r-reticulate") {
        stop(sprintf("Unable to locate conda environment '%s'.", envname), call. = FALSE)
      }
      # Simulate using the conda environment by doing nothing
      NULL
    },
    `rstudioapi::restartSession` = function() NULL,

    {
      expected_pattern <- "No conda environment found\\. Creating a new environment named '.*'\\. After restarting the R session, please run create_flair_env\\(\\) again\\."
      expect_message(flaiR::create_flair_env(), expected_pattern, fixed = FALSE)
    }
  )

  # Scenario 3: No Conda environment exists
  with_mock(
    `reticulate::py_module_available` = function(x) FALSE,
    `reticulate::conda_list` = function() data.frame(python = "python_path"),
    `reticulate::conda_create` = function(env) NULL,
    `rstudioapi::restartSession` = function() NULL,

    {
      expected_pattern <- "No conda environment found\\. Creating a new environment named '.*'\\. After restarting the R session, please run create_flair_env\\(\\) again\\."
      expect_message(flaiR::create_flair_env(), expected_pattern, fixed = FALSE)
    }
  )
})
