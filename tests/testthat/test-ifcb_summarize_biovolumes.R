# Define paths to the test data
test_data_zip <- test_path("test_data/test_data.zip")
temp_dir <- file.path(tempdir(), "ifcb_summarize_biovolumes")
unzip(test_data_zip, exdir = temp_dir)

feature_folder <- file.path(temp_dir, "test_data", "features")
class_folder <- file.path(temp_dir, "test_data", "class", "class2022_v1")
hdr_folder <- file.path(temp_dir, "test_data", "data")
manual_folder <- file.path(temp_dir, "test_data", "manual")

test_that("ifcb_summarize_biovolumes works correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Call the function with the test data
  result <- ifcb_summarize_biovolumes(feature_folder, class_folder, hdr_folder = hdr_folder)

  # Check if the result is a data frame
  expect_s3_class(result, "data.frame")

  # Check if the result contains the expected columns
  expected_columns <- c("sample", "class", "counts", "biovolume_mm3", "carbon_ug", "ml_analyzed",
                        "counts_per_liter", "biovolume_mm3_per_liter", "carbon_ug_per_liter")
  expect_true(all(expected_columns %in% colnames(result)))

  # Check if the result contains the correct number of rows (adjust this based on your expected output)
  expected_rows <- 1
  expect_equal(nrow(result), expected_rows)

  # Check if the result contains non-NA values in key columns
  expect_true(all(!is.na(result$biovolume_mm3)))
  expect_true(all(!is.na(result$carbon_ug)))
  expect_true(all(!is.na(result$ml_analyzed)))
  expect_true(all(!is.na(result$biovolume_mm3_per_liter)))
  expect_true(all(!is.na(result$carbon_ug_per_liter)))

  # Check if the result values are within expected ranges (adjust based on your expected output)
  expect_equal(result$biovolume_mm3, 1.224387e-05, tolerance = 1e-7)
  expect_equal(result$carbon_ug, 0.001554673, tolerance = 1e-6)
  expect_equal(result$ml_analyzed, 2.9812723)
  expect_equal(result$biovolume_mm3_per_liter, 0.004106928)
  expect_equal(result$carbon_ug_per_liter, 0.52147962)
})

test_that("ifcb_summarize_biovolumes handles empty directories gracefully", {

  temp_dir <- file.path(tempdir(), "ifcb_summarize_biovolumes")

  # Create empty directories
  feature_folder <- file.path(temp_dir, "empty_features")
  mat_folder <- file.path(temp_dir, "empty_mat")
  hdr_folder <- file.path(temp_dir, "empty_hdr")
  dir.create(feature_folder, showWarnings = FALSE)
  dir.create(mat_folder, showWarnings = FALSE)
  dir.create(hdr_folder, showWarnings = FALSE)

  expect_error(ifcb_summarize_biovolumes(feature_folder, mat_folder, hdr_folder = hdr_folder),
               "No classification files found")
})

test_that("ifcb_summarize_biovolumes works correctly with custom class data", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Define custom list
  classes = c("Mesodinium_rubrum", "Mesodinium_rubrum")
  images <- c("D20220522T003051_IFCB134_00002", "D20220522T003051_IFCB134_00003")

  # Call the function with the test data
  result <- ifcb_summarize_biovolumes(feature_folder,
                                      hdr_folder = hdr_folder,
                                      custom_images = images,
                                      custom_classes = classes)

  # Check if the result is a data frame
  expect_s3_class(result, "data.frame")

  # Check if the result contains the expected columns
  expected_columns <- c("sample", "class", "counts", "biovolume_mm3", "carbon_ug", "ml_analyzed",
                        "counts_per_liter", "biovolume_mm3_per_liter", "carbon_ug_per_liter")
  expect_true(all(expected_columns %in% colnames(result)))

  # Check if the result contains the correct number of rows (adjust this based on your expected output)
  expected_rows <- 1
  expect_equal(nrow(result), expected_rows)

  # Check if the result contains non-NA values in key columns
  expect_true(all(!is.na(result$biovolume_mm3)))
  expect_true(all(!is.na(result$carbon_ug)))
  expect_true(all(!is.na(result$ml_analyzed)))
  expect_true(all(!is.na(result$biovolume_mm3_per_liter)))
  expect_true(all(!is.na(result$carbon_ug_per_liter)))
  expect_true(all(is.na(result$classifier)))

  # Check if the result values are within expected ranges (adjust based on your expected output)
  expect_equal(result$biovolume_mm3, 1.224387e-05, tolerance = 1e-7)
  expect_equal(result$carbon_ug, 0.001554673, tolerance = 1e-6)
  expect_equal(result$ml_analyzed, 2.9812723)
  expect_equal(result$biovolume_mm3_per_liter, 0.004106928)
  expect_equal(result$carbon_ug_per_liter, 0.52147962)
})

test_that("ifcb_summarize_biovolumes aborts with use_cell_counts on files without chain data", {
  # The test .mat classification files do not contain chain-count data, so
  # requesting chain counts should abort before any WoRMS lookup (offline-safe).
  expect_error(
    ifcb_summarize_biovolumes(feature_folder, class_folder, use_cell_counts = TRUE,
                              verbose = FALSE),
    "chain-count data"
  )
})

test_that("ifcb_summarize_biovolumes computes cell abundance with use_cell_counts", {
  skip_if_offline()
  skip_on_cran()
  skip_if_not_installed("hdf5r")
  skip_if_resource_unavailable("https://marinespecies.org")

  # Build a synthetic .h5 classification file (carrying cell_count) for the same
  # sample as the real feature file, so the feature join yields known ROIs. The
  # feature file holds ROIs 2 and 3.
  chain_class_dir <- file.path(tempdir(), "ifcb_summarize_biovolumes_chain")
  dir.create(chain_class_dir, showWarnings = FALSE)
  h5_path <- file.path(chain_class_dir, "D20220522T003051_IFCB134_class.h5")

  f <- hdf5r::H5File$new(h5_path, mode = "w")
  cl <- "Mesodinium_rubrum"
  f[["class_labels"]] <- cl
  f[["roi_numbers"]] <- c(2L, 3L)
  f[["output_scores"]] <- matrix(0.9, nrow = 1, ncol = 2)
  f[["classifier_name"]] <- "test_clf"
  f[["class_name_auto"]] <- rep(cl, 2)
  f[["class_name"]] <- rep(cl, 2)
  f[["thresholds"]] <- 0.5
  f[["cell_count"]] <- c(2L, 3L)  # neither value is a single-cell marker
  f$close_all()

  result <- ifcb_summarize_biovolumes(feature_folder, chain_class_dir,
                                      hdr_folder = hdr_folder,
                                      use_cell_counts = TRUE, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("cell_counts", "cell_counts_per_liter") %in% colnames(result)))

  # Two ROIs of the same class; chain counts 2 and 3 -> 5 cells from 2 ROIs
  expect_equal(nrow(result), 1)
  expect_equal(result$counts, 2)
  expect_equal(result$cell_counts, 5)
  expect_equal(result$ml_analyzed, 2.9812723)
  expect_equal(result$cell_counts_per_liter, 5 / (2.9812723 / 1000))
})

test_that("ifcb_summarize_biovolumes handles no class2use file gracefully", {

  expect_error(ifcb_summarize_biovolumes(feature_folder, manual_folder, hdr_folder = hdr_folder),
               "class2use_file.*must be specified")

  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})

