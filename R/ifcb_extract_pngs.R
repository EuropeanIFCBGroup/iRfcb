#' Extract Images from IFCB ROI File
#'
#' This function reads an IFCB (`.roi`) file and its corresponding `.adc` file, extracts regions of interest (ROIs),
#' and saves each ROI as a PNG image in a specified directory. Optionally, you can specify ROI numbers
#' to extract, useful for specific ROIs from manual or automatic classification results. Additionally, a scale bar
#' can be added to the extracted images based on a specified micron-to-pixel conversion factor.
#'
#' @param roi_file A character string specifying the path to the `.roi` file.
#' @param out_folder A character string specifying the directory where the PNG images will be saved. Defaults to the directory of the ROI file.
#' @param ROInumbers An optional numeric vector specifying the ROI numbers to extract. If NULL, all ROIs with valid dimensions are extracted.
#' @param taxaname An optional character string specifying the taxa name for organizing images into subdirectories. Defaults to NULL.
#' @param gamma A numeric value for gamma correction applied to the image. Default is 1 (no correction). Values <1 increase contrast in dark regions, while values >1 decrease contrast.
#' @param overwrite A logical value indicating whether to overwrite existing PNG files. Default is FALSE.
#' @param scale_bar_um An optional numeric value specifying the length of the scale bar in micrometers. If NULL, no scale bar is added.
#' @param scale_micron_factor A numeric value defining the conversion factor from micrometers to pixels. Defaults to 1/3.4.
#' @param scale_bar_position A character string specifying the position of the scale bar in the image. Options are `"topright"`, `"topleft"`, `"bottomright"`, or `"bottomleft"`. Defaults to `"bottomright"`.
#' @param scale_bar_color A character string specifying the scale bar color. Options are `"black"` or `"white"`. Defaults to `"black"`.
#' @param old_adc A logical value indicating whether the `adc` file is of the old format (samples from IFCB1-6, labeled "IFCBxxx_YYYY_DDD_HHMMSS"). Default is FALSE.
#' @param verbose A logical value indicating whether to print progress messages. Default is TRUE.
#'
#' @return This function is called for its side effects: it writes PNG images to a directory.
#'
#' @examples
#' \dontrun{
#' # Convert ROI file to PNG images
#' ifcb_extract_pngs("path/to/your_roi_file.roi")
#'
#' # Extract specific ROI numbers from ROI file
#' ifcb_extract_pngs("path/to/your_roi_file.roi", "output_directory", ROInumbers = c(1, 2, 3))
#'
#' # Extract images with a 5 micrometer scale bar
#' ifcb_extract_pngs("path/to/your_roi_file.roi", scale_bar_um = 5)
#' }
#' @export
#' @seealso \code{\link{ifcb_extract_classified_images}} for extracting ROIs from automatic classification.
#' @seealso \code{\link{ifcb_extract_annotated_images}} for extracting ROIs from manual annotation.
ifcb_extract_pngs <- function(roi_file, out_folder = dirname(roi_file), ROInumbers = NULL, taxaname = NULL,
                              gamma = 1, overwrite = FALSE, scale_bar_um = NULL, scale_micron_factor = 1/3.4,
                              scale_bar_position = "bottomright", scale_bar_color = "black", old_adc = FALSE,
                              verbose = TRUE) {

  # Ensure roi_file has .roi extension
  if (!grepl("\\.roi$", roi_file, ignore.case = TRUE)) {
    roi_file <- paste0(roi_file, ".roi")
  }

  if (!file.exists(roi_file)) {
    stop("ROI file does not exist: ", roi_file)
  }

  # Valid positions for scale bar
  valid_positions <- c("topright", "topleft", "bottomright", "bottomleft")
  if (!(scale_bar_position %in% valid_positions)) {
    stop("Invalid scale_bar_position. Choose from 'topright', 'topleft', 'bottomright', 'bottomleft'.")
  }

  # Valid scale bar colors
  valid_colors <- c("black", "white")
  if (!(scale_bar_color %in% valid_colors)) {
    stop("Invalid scale_bar_color. Choose 'black' or 'white'.")
  }

  # Create output directory if needed
  if (!is.null(taxaname)) {
    outpath <- file.path(out_folder, taxaname)
  } else {
    outpath <- file.path(out_folder, tools::file_path_sans_ext(basename(roi_file)))
  }
  dir.create(outpath, showWarnings = FALSE, recursive = TRUE)

  # Get ADC data for start byte and length of each ROI
  adcfile <- sub("\\.roi$", ".adc", roi_file)
  adcdata <- read.csv(adcfile, header = FALSE, sep = ",")
  x <- as.numeric(if (old_adc) adcdata$V12 else adcdata$V16)
  y <- as.numeric(if (old_adc) adcdata$V13 else adcdata$V17)
  startbyte <- as.numeric(if (old_adc) adcdata$V14 else adcdata$V18)

  if (!is.null(ROInumbers)) {
    adcdata <- adcdata[ROInumbers,]
    x <- as.numeric(if (old_adc) adcdata$V12 else adcdata$V16)
    y <- as.numeric(if (old_adc) adcdata$V13 else adcdata$V17)
    startbyte <- as.numeric(if (old_adc) adcdata$V14 else adcdata$V18)
  } else {
    ROInumbers <- seq_along(startbyte)
  }

  # Open roi file
  tryCatch({
    fid <- file(roi_file, "rb")
  }, error = function(e) {
    cat("An error occurred:", conditionMessage(e), "\n")
    NULL
  })

  # Track images where the scale bar was skipped
  skipped_scale_bar <- 0

  # Loop over ROIs and save PNG images
  if (verbose) cat(paste("Writing", length(x[x > 0]), "ROIs from", basename(roi_file), "to", outpath), "\n")
  for (count in seq_along(ROInumbers)) {
    if (x[count] > 0) {
      num <- ROInumbers[count]
      pngname <- paste0(tools::file_path_sans_ext(basename(roi_file)), "_", sprintf("%05d", num), ".png")
      pngfile <- file.path(outpath, pngname)

      if (!file.exists(pngfile) || overwrite) {
        seek(fid, startbyte[count])
        img_data <- readBin(fid, raw(), n = x[count] * y[count])  # Read img pixels as raw
        img_matrix <- matrix(as.integer(img_data), ncol = x[count], byrow = TRUE)  # Reshape to original x-y array

        tryCatch({
          # Normalize pixel values to [0,1] using min-max scaling
          img_matrix <- (img_matrix - min(img_matrix)) / (max(img_matrix) - min(img_matrix))

          # Apply gamma correction only if gamma != 1
          if (gamma != 1) {
            img_matrix <- img_matrix^gamma
          }

          # Add scale bar if requested
          if (!is.null(scale_bar_um) && !is.null(scale_micron_factor)) {
            scale_bar_px <- round(scale_bar_um / scale_micron_factor, 0)  # Convert micrometer to pixels

            # Skip adding the scale bar if it's too long for the image
            if (scale_bar_px >= x[count]) {
              skipped_scale_bar <- skipped_scale_bar + 1
            } else {
              bar_height <- max(2, round(0.02 * y[count]))  # 2% of image height

              # Determine position based on user input
              if (scale_bar_position == "bottomright") {
                bar_x1 <- x[count] - scale_bar_px - 4
                bar_y1 <- y[count] - bar_height - 3
              } else if (scale_bar_position == "bottomleft") {
                bar_x1 <- 4
                bar_y1 <- y[count] - bar_height - 3
              } else if (scale_bar_position == "topright") {
                bar_x1 <- x[count] - scale_bar_px - 4
                bar_y1 <- 4
              } else if (scale_bar_position == "topleft") {
                bar_x1 <- 4
                bar_y1 <- 4
              }

              bar_x2 <- bar_x1 + scale_bar_px
              bar_y2 <- bar_y1 + bar_height

              # Set scale bar color (black = 0, white = 1)
              scale_bar_value <- ifelse(scale_bar_color == "black", 0, 1)

              # Draw the black scale bar directly on the image
              img_matrix[bar_y1:bar_y2, bar_x1:bar_x2] <- scale_bar_value
            }
          }

          # Save using png::writePNG
          png::writePNG(img_matrix, pngfile)
        }, error = function(e) {
          cat("An error occurred:", conditionMessage(e), "\n")
        })
      } else {
        if (verbose) cat("PNG file already exists:", pngfile, "\n")
      }
    }
  }

  # Close the roi file
  close(fid)

  # Warn if any scale bars were skipped
  if (skipped_scale_bar > 0) {
    warning(paste(skipped_scale_bar, "images were printed without a scale bar because the scale bar was too long for the image."))
  }
}
