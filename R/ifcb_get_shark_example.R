#' Get Shark Column Example
#'
#' This function reads a SHARK submission example from a file included in the package.
#' This format is used for submitting IFCB data to \url{https://sharkweb.smhi.se/}.
#'
#' @return A data frame containing example data following the SHARK submission format.
#' @export
#'
#' @seealso \code{\link{ifcb_get_shark_colnames}}
#'
#' @examples
#' shark_example <- ifcb_get_shark_example()
#' print(shark_example)
ifcb_get_shark_example <- function() {
  read.table(system.file("exdata/shark_col.txt", package = "iRfcb"), sep = "\t", header = TRUE)
}
