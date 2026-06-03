#' Classify All Images in an IFCB Sample Using a Gradio Application
#'
#' Extracts PNG images from an IFCB sample (`.roi` file) using
#' [ifcb_extract_pngs()] into a temporary directory, then classifies each
#' image through a CNN model served by a Gradio application. Per-class F2
#' optimal thresholds are applied automatically. The temporary directory is
#' automatically removed when the function exits.
#'
#' To classify individual pre-extracted PNG files, use [ifcb_classify_images()]
#' directly.
#'
#' @param roi_file A character string specifying the path to the `.roi` file.
#' @param gradio_url A character string specifying the base URL of the Gradio
#'   application. Default is `"https://ifcb.serve.scilifelab.se"`, an instance
#'   hosted on the SciLifeLab Serve platform. A free example Hugging Face Space
#'   is also available at `"https://irfcb-classify.hf.space"` (limited resources,
#'   intended for testing and demonstration). For large-scale or production
#'   classification, deploy your own instance of the classification app
#'   (source code: \url{https://github.com/EuropeanIFCBGroup/ifcb-inference-app})
#'   and pass its URL here.
#' @param top_n An integer specifying the number of top predictions to return
#'   per image. Default is `1` (top prediction only). Use `Inf` to return all
#'   predictions.
#' @param model_name A character string specifying the name of the CNN model
#'   to use for classification. Default is `"SMHI NIVA SYKE SAMS SZN ResNet 50 V6"`. Use
#'   [ifcb_classify_models()] to list all available models.
#' @param verbose A logical value indicating whether to print progress messages.
#'   Default is `TRUE`.
#' @param ... Additional arguments passed to [ifcb_extract_pngs()] (e.g.
#'   `ROInumbers`, `gamma`, `scale_bar_um`).
#'
#' @return A data frame with the following columns:
#'   \describe{
#'     \item{`file_name`}{The PNG file name of the classified image.}
#'     \item{`class_name`}{The predicted class name with per-class thresholds
#'       applied; `"unclassified"` if the score is below the threshold.}
#'     \item{`class_name_auto`}{The winning class name without any threshold
#'       applied (argmax of scores).}
#'     \item{`score`}{The prediction confidence score (0–1).}
#'     \item{`model_name`}{The name of the CNN model used for classification.}
#'   }
#'   Images that could not be classified have `NA` in `class_name`,
#'   `class_name_auto`, and `score`.
#'   When `top_n > 1`, multiple rows are returned per image (one per prediction).
#'
#' @examples
#' \dontrun{
#' # Classify all ROIs in a sample (top prediction per image)
#' result <- ifcb_classify_sample("path/to/D20220522T003051_IFCB134.roi")
#' head(result)
#'
#' # Return top 3 predictions per image
#' result <- ifcb_classify_sample(
#'   "path/to/D20220522T003051_IFCB134.roi",
#'   top_n = 3
#' )
#'
#' # Classify only specific ROI numbers
#' result <- ifcb_classify_sample(
#'   "path/to/D20220522T003051_IFCB134.roi",
#'   ROInumbers = c(1, 5, 10)
#' )
#' }
#'
#' @seealso [ifcb_classify_images()] to classify pre-extracted PNG files
#'   directly. [ifcb_classify_models()] to list available CNN models.
#'   [ifcb_extract_pngs()] to extract PNG images from IFCB ROI files.
#'
#' @export
ifcb_classify_sample <- function(
    roi_file,
    gradio_url = "https://ifcb.serve.scilifelab.se",
    top_n = 1,
    model_name = "SMHI NIVA SYKE SAMS SZN ResNet 50 V6",
    verbose = TRUE,
    ...) {

  if (!file.exists(roi_file)) {
    cli_abort("{.arg roi_file} not found: {.file {roi_file}}")
  }

  gradio_url <- sub("/+$", "", gradio_url)

  # Create a temporary directory for PNG extraction
  sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
  temp_dir <- file.path(tempdir(), paste0("ifcb_classify_", sample_name))
  dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Extract PNG images from the ROI file
  if (verbose) cli_inform("Extracting images from {.file {basename(roi_file)}}")
  ifcb_extract_pngs(roi_file, out_folder = temp_dir, verbose = verbose, ...)

  png_files <- list.files(temp_dir, pattern = "\\.png$", full.names = TRUE,
                          recursive = TRUE)

  if (length(png_files) == 0) {
    cli_warn("No PNG images were extracted from {.file {roi_file}}.")
    return(data.frame(file_name = character(), class_name = character(),
                      class_name_auto = character(),
                      score = numeric(), model_name = character()))
  }

  ifcb_classify_images(png_files, gradio_url = gradio_url, top_n = top_n,
                      model_name = model_name, verbose = verbose)
}
