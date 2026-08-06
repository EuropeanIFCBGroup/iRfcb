# Plot and Save IFCB PSD Data

This function generates and saves data about a dataset's Particle Size
Distribution (PSD) from Imaging FlowCytobot (IFCB) feature and hdr
files, which can be used for data quality assurance and quality control.

## Usage

``` r
ifcb_psd(
  feature_folder,
  hdr_folder,
  bins = NULL,
  save_data = FALSE,
  output_file = NULL,
  plot_folder = NULL,
  use_marker = FALSE,
  start_fit = 10,
  r_sqr = 0.5,
  beads = NULL,
  bubbles = NULL,
  incomplete = NULL,
  missing_cells = NULL,
  biomass = NULL,
  bloom = NULL,
  humidity = NULL,
  micron_factor = 1/3.4,
  fea_v = 2,
  use_plot_subfolders = TRUE,
  ...
)
```

## Arguments

- feature_folder:

  The absolute path to a directory containing all of the feature files
  for the dataset (version can be defined in `fea_v`).

- hdr_folder:

  The absolute path to a directory containing all of the hdr files for
  the dataset.

- bins:

  An optional character vector of bin names (e.g.,
  `"D20251021T133007_IFCB134"`) to restrict processing to a specified
  subset of bins. If `NULL` (default), all bins present in
  `feature_folder` are processed.

- save_data:

  A logical indicating whether to save data to CSV files. Default is
  FALSE.

- output_file:

  A string with the base file name for the .csv output (including path).
  Set to NULL to avoid saving data (default).

- plot_folder:

  The folder where graph images for each sample will be saved. If `NULL`
  (default), plots are not saved. If `use_plot_subfolders = TRUE`, plots
  are organized into subfolders based on their flag status.

- use_marker:

  A logical indicating whether to show markers on the plot. Default is
  FALSE.

- start_fit:

  An integer indicating the start fit value for the plot. Default is 10.
  The value is the index of the first 1 micron ESD bin included in the
  curve fit, calibrated for version 2 features. See the Feature file
  version section before using it with another version.

- r_sqr:

  The lower limit of acceptable R^2 values (any curves below it will be
  flagged). Default is 0.5.

- beads:

  The maximum multiplier for the curve fit. Any files with higher curve
  fit multipliers will be flagged as bead runs. If this argument is
  included, files with `"runBeads"` marked as TRUE in the header file
  will also be flagged. Optional.

- bubbles:

  The minimum difference between the starting ESD and the ESD with the
  most targets. Files with a difference higher than this threshold will
  be flagged as mostly bubbles. Optional.

- incomplete:

  A numeric vector of length 2 giving the minimum volume of cells (in
  c/L) and the minimum mL analyzed for a complete run. Files with values
  below these thresholds will be flagged as incomplete. Optional.

- missing_cells:

  The minimum image count ratio threshold. Files with ratios below this
  value will be flagged as missing cells. Optional.

- biomass:

  The minimum number of targets in the most populated ESD bin for any
  given run. Files with fewer targets will be flagged as low biomass.
  Optional.

- bloom:

  The minimum difference between the starting ESD and the ESD with the
  most targets. Files with a difference less than this threshold will be
  flagged as bloom events. This threshold is usually lower than the
  bubbles threshold. Optional.

- humidity:

  The maximum percent humidity. Files with higher values will be flagged
  as high humidity. Optional.

- micron_factor:

  Conversion factor from microns per pixel (default: 1/3.4).

- fea_v:

  The version number of the IFCB feature file (e.g., 2, 4). Default is
  2, as described in Hayashi et al. 2025. The function reads other
  versions unchanged, but the default `start_fit` and flag thresholds
  only apply to version 2. Re-derive them first; see the Feature file
  version section. **\[experimental\]**

- use_plot_subfolders:

  A logical indicating whether to save plots in subfolders based on the
  sample's flag status. If TRUE (default), samples without flags are
  saved in a "PSD.OK" subfolder, and samples with flags are saved in
  subfolders named after their flag(s). If FALSE, all plots are saved
  directly in `plot_folder`.

