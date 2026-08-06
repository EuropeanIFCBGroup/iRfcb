# Summarize Diatom Cell Counts and Chain-Length Statistics from IFCB Data

Summarizes the optional per-ROI cell-count data produced by the diatom
chain counter and stored in classification files (`.mat`, `.h5` or
`.csv`). For each sample and class it computes the total cell abundance
(number of cells, accounting for chains) together with a user-selectable
set of chain-length statistics.

## Usage

``` r
ifcb_summarize_cell_counts(
  class_files,
  hdr_folder = NULL,
  single_cell_values = c(-1, 0),
  stats = c("n_counted", "mean", "median", "max"),
  threshold = "opt",
  class_recursive = TRUE,
  hdr_recursive = TRUE,
  use_python = FALSE,
  verbose = TRUE
)
```

## Arguments

- class_files:

  A character vector of full paths to classification files (`.mat`,
  `.h5` or `.csv`), or a single path to a folder containing such files.
  Any of these file types can carry the optional `cell_count` data
  written by the chain counter; files without it are treated as `NA`
  chain counts. Supply a single file format per sample: a sample
  represented twice (e.g. by both a `.mat` and a `.h5`) would have its
  ROIs counted once per file, so this is rejected with an error naming
  the affected samples.

- hdr_folder:

  (Optional) Path to the folder containing HDR files. Needed for
  calculating cell abundance per liter.

- single_cell_values:

  Integer vector of `cell_count` values that should be treated as a
  single cell when computing abundance. Default is `c(-1, 0)`, i.e. both
  ROIs that were not counted and ROIs where no cells were detected count
  as one cell. Values not listed are used verbatim.

- stats:

  Character vector selecting which chain-length statistics to include.
  Any of `"n_counted"` (the number of ROIs the chain counter measured,
  which the other statistics are computed over), `"mean"`, `"median"`,
  `"max"`, and `"sd"`. Default is
  `c("n_counted", "mean", "median", "max")`. Use `character(0)` to
  return abundance only.

- threshold:

  A character string controlling which classification to use. `"opt"`
  (default) uses the threshold-applied classification, where predictions
  below the per-class optimal threshold are labeled `"unclassified"`.
  Any other value (e.g. `"all"`) uses the raw winning class.

- class_recursive:

  Logical. If `TRUE` and `class_files` is a folder, searches recursively
  for classification files. Default is `TRUE`.

- hdr_recursive:

  Logical. If `TRUE`, searches for HDR files recursively within
  `hdr_folder` (if provided). Default is `TRUE`.

- use_python:

  Logical. If `TRUE`, attempts to read `.mat` files using a Python-based
  method (`SciPy`). Default is `FALSE`.

- verbose:

  Logical. If `TRUE`, prints progress messages. Default is `TRUE`.

## Value

A data frame with one row per sample and class. Columns always include
`sample`, `classifier`, `class`, `counts` (number of ROIs), and
`cell_counts` (total cell abundance). The requested chain-length
statistics are added as `n_counted` (number of ROIs the chain counter
measured, i.e. those with `cell_count >= 1`, including single-cell
ones), `mean_chain_length`, `median_chain_length`, `max_chain_length`,
and/or `sd_chain_length`. When `hdr_folder` is provided, `ml_analyzed`
and `cell_counts_per_liter` are also returned.

`cell_counts` is `NA` for a sample whose classification file carries no
`cell_count` data, since the cell total is unknown there. It is not
reported as `0`, which would be indistinguishable from a taxon that was
genuinely absent. `counts` is unaffected and still reports the ROIs.

## Details

The chain counter stores one integer `cell_count` per region of interest
(ROI). The value `-1` marks ROIs of classes that were not configured for
chain counting, `0` marks ROIs that were counted but where no cells were
detected, and a positive value is the number of cells in that ROI.
Abundance is derived by translating the values listed in
`single_cell_values` to a single cell and using every other value
verbatim (see
[`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
which shares this logic to report `cell_counts`).

Chain-length statistics (`mean`, `median`, `max`, `sd`) are computed
only over ROIs that were genuinely chain-counted (`cell_count >= 1`);
ROIs with `-1` (not counted) or `0` (no cells detected) are excluded
from the length statistics, although both still contribute to abundance
according to `single_cell_values` (by default one cell each).

`n_counted` reports how many ROIs those length statistics were computed
over, i.e. the number of ROIs the chain counter measured
(`cell_count >= 1`). It is a count of ROIs rather than of chains, and it
includes ROIs found to hold a single cell, which are not chains. It is
useful for telling a measured abundance from an imputed one: a class
with `cell_counts > 0` but `n_counted == 0` was never chain-counted, so
its abundance is one cell per ROI by imputation rather than by
measurement.

Chain counting was introduced by Groves et al. (2026), who trained a
"You Only Look Once" (YOLO) object detection model to enumerate the
cells in diatom chains imaged by the IFCB. The per-ROI `cell_count` data
summarized here is produced by the `ifcb-pytorch-classify` inference
pipeline (<https://github.com/nodc-sweden/ifcb-pytorch-classify>), which
writes it as an optional `cell_count` variable in the `.mat`, `.h5` and
`.csv` classification files alongside the class predictions.

This function derives `cell_counts` from every classified ROI. This
differs from
[`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
which reports `cell_counts` only over ROIs that also have matching
feature (biovolume) data, so the two abundance totals can differ when
some ROIs lack feature data.

## References

Groves, G. J. J., Arthur, G., Bresnan, E., Whyte, C., Arce, P. and
Davidson, K. (2026), Automatic enumeration of chains of marine diatoms
using "You Only Look Once" - a machine learning approach. Journal of
Plankton Research, 48(2), fbaf064, doi: 10.1093/plankt/fbaf064.

## See also

[`ifcb_summarize_biovolumes`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
[`ifcb_extract_biovolumes`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
<https://github.com/nodc-sweden/ifcb-pytorch-classify>

## Examples

``` r
if (FALSE) { # \dontrun{
# Summarize chain counts and abundance from classification files
chains <- ifcb_summarize_cell_counts("path/to/class")

# Include abundance per liter and only the mean chain length
chains <- ifcb_summarize_cell_counts(
  "path/to/class",
  hdr_folder = "path/to/hdr",
  stats = "mean"
)
} # }
```
