#' Classify Pre-Extracted IFCB PNG Images Using a Gradio Application
#'
#' Classifies one or more pre-extracted IFCB PNG images through a CNN model
#' served by a Gradio application. Each PNG is uploaded to the Gradio server
#' and the prediction result is returned as a data frame. Per-class F2 optimal
#' thresholds are applied automatically; predictions scoring below the
#' threshold for their class are labeled `"unclassified"` in `class_name`.
#'
#' To classify all images in a raw IFCB sample (`.roi` file) without first
#' extracting them manually, use [ifcb_classify_sample()] instead.
#'
#' @param png_file A character vector of paths to PNG files to classify.
#' @param gradio_url A character string specifying the base URL of the Gradio
#'   application. Default is `"https://irfcb-classify.hf.space"`, which is an
#'   example Hugging Face Space with limited resources intended for testing and
#'   demonstration. For large-scale classification, deploy your own instance of
#'   the classification app (source code:
#'   \url{https://github.com/EuropeanIFCBGroup/ifcb-inference-app}) and
#'   pass its URL here.
#' @param top_n An integer specifying the number of top predictions to return
#'   per image. Default is `1` (top prediction only). Use `Inf` to return all
#'   predictions.
#' @param model_name A character string specifying the name of the CNN model
#'   to use for classification. Default is `"SMHI NIVA ResNet50 V5"`. Use
#'   [ifcb_classify_models()] to list all available models.
#' @param verbose A logical value indicating whether to print progress messages.
#'   Default is `TRUE`.
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
#' # Classify a single pre-extracted PNG
#' result <- ifcb_classify_images("path/to/D20220522T003051_IFCB134_00001.png")
#'
#' # Classify several PNGs at once
#' pngs <- list.files("path/to/png_folder", pattern = "\\.png$",
#'                    full.names = TRUE)
#' result <- ifcb_classify_images(pngs, top_n = 3)
#' }
#'
#' @seealso [ifcb_classify_sample()] to classify all images in a raw IFCB
#'   sample without prior extraction. [ifcb_classify_models()] to list
#'   available CNN models. [ifcb_extract_pngs()] to extract PNG images from
#'   IFCB ROI files.
#'
#' @export
ifcb_classify_images <- function(
    png_file,
    gradio_url = "https://irfcb-classify.hf.space",
    top_n = 1,
    model_name = "SMHI NIVA ResNet50 V5",
    verbose = TRUE) {

  missing_files <- png_file[!file.exists(png_file)]
  if (length(missing_files) > 0) {
    stop("PNG file(s) not found: ", paste(missing_files, collapse = ", "))
  }

  gradio_url <- sub("/+$", "", gradio_url)

  # Fetch per-class thresholds
  if (verbose) message("Fetching per-class thresholds...")
  thresholds <- gradio_get_thresholds(gradio_url, model_name)

  if (verbose) message("Classifying ", length(png_file), " image(s)...")

  results_list <- lapply(seq_along(png_file), function(i) {
    png_path <- png_file[i]
    file_name <- basename(png_path)

    if (verbose) print_progress(i, length(png_file))

    tryCatch({
      predictions <- gradio_classify_png(png_path, gradio_url, top_n, model_name)
      data.frame(
        file_name       = file_name,
        class_name_auto = predictions$class_name,
        score           = predictions$score,
        model_name      = model_name
      )
    }, error = function(e) {
      warning("Failed to classify image '", file_name, "': ", e$message)
      data.frame(
        file_name       = file_name,
        class_name_auto = NA_character_,
        score           = NA_real_,
        model_name      = model_name
      )
    })
  })

  if (verbose) cat("\n")

  result <- do.call(rbind, results_list)

  # Apply per-class thresholds
  result$class_name <- vapply(
    seq_len(nrow(result)), function(i) {
      cls <- result$class_name_auto[i]
      scr <- result$score[i]
      if (is.na(cls) || is.na(scr)) return(NA_character_)
      thr <- thresholds$thresholds[cls]
      if (is.null(thr) || is.na(thr)) return(cls)
      if (scr >= thr) cls else "unclassified"
    },
    character(1)
  )

  # Reorder columns: file_name, class_name, class_name_auto, score, model_name
  result[, c("file_name", "class_name", "class_name_auto", "score", "model_name")]
}

# ── Private Gradio API helpers ────────────────────────────────────────────────

