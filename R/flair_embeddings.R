#' @title Flair Embeddings Importer
#'
#' @description This function imports and returns the \code{flair.embeddings} module from Flair.
#' It provides a convenient R interface to the Flair library's embedding functionalities.
#'
#' @return The \code{flair.embeddings} module from Flair.
#'
#' @examples \dontrun{
#' flair_embeddings <- flair_embeddings()$FlairEmbeddings
#' OpenAIGPTEmbeddings <- flair_embeddings()$OpenAIGPTEmbeddings
#' StackedEmbeddings <- flair_embeddings()$StackedEmbeddings
#' TransformerDocumentEmbeddings <- flair_embeddings()$TransformerDocumentEmbeddings
#' TransformerWordEmbeddings <- flair_embeddings()$TransformerWordEmbeddings
#' RoBERTaEmbeddings <- flair_embeddings()$RoBERTaEmbeddings
#' TransformerOnnxDocumentEmbeddings <- flair_embeddings()$TransformerOnnxDocumentEmbeddings
#' SentenceTransformerDocumentEmbeddings <- flair_embeddings()$SentenceTransformerDocumentEmbeddings
#' PooledFlairEmbeddings <- flair_embeddings()$PooledFlairEmbeddings
#' }
#'
#' @references
#' In Python's Flair library:
#' \code{
#' from flair.embeddings import FlairEmbeddings
#' }
#'
#' @importFrom reticulate import
#' @export
flair_embeddings <- function() {
  flair_embeddings <- import('flair.embeddings')
  return(flair_embeddings)
}

#' @title Flair Embedding Initialization
#'
#' @description This function initializes Flair embeddings using Python's Flair
#' library.
#'
#' @references
#' FlairEmbeddings from Flair library in Python. Example usage in Python:
#' \preformatted{
#' flair_embedding_forward = FlairEmbeddings('news-forward')
#' flair_embedding_backward = FlairEmbeddings('news-backward')
#' }
#' @param embeddings_type Character, type of embeddings to initialize.
#' Options: "news-forward", "news-backward".
#' @return A Flair embeddings object from Python's Flair library.
#' @export
#' @examples
#' \dontrun{
#' flair_embedding_forward <- flair_embeddings.FlairEmbeddings("news-forward")
#' flair_embedding_backward <- flair_embeddings.FlairEmbeddings("news-backward")
#' }
flair_embeddings.FlairEmbeddings <- function(embeddings_type = "news-forward") {
  flair_embeddings <- import('flair.embeddings')

  # Try to get embeddings and catch any Python errors
  tryCatch({
    embeddings <- flair_embeddings$FlairEmbeddings(embeddings_type)
  }, error = function(e) {
    stop("Invalid embeddings type. Choose `news-forward` or `news-backward`")
  })

  if (embeddings_type == "news-backward") {
    message("Initialized Flair backward embeddings")
  } else if (embeddings_type == "news-forward") {
    message("Initialized Flair forward embeddings")
  } else {
    stop("Invalid embeddings type. Choose `news-forward` or `news-backward`")
  }
  return(embeddings)
}


