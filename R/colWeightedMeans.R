### ============================================================================
### colWeightedMeans
###

### ----------------------------------------------------------------------------
### Non-exported methods
###

.DelayedMatrix_block_colWeightedMeans <- function(x, w = NULL, rows = NULL,
                                                  cols = NULL, na.rm = FALSE,
                                                  ...) {
  # Check input type
  stopifnot(is(x, "DelayedMatrix"))
  DelayedArray:::.get_ans_type(x, must.be.numeric = FALSE)

  # Subset
  x <- ..subset(x, rows, cols)
  if (!is.null(w) && !is.null(rows)) {
    w <- w[rows]
  }

  # Compute result
  val <- DelayedArray:::colblock_APPLY(x = x,
                                       APPLY = matrixStats::colWeightedMeans,
                                       w = w,
                                       na.rm = na.rm,
                                       ...)
  if (length(val) == 0L) {
    return(numeric(ncol(x)))
  }
  # NOTE: Return value of matrixStats::colWeightedMeans() has names
  unlist(val, recursive = FALSE, use.names = TRUE)
}

### ----------------------------------------------------------------------------
### Exported methods
###

# ------------------------------------------------------------------------------
# General method
#

#' @importMethodsFrom DelayedArray seed
#' @rdname colWeightedMeans
#' @template common_params
#' @template lowercase_x
#' @export
#' @template example_dm_MatrixMatrix
#' @examples
#'
#' colWeightedMeans(dm_Matrix)
#' # Specifying weights inversely proportional to rowwise variances
#' colWeightedMeans(dm_Matrix, w = 1 / rowVars(dm_Matrix))
setMethod("colWeightedMeans", "DelayedMatrix",
          function(x, w = NULL, rows = NULL, cols = NULL, na.rm = FALSE,
                   force_block_processing = FALSE, ...) {
            if (!hasMethod("colWeightedMeans", seedClass(x)) ||
                force_block_processing) {
              message2("Block processing", get_verbose())
              return(.DelayedMatrix_block_colWeightedMeans(x = x,
                                                           w = w,
                                                           rows = rows,
                                                           cols = cols,
                                                           na.rm = na.rm,
                                                           ...))
            }

            message2("Has seed-aware method", get_verbose())
            if (DelayedArray:::is_pristine(x)) {
              message2("Pristine", get_verbose())
              simple_seed_x <- seed(x)
            } else {
              message2("Coercing to seed class", get_verbose())
              # TODO: do_transpose trick
              simple_seed_x <- try(from_DelayedArray_to_simple_seed_class(x),
                                   silent = TRUE)
              if (is(simple_seed_x, "try-error")) {
                message2("Unable to coerce to seed class", get_verbose())
                return(colWeightedMeans(x = x,
                                        w = w,
                                        rows = rows,
                                        cols = cols,
                                        na.rm = na.rm,
                                        force_block_processing = TRUE,
                                        ...))
              }
            }

            colWeightedMeans(x = simple_seed_x,
                             w = w,
                             rows = rows,
                             cols = cols,
                             na.rm = na.rm,
                             ...)
          }
)

# ------------------------------------------------------------------------------
# Seed-aware methods
#

#' @export
setMethod("colWeightedMeans", "matrix", matrixStats::colWeightedMeans)