# Submit an image to /gradio_api/call/predict_scores and return all class scores.
#
# Uploads the PNG, then POSTs to the predict_scores endpoint and parses the
# SSE JSON response.
#
# @param gradio_url Base URL of the Gradio application (no trailing slash).
# @param image_data Named list matching the Gradio FileData schema.
# @param model_name Model display name.
# @return A list with `class_labels` (character vector) and `scores` (numeric vector).
# @noRd
gradio_predict_scores <- function(gradio_url, image_data, model_name) {
  json_body <- as.character(
    jsonlite::toJSON(list(data = list(image_data, model_name)),
                     auto_unbox = TRUE)
  )

  call_url <- paste0(gradio_url, "/gradio_api/call/predict_scores")
  h_post <- curl::new_handle()
  curl::handle_setopt(h_post,
    customrequest = "POST",
    postfields = json_body,
    httpheader = c("Content-Type: application/json", "Accept: application/json")
  )

  post_resp <- tryCatch(
    curl::curl_fetch_memory(call_url, handle = h_post),
    error = function(e) stop("Connection to Gradio failed at '", call_url,
                             "': ", e$message)
  )

  if (post_resp$status_code != 200) {
    stop("Gradio POST failed [", post_resp$status_code, "]: ", call_url)
  }

  call_result <- tryCatch(
    jsonlite::fromJSON(rawToChar(post_resp$content), simplifyVector = FALSE),
    error = function(e) stop("Failed to parse Gradio POST response: ", e$message)
  )
  event_id <- call_result$event_id
  if (is.null(event_id)) stop("No event_id in Gradio POST response")

  result_url <- paste0(gradio_url, "/gradio_api/call/predict_scores/", event_id)
  h_get <- curl::new_handle()
  curl::handle_setopt(h_get,
    httpheader = c("Accept: text/event-stream")
  )

  get_resp <- tryCatch(
    curl::curl_fetch_memory(result_url, handle = h_get),
    error = function(e) stop("Failed to fetch Gradio SSE from '", result_url,
                             "': ", e$message)
  )

  if (get_resp$status_code != 200) {
    stop("Gradio SSE failed [", get_resp$status_code, "]: ", result_url)
  }

  # Parse the SSE response as a JSON object (not simplified to data frame)
  sse_result <- gradio_parse_sse_json(rawToChar(get_resp$content))

  list(
    class_labels = as.character(unlist(sse_result$class_labels)),
    scores = as.numeric(unlist(sse_result$scores))
  )
}

# Fetch per-class thresholds from /gradio_api/call/get_thresholds.
#
# @param gradio_url Base URL of the Gradio application (no trailing slash).
# @param model_name Model display name.
# @return A list with `class_labels` (character), `thresholds` (named numeric),
#   and `model_name` (character).
# @noRd
gradio_get_thresholds <- function(gradio_url, model_name) {
  json_body <- as.character(
    jsonlite::toJSON(list(data = list(model_name)),
                     auto_unbox = TRUE)
  )

  call_url <- paste0(gradio_url, "/gradio_api/call/get_thresholds")
  h_post <- curl::new_handle()
  curl::handle_setopt(h_post,
    customrequest = "POST",
    postfields = json_body,
    httpheader = c("Content-Type: application/json", "Accept: application/json")
  )

  post_resp <- tryCatch(
    curl::curl_fetch_memory(call_url, handle = h_post),
    error = function(e) stop("Connection to Gradio failed at '", call_url,
                             "': ", e$message)
  )

  if (post_resp$status_code != 200) {
    stop("Gradio POST failed [", post_resp$status_code, "]: ", call_url)
  }

  call_result <- tryCatch(
    jsonlite::fromJSON(rawToChar(post_resp$content), simplifyVector = FALSE),
    error = function(e) stop("Failed to parse Gradio POST response: ", e$message)
  )
  event_id <- call_result$event_id
  if (is.null(event_id)) stop("No event_id in Gradio POST response")

  result_url <- paste0(gradio_url, "/gradio_api/call/get_thresholds/", event_id)
  h_get <- curl::new_handle()
  curl::handle_setopt(h_get,
    httpheader = c("Accept: text/event-stream")
  )

  get_resp <- tryCatch(
    curl::curl_fetch_memory(result_url, handle = h_get),
    error = function(e) stop("Failed to fetch Gradio SSE from '", result_url,
                             "': ", e$message)
  )

  if (get_resp$status_code != 200) {
    stop("Gradio SSE failed [", get_resp$status_code, "]: ", result_url)
  }

  sse_result <- gradio_parse_sse_json(rawToChar(get_resp$content))

  thresholds_list <- sse_result$thresholds
  thresholds <- vapply(thresholds_list, as.numeric, numeric(1))

  list(
    class_labels = as.character(sse_result$class_labels),
    thresholds = thresholds,
    model_name = as.character(sse_result$model_name)
  )
}

