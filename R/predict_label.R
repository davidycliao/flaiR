#' Predict Text Label Using Flair Classifier
#'
#' @param text A character string containing the text to be labeled
#' @param classifier A Flair TextClassifier object for making predictions
#' @param sentence Optional Flair Sentence object. If NULL, one will be created from text
#'
#' @return A list containing:
#'   \describe{
#'     \item{label}{Character string of predicted label}
#'     \item{score}{Numeric confidence score from classifier}
#'     \item{token_number}{Integer count of tokens in input text}
#'   }
#'
#' @examples
#' \dontrun{
#' # Example 1: Using text input
#' classifier <- flair_models()$TextClassifier$load('stance-classifier')
#' result1 <- predict_label(
#'   text = "I strongly support this policy",
#'   classifier = classifier
#' )
#'
#' # Example 2: Using pre-created and tagged sentence
#' sent <- Sentence("I love Berlin and New York.")
#' tagger <- flair_models()$SequenceTagger$load('pos')
#' tagger$predict(sent)
#' print(sent)  # Shows tokens with POS tags
#'
#' result2 <- predict_label(
#'   text = NULL,
#'   classifier = classifier,
#'   sentence = sent
#' )
#' }
#'
#' @import flaiR
#' @export
predict_label <- function(text, classifier, sentence = NULL) {

  # Check if classifier is valid
  if (is.null(classifier) || !isTRUE(class(classifier)[1] == "flair.models.text_classification_model.TextClassifier")) {
    stop("Invalid or missing classifier. Please provide a pre-trained Flair TextClassifier model.")
  }

  # Check if Sentence exists and is correctly loaded
  if (!("python.builtin.type" %in% class(Sentence))) {
    stop("Sentence class not found or not properly loaded. Please ensure flaiR is properly loaded.")
  }

  # Check if either text or sentence is provided
  if (is.null(text) && is.null(sentence)) {
    stop("Either text or sentence must be provided")
  }

  # Create or validate sentence
  if (is.null(sentence)) {
    tryCatch({
      sentence <- Sentence(text)
    }, error = function(e) {
      stop("Failed to create Sentence object: ", e$message)
    })
  } else {
    # Enhanced sentence validation
    if (!inherits(sentence, "flair.data.Sentence")) {
      stop("Invalid sentence object. Must be a Flair Sentence instance.")
    }

    if (!("tokens" %in% names(sentence)) || length(sentence$tokens) == 0) {
      stop("Invalid sentence object: No tokens found.")
    }
  }

  # Use the classifier to predict
  tryCatch({
    classifier$predict(sentence)
  }, error = function(e) {
    stop("Prediction failed: ", e$message)
  })

  # Verify prediction results
  if (length(sentence$labels) == 0) {
    stop("No prediction labels generated")
  }

  # Get prediction details
  predicted_label <- sentence$labels[[1]]$value
  score <- sentence$labels[[1]]$score
  token_number <- length(sentence$tokens)

  # Return results
  return(list(
    label = predicted_label,
    score = score,
    token_number = token_number
  ))
}
