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

  # Modern header format stores values as "runtime: <seconds>" (colon-delimited).
  # Keys are matched at the start of the line, as the MATLAB reference's
  # strmatch() does; a substring match would also hit unrelated keys such as
  # "AdcRunTime:", yielding length-2 values that downstream tibble() calls
  # would recycle into duplicated rows.
  ii <- grep('^\\s*runtime:', t)
  if (length(ii) > 0) {
    linestr <- t[ii[1]]
    colonpos <- regexpr(':', linestr)[[1]]
    hdr$runtime <- as.numeric(trimws(substr(linestr, colonpos + 1, nchar(linestr))))

    ii <- grep('^\\s*inhibittime:', t)
    if (length(ii) > 0) {
      linestr <- t[ii[1]]
      colonpos <- regexpr(':', linestr)[[1]]
      hdr$inhibittime <- as.numeric(trimws(substr(linestr, colonpos + 1, nchar(linestr))))
    }
  } else {
    # Legacy header format stores both values on a single line,
    # "run time = <x> s ... inhibit time = <y> s". The runtime sits between the
    # first "=" and the first "s", the inhibittime between the second "=" and
    # the second "s" - the same positions the MATLAB reference indexes with
    # eqpos(1)/spos(1) and eqpos(2)/spos(2). ("inhibit time" contains no "s",
    # so the second "s" is the inhibittime's unit.)
    ii <- grep('^\\s*run time', t)
    if (length(ii) > 0) {
      linestr <- t[ii[1]]
      eqpos <- gregexpr('=', linestr)[[1]]
      spos <- gregexpr('s', linestr)[[1]]
      if (eqpos[1] > 0 && spos[1] > 0) {
        hdr$runtime <- as.numeric(trimws(substr(linestr, eqpos[1] + 1, spos[1] - 1)))
      }
      if (length(eqpos) >= 2 && length(spos) >= 2) {
        hdr$inhibittime <- as.numeric(trimws(substr(linestr, eqpos[2] + 1, spos[2] - 1)))
      }
    }
  }

  ii <- grep('^\\s*runtype:', t)
  if (length(ii) > 0) {
    # Last entry, matching the reference's "fudge for 2018 IFCB109 cases with
    # two runType entries".
    linestr <- t[ii[length(ii)]]
    colonpos <- regexpr(':', linestr)[[1]]
    hdr$runType <- trimws(substr(linestr, colonpos + 2, nchar(linestr)))
  }

  hdr
}
