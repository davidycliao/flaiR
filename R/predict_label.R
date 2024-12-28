#' Predict Text Label Using Flair Classifier
#'
#' This function predicts the label of input text using a Flair classifier,
#' with options for confidence thresholding to adjust predictions to NEUTRAL.
#'
#' @param text A character string containing the text to be labeled
#' @param classifier A Flair TextClassifier object for making predictions
#' @param threshold_score Numeric value between 0 and 1 representing the confidence
#'        threshold for label classification. Defaults to 0.5 if not specified
#' @param threshold Logical indicating whether to apply the threshold_score to
#'        adjust predictions to NEUTRAL. Defaults to FALSE
#'
#' @return A list containing the following elements:
#'   \describe{
#'     \item{label}{Character string of the final predicted label (AGAINST/FAVOR/NEUTRAL)}
#'     \item{score}{Numeric confidence score from the classifier}
#'     \item{token_number}{Integer count of tokens in the input text}
#'     \item{threshold_score}{Numeric value of the threshold used}
#'     \item{original_label}{Character string of the classifier's original prediction
#'          before thresholding}
#'   }
#'
#' @examples
#' \dontrun{
#' # Load a pre-trained classifier
#' classifier <- flair$models$TextClassifier$load('stance-classifier')
#'
#' # Predict label without thresholding
#' result1 <- predict_label(
#'   text = "I strongly support this policy",
#'   classifier = classifier
#' )
#'
#' # Predict with custom threshold
#' result2 <- predict_label(
#'   text = "I somewhat agree with the proposal",
#'   classifier = classifier,
#'   threshold_score = 0.7,
#'   threshold = TRUE
#' )
#' }
#'
#' @details
#' The function will throw an error if the classifier is NULL or not a
#' Flair TextClassifier.
#'
#' @import flaiR
#' @export
predict_label <- function(text, classifier, threshold_score = NULL, threshold = FALSE) {
  # Check if classifier is provided and valid
  if (is.null(classifier) || !isTRUE(class(classifier)[1] == "flair.models.text_classification_model.TextClassifier")) {
    stop("Invalid or missing classifier. Please provide a pre-trained Flair TextClassifier model.")
  }

  # Create a sentence object
  sentence <- Sentence(text)

  # Use the classifier to predict
  classifier$predict(sentence)

  # Get the predicted label and score
  predicted_label <- sentence$labels[[1]]$value
  score <- sentence$labels[[1]]$score  # 移除 as.numeric
  token_number <- length(sentence$tokens)

  # Set default threshold_score if NULL
  if (is.null(threshold_score)) {
    threshold_score <- 0.5
  }

  # Modify label based on the score threshold and original label
  original_label <- predicted_label
  if (threshold && score < threshold_score) {
    if (predicted_label %in% c("AGAINST", "FAVOR")) {
      predicted_label <- "NEUTRAL"
    }
  }

  # Construct the prediction result
  prediction = list(label = predicted_label,
                    score = score,
                    token_number = token_number,
                    threshold_score = threshold_score,
                    original_label = original_label)

  # Return the prediction result
  return(prediction)
}
