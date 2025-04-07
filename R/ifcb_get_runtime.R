#' Read IFCB Header File and Extract Runtime Information
#'
#' This function imports an IFCB header file (either from a local path or URL),
#' extracts specific target values such as runtime and inhibittime,
#' and returns them in a structured format (in seconds). This is
#' the R equivalent function of `IFCBxxx_readhdr` from the `ifcb-analysis` repository (Sosik and Olson 2007).
#'
#' @param hdr_file A character string specifying the full path to the .hdr file or URL.
#' @return A list (hdr) containing runtime, inhibittime, and runType (if available) extracted from the header file.
#' @export
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @seealso \url{https://github.com/hsosik/ifcb-analysis}
#' @examples
#' \dontrun{
#' # Example: Read and extract information from an IFCB header file
#' hdr_info <- ifcb_get_runtime("path/to/IFCB_hdr_file.hdr")
#'
#' print(hdr_info)
#' }
ifcb_get_runtime <- function(hdr_file) {
  if (startsWith(hdr_file, "http")) {
    # Fetch the raw content
    response <- curl::curl_fetch_memory(hdr_file, handle = curl::new_handle())

    # Convert raw content to a character vector
    text_content <- rawToChar(response$content)

    # Read lines from the character string
    t <- strsplit(text_content, "\r\n")[[1]]
  } else {
    t <- readLines(hdr_file, warn = FALSE)
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

      eqpos2 <- regexpr('=', linestr)[[1]]
      spos2 <- regexpr('s', linestr)[[1]]
      hdr$inhibittime <- as.numeric(trimws(substr(linestr, eqpos2 + 1, spos2 - 1)))
    }
  }

  ii <- grep('runtype:', t, ignore.case = TRUE)
  if (length(ii) > 0) {
    linestr <- t[ii[length(ii)]]
    colonpos <- regexpr(':', linestr)[[1]]
    hdr$runType <- trimws(substr(linestr, colonpos + 2, nchar(linestr)))
  }

  hdr
}
