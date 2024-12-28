#' Process Token Embeddings from Flair Sentence Object
#'
#' This function processes token embeddings from a Flair sentence object and converts them
#' into a matrix format with token names as row names. It handles the extraction of
#' embeddings from tokens, retrieval of token texts, and conversion to matrix format.
#'
#' @param sentence A Flair sentence object containing tokens with embeddings.
#'        The sentence object should have a 'tokens' attribute, where each token
#'        has both an 'embedding' (with numpy() method) and 'text' attribute.
#' @param verbose Logical indicating whether to print progress messages. Default is FALSE.
#'
#' @return A matrix where:
#'   \itemize{
#'     \item Each row represents a token's embedding
#'     \item Row names are the corresponding token texts
#'     \item Columns represent the dimensions of the embedding vectors
#'   }
#'
#' @details
#' The function will throw errors in the following cases:
#'   \itemize{
#'     \item If sentence is NULL or has no tokens
#'     \item If any token is missing an embedding
#'     \item If any token is missing text
#'   }
#'
#' @examples
#' \dontrun{
#' # Create a Flair sentence
#' sentence <- Sentence("example text")
#' WordEmbeddings <- flair_embeddings()$WordEmbeddings
#'
#' # Initialize FastText embeddings trained on Common Crawl
#' fasttext_embeddings <- WordEmbeddings('en-crawl')
#'
#' # Apply embeddings
#' fasttext_embeddings$embed(sentence)
#'
#' # Process embeddings with timing and messages
#' embedding_matrix <- process_embeddings(sentence, verbose = TRUE)
#' }
#'
#' @import flaiR
#' @export
process_embeddings <- function(sentence, verbose = FALSE) {
  # Start timing
  start_time <- Sys.time()

  # Input validation
  if (is.null(sentence) || is.null(sentence$tokens)) {
    stop("Invalid input: sentence or tokens is NULL")
  }

  # Check if embeddings are valid
  if (!.has_valid_embeddings(sentence)) {
    stop("Sentence needs to be embedded")
  }

  # Extract and store embeddings for each token
  if (verbose) message("Extracting token embeddings...")
  sen_list <- list()
  for (i in seq_along(sentence$tokens)) {
    if (is.null(sentence$tokens[[i]]$embedding$numpy())) {
      stop(sprintf("No embedding found for token at position %d", i))
    }
    sen_list[[i]] <- as.vector(sentence$tokens[[i]]$embedding$numpy())
  }

  # Extract token texts for labeling
  token_texts <- sapply(sentence$tokens, function(token) {
    if (is.null(token$text)) {
      stop("Token text is missing")
    }
    token$text
  })

  # Convert list of embeddings to matrix format
  if (verbose) cat("Converting embeddings to matrix format...")
  stacked_subset <- do.call(rbind, lapply(sen_list, function(x) {
    matrix(x, nrow = 1)
  }))

  # Add row names
  rownames(stacked_subset) <- token_texts

  # Calculate processing time
  end_time <- Sys.time()
  processing_time <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 3)
  if (verbose) {
    cat(sprintf("Processing completed in %s seconds\n", processing_time))
    cat(sprintf("Generated embedding matrix with %d tokens and %d dimensions\n",
                nrow(stacked_subset), ncol(stacked_subset)))
  }

  return(stacked_subset)
}


#' Internal function to check embedding validity
#'
#' This function verifies whether a Flair sentence object has been properly
#' embedded through the Flair framework by checking both the existence and
#' validity of embeddings.
#'
#' @param sentence A Flair sentence object to check
#' @return Logical indicating whether the sentence has valid embeddings
#'
#' @import flaiR
#' @noRd
.has_valid_embeddings <- function(sentence) {
  # Input validation
  if (is.null(sentence) || is.null(sentence$tokens)) {
    return(FALSE)
  }

  # Check if tokens exist and is not empty
  if (length(sentence$tokens) == 0 || identical(sentence$tokens, numeric(0))) {
    return(FALSE)
  }

  # Safely get first token
  first_token <- try(sentence$tokens[[1]], silent = TRUE)
  if (inherits(first_token, "try-error") ||
      identical(first_token, numeric(0))) {
    return(FALSE)
  }

  # Check embedding structure exists
  if (is.null(first_token$embedding)) {
    return(FALSE)
  }

  # Get numpy representation
  embedding_array <- try(first_token$embedding$numpy(), silent = TRUE)

  # Check if embedding is valid (not numeric(0) and has values)
  if (inherits(embedding_array, "try-error") ||
      identical(embedding_array, numeric(0)) ||
      length(embedding_array) == 0) {
    return(FALSE)
  }

  return(TRUE)
}
