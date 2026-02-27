utils::globalVariables("save_classification_mat")
#' Classify an IFCB Sample and Save Results
#'
#' Extracts PNG images from an IFCB `.roi` file, classifies each image via the
#' Gradio API `predict_scores` endpoint (returning all class scores), fetches
#' per-class thresholds, and writes the results in the specified format.
#'
#' Three output formats are supported:
#' \describe{
#'   \item{`"h5"`}{IFCB Dashboard class_scores v3 HDF5 format. Contains `output_scores`,
#'     `class_labels`, `roi_numbers` (Dashboard-required), plus
#'     `classifier_name`, `class_name`, `class_name_auto`, and `thresholds`.
#'     Requires the \pkg{hdf5r} package.}
#'   \item{`"mat"`}{IFCB Dashboard class_scores v1 MATLAB format. Contains `class2useTB`,
#'     `TBscores`, `roinum`, `TBclass`, `TBclass_above_threshold`, and
#'     `classifierName`. Requires Python with \pkg{scipy} and \pkg{numpy}.}
#'   \item{`"csv"`}{`ClassiPyR`-compatible CSV format with columns `file_name`,
#'     `class_name` (threshold-applied), `class_name_auto` (winning class
#'     without threshold), and `score` (winning class confidence). See
#'     \url{https://github.com/EuropeanIFCBGroup/ClassiPyR} for details.}
#' }
#'
#' @param roi_file A character string specifying the path to the `.roi` file.
#' @param output_folder A character string specifying the directory where the
#'   output file will be saved. The file is named automatically based on
#'   the sample name (e.g. `D20220522T003051_IFCB134_class.h5`,
#'   `D20220522T003051_IFCB134_class_v1.mat`, or
#'   `D20220522T003051_IFCB134.csv`).
#' @param format A character string specifying the output format. One of
#'   `"h5"` (default), `"mat"`, or `"csv"`.
#' @param gradio_url A character string specifying the base URL of the Gradio
#'   application. Default is `"https://irfcb-classify.hf.space"`, which is an
#'   example Hugging Face Space with limited resources intended for testing and
#'   demonstration. For large-scale classification, deploy your own instance of
#'   the classification app (source code:
#'   \url{https://github.com/EuropeanIFCBGroup/ifcb-inference-app}) and
#'   pass its URL here.
#' @param model_name A character string specifying the name of the CNN model
#'   to use for classification. Default is `"SMHI NIVA ResNet50 V5"`. Use
#'   [ifcb_classify_models()] to list all available models.
#' @param verbose A logical value indicating whether to print progress messages.
#'   Default is `TRUE`.
#' @param ... Additional arguments passed to [ifcb_extract_pngs()] (e.g.
#'   `ROInumbers`, `gamma`).
#'
#' @return The path to the saved file (invisibly).
#'
#' @examples
#' \dontrun{
#' # Classify a sample and save as HDF5 (default)
#' ifcb_save_classification(
#'   "path/to/D20220522T003051_IFCB134.roi",
#'   output_folder = "output"
#' )
#'
#' # Save as Dashboard v1 .mat format
#' ifcb_save_classification(
#'   "path/to/D20220522T003051_IFCB134.roi",
#'   output_folder = "output",
#'   format = "mat"
#' )
#'
#' # Save as CSV
#' ifcb_save_classification(
#'   "path/to/D20220522T003051_IFCB134.roi",
#'   output_folder = "output",
#'   format = "csv"
#' )
#' }
#'
#' @seealso [ifcb_classify_images()], [ifcb_classify_sample()],
#'   [ifcb_classify_models()]
#'
#' @export
ifcb_save_classification <- function(
    roi_file,
    output_folder,
    format = c("h5", "mat", "csv"),
    gradio_url = "https://irfcb-classify.hf.space",
    model_name = "SMHI NIVA ResNet50 V5",
    verbose = TRUE,
    ...) {

  format <- match.arg(format)

  if (format == "h5" && !requireNamespace("hdf5r", quietly = TRUE)) {
    stop("Package 'hdf5r' is required for format = \"h5\". ",
         "Install it with: install.packages('hdf5r')")
  }

  if (format == "mat") {
    check_python_and_module(c("scipy", "numpy"))
  }

  if (!file.exists(roi_file)) {
    stop("roi_file not found: ", roi_file)
  }

  gradio_url <- sub("/+$", "", gradio_url)

  # Derive output path from sample name
  sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
  output_path <- switch(format,
    h5  = file.path(output_folder, paste0(sample_name, "_class.h5")),
    mat = file.path(output_folder, paste0(sample_name, "_class_v1.mat")),
    csv = file.path(output_folder, paste0(sample_name, ".csv"))
  )

  # Extract PNGs to temp dir
  temp_dir <- file.path(tempdir(), paste0("ifcb_save_", sample_name))
  dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  if (verbose) message("Extracting images from: ", basename(roi_file))
  ifcb_extract_pngs(roi_file, out_folder = temp_dir, verbose = verbose, ...)

  png_files <- list.files(temp_dir, pattern = "\\.png$", full.names = TRUE,
                          recursive = TRUE)

  if (length(png_files) == 0) {
    stop("No PNG images were extracted from: ", roi_file)
  }

  # Extract ROI numbers from filenames (e.g. D20220522T003051_IFCB134_00001.png -> 1)
  roi_numbers <- as.integer(
    sub(".*_(\\d+)\\.png$", "\\1", basename(png_files))
  )

  # Classify each image via predict_scores endpoint
  n_images <- length(png_files)
  if (verbose) message("Classifying ", n_images, " image(s) via predict_scores...")

  scores_list <- vector("list", n_images)
  class_labels <- NULL

  for (i in seq_len(n_images)) {
    if (verbose) print_progress(i, n_images)

    server_path <- gradio_upload_file(png_files[i], gradio_url)
    image_data <- list(
      path = server_path,
      meta = list(`_type` = "gradio.FileData")
    )

    result <- gradio_predict_scores(gradio_url, image_data, model_name)

    if (is.null(class_labels)) {
      class_labels <- result$class_labels
    }

    scores_list[[i]] <- result$scores
  }

  if (verbose) cat("\n")

  # Build score matrix (N x C)
  score_matrix <- do.call(rbind, scores_list)

  # Fetch thresholds
  if (verbose) message("Fetching per-class thresholds...")
  threshold_info <- gradio_get_thresholds(gradio_url, model_name)
  thresholds_vec <- vapply(class_labels, function(cls) {
    thr <- threshold_info$thresholds[cls]
    if (is.null(thr) || is.na(thr)) NA_real_ else thr
  }, numeric(1), USE.NAMES = FALSE)

  # Derive winning class per ROI and threshold-applied class
  winning_idx <- apply(score_matrix, 1, which.max)
  winning_class <- class_labels[winning_idx]
  winning_score <- vapply(seq_len(n_images), function(i) {
    score_matrix[i, winning_idx[i]]
  }, numeric(1))

  class_above_threshold <- vapply(seq_len(n_images), function(i) {
    cls <- winning_class[i]
    thr <- thresholds_vec[winning_idx[i]]
    if (is.na(thr)) return(cls)
    if (winning_score[i] >= thr) cls else "unclassified"
  }, character(1))

  dir.create(output_folder, showWarnings = FALSE, recursive = TRUE)

  # Write output in the requested format
  if (format == "h5") {
    if (verbose) message("Writing HDF5 file: ", output_path)

    h5file <- hdf5r::H5File$new(output_path, mode = "w")
    on.exit(h5file$close_all(), add = TRUE)

    h5file[["output_scores"]] <- t(score_matrix)
    h5file[["class_labels"]] <- class_labels
    h5file[["roi_numbers"]] <- roi_numbers
    h5file[["classifier_name"]] <- model_name
    h5file[["class_name_auto"]] <- winning_class
    h5file[["class_name"]] <- class_above_threshold
    h5file[["thresholds"]] <- thresholds_vec

  } else if (format == "mat") {
    if (verbose) message("Writing MAT file: ", output_path)

    source_python(system.file("python", "save_class_mat.py", package = "iRfcb"))

    save_classification_mat(
      score_matrix = score_matrix,
      class_labels = class_labels,
      roi_numbers = roi_numbers,
      winning_class = winning_class,
      class_above_threshold = class_above_threshold,
      model_name = model_name,
      output_path = output_path
    )

  } else if (format == "csv") {
    if (verbose) message("Writing CSV file: ", output_path)

    # ClassiPyR-compatible format: file_name, class_name, score
    # class_name uses threshold-applied classification
    # class_name_auto is the winning class without thresholds
    roi_padded <- sprintf("%05d", roi_numbers)
    file_names <- paste0(sample_name, "_", roi_padded, ".png")

    csv_df <- data.frame(
      file_name = file_names,
      class_name = class_above_threshold,
      class_name_auto = winning_class,
      score = winning_score
    )

    utils::write.csv(csv_df, file = output_path, row.names = FALSE)
  }

  if (verbose) message("Done. Saved ", n_images, " ROIs x ", length(class_labels),
                       " classes to: ", output_path)

  invisible(output_path)
}
