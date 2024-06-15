#' Estimate Volume Analyzed from IFCB Header File
#'
#' This function reads an IFCB header file to extract sample run time and inhibittime,
#' and returns the associated estimate of sample volume analyzed (in milliliters).
#' The function assumes a standard IFCB configuration with a sample syringe operating
#' at 0.25 mL per minute. For IFCB instruments after 007 and higher (except 008).
#'
#' @param hdrfilename A character vector specifying the path(s) to one or more .hdr files or URLs.
#' @param hdrOnly_flag An optional flag indicating whether to skip ADC file estimation (default is 0).
#' @return A numeric vector containing the estimated sample volume analyzed for each header file.
#' @importFrom utils read.table
#' @importFrom R.matlab readMat
#' @export
#' @examples
#' \dontrun{
#' # Example: Estimate volume analyzed from an IFCB header file
#' hdr_file <- "path/to/IFCB_hdr_file.hdr"
#' ml_analyzed <- IFCB_volume_analyzed(hdr_file)
#' print(ml_analyzed)
#' }
IFCB_volume_analyzed <- function(hdrfilename, hdrOnly_flag = 0) {
  flowrate <- 0.25  # milliliters per minute for syringe pump

  if (is.character(hdrfilename)) {
    hdrfilename <- as.list(hdrfilename)
  }

  ml_analyzed <- rep(NA, length(hdrfilename))

  for (count in seq_along(hdrfilename)) {
    hdr <- IFCBxxx_readhdr(hdrfilename[[count]])
    runtime <- hdr$runtime
    inhibittime <- hdr$inhibittime

    if (!hdrOnly_flag) {
      adcfilename <- sub("\\.hdr$", ".adc", hdrfilename[[count]])
      adc_info <- IFCB_volume_analyzed_fromADC(adcfilename)

      inhibittime_adc <- adc_info$inhibittime
      runtime_adc <- adc_info$runtime

      if ((runtime / runtime_adc < 0.98) || (runtime / runtime_adc > 1.02)) {
        runtime <- runtime_adc
      }
      if ((inhibittime / inhibittime_adc < 0.98) || (inhibittime / inhibittime_adc > 1.02)) {
        inhibittime <- inhibittime_adc
      }
    }

    looktime <- runtime - inhibittime  # seconds
    ml_analyzed[count] <- flowrate * looktime / 60
  }

  return(ml_analyzed)
}
