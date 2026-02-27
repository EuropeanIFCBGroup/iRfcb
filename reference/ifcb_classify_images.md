# Classify Pre-Extracted IFCB PNG Images Using a Gradio Application

Classifies one or more pre-extracted IFCB PNG images through a CNN model
served by a Gradio application. Each PNG is uploaded to the Gradio
server and the prediction result is returned as a data frame. Per-class
F2 optimal thresholds are applied automatically; predictions scoring
below the threshold for their class are labeled `"unclassified"` in
`class_name`.

## Usage

``` r
ifcb_classify_images(
  png_file,
  gradio_url = "https://irfcb-classify.hf.space",
  top_n = 1,
  model_name = "SMHI NIVA ResNet50 V5",
  verbose = TRUE
)
```

## Arguments

- png_file:

  A character vector of paths to PNG files to classify.

- gradio_url:

  A character string specifying the base URL of the Gradio application.
  Default is `"https://irfcb-classify.hf.space"`, which is an example
  Hugging Face Space with limited resources intended for testing and
  demonstration. For large-scale classification, deploy your own
  instance of the classification app (source code:
  <https://github.com/EuropeanIFCBGroup/ifcb-inference-app>) and pass
  its URL here.

- top_n:

  An integer specifying the number of top predictions to return per
  image. Default is `1` (top prediction only). Use `Inf` to return all
  predictions.

- model_name:

  A character string specifying the name of the CNN model to use for
  classification. Default is `"SMHI NIVA ResNet50 V5"`. Use
  [`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
  to list all available models.

- verbose:

  A logical value indicating whether to print progress messages. Default
  is `TRUE`.

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

To classify all images in a raw IFCB sample (`.roi` file) without first
extracting them manually, use
[`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md)
instead.

## See also

[`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md)
to classify all images in a raw IFCB sample without prior extraction.
[`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
to list available CNN models.
[`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
to extract PNG images from IFCB ROI files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Classify a single pre-extracted PNG
result <- ifcb_classify_images("path/to/D20220522T003051_IFCB134_00001.png")

# Classify several PNGs at once
pngs <- list.files("path/to/png_folder", pattern = "\\.png$",
                   full.names = TRUE)
result <- ifcb_classify_images(pngs, top_n = 3)
} # }
```
