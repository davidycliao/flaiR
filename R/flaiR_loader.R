
#' @title Load the Named Entity Recognition (NER) Tagger
#'
#' @description A helper function to load the appropriate tagger based on the provided language.
#' This function supports a variety of languages/models.
#'
#' @param language A character string indicating the desired language for the NER tagger.
#' If `NULL`, the function will default to the 'pos-fast' model.
#' Supported languages and their models include:
#' \itemize{
#'   \item `"en"` - English NER tagging (`ner`)
#'   \item `"de"` - German NER tagging (`de-ner`)
#'   \item `"fr"` - French NER tagging (`fr-ner`)
#'   \item `"nl"` - Dutch NER tagging (`nl-ner`)
#'   \item `"da"` - Danish NER tagging (`da-ner`)
#'   \item `"ar"` - Arabic NER tagging (`ar-ner`)
#'   \item `"ner-fast"` - English NER fast model (`ner-fast`)
#'   \item `"ner-large"` - English NER large mode (`ner-large`)
#'   \item `"de-ner-legal"` - NER (legal text) (`de-ner-legal`)
#'   \item `"nl"` - Dutch NER tagging (`nl-ner`)
#'   \item `"da"` - Danish NER tagging (`da-ner`)
#'   \item `"ar"` - Arabic NER tagging (`ar-ner`)
#'}
#'
#' @return An instance of the Flair SequenceTagger for the specified language.
#'
#' @import reticulate
#' @importFrom stats setNames
#'
#' @examples
#' # Load the English NER tagger
#' tagger_en <- load_tagger_ner("en")
#'
#' @export
load_tagger_ner <- function(language = NULL) {
  supported_lan_models <- c("ner", "de-ner",
                            "fr-ner", "nl-ner",
                            "da-ner", "ar-ner",
                            "ner-fast", "ner-large",
                            "ner-pooled",  "ner-ontonotes",
                            "ner-ontonotes-fast", "ner-ontonotes-large",
                            "de-ner-large", "de-ner-germeval",
                            "de-ner-legal", "es-ner",
                            "nl-ner", "nl-ner-large",
                            "nl-ner-rnn", "ner-ukrainian")
  language_model_map <- setNames(supported_lan_models, c("en", "de",
                                                         "fr", "nl",
                                                         "da", "ar",
                                                         "ner-fast", "ner-large",
                                                         "ner-pooled", "ner-ontonotes",
                                                         "ner-ontonotes-fast", "ner-ontonotes-large",
                                                         "de-ner-large", "de-ner-germeval",
                                                         "de-ner-legal", "es-ner-large",
                                                         "nl-ner", "nl-ner-large",
                                                         "nl-ner-rnn", "ner-ukrainian")
  )

  if (is.null(language)) {
    language <- "en"
    message("Language is not specified. ", language, " in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
  }

  # Translate language to model name if necessary
  if (language %in% names(language_model_map)) {
    language <- language_model_map[[language]]
  }

  # Ensure the model is supported
  check_language_supported(language = language, supported_lan_models = supported_lan_models)

  # Load the model
  SequenceTagger <- reticulate::import("flair.models")$SequenceTagger
  SequenceTagger$load(language)
}

#' Load Flair POS Tagger
#'
#' This function loads the POS (part-of-speech) tagger model for a specified language
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
load_tagger_pos <- function(language = NULL) {
  supported_lan_models <- c("pos", "pos-fast", "upos", "upos-fast",
                            "pos-multi", "pos-multi-fast", "ar-pos", "de-pos",
                            "de-pos-tweets", "da-pos", "ml-pos",
                            "ml-upos", "pt-pos-clinical", "pos-ukrainian")

  if (is.null(language)) {
    language <- "pos-fast"
    message("Language is not specified. ", language, "in Flair is forceloaded. Please ensure that the internet connectivity is stable. \n")
  }

  # Ensure the model is supported
  check_language_supported(language = language, supported_lan_models = supported_lan_models)

  # Load the model
  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  tagger <- Classifier$load(language)
}

#' @title Load a Sentiment or Language Tagger Model from Flair
#'
#' @description This function loads a pre-trained sentiment or language tagger
#' from the Flair library.
#'
#' @param language A character string specifying the language model to load.
#' Supported models include:
#' \itemize{
#'   \item "sentiment" - Sentiment analysis model
#'   \item "sentiment-fast" - Faster sentiment analysis model
#'   \item "de-offensive-language" - German offensive language detection model
#'} If not provided, the function will default to the "sentiment" model.
#'
#' @return An object of the loaded Flair model.
#'
#' @import reticulate
#' @examples
#' \dontrun{
#'   tagger <- load_tagger_sentiments("sentiment")
#' }
#'
#' @export
load_tagger_sentiments <- function(language = NULL) {
  supported_lan_models <- c("sentiment", "sentiment-fast", "de-offensive-language")

  if (is.null(language)) {
    language <- "sentiment"
    message("Language is not specified. ", language, " in Flair is forceloaded. Please ensure that the internet connectivity is stable.")
  }

  # Ensure the model is supported
  check_language_supported(language = language, supported_lan_models = supported_lan_models)

  # Load the model
  flair <- reticulate::import("flair")
  Classifier <- flair$nn$Classifier
  tagger <- Classifier$load(language)
  return(tagger)
}
