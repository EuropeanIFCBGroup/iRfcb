#' Estimate Volume Analyzed from IFCB ADC File
#'
#' This function reads an IFCB ADC file to extract sample run time and inhibittime,
#' and returns the associated estimate of sample volume analyzed (in milliliters).
#' The function assumes a standard IFCB configuration with a sample syringe operating
#' at 0.25 mL per minute. For IFCB instruments after 007 and higher (except 008). This is
#' the R equivalent function of `IFCB_volume_analyzed_fromADC` from the `ifcb-analysis repository` (Sosik and Olson 2007).
#'
#' @param adc_file A character vector specifying the path(s) to one or more .adc files or URLs.
#'
#' @return A list containing:
#' \itemize{
#'   \item \strong{ml_analyzed}: A numeric vector of estimated sample volume analyzed for each ADC file.
#'   \item \strong{inhibittime}: A numeric vector of inhibittime values extracted from ADC files.
#'   \item \strong{runtime}: A numeric vector of runtime values extracted from ADC files.
#' }
#'
#' @export
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @seealso \url{https://github.com/hsosik/ifcb-analysis}
#' @examples
#' \dontrun{
#' # Example: Estimate volume analyzed from an IFCB ADC file
#' adc_file <- "path/to/IFCB_adc_file.csv"
#' adc_info <- ifcb_volume_analyzed_from_adc(adc_file)
#' print(adc_info$ml_analyzed)
#' }

ifcb_volume_analyzed_from_adc <- function(adc_file) {
  flowrate <- 0.25  # milliliters per minute for syringe pump

  if (is.character(adc_file)) {
    adc_file <- as.list(adc_file)
  }

  ml_analyzed <- numeric(length(adc_file))
  inhibittime <- numeric(length(adc_file))
  runtime <- numeric(length(adc_file))

  for (count in seq_along(adc_file)) {
    if (startsWith(adc_file[[count]], 'http')) {
      adc <- read.csv(adc_file[[count]], header = FALSE)
    } else {
      adc <- read.csv(adc_file[[count]], header = FALSE)
    }

    if (nrow(adc) > 1 && any(adc$V24 != 0)) {
      diffinh <- diff(adc$V24)
      iii <- c(1, which(adc$V24[-1] > 0 & diffinh > -0.1 & diffinh < 5) + 1)

      modeinhibittime <- mode(round(diff(adc$V24[iii]), 4))

      runtime_offset <- 0
      inhibittime_offset <- 0

      if (nrow(adc) > 1) {
        runtime_offset_test <- adc$V23[2] - adc$V2[2]

        if (runtime_offset_test > 10) {
          runtime_offset <- runtime_offset_test
          inhibittime_offset <- adc$V24[2] + modeinhibittime * 2
        }

        runtime2 <- adc$V2[nrow(adc)] + median(adc$V23[seq_len(min(nrow(adc), 50))] - adc$V2[seq_len(min(nrow(adc), 50))]) - runtime_offset

        if (abs(runtime - runtime2) > 0.2) {
          runtime[count] <- runtime2
        }
      }

      inhibittime[count] <- adc$V24[nrow(adc)] - inhibittime_offset
      runtime[count] <- adc$V23[nrow(adc)] - runtime_offset

      looktime <- runtime[count] - inhibittime[count]
      ml_analyzed[count] <- flowrate * looktime / 60
    }
  }

  list(ml_analyzed = ml_analyzed, inhibittime = inhibittime, runtime = runtime)
}
