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
  print_progress = TRUE
)
}
\arguments{
\item{manual_folder}{The directory containing .mat files to be included in the zip archive.}

\item{features_folder}{The directory containing .csv files, including subfolders, to be included in the zip archive.}

\item{class2use_file}{The path to the file (class2use_file) that will be renamed and included in the 'config' directory of the zip archive.}

\item{zip_filename}{The filename for the zip archive to be created.}

\item{data_folder}{Optionally, the directory containing additional data files (.roi, .adc, .hdr) to be included in the zip archive.}

\item{readme_file}{Optionally, the path to a README file that will be updated with metadata and included in the zip archive.}

\item{matlab_readme_file}{Optionally, the path to a MATLAB README file whose content will be appended to the end of the README file in the zip archive.}

\item{email_address}{The email address to be included in the README file for contact information.}

\item{version}{Optionally, the version number to be included in the README file.}

\item{print_progress}{A logical value indicating whether to print progress bar. Default is TRUE.}
}
\description{
This function creates a zip archive containing specified files and directories for manually
annotated IFCB images, organized into a structured format suitable for distribution or storage.
The MATLAB files are generated by the `ifcb-analysis` repository (Sosik and Olson 2007).
}
\details{
This function performs the following operations:
- Lists .mat files from `manual_folder`.
- Lists .csv files from `features_folder` (including subfolders).
- Lists .roi, .adc, .hdr files from `data_folder` if provided.
- Copies listed files to temporary directories (`manual_dir`, `features_dir`, `data_dir`, `config_dir`).
- Renames and copies `class2use_file` to `config_dir` as `class2use.mat`.
- Updates `readme_file` with metadata (if provided) and appends PNG image statistics and MATLAB README content.
- Creates a manifest file (`MANIFEST.txt`) listing all files in the zip archive.
- Creates a zip archive (`zip_filename`) containing all copied and updated files.
- Cleans up temporary directories after creating the zip archive.
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
}
\seealso{
\code{\link{ifcb_zip_pngs}} \url{https://github.com/hsosik/ifcb-analysis}
}
