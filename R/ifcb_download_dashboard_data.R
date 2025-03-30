#' Download IFCB data files from an IFCB Dashboard
#'
#' This function downloads specified IFCB data files from a given IFCB Dashboard URL.
#' It supports optional filename conversion and ADC file adjustments from the old IFCB file format.
#'
#' @param dashboard_url Character. The base URL of the IFCB dashboard (e.g., `"https://ifcb-data.whoi.edu"`).
#'                      If no subpath (e.g., `/data/` or `/mvco/`) is included, `/data/` will be added automatically.
#' @param samples Character vector. The IFCB sample identifiers (e.g., `"IFCB1_2014_188_222013"` or `"D20220807T025424_IFCB010"`).
#' @param file_types Character vector. Specifies which file types to download.
#'                   Allowed values: `"blobs"`, `"features"`, `"autoclass"`, `"roi"`, `"zip"`, `"hdr"`, `"adc"`.
#' @param dest_dir Character. The directory where downloaded files will be saved.
#' @param convert_filenames Logical. If `TRUE`, converts filenames of the old format `"IFCBxxx_YYYY_DDD_HHMMSS"`
#'   to the new format (`DYYYYMMDDTHHMMSS_IFCBXXX`).
#'   `r lifecycle::badge("experimental")`
#' @param convert_adc Logical. If `TRUE`, adjusts ADC files from older IFCB instruments
#'   (IFCB1–6, with filenames in the format `"IFCBxxx_YYYY_DDD_HHMMSS"`) by inserting
#'   four empty columns after column 7 to match the newer format. Default is `FALSE`.
#'   `r lifecycle::badge("experimental")`
#' @param parallel_downloads Integer. The number of files to download in parallel per batch.
#'                           This helps manage network load and system performance. Default is `10`.
#' @param sleep_time A numeric value indicating the number of seconds to wait between each batch of downloads. Default is `2`.
#' @param multi_timeout Numeric. The maximum time in seconds that the `curl` multi-download request
#'                      will wait for a response before timing out. This helps prevent
#'                      hanging downloads in case of slow or unresponsive servers. Default is `120` seconds.

