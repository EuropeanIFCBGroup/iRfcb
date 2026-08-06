# Version dev

## iRfcb (development version)

### New features

- Added support for the per-ROI `cell_count` data produced by the diatom
  chain counter (Groves et al. 2026,
  [doi:10.1093/plankt/fbaf064](https://doi.org/10.1093/plankt/fbaf064))
  through the
  [`ifcb-pytorch-classify`](https://github.com/nodc-sweden/ifcb-pytorch-classify)
  pipeline and stored in `.mat`, `.h5` and `.csv` classification files.
  Abundance can now be reported in cells rather than images, so a chain
  of eight cells counts as eight.
  - New
    [`ifcb_summarize_cell_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_cell_counts.md)
    reports cell abundance and chain-length statistics (`n_counted`,
    `mean`, `median`, `max`, `sd`) per sample and class, and abundance
    per liter when given an `hdr_folder`. `n_counted` is the number of
    ROIs the chain counter measured, including those it found to hold a
    single cell.
  - [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    and
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    gain a `use_cell_counts` argument. When `TRUE`,
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    adds a `cell_counts` column, and `cell_counts_per_liter` when an
    `hdr_folder` is supplied.
  - `single_cell_values` (default `c(-1, 0)`) sets which `cell_count`
    values are read as one cell: by default the ROIs the counter skipped
    (`-1`) and those where it found no cells (`0`). Any other value is
    used as it stands.
  - `cell_counts` is `NA` rather than `0` for a sample whose
    classification file carries no `cell_count` data, since a zero would
    look the same as a taxon that was genuinely absent. `counts` still
    reports the images, and a warning says how many files were affected.
  - The SHARK column template
    ([`ifcb_get_shark_colnames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md)
    and
    [`ifcb_get_shark_example()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_example.md))
    gains an `IMAGE_COUNT` column after `COUNT`. Dividing `COUNT` by
    `IMAGE_COUNT` gives the average cells per image. That is not the
    same as `mean_chain_length`, which averages only over the images the
    counter actually measured, whereas the ratio includes the images it
    never looked at.
- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  gain two arguments controlling how the Menden-Deuer and Lessard (2000)
  carbon equations are applied. Both keep the previous behavior by
  default, so carbon values do not change unless you set one.
  - `diatom_equation` chooses the diatom equation. `"large"` (the
    default) uses the large-diatom equation, as `ifcb-analysis` does;
    `"all"` uses the all-sizes equation, which gives small cells more
    carbon; `"auto"` chooses per ROI by volume, keeping each equation
    inside the size range it was fitted for. The two disagree at the
    3000 micron^3 boundary, predicting about 190 against 135 pgC, so
    `"auto"` makes carbon fall as a cell grows past it. That is why it
    is not the default. New helpers
    [`vol2C_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_diatom.md)
    and
    [`vol2C_diatom_auto()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_diatom_auto.md)
    are exported.
  - `carbon_conversion` chooses the volume the equation is applied to.
    The equations are fitted per cell, but an IFCB biovolume covers a
    whole image, which for a chain-forming diatom is the whole chain, so
    converting the chain volume in one go under-reports carbon. `"cell"`
    converts per cell and sums over the chain, and requires
    `use_cell_counts = TRUE`. See
    [`?ifcb_extract_biovolumes`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    for how large the difference gets.
  - Biovolume itself is unchanged by either argument. It is still
    measured per image, so a chain of small cells still gives one large
    biovolume.
- Added
  [`ifcb_qc_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_qc_sample.md),
  which checks raw IFCB samples (the `.hdr`, `.adc` and `.roi` triplet)
  and returns one row of QC metrics and flags per sample. It looks for
  missing files, ROI counts that disagree with the header, truncated
  `.roi` files, run times that contradict the ADC, implausible analyzed
  volumes, and ROI dimensions that failed to parse. Bead runs, empty
  samples, oversized `.roi` files and high recorded humidity or
  temperature are reported as advisory flags and do not fail `qc_pass`.
  A check that cannot be run on a sample is reported as `NA` and does
  not fail it either, so legacy headers without a `roiCount` field are
  not penalized for a check that could never apply. The function accepts
  a directory, sample names with a `data_folder`, or explicit file
  paths, and needs no Python.

### Minor improvements and fixes

- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  and
  [`ifcb_summarize_cell_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_cell_counts.md)
  now stop with an error when one sample resolves to more than one
  classification file, for example a folder holding both a `.mat` and an
  `.h5` for the same sample, and name the samples involved. Previously
  both files were read and joined, which silently doubled that sample’s
  counts, biovolume and carbon.
- The classification-file readers no longer trip over non-class `.csv`
  files in a class directory. An IFCB Dashboard `class_scores` export
  (`{sample}_class.csv`) could be picked up and then fail with a
  confusing `Unknown or uninitialised column: 'class'` error followed by
  a WoRMS 400 response. Such files are now skipped with a warning naming
  the missing columns when a folder is supplied, and raise a clear error
  when passed explicitly.
- [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md)
  gains a `details` argument. When `TRUE` it returns a data frame with
  the WoRMS class resolved for each taxon instead of a logical vector.
  Use it to find genus homonyms, that is diatom genera such as
  `Navicula` or `Actinocyclus` that share a name with an animal and so
  resolve to a non-diatom class, then add those taxa to
  `diatom_include`.
- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  report the diatom classification more clearly when `verbose = TRUE`.
  The classes treated as diatoms are listed in full, classes missing
  from WoRMS are listed separately, and the long list of non-diatoms is
  reduced to a count. Previously that list was printed and truncated,
  making it hard to see whether a class you expected to be a diatom had
  been recognized as one.
- Creating and editing MATLAB `ifcb-analysis` manual classification
  files no longer requires Python.
  [`ifcb_create_class2use()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_class2use.md),
  [`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md),
  [`ifcb_adjust_classes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_adjust_classes.md),
  [`ifcb_correct_annotation()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md),
  [`ifcb_replace_mat_values()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_replace_mat_values.md)
  and the `format = "mat"` output of
  [`ifcb_save_classification()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_save_classification.md)
  write `.mat` files with a native R implementation, producing the same
  output as the previous `scipy.io.savemat` approach. The wrapper
  functions that call them are Python-free as a result, so `scipy` and
  `numpy` are no longer needed for annotation work.
- Removed `R.matlab` as a dependency. Reading `.mat` files without
  Python now uses the native R reader as well, which decodes MATLAB
  UTF-16 text correctly, so accented class or path names survive where
  [`R.matlab::readMat()`](https://rdrr.io/pkg/R.matlab/man/readMat.html)
  could mangle them. It reads every numeric storage type MATLAB uses to
  hold an array compactly (`int8` through `uint32`, `single` and
  `double`), preserving each across a read-write round-trip, including
  values at the signed and unsigned 32-bit limits that R cannot hold in
  an integer. The reader also refuses input it cannot represent
  faithfully, naming the variable and the reason, reports a truncated
  file instead of reading it back quietly padded with zeros, and rejects
  declared dimensions that disagree with the data carried rather than
  recycling values to fill them out. All of this matters because
  [`ifcb_adjust_classes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_adjust_classes.md)
  and
  [`ifcb_correct_annotation()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md)
  write what they read back over the same file. One thing it tolerates
  rather than refuses: a compressed section that ends without its stream
  terminator, which some classification files written by MATLAB contain.
  The data in those is intact, so it is decoded incrementally and read,
  with a warning naming the file. `R.matlab` has moved to `Suggests`.
  - Note that this makes reading stricter than in 0.9.0, so a file that
    used to open may now stop with an error. `R.matlab` would read a
    `.mat` containing a struct, an object, a sparse or complex array, a
    logical array, more than two dimensions, or a MATLAB string array
    (as saved by `class2use = ["a" "b"]` in a recent MATLAB release),
    and iRfcb would then quietly write back something that was not what
    it read. Those files are now named and refused instead. The formats
    iRfcb itself deals with are unaffected: manual files, `class2use`
    files and classifier output written by MATLAB `ifcb-analysis` or the
    Python pipelines all read as before. If you do have a third-party
    file that no longer opens,
    [`ifcb_get_mat_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_names.md)
    and
    [`ifcb_get_mat_variable()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_variable.md)
    read it with `use_python = TRUE`, which goes through `SciPy`
    instead, once a Python environment has been set up with
    [`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  now works with both raw-data readers used by WHOI
  [`ifcb-features`](https://github.com/WHOIGit/ifcb-features). Release
  v1.1.0 swapped `pyifcb` for the lighter
  [`ifcbkit`](https://github.com/WHOIGit/ifcbkit), which broke `iRfcb`
  against v1.1.0 and later, and since `ifcb_py_install(features = TRUE)`
  installs the newest release by default this affected new
  installations. Either reader now works, and a new `backend` argument
  (or the `IRFCB_IFCB_BACKEND` environment variable) pins one.
  Measurements are unaffected for the D-style bins current instruments
  produce. The readers differ only on older I-style bins and on ROIs
  with zero height, so pin a reader if you need results comparable to an
  earlier I-style run. Installing v1.1.0 or later also drops the `h5py`
  dependency, which had restricted which Python versions could be used.
- Fixed
  [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  writing text instead of numbers into the `Eccentricity`,
  `MajorAxisLength` and `MinorAxisLength` columns of
  `<bin>_features_v4.csv`. On `numpy` 2.3 and later these values arrived
  as complex numbers and were written as strings such as `(0.797+0j)`,
  quietly turning three numeric columns into text. They are numeric
  again and the values are unchanged, with one exception worth knowing
  about for size spectra and biovolume sums: a degenerate,
  one-pixel-wide blob is now measured as `0` rather than `NaN`, so it
  contributes a zero instead of a missing value you could filter out.
  That matches upstream `ifcb-features` and the `summed*` columns. To
  reproduce an earlier run, pin `ifcb-features` v1.0.0 or `numpy < 2.3`;
  see
  [`?ifcb_py_install`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  no longer prints a `FutureWarning` for every region of interest from
  recent `scikit-image` releases, which had been breaking up the
  progress bar. `ifcb_py_install(features = TRUE)` also holds
  `scikit-image` below 0.28, the release that removes the deprecated
  functions `ifcb_features` calls.
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  no longer discards a whole sequential run when one bin cannot be read.
  A corrupt or truncated `.roi` used to escape as a Python traceback,
  taking every bin already processed with it. Such a bin is now reported
  as a per-bin error like any other.
- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  gains a `feature_tag` argument controlling the feature file name. The
  default (`"features"`) writes `<bin>_features_v4.csv` as before;
  `"fea"` writes `<bin>_fea_v4.csv`, the name the IFCB Dashboard serves.
- Fixed
  [`ifcb_volume_analyzed_from_adc()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed_from_adc.md)
  failing when given more than one ADC file, or a URL. The existence
  check was not vectorized, so a vector of files stopped with
  `the condition has length > 1` even though the rest of the function
  already looped over them, and it rejected URLs outright even though
  the rest of the function handles remote files. Local paths are now
  checked one by one, with every missing path reported at once, and URLs
  pass straight through.
- [`ifcb_correct_annotation()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md)
  and
  [`ifcb_replace_mat_values()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_replace_mat_values.md)
  now check their inputs and fail with a message you can act on. An
  out-of-range ROI number or `column_index` reports the value and the
  valid range instead of `subscript out of bounds`, and a missing input
  file or a `.mat` file without a `classlist` variable is named
  explicitly.
- Fixed `use_python = TRUE` being ignored when Python and `SciPy` were
  in fact available.
  [`ifcb_get_mat_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_names.md),
  [`ifcb_get_mat_variable()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_variable.md),
  [`ifcb_read_summary()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_summary.md),
  [`ifcb_count_mat_annotations()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_count_mat_annotations.md),
  [`ifcb_extract_annotated_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
  and
  [`ifcb_adjust_classes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_adjust_classes.md)
  decided whether they could use Python by looking for `scipy` in
  [`reticulate::py_list_packages()`](https://rstudio.github.io/reticulate/reference/py_list_packages.html),
  and fell back to the R reader without saying so when it was not
  listed. Two things went wrong with that: on a `conda` environment the
  listing reports conda’s own base packages, so an installed and
  perfectly importable `scipy` was absent from it; and the check did not
  initialize Python, so in a fresh session it failed whatever the
  environment held. Availability is now settled by asking Python to
  import the module. This matters most when a `.mat` file cannot be read
  by the R reader, since `use_python = TRUE` is the documented way to
  read it.
- Clarified the deprecation of `ifcb_read_hdr_data(hdr_folder = )` and
  `ifcb_annotate_batch(adc_folder = )`. Both read as though the package
  had renamed `hdr_folder` and `adc_folder` everywhere, which it has
  not: those two functions were changed to accept a vector of file
  paths, so their argument was renamed to match. Functions that
  genuinely take a single directory, such as
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
  [`ifcb_summarize_cell_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_cell_counts.md)
  and
  [`ifcb_annotate_samples()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_annotate_samples.md),
  keep `hdr_folder` and `adc_folder` and are not deprecated.
- Corrected the
  [`vol2C_lgdiatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)
  documentation, which said the relationship applied to diatoms above
  2000 micron^3. The Menden-Deuer and Lessard (2000) large-diatom
  equation is for cells above 3000 micron^3.
- Examples that call remote services
  ([`ifcb_download_dashboard_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md),
  [`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md),
  [`ifcb_match_taxa_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_match_taxa_names.md)
  and
  [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md))
  are now wrapped in [`try()`](https://rdrr.io/r/base/try.html) so they
  fail gracefully when the service is unreachable.
