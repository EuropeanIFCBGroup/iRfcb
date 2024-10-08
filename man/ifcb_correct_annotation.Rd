% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_correct_annotation.R
\name{ifcb_correct_annotation}
\alias{ifcb_correct_annotation}
\title{Correct Annotations in MATLAB Classlist Files}
\usage{
ifcb_correct_annotation(
  manual_folder,
  out_folder,
  correction_file,
  correct_classid
)
}
\arguments{
\item{manual_folder}{A character string specifying the path to the folder containing the original MAT classlist files to be updated.}

\item{out_folder}{A character string specifying the path to the folder where updated MAT classlist files will be saved.}

\item{correction_file}{A character string specifying the path to the correction file. The correction file should have columns \code{class_folder} and \code{image_filename}, but only \code{image_filename} is used.}

\item{correct_classid}{An integer specifying the class ID to use for corrections.}
}
\value{
This function does not return any value; it updates the classlist files in the specified output directory.
}
\description{
This function corrects annotations in MATLAB classlist files located in a specified manual folder, generated by the code in the \code{ifcb-analysis} repository (Sosik and Olson 2007).
It replaces the class ID of specified regions of interest (ROIs) in the classlist files based on
a correction file.
}
\details{
This function requires a python interpreter to be installed. The required python packages can be installed in a virtual environment using \code{ifcb_py_install}

The correction file is expected to contain at least two columns: \code{class_folder}, which indicates the folder of the class,
and \code{image_filename}, which includes the filenames of the images (with or without additional trailing information).
The function processes each file, corrects the annotations, and saves the updated files in the output folder.

The \code{correction_file} is typically generated using a Shiny app that provides an interactive interface for browsing and managing
IFCB (Imaging FlowCytobot) image galleries. This Shiny app can be initialized using the function \code{ifcb_run_image_gallery()}.
}
\examples{
\dontrun{
# Correct class ID in .mat classlist files
ifcb_correct_annotation("input/manual", "output/manual", "corrections.txt", 99)
}

}
\references{
Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
}
\seealso{
\code{\link{ifcb_py_install}} \url{https://github.com/hsosik/ifcb-analysis}
}
