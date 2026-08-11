# Most frequent value of `x`, ignoring NA and breaking ties by the smallest
# value - the behaviour of MATLAB's mode(), which the reference implementation
# relies on. Not base::mode(), which reports the storage mode of its argument;
# the previous port called that by mistake, so the offset-correction branch
# below errored with "non-numeric argument" whenever it ran.
stat_mode <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NaN)
  ux <- sort(unique(x))
  ux[which.max(tabulate(match(x, ux)))]
}

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
#' A value is `NA` when it cannot be derived from the file, for example when
#' the ADC lacks the run/inhibit time columns (with a warning) or records no
#' nonzero inhibit time, matching the `NaN` the MATLAB reference returns in
#' those cases.
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

  # NA until computed, matching the NaN-filled vectors the MATLAB reference
  # starts from: a file whose volume cannot be derived must not come back as a
  # measured zero, which downstream is indistinguishable from an instrument
  # that analyzed no water.
  ml_analyzed <- rep(NA_real_, length(adc_file))
  inhibittime <- rep(NA_real_, length(adc_file))
  runtime <- rep(NA_real_, length(adc_file))

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

    # An ADC without the run/inhibit clocks (a short legacy format, or a file
    # with fewer columns than the standard 24) cannot yield a volume. Say so
    # and leave this file's results NA.
    if (is.null(adc_time) || is.null(run_time_col) || is.null(inhibit_time_col)) {
      cli_warn(c(
        "No run/inhibit time columns in {.file {adc_file[[count]]}}.",
        "i" = "{.field ml_analyzed} is {.code NA} for this file."
      ))
      next
    }

    if (nrow(adc) > 1 && any(inhibit_time_col != 0, na.rm = TRUE)) {
      # Estimate the typical per-trigger inhibit increment ("dead time" added each
      # time an image is captured). Only well-behaved rows are used: those where
      # the inhibit clock is positive and steps by a small, plausible amount
      # (between -0.1 and 5 s), which excludes spurious jumps from clock glitches.
      diffinh <- diff(inhibit_time_col)
      iii <- c(1, which(inhibit_time_col[-1] > 0 & diffinh > -0.1 & diffinh < 5) + 1)

      modeinhibittime <- stat_mode(round(diff(inhibit_time_col[iii]), 4))

      runtime_offset <- 0
      inhibittime_offset <- 0

      # Detect a startup offset between the run-time clock and the ADC timestamp.
      # A gap larger than 10 s indicates the run/inhibit clocks were already
      # running before the ADC timestamp started, so subtract that offset below.
      runtime_offset_test <- run_time_col[2] - adc_time[2]

      if (isTRUE(runtime_offset_test > 10)) {
        runtime_offset <- runtime_offset_test
        # Use the second row, since the first is occasionally bad, and add two
        # mode increments to account for that (as the reference does).
        inhibittime_offset <- inhibit_time_col[2] + modeinhibittime * 2
      }

      if (nrow(adc) == length(iii)) {
        # Every row is well-behaved: the last cumulative value is the best
        # estimate.
        inhibittime[count] <- inhibit_time_col[nrow(adc)] - inhibittime_offset
      } else {
        # Corrupt rows present: take the last good row and add one mode
        # increment as the best guess for each bad row, as the reference does.
        inhibittime[count] <- inhibit_time_col[iii[length(iii)]] +
          (nrow(adc) - length(iii)) * modeinhibittime - inhibittime_offset
      }

      runtime[count] <- run_time_col[nrow(adc)] - runtime_offset

      # Alternative runtime estimate from the ADC timestamp plus the median
      # clock offset over the first (up to) 50 rows. The timestamp column is
      # not corrupted in the cases where the run-time column sometimes is
      # towards the file end, so when the two estimates disagree by more than
      # 0.2 s the timestamp-derived one wins.
      n_head <- seq_len(min(nrow(adc), 50))
      runtime2 <- adc_time[nrow(adc)] + median(run_time_col[n_head] - adc_time[n_head]) - runtime_offset
      if (isTRUE(abs(runtime[count] - runtime2) > 0.2)) {
        runtime[count] <- runtime2
      }

      looktime <- runtime[count] - inhibittime[count]   # seconds the sample was actually analyzed
      ml_analyzed[count] <- flowrate * looktime / 60     # flowrate is mL/min, hence /60
    }
  }

  list(ml_analyzed = ml_analyzed, inhibittime = inhibittime, runtime = runtime)
}
