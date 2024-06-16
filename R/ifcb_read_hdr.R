#' Read IFCB Header File and Extract Runtime Information
#'
#' This function imports an IFCB header file (either from local path or URL),
#' extracts specific target values such as runtime, inhibittime, and runType,
#' and returns them in a structured format (hdr).
#'
#' @param fullfilename A character string specifying the full path to the .hdr file or URL.
#' @return A list (hdr) containing runtime, inhibittime, and runType (if available) extracted from the header file.
#' @importFrom R.matlab readMat
#' @export
#' @examples
#' \dontrun{
#' # Example: Read and extract information from an IFCB header file
#' hdr_info <- ifcb_read_hdr("path/to/IFCB_hdr_file.hdr")
#' print(hdr_info)
#' }
ifcb_read_hdr <- function(fullfilename) {
  if (startsWith(fullfilename, "http")) {
    t <- readLines(fullfilename, warn = FALSE)
  } else {
    t <- readLines(fullfilename, warn = FALSE)
  }
  t <- tolower(t)

  hdr <- list()

  ii <- grep('runtime:', t, ignore.case = TRUE)
  if (length(ii) > 0) {
    linestr <- t[ii]
    colonpos <- regexpr(':', linestr)[[1]]
    hdr$runtime <- as.numeric(trimws(substr(linestr, colonpos + 1, nchar(linestr))))

    ii <- grep('inhibittime:', t, ignore.case = TRUE)
    if (length(ii) > 0) {
      linestr <- t[ii]
      colonpos <- regexpr(':', linestr)[[1]]
      hdr$inhibittime <- as.numeric(trimws(substr(linestr, colonpos + 1, nchar(linestr))))
    }

    ii <- grep('pmttriggerselection_daq_mcconly:', t, ignore.case = TRUE)
    if (length(ii) > 0) {
      linestr <- t[ii]
      colonpos <- regexpr(':', linestr)[[1]]
      # hdr$PMTtriggerSelection_DAQ_MCConly <- as.numeric(trimws(substr(linestr, colonpos + 1, nchar(linestr))))
    }
  } else {
    ii <- grep('run time', t, ignore.case = TRUE)
    if (length(ii) > 0) {
      linestr <- t[ii]
      eqpos <- regexpr('=', linestr)[[1]]
      spos <- regexpr('s', linestr)[[1]]
      hdr$runtime <- as.numeric(trimws(substr(linestr, eqpos + 1, spos - 1)))

      eqpos2 <- regexpr('=', linestr, fixed = TRUE, after = eqpos + 1)[[1]]
      hdr$inhibittime <- as.numeric(trimws(substr(linestr, eqpos2 + 1, spos2 - 1)))
    }
  }

  ii <- grep('runtype:', t, ignore.case = TRUE)
  if (length(ii) > 0) {
    linestr <- t[ii[length(ii)]]
    colonpos <- regexpr(':', linestr)[[1]]
    hdr$runType <- trimws(substr(linestr, colonpos + 2, nchar(linestr)))
  }

  return(hdr)
}