# Classify a single PNG image via the Gradio /gradio_api/call/predict_html endpoint.
#
# Uploads the PNG to /gradio_api/upload, then submits the server path to the
# prediction endpoint and reads the result from the SSE stream.
#
# @param png_path Path to a local PNG file.
# @param gradio_url Base URL of the Gradio application (no trailing slash).
# @param top_n Number of top predictions to return.
# @return A list with elements `class_name` (character) and `score` (numeric).
# @noRd
gradio_classify_png <- function(png_path, gradio_url, top_n, model_name) {
  server_path <- gradio_upload_file(png_path, gradio_url)

  # Minimal FileData object matching the documented API format
  image_data <- list(
    path = server_path,
    meta = list(`_type` = "gradio.FileData")
  )

  html_content <- gradio_predict(gradio_url, image_data, model_name)
  gradio_parse_predictions(html_content, top_n)
}

# Upload a local PNG file to the Gradio server.
#
# POSTs the file as multipart/form-data to /gradio_api/upload and returns the
# server-side path needed for subsequent prediction calls.
#
# @param png_path Path to a local PNG file.
# @param gradio_url Base URL of the Gradio application (no trailing slash).
# @return A character string with the server-side file path.
# @noRd
gradio_upload_file <- function(png_path, gradio_url) {
  upload_url <- paste0(gradio_url, "/gradio_api/upload")

  h <- curl::new_handle()
  curl::handle_setform(h,
    files = curl::form_file(png_path, type = "image/png")
  )

  resp <- tryCatch(
    curl::curl_fetch_memory(upload_url, handle = h),
    error = function(e) stop("File upload to Gradio failed at '", upload_url,
                             "': ", e$message)
  )

  if (resp$status_code != 200) {
    stop("Gradio file upload failed [", resp$status_code, "]: ", upload_url)
  }

  paths <- tryCatch(
    jsonlite::fromJSON(rawToChar(resp$content), simplifyVector = TRUE),
    error = function(e) stop("Failed to parse Gradio upload response: ", e$message)
  )
  paths[[1]]
}

# Submit an image to /gradio_api/call/predict_html and return the prediction HTML.
#
# POSTs the prediction request, extracts the event_id, then streams the SSE
# result from /gradio_api/call/predict_html/<event_id>.
#
# NOTE: R's curl requires "Header: value" colon-string format for httpheader.
# Named-vector format (c("Content-Type" = "...")) is silently ignored.
#
# @param gradio_url Base URL of the Gradio application (no trailing slash).
# @param image_data Named list matching the Gradio FileData schema.
# @return A character string containing the prediction HTML.
# @noRd
gradio_predict <- function(gradio_url, image_data, model_name) {
  json_body <- as.character(
    jsonlite::toJSON(list(data = list(image_data, model_name)),
                     auto_unbox = TRUE)
  )

  call_url <- paste0(gradio_url, "/gradio_api/call/predict_html")
  h_post <- curl::new_handle()
  curl::handle_setopt(h_post,
    customrequest = "POST",
    postfields = json_body,
    httpheader = c("Content-Type: application/json", "Accept: application/json")
  )

  post_resp <- tryCatch(
    curl::curl_fetch_memory(call_url, handle = h_post),
    error = function(e) stop("Connection to Gradio failed at '", call_url,
                             "': ", e$message)
  )

  if (post_resp$status_code != 200) {
    stop("Gradio POST failed [", post_resp$status_code, "]: ", call_url)
  }

  call_result <- tryCatch(
    jsonlite::fromJSON(rawToChar(post_resp$content), simplifyVector = FALSE),
    error = function(e) stop("Failed to parse Gradio POST response: ", e$message)
  )
  event_id <- call_result$event_id
  if (is.null(event_id)) stop("No event_id in Gradio POST response")

  result_url <- paste0(gradio_url, "/gradio_api/call/predict_html/", event_id)
  h_get <- curl::new_handle()
  curl::handle_setopt(h_get,
    httpheader = c("Accept: text/event-stream")
  )

  get_resp <- tryCatch(
    curl::curl_fetch_memory(result_url, handle = h_get),
    error = function(e) stop("Failed to fetch Gradio SSE from '", result_url,
                             "': ", e$message)
  )

  if (get_resp$status_code != 200) {
    stop("Gradio SSE failed [", get_resp$status_code, "]: ", result_url)
  }

  gradio_parse_sse(rawToChar(get_resp$content))
}

