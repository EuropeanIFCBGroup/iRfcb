#' Zip PNG Folders
#'
#' This function zips directories containing `.png` files and optionally includes README and MANIFEST files.
#' It can also split the resulting zip file into smaller parts if it exceeds a specified size.
#' The zip archive can be used to submit IFCB data to repositories like in the SMHI IFCB Plankton Image Reference Library (Torstensson et al., 2024).
#'
#' @param png_folder The directory containing subdirectories with `.png` files.
#' @param zip_filename The name of the zip file to create.
#' @param readme_file Optional path to a README file for inclusion in the zip package.
#' @param email_address Optional email address to include in the README file.
#' @param version Optional version information to include in the README file.
#' @param print_progress A logical value indicating whether to print progress bar. Default is TRUE.
#' @param include_txt A logical value indicating whether to include text (`.txt`, `.tsv` and `.csv`) files located in the subdirectories. Default is FALSE.
#' @param split_zip A logical value indicating whether to split the zip file into smaller parts if its size exceeds `max_size`. Default is FALSE.
#' @param max_size The maximum size (in MB) for the zip file before it gets split. Only used if `split_zip` is TRUE. Default is 500 MB.
#' @param quiet Logical. If TRUE, suppresses messages about the progress and completion of the zip process. Default is FALSE.
#'
#' @return This function does not return any value; it creates a zip archive and optionally splits it into smaller files if specified.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Zip all subdirectories in the 'images' folder with a README file
#' ifcb_zip_pngs("path/to/images",
#'               "images.zip",
#'               readme_file = system.file("exdata/README-template.md", package = "iRfcb"),
#'               email_address = "example@example.com",
#'               version = "1.0")
#'
#' # Zip all subdirectories in the 'images' folder without a README file
#' ifcb_zip_pngs("path/to/images", "images.zip")
#' }
#'
#' @references
#' Torstensson, Anders; Skjevik, Ann-Turi; Mohlin, Malin; Karlberg, Maria; Karlson, Bengt (2024). SMHI IFCB Plankton Image Reference Library. SciLifeLab. Dataset. \doi{10.17044/scilifelab.25883455}
#'
#' @seealso \code{\link{ifcb_zip_matlab}}
ifcb_zip_pngs <- function(png_folder, zip_filename, readme_file = NULL, email_address = "",
                          version = "", print_progress = TRUE, include_txt = FALSE,
                          split_zip = FALSE, max_size = 500, quiet = FALSE) {

  if (!dir.exists(png_folder)) {
    stop("PNG folder does not exist: ", png_folder)
  }

  if (!is.null(readme_file)) {
    if (!file.exists(readme_file)) {
      stop("README file does not exist: ", readme_file)
    }
  }

  # List all subdirectories in the main directory
  subdirs <- list.dirs(png_folder, recursive = FALSE)

  # Initialize a vector to store directories with .png files
  dirs_to_zip <- character()

  # Total number of subdirectories
  total_subdirs <- length(subdirs)

  # Temporary directory to store renamed folders
  temp_dir <- tempdir()
  temp_subdirs <- character()

  # Iterate over each subdirectory
  for (i in seq_along(subdirs)) {
    # List all files in the subdirectory
    if (include_txt) {
      png_files <- list.files(subdirs[i], pattern = "\\.(png|txt|tsv|csv)$", full.names = TRUE)
    } else {
      png_files <- list.files(subdirs[i], pattern = "\\.png$", full.names = TRUE)
    }

    # If there are any .png files, add the subdirectory to the list
    if (length(png_files) > 0) {
      truncated_name <- truncate_folder_name(subdirs[i]) # Helper function
      temp_subdir <- file.path(temp_dir, truncated_name)
      if (!dir.exists(temp_subdir)) {
        dir.create(temp_subdir)
      }
      file.copy(png_files, temp_subdir, overwrite = TRUE)
      temp_subdirs <- c(temp_subdirs, temp_subdir)
    }

    # Update the progress bar
    if (print_progress & !quiet) {
      print_progress(i, total_subdirs) # Helper function
    }
  }

  # Print a new line after the progress bar is complete
  if (print_progress & !quiet) {
    cat("\n")
  }

  # If readme_file is provided, update it
  if (!is.null(readme_file)) {
    if (!quiet) {
      message("Creating README file...")
    }

    # Read the template README.md content
    readme_content <- readLines(readme_file, encoding = "UTF-8")

    # Get the current date
    current_date <- Sys.Date()

    # Get list of filenames with .png extension
    files <- list.files(png_folder, pattern = "png$", full.names = TRUE, recursive = TRUE)

    # Summarize the number of images by directory
    files_df <- dplyr::tibble(dir = dirname(files)) %>%
      dplyr::count(dir) %>%
      dplyr::mutate(taxa = truncate_folder_name(dir)) %>% # Helper function
      dplyr::arrange(desc(n))

    # Extract dates from file paths and get the years
    dates <- stringr::str_extract(files, "D\\d{8}")
    years <- as.integer(substr(dates, 2, 5))

    # Find the minimum and maximum year
    min_year <- min(years, na.rm = TRUE)
    max_year <- max(years, na.rm = TRUE)

    # Remove suffix from zip-filename, if present
    zip_name <- gsub("_annotated_images.zip|_matlab_files.zip", "", basename(zip_filename))
    zip_name <- gsub(".zip", "", zip_name)

    # Update the README.md template placeholders
    updated_readme <- gsub("<DATE>", current_date, readme_content)
    updated_readme <- gsub("<VERSION>", version, updated_readme)
    updated_readme <- gsub("<E-MAIL>", email_address, updated_readme)
    updated_readme <- gsub("<ZIP_NAME>", zip_name, updated_readme)
    updated_readme <- gsub("<YEAR_START>", min_year, updated_readme)
    updated_readme <- gsub("<YEAR_END>", max_year, updated_readme)
    updated_readme <- gsub("<YEAR>", lubridate::year(current_date), updated_readme)
    updated_readme <- gsub("<N_IMAGES>", formatC(sum(files_df$n), format = "d", big.mark = ","), updated_readme)
    updated_readme <- gsub("<CLASSES>", nrow(files_df), updated_readme)

    # Create the new section for the number of images
    new_section <- c("### Number of images per class", "")
    new_section <- c(new_section, paste0("- ", files_df$taxa, ": ", formatC(files_df$n, format = "d", big.mark = ",")))
    new_section <- c("", new_section)  # Add an empty line before the new section for separation

    # Append the new section to the readme content
    updated_readme <- c(updated_readme, new_section)

    # Write the updated content back to the README.md file
    writeLines(updated_readme, file.path(temp_dir, "README.md"), useBytes = TRUE)
  }

  # If there are directories to zip
  if (length(temp_subdirs) > 0) {
    # Create the zip archive
    files_to_zip <- temp_subdirs

    if (!is.null(readme_file)) {
      # Print message to indicate creating of MANIFEST.txt
      if (!quiet) {
        message("Creating MANIFEST.txt...")
      }

      # Create a manifest for the zip package
      create_package_manifest(files_to_zip, manifest_path = file.path(temp_dir, "MANIFEST.txt"), temp_dir) # Helper function

      files_to_zip <- c(files_to_zip, file.path(temp_dir, "README.md"), file.path(temp_dir, "MANIFEST.txt"))
    }

    # Print message to indicate starting zip creation
    if (!quiet) {
      message("Creating zip archive...")
    }

    if (!dir.exists(dirname(zip_filename))) {
      dir.create(dirname(zip_filename), recursive = TRUE)
    }

    zip::zipr(zipfile = zip_filename, files = files_to_zip)
    if (!quiet) {
      message("Zip archive created successfully: ", normalizePath(zip_filename, winslash = "/"))
    }

    # Check zip file size and split only if necessary
    zip_file_size <- file.info(zip_filename)$size / (1024 * 1024)

    if (split_zip && zip_file_size > max_size) {
      if (!quiet) {
        message(zip_filename, " is larger than ", max_size, " MB. Splitting the zip file into smaller parts...")
      }

      split_large_zip(zip_filename, max_size, quiet)
    }

  } else {
    message("No directories with .png files found.")
  }

  # Clean up temporary directories
  unlink(temp_subdirs, recursive = TRUE)
}
