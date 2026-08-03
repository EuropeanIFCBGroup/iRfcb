# Version dev

## iRfcb (development version)

### New features

- Added support for the optional per-ROI `cell_count` data produced by
  the diatom chain counter (Groves et al. 2026,
  [doi:10.1093/plankt/fbaf064](https://doi.org/10.1093/plankt/fbaf064))
  via the
  [`ifcb-pytorch-classify`](https://github.com/nodc-sweden/ifcb-pytorch-classify)
  inference pipeline, and stored in `.mat`/`.h5`/`.csv` classification
  files. This enables reporting cell abundance (accounting for chains)
  in addition to ROI counts.
  - New
    [`ifcb_summarize_cell_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_cell_counts.md)
    summarizes cell abundance and user-selectable chain-length
    statistics (`mean`, `median`, `max`, `sd`, `n_chains`) per sample
    and class, with optional per-liter abundance via an `hdr_folder`.
  - [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    and
    [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    gain a `use_cell_counts` argument. When `TRUE`,
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    adds `cell_counts` (and `cell_counts_per_liter` when an `hdr_folder`
    is supplied) to the output.
  - A `single_cell_values` argument (default `c(-1, 0)`) lets the user
    define which `cell_count` values are treated as a single cell. By
    default, ROIs that were not chain-counted (`-1`) and ROIs where no
    cells were detected (`0`) each count as one cell; any other value is
    used verbatim.
  - The bundled SHARK column template
    ([`ifcb_get_shark_colnames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md)/[`ifcb_get_shark_example()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_example.md))
    gains an `IMAGE_COUNT` column (number of ROIs/images), placed after
    `COUNT`. When `COUNT`/`ABUND` report cells, the mean chain length
    per taxon is `COUNT / IMAGE_COUNT`.
- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  gain a `diatom_equation` argument selecting which Menden-Deuer and
  Lessard (2000) carbon-to-volume relationship to apply to diatoms. The
  default (`"large"`) uses the large-diatom (\> 3000 micron^3) equation,
  matching the `ifcb-analysis` convention and preserving previous
  behavior; `"all"` uses the all-sizes diatom equation, which assigns
  more carbon to small cells. A new exported helper
  [`vol2C_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_diatom.md)
  implements the all-sizes relationship (log a = -0.541, b = 0.811).
  Note that biovolume is measured per region of interest (image), not
  per cell, so chains of small cells register a large ROI biovolume.
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

- The classification-file readers used by
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
  and
  [`ifcb_summarize_cell_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_cell_counts.md)
  are now robust to non-class `.csv` files in a class directory.
  Previously a directory that also contained an IFCB-Dashboard
  class_scores export (`{sample}_class.csv`, with a `pid` column plus
  one score column per class, and no `file_name`/`class_name` columns)
  could be picked up and either silently tolerated or fail later with a
  cryptic `Unknown or uninitialised column: 'class'` error followed by a
  WoRMS (400) Bad Request. When a folder is supplied, such files are now
  skipped with a warning naming the file and the missing columns, so a
  directory mixing dashboard score exports with ClassiPyR label files
  runs cleanly using only the valid label files. When a non-class `.csv`
  is passed explicitly, the reader aborts with a clear message
  identifying the file and the missing columns.
- [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md)
  gains a `details` argument. When `TRUE`, it returns a data frame with
  the resolved WoRMS class (`worms_class`) for each taxon instead of a
  logical vector, making it possible to audit genus homonyms,
  i.e. diatom genera such as `Navicula` or `Actinocyclus` whose names
  are shared with animals and therefore resolve to a non-diatom class in
  WoRMS. Inspect the `worms_class` column to identify such cases and add
  the affected taxa to `diatom_include`.
- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  now report the diatom classification more usefully when
  `verbose = TRUE`: the (typically short) list of classes treated as
  diatoms is printed in full, classes that could not be found in WoRMS
  are listed separately, and the (typically long) list of non-diatom
  classes is summarized as a count with a pointer to
  `ifcb_is_diatom(details = TRUE)` for auditing homonyms. Previously the
  full non-diatom list was printed and truncated with an ellipsis,
  making it hard to tell whether a diatom class had been
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
  now supports both raw-data readers used by the WHOI
  [`ifcb-features`](https://github.com/WHOIGit/ifcb-features) package.
  Release v1.1.0 replaced its `pyifcb` dependency with the much lighter
  [`ifcbkit`](https://github.com/joefutrelle/ifcbkit), which exposes a
  different API; `iRfcb` previously required `pyifcb` and therefore
  failed against v1.1.0 and later. Since
  `ifcb_py_install(features = TRUE)` installs the latest release by
  default, this affected new installations. Raw data is now read through
  an adapter that uses whichever reader is available (`ifcbkit`
  preferred when both are), so `ifcb-features` v1.0.0 and v1.1.x both
  work, including with both readers installed in the same environment.
  Set the `IRFCB_IFCB_BACKEND` environment variable to `"ifcbkit"` or
  `"pyifcb"` to force a specific reader. Computed features are
  unaffected by the choice: the `ifcb_features` code is identical
  between these releases, and the two readers agree on ROI numbering,
  the skipping of zero-sized ROIs, and pixel data. Note that installing
  `ifcb-features` v1.1.0 or later no longer pulls in `h5py` (via
  `pyifcb`), removing the binary-wheel constraint that previously
  limited which Python versions could be used.
- Fixed
  [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  writing non-numeric values into the `Eccentricity`, `MajorAxisLength`
  and `MinorAxisLength` columns of `<bin>_features_v4.csv`.
  `ifcb_features` derives these from `numpy.linalg.eig`, which returns
  complex eigenvalues (with a zero imaginary part) for real symmetric
  input from `numpy` 2.3 and later; they were written as strings such as
  `(0.797+0j)`, silently turning three numeric columns into text. The
  zero imaginary part is now dropped, so the columns are numeric again
  and the values are unchanged. This only affected environments with
  `numpy` \>= 2.3, which became reachable when `ifcb-features` v1.1.0
  dropped the `pyifcb` dependency whose pinned `scipy` had previously
  capped `numpy`. Feature values and blob masks are otherwise
  byte-identical across both readers and across old and new
  `numpy`/`scikit-image`/`scipy` versions.
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  no longer emits a `FutureWarning` per region of interest from recent
  `scikit-image` releases, which had obscured the progress bar.
  `ifcb_py_install(features = TRUE)` additionally constrains
  `scikit-image` to `< 0.28`, the release that removes the deprecated
  morphology functions `ifcb_features` calls; without the bound, a
  future `scikit-image` release would break `ifcb-features` v1.1.x
  installs, which (unlike v1.0.0, pinned via `pyifcb`) leave the version
  unconstrained.
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  gains a `feature_tag` argument to control the feature file naming. The
  default (`"features"`) writes `<bin>_features_v4.csv` as before;
  `"fea"` writes `<bin>_fea_v4.csv`, the name served by the IFCB
  Dashboard (pyifcb’s `FeaturesDirectory`).
- Corrected the
  [`vol2C_lgdiatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)
  documentation, which incorrectly stated the relationship applied to
  diatoms \> 2000 micron^3 (the Menden-Deuer and Lessard 2000
  large-diatom equation is for cells \> 3000 micron^3).
