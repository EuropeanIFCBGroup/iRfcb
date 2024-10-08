utils::globalVariables(c("biovolume_um3", "carbon_pg", "counts", "classifier", "."))
#' Summarize Biovolumes and Carbon Content from IFCB Data
#'
#' This function calculates aggregated biovolumes and carbon content from Imaging FlowCytobot (IFCB)
#' samples based on biovolume information from feature files. Images are grouped in classes either
#' based on MATLAB classification or manually annotation files, generated by the code in
#' `ifcb-analysis` repository (Sosik and Olson 2007). Biovolumes are converted to carbon according
#' to Menden-Deuer and Lessard 2000 for individual regions of interest (ROI),
#' where different conversion factors are applied to diatoms and non-diatom protist.
#' If provided, it also incorporates sample volume data from HDR files to compute biovolume
#' and carbon content per liter of sample.
#'
#' @param feature_folder Path to the folder containing feature files (e.g., CSV format).
#' @param mat_folder Path to the folder containing class or manual MATLAB files.
#' @param class2use_file A character string specifying the path to the file containing the class2use variable (default NULL). Only needed when summarizing manual results.
#' @param hdr_folder Path to the folder containing HDR files (optional).
#' @param micron_factor Conversion factor from microns per pixel (default: 1/3.4).
#' @param diatom_class A string vector of diatom class names in the World Register of Marine Species (WoRMS). Default is "Bacillariophyceae".
#' @param marine_only Logical. If TRUE, restricts the WoRMS search to marine taxa only. Default is FALSE.
#' @param threshold Threshold for classification (default: "opt").
#' @param feature_recursive Logical. If TRUE, the function will search for feature files recursively within the `feature_folder`. Default is TRUE.
#' @param mat_recursive Logical. If TRUE, the function will search for MATLAB files recursively within the `mat_folder`. Default is TRUE.
#' @param hdr_recursive Logical. If TRUE, the function will search for HDR files recursively within the `hdr_folder` (if provided). Default is TRUE.
#'
#' @return A data frame summarizing aggregated biovolume and carbon content per class per sample.
#'   Columns include 'sample', 'classifier', 'class', 'biovolume_mm3', 'carbon_ug', 'ml_analyzed',
#'   'biovolume_mm3_per_liter', and 'carbon_ug_per_liter'.
#'
#' @details This function performs the following steps:
#' \enumerate{
#'   \item Extracts biovolumes and carbon content from feature and MATLAB files using `ifcb_extract_biovolumes`.
#'   \item Optionally incorporates volume data from HDR files to calculate volume analyzed per sample.
#'   \item Computes biovolume and carbon content per liter of sample analyzed.
#' }
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' ifcb_summarize_biovolumes("path/to/features", "path/to/mat", hdr_folder = "path/to/hdr")
#' }
#'
#' @references Menden-Deuer Susanne, Lessard Evelyn J., (2000), Carbon to volume relationships for dinoflagellates, diatoms, and other protist plankton, Limnology and Oceanography, 3, doi: 10.4319/lo.2000.45.3.0569.
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @importFrom dplyr group_by summarise left_join
#' @importFrom magrittr %>%
#'
#' @export
ifcb_summarize_biovolumes <- function(feature_folder, mat_folder, class2use_file = NULL,
                                      hdr_folder = NULL, micron_factor = 1 / 3.4,
                                      diatom_class = "Bacillariophyceae", marine_only = FALSE, threshold = "opt",
                                      feature_recursive = TRUE, mat_recursive = TRUE, hdr_recursive = TRUE) {

  # Step 1: Extract biovolumes and carbon content from feature and class files
  biovolumes <- ifcb_extract_biovolumes(feature_files = feature_folder,
                                        mat_folder = mat_folder,
                                        class2use_file = class2use_file,
                                        micron_factor = micron_factor,
                                        diatom_class = diatom_class,
                                        marine_only = marine_only,
                                        threshold = threshold,
                                        feature_recursive = feature_recursive,
                                        mat_recursive = mat_recursive)

  # Step 2: Aggregate biovolumes and carbon content by sample and class
  biovolume_aggregated <- biovolumes %>%
    group_by(sample, classifier, class) %>%
    summarise(counts = n(),
              biovolume_mm3 = sum(biovolume_um3 * 10^-9, na.rm = TRUE),  # Convert from um3 to mm3
              carbon_ug = sum(carbon_pg * 10^-6, na.rm = TRUE),  # Convert from pg to ug
              .groups = 'drop')

  # Step 3: Optionally incorporate volume data from HDR files if provided
  if (!is.null(hdr_folder)) {
    mat_files <- list.files(mat_folder, pattern = "D.*\\.mat", full.names = TRUE, recursive = mat_recursive)
    hdr_files <- list.files(hdr_folder, pattern = "D.*\\.hdr", full.names = TRUE, recursive = hdr_recursive)

    # Extract sample names from HDR and class files using a general regular expression
    hdr_sample_names <- sub(".*/(D\\d+T\\d+_IFCB\\d+)\\.hdr", "\\1", hdr_files)
    mat_sample_names <- sub(".*/(D\\d{8}T\\d{6}_IFCB\\d+).*", "\\1", mat_files)

    # Find common sample names between HDR and class files
    common_sample_names <- intersect(hdr_sample_names, mat_sample_names)

    # Filter HDR files to include only those matching common sample names
    hdr_files_filtered <- hdr_files[hdr_sample_names %in% common_sample_names]

    # Initialize an empty data frame to store volume data
    volumes <- data.frame()

    # Loop through filtered HDR files to extract volume analyzed per sample
    for (file in seq_along(hdr_files_filtered)) {
      volume <- data.frame(sample = sub(".*/(D\\d+T\\d+_IFCB\\d+)\\.hdr", "\\1", hdr_files_filtered[file]),
                           ml_analyzed = ifcb_volume_analyzed(hdr_files_filtered[file]))  # Calculate volume analyzed

      volumes <- rbind(volumes, volume)  # Append volume data to 'volumes' data frame
    }

    # Join volume data with aggregated biovolumes based on 'sample' column
    biovolume_aggregated <- left_join(biovolume_aggregated, volumes, by = "sample")

    # Calculate biovolume and carbon content per liter of sample analyzed
    biovolume_aggregated$counts_per_liter <- biovolume_aggregated$counts / (biovolume_aggregated$ml_analyzed / 1000)
    biovolume_aggregated$biovolume_mm3_per_liter <- biovolume_aggregated$biovolume_mm3 / (biovolume_aggregated$ml_analyzed / 1000)
    biovolume_aggregated$carbon_ug_per_liter <- biovolume_aggregated$carbon_ug / (biovolume_aggregated$ml_analyzed / 1000)
  }
  return(biovolume_aggregated)
}
