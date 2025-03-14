#' Estimate Volume Analyzed from IFCB Header File
#'
#' This function reads an IFCB header file to extract sample run time and inhibittime,
#' and returns the associated estimate of sample volume analyzed (in milliliters).
#' The function assumes a standard IFCB configuration with a sample syringe operating
#' at 0.25 mL per minute. For IFCB instruments after 007 and higher (except 008). This is
#' the R equivalent function of `IFCB_volume_analyzed` from the `ifcb-analysis` repository (Sosik and Olson 2007).
#'
#' @param hdr_file A character vector specifying the path(s) to one or more .hdr files or URLs.
#' @param hdrOnly_flag An optional flag indicating whether to skip ADC file estimation (default is FALSE).
#' @param flowrate Milliliters per minute for syringe pump (default is 0.25).
#' @return A numeric vector containing the estimated sample volume analyzed for each header file.
#'
#' @export
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @seealso \url{https://github.com/hsosik/ifcb-analysis}
#' @examples
#' \dontrun{
#' # Example: Estimate volume analyzed from an IFCB header file
#' hdr_file <- "path/to/IFCB_hdr_file.hdr"
#' ml_analyzed <- ifcb_volume_analyzed(hdr_file)
#' print(ml_analyzed)
#' }
ifcb_volume_analyzed <- function(hdr_file, hdrOnly_flag = FALSE, flowrate = 0.25) {

  if (is.character(hdr_file)) {
    hdr_file <- as.list(hdr_file)
  }

  ml_analyzed <- rep(NA, length(hdr_file))

  for (count in seq_along(hdr_file)) {
    if (!file.exists(hdr_file[[count]])) {
      stop(sprintf("Cannot open HDR file '%s': File not found.",hdr_file[[count]]))
    }
    hdr <- ifcb_get_runtime(hdr_file[[count]])
    runtime <- hdr$runtime
    inhibittime <- hdr$inhibittime

    if (!hdrOnly_flag) {
      adcfilename <- sub("\\.hdr$", ".adc", hdr_file[[count]])
      if (!file.exists(adcfilename)) {
        stop(sprintf(
            "Cannot open ADC file '%s': File not found. If you want to proceed without the ADC file for volume estimation, set `hdrOnly_flag = TRUE`.",
            adcfilename))
      }
      adc_info <- ifcb_volume_analyzed_from_adc(adcfilename)

      inhibittime_adc <- adc_info$inhibittime
      runtime_adc <- adc_info$runtime

      if ((runtime / runtime_adc < 0.98) & runtime_adc > 0 || (runtime / runtime_adc > 1.02) & runtime_adc > 0) {
        runtime <- runtime_adc
      }
      if ((inhibittime / inhibittime_adc < 0.98) & inhibittime_adc > 0 || (inhibittime / inhibittime_adc > 1.02) & inhibittime_adc > 0 ) {
        inhibittime <- inhibittime_adc
      }
    }

    looktime <- runtime - inhibittime  # seconds
    ml_analyzed[count] <- flowrate * looktime / 60
  }

  return(ml_analyzed)
}
