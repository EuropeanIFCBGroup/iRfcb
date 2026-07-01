utils::globalVariables(c("cell_count", "cell_count_resolved", "classifier", "class", "sample",
                         "roi_number"))
#' Summarize Diatom Cell Counts and Chain-Length Statistics from IFCB Data
#'
#' Summarizes the optional per-ROI cell-count data produced by the diatom chain
#' counter and stored in classification files (`.h5` or `.csv`). For each sample
#' and class it computes the total cell abundance (number of cells, accounting
#' for chains) together with a user-selectable set of chain-length statistics.
#'
#' The chain counter stores one integer `cell_count` per region of interest
#' (ROI). The value `-1` marks ROIs of classes that were not configured for chain
#' counting, `0` marks ROIs that were counted but where no cells were detected,
#' and a positive value is the number of cells in that ROI. Abundance is derived
#' by translating the values listed in `single_cell_values` to a single cell and
#' using every other value verbatim (see [ifcb_summarize_biovolumes()], which
#' shares this logic to report `cell_counts`).
#'
#' Chain-length statistics (`mean`, `median`, `max`, `sd`) are computed only over
#' ROIs that were genuinely chain-counted (`cell_count >= 1`); ROIs with `-1`
#' (not counted) or `0` (no cells detected) are excluded from the length
#' statistics, although `0`-valued ROIs still contribute to abundance according
#' to `single_cell_values`.
#'
#' @param class_files A character vector of full paths to classification files
#'   (`.h5` or `.csv`), or a single path to a folder containing such files. Only
#'   `.h5` and `.csv` files can carry chain-count data; `.mat` files never do.
#' @param hdr_folder (Optional) Path to the folder containing HDR files. Needed
#'   for calculating cell abundance per liter.
#' @param single_cell_values Integer vector of `cell_count` values that should
#'   be treated as a single cell when computing abundance. Default is
#'   `c(-1, 0)`, i.e. both ROIs that were not counted and ROIs where no cells
#'   were detected count as one cell. Values not listed are used verbatim.
#' @param stats Character vector selecting which chain-length statistics to
#'   include. Any of `"n_chains"`, `"mean"`, `"median"`, `"max"`, and `"sd"`.
#'   Default is `c("n_chains", "mean", "median", "max")`. Use `character(0)` to
#'   return abundance only.
#' @param threshold A character string controlling which classification to use.
#'   `"opt"` (default) uses the threshold-applied classification, where
#'   predictions below the per-class optimal threshold are labeled
#'   `"unclassified"`. Any other value (e.g. `"all"`) uses the raw winning class.
#' @param class_recursive Logical. If `TRUE` and `class_files` is a folder,
#'   searches recursively for classification files. Default is `TRUE`.
#' @param hdr_recursive Logical. If `TRUE`, searches for HDR files recursively
#'   within `hdr_folder` (if provided). Default is `TRUE`.
#' @param use_python Logical. If `TRUE`, attempts to read `.mat` files using a
#'   Python-based method (`SciPy`). Default is `FALSE`. Has no effect on chain
#'   counts, which are only present in `.h5`/`.csv` files.
#' @param verbose Logical. If `TRUE`, prints progress messages. Default is `TRUE`.
#'
#' @return A data frame with one row per sample and class. Columns always include
#'   `sample`, `classifier`, `class`, `counts` (number of ROIs), and
#'   `cell_counts` (total cell abundance). The requested chain-length statistics
#'   are added as `n_chains`, `mean_chain_length`, `median_chain_length`,
#'   `max_chain_length`, and/or `sd_chain_length`. When `hdr_folder` is provided,
#'   `ml_analyzed` and `cell_counts_per_liter` are also returned.
#'
#' @details
#' Chain counting was introduced by Groves et al. (2026), who trained a
#' "You Only Look Once" (YOLO) object detection model to enumerate the cells in
#' diatom chains imaged by the IFCB. The per-ROI `cell_count` data summarized
#' here is produced by the `ifcb-pytorch-classify` inference pipeline
#' (\url{https://github.com/nodc-sweden/ifcb-pytorch-classify}), which writes it
#' as an optional dataset in the `.h5` classification files alongside the class
#' predictions.
#'
#' This function derives `cell_counts` from every classified ROI. This differs
#' from [ifcb_summarize_biovolumes()], which reports `cell_counts` only over ROIs
#' that also have matching feature (biovolume) data, so the two abundance totals
#' can differ when some ROIs lack feature data.
#'
#' @examples
#' \dontrun{
#' # Summarize chain counts and abundance from classification files
#' chains <- ifcb_summarize_cell_counts("path/to/class")
#'
#' # Include abundance per liter and only the mean chain length
#' chains <- ifcb_summarize_cell_counts(
#'   "path/to/class",
#'   hdr_folder = "path/to/hdr",
#'   stats = "mean"
#' )
#' }
#'
#' @references Groves, G. J. J., Arthur, G., Bresnan, E., Whyte, C., Arce, P. and Davidson, K. (2026), Automatic enumeration of chains of marine diatoms using "You Only Look Once" - a machine learning approach. Journal of Plankton Research, 48(2), fbaf064, doi: 10.1093/plankt/fbaf064.
#'
#' @seealso \code{\link{ifcb_summarize_biovolumes}} \code{\link{ifcb_extract_biovolumes}} \url{https://github.com/nodc-sweden/ifcb-pytorch-classify}
#'
#' @export
ifcb_summarize_cell_counts <- function(class_files, hdr_folder = NULL,
                                        single_cell_values = c(-1, 0),
                                        stats = c("n_chains", "mean", "median", "max"),
                                        threshold = "opt", class_recursive = TRUE,
                                        hdr_recursive = TRUE, use_python = FALSE,
                                        verbose = TRUE) {

  allowed_stats <- c("n_chains", "mean", "median", "max", "sd")
  if (length(stats) > 0) {
    invalid <- setdiff(stats, allowed_stats)
    if (length(invalid) > 0) {
      cli_abort(c(
        "Invalid value{?s} in {.arg stats}: {.val {invalid}}.",
        "i" = "Allowed values are {.val {allowed_stats}}."
      ))
    }
  }

  # Resolve class_files: a single folder path or a vector of file paths
  if (length(class_files) == 1 && dir.exists(class_files)) {
    class_files <- list.files(class_files, pattern = "\\.(h5|csv)$",
                              recursive = class_recursive, full.names = TRUE)
  }

  # Chain counts only exist in .h5 and .csv files; drop any .mat files
  class_files <- class_files[tolower(tools::file_ext(class_files)) %in% c("h5", "csv")]

  if (length(class_files) == 0) {
    cli_abort(c(
      "No {.file .h5} or {.file .csv} classification files found.",
      "i" = "Chain-count data is only stored in {.file .h5} and {.file .csv} files."
    ))
  }

  n_files <- length(class_files)
  tb_list <- vector("list", n_files)
  has_chain <- logical(n_files)

  if (verbose) {
    cli_progress_bar("Reading classification files", total = n_files)
  }

  for (i in seq_along(class_files)) {

    if (verbose) {
      cli_progress_update()
    }

    temp <- suppressWarnings({
      read_class_file(class_files[i], use_python = use_python)
    })

    has_chain[i] <- !is.null(temp$cell_count)

    sample_name <- sub("_class(_v\\d+)?\\.(mat|h5)$", "", basename(class_files[i]))
    sample_name <- sub("\\.csv$", "", sample_name)

    tb_list[[i]] <- tibble(
      sample = sample_name,
      classifier = temp$classifierName,
      roi_number = temp$roinum,
      class = if (threshold == "opt") {
        unlist(temp$TBclass_above_threshold)
      } else {
        unlist(temp$TBclass)
      },
      cell_count = if (is.null(temp$cell_count)) NA_integer_ else temp$cell_count
    )
  }

  if (verbose) cli_progress_done()

  if (!any(has_chain)) {
    cli_abort(c(
      "None of the supplied classification files contain chain-count data.",
      "i" = "Re-run classification with chain counting enabled to produce a {.code cell_count} dataset."
    ))
  }

  if (!all(has_chain) && verbose) {
    cli_warn(c(
      "{sum(!has_chain)} of {n_files} classification file{?s} {?does/do} not contain chain-count data.",
      "i" = "ROIs from {?this file/these files} are treated as {.code NA} chain counts."
    ))
  }

  chain_df <- bind_rows(tb_list)

  # Resolve per-ROI cell counts for abundance
  chain_df$cell_count_resolved <- resolve_cell_counts(chain_df$cell_count, single_cell_values)

  # Helper computing a length statistic over genuinely counted ROIs (cell_count >= 1)
  length_stat <- function(x, fun) {
    x <- x[!is.na(x) & x >= 1]
    if (length(x) == 0) return(NA_real_)
    fun(x)
  }

  summary_df <- chain_df %>%
    group_by(sample, classifier, class) %>%
    summarise(
      counts = n(),
      cell_counts = sum(cell_count_resolved, na.rm = TRUE),
      n_chains = sum(cell_count >= 1, na.rm = TRUE),
      mean_chain_length = length_stat(cell_count, mean),
      median_chain_length = length_stat(cell_count, stats::median),
      max_chain_length = length_stat(cell_count, max),
      sd_chain_length = length_stat(cell_count, stats::sd),
      .groups = "drop"
    )

  # Keep only the requested chain-length statistics
  stat_cols <- c(n_chains = "n_chains",
                 mean = "mean_chain_length",
                 median = "median_chain_length",
                 max = "max_chain_length",
                 sd = "sd_chain_length")
  keep_stat_cols <- unname(stat_cols[stats])
  base_cols <- c("sample", "classifier", "class", "counts", "cell_counts")
  summary_df <- summary_df[, c(base_cols, keep_stat_cols), drop = FALSE]

  # Optionally incorporate sample volume data from HDR files
  if (!is.null(hdr_folder)) {
    hdr_files <- list.files(hdr_folder, pattern = "D.*\\.hdr", full.names = TRUE,
                            recursive = hdr_recursive)

    hdr_sample_names <- sub(".*/(D\\d+T\\d+_IFCB\\d+)\\.hdr", "\\1", hdr_files)
    common_sample_names <- intersect(hdr_sample_names, unique(summary_df$sample))
    hdr_files_filtered <- hdr_files[hdr_sample_names %in% common_sample_names]

    n_hdr <- length(hdr_files_filtered)
    volume_list <- vector("list", n_hdr)

    if (verbose && n_hdr > 0) {
      cli_progress_bar("Calculating sample volumes", total = n_hdr)
    }

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

    volumes <- bind_rows(volume_list)

    summary_df <- left_join(summary_df, volumes, by = "sample")
    summary_df$cell_counts_per_liter <- summary_df$cell_counts / (summary_df$ml_analyzed / 1000)
  }

  summary_df
}
