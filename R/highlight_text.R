#' Highlight Entities with Specified Colors and Tag
#'
#' @description This function highlights specified entities in a text string
#' with specified background colors, font colors, and optional labels.
#' Additionally, it allows setting a specific font type for highlighted text.
#'
#' @param text A character string containing the text to highlight.
#' @param entities_mapping A named list of lists, with each sub-list containing:
#'   \itemize{
#'     \item \code{words}: A character vector of words to highlight.
#'     \item \code{background_color}: A character string specifying the CSS color for the highlight background.
#'     \item \code{font_color}: A character string specifying the CSS color for the highlighted text.
#'     \item \code{label}: A character string specifying a label to append after each highlighted word.
#'     \item \code{label_color}: A character string specifying the CSS color for the label text.
#'   }
#' @param font_family A character string specifying the CSS font family for
#' the highlighted text and label. Default is "Arial".
#'
#' @return An HTML object containing the text with highlighted entities.
#'
#' @examples
#' library(flaiR)
#' data("uk_immigration")
#' uk_immigration <- head(uk_immigration, 1)
#' tagger_ner <- load_tagger_ner("ner")
#' results <- get_entities(uk_immigration$text,
#'                         uk_immigration$speaker,
#'                         tagger_ner,
#'                         show.text_id = FALSE)
#'
#' highlighted_text <- highlight_text(uk_immigration$text, map_entities(results))
#' print(highlighted_text)
#'
#' @importFrom htmltools HTML
#' @importFrom stringr str_replace_all
#' @export
highlight_text <- function(text, entities_mapping, font_family = "Arial") {
  # Ensure 'entities_mapping' and 'font_family' are not used directly without being checked
  if(!is.list(entities_mapping) || !all(c("words", "background_color", "font_color", "label", "label_color") %in% names(entities_mapping[[1]]))) {
    stop("'entities_mapping' must be a list with specific structure.")
  }

  if(!is.character(font_family) || length(font_family) != 1) {
    stop("'font_family' must be a single character string.")
  }

  # Keeping track of replaced words+tags to ensure they are highlighted only once
  already_replaced <- c()

  for (category in names(entities_mapping)) {
    words_to_highlight <- entities_mapping[[category]]$words
    background_color <- entities_mapping[[category]]$background_color
    font_color <- entities_mapping[[category]]$font_color
    label <- entities_mapping[[category]]$label
    label_color <- entities_mapping[[category]]$label_color

    for (word in words_to_highlight) {
      # Create a unique identifier for each word+tag combination
      word_tag_identifier <- paste(word, label, sep = "_")

      # Check if this word+tag has not been replaced already
      if(!(word_tag_identifier %in% already_replaced)) {
        replacement <- sprintf('<span style="background-color: %s; color: %s; font-family: %s">%s</span> <span style="color: %s; font-family: %s">(%s)</span>', background_color, font_color, font_family, word, label_color, font_family, label)
        text <- gsub(paste0("\\b", word, "\\b"), replacement, text)

        already_replaced <- c(already_replaced, word_tag_identifier)
      }
    }
  }

  # Justify the text
  justified_text <- sprintf('<div style="text-align: justify; font-family: %s">%s</div>', font_family, text)

  return(HTML(justified_text))
}

