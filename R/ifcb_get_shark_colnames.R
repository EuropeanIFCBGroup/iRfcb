#' Get Shark Column Names
#'
#' This function reads SHARK column names from a specified tab-separated values (TSV) file included in the package.
#' These columns are used for submitting IFCB data to \url{https://shark.smhi.se/}.
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
#' @examples
#' shark_colnames <- ifcb_get_shark_colnames()
#' print(shark_colnames)
#'
#' shark_colnames_minimal <- ifcb_get_shark_colnames(minimal = TRUE)
#' print(shark_colnames_minimal)
ifcb_get_shark_colnames <- function(minimal = FALSE) {
  shark_example <- read.table(system.file("exdata/shark_col.txt", package = "iRfcb"), sep = "\t", header = TRUE)

  if (minimal) {
    columns <- c("MYEAR", "STATN", "PROJ", "ORDERER", "SHIPC", "SDATE", "STIME",
                 "LATIT", "LONGI", "POSYS", "MNDEP", "MXDEP", "SLABO", "ACKR_SMP",
                 "SMTYP", "SMVOL", "IFCBNO", "SMPNO", "LATNM", "SFLAG", "TRPHY",
                 "IMAGE_VERIFICATION", "VERIFIED_BY", "COUNT", "QFLAG", "COEFF", "CLASS_F1",
                 "UNCLASSIFIED_COUNTS", "METOA", "ASSOCIATED_MEDIA", "CLASSPROG", "TRAINING_SET",
                 "ALABO", "ACKR_ANA", "ANADATE", "METDC", "CLASSIFIER_USED")

    shark_example <- dplyr::select(shark_example, dplyr::all_of(columns))
  }

  # Return empty dataframe
  shark_example[0,]
}
