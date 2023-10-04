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
      expect_message(create_flair_env(), expected_pattern, fixed = FALSE)
    }
  )
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
  expect_error(check_texts_and_ids(c("text1", "text2"), c("id1")), "The lengths of texts and doc_ids do not match.")

  # Check that the function returns correct output if inputs are valid
  expect_silent(res <- check_texts_and_ids(c("text1", "text2"), c("id1", "id2")))
  expect_equal(res$texts, c("text1", "text2"))
  expect_equal(res$doc_ids, c("id1", "id2"))
})


# test_that("clear_flair_cache handles no directory", {
#   local_temp_env()
#   expect_output(clear_flair_cache(), "Flair cache directory does not exist.")
# })
#
# test_that("clear_flair_cache handles empty directory", {
#   local_temp_env()
#   dir.create(file.path(path.expand("~"), ".flair"))
#   expect_output(clear_flair_cache(), "No files in flair cache directory.")
# })
#
# test_that("clear_flair_cache handles non-empty directory", {
#   local_temp_env()
#   flair_cache_dir <- file.path(path.expand("~"), ".flair")
#   dir.create(flair_cache_dir)
#   file.create(file.path(flair_cache_dir, "file1.txt"))
#   expect_output(clear_flair_cache(), "Files in flair cache directory:")
# })

#
# test_that("check_device functionality", {
#   skip_on_cran() # prevent this from running on CRAN
#
#   # Importing torch without activating Python might cause issues
#   # It is ideal to mock or skip real interaction with reticulate & pytorch
#
#   # Test 1: MPS on supported system
#   withr::local_envvar(c(SYSNAME = "Darwin", MACHINE = "arm64", RELEASE = "12.3"))
#   # Here we need to mock pytorch and device check - not implemented in this example
#   expect_message(check_device("mps"), "MPS is used on Mac M1/M2.")
#
#   # # Test 2: MPS on unsupported system version
#   # withr::local_envvar(c(SYSNAME = "Darwin", MACHINE = "arm64", RELEASE = "12.0"))
#   # # Same here - mock pytorch and device check
#   # expect_warning(check_device("mps"), "MPS requires macOS 12.3 or higher")
#   #
#   # Test 3: CPU usage
#   expect_message(check_device("cpu"), "CPU is used.")
#   #
#   # # Test 4: CUDA available
#   # # Mock pytorch$cuda$is_available to return TRUE, and assert message
#   # # expect_message(check_device("cuda"), "CUDA is available and will be used.")
#   #
#   # Test 5: CUDA not available
#   # Mock pytorch$cuda$is_available to return FALSE, and assert message
#   expect_message(check_device("cuda"), "CUDA is not available on this machine. Using CPU.")
#   #
#   # # Test 6: Unknown device
#   # expect_warning(check_device("unknown_device"), "Unknown device specified.")
# })
#

#
