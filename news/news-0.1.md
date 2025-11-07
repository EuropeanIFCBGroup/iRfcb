# Version 0.1

## iRfcb 0.1.0

Initial development release of `iRfcb`.

### Features

- Core functionality for reading and analyzing IFCB data, including:
  - [`ifcb_convert_filenames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_convert_filenames.md)
  - [`ifcb_correct_annotation()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md)
  - [`ifcb_count_mat_annotations()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_count_mat_annotations.md)
  - [`ifcb_create_manifest()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manifest.md)
  - [`ifcb_download_test_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_test_data.md)
  - [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
  - [`ifcb_extract_classified_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md)
  - [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
  - [`ifcb_get_mat_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_names.md)
  - `ifcb_get_mat_variables()`
  - [`ifcb_get_runtime()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_runtime.md)
  - [`ifcb_is_near_land()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_near_land.md)
  - [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  - [`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)
  - [`ifcb_read_hdr_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_hdr_data.md)
  - [`ifcb_read_summary()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_summary.md)
  - [`ifcb_replace_mat_values()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_replace_mat_values.md)
  - [`ifcb_run_image_gallery()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_run_image_gallery.md)
  - `ifcb_summarize_png_data()`
  - [`ifcb_volume_analyzed_from_adc()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed_from_adc.md)
  - [`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md)
  - [`ifcb_zip_matlab()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_matlab.md)
  - [`ifcb_zip_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_zip_pngs.md)

## iRfcb 0.1.1

### Minor improvements and fixes

- Fixed warning in
  [`ifcb_is_near_land()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_near_land.md)
  by applying
  [`sf::st_wrap_dateline()`](https://r-spatial.github.io/sf/reference/st_transform.html)
  only when the CRS is geographic.
- Updated function documentation for consistency.

## iRfcb 0.1.2

### Minor improvements and fixes

- Fixed edge case in
  [`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md)
  when inhibition `time == 0`
  ([\#2](https://github.com/EuropeanIFCBGroup/iRfcb/issues/2)).
