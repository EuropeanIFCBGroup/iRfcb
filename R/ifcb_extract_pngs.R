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
#' @param gamma A numeric value for gamma correction applied to the image. Default is 1 (no correction). Values <1 brighten dark regions, while values >1 darken the image.
#' @param normalize A logical value indicating whether to apply min-max normalization to stretch pixel values to the full 0-255 range. Default is FALSE, which preserves raw pixel values from the camera, producing images comparable to IFCB Dashboard and other standard IFCB software. Set to TRUE to stretch contrast to the full 0-255 range.
#' @param overwrite A logical value indicating whether to overwrite existing PNG files. Default is FALSE.
#' @param scale_bar_um An optional numeric value specifying the length of the scale bar in micrometers. If NULL, no scale bar is added.
#' @param scale_micron_factor A numeric value defining the conversion factor from micrometers to pixels. Defaults to 1/3.4.
#' @param scale_bar_position A character string specifying the position of the scale bar in the image. Options are `"topright"`, `"topleft"`, `"bottomright"`, or `"bottomleft"`. Defaults to `"bottomright"`.
#' @param scale_bar_color A character string specifying the scale bar color. Options are `"black"` or `"white"`. Defaults to `"black"`.
#' @param old_adc
#'    `r lifecycle::badge("deprecated")`
#'    Previously used to indicate old ADC format. ADC format is now auto-detected
#'    from the HDR file and column count. This parameter is ignored.
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
                              gamma = 1, normalize = FALSE, overwrite = FALSE, scale_bar_um = NULL, scale_micron_factor = 1/3.4,
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

  # Deprecate old_adc parameter (format is now auto-detected)
  if (!missing(old_adc) && old_adc) {
    lifecycle::deprecate_warn("0.8.0", "ifcb_extract_pngs(old_adc)",
                              details = "ADC format is now auto-detected from the HDR file and column count.")
  }

  # Get ADC data for start byte and length of each ROI
  adcfile <- sub("\\.roi$", ".adc", roi_file)
  if (!file.exists(adcfile)) {
    stop("ADC file not found: ", adcfile)
  }
  adcdata <- read_adc_columns(adcfile)
  roi_cols <- adc_get_roi_columns(adcdata)
  x <- roi_cols$x
  y <- roi_cols$y
  startbyte <- roi_cols$startbyte

  if (!is.null(ROInumbers)) {
    invalid_rois <- ROInumbers[ROInumbers < 1 | ROInumbers > nrow(adcdata)]
    if (length(invalid_rois) > 0) {
      stop("ROI number(s) out of range: ", paste(invalid_rois, collapse = ", "),
           ". ADC file contains ", nrow(adcdata), " ROIs.")
    }
    x <- x[ROInumbers]
    y <- y[ROInumbers]
    startbyte <- startbyte[ROInumbers]
  } else {
    ROInumbers <- seq_along(startbyte)
  }

  # Open roi file
  fid <- file(roi_file, "rb")
  on.exit(close(fid), add = TRUE)

  # Track images where the scale bar was skipped
  skipped_scale_bar <- 0

  # Loop over ROIs and save PNG images
  if (verbose) message("Writing ", length(x[x > 0]), " ROIs from ", basename(roi_file), " to ", outpath)
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
          if (normalize) {
            # Normalize pixel values to [0,1] using min-max scaling (stretches to full contrast range)
            img_matrix <- (img_matrix - min(img_matrix)) / (max(img_matrix) - min(img_matrix))
          } else {
            # Preserve raw pixel values by scaling to [0,1] without stretching
            img_matrix <- img_matrix / 255
          }

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

              # Clamp coordinates to image bounds
              bar_x1 <- max(1, bar_x1)
              bar_y1 <- max(1, bar_y1)
              bar_x2 <- min(bar_x2, x[count])
              bar_y2 <- min(bar_y2, y[count])

              # Set scale bar color (black = 0, white = 1)
              scale_bar_value <- ifelse(scale_bar_color == "black", 0, 1)

              # Draw the scale bar directly on the image
              img_matrix[bar_y1:bar_y2, bar_x1:bar_x2] <- scale_bar_value
            }
          }

          # Save using png::writePNG
          png::writePNG(img_matrix, pngfile)
        }, error = function(e) {
          warning("Failed to extract ROI ", num, ": ", conditionMessage(e))
        })
      } else {
        if (verbose) message("PNG file already exists: ", pngfile)
      }
    }
  }

  # Warn if any scale bars were skipped
  if (skipped_scale_bar > 0) {
    warning(paste(skipped_scale_bar, "images were printed without a scale bar because the scale bar was too long for the image."))
  }
}
