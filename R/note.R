

#' @title .onAttach Function for the flaiR Package
#'
#' @description The provided R code describes the `.onAttach` function for the `flaiR` package.
#' This function is automatically invoked when the `flaiR` package is loaded. Its primary purpose
#' is to set up and check the environment for the package and to display startup messages.
#' .onAttach is triggered when the flaiR package gets loaded. It produces
#' messages indicating the versions of Python and Flair in use and provides o
#' ther details related to the package.
#' @details
#' \itemize{
#'   \item **Specifying Python Path:** The function starts by looking for the path of Python 3.
#'   If it doesn't find it, it stops the package load with an error message.
#'   \item **Checking Python Version:** Next, the function checks whether the identified version
#'   of Python is Python 3. If it's not, it emits a warning.
#'   \item **Checking PyTorch Version:** The function then checks if PyTorch is correctly installed
#'   and fetches its version information.
#'   \item **Checking Flair Version:** It also checks if Flair is correctly installed and fetches
#'   its version.
#'   \item **Installation Status of Flair:** If Flair isn't installed, the function attempts to install
#'   PyTorch and Flair automatically using pip commands. If the installation fails, it produces an error message.
#'   \item **Success Message:** If all the checks pass, a message is displayed indicating that Flair can
#'   be successfully imported in R via `flaiR`.
#'   \item **Specifying Python Version for Use:** Lastly, the function specifies which version of Python
#'   to use within R using the `reticulate` package.
#' }
#' @keywords internal
#' @export
# .onAttach <- function(...) {
#   # Check operating system, mac by default
#   os_name <- Sys.info()["sysname"]
#
#   # Depending on OS, determine Python command
#   if (os_name == "Windows") {
#     python_cmd <- "python"
#     python_path <- normalizePath(Sys.which(python_cmd), winslash = "/", mustWork = TRUE)
#     return(python_path)
#   } else {
#     # For Linux and macOS
#     python_cmd <- "python3"
#     python_path <- Sys.which(python_cmd)
#   }
#
#   # If Python path is empty, raise an error
#   if (python_path == "") {
#     stop(paste("Cannot locate the", python_cmd, "path. Ensure it's installed and in your system's path."))
#   }
#
#   # Try to get Python version and handle any errors
#   tryCatch({
#     python_version <- system(paste(python_path, "--version"), intern = TRUE)
#   }, error = function(e) {
#     stop(paste("Failed to get Python version with path:", python_path, "Error:", e$message))
#   })
#
#   # Check if Python version is 2 or 3
#   if (!grepl("Python 3", python_version)) {
#     warning("You seem to be using Python 2. This package may require Python 3. Consider installing or using Python 3.")
#   }
#
#   # Check if PyTorch is genuinely installed and its version
#   check_torch_version <- function() {
#     torch_version_command <- paste(python_path, "-c 'import torch; print(torch.__version__)'")
#     result <- system(torch_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("PyTorch", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     return(list(paste("PyTorch", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
#   }
#
#   # Check if flair is genuinely installed and its version
#   check_flair_version <- function() {
#     flair_version_command <- paste(python_path, "-c 'import flair; print(flair.__version__)'")
#     result <- system(flair_version_command, intern = TRUE)
#     if (length(result) == 0 || result[1] == "ERROR" || is.na(result[1])) {
#       return(list(paste("flair", paste0("\033[31m", "\u2717", "\033[39m"), sep = " "), FALSE))
#     }
#     # Return flair version
#     # return(list(paste("Flair NLP", paste0("\033[32m", "\u2713", "\033[39m") ,result[1], sep = " "), TRUE))
#     return(list(result[1], TRUE))
#   }
#
#   flair_version <- suppressWarnings(check_flair_version())
#   torch_version <- suppressWarnings(check_torch_version())
#
#   if (isFALSE(flair_version[[2]])) {
#     packageStartupMessage(sprintf(" Flair NLP %-50s", paste0("is installing from Python")))
#     commands <- c(
#       paste(python_path, "-m pip install --upgrade pip"),
#       # paste(python_path, "-m pip install aiohttp --no-binary aiohttp"),
#       paste(python_path, "-m pip install torch torchvision torchaudio"),
#       paste(python_path, "-m pip install flair")
#     )
#
#     vapply(commands, system, FUN.VALUE = integer(1))
#
#     re_installation <- suppressWarnings(check_flair_version())
#     if (isFALSE(re_installation[[2]])) {
#       packageStartupMessage("Failed to install Flair. {flaiR} requires Flair NLP. Please ensure Flair NLP is installed in Python manually.")
#     }
#   } else {
#     packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", paste("\033[1m\033[33m", flair_version[1],"\033[39m\033[22m", sep = "")))
#     # packageStartupMessage(paste(flair_version[[1]], torch_version[[1]], sep = " | "))
#     # packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
#     Sys.setenv(RETICULATE_PYTHON = Sys.which("python3"))
#     }
# }

