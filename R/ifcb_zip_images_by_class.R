#' Zip Image Subfolders by Class
#'
#' This function creates one zip archive per immediate subdirectory in a folder
#' containing image files. Each archive corresponds to a single class or taxon.
#'
#' When `n_images` is specified, images are randomly sampled without replacement
#' from each subdirectory. When `n_images` is NULL, all images in each subdirectory
#' are included.
#'
#' Supported image formats (case-insensitive) are:
#' `png`, `jpg`, `jpeg`, `tif`, `tiff`, `bmp`, and `gif`.
#'
#' @param image_folder The directory containing subdirectories with image files.
#' @param output_dir The directory where the zip archives will be written.
#' @param n_images Integer. Maximum number of images to randomly sample per
#'   subdirectory. If NULL, all images are included.
#' @param quiet Logical. If TRUE, suppresses the progress bar. Default is FALSE.
#'
#' @return This function does not return any value; it creates one zip archive per
#'   subdirectory containing images.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Set a random seed to reproduce the random sampling
#' set.seed(123)
#'
#' # Create zip archives for each subdirectory with up to 50 random images
#' ifcb_zip_images_by_class(
#'   image_folder = "path/to/images",
#'   output_dir = "path/to/zips",
#'   n_images = 50
#' )
#' }
ifcb_zip_images_by_class <- function(
    image_folder,
    output_dir,
    n_images = NULL,
    quiet = FALSE
) {

  if (!dir.exists(image_folder)) {
    stop("Image folder does not exist: ", image_folder)
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  if (!is.null(n_images)) {
    if (!is.numeric(n_images) || length(n_images) != 1 || n_images <= 0) {
      stop("n_images must be a single positive integer or NULL")
    }
    n_images <- as.integer(n_images)
  }

  # Define allowed image extensions
  image_extensions <- c("png", "jpg", "jpeg", "tif", "tiff", "bmp", "gif")
  pattern <- paste0("\\.(", paste(image_extensions, collapse = "|"), ")$", collapse = "")

  subdirs <- list.dirs(image_folder, recursive = FALSE)
  total_subdirs <- length(subdirs)

  if (total_subdirs == 0) {
    message("No subdirectories found in image folder")
    return(invisible(NULL))
  }

  temp_root <- tempdir()

  for (i in seq_along(subdirs)) {

    subdir <- subdirs[i]

    image_files <- list.files(
      subdir,
      pattern = pattern,
      full.names = TRUE,
      ignore.case = TRUE
    )

    if (length(image_files) > 0) {

      if (!is.null(n_images) && length(image_files) > n_images) {
        image_files <- sample(image_files, n_images)
      }

      class_name <- truncate_folder_name(subdir)
      zip_path <- file.path(output_dir, paste0(class_name, ".zip"))

      temp_class_dir <- file.path(temp_root, class_name)
      if (!dir.exists(temp_class_dir)) {
        dir.create(temp_class_dir)
      }

      file.copy(
        from = image_files,
        to = temp_class_dir,
        overwrite = TRUE
      )

      zip::zipr(
        zipfile = zip_path,
        files = temp_class_dir
      )

      unlink(temp_class_dir, recursive = TRUE)
    }

    if (!quiet) {
      print_progress(i, total_subdirs)
    }
  }

  if (!quiet) {
    cat("\n")
  }

  invisible(NULL)
}
