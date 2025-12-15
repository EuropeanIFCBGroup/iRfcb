# Run IFCB Image Gallery

Launches a Shiny application that provides an interactive interface for
browsing and managing IFCB (Imaging FlowCytobot) image galleries.

## Usage

``` r
ifcb_run_image_gallery()
```

## Value

No return value. This function launches a Shiny application for
interactive image browsing and management.

## Details

Users can specify a folder containing .png images, navigate through the
images, select and unselect images, and download a list of selected
images. This feature is particularly useful for quality control of
annotated images. A downloaded list of images from the app can also be
uploaded to filter and view only the selected images.

## Examples

``` r
# \donttest{
# Run the IFCB image gallery Shiny app
if(interactive()){
  ifcb_run_image_gallery()
}
# }
```
