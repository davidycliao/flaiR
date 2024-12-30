#' @title Check if Tagger is Valid
#'
#' @description Internal function to verify if the provided tagger is valid
#' and has the required methods.
#'
#' @param tagger A Flair tagger object to check
#' @return Logical indicating if the tagger is valid
#' @keywords internal
check_tagger <- function(tagger) {
  if (is.null(tagger)) {
    stop("Tagger cannot be NULL. Please provide a valid Flair tagger object.",
         "\nExample: tagger_ner <- load_tagger_ner('ner')")
  }

  # Check if tagger has required methods
  required_methods <- c("predict", "to")
  has_methods <- sapply(required_methods, function(method) {
    !is.null(tagger[[method]]) && is.function(tagger[[method]])
  })

  if (!all(has_methods)) {
    missing_methods <- required_methods[!has_methods]
    stop("Invalid tagger object. Missing required methods: ",
         paste(missing_methods, collapse = ", "))
  }

  return(TRUE)
}

#' @title Extract Named Entities from Texts with Batch Processing
#'
#' @description This function processes texts in batches and extracts named entities
#' using the Flair NLP library. It supports both standard NER and OntoNotes models,
#' with options for batch processing and GPU acceleration.
#'
#' @param texts A character vector containing the texts to process.
#' @param doc_ids A character or numeric vector containing the document IDs
#' corresponding to each text.
#' @param tagger A Flair tagger object for named entity recognition. Must be provided
#' by the user. Can be created using load_tagger_ner() with different models:
#' \itemize{
#'   \item Standard NER: tagger_ner <- load_tagger_ner('ner')
#'   \item OntoNotes: tagger_ner <- load_tagger_ner('flair/ner-english-ontonotes')
#'   \item Large model: tagger_ner <- load_tagger_ner('flair/ner-english-large')
#' }
#' @param show.text_id A logical value. If TRUE, includes the actual text from
#' which the entity was extracted. Default is FALSE.
#' @param gc.active A logical value. If TRUE, runs the garbage collector after
#' processing texts. Default is FALSE.
#' @param batch_size An integer specifying the size of each batch. Set to 1 for
#' single-text processing. Default is 5.
#' @param device A character string specifying the computation device ("cpu",
#' "cuda:0", "cuda:1", etc.). Default is "cpu". Note: MPS (Mac M1/M2) is currently
#' not fully supported and will default to CPU.
#' @param verbose A logical value. If TRUE, prints processing progress. Default is FALSE.
#'
#' @return A data table with columns:
#' \describe{
#'   \item{doc_id}{Character or numeric. The ID of the document from which the
#'   entity was extracted.}
#'   \item{text_id}{Character. The complete text from which the entity was
#'   extracted. Only included when show.text_id = TRUE.}
#'   \item{entity}{Character. The actual named entity text that was extracted.
#'   Will be NA if no entity was found.}
#'   \item{tag}{Character. The category of the named entity.}
#'   \item{score}{Numeric. Confidence score of the prediction.}
#' }
#'
#' @examples
#' \dontrun{
#' library(reticulate)
#' library(flaiR)
#'
#' # Using standard NER model
#' tagger_std <- load_tagger_ner('ner')
#'
#' texts <- c(
#'   "John Smith works at Google in New York.",
#'   "The Eiffel Tower was built in 1889."
#' )
#' doc_ids <- c("doc1", "doc2")
#'
#' results <- get_entities(
#'   texts = texts,
#'   doc_ids = doc_ids,
#'   tagger = tagger_std,
#'   batch_size = 2,
#'   verbose = TRUE
#' )
#' }
#'
#' @importFrom data.table data.table rbindlist :=
#' @importFrom reticulate import
#' @export
get_entities <- function(texts, doc_ids = NULL, tagger, show.text_id = FALSE,
                         gc.active = FALSE, batch_size = 5, device = "cpu",
                         verbose = FALSE) {
  # 声明所有会用到的变量
  text_id <- entity <- tag <- score <- NULL

  if (verbose) {
    message("Starting entity extraction process...")
    message("Checking tagger...")
  }

  # Check tagger
  check_tagger(tagger)

  if (verbose) {
    message("Tagger validation successful")
    message("Number of texts to process: ", length(texts))
    message("Batch size: ", batch_size)
    message("Device: ", device)
  }

  # Check environment and parameters
  check_prerequisites()
  check_device(device)
  check_batch_size(batch_size)
  check_show.text_id(show.text_id)

  # Check and prepare texts and doc_ids
  texts_and_ids <- check_texts_and_ids(texts, doc_ids)
  texts <- texts_and_ids$texts
  doc_ids <- texts_and_ids$doc_ids

  # Set device for processing
  if (device != "cpu") {
    tryCatch({
      tagger$to(device)
    }, error = function(e) {
      warning(sprintf("Error setting device %s: %s\nDefaulting to CPU.",
                      device, e$message))
      device <- "cpu"
    })
  }

  Sentence <- reticulate::import("flair")$data$Sentence

  # Helper function for progress bar
  create_progress_bar <- function(current, total, width = 50) {
    percent <- current / total
    filled <- round(width * percent)
    empty <- width - filled
    bar <- paste0(
      "[",
      strrep("=", filled),
      ">",
      strrep(" ", empty),
      "] ",
      sprintf("%3d%%", round(percent * 100))
    )
    return(bar)
  }

  # Process batch of texts and extract entities
  process_batch <- function(batch_texts, batch_doc_ids, batch_num, total_batches) {
    if (verbose) {
      progress_text <- sprintf("\rBatch %d/%d %s Processing %d texts...",
                               batch_num, total_batches,
                               create_progress_bar(batch_num, total_batches),
                               length(batch_texts))
      cat(progress_text)
    }

    results_list <- lapply(seq_along(batch_texts), function(i) {
      text <- batch_texts[[i]]
      doc_id <- batch_doc_ids[[i]]

      if (is.na(text) || is.na(doc_id)) {
        if (verbose) message("Skipping NA text or doc_id")
        return(data.table::data.table(
          doc_id = NA_character_,
          entity = NA_character_,
          tag = NA_character_,
          score = NA_real_
        ))
      }

      tryCatch({
        sentence <- Sentence(text)
        tagger$predict(sentence)
        entities <- sentence$get_spans("ner")

        if (length(entities) == 0) {
          return(data.table::data.table(
            doc_id = doc_id,
            entity = NA_character_,
            tag = NA_character_,
            score = NA_real_
          ))
        }

        # Create data table with entity information
        dt <- data.table::data.table(
          doc_id = rep(doc_id, length(entities)),
          entity = vapply(entities, function(e) e$text, character(1)),
          tag = vapply(entities, function(e) e$tag, character(1)),
          score = vapply(entities, function(e) e$score, numeric(1))
        )

        if (isTRUE(show.text_id)) {
          dt[, "text_id" := text]
        }

        return(dt)
      }, error = function(e) {
        warning(sprintf("Error processing text %d: %s", i, e$message))
        return(data.table::data.table(
          doc_id = doc_id,
          entity = NA_character_,
          tag = NA_character_,
          score = NA_real_
        ))
      })
    })

    if (verbose) {
      cat("\r", strrep(" ", 80), "\r")  # Clear current line
      cat(sprintf("Batch %d/%d completed\n", batch_num, total_batches))
    }

    return(rbindlist(results_list, fill = TRUE))
  }

  # Process all batches
  num_batches <- ceiling(length(texts) / batch_size)
  all_results <- lapply(1:num_batches, function(b) {
    start_idx <- (b - 1) * batch_size + 1
    end_idx <- min(b * batch_size, length(texts))

    batch_result <- process_batch(
      texts[start_idx:end_idx],
      doc_ids[start_idx:end_idx],
      b,
      num_batches
    )

    # Run garbage collection if requested
    if (gc.active) {
      if (verbose) message("Running garbage collection...")
      check_and_gc(gc.active)
    }

    return(batch_result)
  })

  # Combine all results
  final_results <- rbindlist(all_results, fill = TRUE)

  # Final summary
  if (verbose) {
    total_entities <- nrow(final_results[!is.na(entity)])
    message("\n", strrep("=", 60))
    message("Processing Summary:")
    message(strrep("-", 60))
    message(sprintf("Total texts processed:     %d", length(texts)))
    message(sprintf("Total entities found:      %d", total_entities))
    message(sprintf("Average entities per text: %.1f", total_entities/length(texts)))
    message(strrep("=", 60))
  }

  return(final_results)
}
