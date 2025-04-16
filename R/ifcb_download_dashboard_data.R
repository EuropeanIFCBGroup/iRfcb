utils::globalVariables("status_code")
#' Download IFCB data files from an IFCB Dashboard
#'
#' This function downloads specified IFCB data files from a given IFCB Dashboard URL.
#' It supports optional filename conversion and ADC file adjustments from the old IFCB file format.
#'
#' @details
#' This function can download several files in parallel if the server allows it. The download parameters can be adjusted using the `parallel_downloads`, `sleep_time` and `multi_timeout` arguments.
#'
#' If `convert_filenames = TRUE` `r lifecycle::badge("experimental")`, filenames in the `"IFCBxxx_YYYY_DDD_HHMMSS"` format (used by IFCB1-6)
#' will be converted to `IYYYYMMDDTHHMMSS_IFCBXXX`, ensuring compatibility with blob extraction in `ifcb-analysis` (Sosik & Olson, 2007), which identified the old `.adc` format by the first letter of the filename.
#'
#' If `convert_adc = TRUE` `r lifecycle::badge("experimental")` and `convert_filenames = TRUE` `r lifecycle::badge("experimental")`, the `"IFCBxxx_YYYY_DDD_HHMMSS"` format will instead be converted to
#' `DYYYYMMDDTHHMMSS_IFCBXXX`. Additionally, `.adc` files will be modified to include four empty columns
#' (PMT-A peak, PMT-B peak, PMT-C peak, and PMT-D peak), aligning them with the structure of modern `.adc` files
#' for full compatibility with `ifcb-analysis`.
#'
#' @param dashboard_url Character. The base URL of the IFCB dashboard (e.g., `"https://ifcb-data.whoi.edu"`).
#'                      If no subpath (e.g., `/data/` or `/mvco/`) is included, `/data/` will be added automatically. For the "features" and "autoclass" `file_types`, the dataset name needs to be
#'                      included in the url (e.g. `"https://ifcb-data.whoi.edu/mvco/"`).
#' @param samples Character vector. The IFCB sample identifiers (e.g., `"IFCB1_2014_188_222013"` or `"D20220807T025424_IFCB010"`).
#' @param file_types Character vector. Specifies which file types to download.
#'                   Allowed values: `"blobs"`, `"features"`, `"autoclass"`, `"roi"`, `"zip"`, `"hdr"`, `"adc"`.
#' @param dest_dir Character. The directory where downloaded files will be saved.
#' @param convert_filenames Logical. If `TRUE`, converts filenames of the old format `"IFCBxxx_YYYY_DDD_HHMMSS"`
#'   to the new format (`DYYYYMMDDTHHMMSS_IFCBXXX` or `IYYYYMMDDTHHMMSS_IFCBXXX`). Default is `FALSE`.
#'   `r lifecycle::badge("experimental")`
#' @param convert_adc Logical. If `TRUE`, adjusts `.adc` files from older IFCB instruments
#'   (IFCB1–6, with filenames in the format `"IFCBxxx_YYYY_DDD_HHMMSS"`) by inserting
#'   four empty columns after column 7 to match the newer format. Default is `FALSE`.
#'   `r lifecycle::badge("experimental")`
#' @param parallel_downloads Integer. The number of files to download in parallel per batch.
#'                           This helps manage network load and system performance. Default is `5`.
#' @param sleep_time A numeric value indicating the number of seconds to wait between each batch of downloads. Default is `2`.
#' @param multi_timeout Numeric. The maximum time in seconds that the `curl` multi-download request
#'                      will wait for a response before timing out. This helps prevent
#'                      hanging downloads in case of slow or unresponsive servers. Default is `120` seconds.
#' @param max_retries An integer specifying the maximum number of attempts to retrieve data in case the server is unable to handle the request. Default is 3.
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
#'   dashboard_url = "https://ifcb-data.whoi.edu/mvco/",
#'   samples = "IFCB1_2014_188_222013",
#'   file_types = c("blobs", "autoclass"),
#'   dest_dir = "data",
#'   convert_filenames = FALSE,
#'   convert_adc = FALSE
#' )
#' }
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @export
ifcb_download_dashboard_data <- function(dashboard_url,
                                         samples,
                                         file_types,
                                         dest_dir,
                                         convert_filenames = FALSE,
                                         convert_adc = FALSE,
                                         parallel_downloads = 5,
                                         sleep_time = 2,
                                         multi_timeout = 120,
                                         max_retries = 3,
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

  sample_url <- paste0(dashboard_url, unique(samples))

  for (ext in file_types) {
    file_url <- paste0(sample_url, switch(
      ext,
      blobs = "_blob.zip",
      features = "_features.csv",
      autoclass = "_class_scores.csv",
      paste0(".", ext)  # Default case
    ))

    # Extract the IFCB string
    ifcb_strings <- tools::file_path_sans_ext(basename(sample_url))

    # Initialize date_object as NULL
    date_object <- NA

    # Process ifcb string to extract date
    date_object <- process_ifcb_string(ifcb_strings, quiet)

    ifcb_string_to_convert <- ifcb_strings[!grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)]

    filename <- rep(NA, length(ifcb_strings))

    # Filename creation logic
    if (convert_filenames && !all(is.na(date_object)) && length(ifcb_string_to_convert) > 0) {

      ifcb_string_no_convert <- file_url[grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)]

      filename[grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)] <- basename(ifcb_string_no_convert)

      # Extract the file name part (before the extension)
      ifcb_string <- tools::file_path_sans_ext(basename(file_url[!grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)]))

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
      date_object[!grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)] <- paste0(first_letter, format(as.Date(paste0(year, "-01-01")) + day_of_year - 1, "%Y%m%d"))

      # Map special cases to their corresponding filenames
      file_suffix <- switch(
        ext,
        blobs = "_blob.zip",
        features = "_features.csv",
        autoclass = "_class_scores.csv",
        paste0(".", ext)  # Default case for roi, zip, hdr, adc
      )

      # Construct the filename in the desired format
      filename[!grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)] <- paste0(date_object[!grepl("^D\\d{8}T\\d{6}_IFCB\\d+$", ifcb_strings)], "T", substr(time, 1, 2), substr(time, 3, 4), substr(time, 5, 6), "_", ifcb_number, file_suffix)
    } else {
      filename <- basename(file_url)
    }

    # Set the destination file path
    if (!all(is.na(date_object))) {
      if (convert_filenames & !convert_adc) {
        date_object <- sub("I", "D", date_object)
      }

      if (ext %in% c("features", "autoclass")) {
        destfile <- file.path(dest_dir, filename)
      } else {
        destfile <- file.path(dest_dir, date_object, filename)  # Use date_object with a D as directory
      }
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

      if (ext == "features") {
        # Get the list of existing filenames in the directory
        exisiting_filenames <- list.files(dirname(chunk$destfile), pattern = "\\.csv$")

        # Create a vector of TRUE/FALSE for each file in chunk$filename based on the base name comparison
        existing_files <- sapply(chunk$filename, function(f) {
          # Remove the extension from the filename in chunk$filename
          base_no_ext <- tools::file_path_sans_ext(f)
          # Construct a regex pattern that allows an optional version suffix before .csv
          pattern <- paste0("^", base_no_ext, "(_v\\w+)?\\.csv$")
          any(grepl(pattern, exisiting_filenames))
        })
      } else if (ext == "autoclass") {
        # Get the list of existing filenames in the directory
        exisiting_filenames <- list.files(dirname(chunk$destfile), pattern = "\\.csv$")

        # Create a vector of TRUE/FALSE for each file in chunk$filename based on the base name comparison
        existing_files <- sapply(chunk$filename, function(f) {
          # Remove the extension from the filename in chunk$filename
          base_no_ext <- tools::file_path_sans_ext(f)
          base_no_ext <- sub("_scores", "", base_no_ext)
          # Construct a regex pattern that allows an optional version suffix before .csv
          pattern <- paste0("^", base_no_ext, "(_v\\w+)?\\.csv$")
          any(grepl(pattern, exisiting_filenames))
        })
      } else if (ext == "blobs") {
        # Get the list of existing .zip filenames in the directory
        existing_filenames <- list.files(dirname(chunk$destfile), pattern = "\\.zip$")

        # Check if each file in chunk$filename (without extension) exists as a .zip
        existing_files <- sapply(chunk$filename, function(f) {
          base_no_ext <- tools::file_path_sans_ext(f)
          pattern <- paste0("^", base_no_ext, "(s_v\\w+)?\\.zip$")
          any(grepl(pattern, existing_filenames))
        })
      } else {
        # Remove already existing files *before* iterating over chunk
        existing_files <- file.exists(chunk$destfile)
      }

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

      # Retry logic (max 5 attempts)
      attempt <- 1
      success <- FALSE

      while (attempt <= max_retries && !success) {
        # Perform the download
        res <- curl::multi_download(
          urls = chunk$file_url,
          destfiles = chunk$destfile,
          resume = TRUE,
          multi_timeout = multi_timeout,
          progress = FALSE,
          multiplex = FALSE
        )

        # Extract the relevant portion from the Content-Disposition header and modify the filename
        for (j in seq_len(nrow(res))) {
          # Get the headers for this download
          headers <- res$headers[[j]]

          # Extract the Content-Disposition header
          content_disposition <- headers[grep("Content-Disposition", headers)]

          # If Content-Disposition is found, extract the suffix after '_v'
          if (length(content_disposition) > 0) {
            # Adjust the regex to match both .csv and .zip files
            file_suffix <- str_match(content_disposition, 'filename=.*_v([^\\s;]+)\\.(csv|zip)')[, 2]

            if (!is.na(file_suffix)) {
              # Determine the file extension
              file_ext <- tools::file_ext(res$destfile[j])

              # Construct the new filename by appending '_v' and the extracted suffix to the custom destfile
              custom_destfile <- res$destfile[j]
              if (ext == "blobs") {
                new_destfile <- sub(paste0("\\.", file_ext, "$"), paste0("s_v", file_suffix, ".", file_ext), custom_destfile)
              } else if (ext == "autoclass") {
                custom_destfile <- sub("_scores", "", custom_destfile)
                new_destfile <- sub(paste0("\\.", file_ext, "$"), paste0("_v", file_suffix, ".", file_ext), custom_destfile)
              } else {
                new_destfile <- sub(paste0("\\.", file_ext, "$"), paste0("_v", file_suffix, ".", file_ext), custom_destfile)
              }

              # Rename the file
              file_rename <- file.rename(res$destfile[j], new_destfile)

              # Update the destfile in the result (if needed)
              res$destfile[j] <- new_destfile
            }
          }

          # Check if all downloads were successful
          unsuccessful <- res %>%
            filter(!status_code == 200)

          # Check results
          if (nrow(unsuccessful) == 0) {
            success <- TRUE
          } else {
            # url_df_complete <- dplyr::filter(url_df, basename(dirname(url)) %in% basename(dirname(complete$url)))
            chunk <- dplyr::filter(chunk, file_url %in% unsuccessful$url)

            # Remove partial downloads
            bad_files <- dplyr::filter(res, !status_code == 200)
            if (!is.null(bad_files) && nrow(bad_files) > 0) {
              unlink(bad_files$destfile)
            }

            attempt <- attempt + 1
            # Wait the next attempt
            Sys.sleep(sleep_time)
          }
        }
      }

      # Check for failed downloads
      if (any(!res$status_code == 200, na.rm = TRUE)) {
        warning("Some downloads failed:\n",
                paste(res$url[!res$status_code == 200], collapse = "\n"),
                "\nPlease check the following:\n",
                "1. Verify the URL(s) for any errors or issues.\n",
                "2. Retry the download in case of transient network issues.\n",
                "3. Consider adjusting the `parallel_downloads`, `multi_timeout`, or `sleep_time` parameters to optimize the download process.")
        # Remove partial downloads
        if (!is.null(bad_files) && nrow(bad_files) > 0) {
          unlink(bad_files$destfile)
        }
        unlink(bad_files$destfile)
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

        if (!file.exists(file)) {
          next
        }

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
        }
      }
    }
  }
}
