### ============================================================================
### rowMadDiffs
###

### ----------------------------------------------------------------------------
### Non-exported methods
###

.DelayedMatrix_block_rowMadDiffs <- function(x, rows = NULL, cols = NULL,
                                              na.rm = FALSE, diff = 1L,
                                              trim = 0, ...) {
  # Check input type
  stopifnot(is(x, "DelayedMatrix"))
  DelayedArray:::.get_ans_type(x, must.be.numeric = TRUE)

  # Subset
  x <- ..subset(x, rows, cols)

  # Compute result
  val <- rowblock_APPLY(x = x,
                        APPLY = matrixStats::rowMadDiffs,
                        na.rm = na.rm,
                        diff = diff,
                        trim = trim,
                        ...)
  if (length(val) == 0L) {
    return(numeric(ncol(x)))
  }
  # NOTE: Return value of matrixStats::colIQRDiffs() has names
  unlist(val, recursive = FALSE, use.names = TRUE)
}

### ----------------------------------------------------------------------------
### Exported methods
###

# ------------------------------------------------------------------------------
# General method
#

#' @importMethodsFrom DelayedArray seed
#' @rdname colIQRDiffs
#' @export
#' @examples
#'
#' # Only using rows 2-4
#' rowMadDiffs(dm_Rle, rows = 2:4)
setMethod("rowMadDiffs", "DelayedMatrix",
          function(x, rows = NULL, cols = NULL, na.rm = FALSE, diff = 1L,
                   trim = 0, force_block_processing = FALSE, ...) {
            if (!hasMethod("rowMadDiffs", seedClass(x)) ||
                force_block_processing) {
              message2("Block processing", get_verbose())
              return(.DelayedMatrix_block_rowMadDiffs(x = x,
                                                       rows = rows,
                                                       cols = cols,
                                                       na.rm = na.rm,
                                                       diff = diff,
                                                       trim = trim,
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
                return(rowMadDiffs(x = x,
                                    rows = rows,
                                    cols = cols,
                                    na.rm = na.rm,
                                    diff = diff,
                                    trim = trim,
                                    force_block_processing = TRUE,
                                    ...))
              }
            }

            rowMadDiffs(x = simple_seed_x,
                         rows = rows,
                         cols = cols,
                         na.rm = na.rm,
                         diff = diff,
                         trim = trim,
                         ...)
          }
)

# ------------------------------------------------------------------------------
# Seed-aware methods
#

#' @export
setMethod("rowMadDiffs", "matrix", matrixStats::rowMadDiffs)