- ...:

  Additional arguments passed to `ggsave()`. These override the default
  width, height, dpi, and background color when saving plots. For
  example, `width = 7, dpi = 300` can be supplied.

## Value

A list containing three tibbles:

- data:

  A tibble with flattened PSD data for each sample.

- fits:

  A tibble containing curve fit parameters for each sample.

- flags:

  A tibble of flags for each sample, or NULL if no flags are found.

The `save_data` parameter only controls whether CSV files are written to
disk; the function always returns this list.

## Details

The PSD function originates from the `PSD` Python repository (Hayashi et
al. 2025), which can be found at <https://github.com/kudelalab/PSD>.

Python must be installed to use this function. The required Python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

## Feature file version

The PSD is built from one feature, `EquivDiameter`, converted to microns
with `micron_factor` and binned into 1 micron bins. The fitted curve,
`max_ESD_diff` and every flag derived from them all follow from that
single distribution.

`EquivDiameter` is not directly comparable between feature set versions.
The version 4 extractor (`ifcb-features`, see
[`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md))
segments a tighter blob boundary than the version 2 MATLAB extractor
(`ifcb-analysis`), so it reports a smaller equivalent diameter for the
same image. The difference is roughly a fixed number of pixels rather
than a fixed proportion. It therefore converts to microns through
`micron_factor`, and moves the whole ESD histogram towards smaller bins
by about that many microns. Small particles lose a larger share of their
diameter than large ones.

The thresholds published by Hayashi et al. (2025) were calibrated on
version 2 features and do not carry over unchanged:

- `start_fit` selects a histogram bin. When the distribution moves, the
  fit window sits at a different position relative to the peak, which
  changes the fitted exponent as well as the multiplier. The `r_sqr` and
  `beads` flags read those two values.

- `bloom` and `bubbles` are evaluated against `max_ESD_diff`, which is
  measured relative to `start_fit`. They move with the shifted
  distribution, and again with any compensating change to `start_fit`.

- `biomass` and `incomplete` depend on the height of the most populated
  bin, which changes as the shift moves targets between bins.

With a version other than 2, measure the offset on your own data instead
of assuming a published value: extract both feature versions for a set
of representative bins, compare `EquivDiameter` per ROI, and lower
`start_fit` by the median difference in whole microns. Re-derive the
flag thresholds on that basis, and report the feature version together
with any quality flags you publish. `micron_factor` sets what the offset
amounts to in microns, so an instrument with a different pixel size
needs its own value.

The file name is the only other place the version is used: features are
read as `<bin>_fea_v<fea_v>.csv`.
[`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
writes `<bin>_features_v4.csv` by default, so pass `feature_tag = "fea"`
there to get the names this function searches for.

## References

Hayashi, K., Enslein, J., Lie, A., Smith, J., Kudela, R.M., 2025. Using
particle size distribution (PSD) to automate imaging flow cytobot (IFCB)
data quality in coastal California, USA. International Society for the
Study of Harmful Algae. https://doi.org/10.15027/0002041270

## See also

[`ifcb_py_install`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md),
[`ifcb_extract_features`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md),
<https://github.com/kudelalab/PSD>

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize the Python session if not already set up
ifcb_py_install()

ifcb_psd(
  feature_folder = 'path/to/features',
  hdr_folder = 'path/to/hdr_data',
  bins = c("D20211021T133007_IFCB134", "D20211021T140753_IFCB134"),
  save_data = TRUE,
  output_file = 'psd/svea_2021',
  plot_folder = 'psd/plots',
  use_marker = FALSE,
  start_fit = 13,
  r_sqr = 0.5,
  beads = 10 ** 9,
  bubbles = 150,
  incomplete = c(1500, 3),
  missing_cells = 0.7,
  biomass = 1000,
  bloom = 5,
  humidity = NULL,
  micron_factor = 1/2.77,
  fea_v = 2
)
} # }
```
