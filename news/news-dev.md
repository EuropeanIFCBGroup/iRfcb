# Version dev

## iRfcb (development version)

### New features

- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  gain a `custom_cell_counts` argument, so `use_cell_counts = TRUE` (and
  with it `carbon_conversion = "cell"`) now works with
  `custom_images`/`custom_classes`, which previously could not use
  chain-count abundance or per-cell carbon at all. The counts are
  matched to `custom_images` by position and follow the same semantics
  as counts read from classification files, including `NA` marking a ROI
  without chain-count data, which makes the affected sample’s
  `cell_counts` `NA` rather than a silent partial sum. Invalid input
  (wrong length, all-`NA`, counts without `custom_images` or without
  `use_cell_counts = TRUE`) fails with an error saying what to change.

### Minor improvements and fixes

- `.h5` classification files are read several times faster, by skipping
  a full garbage collection per file.
- A damaged or incomplete `.h5` classification file now stops with an
  error naming the file and what is wrong with it, instead of a
  misleading `class_labels_auto does not exist` or a raw HDF5 error.
- Fixed the scores of single-class `.h5` classification files being read
  transposed.
