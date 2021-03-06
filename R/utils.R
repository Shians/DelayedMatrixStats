### ============================================================================
### Utility functions
###

# ------------------------------------------------------------------------------
# Non-exported functions
#

get_verbose <- function() {
  getOption("DelayedMatrixStats.verbose", default = FALSE)
}

set_verbose <- function(verbose) {
  if (!isTRUEorFALSE(verbose)) {
    stop("'verbose' must be TRUE or FALSE")
  }
  old_verbose <- get_verbose()
  options(DelayedMatrixStats.verbose = verbose)
  old_verbose
}

message2 <- function(msg, verbose = FALSE) {
  if (verbose) {
    message(msg)
  }
}

# TODO: Figure out a minimal definition of a "simple seed"; Hervé defines a
#       "seed contract" as dim(), dimnames(), and extract_array(); see
#       DelayedArray vignette
#       A potential minimal (albeit almost circular) definition is it has a
#       well-defined subset_by_Nindex() method
# TODO: Is an RleArraySeed a simple seed? It's in memory, but doesn't support
#       basic operations like "[", although it does support subset_by_Nindex()
#       and  DelayedArray::extract_array(), which may be sufficient
# NOTE: A HDF5ArraySeed is not a simple seed because it does not support
#       subset_by_Nindex()
.is_simple_seed <- function(seed) {
  simple_seed_classes <- c("matrix", "Matrix", "data.frame", "DataFrame",
                           "RleArraySeed")
  any(vapply(simple_seed_classes, function(class) is(seed, class), logical(1)))
}

.has_simple_seed <- function(x) {
  .is_simple_seed(seed(x))
}

# NOTE: A basic wrapper around DelayedArray:::.execute_delayed_ops() that also
#       handles seed instance of class RleArraySeed
# TODO: Make generic and implement methods
#' @importFrom S4Vectors endoapply
.execute_delayed_ops <- function(seed, delayed_ops) {
  if (is(seed, "RleArraySeed")) {
    seed@rle <- DelayedArray:::.execute_delayed_ops(seed@rle, delayed_ops)
  } else if (is(seed, "DataFrame")) {
    seed <- endoapply(seed, DelayedArray:::.execute_delayed_ops, delayed_ops)
  } else {
    seed <- DelayedArray:::.execute_delayed_ops(seed, delayed_ops)
  }
  seed
}

# NOTE: Named to avoid clash with base::.subset
# NOTE: Helper function used within [col|row]* functions
..subset <- function(x, rows = NULL, cols = NULL) {
  if (!is.null(rows) && !is.null(cols)) {
    x <- x[rows, cols, drop = FALSE]
  } else if (!is.null(rows)) {
    x <- x[rows, , drop = FALSE] # nolint
  } else if (!is.null(cols)) {
    x <- x[, cols, drop = FALSE]
  }
  x
}

#' Coerce DelayedArray to its 'simple seed' form
#' @details Like `DelayedArray:::.from_DelayedArray_to_array` but returning an
#' object of the same class as `seedClass(x)` instead of an _array_. In
#' doing so, all delayed operations are realised (including subsetting).
#'
#' @param x A \linkS4class{DelayedArray}
#' @param drop If `TRUE` the result is coerced to the lowest possible dimension
#' @param do_transpose Should transposed input be physically transposed?
#'
#' @return An object of the same class as `seedClass(x)`.
#'
#' @note Can be more efficient to leave the transpose implicit
#' (`do_transpose = FALSE`) and switch from a `row*()` method to a `col*()`
#' method (or vice versa).
#'
#' @note Only works on \linkS4class{DelayedArray} objects with 'simple seeds'
#'
#' @importFrom S4Vectors isTRUEorFALSE
#' @keywords internal
from_DelayedArray_to_simple_seed_class <- function(x, drop = FALSE,
                                                   do_transpose = TRUE) {
  stopifnot(is(x, "DelayedArray"))
  if (!.is_simple_seed(seed(x))) {
    stop("x does not have a simple seed")
  }
  if (!isTRUEorFALSE(drop)) {
    stop("'drop' must be TRUE or FALSE")
  }
  ans <- subset_by_Nindex(seed(x), unname(x@index))
  # TODO: Doesn't work for certain types of seed; does this matter? (am I going
  #       to have transposed DelayedArray objects coming through this routine?)
  # TODO: Need a dim,RleArraySeed-method
  if (!is.data.frame(ans) && !is(ans, "RleArraySeed") &&
      !is(ans, "DataFrame")) {
    ans <- DelayedArray:::set_dim(ans, dim(x))
  }
  ans <- DelayedArray:::.execute_delayed_ops(ans, x@delayed_ops)
  # TODO: Need a dimnames,RleArraySeed-method
  if (!is(ans, "RleArraySeed")) {
    ans <- DelayedArray:::set_dimnames(ans, dimnames(x))
  }
  if (drop) {
    ans <- DelayedArray:::.reduce_array_dimensions(ans)
  }
  ans
}

