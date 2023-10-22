#' @title Initialization of of Flair Embeddings Modules
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

#' @title Initializing a Class for Flair's Forward and Backward Embeddings
#'
#' @description This function initializes Flair embeddings from flair.embeddings
#' module.
#'
#' @details
#' **Multi-Language Embeddings**:
#' \itemize{
#'   \item \strong{multi-X}: Supports 300+ languages, sourced from the JW300 corpus.
#'   JW300 corpus, as proposed by Agić and Vulić (2019). The corpus is licensed under CC-BY-NC-SA.
#'   \item \strong{multi-X-fast}: CPU-friendly version, trained on a mix of corpora in languages like English, German, French, Italian, Dutch, and Polish.
#' }
#'
#' **English Embeddings**:
#'
#' \itemize{
#'   \item \strong{'news-X'}: Trained with 1 billion word corpus
#'   \item \strong{'news-X-fast'}: Trained with 1 billion word corpus, CPU-friendly.
#'   \item \strong{'mix-X'}: Trained with mixed corpus (Web, Wikipedia, Subtitles)
#'   \item \strong{'pubmed-X'}: Added by @jessepeng: Trained with 5% of PubMed
#'   abstracts until 2015 (1150 hidden states, 3 layers)
#' }
#'
#' **Specific Langauge Embeddings**:
#'
#' \itemize{
#'   \item \strong{'de-X'}: German. Trained with mixed corpus (Web, Wikipedia, Subtitles)
#'   \item \strong{de-historic-ha-X}: German (historical). Added by
#'   @stefan-it: Historical German trained over Hamburger Anzeiger.
#'   \item \strong{de-historic-wz-X}: German (historical). Added by
#'   @stefan-it: Historical German trained over Wiener Zeitung.
#'   \item \strong{de-historic-rw-X}: German (historical). Added by
#'    @redewiedergabe: Historical German trained over 100 million tokens
#'   \item \strong{de-impresso-hipe-v1-X}: In-domain data for the CLEF HIPE
#'   Shared task. In-domain data (Swiss and Luxembourgish newspapers) for
#'   CLEF HIPE Shared task. More information on the shared task can be found
#'   in this paper.
#'   \item \strong{'no-X'}: Norwegian. Added by @stefan-it: Trained with
#'   Wikipedia/OPUS.
#'   \item \strong{'nl-X'}: Dutch. Added by @stefan-it: Trained with Wikipedia/OPUS
#'   \item \strong{'nl-v0-X'}: Dutch.Added by @stefan-it: LM embeddings (earlier version)
#'   \item \strong{'ja-X'}: Japanese. Added by @frtacoa: Trained with 439M words
#'   of Japanese Web crawls (2048 hidden states, 2 layers)
#'   \item \strong{'ja-X'}: Japanese. Added by @frtacoa: Trained with 439M words
#'   of Japanese Web crawls (2048 hidden states, 2 layers)
#'
#'   \item \strong{'fi-X'}: Finnish. Added by @stefan-it: Trained with Wikipedia/OPUS.
#'   \item \strong{'fr-X'}: French. Added by @mhham: Trained with French Wikipedia
#'   of Japanese Web crawls (2048 hidden states, 2 layers)
#'
#' }
#'
#' **Domain-Specific Embeddings**:
#'
#' \itemize{
#'   \item \strong{'es-clinical-'}: Spanish (clinical). Added by @matirojasg:
#'   Trained with Wikipedia
#'   \item \strong{'pubmed-X'}:English.  Added by @jessepeng: Trained with 5%
#'   of PubMed abstracts until 2015 (1150 hidden states, 3 layers)
#' }
#'
#' The above are examples. Ensure you reference the correct embedding
#' name and details for your application. Replace '*X*' with either
#' '*forward*' or '*backward*'. For a comprehensive list of embeddings,
#' please refer to:
#' \href{https://github.com/flairNLP/flair/blob/master/resources/docs/embeddings/FLAIR_EMBEDDINGS.md}{Flair Embeddings Documentation}.

#' @references
#' FlairEmbeddings from the Flair Python library. Python example usage:
#' \preformatted{
#' from flair.embeddings import FlairEmbeddings
#' flair_embedding_forward = FlairEmbeddings('news-forward')
#' flair_embedding_backward = FlairEmbeddings('news-backward')
#' }
#'
#' @param embeddings_type A character string specifying the type of embeddings to initialize. Options include: "news-forward", "news-backward".
#'
#' @return A Flair embeddings class from the flair.embeddings module.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' flair_embedding_forward <- flair_embeddings.FlairEmbeddings("news-forward")
#' flair_embedding_backward <- flair_embeddings.FlairEmbeddings("news-backward")
#' }
flair_embeddings.FlairEmbeddings <- function(embeddings_type = "news-forward") {
  flair_embeddings <- import('flair.embeddings')
  embeddings <- flair_embeddings$FlairEmbeddings(embeddings_type)
  return(embeddings)
}


#' @title Initializing a Class for Flair WordEmbeddings Class
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


#' @title Initializing a Class for TransformerDocumentEmbeddings
#'
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
#' @param use_context Logical. Whether to consider the surrounding context
#' in some processing step. Default is FALSE.
#'
#' @return A Flair TransformerWordEmbeddings in Python class.
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


#' @title Initializing a Class for TransformerWordEmbeddings
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
#' @param use_context Logical. Whether to consider the surrounding context
#' in some processing step. Default is FALSE.
#'
#' @param memory_efficient (Optional) Enables memory efficient mode in transformers. When set to TRUE,
#' uses less memory, but might be slower.
#'
#' @return A Flair TransformerWordEmbeddings in Python class.
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

#' @title Initializing a Class for StackedEmbeddings
#'
#' @description
#' Creates a stacked embedding instance using multiple Flair embeddings.
#'
#' @param embeddings_list A list containing Flair embedding instances.
#'
#' @return
#' An instance of the StackedEmbeddings from the flair.embeddings module.
#'
#' @details
#' The function ensures that each embedding provided in the list is a recognized Flair embedding.
#' If any of the embeddings in the list is not recognized, the function will throw an error.
#'
#' @examples
#' \dontrun{
#' glove_embedding <- flair_embeddings.WordEmbeddings("glove")
#' fasttext_embedding <- flair_embeddings.WordEmbeddings("fasttext")
#' stacked_embedding <- flair_embeddings.StackedEmbeddings(list(glove_embedding, fasttext_embedding))
#' }
#'
#' @importFrom reticulate py_get_attr
#' @importFrom reticulate import
#'
#' @export
flair_embeddings.StackedEmbeddings <- function(embeddings_list) {
  # Ensure that embeddings_list is a list
  if (!is.list(embeddings_list)) {
    stop("embeddings_list should be a list of Flair embeddings.")
  }

  # Ensure all elements in the list are valid Flair embeddings
  for (embedding in embeddings_list) {
    # Get the class name of the Python object
    class_name <- py_get_attr(embedding, "__class__")$`__name__`

    # Validate if it's a known Flair embedding class.
    embedding_from_flair <- names(flair_embeddings())
    if (!class_name %in% embedding_from_flair) {
      stop(paste("The embedding of type", class_name, "is not a recognized Flair embedding."))
    }
  }

  # Create the stacked embedding
  flair_embeddings <- import("flair.embeddings")
  StackedEmbeddings <- flair_embeddings$StackedEmbeddings
  embedding <- StackedEmbeddings(embeddings = embeddings_list)

  return(embedding)
}
