# Classify an IFCB Sample and Save Results

Extracts PNG images from an IFCB `.roi` file, classifies each image via
the Gradio API `predict_scores` endpoint (returning all class scores),
fetches per-class thresholds, and writes the results in the specified
format.

## Usage

``` r
ifcb_save_classification(
  roi_file,
  output_folder,
  format = c("h5", "mat", "csv"),
  gradio_url = "https://irfcb-classify.hf.space",
  model_name = "SMHI NIVA ResNet50 V5",
  verbose = TRUE,
  ...
)
```

## Arguments

- roi_file:

  A character string specifying the path to the `.roi` file.

- output_folder:

  A character string specifying the directory where the output file will
  be saved. The file is named automatically based on the sample name
  (e.g. `D20220522T003051_IFCB134_class.h5`,
  `D20220522T003051_IFCB134_class_v1.mat`, or
  `D20220522T003051_IFCB134.csv`).

- format:

  A character string specifying the output format. One of `"h5"`
  (default), `"mat"`, or `"csv"`.

- gradio_url:

  A character string specifying the base URL of the Gradio application.
  Default is `"https://irfcb-classify.hf.space"`, which is an example
  Hugging Face Space with limited resources intended for testing and
  demonstration. For large-scale classification, deploy your own
  instance of the classification app (source code:
  <https://github.com/EuropeanIFCBGroup/ifcb-inference-app>) and pass
  its URL here.

- model_name:

  A character string specifying the name of the CNN model to use for
  classification. Default is `"SMHI NIVA ResNet50 V5"`. Use
  [`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
  to list all available models.

- verbose:

  A logical value indicating whether to print progress messages. Default
  is `TRUE`.

- ...:

  Additional arguments passed to
  [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
  (e.g. `ROInumbers`, `gamma`).

## Value

The path to the saved file (invisibly).

## Details

Three output formats are supported:

- `"h5"`:

  IFCB Dashboard class_scores v3 HDF5 format. Contains `output_scores`,
  `class_labels`, `roi_numbers` (Dashboard-required), plus
  `classifier_name`, `class_name`, `class_name_auto`, and `thresholds`.
  Requires the hdf5r package.

- `"mat"`:

  IFCB Dashboard class_scores v1 MATLAB format. Contains `class2useTB`,
  `TBscores`, `roinum`, `TBclass`, `TBclass_above_threshold`, and
  `classifierName`. Requires Python with scipy and numpy.

- `"csv"`:

  `ClassiPyR`-compatible CSV format with columns `file_name`,
  `class_name` (threshold-applied), `class_name_auto` (winning class
  without threshold), and `score` (winning class confidence). See
  <https://github.com/EuropeanIFCBGroup/ClassiPyR> for details.

## See also

[`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md),
[`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md),
[`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Classify a sample and save as HDF5 (default)
ifcb_save_classification(
  "path/to/D20220522T003051_IFCB134.roi",
  output_folder = "output"
)

# Save as Dashboard v1 .mat format
ifcb_save_classification(
  "path/to/D20220522T003051_IFCB134.roi",
  output_folder = "output",
  format = "mat"
)

# Save as CSV
ifcb_save_classification(
  "path/to/D20220522T003051_IFCB134.roi",
  output_folder = "output",
  format = "csv"
)
} # }
```
