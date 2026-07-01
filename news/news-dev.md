# Version dev

## iRfcb (development version)

### New features

- Added
  [`ifcb_qc_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_qc_sample.md),
  which validates the integrity and self-consistency of raw IFCB samples
  (the `.hdr`/`.adc`/`.roi` triplet) and returns a tidy tibble of QC
  metrics and flags, one row per sample. Checks cover triplet
  completeness, ROI count consistency (imaged ROIs in the ADC versus the
  header `roiCount`), ROI data completeness (detecting truncated/aborted
  `.roi` files by comparing the file size to the last image’s end
  offset), header/ADC run time consistency, and flow/volume sanity via
  [`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md)
  (the volume ceiling is derived per sample from the header
  `SyringeSampleVolume`, reported as `syringe_ml`, rather than a fixed
  value; a constant ceiling can be forced with `max_ml`).
  Bead/calibration runs (`is_bead_run`), empty samples (`is_empty`),
  and, via the optional `max_roi_mb` argument, oversized `.roi` files
  (`roi_oversized`); and, via the optional `max_humidity` /
  `max_temperature` arguments, high recorded humidity or temperature
  (`humidity_high` / `temperature_high`) are flagged separately as
  advisory. The function accepts a directory, sample names with a
  `data_folder`, or explicit file paths, and builds entirely on existing
  native-R readers (no Python required).

### Minor improvements and fixes

- Removed the Python dependency from all functions that create or edit
  MATLAB `ifcb-analysis` manual classification files.
  [`ifcb_create_class2use()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_class2use.md),
  [`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md)
  (and the deprecated
  [`ifcb_create_empty_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_empty_manual_file.md)),
  [`ifcb_adjust_classes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_adjust_classes.md),
  [`ifcb_correct_annotation()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md),
  [`ifcb_replace_mat_values()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_replace_mat_values.md),
  and the `format = "mat"` output of
  [`ifcb_save_classification()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_save_classification.md)
  now write `.mat` files with a native R implementation of the MATLAB
  Level 5 MAT-file format, producing output identical to the previous
  `scipy.io.savemat`-based approach (byte-for-byte identical when
  uncompressed, and identical in content when compressed). The wrapper
  functions
  [`ifcb_annotate_batch()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_annotate_batch.md),
  [`ifcb_annotate_samples()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_annotate_samples.md),
  [`ifcb_merge_manual()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_merge_manual.md),
  and
  [`ifcb_prepare_whoi_plankton()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_prepare_whoi_plankton.md),
  which delegate to the above, are therefore also Python-free. This
  removes the `scipy`/`numpy` requirement for creating and editing
  manual annotation files.
- Removed the `R.matlab` package as a dependency. The default
  (non-Python) path for *reading* `.mat` files now also uses the native
  R MAT-file reader instead of
  [`R.matlab::readMat()`](https://rdrr.io/pkg/R.matlab/man/readMat.html),
  affecting
  [`ifcb_get_mat_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_names.md),
  [`ifcb_get_mat_variable()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_variable.md),
  [`ifcb_read_summary()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_summary.md),
  [`ifcb_count_mat_annotations()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_count_mat_annotations.md),
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md),
  and the reading of `.mat` classification files. The native reader
  decodes MATLAB-generated UTF-16 character data correctly, so non-ASCII
  strings (e.g. accented class or path names) that
  [`R.matlab::readMat()`](https://rdrr.io/pkg/R.matlab/man/readMat.html)
  could mangle are now preserved. `R.matlab` has been moved from
  `Imports` to `Suggests` (used only as an independent cross-check in
  the test suite).
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  gains a `feature_tag` argument to control the feature file naming. The
  default (`"features"`) writes `<bin>_features_v4.csv` as before;
  `"fea"` writes `<bin>_fea_v4.csv`, the name served by the IFCB
  Dashboard (pyifcb’s `FeaturesDirectory`).
