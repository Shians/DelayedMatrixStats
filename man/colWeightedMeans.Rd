% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/colWeightedMeans.R,
%   R/rowWeightedMeans.R
\docType{methods}
\name{colWeightedMeans}
\alias{colWeightedMeans}
\alias{rowWeightedMeans}
\alias{colWeightedMeans,DelayedMatrix-method}
\alias{rowWeightedMeans,DelayedMatrix-method}
\title{Calculates the weighted means for each row (column) in a matrix}
\usage{
colWeightedMeans(x, w = NULL, rows = NULL, cols = NULL,
  na.rm = FALSE, ...)

rowWeightedMeans(x, w = NULL, rows = NULL, cols = NULL,
  na.rm = FALSE, ...)

\S4method{colWeightedMeans}{DelayedMatrix}(x, w = NULL, rows = NULL,
  cols = NULL, na.rm = FALSE, force_block_processing = FALSE, ...)

\S4method{rowWeightedMeans}{DelayedMatrix}(x, w = NULL, rows = NULL,
  cols = NULL, na.rm = FALSE, force_block_processing = FALSE, ...)
}
\arguments{
\item{x}{A NxK \linkS4class{DelayedMatrix}.}

\item{w}{A \code{\link[base]{numeric}} \code{\link[base]{vector}} of length
K (N).}

\item{rows}{A \code{\link[base]{vector}} indicating subset of rows
(and/or columns) to operate over. If \code{\link[base]{NULL}}, no subsetting
is done.}

\item{cols}{A \code{\link[base]{vector}} indicating subset of rows
(and/or columns) to operate over. If \code{\link[base]{NULL}}, no subsetting
is done.}

\item{na.rm}{If \code{\link[base:logical]{TRUE}}, missing values are
excluded from the calculation, otherwise not.}

\item{...}{Additional arguments passed to specific methods.}

\item{force_block_processing}{\code{FALSE} (the default) means that a
seed-aware, optimised method is used (if available). This can be overridden
to use the general block-processing strategy by setting this to \code{TRUE}
(typically not advised). The block-processing strategy loads one or more
(depending on \code{\link[DelayedArray]{getAutoBlockSize}()}) columns (\code{colFoo()})
or rows (\code{rowFoo()}) into memory as an ordinary \link[base:array]{base::array}.}
}
\value{
Returns a \code{\link[base]{numeric}} \code{\link[base]{vector}} of
length N (K).
}
\description{
Calculates the weighted means for each row (column) in a matrix.
}
\details{
The implementations of these methods are optimized for both speed and
memory.  If no weights are given, the corresponding
\code{rowMeans()}/\code{colMeans()} is used.
}
\examples{
# A DelayedMatrix with a 'Matrix' seed
dm_Matrix <- DelayedArray(Matrix::Matrix(c(rep(1L, 5),
                                           as.integer((0:4) ^ 2),
                                           seq(-5L, -1L, 1L)),
                                         ncol = 3))

colWeightedMeans(dm_Matrix)
# Specifying weights inversely proportional to rowwise variances
colWeightedMeans(dm_Matrix, w = 1 / rowVars(dm_Matrix))
rowWeightedMeans(dm_Matrix, w = 1:3)
}
\seealso{
See \code{rowMeans()} and \code{colMeans()} in
\code{\link[base]{colSums}}() for non-weighted means.  See also
\code{\link[stats]{weighted.mean}}.
}
