utils::globalVariables(c("biovolume_um3", "carbon_pg", "counts", "classifier", "cell_count_resolved", "cell_counts", "."))
#' Summarize Biovolumes and Carbon Content from IFCB Data
#'
#' This function calculates aggregated biovolumes and carbon content from Imaging FlowCytobot (IFCB)
#' samples based on biovolume information from feature files. Images are grouped into classes either
#' based on classification files (`.mat`, `.h5`, or `.csv`), manually annotated files, or a
#' user-supplied list of images and their corresponding class labels (e.g. from a CNN model).
#'
#' @param feature_folder Path to the folder containing feature files (e.g., CSV format).
#' @param class_files (Optional) A character vector of full paths to classification or manual
#'   annotation files (`.mat`, `.h5`, or `.csv`), or a single path to a folder
#'   containing such files. Supply a single file format per sample: a sample
#'   represented twice (e.g. by both a `.mat` and a `.h5`) would have its ROIs
#'   counted once per file, so this is rejected with an error naming the
#'   affected samples.
#' @param class2use_file (Optional) A character string specifying the path to the file containing the class2use variable (default NULL). Only needed when summarizing manual MATLAB results.
#' @param hdr_folder (Optional) Path to the folder containing HDR files. Needed for calculating cell, biovolume and carbon concentration per liter.
#' @param custom_images (Optional) A character vector of image filenames in the format DYYYYMMDDTHHMMSS_IFCBXXX_ZZZZZ(.png),
#'        where "XXX" represents the IFCB number and "ZZZZZ" represents the ROI number.
#'        These filenames should match the `roi_number` assignment in the `feature_files` and can be
#'        used as a substitute for classification files.
#' @param custom_classes (Optional) A character vector of corresponding class labels for `custom_images`.
#' @param micron_factor Conversion factor from microns per pixel (default: 1/3.4).
#' @param diatom_class A character vector of diatom class names in the World Register of Marine Species (WoRMS). Default is "Bacillariophyceae".
#' @param diatom_include Optional character vector of class names that should always be treated as diatoms,
#'        overriding the boolean result of \code{ifcb_is_diatom}. Default: NULL.
#' @param marine_only Logical. If TRUE, restricts the WoRMS search to marine taxa only. Default is FALSE.
#' @param diatom_equation A character string selecting which Menden-Deuer and Lessard (2000)
#'   carbon-to-volume relationship to apply to diatoms. `"large"` (default) uses the
#'   large-diatom (> 3000 micron^3) equation, matching the `ifcb-analysis` convention.
#'   `"all"` uses the all-sizes diatom equation, which assigns more carbon to small
#'   cells. `"auto"` selects between them per volume (large-diatom above
#'   3000 micron^3, all-sizes at or below), keeping each in its calibrated range at
#'   the cost of a discontinuity at the boundary, where predicted carbon falls from
#'   about 190 to 135 pgC as volume increases. Note that biovolume is measured per
#'   region of interest (ROI/image), not per cell, so chains of small cells register
#'   a large ROI biovolume unless `carbon_conversion = "cell"` is used. Passed to
#'   \code{ifcb_extract_biovolumes}.
#' @param threshold A character string controlling which classification to use.
#'   `"opt"` (default) uses the threshold-applied classification, where
#'   predictions below the per-class optimal threshold are labeled
#'   `"unclassified"`. Any other value (e.g. `"all"`) uses the raw winning
#'   class without any threshold applied.
#' @param feature_recursive Logical. If TRUE, the function will search for feature files recursively within the `feature_folder`. Default is TRUE.
#' @param class_recursive Logical. If TRUE, the function will search for classification files recursively when `class_files` is a folder. Default is TRUE.
#' @param hdr_recursive Logical. If TRUE, the function will search for HDR files recursively within the `hdr_folder` (if provided). Default is TRUE.
#' @param drop_zero_volume Logical. If `TRUE`, rows where `Biovolume` equals zero (e.g., artifacts such as smudges on the flow cell) are removed. Default: `FALSE`.
#' @param feature_version Optional numeric or character version to filter feature files by (e.g. 2 for "_v2"). Default is NULL (no filtering).
#' @param use_cell_counts Logical. If `TRUE`, reads the optional per-ROI `cell_count` data
#'   stored by the diatom chain counter in `.mat`/`.h5`/`.csv` classification files and adds
#'   `cell_counts` (and `cell_counts_per_liter` when `hdr_folder` is supplied) to the output,
#'   reporting cell abundance alongside ROI counts. Only supported with automated `class_files`.
#'   The function aborts if enabled but no classification file contains chain-count data. For
#'   chain-length statistics (mean, median, max chain length) use
#'   \code{\link{ifcb_summarize_cell_counts}}. Note that `cell_counts` here is summed only over
#'   ROIs that also have matching feature (biovolume) data (the same ROI population as `counts`);
#'   \code{\link{ifcb_summarize_cell_counts}} instead sums over all classified ROIs, so the two
#'   abundance totals can differ. Default is `FALSE`.
#' @param single_cell_values Integer vector of `cell_count` values that should be treated as a
#'   single cell when computing `cell_counts`. Default is `c(-1, 0)`, i.e. ROIs that were not
#'   counted (`-1`) and ROIs where no cells were detected (`0`) each count as one cell. Values
#'   not listed are used verbatim. Only used when `use_cell_counts = TRUE`.
#' @param carbon_conversion A character string controlling how the Menden-Deuer and
#'   Lessard (2000) relationships are applied. `"roi"` (default) applies the selected
#'   equation once to the whole ROI biovolume, matching the `ifcb-analysis`
#'   convention and reproducing previous results exactly. `"cell"` applies it to the
#'   per-cell volume and sums over the chain, which is how the relationships are
#'   defined; it requires `use_cell_counts = TRUE`. `carbon_ug` remains a per-class
#'   total in both cases. Unlike `cell_counts`, it is not `NA` for a sample whose
#'   classification file carries no `cell_count` data: those ROIs are converted as
#'   single cells, which is the value reported today rather than an unknown. See
#'   \code{\link{ifcb_extract_biovolumes}} for the full rationale.
#' @param use_python Logical. If `TRUE`, attempts to read the `.mat` file using a Python-based method. Default is `FALSE`.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @param mat_folder `r lifecycle::badge("deprecated")`
#'    Use \code{class_files} instead.
#' @param mat_files `r lifecycle::badge("deprecated")`
#'    Use \code{class_files} instead.
#' @param mat_recursive `r lifecycle::badge("deprecated")`
#'    Use \code{class_recursive} instead.
#'
#' @return A data frame summarizing aggregated biovolume and carbon content per class per sample.
#'   Columns include 'sample', 'classifier', 'class', 'biovolume_mm3', 'carbon_ug', 'ml_analyzed',
#'   'biovolume_mm3_per_liter', and 'carbon_ug_per_liter'. When `use_cell_counts = TRUE`, the cell
#'   abundance columns 'cell_counts' (and 'cell_counts_per_liter' when `hdr_folder` is provided) are
#'   also included. `cell_counts` is `NA` for a sample whose classification file carries no
#'   `cell_count` data, since the cell total is unknown there; it is not reported as `0`, which
#'   would be indistinguishable from a taxon that was genuinely absent.
#'
#' @details This function performs the following steps:
#' \enumerate{
#'   \item Extracts biovolumes and carbon content from feature and classification results using `ifcb_extract_biovolumes`.
#'   \item Optionally incorporates volume data from HDR files to calculate volume analyzed per sample.
#'   \item Computes biovolume and carbon content per liter of sample analyzed.
#' }
#'
#' The classification or manual annotation files are generated by the `ifcb-analysis` repository
#' (Sosik and Olson 2007). Users can optionally provide a **custom classification** by supplying a vector of image filenames
#' (`custom_images`) along with corresponding class labels (`custom_classes`). This allows summarization
#' of biovolume and carbon content without requiring classification or manual annotation files
#' (e.g. results from a CNN model).
#'
#' Biovolumes are converted to carbon according to Menden-Deuer and Lessard 2000
#' for individual regions of interest (ROI), applying different conversion factors to diatoms and
#' non-diatom protists. The diatom relationship is selected with `diatom_equation`
#' (`"large"`, the default, or `"all"`). If provided, the function also incorporates sample volume
#' data from HDR files to compute biovolume and carbon content per liter of sample.
#'
#' If `use_python = TRUE`, the function tries to read the `.mat` file using `ifcb_read_mat()`, which relies on `SciPy`.
#' This approach may be faster than the default R reader, especially for large `.mat` files.
#' To enable this functionality, ensure Python is properly configured with the required dependencies.
#' You can initialize the Python environment and install necessary packages using `ifcb_py_install()`.
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' ifcb_summarize_biovolumes("path/to/features", "path/to/classified",
#'                           hdr_folder = "path/to/hdr")
#'
#' # Using custom classification result:
#' images <- c("D20220522T003051_IFCB134_00002",
#'             "D20220522T003051_IFCB134_00003")
#' classes <- c("Mesodinium_rubrum",
#'              "Mesodinium_rubrum")
#'
#' ifcb_summarize_biovolumes(feature_folder = "path/to/features",
#'                           hdr_folder = "path/to/hdr",
#'                           custom_images = images,
#'                           custom_classes = classes)
#' }
#'
#' @references Menden-Deuer Susanne, Lessard Evelyn J., (2000), Carbon to volume relationships for dinoflagellates, diatoms, and other protist plankton, Limnology and Oceanography, 45(3), 569-579, doi: 10.4319/lo.2000.45.3.0569.
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @references Groves, G. J. J., Arthur, G., Bresnan, E., Whyte, C., Arce, P. and Davidson, K. (2026), Automatic enumeration of chains of marine diatoms using "You Only Look Once" - a machine learning approach. Journal of Plankton Research, 48(2), fbaf064, doi: 10.1093/plankt/fbaf064.
#'
#' @seealso \code{\link{ifcb_summarize_cell_counts}} \code{\link{ifcb_extract_biovolumes}} \url{https://github.com/nodc-sweden/ifcb-pytorch-classify}
#'
#' @export
ifcb_summarize_biovolumes <- function(feature_folder, class_files = NULL, class2use_file = NULL,
                                      hdr_folder = NULL, custom_images = NULL, custom_classes = NULL,
                                      micron_factor = 1 / 3.4, diatom_class = "Bacillariophyceae", diatom_include = NULL,
                                      marine_only = FALSE, diatom_equation = c("large", "all", "auto"),
                                      threshold = "opt", feature_recursive = TRUE,
                                      class_recursive = TRUE, hdr_recursive = TRUE, drop_zero_volume = FALSE,
                                      feature_version = NULL, use_cell_counts = FALSE,
                                      single_cell_values = c(-1, 0), carbon_conversion = c("roi", "cell"),
                                      use_python = FALSE, verbose = TRUE,
                                      mat_folder = deprecated(), mat_files = deprecated(), mat_recursive = deprecated()) {

  # Validate here as well as in ifcb_extract_biovolumes(), so the error names
  # the function the user actually called.
  carbon_conversion <- match.arg(carbon_conversion)
  check_carbon_conversion(carbon_conversion, use_cell_counts)

  # Handle deprecated mat_folder argument
  if (lifecycle::is_present(mat_folder)) {
    deprecate_warn("0.7.0", "iRfcb::ifcb_summarize_biovolumes(mat_folder = )", "iRfcb::ifcb_summarize_biovolumes(class_files = )")
    class_files <- mat_folder
  }

  # Handle deprecated mat_files argument
  if (lifecycle::is_present(mat_files)) {
    deprecate_warn("0.8.0", "iRfcb::ifcb_summarize_biovolumes(mat_files = )", "iRfcb::ifcb_summarize_biovolumes(class_files = )")
    class_files <- mat_files
  }

  # Handle deprecated mat_recursive argument
  if (lifecycle::is_present(mat_recursive)) {
    deprecate_warn("0.8.0", "iRfcb::ifcb_summarize_biovolumes(mat_recursive = )", "iRfcb::ifcb_summarize_biovolumes(class_recursive = )")
    class_recursive <- mat_recursive
  }

  # Extract biovolumes and carbon content from feature and class files
  biovolumes <- ifcb_extract_biovolumes(feature_files = feature_folder,
                                        class_files = class_files,
                                        custom_images = custom_images,
                                        custom_classes = custom_classes,
                                        class2use_file = class2use_file,
                                        micron_factor = micron_factor,
                                        diatom_class = diatom_class,
                                        diatom_include = diatom_include,
                                        marine_only = marine_only,
                                        diatom_equation = diatom_equation,
                                        threshold = threshold,
                                        feature_recursive = feature_recursive,
                                        class_recursive = class_recursive,
                                        drop_zero_volume = drop_zero_volume,
                                        feature_version = feature_version,
                                        use_cell_counts = use_cell_counts,
                                        single_cell_values = single_cell_values,
                                        carbon_conversion = carbon_conversion,
                                        use_python = use_python,
                                        verbose = verbose)

  # Aggregate biovolumes and carbon content by sample and class
  biovolume_aggregated <- biovolumes %>%
    group_by(sample, classifier, class) %>%
    summarise(counts = n(),
              # ROIs from a file without a `cell_count` dataset carry NA. Summing
              # them with na.rm = TRUE would report 0 cells for a taxon present
              # in the images, so the group total is reported as NA instead.
              cell_counts = if (!use_cell_counts) NA_real_
                            else if (any(is.na(cell_count_resolved))) NA_real_
                            else sum(cell_count_resolved),
              biovolume_mm3 = sum(biovolume_um3 * 10^-9, na.rm = TRUE),  # Convert from um3 to mm3
              carbon_ug = sum(carbon_pg * 10^-6, na.rm = TRUE),  # Convert from pg to ug
              .groups = 'drop')

  # Drop the cell_counts placeholder column when chain counts are not used
  if (!use_cell_counts) {
    biovolume_aggregated$cell_counts <- NULL
  }

  # Optionally incorporate sample volume data from HDR files if provided and calculate volume normalized values
  if (!is.null(hdr_folder)) {
    hdr_files <- list.files(hdr_folder, pattern = "D.*\\.hdr", full.names = TRUE, recursive = hdr_recursive)

    # Extract sample names from HDR files
    hdr_sample_names <- sub(".*/(D\\d+T\\d+_IFCB\\d+)\\.hdr", "\\1", hdr_files)

    if (!is.null(custom_images)) {
      # Extract date-time from class file paths
      class_sample_names <- sub("^(D\\d{8}T\\d{6}_IFCB\\d+)_.*", "\\1", custom_images)
    } else {

      # Check if class_files is a single folder path or a vector of file paths
      if (length(class_files) == 1 && file.info(class_files)$isdir) {
        class_files <- list.files(class_files, pattern = "D.*\\.(mat|h5|csv)", recursive = class_recursive, full.names = TRUE)
      }

      # Extract sample names from class file paths
      class_sample_names <- sub("_class(_v\\d+)?\\.(mat|h5)$", "", basename(class_files))
      class_sample_names <- sub("\\.(mat|h5|csv)$", "", class_sample_names)
    }

    # Find common sample names between HDR and class files
    common_sample_names <- intersect(hdr_sample_names, class_sample_names)

    # Filter HDR files to include only those matching common sample names
    hdr_files_filtered <- hdr_files[hdr_sample_names %in% common_sample_names]

    n_hdr <- length(hdr_files_filtered)

    # Preallocate list for speed
    volume_list <- vector("list", n_hdr)

    # Set up the progress bar
    if (verbose && n_hdr > 0) {
      cli_progress_bar("Calculating sample volumes", total = n_hdr)
    }

    # Loop through filtered HDR files to extract volume analyzed per sample
    for (i in seq_along(hdr_files_filtered)) {

      if (verbose && n_hdr > 0) {
        cli_progress_update()
      }

      volume_list[[i]] <- tibble(
        sample = sub(".*/(D\\d+T\\d+_IFCB\\d+)\\.hdr", "\\1", hdr_files_filtered[i]),
        ml_analyzed = ifcb_volume_analyzed(hdr_files_filtered[i])
      )
    }

    if (verbose && n_hdr > 0) {
      cli_progress_done()
    }

    # When no HDR file matches any classified sample, bind_rows() yields a 0x0
    # tibble without a `sample` column and the join aborts with an error that
    # names neither the cause nor the argument. Warn and report unknown
    # volumes instead.
    if (n_hdr == 0) {
      cli_warn(c(
        "No {.file .hdr} files in {.arg hdr_folder} match the classified samples.",
        "i" = "{.field ml_analyzed} and the per-liter columns are {.code NA}."
      ))
      biovolume_aggregated$ml_analyzed <- NA_real_
    } else {
      # Combine into a single data frame
      volumes <- bind_rows(volume_list)

      # Join volume data with aggregated biovolumes based on 'sample' column
      biovolume_aggregated <- left_join(biovolume_aggregated, volumes, by = "sample")
    }

    # Calculate biovolume and carbon content per liter of sample analyzed
    biovolume_aggregated$counts_per_liter <- biovolume_aggregated$counts / (biovolume_aggregated$ml_analyzed / 1000)
    if (use_cell_counts) {
      biovolume_aggregated$cell_counts_per_liter <- biovolume_aggregated$cell_counts / (biovolume_aggregated$ml_analyzed / 1000)
    }
    biovolume_aggregated$biovolume_mm3_per_liter <- biovolume_aggregated$biovolume_mm3 / (biovolume_aggregated$ml_analyzed / 1000)
    biovolume_aggregated$carbon_ug_per_liter <- biovolume_aggregated$carbon_ug / (biovolume_aggregated$ml_analyzed / 1000)
  }
  biovolume_aggregated
}
