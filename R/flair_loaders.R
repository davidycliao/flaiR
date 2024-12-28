#' @title Load and Configure NER Tagger
#'
#' @description Loads a Named Entity Recognition model from Flair and displays
#' its tag dictionary. Supports both standard NER and OntoNotes models.
#'
#' @param model_name Character string specifying the model to load.
#' Can be "ner" (default), "flair/ner-english-large", or "flair/ner-english-ontonotes"
#' @param show_tags Logical, whether to display the tag dictionary.
#' Default is TRUE.
#'
#' @return A Flair SequenceTagger model object
#' @export
load_tagger_ner <- function(model_name = "ner", show_tags = TRUE) {
  if (is.null(model_name)) {
    model_name <- "ner"
    message("Model name is not specified. Using default 'ner' model.")
  }

  # Load the model
  tryCatch({
    SequenceTagger <- flair_models()$SequenceTagger
    tagger <- SequenceTagger$load(model_name)

    # Extract and organize tags if requested
    if (show_tags) {
      tag_dict <- tagger$label_dictionary
      tag_list <- tag_dict$get_items()

      # Function to extract specific entity types
      get_entity_tags <- function(pattern, tags) {
        grep(pattern, tags, value = TRUE)
      }

      # Group tags by category (supporting both standard and OntoNotes)
      categories <- list(
        special = get_entity_tags("^<.*>$|^O$", tag_list),
        person = get_entity_tags("PERSON", tag_list),
        organization = get_entity_tags("ORG", tag_list),
        location = get_entity_tags("LOC|GPE", tag_list),
        time = get_entity_tags("TIME|DATE", tag_list),
        numbers = get_entity_tags("CARDINAL|ORDINAL|PERCENT|MONEY", tag_list),
        groups = get_entity_tags("NORP", tag_list),  # Nationalities, religious or political groups
        facilities = get_entity_tags("FAC", tag_list),  # Buildings, airports, highways, bridges
        products = get_entity_tags("PRODUCT", tag_list),
        events = get_entity_tags("EVENT", tag_list),
        art = get_entity_tags("WORK_OF_ART", tag_list),
        languages = get_entity_tags("LANGUAGE", tag_list),
        laws = get_entity_tags("LAW", tag_list),
        misc = get_entity_tags("MISC", tag_list)
      )

      # Print organized output
      cat("\nNER Tagger Dictionary:\n")
      cat("========================================\n")
      cat(sprintf("Total tags: %d\n", length(tag_list)))
      cat(sprintf("Model: %s\n", model_name))
      cat("----------------------------------------\n")

      # Print categories with tags
      for (cat_name in names(categories)) {
        tags <- categories[[cat_name]]
        if (length(tags) > 0) {
          # Format category name
          formatted_name <- gsub("_", " ", tools::toTitleCase(cat_name))
          cat(sprintf("%-15s: %s\n",
                      formatted_name,
                      paste(tags, collapse = ", ")))
        }
      }

      cat("----------------------------------------\n")
      cat("Tag scheme: BIOES\n")
      cat("B-: Beginning of multi-token entity\n")
      cat("I-: Inside of multi-token entity\n")
      cat("O: Outside (not part of any entity)\n")
      cat("E-: End of multi-token entity\n")
      cat("S-: Single token entity\n")
      cat("========================================\n")
    }

    return(tagger)

  }, error = function(e) {
    stop(sprintf(
      "Error loading model: %s\nPlease check:\n - Model name is correct\n - Internet connection is stable\n - You have sufficient permissions\nError: %s",
      model_name, e$message
    ))
  })
}


