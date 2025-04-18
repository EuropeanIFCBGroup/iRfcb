% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_read_mat.R
\name{ifcb_read_mat}
\alias{ifcb_read_mat}
\title{Read a MATLAB .mat File in R}
\usage{
ifcb_read_mat(file_path)
}
\arguments{
\item{file_path}{A character string representing the full path to the .mat file.}
}
\value{
A list containing the MATLAB variables.
}
\description{
This function reads a MATLAB \code{.mat} file using a Python function via \code{reticulate}.
}
\details{
Python must be installed to use this function. The required python packages can be installed in a virtual environment using \code{ifcb_py_install()}.

This function requires a python interpreter to be installed.
The required python packages can be installed in a virtual environment using \code{ifcb_py_install()}.
}
\examples{
\dontrun{
# Initialize Python environment and install required packages
ifcb_py_install()

# Example .mat file included in the package
mat_file <- system.file("exdata/example.mat", package = "iRfcb")

# Read mat file using Python
data <- ifcb_read_mat(mat_file)
}

}
\seealso{
\code{\link{ifcb_py_install}}
}