# Extract the HTML prediction output from a Gradio SSE response.
#
# Handles the Gradio 6 SSE format:
#   event: complete
#   data: ["<html>..."]
#
# @param sse_text Raw SSE response text (may contain multiple events).
# @return A character string containing the prediction HTML.
# @noRd
gradio_parse_sse <- function(sse_text) {
  lines <- strsplit(sse_text, "\n")[[1]]

  # Gradio 6: look for "event: complete" followed by a "data: [...]" array line
  event_idx <- which(trimws(lines) == "event: complete")
  for (i in rev(event_idx)) {
    # The data line immediately follows the event line (skip any blank lines)
    j <- i + 1L
    while (j <= length(lines) && trimws(lines[j]) == "") j <- j + 1L
    if (j <= length(lines) && startsWith(trimws(lines[j]), "data: ")) {
      json_str <- trimws(sub("^data: ", "", lines[j]))
      result <- tryCatch(
        jsonlite::fromJSON(json_str, simplifyVector = TRUE),
        error = function(e) NULL
      )
      if (!is.null(result) && length(result) >= 1L) {
        return(result[[1L]])
      }
    }
  }

  stop("No completed prediction found in Gradio SSE response. ",
       "First 300 chars of response: ", substr(sse_text, 1, 300))
}

# Extract a JSON object from a Gradio SSE response.
#
# Like gradio_parse_sse but uses simplifyVector = FALSE so that JSON objects
# (dicts) are returned as named lists rather than data frames.
#
# @param sse_text Raw SSE response text.
# @return The first element of the JSON data array (typically a named list).
# @noRd
gradio_parse_sse_json <- function(sse_text) {
  lines <- strsplit(sse_text, "\n")[[1]]

  event_idx <- which(trimws(lines) == "event: complete")
  for (i in rev(event_idx)) {
    j <- i + 1L
    while (j <= length(lines) && trimws(lines[j]) == "") j <- j + 1L
    if (j <= length(lines) && startsWith(trimws(lines[j]), "data: ")) {
      json_str <- trimws(sub("^data: ", "", lines[j]))
      result <- tryCatch(
        jsonlite::fromJSON(json_str, simplifyVector = FALSE),
        error = function(e) NULL
      )
      if (!is.null(result) && length(result) >= 1L) {
        return(result[[1L]])
      }
    }
  }

  stop("No completed result found in Gradio SSE response. ",
       "First 300 chars of response: ", substr(sse_text, 1, 300))
}

# Parse class names and confidence scores from Gradio prediction HTML.
#
# Expects the Gradio 6 pred-panel format:
#   <span class="pred-name">Chaetoceros_sp</span>
#   <span class="pred-pct">95.2%</span>
#
# @param html_content HTML string returned by the Gradio prediction endpoint.
# @param top_n Number of top predictions to return.
# @return A list with elements `class_name` (character) and `score` (numeric).
# @noRd
gradio_parse_predictions <- function(html_content, top_n) {
  # Normalise common HTML entities
  html_clean <- gsub("&amp;", "&", html_content, fixed = TRUE)
  html_clean <- gsub("&lt;", "<", html_clean, fixed = TRUE)
  html_clean <- gsub("&gt;", ">", html_clean, fixed = TRUE)
  html_clean <- gsub("&#39;", "'", html_clean, fixed = TRUE)
  html_clean <- gsub("&quot;", "\"", html_clean, fixed = TRUE)

  name_pat <- '<span[^>]*class="pred-name"[^>]*>\\s*([^<]+?)\\s*</span>'
  pct_pat  <- '<span[^>]*class="pred-pct"[^>]*>\\s*([0-9]*\\.?[0-9]+%?)\\s*</span>'

  name_matches <- regmatches(html_clean,
                             gregexpr(name_pat, html_clean, perl = TRUE))[[1]]
  pct_matches  <- regmatches(html_clean,
                             gregexpr(pct_pat, html_clean, perl = TRUE))[[1]]

  if (length(name_matches) == 0 || length(pct_matches) == 0) {
    stop("Could not parse predictions from Gradio HTML. ",
         "First 500 chars of HTML: ", substr(html_content, 1, 500))
  }

  class_names <- gsub(name_pat, "\\1", name_matches, perl = TRUE)
  scores_raw  <- gsub(pct_pat,  "\\1", pct_matches,  perl = TRUE)
  scores <- as.numeric(gsub("%", "", scores_raw, fixed = TRUE)) / 100

  n <- min(top_n, length(class_names), length(scores))
  list(
    class_name = class_names[seq_len(n)],
    score      = scores[seq_len(n)]
  )
}
