test_that("ifcb_classify_images errors when a PNG file does not exist", {
  expect_error(
    ifcb_classify_images("nonexistent.png"),
    "PNG file.*not found"
  )
})

test_that("ifcb_classify_images errors when any path in a vector does not exist", {
  skip_on_cran()
  tmp <- tempfile(fileext = ".png")
  writeBin(raw(0), tmp)
  on.exit(unlink(tmp))
  expect_error(
    ifcb_classify_images(c(tmp, "missing.png")),
    "PNG file.*not found"
  )
})

# Helper: build a Gradio 6 SSE data line with properly JSON-escaped HTML.
make_sse <- function(...) {
  events <- list(...)
  paste(vapply(events, function(e) {
    json_data <- as.character(jsonlite::toJSON(list(e$html), auto_unbox = FALSE))
    paste0("event: ", e$event, "\n", "data: ", json_data)
  }, character(1)), collapse = "\n\n")
}

# ── Internal helper: gradio_fetch ─────────────────────────────────────────────

test_that("gradio_fetch retries connection errors and returns a later success", {
  old <- options(iRfcb.gradio_retry_delay = 0)
  on.exit(options(old))
  attempts <- 0L
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle = NULL) {
      attempts <<- attempts + 1L
      if (attempts < 3L) stop("Couldn't connect to server")
      list(status_code = 200L, content = charToRaw("ok"))
    },
    .package = "curl"
  )
  resp <- iRfcb:::gradio_fetch("http://example.invalid", curl::new_handle())
  expect_equal(attempts, 3L)
  expect_equal(resp$status_code, 200L)
})

test_that("gradio_fetch retries HTTP 5xx and 429 responses", {
  old <- options(iRfcb.gradio_retry_delay = 0)
  on.exit(options(old))
  codes <- c(503L, 429L, 200L)
  attempts <- 0L
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle = NULL) {
      attempts <<- attempts + 1L
      list(status_code = codes[attempts], content = raw(0))
    },
    .package = "curl"
  )
  resp <- iRfcb:::gradio_fetch("http://example.invalid", curl::new_handle())
  expect_equal(attempts, 3L)
  expect_equal(resp$status_code, 200L)
})

test_that("gradio_fetch does not retry non-transient responses", {
  old <- options(iRfcb.gradio_retry_delay = 0)
  on.exit(options(old))
  attempts <- 0L
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle = NULL) {
      attempts <<- attempts + 1L
      list(status_code = 404L, content = raw(0))
    },
    .package = "curl"
  )
  resp <- iRfcb:::gradio_fetch("http://example.invalid", curl::new_handle())
  expect_equal(attempts, 1L)
  expect_equal(resp$status_code, 404L)
})

test_that("gradio_fetch aborts with the error prefix after exhausting attempts", {
  old <- options(iRfcb.gradio_retry_delay = 0, iRfcb.gradio_max_tries = 2)
  on.exit(options(old))
  attempts <- 0L
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle = NULL) {
      attempts <<- attempts + 1L
      stop("Couldn't connect to server")
    },
    .package = "curl"
  )
  expect_error(
    iRfcb:::gradio_fetch("http://example.invalid", curl::new_handle(),
                         "File upload to Gradio failed"),
    "File upload to Gradio failed"
  )
  expect_equal(attempts, 2L)
})

test_that("gradio_fetch returns the final response when a 5xx persists", {
  old <- options(iRfcb.gradio_retry_delay = 0, iRfcb.gradio_max_tries = 2)
  on.exit(options(old))
  attempts <- 0L
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle = NULL) {
      attempts <<- attempts + 1L
      list(status_code = 502L, content = raw(0))
    },
    .package = "curl"
  )
  resp <- iRfcb:::gradio_fetch("http://example.invalid", curl::new_handle())
  expect_equal(attempts, 2L)
  expect_equal(resp$status_code, 502L)
})

# ── Internal helper: gradio_parse_sse ─────────────────────────────────────────

test_that("gradio_parse_sse extracts HTML from a Gradio 6 complete event", {
  html_snippet <- '<div class="pred-panel"><span class="pred-name">Chaetoceros</span><span class="pred-pct">95.2%</span></div>'
  sse_text <- make_sse(list(event = "complete", html = html_snippet))

  result <- iRfcb:::gradio_parse_sse(sse_text)
  expect_equal(result, html_snippet)
})

test_that("gradio_parse_sse returns the last complete event when multiple exist", {
  first <- '<div class="pred-panel"><span class="pred-name">ClassA</span><span class="pred-pct">80%</span></div>'
  last  <- '<div class="pred-panel"><span class="pred-name">ClassB</span><span class="pred-pct">90%</span></div>'
  sse_text <- make_sse(list(event = "complete", html = first),
                       list(event = "complete", html = last))
  result <- iRfcb:::gradio_parse_sse(sse_text)
  expect_equal(result, last)
})

test_that("gradio_parse_sse handles generating events before complete", {
  html_snippet <- '<div class="pred-panel"><span class="pred-name">Dinophysis</span><span class="pred-pct">88.0%</span></div>'
  sse_text <- paste0(
    "event: generating\ndata: null\n\n",
    make_sse(list(event = "complete", html = html_snippet))
  )
  result <- iRfcb:::gradio_parse_sse(sse_text)
  expect_equal(result, html_snippet)
})

test_that("gradio_parse_sse errors when no complete event is found", {
  sse_text <- "event: generating\ndata: null\n\n"
  expect_error(iRfcb:::gradio_parse_sse(sse_text), "No completed prediction found")
})

