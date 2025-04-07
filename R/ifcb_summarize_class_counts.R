#' Count Cells from TreeBagger Classifier Output
#'
#' This function summarizes class results for a series of classifier output files
#' and returns a summary data list.
#'
#' @param classpath_generic Character string specifying the location of the classifier output files.
#'                          The path should include 'xxxx' in place of the 4-digit year (e.g., 'classxxxx_v1/').
#' @param hdr_folder Character string specifying the directory where the data (hdr files) are located.
#'                   This can be a URL for web services or a full path for local files.
#' @param year_range Numeric vector specifying the range of years (e.g., 2013:2014) to process.
#' @param use_python Logical. If `TRUE`, attempts to read the `.mat` file using a Python-based method. Default is `FALSE`.
#'
#' @return A list containing the following elements:
#'   \item{class2useTB}{Classes used in the TreeBagger classifier.}
#'   \item{classcountTB}{Counts of each class considering each target placed in the winning class.}
#'   \item{classcountTB_above_optthresh}{Counts of each class considering only classifications above the optimal threshold for maximum accuracy.}
#'   \item{ml_analyzedTB}{Volume analyzed for each file.}
#'   \item{mdateTB}{Dates associated with each file.}
#'   \item{filelistTB}{List of files processed.}
#'   \item{classpath_generic}{The generic classpath provided as input.}
#'   \item{classcountTB_above_adhocthresh (optional)}{Counts of each class considering only classifications above the adhoc threshold.}
#'   \item{adhocthresh (optional)}{The adhoc threshold used for classification.}
#'
#' @details
#' If `use_python = TRUE`, the function tries to read the `.mat` file using `ifcb_read_mat()`, which relies on `SciPy`.
#' This approach may be faster than the default approach using `R.matlab::readMat()`, especially for large `.mat` files.
#' To enable this functionality, ensure Python is properly configured with the required dependencies.
#' You can initialize the Python environment and install necessary packages using `ifcb_py_install()`.
#'
#' If `use_python = FALSE` or if `SciPy` is not available, the function falls back to using `R.matlab::readMat()`.
#'
#' @examples
#' \dontrun{
#' ifcb_summarize_class_counts('path/to/class/classxxxx_v1/',
#'                             'path/to/data/', 2014)
#' }
#'
#' @export
ifcb_summarize_class_counts <- function(classpath_generic, hdr_folder, year_range, use_python = FALSE) {
  # Check whether hdr_folder is a URL
  urlflag <- FALSE
  if (startsWith(hdr_folder, "http")) {
    urlflag <- TRUE
  }

  # Ensure input paths end with file separator
  if (!endsWith(classpath_generic, .Platform$file.sep)) {
    classpath_generic <- paste0(classpath_generic, .Platform$file.sep)
  }
  if (!endsWith(hdr_folder, .Platform$file.sep) && !urlflag) {
    hdr_folder <- paste0(hdr_folder, .Platform$file.sep)
  }

  path_out <- file.path(gsub("classxxxx_v1/", "", classpath_generic), "summary", .Platform$file.sep)

  classfiles <- NULL
  filelist <- NULL

  for (yr in year_range) {
    classpath <- gsub("xxxx", as.character(yr), classpath_generic)
    temp <- list.files(classpath, pattern = "D.*\\.mat", full.names = TRUE)
    if (length(temp) > 0) {
      classfiles <- c(classfiles, temp)
      filelist <- c(filelist, substr(basename(temp), 1, 24))
    }
  }

  if (urlflag) {
    hdrfiles <- paste0(hdr_folder, filelist, ".hdr")
  } else {
    if (file.exists(file.path(hdr_folder, paste0(filelist[1], ".hdr")))) {
      hdrfiles <- file.path(hdr_folder, paste0(filelist, ".hdr"))
    } else if (file.exists(file.path(hdr_folder, substr(filelist[1], 2, 5), paste0(filelist[1], ".hdr")))) {
      hdrfiles <- file.path(hdr_folder, substr(filelist, 2, 5), paste0(filelist, ".hdr"))
    } else if (file.exists(file.path(hdr_folder, substr(filelist[1], 2, 5), substr(filelist[1], 1, 9), paste0(filelist[1], ".hdr")))) {
      hdrfiles <- file.path(hdr_folder, substr(filelist, 2, 5), substr(filelist, 1, 9), paste0(filelist, ".hdr"))
    } else {
      stop("First hdr file not found. Check input directory.")
    }
  }

  mdate <- sapply(filelist, function(f) { ymd_hms(gsub("T", "", substr(f, 2, 16)), tz = "UTC") })

  # Load the first class file to get class2useTB
  if (use_python && scipy_available()) {
    temp <- ifcb_read_mat(classfiles[1])
  } else {
    # Read the contents of the MAT file
    temp <- read_mat(classfiles[1])
  }
  class2use <- temp$class2useTB
  classcount <- matrix(NA, nrow = length(classfiles), ncol = length(class2use))
  classcount_above_optthresh <- classcount
  classcount_above_adhocthresh <- classcount
  ml_analyzed <- rep(NA, length(classfiles))
  adhocthresh <- rep(0.5, length(class2use))

  for (filecount in seq_along(classfiles)) {
    if (filecount %% 10 == 0) {
      cat("reading", filecount, "of", length(classfiles), "\n")
    }
    ml_analyzed[filecount] <- ifcb_volume_analyzed(hdrfiles[filecount])
    if (exists("adhocthresh")) {
      res <- summarize_TBclass(classfiles[filecount], adhocthresh)
      classcount[filecount,] <- res[[1]]
      classcount_above_optthresh[filecount,] <- res[[2]]
      classcount_above_adhocthresh[filecount,] <- res[[3]]
    } else {
      res <- summarize_TBclass(classfiles[filecount])
      classcount[filecount,] <- res[[1]]
      classcount_above_optthresh[filecount,] <- res[[2]]
    }
  }

  if (!dir.exists(path_out)) {
    dir.create(path_out, recursive = TRUE)
  }

  year_rangestr <- as.character(year_range[1])
  if (length(year_range) > 1) {
    year_rangestr <- paste0(year_rangestr, "_", as.character(year_range[length(year_range)]))
  }

  summary_data <- list(
    class2useTB = class2use,
    classcountTB = classcount,
    classcountTB_above_optthresh = classcount_above_optthresh,
    ml_analyzedTB = ml_analyzed,
    mdateTB = mdate,
    filelistTB = filelist,
    classpath_generic = classpath_generic
  )

  if (exists("adhocthresh")) {
    summary_data$classcountTB_above_adhocthresh <- classcount_above_adhocthresh
    summary_data$adhocthresh <- adhocthresh
  }

  summary_data
}