# .onAttach <- function(...) {
#   packageStartupMessage(sprintf(" flai\033[34mR\033[39m: An R Wrapper for Accessing Flair NLP Tagging Features %-5s", ""))
#
#   # Check and report Python is installed
#   if (check_python_installed()) {
#     packageStartupMessage(sprintf(" Python: %-47s", reticulate::py_config()$version))
#   } else {
#     packageStartupMessage(sprintf(" Python: %-50s", paste0("\033[31m", "\u2717", "\033[39m")))
#   }
#
#   # Check and report  flair is installed
#   if (reticulate::py_module_available("flair")) {
#     packageStartupMessage(sprintf(" Flair: %-47s",  get_flair_version()))
#   } else {
#     packageStartupMessage(sprintf(" Flair: %-50s", paste0("\033[31m", "\u2717", "\033[39m")))
#     packageStartupMessage(sprintf(" Flair %-50s", paste0("is installing from Python")))
#     system(paste(reticulate::py_config()$python, "-m pip install flair==0.13"))
#   }
# }


# Current
# .onAttach <- function(...) {
#   packageStartupMessage(sprintf("\033[1m\033[34mflaiR\033[39m\033[22m: \033[1m\033[33mAn R Wrapper for Accessing Flair NLP\033[39m\033[22m %-5s", ""))
#   if (check_python_installed()) {
#     packageStartupMessage(sprintf("Python: %-47s", reticulate::py_config()$version))
#   } else {
#     stop("Python is not installed. This package requires Python to run Flair.")
#   }
#   if (!reticulate::py_module_available("flair")) {
#     packageStartupMessage("Attempting to install Flair in Python...")
#     system(paste(reticulate::py_config()$python, "-m pip3 install torch torchvision torchaudio"))
#     if (!reticulate::py_module_available("flair")) {
#       packageStartupMessage("Failed to install Flair. This package requires Flair. Please ensure Flair is installed in Python manually.")
#     } else {
#       packageStartupMessage(sprintf("Flair: %-47s", get_flair_version()))
#     }
#   } else {
#     packageStartupMessage(sprintf("Flair: %-47s", get_flair_version()))
#     packageStartupMessage("Flair NLP can be successfully imported in R via {flaiR} ! \U1F44F")
#   }
# }



