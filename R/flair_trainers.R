#' @title Import flair.trainers Module in R
#'
#' @description This flair_trainers() provides R users with access to Flair's
#' ModelTrainer Python class using the {reticulate} package. The `ModelTrainer`
#' class offers the following main methods:
#' \itemize{
#'   \item **train**: Trains a given model. Parameters include the corpus
#'   (data split into training, development, and test sets),
#'   an output directory to save the model and logs, and various
#'   other parameters to control the training process (e.g., learning rate,
#'   mini-batch size, maximum epochs).
#'
#'   \item **find_learning_rate**: Uses the "learning rate finder"
#'   method to find an optimal learning rate for training. Parameters
#'   typically include the corpus, batch size, and a range of learning
#'   rates to explore.
#'
#'   \item **final_test**: After training a model, this method evaluates
#'    the model on a test set and prints the results.
#'
#'   \item **save_checkpoint**: Saves the current training state
#'   (including model parameters and training configurations) to resume
#'   later if interrupted.
#'
#'   \item **load_checkpoint**: Loads a previously saved checkpoint to
#'   resume training.
#'
#'   \item **log_line**: Utility method for logging. Writes a
#'   line to both the console and the log file.
#'
#'   \item **log_section**: Utility method for logging. Writes a
#'   section break to both the console and the log file.
#' }
#'
#' @return A Python Module(flair.trainers) object allowing access to Flair's trainers in R.
#'
#' @references
#' [Flair GitHub](https://github.com/flairNLP/flair/blob/master/flair/trainers/trainer.py)
#' Python equivalent:
#' \preformatted{
#' from flair.trainers import ModelTrainer
#' }
#'
#' @examples
#' \dontrun{
#' trainers <- flair_trainers()
#' model_trainer <- trainers$ModelTrainer
#' }
#' @importFrom reticulate import
#'
#' @export
flair_trainers <- function() {
  trainers <- import('flair.trainers')
  return(trainers)
}

