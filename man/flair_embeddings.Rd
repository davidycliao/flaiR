% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrapping_python_flair.R
\name{flair_embeddings}
\alias{flair_embeddings}
\title{Flair Embeddings Importer}
\usage{
flair_embeddings()
}
\value{
The \code{flair.embeddings} module from Flair.
}
\description{
This function imports and returns the \code{flair.embeddings} module from Flair.
It provides a convenient R interface to the Flair library's embedding functionalities.
}
\examples{
\dontrun{
flair_embeddings <- flair_embeddings()$FlairEmbeddings
}

}
\references{
In Python's Flair library:
\code{
from flair.embeddings import FlairEmbeddings
}
}