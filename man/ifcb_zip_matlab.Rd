% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_zip_matlab.R
\name{ifcb_zip_matlab}
\alias{ifcb_zip_matlab}
\title{Create a Zip Archive of Manual MATLAB Files}
\usage{
ifcb_zip_matlab(
  manual_folder,
  features_folder,
  class2use_file,
  zip_filename,
  data_folder = NULL,
  readme_file = NULL,
  matlab_readme_file = NULL,
  email_address = "",
  version = "",
  print_progress = TRUE,
  feature_recursive = TRUE,
  manual_recursive = FALSE,
  data_recursive = TRUE,
  quiet = FALSE
)
}
\arguments{
\item{manual_folder}{The directory containing \code{.mat} files to be included in the zip archive.}

\item{features_folder}{The directory containing \code{.csv} files, including subfolders, to be included in the zip archive.}

\item{class2use_file}{The path to the file (class2use_file) that will be renamed and included in the 'config' directory of the zip archive.}

\item{zip_filename}{The filename for the zip archive to be created.}

\item{data_folder}{Optionally, the directory containing additional data files (\code{.roi}, \code{.adc}, \code{.hdr}) to be included in the zip archive.}

\item{readme_file}{Optionally, the path to a README file that will be updated with metadata and included in the zip archive.}

\item{matlab_readme_file}{Optionally, the path to a MATLAB README file whose content will be appended to the end of the README file in the zip archive.}

\item{email_address}{The email address to be included in the README file for contact information.}

\item{version}{Optionally, the version number to be included in the README file.}

\item{print_progress}{A logical value indicating whether to print progress bar. Default is TRUE.}

\item{feature_recursive}{Logical. If TRUE, the function will search for feature files recursively within the \code{feature_folder}. Default is TRUE.}

\item{manual_recursive}{Logical. If TRUE, the function will search for MATLAB files recursively within the \code{manual_folder}. Default is FALSE.}

\item{data_recursive}{Logical. If TRUE, the function will search for data files recursively within the \code{data_folder} (if provided). Default is TRUE.}

\item{quiet}{Logical. If TRUE, suppresses messages about the progress and completion of the zip process. Default is FALSE.}
}
\value{
No return value. This function creates a zip archive containing the specified files and directories.
}
\description{
This function creates a zip archive containing specified files and directories for manually
annotated IFCB images, organized into a structured format suitable for distribution or storage.
The MATLAB files are generated by the \code{ifcb-analysis} repository (Sosik and Olson 2007).
The zip archive can be used to submit IFCB data to repositories like in the SMHI IFCB Plankton Image Reference Library (Torstensson et al., 2024).
}
\details{
This function performs the following operations:
\itemize{
\item Lists \code{.mat} files from \code{manual_folder}.
\item Lists \code{.csv} files from \code{features_folder} (including subfolders).
\item Lists \code{.roi}, \code{.adc}, \code{.hdr} files from \code{data_folder} if provided.
\item Copies listed files to temporary directories (\code{manual_dir}, \code{features_dir}, \code{data_dir}, \code{config_dir}).
\item Renames and copies \code{class2use_file} to \code{config_dir} as \code{class2use.mat}.
\item Updates \code{readme_file} with metadata (if provided) and appends PNG image statistics and MATLAB README content.
\item Creates a manifest file (\code{MANIFEST.txt}) listing all files in the zip archive.
\item Creates a zip archive (\code{zip_filename}) containing all copied and updated files.
\item Cleans up temporary directories after creating the zip archive.
}
}
\examples{
\dontrun{
ifcb_zip_matlab("path/to/manual_files", "path/to/feature_files",
                "path/to/class2use.mat", "output_zip_archive.zip",
                data_folder = "path/to/data_files",
                readme_file = system.file("exdata/README-template.md", package = "iRfcb"),
                matlab_readme_file = system.file("inst/exdata/MATLAB-template.md",
                                                 package = "iRfcb"),
                email_address = "example@email.com",
                version = "1.0")
}

}
\references{
Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
Torstensson, Anders; Skjevik, Ann-Turi; Mohlin, Malin; Karlberg, Maria; Karlson, Bengt (2024). SMHI IFCB Plankton Image Reference Library. SciLifeLab. Dataset. \doi{10.17044/scilifelab.25883455}
}
\seealso{
\code{\link{ifcb_zip_pngs}} \url{https://github.com/hsosik/ifcb-analysis}
}
