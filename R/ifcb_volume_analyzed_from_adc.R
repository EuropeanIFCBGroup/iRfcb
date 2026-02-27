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
#' adc_file <- "path/to/IFCB_adc_file.adc"
#' adc_info <- ifcb_volume_analyzed_from_adc(adc_file)
#' print(adc_info$ml_analyzed)
#' }

ifcb_volume_analyzed_from_adc <- function(adc_file) {
  if (!file.exists(adc_file)) {
    stop("ADC file does not exist: ", adc_file)
  }

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
      adc <- read_adc_columns(adc_file[[count]])
    }

    # Access columns by name if available, fallback to position
    adc_time <- if ("ADCtime" %in% names(adc)) adc$ADCtime else adc$V2
    run_time_col <- if ("RunTime" %in% names(adc)) adc$RunTime else adc$V23
    inhibit_time_col <- if ("InhibitTime" %in% names(adc)) adc$InhibitTime else adc$V24

    if (nrow(adc) > 1 && any(inhibit_time_col != 0)) {
      diffinh <- diff(inhibit_time_col)
      iii <- c(1, which(inhibit_time_col[-1] > 0 & diffinh > -0.1 & diffinh < 5) + 1)

      modeinhibittime <- mode(round(diff(inhibit_time_col[iii]), 4))

      runtime_offset <- 0
      inhibittime_offset <- 0

      if (nrow(adc) > 1) {
        runtime_offset_test <- run_time_col[2] - adc_time[2]

        if (runtime_offset_test > 10) {
          runtime_offset <- runtime_offset_test
          inhibittime_offset <- inhibit_time_col[2] + modeinhibittime * 2
        }

        runtime2 <- adc_time[nrow(adc)] + median(run_time_col[seq_len(min(nrow(adc), 50))] - adc_time[seq_len(min(nrow(adc), 50))]) - runtime_offset

        if (abs(runtime - runtime2) > 0.2) {
          runtime[count] <- runtime2
        }
      }

      inhibittime[count] <- inhibit_time_col[nrow(adc)] - inhibittime_offset
      runtime[count] <- run_time_col[nrow(adc)] - runtime_offset

      looktime <- runtime[count] - inhibittime[count]
      ml_analyzed[count] <- flowrate * looktime / 60
    }
  }

  list(ml_analyzed = ml_analyzed, inhibittime = inhibittime, runtime = runtime)
}