#' #' @title Load the Named Entity Recognition (NER) Tagger
#' #'
#' #' @description A helper function to load the appropriate tagger based on the provided language.
#' #' This function supports a variety of languages/models.
#' #'
#' #' @param language A character string indicating the desired language for the NER tagger.
#' #' If `NULL`, the function will default to the 'pos-fast' model.
#' #' Supported languages and their models include:
#' #' \itemize{
#' #'   \item `"en"` - English NER tagging (`ner`)
#' #'   \item `"de"` - German NER tagging (`de-ner`)
#' #'   \item `"fr"` - French NER tagging (`fr-ner`)
#' #'   \item `"nl"` - Dutch NER tagging (`nl-ner`)
#' #'   \item `"da"` - Danish NER tagging (`da-ner`)
#' #'   \item `"ar"` - Arabic NER tagging (`ar-ner`)
#' #'   \item `"ner-fast"` - English NER fast model (`ner-fast`)
#' #'   \item `"ner-large"` - English NER large mode (`ner-large`)
#' #'   \item `"de-ner-legal"` - NER (legal text) (`de-ner-legal`)
#' #'   \item `"nl"` - Dutch NER tagging (`nl-ner`)
#' #'   \item `"da"` - Danish NER tagging (`da-ner`)
#' #'   \item `"ar"` - Arabic NER tagging (`ar-ner`)
#' #'}
#' #'
#' #' @return An instance of the Flair SequenceTagger for the specified language.
#' #'
#' #' @import reticulate
#' #' @importFrom stats setNames
#' #'
#' #' @examples
#' #' # Load the English NER tagger
#' #' tagger_en <- load_tagger_ner("en")
#' #'
#' #' @export
#' load_tagger_ner <- function(language = NULL) {
#'   supported_lan_models <- c("ner", "de-ner",
#'                             "fr-ner", "nl-ner",
#'                             "da-ner", "ar-ner",
#'                             "ner-fast", "ner-large",
#'                             "ner-pooled",  "ner-ontonotes",
#'                             "ner-ontonotes-fast", "ner-ontonotes-large",
#'                             "de-ner-large", "de-ner-germeval",
#'                             "de-ner-legal", "es-ner",
#'                             "nl-ner", "nl-ner-large",
#'                             "nl-ner-rnn", "ner-ukrainian")
#'   language_model_map <- setNames(supported_lan_models, c("en", "de",
#'                                                          "fr", "nl",
#'                                                          "da", "ar",
#'                                                          "ner-fast", "ner-large",
#'                                                          "ner-pooled", "ner-ontonotes",
#'                                                          "ner-ontonotes-fast", "ner-ontonotes-large",
#'                                                          "de-ner-large", "de-ner-germeval",
#'                                                          "de-ner-legal", "es-ner-large",
#'                                                          "nl-ner", "nl-ner-large",
#'                                                          "nl-ner-rnn", "ner-ukrainian")
#'   )
#'
#'   if (is.null(language)) {
#'     language <- "en"
#'     message("Language is not specified. ", language, " in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
#'   }
#'
#'   # Translate language to model name if necessary
#'   if (language %in% names(language_model_map)) {
#'     language <- language_model_map[[language]]
#'   }
#'
#'   # Ensure the model is supported
#'   check_language_supported(language = language, supported_lan_models = supported_lan_models)
#'
#'   # Load the model
#'   SequenceTagger <- reticulate::import("flair.models")$SequenceTagger
#'   SequenceTagger$load(language)
#' }
#'
#'
#'



