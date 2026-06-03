# Version 0.7

## iRfcb 0.7.0

CRAN release: 2026-01-07

### New features

- New function
  [`ifcb_annotate_samples()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_annotate_samples.md)
  to create manual classification `.mat` files compatible with the
  `ifcb-analysis` MATLAB repository, using PNG images organized in class
  named subfolders and a `class2use.mat` file.
- New function
  [`ifcb_zip_images_by_class()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_images_by_class.md)
  to zip each PNG subfolder with optional random sampling. Useful for
  preparing class-specific image archives for submission.
- Added a new `diatom_include` argument to
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md)
  for manually forcing specific taxa to be treated as diatoms (overrides
  WoRMS classification).
- Added a new `timestamp_param` argument to
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  allowing the Ferrybox timestamp column to be specified dynamically
  instead of being hard coded.
- Added a new `max_time_diff_min` argument to
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  controlling the maximum allowed time difference in minutes when
  matching Ferrybox data to requested timestamps.
- Added a new `biovolume_only` argument to
  [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md)
  to allow reading only biovolume related columns, improving performance
  for large feature tables.
- Added a new `add_trailing_numbers` argument to
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
  to control whether a zero-padded numeric suffix based on the manual
  class index is appended to class names in the output filenames.
- Added a new `include_classes` argument to
  [`ifcb_prepare_whoi_plankton()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_prepare_whoi_plankton.md)
  to allow explicit selection of classes to include during processing.

### Minor improvements and fixes

- Runnable examples are now wrapped in `\donttest{}` instead of
  `\dontrun{}`.
- Timestamp matching in
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  is now more flexible and can fall back to the closest available
  Ferrybox observation within the specified time window when no exact or
  rounded match is found.
- [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  are now more flexible and accept individual `.mat` files in addition
  to folders.
- Improved performance of
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).
- All data frame outputs are now consistently returned as tibbles.
- Updated IFCB example in
  [`ifcb_get_ecotaxa_example()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ecotaxa_example.md).
- Moved vignettes that required internet access to package articles to
  improve CRAN check reliability.
- Improved error handling across functions, with clearer and more
  consistent messages.
- EEA coastline data are now obtained from EEA map services, replacing
  direct file server downloads that were unstable.
- Test data are sourced from GitHub when not available on Figshare.
- [`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md)
  and
  [`ifcb_create_empty_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_empty_manual_file.md)
  now correctly handles `NaN` values in the `classlist`.

### Deprecations

- [`ifcb_create_empty_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_empty_manual_file.md)
  has been renamed to
  [`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md).
- [`ifcb_match_taxa_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_match_taxa_names.md)
  is now superseded by `SHARK4R::match_worms_taxa()`.
- Deprecated arguments:
  - `mat_folder` in
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    and
    [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    (replaced by `mat_files`).
  - `expected_checksum` in
    [`ifcb_download_test_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_test_data.md).