#' @param quiet Logical. If TRUE, suppresses messages about the progress and completion of the download process. Default is FALSE.
#'
#' @return
#' This function does not return a value. It performs the following actions:
#' - Downloads the requested files into `dest_dir`.
#' - If `convert_adc = TRUE`, modifies ADC files in place by inserting four empty columns after column 7.
#' - Displays messages indicating the download status.
#'
#' @examples
#' \dontrun{
#' ifcb_download_dashboard_data(
#'   dashboard_url = "https://ifcb-data.whoi.edu",
#'   samples = "IFCB1_2014_188_222013",
#'   file_types = c("blobs", "features"),
#'   dest_dir = "data",
#'   convert_filenames = FALSE,
#'   convert_adc = FALSE
#' )
#' }
#'
#' @export
ifcb_download_dashboard_data <- function(dashboard_url,
                                         samples,
                                         file_types,
                                         dest_dir,
                                         convert_filenames = FALSE,
                                         convert_adc = FALSE,
                                         parallel_downloads = 10,
                                         sleep_time = 2,
                                         multi_timeout = 120,
                                         quiet = FALSE) {

  # Remove possible dots from the file_types
  file_types <- gsub("\\.", "", file_types)

  # Remove duplicates
  file_types <- unique(file_types)

  # Define allowed file_types
  allowed_file_types <- c("blobs", "features", "autoclass", "roi", "zip", "hdr", "adc")

  # Check if ext is valid
  if (!all(file_types %in% allowed_file_types)) {  # Ensure all are valid
    stop("Invalid extension(s): ", paste(setdiff(file_types, allowed_file_types), collapse = ", "),
         ". Allowed file types are: ", paste(allowed_file_types, collapse = ", "))
  }

  # Add "/data/" only if there's no path after the domain, and ensure it ends with "/"
  if (!grepl("https?://[^/]+/[^/]", dashboard_url)) {
    dashboard_url <- paste0(sub("/$", "", dashboard_url), "/data/")
  }

  # Ensure the URL ends with "/"
  if (!grepl("/$", dashboard_url)) {
    dashboard_url <- paste0(dashboard_url, "/")
  }

  sample_url <- paste0(dashboard_url, samples)

  for (ext in file_types) {
    file_url <- paste0(sample_url, switch(
      ext,
      blobs = "_blob.zip",
      features = "_features.csv",
      autoclass = "_class_scores.csv",
      paste0(".", ext)  # Default case
    ))

    # Extract the IFCB string
    ifcb_string <- tools::file_path_sans_ext(basename(sample_url))

    # Initialize date_object as NULL
    date_object <- NULL

    # Process ifcb string to extract date
    date_object <- process_ifcb_string(ifcb_string, quiet)

    # Filename creation logic
    if (convert_filenames && !is.null(date_object)) {
      # Extract the file name part (before the extension)
      ifcb_string <- tools::file_path_sans_ext(basename(file_url))

      # Remove "_blob", "_features", "_class_scores" from the string
      ifcb_string <- gsub("_blob", "", ifcb_string)
      ifcb_string <- gsub("_features", "", ifcb_string)
      ifcb_string <- gsub("_class_scores", "", ifcb_string)

      # Extract components using regex
      ifcb_parts <- str_match(ifcb_string, "^(IFCB\\d+)_(\\d{4})_(\\d{3})_(\\d{6})$")

      # Extract year, day of year, and time
      year <- ifcb_parts[,3]
      day_of_year <- as.integer(ifcb_parts[,4])
      time <- ifcb_parts[,5]
      ifcb_number <- ifcb_parts[,2]

      # Convert the initial letter to "D" if convert_adc is TRUE to make data compatible with `ifcb-analysis`
      if (convert_adc) {
        first_letter <- "D"
      } else {
        first_letter <- "I"
      }
      date_object <- paste0(first_letter, format(as.Date(paste0(year, "-01-01")) + day_of_year - 1, "%Y%m%d"))

      # Map special cases to their corresponding filenames
      file_suffix <- switch(
        ext,
        blobs = "_blob.zip",
        features = "_features.csv",
        autoclass = "_class_scores.csv",
        paste0(".", ext)  # Default case for roi, zip, hdr, adc
      )

      # Construct the filename in the desired format: DYYYYMMDD_THHMMSS_IFCB<ifcb_number>_YYYY_DDD_HHMMSS.ext
      filename <- paste0(date_object, "T", substr(time, 1, 2), substr(time, 3, 4), substr(time, 5, 6), "_", ifcb_number, file_suffix)
    } else {
      filename <- basename(file_url)
    }

    # Set the destination file path
    if (!is.null(date_object)) {
      if (convert_filenames & !convert_adc) {
        date_object <- sub("I", "D", date_object)
      }

      destfile <- file.path(dest_dir, date_object, filename)  # Use date_object with a D as directory
    } else {
      destfile <- file.path(dest_dir, filename)  # If no date_object, just the filename
    }

    # Create the destination folder if it doesn't exist
    dir <- sapply(destfile, function(f) dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE))

    file_df <- data.frame(filename, destfile, file_url)

    if (!quiet) message("Downloading ", nrow(file_df), " ", ext, " files")
    if (!quiet) pb <- txtProgressBar(min = 0, max = nrow(file_df), style = 3)

    # Process in chunks
    for (i in seq(1, nrow(file_df), by = parallel_downloads)) {
      chunk <- file_df[i:min(i + parallel_downloads - 1, nrow(file_df)), ]

      # Remove already existing files *before* iterating over chunk
      existing_files <- file.exists(chunk$destfile)

      # Print each skipped file on a separate line
      if (any(existing_files)) {
        if (!quiet) {
          message("\n")
          for (f in chunk$destfile[existing_files]) {
            message("Skipping existing file: ", f)
          }
        }
        chunk <- chunk[!existing_files, ]  # Remove already existing files
      }

      # If no files left to process, skip to the next chunk
      if (nrow(chunk) == 0) next

      # Perform the download
      res <- curl::multi_download(
        urls = chunk$file_url,
        destfiles = chunk$destfile,
        resume = TRUE,
        multi_timeout = multi_timeout,
        progress = FALSE,
        multiplex = FALSE
      )

      # Check for failed downloads
      if (any(!res$success, na.rm = TRUE)) {
        warning("Some downloads failed:\n",
                paste(res$url[!res$success], collapse = "\n"),
                "\nPlease check the following:\n",
                "1. Verify the URL(s) for any errors or issues.\n",
                "2. Retry the download in case of transient network issues.\n",
                "3. Consider adjusting the `parallel_downloads`, `multi_timeout`, or `sleep_time` parameters to optimize the download process.")
      }

      # Wait the next batch of downloads
      Sys.sleep(sleep_time)

      # Update progress bar correctly
      if (!quiet) {
        setTxtProgressBar(pb, min(i + parallel_downloads - 1, nrow(file_df)))
      }
    }

    # Close the progress bar
    if (!quiet) close(pb)

    if (ext == "adc" & convert_adc) {

      for (file in destfile) {
        # Read adc file
        adc_file <- read.csv(file, header = FALSE)

        if (ncol(adc_file) > 16) {
          if (!quiet) {
            message("ADC file already have > 16 columns, does not need to be converted: ", file)
          }
        } else {
          # Insert four empty columns after column 7
          adc_file <- cbind(adc_file[, 1:7], matrix(0, nrow = nrow(adc_file), ncol = 4), adc_file[, 8:ncol(adc_file)])

          # Rename columns to maintain numeric order (optional)
          colnames(adc_file) <- paste0("V", seq_len(ncol(adc_file)))

          # Store new file
          conn <- file(file, "wb")
          write.table(adc_file, conn, sep = ",", row.names = FALSE, col.names = FALSE, na = "", eol = "\n")
          close(conn)

          # Print message
          if (!quiet) {
            message("Adjusted ADC file to new format: ", file)
          }
        }
      }
    }
  }
}