#' @title Extract Model Tags
#'
#' @description Helper function to extract and categorize tags from a loaded Flair
#' SequenceTagger model. The tags are grouped into categories such as person,
#' organization, location, and miscellaneous.
#'
#' @param tagger A loaded Flair SequenceTagger model
#'
#' @return A list of tags grouped by category:
#' \describe{
#'   \item{all}{Complete list of all available tags}
#'   \item{special}{Special tags like <unk>, O, <START>, <STOP>}
#'   \item{person}{Person-related tags (e.g., B-PER, I-PER)}
#'   \item{organization}{Organization tags (e.g., B-ORG, E-ORG)}
#'   \item{location}{Location tags (e.g., B-LOC, S-LOC)}
#'   \item{misc}{Miscellaneous entity tags}
#' }
#'
#' @details
#' The tags follow the BIOES (Begin, Inside, Outside, End, Single) scheme:
#' \itemize{
#'   \item{B-: Beginning of multi-token entity (e.g., B-PER in "John Smith")}
#'   \item{I-: Inside of multi-token entity (e.g., I-PER in "John Smith")}
#'   \item{O: Outside of any entity}
#'   \item{E-: End of multi-token entity}
#'   \item{S-: Single token entity (e.g., S-LOC in "Paris")}
#' }
#'
#' @examples
#' \dontrun{
#' # Load a NER model
#' tagger <- load_tagger_ner("flair/ner-english-large")
#'
#' # Extract all tags
#' tags <- get_tagger_tags(tagger)
#'
#' # Access specific tag categories
#' print(tags$person)      # All person-related tags
#' print(tags$location)    # All location-related tags
#'
#' # Example usage with text annotation
#' # B-PER I-PER    O    S-ORG
#' # "John Smith works at Google"
#'
#' # B-LOC  E-LOC   O   B-ORG    E-ORG
#' # "New   York    is  United   Nations headquarters"
#'
#' # Use tags to filter entities
#' person_entities <- results[tag %in% tags$person]
#' org_entities <- results[tag %in% tags$organization]
#' }
#'
#' @seealso
#' \code{\link{load_tagger_ner}} for loading the NER model
#'
#' @export
get_tagger_tags <- function(tagger) {
  tag_dict <- tagger$label_dictionary
  tag_list <- tag_dict$get_items()

  list(
    all = tag_list,
    special = grep("^<.*>$|^O$", tag_list, value = TRUE),
    person = grep("PER", tag_list, value = TRUE),
    organization = grep("ORG", tag_list, value = TRUE),
    location = grep("LOC", tag_list, value = TRUE),
    misc = grep("MISC", tag_list, value = TRUE)
  )
}


#' @title Load Flair POS Tagger
#'
#' @description This function loads the POS (part-of-speech) tagger model for a specified language
#' using the Flair library. If no language is specified, it defaults to 'pos-fast'.
#'
#' @param language A character string indicating the desired language model. If `NULL`,
#' the function will default to the 'pos-fast' model. Supported language models include:
#' \itemize{
#'   \item "pos" - General POS tagging
#'   \item "pos-fast" - Faster POS tagging
#'   \item "upos" - Universal POS tagging
#'   \item "upos-fast" - Faster Universal POS tagging
#'   \item "pos-multi" - Multi-language POS tagging
#'   \item "pos-multi-fast" - Faster Multi-language POS tagging
#'   \item "ar-pos" - Arabic POS tagging
#'   \item "de-pos" - German POS tagging
#'   \item "de-pos-tweets" - German POS tagging for tweets
#'   \item "da-pos" - Danish POS tagging
#'   \item "ml-pos" - Malayalam POS tagging
#'   \item "ml-upos" - Malayalam Universal POS tagging
#'   \item "pt-pos-clinical" - Clinical Portuguese POS tagging
#'   \item "pos-ukrainian" - Ukrainian POS tagging
#' }
#' @return A Flair POS tagger model corresponding to the specified (or default) language.
#'
#' @importFrom reticulate import
#' @export
#' @examples
#' \dontrun{
#' tagger <- load_tagger_pos("pos-fast")
#' }
# load_tagger_pos <- function(language = NULL) {
#   supported_lan_models <- c("pos", "pos-fast", "upos", "upos-fast",
#                             "pos-multi", "pos-multi-fast", "ar-pos", "de-pos",
#                             "de-pos-tweets", "da-pos", "ml-pos",
#                             "ml-upos", "pt-pos-clinical", "pos-ukrainian")
#
#   if (is.null(language)) {
#     language <- "pos-fast"
#     message("Language is not specified. ", language, "in Flair is forceloaded. Please ensure that the internet connectivity is stable. \n")
#   }
#
#   # Ensure the model is supported
#   check_language_supported(language = language, supported_lan_models = supported_lan_models)
#
#   # Load the model
#   flair <- reticulate::import("flair")
#   Classifier <- flair$nn$Classifier
#   tagger <- Classifier$load(language)
# }

