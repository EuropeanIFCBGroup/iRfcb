# Version dev

## iRfcb (development version)

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