# ── Internal helper: gradio_parse_predictions ─────────────────────────────────

test_that("gradio_parse_predictions parses pred-name / pred-pct span format", {
  html <- paste0(
    '<div class="pred-panel">',
    '<div class="pred-row"><div class="pred-header">',
    '<span class="pred-name">Chaetoceros_sp</span>',
    '<span class="pred-pct">95.2%</span>',
    '</div></div>',
    '<div class="pred-row"><div class="pred-header">',
    '<span class="pred-name">detritus</span>',
    '<span class="pred-pct">3.1%</span>',
    '</div></div>',
    '</div>'
  )

  result <- iRfcb:::gradio_parse_predictions(html, top_n = 1)
  expect_equal(result$class_name, "Chaetoceros_sp")
  expect_equal(result$score, 0.952, tolerance = 1e-6)
})

test_that("gradio_parse_predictions respects top_n", {
  html <- paste0(
    '<span class="pred-name">ClassA</span><span class="pred-pct">80.0%</span>',
    '<span class="pred-name">ClassB</span><span class="pred-pct">15.0%</span>',
    '<span class="pred-name">ClassC</span><span class="pred-pct">5.0%</span>'
  )

  result <- iRfcb:::gradio_parse_predictions(html, top_n = 2)
  expect_length(result$class_name, 2)
  expect_equal(result$class_name, c("ClassA", "ClassB"))
  expect_equal(result$score, c(0.80, 0.15), tolerance = 1e-6)
})

test_that("gradio_parse_predictions converts percentage scores to 0-1 range", {
  html <- paste0(
    '<span class="pred-name">Dinophysis</span>',
    '<span class="pred-pct">87.3%</span>'
  )

  result <- iRfcb:::gradio_parse_predictions(html, top_n = 1)
  expect_equal(result$score, 87.3 / 100, tolerance = 1e-6)
})

test_that("gradio_parse_predictions decodes HTML entities in class names", {
  html <- paste0(
    '<span class="pred-name">Thalassiosira &amp; related</span>',
    '<span class="pred-pct">60.0%</span>'
  )

  result <- iRfcb:::gradio_parse_predictions(html, top_n = 1)
  expect_equal(result$class_name, "Thalassiosira & related")
})

test_that("gradio_parse_predictions errors on unrecognised HTML", {
  expect_error(
    iRfcb:::gradio_parse_predictions("<p>No predictions here</p>", top_n = 1),
    "Could not parse predictions"
  )
})

# ── Integration test (requires network access) ────────────────────────────────

test_that("ifcb_classify_images classifies a real PNG and returns non-NA results", {
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable(
    "https://ifcb.serve.scilifelab.se/gradio_api/call/predict_html"
  )

  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_classify_image_integration")
  unzip(test_data_zip, exdir = temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  roi_file <- file.path(temp_dir, "test_data", "data",
                        "D20220522T003051_IFCB134.roi")

  # Extract a couple of PNGs first, then classify them directly
  png_dir <- file.path(temp_dir, "pngs")
  dir.create(png_dir)
  ifcb_extract_pngs(roi_file, out_folder = png_dir, verbose = FALSE)
  png_files <- list.files(png_dir, pattern = "\\.png$",
                          full.names = TRUE, recursive = TRUE)

  result <- ifcb_classify_images(png_files, verbose = FALSE)

  expect_true(is.data.frame(result))
  expect_named(result, c("file_name", "class_name", "class_name_auto", "score", "model_name"))
  expect_equal(nrow(result), length(png_files))
  expect_false(anyNA(result$class_name),
               label = "class_name must have no NAs when API is reachable")
  expect_false(anyNA(result$class_name_auto),
               label = "class_name_auto must have no NAs when API is reachable")
  expect_true(all(result$score >= 0 & result$score <= 1),
              label = "scores must be in [0, 1]")
})

test_that("ifcb_classify_images applies thresholds: class_name may differ from class_name_auto", {
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable(
    "https://ifcb.serve.scilifelab.se/gradio_api/call/predict_html"
  )

  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_classify_image_threshold")
  unzip(test_data_zip, exdir = temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  roi_file <- file.path(temp_dir, "test_data", "data",
                        "D20220522T003051_IFCB134.roi")

  png_dir <- file.path(temp_dir, "pngs")
  dir.create(png_dir)
  ifcb_extract_pngs(roi_file, out_folder = png_dir, verbose = FALSE)
  png_files <- list.files(png_dir, pattern = "\\.png$",
                          full.names = TRUE, recursive = TRUE)

  # Only test with first 2 images for speed
  result <- ifcb_classify_images(png_files[1:2], verbose = FALSE)

  expect_true(is.data.frame(result))
  expect_true("class_name" %in% names(result))
  expect_true("class_name_auto" %in% names(result))
  # class_name is either the same as class_name_auto or "unclassified"
  expect_true(all(result$class_name %in%
                    c(result$class_name_auto, "unclassified") | is.na(result$class_name)))
})

test_that("malformed retry options are reported clearly, naming the option", {
  old <- options(iRfcb.gradio_max_tries = "3x", iRfcb.gradio_retry_delay = NULL)
  on.exit(options(old), add = TRUE)
  # Used to surface as a cryptic seq_len() error far from the option.
  expect_error(gradio_fetch("http://localhost:1/nope"), "gradio_max_tries")

  options(iRfcb.gradio_max_tries = 4L, iRfcb.gradio_retry_delay = "fast")
  expect_error(gradio_fetch("http://localhost:1/nope"), "gradio_retry_delay")
})