#' #' @title Tagging Named Entities with Flair Models
#' #'
#' #' @description This function takes texts and their corresponding document IDs
#' #' as inputs, uses the Flair NLP library to extract named entities,
#' #' and returns a dataframe of the identified entities along with their tags.
#' #' When no entities are detected in a text, the function returns a data table
#' #' with NA values. This might clutter the results. Depending on your use case,
#' #' you might decide to either keep this behavior or skip rows with no detected
#' #' entities.
#' #'
#' #' @param texts A character vector containing the texts to process.
#' #' @param doc_ids A character or numeric vector containing the document IDs
#' #' corresponding to each text.
#' #' @param tagger An optional tagger object. If NULL (default), the function will
#' #'  load a Flair tagger based on the specified language.
#' #' @param language A character string indicating the language model to load.
#' #' Default is "en".
#' #' @param show.text_id A logical value. If TRUE, includes the actual text from
#' #' which the entity was extracted in the resulting data table. Useful for
#' #' verification and traceability purposes but might increase the size of
#' #' the output. Default is FALSE.
#' #' @param gc.active A logical value. If TRUE, runs the garbage collector after
#' #' processing all texts. This can help in freeing up memory by releasing unused
#' #' memory space, especially when processing a large number of texts.
#' #' Default is FALSE.
#' #' @return A data table with columns:
#' #' \describe{
#' #'   \item{doc_id}{The ID of the document from which the entity was extracted.}
#' #'   \item{text_id}{If TRUE, the actual text from which the entity
#' #'   was extracted.}
#' #'   \item{entity}{The named entity that was extracted from the text.}
#' #'   \item{tag}{The tag or category of the named entity. Common tags include:
#' #'   PERSON (names of individuals),
#' #'   ORG (organizations, institutions),
#' #'   GPE (countries, cities, states),
#' #'   LOCATION (mountain ranges, bodies of water),
#' #'   DATE (dates or periods),
#' #'   TIME (times of day),
#' #'   MONEY (monetary values),
#' #'   PERCENT (percentage values),
#' #'   FACILITY (buildings, airports),
#' #'   PRODUCT (objects, vehicles),
#' #'   EVENT (named events like wars or sports events),
#' #'   ART (titles of books)}}
#' #' @examples
#' #' \dontrun{
#' #' library(reticulate)
#' #' library(fliaR)
#' #'
#' #' texts <- c("UCD is one of the best universities in Ireland.",
#' #'            "UCD has a good campus but is very far from
#' #'            my apartment in Dublin.",
#' #'            "Essex is famous for social science research.",
#' #'            "Essex is not in the Russell Group, but it is
#' #'            famous for political science research.",
#' #'            "TCD is the oldest university in Ireland.",
#' #'            "TCD is similar to Oxford.")
#' #' doc_ids <- c("doc1", "doc2", "doc3", "doc4", "doc5", "doc6")
#' #' # Load NER ("ner") model
#' #' tagger_ner <- load_tagger_ner('ner')
#' #' results <- get_entities(texts, doc_ids, tagger_ner)
#' #' print(results)}
#' #'
#' #' @importFrom data.table data.table rbindlist
#' #' @importFrom reticulate import
#' #' @importFrom data.table :=
#' #' @export
# get_entities <- function(texts, doc_ids = NULL, tagger = NULL, language = NULL,
#                          show.text_id = FALSE, gc.active = FALSE) {
#
#   # Check environment pre-requisites
#   check_prerequisites()
#   check_show.text_id(show.text_id)
#
#   # Check and prepare texts and doc_ids
#   texts_and_ids <- check_texts_and_ids(texts, doc_ids)
#   texts <- texts_and_ids$texts
#   doc_ids <- texts_and_ids$doc_ids
#
#   # Load tagger if null
#   if (is.null(tagger)) {
#     tagger <- load_tagger_ner(language)
#   }
#
#   Sentence <- reticulate::import("flair")$data$Sentence
#
#   # Process each text and extract entities
#   process_text <- function(text, doc_id) {
#     text_id <- NULL
#     if (is.na(text) || is.na(doc_id)) {
#       return(data.table(doc_id = NA, entity = NA, tag = NA))
#     }
#
#     sentence <- Sentence(text)
#     tagger$predict(sentence)
#     entities <- sentence$get_spans("ner")
#
#     if (length(entities) == 0) {
#       return(data.table(doc_id = doc_id, entity = NA, tag = NA))
#     }
#
#     # Unified data table creation process
#     dt <- data.table(
#       doc_id = rep(doc_id, length(entities)),
#       entity = vapply(entities, function(e) e$text, character(1)),
#       tag = vapply(entities, function(e) e$tag, character(1))
#     )
#
#     if (isTRUE(show.text_id)) {
#       dt[, text_id := text]
#     }
#
#     return(dt)
#   }
#   # Activate garbage collection
#   check_and_gc(gc.active)
#
#   results_list <- lapply(seq_along(texts),
#                          function(i) {process_text(texts[[i]], doc_ids[[i]])})
#   rbindlist(results_list, fill = TRUE)
# }



