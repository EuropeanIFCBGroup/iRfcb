#' Read and Summarize MATLAB .mat File
#'
#' This function reads a MATLAB .mat file containing summary IFCB (Imaging FlowCytobot) data generated
#' by the `countcells_allTBnew_user_training` function from the [IFCB analysis repository](https://github.com/hsosik/ifcb-analysis/tree/master).
#' It returns a data frame with species counts and optionally biovolume information based on specified thresholds.
#'
#' @param summary_file A character string specifying the path to the .mat summary file.
#' @param biovolume A logical indicating whether to include biovolume data. Default is FALSE.
#' @param threshold A character string specifying the threshold type for counts and biovolume.
#'                  Options are "opt" (default), "adhoc", and "none".
#' @return A data frame containing the summary information including file list, dates,
#'         volume analyzed, species counts, and optionally biovolume.
#' @importFrom R.matlab readMat
#' @export
#' @examples
#' \dontrun{
#' summary_data <- read_summary("path/to/summary_file.mat", biovolume = TRUE, threshold = "opt")
#' print(summary_data)
#' }
read_summary <- function(summary_file, biovolume = FALSE, threshold = "opt") {
  # Read the MATLAB file
  mat <- R.matlab::readMat(summary_file)

  # Extract common fields
  ml_analyzed <- mat$ml.analyzedTB
  mdateTB <- as.Date(mat$mdateTB, origin = "1970-01-01") - 719529
  filelistTB <- unlist(mat$filelistTB)

  # Select class count based on threshold
  classcountTB <- switch(threshold,
                         "opt" = mat$classcountTB.above.optthresh,
                         "adhoc" = mat$classcountTB.above.adhocthresh,
                         "none" = mat$classcountTB,
                         stop("Invalid threshold option. Choose from 'opt', 'adhoc', or 'none'."))

  if (is.null(classcountTB)) {
    stop(paste("Class count data for threshold", threshold, "does not exist in the file."))
  }

  # Extract species names
  class2useTB <- unlist(mat$class2useTB)

  # Assign column names for class counts
  colnames(classcountTB) <- paste("counts", gsub("_", " ", class2useTB), sep = "_")

  # Initialize the summary data frame
  summary <- data.frame(sample = filelistTB,
                        date = mdateTB,
                        ml_analyzed = ml_analyzed,
                        classcountTB)

  # If biovolume is requested, include biovolume data
  if (biovolume) {
    # Select biovolume based on threshold
    classbiovolTB <- switch(threshold,
                            "opt" = mat$classbiovolTB.above.optthresh,
                            "adhoc" = mat$classbiovolTB.above.adhocthresh,
                            "none" = mat$classbiovolTB,
                            stop("Invalid threshold option. Choose from 'opt', 'adhoc', or 'none'."))

    if (is.null(classbiovolTB)) {
      stop(paste("Biovolume data for threshold", threshold, "does not exist in the file."))
    }

    # Assign column names for biovolume
    colnames(classbiovolTB) <- paste("biovolume", gsub("_", " ", class2useTB), sep = "_")

    # Combine biovolume data with summary
    summary <- cbind(summary, classbiovolTB)
  }

  return(summary)
}
