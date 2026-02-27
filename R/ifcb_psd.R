utils::globalVariables(c("variable", "number", "Bin"))
#' Plot and Save IFCB PSD Data
#'
#' This function generates and saves data about a dataset's Particle Size Distribution (PSD)
#' from Imaging FlowCytobot (IFCB) feature and hdr files, which can be used for data
#' quality assurance and quality control.
#'
#' @details
#' The PSD function originates from the `PSD` Python repository (Hayashi et al. 2025),
#' which can be found at \url{https://github.com/kudelalab/PSD}.
#'
#' Python must be installed to use this function. The required Python packages can be
#' installed in a virtual environment using `ifcb_py_install()`.
#'
#' @param feature_folder The absolute path to a directory containing all of the feature
#'   files for the dataset (version can be defined in `fea_v`).
#' @param hdr_folder The absolute path to a directory containing all of the hdr files for
#'   the dataset.
#' @param bins An optional character vector of bin names (e.g.,
#'   `"D20251021T133007_IFCB134"`) to restrict processing to a specified subset of bins.
#'   If `NULL` (default), all bins present in `feature_folder` are processed.
#' @param save_data A logical indicating whether to save data to CSV files. Default is FALSE.
#' @param output_file A string with the base file name for the .csv output (including path).
#'   Set to NULL to avoid saving data (default).
#' @param plot_folder The folder where graph images for each sample will be saved.
#'   If `NULL` (default), plots are not saved. If `use_plot_subfolders = TRUE`,
#'   plots are organized into subfolders based on their flag status.
#' @param use_marker A logical indicating whether to show markers on the plot. Default is FALSE.
#' @param start_fit An integer indicating the start fit value for the plot. Default is 10.
#' @param r_sqr The lower limit of acceptable R^2 values (any curves below it will be flagged).
#'   Default is 0.5.
#' @param beads The maximum multiplier for the curve fit. Any files with higher curve fit
#'   multipliers will be flagged as bead runs. If this argument is included, files with
#'   `"runBeads"` marked as TRUE in the header file will also be flagged. Optional.
#' @param bubbles The minimum difference between the starting ESD and the ESD with the most
#'   targets. Files with a difference higher than this threshold will be flagged as mostly
#'   bubbles. Optional.
#' @param incomplete A numeric vector of length 2 giving the minimum volume of cells (in c/L)
#'   and the minimum mL analyzed for a complete run. Files with values below these thresholds
#'   will be flagged as incomplete. Optional.
#' @param missing_cells The minimum image count ratio threshold. Files with ratios below this
#'   value will be flagged as missing cells. Optional.
#' @param biomass The minimum number of targets in the most populated ESD bin for any given run.
#'   Files with fewer targets will be flagged as low biomass. Optional.
#' @param bloom The minimum difference between the starting ESD and the ESD with the most
#'   targets. Files with a difference less than this threshold will be flagged as bloom events.
#'   This threshold is usually lower than the bubbles threshold. Optional.
#' @param humidity The maximum percent humidity. Files with higher values will be flagged as
#'   high humidity. Optional.
#' @param micron_factor Conversion factor from microns per pixel (default: 1/3.4).
#' @param fea_v The version number of the IFCB feature file (e.g., 2, 4). Default is 2, as described in Hayashi et al. 2025. `r lifecycle::badge("experimental")`
#' @param use_plot_subfolders A logical indicating whether to save plots in subfolders
#'   based on the sample's flag status. If TRUE (default), samples without flags are
#'   saved in a "PSD.OK" subfolder, and samples with flags are saved in subfolders
#'   named after their flag(s). If FALSE, all plots are saved directly in `plot_folder`.
#' @param ... Additional arguments passed to `ggsave()`.
#'   These override the default width, height, dpi, and background color
#'   when saving plots. For example, `width = 7, dpi = 300` can be supplied.
#'
#' @return A list containing three tibbles:
#'   \describe{
#'     \item{data}{A tibble with flattened PSD data for each sample.}
#'     \item{fits}{A tibble containing curve fit parameters for each sample.}
#'     \item{flags}{A tibble of flags for each sample, or NULL if no flags are found.}
#'   }
#' The `save_data` parameter only controls whether CSV files are written to disk; the
#' function always returns this list.
#'
#' @seealso \code{\link{ifcb_py_install}},
#'   \url{https://github.com/kudelalab/PSD}
#'
#' @references
#' Hayashi, K., Enslein, J., Lie, A., Smith, J., Kudela, R.M., 2025. Using particle size distribution (PSD)
#' to automate imaging flow cytobot (IFCB) data quality in coastal California, USA.
#' International Society for the Study of Harmful Algae. https://doi.org/10.15027/0002041270
#'
#' @examples
#' \dontrun{
#' # Initialize the Python session if not already set up
#' ifcb_py_install()
#'
#' ifcb_psd(
#'   feature_folder = 'path/to/features',
#'   hdr_folder = 'path/to/hdr_data',
#'   bins = c("D20211021T133007_IFCB134", "D20211021T140753_IFCB134"),
#'   save_data = TRUE,
#'   output_file = 'psd/svea_2021',
#'   plot_folder = 'psd/plots',
#'   use_marker = FALSE,
#'   start_fit = 13,
#'   r_sqr = 0.5,
#'   beads = 10 ** 9,
#'   bubbles = 150,
#'   incomplete = c(1500, 3),
#'   missing_cells = 0.7,
#'   biomass = 1000,
#'   bloom = 5,
#'   humidity = NULL,
#'   micron_factor = 1/2.77,
#'   fea_v = 2
#' )
#' }
#'
#' @export
ifcb_psd <- function(feature_folder, hdr_folder, bins = NULL, save_data = FALSE, output_file = NULL, plot_folder = NULL,
                     use_marker = FALSE, start_fit = 10, r_sqr = 0.5, beads = NULL, bubbles = NULL, incomplete = NULL,
                     missing_cells = NULL, biomass = NULL, bloom = NULL, humidity = NULL, micron_factor = 1/3.4, fea_v = 2,
                     use_plot_subfolders = TRUE, ...) {

  if (!dir.exists(feature_folder)) {
    stop(paste("Feature folder does not exist:", feature_folder))
  }

  if (!dir.exists(hdr_folder)) {
    stop(paste("HDR folder does not exist:", hdr_folder))
  }

  if (!reticulate::py_available(initialize = TRUE)) {
    stop("Python is not installed on this machine. Please install Python to use this function.")
  }

  if (save_data & is.null(output_file)) {
    stop("No output file specified. Please provide a valid output file path to save the data.")
  }

  # Initialize python check
  check_python_and_module(c("pandas", "matplotlib", "numpy"))

  # Source the Python script
  source_python(system.file("python", "psd.py", package = "iRfcb"))

  # Create a Bin object
  b <- Bin(feature_dir = as.character(feature_folder),
           hdr_dir = as.character(hdr_folder),
           micron_factor = as.numeric(micron_factor),
           fea_v = as.integer(fea_v),
           bins = if (is.null(bins)) NULL else as.list(bins))

  # Plot the PSD
  b$plot_PSD(use_marker = use_marker, plot_folder = NULL, start_fit = as.integer(start_fit))

  if (save_data) {
    # Prepare arguments for save_data
    args <- list(name = as.character(output_file), r_sqr = as.numeric(r_sqr))
    if (!is.null(beads)) args$beads <- as.numeric(beads)
    if (!is.null(bubbles)) args$bubbles <- as.integer(bubbles)
    if (!is.null(incomplete)) args$incomplete <- as.integer(incomplete)
    if (!is.null(missing_cells)) args$missing_cells <- missing_cells
    if (!is.null(biomass)) args$biomass <- as.integer(biomass)
    if (!is.null(bloom)) args$bloom <- as.integer(bloom)
    if (!is.null(humidity)) args$humidity <- humidity

    # Save the data
    do.call(b$save_data, args)
  }

  # Retrieve data from Python
  data <- b$get_data()
  fits <- b$get_fits()
  flags <- b$get_flags(r_sqr = r_sqr, beads = beads, bubbles = bubbles, incomplete = incomplete,
                       missing_cells = missing_cells, biomass = biomass, bloom = bloom, humidity = humidity)


  # Flatten nested lists and combine into a data frame
  data_df <- as.data.frame(lapply(data, function(x) unlist(x)), check.names = FALSE)

  # Convert to tibble and add sample column
  data_df <- data_df %>%
    mutate(sample = rownames(data_df)) %>%  # Add row names as a new column
    relocate(sample) %>%
    arrange(sample) %>%
    dplyr::as_tibble()

  # Convert nested list to a data frame
  fits_df <- as.data.frame(lapply(fits, function(x) unlist(x)), check.names = FALSE)

  # Convert to long format and then to wide format
  fits_df <- fits_df %>%
    mutate(sample = rownames(.)) %>%
    dplyr::as_tibble() %>%
    relocate(sample) %>%
    dplyr::arrange(sample)

  if (nrow(as.data.frame(flags)) > 0) {
    # Convert to a data frame
    files <- as.character(unlist(flags$sample))
    flags <- unlist(flags$flag)

    # Combine into a data frame
    flags_df <- dplyr::tibble(
      sample = files,
      flag = flags
    ) %>%
      dplyr::arrange(sample)
  } else {
    flags_df <- NULL
  }

  if (!is.null(plot_folder)) {

    if (!dir.exists(plot_folder)) {
      dir.create(plot_folder, recursive = TRUE)
    }

    # List of sample names
    sample_names <- data_df$sample

    for (sample in sample_names) {

      # Specify plot subfolder
      if (use_plot_subfolders) {
        # Find the potential flag
        flag <- flags_df[grepl(sample, flags_df$sample),]


        if (nrow(flag) == 0) {
          sample_plot_folder <- file.path(plot_folder, "PSD.OK")
        } else {
          sample_plot_folder <- file.path(plot_folder, make.names(flag$flag))
        }
      } else {
        sample_plot_folder <- plot_folder
      }

      # Create plot subfolder
      if (!dir.exists(sample_plot_folder)) {
        dir.create(sample_plot_folder, recursive = TRUE)
      }

      # Plot the sample PSD
      p <- ifcb_psd_plot(sample, data_df, fits_df, start_fit, flags = flags_df)

      # Default ggsave arguments
      default_ggsave_args <- list(width = 5, height = 3.5, dpi = 90, bg = "white")

      # Merge with user-supplied ... arguments (overrides defaults if provided)
      ggsave_args <- modifyList(default_ggsave_args, list(...))


      # Save the plot
      do.call(ggsave, c(
        list(filename = file.path(sample_plot_folder, paste0(sample, ".png")),
             plot = p),
        ggsave_args
      ))

      # Inform user
      message("Saving plot ", sample)
    }
  }

  list(data = data_df, fits = fits_df, flags = flags_df)
}
