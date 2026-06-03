# Classify All Images in an IFCB Sample Using a Gradio Application

Extracts PNG images from an IFCB sample (`.roi` file) using
[`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
into a temporary directory, then classifies each image through a CNN
model served by a Gradio application. Per-class F2 optimal thresholds
are applied automatically. The temporary directory is automatically
removed when the function exits.

## Usage

``` r
ifcb_classify_sample(
  roi_file,
  gradio_url = "https://ifcb.serve.scilifelab.se",
  top_n = 1,
  model_name = "SMHI NIVA SYKE SAMS SZN ResNet 50 V6",
  verbose = TRUE,
  ...
)
```

## Arguments

- roi_file:

  A character string specifying the path to the `.roi` file.

- gradio_url:

  A character string specifying the base URL of the Gradio application.
  Default is `"https://ifcb.serve.scilifelab.se"`, an instance hosted on
  the SciLifeLab Serve platform. A free example Hugging Face Space is
  also available at `"https://irfcb-classify.hf.space"` (limited
  resources, intended for testing and demonstration). For large-scale or
  production classification, deploy your own instance of the
  classification app (source code:
  <https://github.com/EuropeanIFCBGroup/ifcb-inference-app>) and pass
  its URL here.

- top_n:

  An integer specifying the number of top predictions to return per
  image. Default is `1` (top prediction only). Use `Inf` to return all
  predictions.

- model_name:

  A character string specifying the name of the CNN model to use for
  classification. Default is `"SMHI NIVA SYKE SAMS SZN ResNet 50 V6"`.
  Use
  [`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
  to list all available models.

- verbose:

  A logical value indicating whether to print progress messages. Default
  is `TRUE`.

- ...:

  Additional arguments passed to
  [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
  (e.g. `ROInumbers`, `gamma`, `scale_bar_um`).

## Value

A data frame with the following columns:

- `file_name`:

  The PNG file name of the classified image.

- `class_name`:

  The predicted class name with per-class thresholds applied;
  `"unclassified"` if the score is below the threshold.

- `class_name_auto`:

  The winning class name without any threshold applied (argmax of
  scores).

- `score`:

  The prediction confidence score (0–1).

- `model_name`:

  The name of the CNN model used for classification.

Images that could not be classified have `NA` in `class_name`,
`class_name_auto`, and `score`. When `top_n > 1`, multiple rows are
returned per image (one per prediction).

## Details

To classify individual pre-extracted PNG files, use
[`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md)
directly.

## See also

[`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md)
to classify pre-extracted PNG files directly.
[`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
to list available CNN models.
[`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
to extract PNG images from IFCB ROI files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Classify all ROIs in a sample (top prediction per image)
result <- ifcb_classify_sample("path/to/D20220522T003051_IFCB134.roi")
head(result)

# Return top 3 predictions per image
result <- ifcb_classify_sample(
  "path/to/D20220522T003051_IFCB134.roi",
  top_n = 3
)

# Classify only specific ROI numbers
result <- ifcb_classify_sample(
  "path/to/D20220522T003051_IFCB134.roi",
  ROInumbers = c(1, 5, 10)
)
} # }
```
