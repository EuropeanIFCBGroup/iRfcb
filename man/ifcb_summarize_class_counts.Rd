% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_summarize_class_counts.R
\name{ifcb_summarize_class_counts}
\alias{ifcb_summarize_class_counts}
\title{Count Cells from TreeBagger Classifier Output}
\usage{
ifcb_summarize_class_counts(
  classpath_generic,
  hdr_folder,
  year_range,
  use_python = FALSE
)
}
\arguments{
\item{classpath_generic}{Character string specifying the location of the classifier output files.
The path should include 'xxxx' in place of the 4-digit year (e.g., 'classxxxx_v1/').}

\item{hdr_folder}{Character string specifying the directory where the data (hdr files) are located.
This can be a URL for web services or a full path for local files.}

\item{year_range}{Numeric vector specifying the range of years (e.g., 2013:2014) to process.}

\item{use_python}{Logical. If \code{TRUE}, attempts to read the \code{.mat} file using a Python-based method. Default is \code{FALSE}.}
}
\value{
A list containing the following elements:
\item{class2useTB}{Classes used in the TreeBagger classifier.}
\item{classcountTB}{Counts of each class considering each target placed in the winning class.}
\item{classcountTB_above_optthresh}{Counts of each class considering only classifications above the optimal threshold for maximum accuracy.}
\item{ml_analyzedTB}{Volume analyzed for each file.}
\item{mdateTB}{Dates associated with each file.}
\item{filelistTB}{List of files processed.}
\item{classpath_generic}{The generic classpath provided as input.}
\item{classcountTB_above_adhocthresh (optional)}{Counts of each class considering only classifications above the adhoc threshold.}
\item{adhocthresh (optional)}{The adhoc threshold used for classification.}
}
\description{
This function summarizes class results for a series of classifier output files
and returns a summary data list.
}
\details{
If \code{use_python = TRUE}, the function tries to read the \code{.mat} file using \code{ifcb_read_mat()}, which relies on \code{SciPy}.
This approach may be faster than the default approach using \code{R.matlab::readMat()}, especially for large \code{.mat} files.
To enable this functionality, ensure Python is properly configured with the required dependencies.
You can initialize the Python environment and install necessary packages using \code{ifcb_py_install()}.

If \code{use_python = FALSE} or if \code{SciPy} is not available, the function falls back to using \code{R.matlab::readMat()}.
}
\examples{
\dontrun{
ifcb_summarize_class_counts('path/to/class/classxxxx_v1/',
                            'path/to/data/', 2014)
}

}