#' @title Create a Flair WordEmbeddings Object
#'
#' @description
#' This function interfaces with Python via {reticulate} to create a `WordEmbeddings`
#' object using the Flair library. Users select which pre-trained embeddings to load
#' by providing the appropriate ID string. Typically, a two-letter language code initializes
#' an embedding (e.g., 'en' for English, 'de' for German). By default, this loads FastText embeddings
#' trained over Wikipedia. For web crawl embeddings, use the '-crawl' suffix (e.g., 'de-crawl' for German).
#' English offers more options like 'en-glove', 'en-extvec', etc.
#'
#' Supported embeddings include:
#' \itemize{
#'   \item 'en-glove' or 'glove': English GloVe embeddings
#'   \item 'en-extvec' or 'extvec': English Komninos embeddings
#'   \item 'en-crawl' or 'crawl': English FastText web crawl embeddings
#'   \item 'en-twitter' or 'twitter': English Twitter embeddings
#'   \item 'en-turian' or 'turian': English Turian embeddings (small)
#'   \item 'en', 'en-news', or 'news': English FastText news and Wikipedia embeddings
#'   \item 'de': German FastText embeddings
#'   \item 'nl': Dutch FastText embeddings
#'   \item 'fr': French FastText embeddings
#'   \item 'it': Italian FastText embeddings
#'   \item 'es': Spanish FastText embeddings
#'   \item 'pt': Portuguese FastText embeddings
#'   \item 'ro': Romanian FastText embeddings
#'   \item 'ca': Catalan FastText embeddings
#'   \item 'sv': Swedish FastText embeddings
#'   \item 'da': Danish FastText embeddings
#'   \item 'no': Norwegian FastText embeddings
#'   \item 'fi': Finnish FastText embeddings
#'   \item 'pl': Polish FastText embeddings
#'   \item 'cz': Czech FastText embeddings
#'   \item 'sk': Slovak FastText embeddings
#'   \item 'sl': Slovenian FastText embeddings
#'   \item 'sr': Serbian FastText embeddings
#'   \item 'hr': Croatian FastText embeddings
#'   \item 'bg': Bulgarian FastText embeddings
#'   \item 'ru': Russian FastText embeddings
#'   \item 'ar': Arabic FastText embeddings
#'   \item 'he': Hebrew FastText embeddings
#'   \item 'tr': Turkish FastText embeddings
#'   \item 'fa': Persian FastText embeddings
#'   \item 'ja': Japanese FastText embeddings
#'   \item 'ko': Korean FastText embeddings
#'   \item 'zh': Chinese FastText embeddings
#'   \item 'hi': Hindi FastText embeddings
#'   \item 'id': Indonesian FastText embeddings
#'   \item 'eu': Basque FastText embeddings
#' }
#'
#' For example, to load German FastText embeddings, use 'de' as the `embeddings` parameter.
#'
#' @param embeddings The type of pre-trained embeddings to use. Defaults to "`glove`".
#'
#' @return A Flair WordEmbeddings class.
#'
#' @examples
#' \dontrun{
#' embedding <- flair_embeddings.WordEmbeddings("glove")
#' }
#'
#' @references
#' Python equivalent:
#' \preformatted{
#' from flair.embeddings import WordEmbeddings
#' embedding = WordEmbeddings('glove')
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_embeddings.WordEmbeddings <- function(embeddings = "glove") {
  flair_embeddings <- import("flair.embeddings")
  WordEmbeddings <- flair_embeddings$WordEmbeddings
  embedding <- WordEmbeddings(embeddings)
  return(embedding)
}


#' @title TransformerDocumentEmbeddings Function
#' @description This function interfaces with Python via {reticulate} to
#' create a `flair_embeddings.TransformerDocumentEmbeddings` object from
#' the flair.embeddings module.
#'
#' @param model A character string specifying the pre-trained model to use.
#' Defaults to 'bert-base-uncased'. This could be the name of the transformer
#' model, e.g., "bert-base-uncased", "gpt2-medium", etc. It can also be a path
#' to a pre-trained model.
#'
#' @param layers (Optional) Layers of the transformer model to use. A string that
#' specifies which layers of the transformer model to use. For BERT, you can
#' specify multiple like "1,2,3" or single layers 1. The layers argument controls
#' which transformer layers are used for the embedding. If you set this value to
#' '-1,-2,-3,-4', the top 4 layers are used to make an embedding. If you set it
#' to '-1', only the last layer is used. If you set it to "all", then all layers
#' are used.
#'
#' @param subtoken_pooling (Optional) Method of pooling to handle subtokens.
#' This determines how subtokens (word pieces) are pooled into one embedding
#' for the original token. Options are 'first' (use first subtoken),
#' 'last' (use last subtoken), 'first_last' (concatenate first and last subtokens),
#'  and 'mean' (average all subtokens).
#'
#' @param fine_tune Logical. Indicates if fine-tuning should be done. Defaults
#' to FALSE.
#' @param allow_long_sentences Logical. Allows longer sentences to be processed.
#' Defaults to TRUE. In certain transformer models (like BERT), there is a
#' maximum sequence length. By default, Flair cuts off sentences that are too \
#' long. If this option is set to True, Flair will split long sentences into
#' smaller parts and later average the embeddings.
#'
#' @param memory_efficient (Optional) Enables memory efficient mode in
#' transformers. When set to TRUE, uses less memory, but might be slower.
#'
#' @return A Flair TransformerWordEmbeddings object.
#'
#' @details This function provides an interface for R users to easily
#' access and utilize the power of Flair's TransformerDocumentEmbeddings.
#' It bridges the gap between Python's Flair library and R, enabling
#' R users to leverage state-of-the-art NLP models.
#'
#' @seealso
#' \link[flair]{https://github.com/flairNLP/flair} Flair's official GitHub repository.
#'
#' @examples
#' \dontrun{
#' embedding <- flair_embeddings.TransformerDocumentEmbeddings("bert-base-uncased")
#' }
#'
#' @references
#' In Python's Flair library:
#' \code{
#' from flair.embeddings import TransformerDocumentEmbeddings
#' embedding = TransformerDocumentEmbeddings('bert-base-uncased')
#' }
#'
#' @importFrom reticulate import
#' @export
flair_embeddings.TransformerDocumentEmbeddings <- function(model = "bert-base-uncased",
                                                           layers = "all",
                                                           subtoken_pooling = "mean",
                                                           fine_tune = FALSE,
                                                           allow_long_sentences = TRUE,
                                                           memory_efficient = NULL,
                                                           use_context = FALSE) {
  flair_embeddings <- import("flair.embeddings")
  TransformerDocumentEmbeddings <- flair_embeddings$TransformerDocumentEmbeddings
  embedding <- TransformerDocumentEmbeddings(model = model,
                                             layers = layers,
                                             subtoken_pooling = subtoken_pooling,
                                             fine_tune = fine_tune,
                                             allow_long_sentences = allow_long_sentences,
                                             memory_efficient = memory_efficient,
                                             use_context = use_context)
  return(embedding)
}


