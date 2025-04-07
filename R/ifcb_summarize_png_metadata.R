#' Summarize PNG Image Metadata
#'
#' This function processes IFCB data by reading images, matching them to the corresponding
#' header and feature files, and joining them into a single dataframe. This function may be
#' useful when preparing metadata files for an EcoTaxa submission.
#'
#' @param png_folder Character. The file path to the folder containing the PNG images.
#' @param feature_folder Character. The file path to the folder containing the feature files (optional).
#' @param hdr_folder Character. The file path to the folder containing the header files (optional).
#'
#' @return A dataframe that joins image data, header data, and feature data based on the sample and roi number.
#'
#' @examples
#' \dontrun{
#' png_folder <- "path/to/pngs"
#' feature_folder <- "path/to/features"
#' hdr_folder <- "path/to/hdr_data"
#' result_df <- ifcb_summarize_png_metadata(png_folder, feature_folder, hdr_folder)
#' }
#'
#' @export
ifcb_summarize_png_metadata <- function(png_folder, feature_folder = NULL, hdr_folder = NULL) {

  # Get list of images and extract sample names
  image_paths <- list.files(png_folder, pattern = "D.*\\.png", recursive = TRUE)

  if (length(image_paths) == 0) {
    stop("No PNG files found in ", png_folder)
  }

  image <- basename(image_paths)
  subfolder <- basename(dirname(image_paths))
  image_df <- data.frame(image, subfolder, ifcb_convert_filenames(image))
  samples <- unique(image_df$sample)

  if (!is.null(hdr_folder)) {
    # List and filter hdr files based on samples
    hdr_files <- list.files(hdr_folder, pattern = "\\.hdr$", recursive = TRUE, full.names = TRUE)

    if (length(hdr_files) == 0) {
      warning("No HDR files found in ", hdr_folder)

      hdr_data <- data.frame(sample = NA, timestamp = NA, date = NA, year = NA,
                             month = NA, day = NA, time = NA, ifcb_number = NA)
    } else {
      hdr_file_names <- tools::file_path_sans_ext(basename(hdr_files))
      hdr_files_selected <- hdr_files[sapply(hdr_file_names, function(file_name) any(grepl(file_name, samples)))]
      hdr_data <- ifcb_read_hdr_data(hdr_files_selected, verbose = FALSE)
    }

  } else {
    hdr_data <- data.frame(sample = NA, timestamp = NA, date = NA, year = NA,
                           month = NA, day = NA, time = NA, ifcb_number = NA)
  }

  if (!is.null(feature_folder)) {
    # List and filter feature files based on samples
    feature_files <- list.files(feature_folder, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)

    if (length(feature_files) == 0) {
      warning("No feature files found in ", feature_folder)

      features_df <- data.frame(sample = NA, roi_number = NA)

    } else {
      feature_file_names <- tools::file_path_sans_ext(basename(feature_files))
      feature_file_names <- sub("(^[^_]+_[^_]+)_.*", "\\1", feature_file_names)
      feature_files_selected <- feature_files[sapply(feature_file_names, function(file_name) any(grepl(file_name, samples)))]
      features <- ifcb_read_features(feature_files_selected, multiblob = FALSE, verbose = FALSE)

      # Combine all features into a single dataframe
      features_df <- bind_rows(lapply(names(features), function(sample_name) {
        extract_features(sample_name, features[[sample_name]])
      }))
    }

  } else {
    features_df <- data.frame(sample = NA, roi_number = NA)
  }

  # Join image_df, hdr_data, and features_df based on 'sample' and 'roi_number'
  joined_df <- image_df %>%
    left_join(hdr_data, by = c("sample", "timestamp", "date", "year", "month", "day", "time", "ifcb_number")) %>%
    left_join(features_df, by = c("sample", "roi" = "roi_number"))

  joined_df
}