#' @title Load NER Tagger Model
#'
#' @description Loads a Named Entity Recognition (NER) model from Flair.
#' Verifies that the loaded model is a valid NER model.
#'
#' @param model_name Character string specifying the model name to load.
#' Default is "ner" (English NER model).
#'
#' @return A Flair SequenceTagger model object for NER.
#' @examples
#' \dontrun{
#' # Load default English NER model
#' tagger <- load_tagger_ner()
#'
#' # Load specific model
#' tagger <- load_tagger_ner("ner-fast")
#' }
#' @export
# load_tagger_ner <- function(model_name = "ner") {
#   if (is.null(model_name)) {
#     model_name <- "ner"
#     message("Model name is not specified. Using default 'ner' model.")
#   }
#
#   # Load the model
#   tryCatch({
#     SequenceTagger <- flair_models()$SequenceTagger
#     tagger <- SequenceTagger$load("flair/ner-english-large")
#
#     # Verify the model is for NER
#     # Check if the model has NER-related tags
#     tags <- tagger$labels
#     if (!any(grepl("PER|ORG|LOC|GPE|MISC", tags))) {
#       warning("The loaded model may not be a proper NER model. ",
#               "Please ensure it's designed for Named Entity Recognition.")
#     }
#
#     return(tagger)
#   }, error = function(e) {
#     stop("Error loading model: ", model_name, "\n", e$message)
#   })
# }
#'
#' #' @title Load and Configure NER Tagger
#' #'
#' #' @description Loads a Named Entity Recognition model from Flair and displays
#' #' its tag dictionary.
#' #'
#' #' @param model_name Character string specifying the model to load.
#' #' Default is "ner".
#' #' @param show_tags Logical, whether to display the tag dictionary.
#' #' Default is TRUE.
#' #'
#' #' @return A Flair SequenceTagger model object
#' #' @export
#' load_tagger_ner <- function(model_name = "ner", show_tags = TRUE) {
#'   if (is.null(model_name)) {
#'     model_name <- "ner"
#'     message("Model name is not specified. Using default 'ner' model.")
#'   }
#'
#'   # Load the model
#'   tryCatch({
#'     SequenceTagger <- flair_models()$SequenceTagger
#'     tagger <- SequenceTagger$load("flair/ner-english-large")
#'
#'     # Extract and organize tags if requested
#'     if (show_tags) {
#'       tag_dict <- tagger$label_dictionary
#'       tag_list <- tag_dict$get_items()
#'
#'       cat("\nNER Tagger Dictionary:\n")
#'       cat("========================================\n")
#'       cat(sprintf("Total tags: %d\n", length(tag_list)))
#'       cat("----------------------------------------\n")
#'       # Group and print tags by type
#'       special_tags <- grep("^<.*>$|^O$", tag_list, value = TRUE)
#'       person_tags <- grep("PER", tag_list, value = TRUE)
#'       org_tags <- grep("ORG", tag_list, value = TRUE)
#'       loc_tags <- grep("LOC", tag_list, value = TRUE)
#'       misc_tags <- grep("MISC", tag_list, value = TRUE)
#'
#'       if (length(special_tags) > 0) cat("Special:", paste(special_tags, collapse = ", "), "\n")
#'       if (length(person_tags) > 0) cat("Person:", paste(person_tags, collapse = ", "), "\n")
#'       if (length(org_tags) > 0) cat("Organization:", paste(org_tags, collapse = ", "), "\n")
#'       if (length(loc_tags) > 0) cat("Location:", paste(loc_tags, collapse = ", "), "\n")
#'       if (length(misc_tags) > 0) cat("Miscellaneous:", paste(misc_tags, collapse = ", "), "\n")
#'
#'       cat("----------------------------------------\n")
#'       cat("Tag scheme: BIOES\n")
#'       cat("B-: Beginning of entity\n")
#'       cat("I-: Inside of entity\n")
#'       cat("O: Outside (not an entity)\n")
#'       cat("E-: End of entity\n")
#'       cat("S-: Single token entity\n")
#'       cat("========================================\n")
#'     }
#'
#'     return(tagger)
#'   }, error = function(e) {
#'     stop("Error loading model: ", model_name, "\n", e$message)
#'   })
#' }
#'
#'

#'
#'
#' #' @title Load a Sentiment or Language Tagger Model from Flair
#' #'
#' #' @description This function loads a pre-trained sentiment or language tagger
#' #' from the Flair library.
#' #'
#' #' @param language A character string specifying the language model to load.
#' #' Supported models include:
#' #' \itemize{
#' #'   \item "sentiment" - Sentiment analysis model
#' #'   \item "sentiment-fast" - Faster sentiment analysis model
#' #'   \item "de-offensive-language" - German offensive language detection model
#' #'} If not provided, the function will default to the "sentiment" model.
#' #'
#' #' @return An object of the loaded Flair model.
#' #'
#' #' @import reticulate
#' #' @examples
#' #' \dontrun{
#' #'   tagger <- load_tagger_sentiments("sentiment")
#' #' }
#' #'
#' #' @export
#' load_tagger_sentiments <- function(language = NULL) {
#'   supported_lan_models <- c("sentiment", "sentiment-fast", "de-offensive-language")
#'
#'   if (is.null(language)) {
#'     language <- "sentiment"
#'     message("Language is not specified. ", language, " in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
#'   }
#'
#'   # Ensure the model is supported
#'   check_language_supported(language = language, supported_lan_models = supported_lan_models)
#'
#'   # Load the model
#'   flair <- reticulate::import("flair")
#'   Classifier <- flair$nn$Classifier
#'   tagger <- Classifier$load(language)
#'   return(tagger)
#' }

