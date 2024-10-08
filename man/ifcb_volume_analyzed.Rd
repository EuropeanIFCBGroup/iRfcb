% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_volume_analyzed.R
\name{ifcb_volume_analyzed}
\alias{ifcb_volume_analyzed}
\title{Estimate Volume Analyzed from IFCB Header File}
\usage{
ifcb_volume_analyzed(hdr_file, hdrOnly_flag = FALSE, flowrate = 0.25)
}
\arguments{
\item{hdr_file}{A character vector specifying the path(s) to one or more .hdr files or URLs.}

\item{hdrOnly_flag}{An optional flag indicating whether to skip ADC file estimation (default is FALSE).}

\item{flowrate}{Milliliters per minute for syringe pump (default is 0.25).}
}
\value{
A numeric vector containing the estimated sample volume analyzed for each header file.
}
\description{
This function reads an IFCB header file to extract sample run time and inhibittime,
and returns the associated estimate of sample volume analyzed (in milliliters).
The function assumes a standard IFCB configuration with a sample syringe operating
at 0.25 mL per minute. For IFCB instruments after 007 and higher (except 008). This is
the R equivalent function of \code{IFCB_volume_analyzed} from the \code{ifcb-analysis} repository (Sosik and Olson 2007).
}
\examples{
\dontrun{
# Example: Estimate volume analyzed from an IFCB header file
hdr_file <- "path/to/IFCB_hdr_file.hdr"
ml_analyzed <- ifcb_volume_analyzed(hdr_file)
print(ml_analyzed)
}
}
\references{
Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
}
\seealso{
\url{https://github.com/hsosik/ifcb-analysis}
}