#' @title Create a Flair TransformerWordEmbeddings Object
#'
#' @description This function interfaces with Python via {reticulate} to create
#' a `TransformerWordEmbeddings` object object from the flair.embeddings module.
#'
#' @param model A character string specifying the pre-trained model to use.
#' Defaults to 'bert-base-uncased'. This could be the name of the transformer
#' model, e.g., "bert-base-uncased", "gpt2-medium", etc. It can also be a path
#' to a pre-trained model.
#'
#' @param layers (Optional) Layers of the transformer model to use. A string that
#' specifies which layers of the transformer model to use. For BERT, you can
#' specify multiple like "1,2,3" or single layers 1. The layers argument controls
#' which transformer layers are used for the embedding. If you set this value to
#' '-1,-2,-3,-4', the top 4 layers are used to make an embedding. If you set it
#' to '-1', only the last layer is used. If you set it to "all", then all layers
#' are used.
#'
#' @param subtoken_pooling (Optional) Method of pooling to handle subtokens.
#' This determines how subtokens (word pieces) are pooled into one embedding
#' for the original token. Options are 'first' (use first subtoken),
#' 'last' (use last subtoken), 'first_last' (concatenate first and last subtokens),
#'  and 'mean' (average all subtokens).
#'
#' @param fine_tune Logical. Indicates if fine-tuning should be done. Defaults to FALSE.
#' @param allow_long_sentences Logical. Allows longer sentences to be processed.
#' Defaults to TRUE. In certain transformer models (like BERT), there is a
#' maximum sequence length. By default, Flair cuts off sentences that are too
#' long. If this option is set to True, Flair will split long sentences into smaller
#' parts and later average the embeddings.
#'
#' @param memory_efficient (Optional) Enables memory efficient mode in transformers. When set to TRUE,
#' uses less memory, but might be slower.
#'
#' @return A Flair TransformerWordEmbeddings object.
#'
#' @details This function provides an interface for R users to easily
#' access and utilize the power of Flair's TransformerWordEmbeddings.
#' It bridges the gap between Python's Flair library and R, enabling
#' R users to leverage state-of-the-art NLP models.
#'
#' @seealso
#' \link[flair]{https://github.com/flairNLP/flair} Flair's official GitHub repository.
#'
#' @examples
#' \dontrun{
#' embedding <- flair_embeddings.TransformerWordEmbeddings("bert-base-uncased")
#' }
#'
#' @references
#' Python equivalent: \preformatted{
#' from flair.embeddings import TransformerWordEmbeddings
#' embedding = TransformerWordEmbeddings('bert-base-uncased')
#' }
#'
#' @importFrom reticulate import
#'
#' @export
flair_embeddings.TransformerWordEmbeddings <- function(model = "bert-base-uncased",
                                                       layers = "all",
                                                       subtoken_pooling = "mean",
                                                       fine_tune = FALSE,
                                                       allow_long_sentences = TRUE,
                                                       memory_efficient = NULL,
                                                       use_context = FALSE) {
  flair_embeddings <- import("flair.embeddings")
  TransformerWordEmbeddings <- flair_embeddings$TransformerWordEmbeddings
  embedding <- TransformerWordEmbeddings(model = model,
                                         layers = layers,
                                         subtoken_pooling = subtoken_pooling,
                                         fine_tune = fine_tune,
                                         allow_long_sentences = allow_long_sentences,
                                         memory_efficient = memory_efficient,
                                         use_context = use_context)
  return(embedding)
}


