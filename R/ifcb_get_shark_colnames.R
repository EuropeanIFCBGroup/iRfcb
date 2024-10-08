utils::globalVariables(".data")
#' Get Shark Column Names
#'
#' This function reads SHARK column names from a specified tab-separated values (TSV) file included in the package.
#' These columns are used for submitting IFCB data to \url{https://sharkweb.smhi.se/}.
#'
#' @param minimal A logical value indicating whether to load only the minimal set of column names required for data submission to SHARK. Default is FALSE.
#'
#' @return An empty data frame containing the SHARK column names.
#' @export
#'
#' @details
#' For a detailed example of a data submission, see \code{\link{ifcb_get_shark_example}}.
#'
#' @seealso \code{\link{ifcb_get_shark_example}}
#'
#' @importFrom dplyr select
#'
#' @examples
#' shark_colnames <- ifcb_get_shark_colnames()
#' print(shark_colnames)
#'
#' shark_colnames_minimal <- ifcb_get_shark_colnames(minimal = TRUE)
#' print(shark_colnames_minimal)
ifcb_get_shark_colnames <- function(minimal = FALSE) {
  shark_example <- read.table(system.file("exdata/shark_col.txt", package = "iRfcb"), sep = "\t", header = TRUE)

  if (minimal) {
    shark_example <- dplyr::select(shark_example,
                                   .data$MYEAR, .data$STATN, .data$PROJ, .data$ORDERER, .data$SHIPC,
                                   .data$SDATE, .data$STIME, .data$LATIT, .data$LONGI, .data$POSYS,
                                   .data$MNDEP, .data$MXDEP, .data$SLABO, .data$ACKR_SMP, .data$SMTYP,
                                   .data$SMVOL, .data$IFCBNO, .data$SMPNO, .data$LATNM, .data$SFLAG,
                                   .data$TRPHY, .data$IMAGE_VERIFICATION, .data$COUNT, .data$QFLAG,
                                   .data$COEFF, .data$CLASS_F1, .data$UNCLASSIFIED_COUNTS, .data$METOA,
                                   .data$ALABO, .data$ACKR_ANA, .data$ANADATE, .data$METDC, .data$CLASSIFIER_USED)
  }

  # Return empty dataframe
  shark_example[0,]
}
