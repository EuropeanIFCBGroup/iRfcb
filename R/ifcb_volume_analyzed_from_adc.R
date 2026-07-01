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
  # Validate existence for local paths only (URLs are read directly below and
  # cannot be checked with file.exists()). Vectorised so multiple files are
  # supported, with all missing paths reported at once.
  is_url <- startsWith(adc_file, "http")
  missing <- adc_file[!is_url & !file.exists(adc_file)]
  if (length(missing) > 0) {
    cli_abort("ADC file{?s} not found: {.file {missing}}")
  }

  flowrate <- 0.25  # milliliters per minute for syringe pump

  if (is.character(adc_file)) {
    adc_file <- as.list(adc_file)
  }

  ml_analyzed <- numeric(length(adc_file))
  inhibittime <- numeric(length(adc_file))
  runtime <- numeric(length(adc_file))

  # The volume analyzed is flowrate * "look time", where look time is the total
  # run time minus the time the instrument's trigger was inhibited (busy capturing
  # a previous image). The ADC file records three relevant clocks per ROI: the ADC
  # timestamp, the cumulative run time, and the cumulative inhibit time. This loop
  # reproduces the correction logic of the MATLAB original
  # (IFCB_volume_analyzed_fromADC), which compensates for instruments whose run/
  # inhibit clocks are offset relative to the ADC timestamp. The magic-number
  # thresholds below are carried over verbatim from that reference implementation.
  for (count in seq_along(adc_file)) {
    if (startsWith(adc_file[[count]], 'http')) {
      adc <- read.csv(adc_file[[count]], header = FALSE)
    } else {
      adc <- read_adc_columns(adc_file[[count]])
    }

    # Access columns by name if available (named via the HDR ADCFileFormat),
    # otherwise fall back to the fixed legacy column positions.
    adc_time <- if ("ADCtime" %in% names(adc)) adc$ADCtime else adc$V2
    run_time_col <- if ("RunTime" %in% names(adc)) adc$RunTime else adc$V23
    inhibit_time_col <- if ("InhibitTime" %in% names(adc)) adc$InhibitTime else adc$V24

    if (nrow(adc) > 1 && any(inhibit_time_col != 0)) {
      # Estimate the typical per-trigger inhibit increment ("dead time" added each
      # time an image is captured). Only well-behaved rows are used: those where
      # the inhibit clock is positive and steps by a small, plausible amount
      # (between -0.1 and 5 s), which excludes spurious jumps from clock glitches.
      diffinh <- diff(inhibit_time_col)
      iii <- c(1, which(inhibit_time_col[-1] > 0 & diffinh > -0.1 & diffinh < 5) + 1)

      modeinhibittime <- mode(round(diff(inhibit_time_col[iii]), 4))

      runtime_offset <- 0
      inhibittime_offset <- 0

      if (nrow(adc) > 1) {
        # Detect a startup offset between the run-time clock and the ADC timestamp.
        # A gap larger than 10 s indicates the run/inhibit clocks were already
        # running before the ADC timestamp started, so subtract that offset below.
        runtime_offset_test <- run_time_col[2] - adc_time[2]

        if (runtime_offset_test > 10) {
          runtime_offset <- runtime_offset_test
          inhibittime_offset <- inhibit_time_col[2] + modeinhibittime * 2
        }

        # Alternative runtime estimate derived from the ADC timestamp plus the
        # median clock offset over the first (up to) 50 rows. Retained from the
        # MATLAB reference; the final runtime below is taken directly from the
        # run-time clock, so this estimate does not change the returned value.
        runtime2 <- adc_time[nrow(adc)] + median(run_time_col[seq_len(min(nrow(adc), 50))] - adc_time[seq_len(min(nrow(adc), 50))]) - runtime_offset

        if (abs(runtime[count] - runtime2) > 0.2) {
          runtime[count] <- runtime2
        }
      }

      # Final run/inhibit times are the last cumulative values, corrected for any
      # detected startup offset.
      inhibittime[count] <- inhibit_time_col[nrow(adc)] - inhibittime_offset
      runtime[count] <- run_time_col[nrow(adc)] - runtime_offset

      looktime <- runtime[count] - inhibittime[count]   # seconds the sample was actually analyzed
      ml_analyzed[count] <- flowrate * looktime / 60     # flowrate is mL/min, hence /60
    }
  }

  list(ml_analyzed = ml_analyzed, inhibittime = inhibittime, runtime = runtime)
}
