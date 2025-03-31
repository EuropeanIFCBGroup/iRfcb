#' Download and Prepare WHOI-Plankton Data
#'
#' This function downloads manually annotated images from the WHOI-Plankton dataset (\url{https://hdl.handle.net/1912/7341}) and generates manual
#' classification files in `.mat` format that can be used to train an image classifier using the `ifcb-analysis` MATLAB package (Sosik and Olson 2007).
#'
#' @details
#' The training data prepared from this function can be merged with an existing training dataset using the \code{\link{ifcb_merge_manual}} function.
#' This is a wrapper function for the \code{\link{ifcb_download_whoi_plankton}}, \code{\link{ifcb_download_dashboard_data}} and \code{\link{ifcb_create_empty_manual_file}} functions and used for downloading, processing, and converting IFCB data.
#' Please note that this function downloads and extracts large amounts of data, which can take considerable time.
#'
#' @param years Character vector. Years to download and process. For available years, see \url{https://hdl.handle.net/1912/7341} or \code{\link{ifcb_download_whoi_plankton}}.
#' @param png_folder Character. Directory where `.png` images will be stored.
#' @param raw_folder Character. Directory where raw files (`.adc`, `.hdr`, `.roi`) will be stored.
#' @param manual_folder Character. Directory where manual classification files (`.mat`) will be stored.
#' @param class2use_file Character. File path to `.mat` file to store the list of available classes.
#' @param skip_classes Character vector. Classes to be excluded during processing. For example images, refer to \url{https://whoigit.github.io/whoi-plankton/}.
#' @param dashboard_url Character. URL for the IFCB dashboard data source (default: "https://ifcb-data.whoi.edu/mvco/").
#' @param download_blobs Logical. Whether to download blob files (default: FALSE).
#' @param blobs_folder Character. Directory where blob files will be stored (required if `download_blobs = TRUE`).
#' @param download_features Logical. Whether to download feature files (default: FALSE).
#' @param features_folder Character. Directory where feature files will be stored (required if `download_features = TRUE`).
#' @param parallel_downloads Integer. Number of parallel IFCB Dashboard downloads (default: 10).
#' @param sleep_time Numeric. Seconds to wait between download requests (default: 2).
#' @param multi_timeout Numeric. Timeout for multiple requests in seconds (default: 120).
#' @param convert_filenames Logical. If `TRUE` (default), converts filenames of the old format `"IFCBxxx_YYYY_DDD_HHMMSS"`
#'   to the new format (`DYYYYMMDDTHHMMSS_IFCBXXX`).
#'   `r lifecycle::badge("experimental")`
#' @param convert_adc Logical. If `TRUE` (default), adjusts `.adc` files from older IFCB instruments
#'   (IFCB1–6, with filenames in the format `"IFCBxxx_YYYY_DDD_HHMMSS"`) by inserting
#'   four empty columns after column 7 to match the newer format.
#'   `r lifecycle::badge("experimental")`
#' @param quiet Logical. Suppress messages if TRUE (default: FALSE).
#'
#' @return This function does not return a value but downloads, processes, and stores IFCB data.
#'
#' @seealso \url{https://hdl.handle.net/1912/7341}, \url{https://whoigit.github.io/whoi-plankton/} \code{\link{ifcb_merge_manual}} \code{\link{ifcb_download_whoi_plankton}} \code{\link{ifcb_download_dashboard_data}}
#'
#' @examples
#' \dontrun{
#' # Download and prepare WHOI-Plankton for the years 2013 and 2014
#' ifcb_prepare_whoi_plankton(
#'   years = c("2013", "2014"),
#'   png_folder = "whoi_plankton/png",
#'   raw_folder = "whoi_plankton/raw",
#'   manual_folder = "whoi_plankton/manual",
#'   class2use_file = "whoi_plankton/config/class2use_whoiplankton.mat"
#' )
#' }
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @export
ifcb_prepare_whoi_plankton <- function(years, png_folder, raw_folder, manual_folder, class2use_file,
                                       skip_classes = NULL, dashboard_url = "https://ifcb-data.whoi.edu/mvco/",
                                       download_blobs = FALSE, blobs_folder = NULL,
                                       download_features = FALSE, features_folder = NULL,
                                       parallel_downloads = 10, sleep_time = 2, multi_timeout = 120,
                                       convert_filenames = TRUE, convert_adc = TRUE, quiet = FALSE) {

  # Initialize python check
  check_python_and_module()

  if (download_blobs & is.null(blobs_folder)) {
    stop("`blobs_folder` must be specified when `download_blobs = TRUE`.
       Please provide a valid directory path for `blobs_folder` to store the downloaded files.")
  }

  if (download_features & is.null(features_folder)) {
    stop("`features_folder` must be specified when `download_features = TRUE`.
       Please provide a valid directory path for `features_folder` to store the downloaded files.")
  }

  # Download WHOI-Plankton png images
  ifcb_download_whoi_plankton(years, png_folder, quiet = quiet)

  # Update years with the successful downloads
  years <- basename(list.dirs(png_folder, recursive = FALSE))

  # Download raw files from Dashboard
  for (year in years) {

    # Define paths for current year
    png_path <- file.path(png_folder, year)
    data_path <- file.path(raw_folder, year)

    # List all png files for the current year
    png_files <- list.files(path = png_path, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)

    # Create dataframe with image information
    image_df <- data.frame(year,
                           folder = folder_name <- basename(dirname(png_files)),
                           image = png_files)

    # Remove skipped classes
    if (!is.null(skip_classes)) {
      selected_images <- dplyr::filter(image_df, !folder %in% skip_classes)
    } else {
      selected_images <- image_df
    }

    # Store image data for later use
    write.table(image_df, file.path(png_path, "images.txt"), na = "", sep = "\t", quote = FALSE, row.names = FALSE)

    # Input string
    ifcb_string <- tools::file_path_sans_ext(basename(selected_images$image))

    # Convert the filenames
    sample_df <- ifcb_convert_filenames(ifcb_string)

    # Get the sample names
    samples <- sample_df$sample

    # Download dashboard data
    ifcb_download_dashboard_data(dashboard_url, samples, file_types = c("roi", "adc", "hdr"),
                                 raw_folder, convert_filenames = convert_filenames, convert_adc = convert_adc,
                                 parallel_downloads = parallel_downloads, sleep_time = sleep_time,
                                 multi_timeout = multi_timeout, quiet = quiet)

    if (download_blobs) {
      # Download blobs
      ifcb_download_dashboard_data(dashboard_url, samples, file_types = "blobs",
                                   blobs_folder, convert_filenames = convert_filenames, convert_adc = convert_adc,
                                   parallel_downloads = parallel_downloads, sleep_time = sleep_time,
                                   multi_timeout = multi_timeout, quiet = quiet)
    }

    if (download_features) {
      # Download features
      ifcb_download_dashboard_data(dashboard_url, samples, file_types = "features",
                                   features_folder, convert_filenames = convert_filenames, convert_adc = convert_adc,
                                   parallel_downloads = parallel_downloads, sleep_time = sleep_time,
                                   multi_timeout = multi_timeout, quiet = quiet)
    }
  }

  # List all available classes
  classes <- "unclassified"

  for (year in years) {
    # List all classes from the current year
    classes_year <- basename(list.dirs(file.path(png_folder, year), recursive = FALSE))

    # Add to vector
    classes <- c(classes, classes_year)
  }

  # Use only unique names
  classes <- unique(classes)

  # Remove skipped classes
  classes <- classes[!classes %in% skip_classes]

  # Create a new class2use file
  ifcb_create_class2use(classes, class2use_file)

  # Create manual files year by year
  for (i in seq_along(years)) {

    year <- years[i]

    # List paths to current folders
    png_path <- file.path(png_folder, year)
    data_path <- file.path(raw_folder, year)

    # Read table written earlier
    all_png_images <- read.table(file.path(png_path, "images.txt"), header = TRUE)

    # Get sample info
    sample_info <- ifcb_convert_filenames(basename(all_png_images$image))

    # Extract info to build new filenames
    sample_info <- sample_info %>%
      mutate(
        formatted_roi = sprintf("%05d", roi),  # Ensure roi is a five-digit number
        new_name = paste0("D",
                          format(date, "%Y%m%d"),
                          "T",
                          format(as.POSIXct(time, format="%H:%M:%S"), "%H%M%S"),
                          "_",
                          ifcb_number,
                          "_",
                          formatted_roi,
                          ".png")
      ) %>%
      select(-formatted_roi)

    # Extract sample info for the converted filename
    new_sample_info <- ifcb_convert_filenames(sample_info$new_name)

    # Create a df with new names
    rename_df <- data.frame(class = all_png_images$folder,
                            old_name = all_png_images$image,
                            new_name = paste(dirname(all_png_images$image), sample_info$new_name, sep = "/"),
                            roi = sample_info$roi)
    rename_df$sample <- new_sample_info$sample
    rename_df$class_index <- match(rename_df$class, classes)

    # List the adc files
    adcfiles <- list.files(data_path, pattern = "adc$", full.names = TRUE, recursive = TRUE)

    if (!quiet) message("Creating ", length(unique(rename_df$sample)) , " manual .mat files from year ", year, "...")
    if (!quiet) pb <- txtProgressBar(min = 0, max = length(unique(rename_df$sample)), style = 3)

    # Get unique sample names
    sample_names <- unique(rename_df$sample)

    for (i in seq_along(sample_names)) {

      sample_name <- sample_names[i]

      # Find the path to the ADC file
      adcfile <- adcfiles[grepl(sample_name, adcfiles)]

      # Check if no ADC file was found
      if (length(adcfile) == 0) {
        warning(paste("ADC file not found for sample:", sample_name))
        next
      }

      if (length(adcfile) > 1) {
        # If multiple ADC files are found, use the first one
        adcfile <- adcfile[1]

        warning("More than one .adc found for sample, will continue with: ", adcfile)
      }

      # Read the ADC data
      adcdata <- read.csv(adcfile, header = FALSE, sep = ",")
      rois <- nrow(adcdata)

      rename_sample <- rename_df %>%
        filter(sample == sample_name)

      # Initialize the vector with 1s
      roi_vector <- rep(1, rois)

      # Assign class_index values at the positions given by roi
      roi_vector[rename_sample$roi] <- rename_sample$class_index

      # Create an unclassifed manual file
      ifcb_create_empty_manual_file(roi_length = as.integer(rois),
                                    class2use = as.character(classes),
                                    output_file = file.path(manual_folder, paste0(sample_name, ".mat")),
                                    classlist = as.integer(roi_vector),
                                    do_compression = TRUE)

      # Update progress bar
      if (!quiet) setTxtProgressBar(pb, i)
    }
    # Close the progress bar after the loop finishes
    if (!quiet) close(pb)
  }
}
