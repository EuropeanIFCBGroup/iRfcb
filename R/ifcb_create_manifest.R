#' Create a MANIFEST.txt File
#'
#' This function generates a MANIFEST.txt file listing all files in a specified folder and its subfolders,
#' along with their sizes in bytes. The function can optionally exclude an existing MANIFEST.txt file from
#' the generated list. A manifest may be useful when archiving images in data repositories.
#'
#' @param folder_path A character string specifying the path to the folder whose files are to be listed.
#' @param manifest_path A character string specifying the path and name of the MANIFEST.txt file to be created. Defaults to "folder_path/MANIFEST.txt".
#' @param exclude_manifest A logical value indicating whether to exclude an existing MANIFEST.txt file from the list. Defaults to TRUE.
#' @return No return value, called for side effects. Creates a MANIFEST.txt file at the specified location.
#' @examples
#' \dontrun{
#' # Create a MANIFEST.txt file for the current directory
#' ifcb_create_manifest(".")
#'
#' # Create a MANIFEST.txt file for a specific directory, excluding an existing MANIFEST.txt file
#' ifcb_create_manifest("path/to/directory")
#'
#' # Create a MANIFEST.txt file and save it to a specific path
#' ifcb_create_manifest("path/to/directory", manifest_path = "path/to/manifest/MANIFEST.txt")
#'
#' # Create a MANIFEST.txt file without excluding an existing MANIFEST.txt file
#' ifcb_create_manifest("path/to/directory", exclude_manifest = FALSE)
#' }
#' @export
ifcb_create_manifest <- function(folder_path, manifest_path = file.path(folder_path, "MANIFEST.txt"), exclude_manifest = TRUE) {
  # Check if manual folder exists
  if (!dir.exists(folder_path)) {
    stop(paste("Folder does not exist:", folder_path))
  }

  # List all files in the folder and subfolders
  files <- list.files(folder_path, recursive = TRUE, full.names = TRUE)

  # Normalize paths to use forward slashes
  files <- normalizePath(files, winslash = "/")

  # Optionally exclude the existing MANIFEST.txt
  if (exclude_manifest) {
    if (file.exists(manifest_path)) {
      manifest_file_path <- normalizePath(manifest_path, winslash = "/")
      files <- files[files != manifest_file_path]
    }
  }

  # Get file sizes
  file_sizes <- file.info(files)$size

  # Create a data frame with filenames and their sizes
  manifest_df <- data.frame(
    file = gsub(paste0(normalizePath(folder_path, winslash = "/"), "/"), "", files, fixed = TRUE),  # Remove the folder path from the file names
    size = file_sizes,
    stringsAsFactors = FALSE
  )

  # Format the file information as "filename [size bytes]"
  manifest_content <- paste0(manifest_df$file, " [", formatC(as.numeric(manifest_df$size), format = "f", big.mark = ",", digits = 0), " bytes]")

  # Create dir if not exists
  if (!dir.exists(dirname(manifest_path))) {
    dir.create(dirname(manifest_path), recursive = TRUE)
  }

  # Write the manifest content to MANIFEST.txt
  writeLines(manifest_content, manifest_path)

  cat("MANIFEST.txt has been created at", manifest_path, "\n")
}
