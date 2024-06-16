#' Get Images from ROI File
#'
#' This function reads a .roi file and its corresponding .adc file, extracts specified regions of interest (ROIs),
#' and returns a list of targets containing the ROI images and IDs.
#'
#' @param ROIfile_withpath A character string specifying the path to the .roi file.
#' @param ROInumbers An optional numeric vector specifying the ROI numbers to extract. If NULL, all ROIs with valid dimensions are extracted.
#' @return A list with components:
#'   \item{targetNumber}{Numeric vector of ROI numbers extracted.}
#'   \item{pid}{List of character vectors containing ROI IDs.}
#'   \item{image}{List of matrices containing ROI images.}
#' @examples
#' \dontrun{
#' # Get images from ROI file
#' targets <- ifcb_get_images_from_roi("path/to/ROIfile.roi")
#' print(targets)
#' }
#' @export
ifcb_get_images_from_roi <- function(ROIfile_withpath, ROInumbers = NULL) {
  basedir <- dirname(ROIfile_withpath)
  filename <- tools::file_path_sans_ext(basename(ROIfile_withpath))
  ROIfile <- paste0(filename, ".roi")

  adcfile <- paste0(filename, ".adc")
  adcdata <- read.table(file.path(basedir, adcfile), header = FALSE, sep = ",")
  x <- adcdata$V12
  y <- adcdata$V13
  startbyte <- adcdata$V14

  if (is.null(ROInumbers)) {
    ROInumbers <- which(x > 0)
  }

  fid <- file.path(basedir, ROIfile)
  con <- file(fid, "rb")
  targets <- list()
  targets$targetNumber <- ROInumbers
  targets$pid <- list()
  targets$image <- list()

  for (count in seq_along(ROInumbers)) {
    num <- ROInumbers[count]
    seek(con, where = startbyte[num] - 1)
    img <- readBin(con, what = "raw", n = x[num] * y[num], size = 1)
    targets$image[[count]] <- matrix(unlist(img), nrow = x[num], byrow = TRUE)
    targets$pid[[count]] <- paste0(filename, "_", formatC(num, width = 5, format = "f", flag = "0"))
  }

  close(con)
  return(targets)
}
