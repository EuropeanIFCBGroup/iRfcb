% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_get_mat_variable.R
\name{ifcb_get_mat_variable}
\alias{ifcb_get_mat_variable}
\title{Get Classes from a MAT File}
\usage{
ifcb_get_mat_variable(
  mat_file,
  variable_name = "class2use",
  use_python = FALSE
)
}
\arguments{
\item{mat_file}{A character string specifying the path to the .mat file containing the class information.}

\item{variable_name}{A character string specifying the variable name in the .mat file that contains the class information.
The default is "class2use". Other examples include "class2use_manual" from a manual file, or "class2use_auto"
for a class list used for automatic assignment. You can find available variable names using the function \code{\link{ifcb_get_mat_names}}.}

\item{use_python}{Logical. If \code{TRUE}, attempts to read the \code{.mat} file using a Python-based method. Default is \code{FALSE}.}
}
\value{
A character vector of class names.
}
\description{
This function reads a specified variable from a .mat file generated by the \code{ifcb-analysis} repository (Sosik and Olson 2007).
It can be used, for example, to extract lists of classes from the file.
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
# Get class names from a class2use file
classes <- ifcb_get_mat_variable("path/to/class2use.mat", "class2use")
print(classes)

# Get class names from a classifier file
class2useTB <- ifcb_get_mat_variable("path/to/classified/sample.mat", "class2useTB")
print(class2useTB)
}

}
\references{
Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
}
\seealso{
\code{\link{ifcb_get_mat_names}} \url{https://github.com/hsosik/ifcb-analysis}
}
