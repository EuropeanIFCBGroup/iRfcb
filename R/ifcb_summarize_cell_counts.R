utils::globalVariables(c("cell_count", "cell_count_resolved", "classifier", "class", "sample",
                         "roi_number"))
#' Summarize Diatom Cell Counts and Chain-Length Statistics from IFCB Data
#'
#' Summarizes the optional per-ROI cell-count data produced by the diatom chain
#' counter and stored in classification files (`.mat`, `.h5` or `.csv`). For each
#' sample and class it computes the total cell abundance (number of cells,
#' accounting for chains) together with a user-selectable set of chain-length
#' statistics.
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
#' statistics, although both still contribute to abundance according to
#' `single_cell_values` (by default one cell each).
#'
#' `n_counted` reports how many ROIs those length statistics were computed over,
#' i.e. the number of ROIs the chain counter measured (`cell_count >= 1`). It is
#' a count of ROIs rather than of chains, and it includes ROIs found to hold a
#' single cell, which are not chains. It is useful for telling a measured
#' abundance from an imputed one: a class with `cell_counts > 0` but
#' `n_counted == 0` was never chain-counted, so its abundance is one cell per ROI
#' by imputation rather than by measurement.
#'
#' @param class_files A character vector of full paths to classification files
#'   (`.mat`, `.h5` or `.csv`), or a single path to a folder containing such
#'   files. Any of these file types can carry the optional `cell_count` data
#'   written by the chain counter; files without it are treated as `NA` chain
#'   counts. Supply a single file format per sample: a sample represented twice
#'   (e.g. by both a `.mat` and a `.h5`) would have its ROIs counted once per
#'   file, so this is rejected with an error naming the affected samples.
#' @param hdr_folder (Optional) Path to the folder containing HDR files. Needed
#'   for calculating cell abundance per liter.
#' @param single_cell_values Integer vector of `cell_count` values that should
#'   be treated as a single cell when computing abundance. Default is
#'   `c(-1, 0)`, i.e. both ROIs that were not counted and ROIs where no cells
#'   were detected count as one cell. Values not listed are used verbatim.
#' @param stats Character vector selecting which chain-length statistics to
#'   include. Any of `"n_counted"` (the number of ROIs the chain counter measured,
#'   which the other statistics are computed over), `"mean"`, `"median"`, `"max"`,
#'   and `"sd"`.
#'   Default is `c("n_counted", "mean", "median", "max")`. Use `character(0)` to
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
#'   Python-based method (`SciPy`). Default is `FALSE`.
#' @param verbose Logical. If `TRUE`, prints progress messages. Default is `TRUE`.
#'
#' @return A data frame with one row per sample and class. Columns always include
#'   `sample`, `classifier`, `class`, `counts` (number of ROIs), and
#'   `cell_counts` (total cell abundance). The requested chain-length statistics
#'   are added as `n_counted` (number of ROIs the chain counter measured, i.e.
#'   those with `cell_count >= 1`, including single-cell ones),
#'   `mean_chain_length`, `median_chain_length`,
#'   `max_chain_length`, and/or `sd_chain_length`. When `hdr_folder` is provided,
#'   `ml_analyzed` and `cell_counts_per_liter` are also returned.
#'
#'   `cell_counts` is `NA` for a sample whose classification file carries no
#'   `cell_count` data, since the cell total is unknown there. It is not
#'   reported as `0`, which would be indistinguishable from a taxon that was
#'   genuinely absent. `counts` is unaffected and still reports the ROIs.
#'
#' @details
#' Chain counting was introduced by Groves et al. (2026), who trained a
#' "You Only Look Once" (YOLO) object detection model to enumerate the cells in
#' diatom chains imaged by the IFCB. The per-ROI `cell_count` data summarized
#' here is produced by the `ifcb-pytorch-classify` inference pipeline
#' (\url{https://github.com/nodc-sweden/ifcb-pytorch-classify}), which writes it
#' as an optional `cell_count` variable in the `.mat`, `.h5` and `.csv`
#' classification files alongside the class predictions.
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
                                        stats = c("n_counted", "mean", "median", "max"),
                                        threshold = "opt", class_recursive = TRUE,
                                        hdr_recursive = TRUE, use_python = FALSE,
                                        verbose = TRUE) {

  allowed_stats <- c("n_counted", "mean", "median", "max", "sd")
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
    class_files <- list.files(class_files, pattern = "\\.(mat|h5|csv)$",
                              recursive = class_recursive, full.names = TRUE)
    # A directory may hold non-class .csv files (e.g. dashboard class_scores
    # exports); drop them with a warning rather than failing later.
    class_files <- drop_invalid_class_csv(class_files)
  }

  # Keep only classification file types that can carry chain-count data
  class_files <- class_files[tolower(tools::file_ext(class_files)) %in% c("mat", "h5", "csv")]

  if (length(class_files) == 0) {
    cli_abort(c(
      "No {.file .mat}, {.file .h5} or {.file .csv} classification files found.",
      "i" = "Chain-count data is stored in {.file .mat}, {.file .h5} and {.file .csv} files."
    ))
  }

  n_files <- length(class_files)
  tb_list <- vector("list", n_files)
  has_chain <- logical(n_files)
  is_automated <- logical(n_files)
  na_gaps <- integer(n_files)

  # Sample names depend only on the file name; compute up front so we can detect
  # a sample resolving to more than one classification file below.
  # Strip the _class(_vN) suffix from .csv names too: a label file named
  # {sample}_class.csv must resolve to the same sample as {sample}.csv, or the
  # duplicate guard below and the per-sample join disagree about its identity.
  sample_names <- sub("_class(_v\\d+)?\\.(mat|h5)$", "", basename(class_files))
  sample_names <- sub("(_class(_v\\d+)?)?\\.csv$", "", sample_names)

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

    # Skip files that are not automated classifications (e.g. manual .mat
    # annotation files), which have no per-ROI winning class and cannot carry
    # chain counts. These are dropped rather than added as junk rows.
    if (is.null(temp$roinum) || is.null(temp$TBclass_above_threshold)) {
      next
    }

    is_automated[i] <- TRUE
    has_chain[i] <- !is.null(temp$cell_count)
    # A missing value inside a file that does carry cell_count data (a blank
    # CSV cell, an HDF5 NaN, a value that failed to parse) nulls the whole
    # sample-class group in the summary; count the gaps so that can be said
    # out loud rather than surface as an unexplained NA.
    na_gaps[i] <- if (has_chain[i]) sum(is.na(temp$cell_count)) else 0L

    tb_list[[i]] <- tibble(
      sample = sample_names[i],
      # read_mat() returns classifierName as a 1x1 character matrix; without
      # as.character() tibble() recycles it into a matrix *column*, which
      # breaks bind_rows() against .h5-derived results and tidyr reshaping.
      classifier = as.character(temp$classifierName)[1],
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

  n_skipped <- sum(!is_automated)
  if (n_skipped > 0 && verbose) {
    cli_warn(c(
      "{n_skipped} of {n_files} file{?s} {?is/are} not {?an/} automated classification file{?s} and {?was/were} skipped.",
      "i" = "Chain-count data is only available in automated classification files; manual annotation {.file .mat} files are ignored."
    ))
  }

  if (!any(is_automated)) {
    cli_abort(c(
      "No automated classification files found.",
      "i" = "Chain-count data is only stored in automated {.file .mat}, {.file .h5} and {.file .csv} classification files."
    ))
  }

  # Guard against the same sample resolving to more than one classification file
  # (e.g. both a .mat and a .h5 for one sample), which would silently double the
  # counts when the per-file rows are summed together.
  automated_samples <- sample_names[is_automated]
  dup_samples <- unique(automated_samples[duplicated(automated_samples)])
  if (length(dup_samples) > 0) {
    cli_abort(c(
      "{length(dup_samples)} sample{?s} resolve{?s/} to more than one classification file: {.val {dup_samples}}.",
      "i" = "Supply a single file format per sample (e.g. only {.file .mat} or only {.file .h5}) to avoid double-counting."
    ))
  }

  if (!any(has_chain)) {
    cli_abort(c(
      "None of the supplied classification files contain chain-count data.",
      "i" = "Re-run classification with chain counting enabled to produce a {.code cell_count} dataset."
    ))
  }

  # Not gated on `verbose`: this reports a data-integrity condition that changes
  # the returned numbers, not progress.
  auto_has_chain <- has_chain[is_automated]
  if (!all(auto_has_chain)) {
    n_no_chain <- sum(!auto_has_chain)
    cli_warn(c(
      "{n_no_chain} of {sum(is_automated)} classification file{?s} {qty(n_no_chain)}{?does/do} not contain chain-count data.",
      "i" = "ROIs from {qty(n_no_chain)}{?this file/these files} are treated as {.code NA} chain counts, so {.field cell_counts} is {.code NA} for the affected samples."
    ))
  }
  if (any(na_gaps > 0)) {
    cli_warn(c(
      "{sum(na_gaps)} ROI{?s} in {sum(na_gaps > 0)} classification file{?s} with chain-count data {qty(sum(na_gaps))}{?has/have} a missing {.code cell_count} value.",
      "i" = "{.field cell_counts} is {.code NA} for the affected sample{?s}: {.val {sample_names[na_gaps > 0]}}."
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
      # ROIs from a file without a `cell_count` dataset carry NA. Summing them
      # with na.rm = TRUE would report 0 cells for a taxon that is present in
      # the images, so the group total is reported as NA instead.
      cell_counts = if (any(is.na(cell_count_resolved))) NA_real_ else sum(cell_count_resolved),
      n_counted = sum(cell_count >= 1, na.rm = TRUE),
      mean_chain_length = length_stat(cell_count, mean),
      median_chain_length = length_stat(cell_count, stats::median),
      max_chain_length = length_stat(cell_count, max),
      sd_chain_length = length_stat(cell_count, stats::sd),
      .groups = "drop"
    )

  # Keep only the requested chain-length statistics
  stat_cols <- c(n_counted = "n_counted",
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

    # When no HDR file matches any classified sample (wrong folder, or files
    # from a different period), bind_rows() yields a 0x0 tibble without a
    # `sample` column and the join aborts with an error that names neither the
    # cause nor the argument. Warn and report unknown volumes instead.
    if (n_hdr == 0) {
      cli_warn(c(
        "No {.file .hdr} files in {.arg hdr_folder} match the classified samples.",
        "i" = "{.field ml_analyzed} and {.field cell_counts_per_liter} are {.code NA}."
      ))
      summary_df$ml_analyzed <- NA_real_
    } else {
      volumes <- bind_rows(volume_list)
      summary_df <- left_join(summary_df, volumes, by = "sample")
    }
    summary_df$cell_counts_per_liter <- summary_df$cell_counts / (summary_df$ml_analyzed / 1000)
  }

  summary_df
}
