% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_zip_pngs.R
\name{ifcb_zip_pngs}
\alias{ifcb_zip_pngs}
\title{Zip PNG Folders}
\usage{
ifcb_zip_pngs(
  png_folder,
  zip_filename,
  readme_file = NULL,
  email_address = "",
  version = "",
  print_progress = TRUE,
  include_txt = FALSE,
  split_zip = FALSE,
  max_size = 500,
  quiet = FALSE
)
}
\arguments{
\item{png_folder}{The directory containing subdirectories with \code{.png} files.}

\item{zip_filename}{The name of the zip file to create.}

\item{readme_file}{Optional path to a README file for inclusion in the zip package.}

\item{email_address}{Optional email address to include in the README file.}

\item{version}{Optional version information to include in the README file.}

\item{print_progress}{A logical value indicating whether to print progress bar. Default is TRUE.}

\item{include_txt}{A logical value indicating whether to include text (\code{.txt}, \code{.tsv} and \code{.csv}) files located in the subdirectories. Default is FALSE.}

\item{split_zip}{A logical value indicating whether to split the zip file into smaller parts if its size exceeds \code{max_size}. Default is FALSE.}

\item{max_size}{The maximum size (in MB) for the zip file before it gets split. Only used if \code{split_zip} is TRUE. Default is 500 MB.}

\item{quiet}{Logical. If TRUE, suppresses messages about the progress and completion of the zip process. Default is FALSE.}
}
\value{
This function does not return any value; it creates a zip archive and optionally splits it into smaller files if specified.
}
\description{
This function zips directories containing \code{.png} files and optionally includes README and MANIFEST files.
It can also split the resulting zip file into smaller parts if it exceeds a specified size.
The zip archive can be used to submit IFCB data to repositories like in the SMHI IFCB Plankton Image Reference Library (Torstensson et al., 2024).
}
\examples{
\dontrun{
# Zip all subdirectories in the 'images' folder with a README file
ifcb_zip_pngs("path/to/images",
              "images.zip",
              readme_file = system.file("exdata/README-template.md", package = "iRfcb"),
              email_address = "example@example.com",
              version = "1.0")

# Zip all subdirectories in the 'images' folder without a README file
ifcb_zip_pngs("path/to/images", "images.zip")
}

}
\references{
Torstensson, Anders; Skjevik, Ann-Turi; Mohlin, Malin; Karlberg, Maria; Karlson, Bengt (2024). SMHI IFCB Plankton Image Reference Library. SciLifeLab. Dataset. \doi{10.17044/scilifelab.25883455}
}
\seealso{
\code{\link{ifcb_zip_matlab}}
}
