# Version 0.3

## iRfcb 0.3.0

### New features

- Introduced unit testing with `testthat` for improve stability.
- Improved consistency and functionality across multiple functions.

## iRfcb 0.3.1

### Minor improvements and fixes

- Corrected documentation errors.

## iRfcb 0.3.2

### Minor improvements and fixes

- Replaced test data with a smaller dataset.
- Improved unit test coverage.

## iRfcb 0.3.3

### Minor improvements and fixes

- Fixed manual `.mat` count edge case.
- Switched to `curl` for downloads.
- Parameterized PSD micron factor in
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  with argument `micron_factor`.
- General clean-up of minor improvements and fixes.

## iRfcb 0.3.4

### Minor improvements and fixes

- Added option to summarize biovolumes from manual files in
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).
- Added `sleep_time` parameter for
  [`ifcb_download_test_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_test_data.md).

## iRfcb 0.3.5

### Minor improvements and fixes

- Improved error handling in WoRMS API calls with multiple attempts in
  `iRfcb:::retrieve_worms_records()`.
- Updated package title.

### Deprecations

- Deprecated `ifcb_get_svea_position()` (replaced by
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)).

## iRfcb 0.3.6

### Minor improvements and fixes

- Removed Öresund from included Baltic Sea shape file used in
  [`ifcb_is_in_basin()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_in_basin.md).
- Updated SHARK column names for compatibility in
  [`ifcb_get_shark_example()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_example.md)
  and
  [`ifcb_get_shark_colnames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md).

## iRfcb 0.3.7

### New features

- Added classifier name to output from MATLAB extraction in
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).

## iRfcb 0.3.8

### Minor improvements and fixes

- Added `marine_only` to
  [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md),
  `iRfcb:::retrieve_worms_records()`,
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md).
- Added `feature_recursive` to
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).
- Added `mat_recursive` to
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).
- Added `hdr_recursive` to
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).
- Extracted helper function from
  [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md).

## iRfcb 0.3.9

### Minor improvements and fixes

- Fixed edge case where `nrow(taxa_list) == 0` in
  [`ifcb_count_mat_annotations()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_count_mat_annotations.md).
- Added `mat_recursive` option to
  [`ifcb_count_mat_annotations()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_count_mat_annotations.md).
- Added `manual_recursive` option to
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
  and
  [`ifcb_zip_matlab()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_matlab.md).
- Added `roi_recursive` option to
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md).
- Added `data_recursive` option to
  [`ifcb_zip_matlab()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_matlab.md).
- Added `feature_recursive` option to
  [`ifcb_zip_matlab()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_matlab.md).

## iRfcb 0.3.10

### Minor improvements and fixes

- Updated documentation and examples.

### Deprecations

- Removed deprecated function `ifcb_get_svea_position()`.
- Removed helper `iRfcb:::handle_missing_positions()`.
- Deprecated arguments `manual_folder`, `feature_folder`, and
  `class_folder` in several functions
  ([`ifcb_count_mat_annotations()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_count_mat_annotations.md),
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md),
  [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).

## iRfcb 0.3.11

### New features

- Added
  [`ifcb_summarize_png_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_png_metadata.md)
  to summarize EcoTaxa metadata.
- Added
  [`ifcb_get_ecotaxa_example()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ecotaxa_example.md)
  to extract EcoTaxa headers and example data.

### Minor improvements and fixes

- Large ZIP files can now be split using helper
  `iRfcb:::split_large_zip()` in
  [`ifcb_zip_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_pngs.md).

### Deprecations

- Deprecated `ifcb_summarize_png_data()` (replaced by
  [`ifcb_summarize_png_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_png_counts.md)).

## iRfcb 0.3.12

### New features

- Added
  [`ifcb_create_empty_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_empty_manual_file.md)
  to create new manual `.mat` files.
- Added
  [`ifcb_annotate_batch()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_annotate_batch.md)
  to annotate multiple `.mat` files in a batch based on `.png` images.

### Minor improvements and fixes

- Compressed `.mat` files to save space using `do_compression` argument
  in:
  - [`ifcb_correct_annotation()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md)
  - [`ifcb_replace_mat_values()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_replace_mat_values.md)

## iRfcb 0.3.13

### New features

- Added
  [`ifcb_merge_manual()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_merge_manual.md)
  to merge manual `.mat` datasets.
- Added
  [`ifcb_adjust_classes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_adjust_classes.md)
  to adjust classes in manual data.
- Added
  [`ifcb_create_class2use()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_class2use.md)
  to generate a class2use file.

## iRfcb 0.3.14

### Minor improvements and fixes

- Updated SHARK example in
  [`ifcb_get_shark_example()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_example.md)
  and
  [`ifcb_get_shark_colnames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md)
  for testing and documentation.

## iRfcb 0.3.15

### Minor improvements and fixes

- Fixed issue in
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  where multiple close ferrybox timestamps caused duplicate rows. Now
  returns only the nearest match.
