#' List Available CNN Models from a Gradio Classification Server
#'
#' Queries the Gradio API to retrieve the names of all CNN models available
#' for IFCB image classification. These model names can be passed to the
#' `model_name` argument of [ifcb_classify_images()] and [ifcb_classify_sample()].
#'
#' @param gradio_url A character string specifying the base URL of the Gradio
#'   application. Default is `"https://irfcb-classify.hf.space"`, which is an
#'   example Hugging Face Space with limited resources intended for testing and
#'   demonstration. For large-scale classification, deploy your own instance of
#'   the classification app with your own model (source code:
#'   \url{https://github.com/EuropeanIFCBGroup/ifcb-inference-app}) and
#'   pass its URL here.
#'
#' @return A character vector of available model names.
#'
#' @examples
#' \dontrun{
#' # List available models
#' models <- ifcb_classify_models()
#' print(models)
#'
#' # Use a specific model for classification
#' result <- ifcb_classify_images("image.png", model_name = models[1])
#' }
#'
#' @seealso [ifcb_classify_images()], [ifcb_classify_sample()]
#'
#' @export
ifcb_classify_models <- function(
    gradio_url = "https://irfcb-classify.hf.space") {

  gradio_url <- sub("/+$", "", gradio_url)
  info_url <- paste0(gradio_url, "/gradio_api/info")

  resp <- tryCatch(
    curl::curl_fetch_memory(info_url),
    error = function(e) stop("Failed to connect to Gradio API at '", info_url,
                             "': ", e$message)
  )

  if (resp$status_code != 200) {
    stop("Gradio API info request failed [", resp$status_code, "]: ", info_url)
  }

  api_info <- tryCatch(
    jsonlite::fromJSON(rawToChar(resp$content), simplifyVector = FALSE),
    error = function(e) stop("Failed to parse Gradio API info: ", e$message)
  )

  # Navigate to the predict_html endpoint and find the model_name parameter
  endpoints <- api_info$named_endpoints
  predict_endpoint <- endpoints$`/predict_html`

  if (is.null(predict_endpoint)) {
    stop("No /predict_html endpoint found in Gradio API info")
  }

  params <- predict_endpoint$parameters
  model_param <- NULL
  for (p in params) {
    if (identical(p$parameter_name, "model_name")) {
      model_param <- p
      break
    }
  }

  if (is.null(model_param)) {
    stop("No model_name parameter found in Gradio /predict_html endpoint")
  }

  model_names <- model_param$type$enum
  if (is.null(model_names) || length(model_names) == 0) {
    stop("No models listed in Gradio API")
  }

  unlist(model_names)
}
