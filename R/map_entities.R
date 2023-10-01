#' Create Mapping for NER Highlighting
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
