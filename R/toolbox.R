#' @title Convert Embeddings to Matrix
#'
#' @description This function takes a three-dimensional array of embeddings and converts them to a two-dimensional matrix
#' based on the specified strategy.
#'
#' @param embeddings A three-dimensional array of shape (number_of_texts, number_of_words, embedding_dimension).
#' @param strategy A character string specifying the strategy to use. Options are "average", "concatenate",
#' "max_pooling", and "min_pooling".
#'
#' @return A two-dimensional matrix with the transformed embeddings.
#' @export
#' @examples
#' \dontrun{
#' embeddings <- array(runif(10 * 5 * 3), c(10, 5, 3))
#' result <- embeddings_to_matrix(embeddings, strategy = "average")
#' }
embeddings_to_matrix <- function(embeddings, strategy = "average") {

  average_embedding <- function(embeddings) {
    apply(embeddings, c(1, 3), mean)
  }

  concatenate_embedding <- function(embeddings) {
    embedding_dim <- dim(embeddings)[3]
    do.call(rbind, lapply(1:dim(embeddings)[1], function(i) {
      as.vector(t(embeddings[i,,1:embedding_dim]))
    }))
  }

  max_pooling <- function(embeddings) {
    apply(embeddings, c(1, 3), max)
  }

  min_pooling <- function(embeddings) {
    apply(embeddings, c(1, 3), min)
  }

  switch(strategy,
         "average" = return(average_embedding(embeddings)),
         "concatenate" = return(concatenate_embedding(embeddings)),
         "max_pooling" = return(max_pooling(embeddings)),
         "min_pooling" = return(min_pooling(embeddings)),
         stop("Invalid strategy chosen.")
  )
}

#' @title Highlight Entities with Specified Colors and Tag
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


#' @title Create Mapping for NER Highlighting
#'
#' @description This function generates a mapping list for Named Entity Recognition (NER)
#' highlighting. The mapping list defines how different entity types should be
#' highlighted in text displays, defining the background color, font color, label, and label color
#' for each entity type.
#'
#' @param df A data frame containing at least two columns:
#'   \itemize{
#'     \item \code{entity}: A character vector of words/entities to be highlighted.
#'     \item \code{tag}: A character vector indicating the entity type of each word/entity.
#'   }
#' @param entity A character vector of entities annotated by the model.
#' @param tag A character vector of tags corresponding to the annotated entities.
#'
#' @return A list with mapping settings for each entity type, where each entity type
#' is represented as a list containing:
#'   \itemize{
#'     \item \code{words}: A character vector of words to be highlighted.
#'     \item \code{background_color}: A character string representing the background color for highlighting the words.
#'     \item \code{font_color}: A character string representing the font color for the words.
#'     \item \code{label}: A character string to label the entity type.
#'     \item \code{label_color}: A character string representing the font color for the label.
#'   }
#'
#' @examples
#'
#' \dontrun{
#'   sample_df <- data.frame(
#'     entity = c("Microsoft", "USA", "dollar", "Bill Gates"),
#'     tag = c("ORG", "LOC", "MISC", "PER"),
#'     stringsAsFactors = FALSE
#'   )
#'   mapping <- map_entities(sample_df)
#' }
#'
#' @export
map_entities <- function(df, entity = "entity", tag = "tag") {
  ## Create Mapping for NER Highlighting
  ## Args:
  ##    df: A data frame containing at least two columns
  ##    entity: A character vector of entities annotated by the model.
  ##    tag: A character vector indicating the entity type of each word/entity.
  ##
  ## Returns:
  ##    list:  A list with mapping settings for each entity type.
  ##
  # Ensure 'entity' and 'tag' are valid column names in df
  if (!(entity %in% names(df)) || !(tag %in% names(df))) {
    stop("The specified entity or tag column names are not found in the data frame.")
  }

  entity_col <- df[[entity]]
  tag_col <- df[[tag]]

  # Ensure 'entity' and 'tag' are character vectors
  if (!is.character(entity_col) || !is.character(tag_col)) {
    stop("Entity and tag columns should be of type character.")
  }

  required_tags <- c("ORG", "LOC", "MISC", "PER")

  # Check if at least one required tag is present
  if (!any(required_tags %in% unique(tag_col))) {
    stop("The data frame must contain at least one named entity tag.")
  }

  coloring_entities <- list(
    ORG = list(words = unique(entity_col[tag_col == "ORG"]),
               background_color = "pink", font_color = "black",
               label = "ORG", label_color = "pink"),
    LOC = list(words = unique(entity_col[tag_col == "LOC"]),
               background_color = "lightblue", font_color = "black",
               label = "LOC", label_color = "blue"),
    MISC = list(words = unique(entity_col[tag_col == "MISC"]),
                background_color = "yellow", font_color = "black",
                label = "MISC", label_color = "orange"),
    PER = list(words = unique(entity_col[tag_col == "PER"]),
               background_color = "lightgreen", font_color = "black",
               label = "PER", label_color = "green")
  )

  return(coloring_entities)
}
