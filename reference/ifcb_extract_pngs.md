# Extract Images from IFCB ROI File

This function reads an IFCB (`.roi`) file and its corresponding `.adc`
file, extracts regions of interest (ROIs), and saves each ROI as a PNG
image in a specified directory. Optionally, you can specify ROI numbers
to extract, useful for specific ROIs from manual or automatic
classification results. Additionally, a scale bar can be added to the
extracted images based on a specified micron-to-pixel conversion factor.

## Usage

``` r
ifcb_extract_pngs(
  roi_file,
  out_folder = dirname(roi_file),
  ROInumbers = NULL,
  taxaname = NULL,
  gamma = 1,
  normalize = FALSE,
  overwrite = FALSE,
  scale_bar_um = NULL,
  scale_micron_factor = 1/3.4,
  scale_bar_position = "bottomright",
  scale_bar_color = "black",
  old_adc = FALSE,
  verbose = TRUE
)
```

## Arguments

- roi_file:

  A character string specifying the path to the `.roi` file.

- out_folder:

  A character string specifying the directory where the PNG images will
  be saved. Defaults to the directory of the ROI file.

- ROInumbers:

  An optional numeric vector specifying the ROI numbers to extract. If
  NULL, all ROIs with valid dimensions are extracted.

- taxaname:

  An optional character string specifying the taxa name for organizing
  images into subdirectories. Defaults to NULL.

- gamma:

  A numeric value for gamma correction applied to the image. Default is
  1 (no correction). Values \<1 brighten dark regions, while values \>1
  darken the image.

- normalize:

  A logical value indicating whether to apply min-max normalization to
  stretch pixel values to the full 0-255 range. Default is FALSE, which
  preserves raw pixel values from the camera, producing images
  comparable to IFCB Dashboard and other standard IFCB software. Set to
  TRUE to stretch contrast to the full 0-255 range.

- overwrite:

  A logical value indicating whether to overwrite existing PNG files.
  Default is FALSE.

- scale_bar_um:

  An optional numeric value specifying the length of the scale bar in
  micrometers. If NULL, no scale bar is added.

- scale_micron_factor:

  A numeric value defining the conversion factor from micrometers to
  pixels. Defaults to 1/3.4.

- scale_bar_position:

  A character string specifying the position of the scale bar in the
  image. Options are `"topright"`, `"topleft"`, `"bottomright"`, or
  `"bottomleft"`. Defaults to `"bottomright"`.

- scale_bar_color:

  A character string specifying the scale bar color. Options are
  `"black"` or `"white"`. Defaults to `"black"`.

- old_adc:

  **\[deprecated\]** Previously used to indicate old ADC format. ADC
  format is now auto-detected from the HDR file and column count. This
  parameter is ignored.

- verbose:

  A logical value indicating whether to print progress messages. Default
  is TRUE.

## Value

This function is called for its side effects: it writes PNG images to a
directory.

## See also

[`ifcb_extract_classified_images`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_classified_images.md)
for extracting ROIs from automatic classification.

[`ifcb_extract_annotated_images`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_annotated_images.md)
for extracting ROIs from manual annotation.

## Examples

``` r
if (FALSE) { # \dontrun{
# Convert ROI file to PNG images
ifcb_extract_pngs("path/to/your_roi_file.roi")

# Extract specific ROI numbers from ROI file
ifcb_extract_pngs("path/to/your_roi_file.roi", "output_directory", ROInumbers = c(1, 2, 3))

# Extract images with a 5 micrometer scale bar
ifcb_extract_pngs("path/to/your_roi_file.roi", scale_bar_um = 5)
} # }
```
