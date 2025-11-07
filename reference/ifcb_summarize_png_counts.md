# Summarize Image Counts by Class and Sample

This function summarizes the number of images per class for each sample
and timestamps, and optionally retrieves GPS positions, and IFCB
information using `ifcb_read_hdr_data` and `ifcb_convert_filenames`
functions.

## Usage

``` r
ifcb_summarize_png_counts(
  png_folder,
  hdr_folder = NULL,
  sum_level = "sample",
  verbose = TRUE
)
```

## Arguments

- png_folder:

  A character string specifying the path to the main directory
  containing subfolders (classes) with `.png` images.

- hdr_folder:

  A character string specifying the path to the directory containing the
  `.hdr` files. Default is NULL.

- sum_level:

  A character string specifying the level of summarization. Options:
  "sample" (default) or "class".

- verbose:

  A logical indicating whether to print progress messages. Default is
  TRUE.

## Value

If sum_level is "sample", returns a data frame with columns: `sample`,
`ifcb_number`, `class_name`, `n_images`, `gpsLatitude`, `gpsLongitude`,
`timestamp`, `year`, `month`, `day`, `time`, `roi_numbers`. If sum_level
is "class", returns a data frame with columns: `class_name`, `n_images.`

## See also

[`ifcb_read_hdr_data`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_hdr_data.md)
[`ifcb_convert_filenames`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_convert_filenames.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Example usage:
# Assuming the following directory structure:
# path/to/png_folder/
# |- class1/
# |  |- sample1_00001.png
# |  |- sample1_00002.png
# |  |- sample2_00001.png
# |- class2/
# |  |- sample1_00003.png
# |  |- sample3_00001.png

png_folder <- "path/to/png_folder"
hdr_folder <- "path/to/hdr_folder" # This folder should contain corresponding .hdr files

# Summarize by sample
summary_sample <- ifcb_summarize_png_counts(png_folder,
                                            hdr_folder,
                                            sum_level = "sample",
                                            verbose = TRUE)
print(summary_sample)

# Summarize by class
summary_class <- ifcb_summarize_png_counts(png_folder,
                                           hdr_folder,
                                           sum_level = "class",
                                           verbose = TRUE)
print(summary_class)
} # }
```