# Convert a Nindex of a matrix-like object to an IRangesList. Each element of
# the IRangesList corresponds to a column of the matrix-like object and the
# IRanges elements correspond to rows of the matrix-like object
# NOTE: This is typically used to construct the ranges in a RleViews object
#       on a RleArraySeed. This RleViews object then provides efficient ways
#       to compute summaries of the RleArraySeed via Views summary functions
#' @importFrom IRanges IRanges IRangesList PartitioningByEnd
#' @importFrom S4Vectors new2
get_Nindex_as_IRangesList <- function(Nindex, dim) {
  stopifnot(is.list(Nindex), is.integer(dim), length(Nindex) ==
              length(dim), length(Nindex) == 2L)
  rows <- Nindex[[1L]]
  cols <- Nindex[[2L]]
  nrow <- dim[[1L]]
  ncol <- dim[[2L]]
  if (ncol == 0) {
    return(IRangesList())
  }
  # TODO: Sanity check rows and cols are compatible with dim(seed)

  # Convert rows and cols to IRangesList
  # Four cases
  if (is.null(rows) && is.null(cols)) {
    # Case 1: NULL rows and NULL cols
    ir <- IRanges(start = seq.int(1, nrow * ncol, nrow),
                  end = seq.int(nrow, nrow * ncol, nrow))
    partitioning <- PartitioningByEnd(seq_len(ncol))
  } else if (is.null(rows) && !is.null(cols)) {
    # Case 2: NULL rows and non-NULL cols
    ir <- IRanges(start = (cols - 1L) * nrow + 1L,
                  end = cols * nrow)
    partitioning <- PartitioningByEnd(seq_along(cols))
  } else if (!is.null(rows)) {
    ir0 <- as(rows, "IRanges")
    if (is.null(cols)) {
      # Case 3: Non-NULL rows and NULL cols
      start <- vapply(X = seq.int(1, ncol),
                      FUN = function(jj) {
                        start(ir0) + (jj - 1L) * nrow
                      },
                      FUN.VALUE = integer(length(ir0)))
      end <- vapply(X = seq.int(1, ncol),
                    FUN = function(jj) {
                      end(ir0) + (jj - 1L) * nrow
                    },
                    FUN.VALUE = integer(length(ir0)))
      ir <- IRanges(start, end)
      partitioning <- PartitioningByEnd(
        seq.int(length(ir0), length(ir0) * ncol, length(ir0)))
    } else if (!is.null(cols)) {
      # Case 4: Non-NULL rows and non_NULL cols
      start <- vapply(X = as.integer(cols),
                      FUN = function(jj) {
                        start(ir0) + (jj - 1L) * nrow
                      },
                      FUN.VALUE = integer(length(ir0)))
      end <- vapply(X = as.integer(cols),
                    FUN = function(jj) {
                      end(ir0) + (jj - 1L) * nrow
                    },
                    FUN.VALUE = integer(length(ir0)))
      ir <- IRanges(start, end)
      partitioning <- PartitioningByEnd(
        seq.int(length(ir0), length(ir0) * length(cols), length(ir0)))
    }
  }
  # TODO: Better way to instantiate the result?
  new2("CompressedIRangesList",
       unlistData = ir,
       partitioning = partitioning)
}

# ------------------------------------------------------------------------------
# Non-exported methods
#

setMethod("subset_by_Nindex", "ANY",
          function(x, Nindex) {
            DelayedArray:::subset_by_Nindex(x = x, Nindex = Nindex)
          }
)

# TODO: Could simplify to subset_by_Nindex,ANY-method if
#       `[`,RleArraySeed-method is defined, e.g., via
#       DelayedArray:::to_linear_index() like in the below
setMethod("subset_by_Nindex", "SolidRleArraySeed",
          function(x, Nindex) {
            x_dim <- dim(x)
            x_dimnames <- dimnames(x)
            i <- DelayedArray:::to_linear_index(Nindex = Nindex,
                                                dim = x_dim)
            rle <- x@rle[i]
            dim <- DelayedArray:::get_Nindex_lengths(Nindex = Nindex,
                                                     dim = x_dim)
            if (is.null(x_dimnames)) {
              dimnames <- x_dimnames
            } else {
              dimnames <- lapply(seq_along(x_dimnames), function(along) {
                DelayedArray:::get_Nindex_names_along(Nindex = Nindex,
                                                      dimnames = x_dimnames,
                                                      along = along)
              })
            }
            DelayedArray:::RleArraySeed(rle, dim, dimnames)
          }
)

# TODO: subset_by_Nindex,ChunkedRleArraySeed-method
#       (see extract_array,ChunkedRleArraySeed-method)?
# TODO: subset_by_Nindex,ConformableSeedCombiner-method
#       (see extract_array,ConformableSeedCombiner-method)?
# TODO: subset_by_Nindex,DelayedOp-method
#       (see extract_array,DelayedOp-method)?
