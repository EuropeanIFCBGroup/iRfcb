# Version 0.5

## iRfcb 0.5.0

CRAN release: 2025-04-15

### New features

- Added `NEWS.md` to track package changes.
- New functions:
  - [`ifcb_download_dashboard_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)
    for fetching data from the WHOI IFCB Dashboard.
  - [`ifcb_download_whoi_plankton()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_whoi_plankton.md)
    for downloading WHOI-Plankton PNG datasets.
  - [`ifcb_prepare_whoi_plankton()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_prepare_whoi_plankton.md)
    to process WHOI data for integration.
- New vignette: `vignette("whoi-plankton-data-integration")`.
- Python virtual environments can now be automatically activated by
  setting the `USE_IRFCB_PYTHON` environment variable when loading the
  package.
- Added scale bar support
  ([\#42](https://github.com/EuropeanIFCBGroup/iRfcb/issues/42)) to:
  - [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
  - [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md)
  - [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
- Added `gamma` argument to
  [`ifcb_extract_annotated_images ()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
  and
  [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md)
  for gamma correction.
- [`ifcb_is_near_land()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_near_land.md):
  - Now returns a plot if `plot = TRUE`.
  - Added option to download EEA coastline data using the new argument
    `source`.
  - Deprecated the argument `utm_zone`, which is now determined
    automatically from longitude.

### Minor improvements and fixes

- [`ifcb_read_hdr_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_hdr_data.md)
  now correctly handles files from IFCB Acquire 1.x.x.x
  ([\#41](https://github.com/EuropeanIFCBGroup/iRfcb/issues/41)).
- [`ifcb_convert_filenames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_convert_filenames.md)
  is more efficient and now correctly parses filenames like
  `"IFCB1_2010_309_192918"`
  ([\#40](https://github.com/EuropeanIFCBGroup/iRfcb/issues/40)).
- The default location of the venv path in
  [`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)
  has changed to “~/.virtualenvs/iRfcb”.
- Added support for old `.adc` file format (IFCB1-6) by argument
  `old_adc` in:
  - [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
  - [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md)
  - [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
- [`ifcb_read_mat()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_mat.md)
  now returns consistent data structures aligned with
  [`R.matlab::readMat()`](https://rdrr.io/pkg/R.matlab/man/readMat.html)
  ([\#50](https://github.com/EuropeanIFCBGroup/iRfcb/issues/50)).

### Deprecations

- `ifcb_summarize_png_data()` is now defunct (previously deprecated in
  version 0.3.11).
- Deprecated arguments:
  - `adc_folder` in
    [`ifcb_annotate_batch()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_annotate_batch.md)
    (replaced by `adc_files`).
  - `unclassified_id` in
    [`ifcb_create_empty_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_empty_manual_file.md)
    (replaced by `classlist`).
  - `utm_zone` in
    [`ifcb_is_near_land()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_near_land.md)
    (now determined automatically from longitude).
- [`ifcb_create_empty_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_empty_manual_file.md)
  now accepts a complete class list via `classlist`, replacing the older
  `unclassified_id`.

## iRfcb 0.5.1

CRAN release: 2025-04-22

### Minor improvements and fixes

- Skipping certain internet-required tests on CRAN servers.
- Corrected help pages for
  [`ifcb_download_dashboard_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)
  and
  [`ifcb_download_whoi_plankton()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_whoi_plankton.md).

## iRfcb 0.5.2

CRAN release: 2025-09-03

### Minor improvements and fixes

- [`ifcb_download_test_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_test_data.md)
  gains checksum validation, `keep_zip` option, and improved retry
  logic.
- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  gain a `drop_zero_volume` option to exclude artifacts with zero
  biovolume
- [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md)
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  now handles single `feature_files` correctly.
- Tests are now skipped if required resources are unavailable, improving
  stability in environments with limited access to external
  dependencies.
