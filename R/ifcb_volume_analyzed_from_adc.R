#' Estimate Volume Analyzed from IFCB ADC File
#'
#' This function reads an IFCB ADC file to extract sample run time and inhibittime,
#' and returns the associated estimate of sample volume analyzed (in milliliters).
#' The function assumes a standard IFCB configuration with a sample syringe operating
#' at 0.25 mL per minute. For IFCB instruments after 007 and higher (except 008).
#'
#' @param adcfilename A character vector specifying the path(s) to one or more .adc files or URLs.
#' @return A list containing:
#'   - ml_analyzed: A numeric vector of estimated sample volume analyzed for each ADC file.
#'   - inhibittime: A numeric vector of inhibittime values extracted from ADC files.
#'   - runtime: A numeric vector of runtime values extracted from ADC files.
#' @importFrom utils read.csv
#' @export
#' @examples
#' \dontrun{
#' # Example: Estimate volume analyzed from an IFCB ADC file
#' adc_file <- "path/to/IFCB_adc_file.csv"
#' adc_info <- ifcb_volume_analyzed_from_adc(adc_file)
#' print(adc_info$ml_analyzed)
#' }

ifcb_volume_analyzed_from_adc <- function(adcfilename) {
  flowrate <- 0.25  # milliliters per minute for syringe pump

  if (is.character(adcfilename)) {
    adcfilename <- as.list(adcfilename)
  }

  ml_analyzed <- numeric(length(adcfilename))
  inhibittime <- numeric(length(adcfilename))
  runtime <- numeric(length(adcfilename))

  for (count in seq_along(adcfilename)) {
    if (startsWith(adcfilename[[count]], 'http')) {
      adc <- read.csv(adcfilename[[count]], header = FALSE)
    } else {
      adc <- read.csv(adcfilename[[count]], header = FALSE)
    }

    # Adjust column indexing based on your ADC file structure
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

        runtime2 <- adc$V2[nrow(adc)] + median(adc$V23[1:min(nrow(adc), 50)] - adc$V2[1:min(nrow(adc), 50)]) - runtime_offset

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

  return(list(ml_analyzed = ml_analyzed, inhibittime = inhibittime, runtime = runtime))
}
