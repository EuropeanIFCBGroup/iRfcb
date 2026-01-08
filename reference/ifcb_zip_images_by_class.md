# Zip Image Subfolders by Class

This function creates one zip archive per immediate subdirectory in a
folder containing image files. Each archive corresponds to a single
class or taxon.

## Usage

``` r
ifcb_zip_images_by_class(
  image_folder,
  output_dir,
  n_images = NULL,
  quiet = FALSE
)
```

## Arguments

- image_folder:

  The directory containing subdirectories with image files.

- output_dir:

  The directory where the zip archives will be written.

- n_images:

  Integer. Maximum number of images to randomly sample per subdirectory.
  If NULL, all images are included.

- quiet:

  Logical. If TRUE, suppresses the progress bar. Default is FALSE.

## Value

This function does not return any value; it creates one zip archive per
subdirectory containing images.

## Details

When `n_images` is specified, images are randomly sampled without
replacement from each subdirectory. When `n_images` is NULL, all images
in each subdirectory are included.

Supported image formats (case-insensitive) are: `png`, `jpg`, `jpeg`,
`tif`, `tiff`, `bmp`, and `gif`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Set a random seed to reproduce the random sampling
set.seed(123)

# Create zip archives for each subdirectory with up to 50 random images
ifcb_zip_images_by_class(
  image_folder = "path/to/images",
  output_dir = "path/to/zips",
  n_images = 50
)
} # }
```