#' @title Load POS (Part-of-Speech) Tagger Model
#'
#' @description Loads a Part-of-Speech tagging model from Flair and displays
#' its tag dictionary in organized categories.
#'
#' @param model_name Character string specifying the model to load.
#' Default is "pos-fast".
#' @param show_tags Logical, whether to display the tag dictionary.
#' Default is TRUE.
#'
#' @return A Flair tagger model object for POS tagging
#' @export
load_tagger_pos <- function(model_name = "pos-fast", show_tags = TRUE) {
  if (is.null(model_name)) {
    model_name <- "pos-fast"
    message("Model name not specified. Using default 'pos-fast' model.")
  }

  # Load the model
  tryCatch({
    flair <- reticulate::import("flair")
    Classifier <- flair$nn$Classifier

    message("Loading POS tagger model: ", model_name)
    tagger <- Classifier$load(model_name)

    # Display tag dictionary if requested
    if (show_tags) {
      tag_dict <- tagger$label_dictionary
      tag_list <- tag_dict$get_items()

      # Group tags by category
      categories <- list(
        special = grep("^<.*>$|^O$", tag_list, value = TRUE),  # Special tags
        noun = grep("^NN|^PRP|^WP|^EX", tag_list, value = TRUE),  # Nouns, pronouns
        verb = grep("^VB|^MD", tag_list, value = TRUE),  # Verbs, modals
        adj = grep("^JJ|^POS", tag_list, value = TRUE),  # Adjectives
        adv = grep("^RB|^WRB", tag_list, value = TRUE),  # Adverbs
        det = grep("^DT|^WDT|^PDT", tag_list, value = TRUE),  # Determiners
        prep = grep("^IN|^TO", tag_list, value = TRUE),  # Prepositions
        conj = grep("^CC", tag_list, value = TRUE),  # Conjunctions
        num = grep("^CD", tag_list, value = TRUE),  # Numbers
        punct = grep("^[[:punct:]]|^-[LR]RB-|^HYPH|^NFP", tag_list, value = TRUE),  # Punctuation
        other = grep("^FW|^SYM|^ADD|^XX|^UH|^LS|^\\$", tag_list, value = TRUE)  # Others
      )

      # Print organized output
      cat("\nPOS Tagger Dictionary:\n")
      cat("========================================\n")
      cat(sprintf("Total tags: %d\n", length(tag_list)))
      cat("----------------------------------------\n")

      # Print each category
      if (length(categories$special) > 0)
        cat("Special:      ", paste(categories$special, collapse = ", "), "\n")
      if (length(categories$noun) > 0)
        cat("Nouns:        ", paste(categories$noun, collapse = ", "), "\n")
      if (length(categories$verb) > 0)
        cat("Verbs:        ", paste(categories$verb, collapse = ", "), "\n")
      if (length(categories$adj) > 0)
        cat("Adjectives:   ", paste(categories$adj, collapse = ", "), "\n")
      if (length(categories$adv) > 0)
        cat("Adverbs:      ", paste(categories$adv, collapse = ", "), "\n")
      if (length(categories$det) > 0)
        cat("Determiners:  ", paste(categories$det, collapse = ", "), "\n")
      if (length(categories$prep) > 0)
        cat("Prepositions: ", paste(categories$prep, collapse = ", "), "\n")
      if (length(categories$conj) > 0)
        cat("Conjunctions: ", paste(categories$conj, collapse = ", "), "\n")
      if (length(categories$num) > 0)
        cat("Numbers:      ", paste(categories$num, collapse = ", "), "\n")
      if (length(categories$punct) > 0)
        cat("Punctuation:  ", paste(categories$punct, collapse = ", "), "\n")
      if (length(categories$other) > 0)
        cat("Others:       ", paste(categories$other, collapse = ", "), "\n")

      cat("----------------------------------------\n")
      cat("Common POS Tag Meanings:\n")
      cat("NN*: Nouns (NNP: Proper, NNS: Plural)\n")
      cat("VB*: Verbs (VBD: Past, VBG: Gerund)\n")
      cat("JJ*: Adjectives (JJR: Comparative)\n")
      cat("RB*: Adverbs\n")
      cat("PRP: Pronouns, DT: Determiners\n")
      cat("IN: Prepositions, CC: Conjunctions\n")
      cat("========================================\n")
    }

    return(tagger)

  }, error = function(e) {
    stop(sprintf(
      "Error loading POS model: %s\n Please check:\n - Model name is correct\n - Internet connection is stable\n - You have sufficient permissions\nError: %s",
      model_name, e$message
    ))
  })
}
