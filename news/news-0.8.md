# Version 0.8

## iRfcb 0.8.0

### New features

- New function
  [`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md)
  to classify one or more pre-extracted IFCB PNG images through a CNN
  model served by a Gradio application, returning a data frame of
  predicted class names and confidence scores. Per-class thresholds are
  applied automatically.
- New function
  [`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md)
  to classify all images in a raw IFCB sample (`.roi` file) without
  prior PNG extraction. Internally extracts images to a temporary
  directory and delegates to
  [`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md).
- New function
  [`ifcb_save_classification()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_save_classification.md)
  to classify IFCB samples via Gradio API and save results as HDF5
  (`.h5`), MAT (`.mat`), or CSV (`.csv`) files.
- New function
  [`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
  to list available CNN models from a Gradio classification server.
- Added HDF5 (`.h5`) and CSV (`.csv`) classification file support to
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md),
  [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md),
  [`ifcb_summarize_class_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_class_counts.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
  and
  [`summarize_TBclass()`](https://europeanifcbgroup.github.io/iRfcb/reference/summarize_TBclass.md),
  in addition to existing `.mat` support.

### Breaking changes

- Image extraction functions
  ([`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md),
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md),
  and
  [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md))
  now preserve raw pixel values by default (`normalize = FALSE`),
  producing images comparable to IFCB Dashboard and other standard IFCB
  software. Previously, pixel values were stretched to the full 0-255
  range using min-max normalization. This change can affect classifier
  training results. Set `normalize = TRUE` to restore the previous
  behavior
  ([\#75](https://github.com/EuropeanIFCBGroup/iRfcb/issues/75)).

### Minor improvements and fixes

- [`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md)
  now writes `class2use_auto` as a numeric matrix, matching the format
  produced by `ifcb-analysis`
  ([\#74](https://github.com/EuropeanIFCBGroup/iRfcb/issues/74)).
- Corrected the parameter description of `micron_factor` in
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md).
- Corrected the parameter description of `skip_class` in
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md).

### Deprecations

- [`ifcb_run_image_gallery()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_run_image_gallery.md)
  is deprecated in favor of `ClassiPyR::run_app()`. See
  <https://europeanifcbgroup.github.io/ClassiPyR/> for more information.
- Deprecated arguments:
  - `old_adc` in
    [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md),
    [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md),
    and
    [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md).
    ADC format (old IFCB1-6 vs new) is now auto-detected from the HDR
    file’s `ADCFileFormat` parameter and the ADC column count.
  - `mat_files` in
    [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    and
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    (replaced by `class_files`).
  - `mat_recursive` in
    [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    and
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    (replaced by `class_recursive`).
