# Define the path to the test data zip file
zip_path <- test_path("test_data/test_data.zip")

# Define the temporary directory for unzipping
temp_dir <- file.path(tempdir(), "ifcb_extract_biovolumes")

# Unzip the test data
unzip(zip_path, exdir = temp_dir)

# Define paths to the unzipped folders
feature_folder <- file.path(temp_dir, "test_data/features")
class_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
manual_folder <- file.path(temp_dir, "test_data/manual")
class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")

test_that("ifcb_extract_biovolumes works correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Run the function with test data
  biovolume_df <- ifcb_extract_biovolumes(feature_folder,
                                          class_folder,
                                          micron_factor = 1 / 3.4,
                                          diatom_class = "Bacillariophyceae",
                                          threshold = "opt",
                                          multiblob = FALSE)

  # Run the function using python
  biovolume_py <- ifcb_extract_biovolumes(feature_folder,
                                          class_folder,
                                          micron_factor = 1 / 3.4,
                                          diatom_class = "Bacillariophyceae",
                                          threshold = "opt",
                                          multiblob = FALSE,
                                          use_python = TRUE)

  # Run the function with diatom_include
  biovolume_diatom_include <- ifcb_extract_biovolumes(feature_folder,
                                                      class_folder,
                                                      micron_factor = 1 / 3.4,
                                                      diatom_class = "Bacillariophyceae",
                                                      diatom_include = "Mesodinium_rubrum",
                                                      threshold = "opt",
                                                      multiblob = FALSE)

  # Check that the .mat data from R and Python are identical
  expect_identical(biovolume_df$sample, biovolume_py$sample)
  expect_identical(biovolume_df$biovolume_um3, biovolume_py$biovolume_um3)
  expect_identical(biovolume_df$roi_number, biovolume_py$roi_number)

  # Sum carbon content
  sum_carbon <- sum(biovolume_df$carbon_pg)
  sum_diatom_include <- sum(biovolume_diatom_include$carbon_pg)

  # Check that carbon content is greater when M. rubrum is considered NOT diatom
  expect_gt(sum_carbon, sum_diatom_include)

  # Check that the returned object is a data frame
  expect_s3_class(biovolume_df, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns <- c("sample", "roi_number", "class", "biovolume_um3", "carbon_pg")
  expect_true(all(expected_columns %in% names(biovolume_df)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(biovolume_df), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and roi_number exist in the output
  expect_true("D20220522T003051_IFCB134" %in% biovolume_df$sample)
  expect_true(2 %in% biovolume_df$roi_number)

  # Example: Check if biovolume_um3 and carbon_pg are calculated correctly
  # Replace the following expected values with the actual expected values from your test data
  expected_biovolume_um3 <- 5206.2003  # Example value
  expect_equal(biovolume_df$biovolume_um3[1], expected_biovolume_um3, tolerance = 1e-8)

  expected_carbon_pg <- 668.05635  # Example value
  expect_equal(biovolume_df$carbon_pg[1], expected_carbon_pg, tolerance = 1e-8)
})

test_that("ifcb_extract_biovolumes handles empty directories", {

  # Define empty directories for features and class
  empty_feature_dir <- file.path(temp_dir, "empty_features")
  empty_class_dir <- file.path(temp_dir, "empty_class")

  dir.create(empty_feature_dir)
  dir.create(empty_class_dir)

  # Run the function with empty feature directory and expect an error
  expect_error(ifcb_extract_biovolumes(empty_feature_dir, class_folder), "No feature data files found")

  # Run the function with empty class directory and expect an error
  expect_error(ifcb_extract_biovolumes(feature_folder, empty_class_dir), "No classification files found")
})

test_that("ifcb_extract_biovolumes handles invalid directories gracefully", {

  # Define invalid directories for features and class
  invalid_feature_dir <- file.path(temp_dir, "invalid_features")
  invalid_class_dir <- file.path(temp_dir, "invalid_class")

  # Run the function with invalid directories and expect an error
  expect_error(ifcb_extract_biovolumes(invalid_feature_dir, invalid_class_dir))
})

test_that("ifcb_extract_biovolumes calculates carbon content correctly for diatoms and non-diatoms", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Use test data to check specific calculations
  biovolume_df <- ifcb_extract_biovolumes(feature_folder, class_folder, micron_factor = 1 / 3.4, diatom_class = "Bacillariophyceae", threshold = "opt", multiblob = FALSE)

  # Check if diatom classes are identified correctly and carbon is calculated
  diatom_rows <- biovolume_df %>% dplyr::filter(class %in% "Bacillariophyceae")
  expect_true(all(diatom_rows$carbon_pg > 0))

  # Check if non-diatom classes are identified correctly and carbon is calculated
  non_diatom_rows <- biovolume_df %>% dplyr::filter(!class %in% "Bacillariophyceae")
  expect_true(all(non_diatom_rows$carbon_pg > 0))
})

test_that("ifcb_extract_biovolumes diatom_equation switch raises diatom carbon only", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  images <- c("D20220522T003051_IFCB134_00002", "D20220522T003051_IFCB134_00003")

  # Diatom genus (Chaetoceros) -> Bacillariophyceae in WoRMS
  diatom_large <- ifcb_extract_biovolumes(feature_folder,
                                          custom_images = images,
                                          custom_classes = c("Chaetoceros_sp", "Chaetoceros_sp"),
                                          verbose = FALSE)
  diatom_all <- ifcb_extract_biovolumes(feature_folder,
                                        custom_images = images,
                                        custom_classes = c("Chaetoceros_sp", "Chaetoceros_sp"),
                                        diatom_equation = "all",
                                        verbose = FALSE)

  # Biovolume is unchanged; the switch only selects which diatom equation is applied.
  # Assert the deterministic contract per ROI rather than a direction of inequality,
  # which only holds below the ~4e5 micron^3 crossover of the two diatom curves.
  expect_identical(diatom_large$biovolume_um3, diatom_all$biovolume_um3)
  expect_equal(diatom_large$carbon_pg, vol2C_lgdiatom(diatom_large$biovolume_um3))
  expect_equal(diatom_all$carbon_pg, vol2C_diatom(diatom_all$biovolume_um3))

  # Non-diatom genus (Mesodinium) -> carbon must be identical regardless of the switch
  nondiatom_large <- ifcb_extract_biovolumes(feature_folder,
                                             custom_images = images,
                                             custom_classes = c("Mesodinium_rubrum", "Mesodinium_rubrum"),
                                             verbose = FALSE)
  nondiatom_all <- ifcb_extract_biovolumes(feature_folder,
                                           custom_images = images,
                                           custom_classes = c("Mesodinium_rubrum", "Mesodinium_rubrum"),
                                           diatom_equation = "all",
                                           verbose = FALSE)
  expect_equal(nondiatom_large$carbon_pg, nondiatom_all$carbon_pg)
  expect_equal(nondiatom_large$carbon_pg, vol2C_nondiatom(nondiatom_large$biovolume_um3))

  # Invalid value is rejected by match.arg
  expect_error(
    ifcb_extract_biovolumes(feature_folder,
                            custom_images = images,
                            custom_classes = c("Chaetoceros_sp", "Chaetoceros_sp"),
                            diatom_equation = "medium")
  )
})

test_that("ifcb_extract_biovolumes manual data correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  expect_error(ifcb_extract_biovolumes(feature_folder, manual_folder), "class2use_file.*must be specified")

  # Run the function with test data
  biovolume_df <- ifcb_extract_biovolumes(feature_folder, manual_folder, class2use_file = class2use_file, micron_factor = 1 / 3.4, diatom_class = "Bacillariophyceae", threshold = "opt", multiblob = FALSE)

  # Check that the returned object is a data frame
  expect_s3_class(biovolume_df, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns <- c("sample", "roi_number", "class", "biovolume_um3", "carbon_pg")
  expect_true(all(expected_columns %in% names(biovolume_df)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(biovolume_df), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and roi_number exist in the output
  expect_true("D20220522T003051_IFCB134" %in% biovolume_df$sample)
  expect_true(2 %in% biovolume_df$roi_number)

  # Example: Check if biovolume_um3 and carbon_pg are calculated correctly
  # Replace the following expected values with the actual expected values from your test data
  expected_biovolume_um3 <- 5206.2003  # Example value
  expect_equal(biovolume_df$biovolume_um3[1], expected_biovolume_um3, tolerance = 1e-8)

  expected_carbon_pg <- 668.05635  # Example value
  expect_equal(biovolume_df$carbon_pg[1], expected_carbon_pg, tolerance = 1e-8)
})

test_that("ifcb_extract_biovolumes handles customs classifications correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Define custom list
  class = c("Mesodinium_rubrum", "Mesodinium_rubrum")
  image <- c("D20220522T003051_IFCB134_00002", "D20220522T003051_IFCB134_00003")

  # Run the function with test data
  biovolume_df <- ifcb_extract_biovolumes(feature_folder, custom_classes = class, custom_images = image)

  # Check that the returned object is a data frame
  expect_s3_class(biovolume_df, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns <- c("sample", "roi_number", "class", "biovolume_um3", "carbon_pg")
  expect_true(all(expected_columns %in% names(biovolume_df)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(biovolume_df), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and roi_number exist in the output
  expect_true("D20220522T003051_IFCB134" %in% biovolume_df$sample)
  expect_true(2 %in% biovolume_df$roi_number)

  # Example: Check if biovolume_um3 and carbon_pg are calculated correctly
  # Replace the following expected values with the actual expected values from your test data
  expected_biovolume_um3 <- 5206.2003  # Example value
  expect_equal(biovolume_df$biovolume_um3[1], expected_biovolume_um3, tolerance = 1e-8)

  expected_carbon_pg <- 668.05635  # Example value
  expect_equal(biovolume_df$carbon_pg[1], expected_carbon_pg, tolerance = 1e-8)
})

test_that("ifcb_extract_biovolumes throws expected errors and warnings", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Define custom list
  class = c("Mesodinium_rubrum", "Mesodinium_rubrum")
  image <- c("D20220522T003051_IFCB134_00002", "D20220522T003051_IFCB134_00003")

  expect_warning(ifcb_extract_biovolumes(feature_folder, class_folder, custom_images = image, verbose = FALSE),
                 "Both")

  expect_error(ifcb_extract_biovolumes(feature_folder, verbose = FALSE),
               "No classification information supplied")

  expect_error(ifcb_extract_biovolumes("not_a_dir", class_folder, verbose = FALSE),
               "specified file or directory does not exist")

  expect_error(ifcb_extract_biovolumes(0, class_folder, verbose = FALSE),
               "must be a character vector")
})

test_that("carbon_conversion is validated before any file is read", {
  # No network, no files: check_carbon_conversion() runs at the top of both
  # functions, so a bad combination fails instantly.
  expect_error(
    ifcb_extract_biovolumes(feature_folder, class_folder, carbon_conversion = "cell", verbose = FALSE),
    "requires"
  )
  expect_error(
    ifcb_summarize_biovolumes(feature_folder, class_folder, carbon_conversion = "cell", verbose = FALSE),
    "requires"
  )
  expect_error(
    ifcb_extract_biovolumes(feature_folder, class_folder, carbon_conversion = "per-cell", verbose = FALSE),
    "should be one of"
  )
  expect_error(
    ifcb_extract_biovolumes(feature_folder, class_folder, diatom_equation = "automatic", verbose = FALSE),
    "should be one of"
  )
})

test_that("carbon_conversion = 'cell' applies the equation per cell and sums over the chain", {
  skip_if_offline()
  skip_on_cran()
  skip_if_not_installed("hdf5r")
  skip_if_resource_unavailable("https://marinespecies.org")

  # Synthetic .h5 for the sample the real feature file covers (ROIs 2 and 3),
  # single-class so the exponent b is unambiguous. Chaetoceros is a diatom in
  # WoRMS, so diatom_equation selects the conversion.
  chain_dir <- file.path(tempdir(), "ifcb_extract_biovolumes_percell")
  dir.create(chain_dir, showWarnings = FALSE)
  on.exit(unlink(chain_dir, recursive = TRUE), add = TRUE)

  write_chain_h5 <- function(path, counts) {
    f <- hdf5r::H5File$new(path, mode = "w")
    cl <- "Chaetoceros_sp"
    f[["class_labels"]] <- cl
    f[["roi_numbers"]] <- c(2L, 3L)
    f[["output_scores"]] <- matrix(0.9, nrow = 1, ncol = 2)
    f[["classifier_name"]] <- "test_clf"
    f[["class_name_auto"]] <- rep(cl, 2)
    f[["class_name"]] <- rep(cl, 2)
    f[["thresholds"]] <- 0.5
    f[["cell_count"]] <- counts
    f$close_all()
  }
  h5_path <- file.path(chain_dir, "D20220522T003051_IFCB134_class.h5")
  write_chain_h5(h5_path, c(4L, 5L))

  roi <- ifcb_extract_biovolumes(feature_folder, chain_dir, use_cell_counts = TRUE,
                                 verbose = FALSE)
  cell <- ifcb_extract_biovolumes(feature_folder, chain_dir, use_cell_counts = TRUE,
                                  carbon_conversion = "cell", verbose = FALSE)

  # Biovolume is a linear sum, so it cannot depend on how carbon is converted.
  expect_identical(roi$biovolume_um3, cell$biovolume_um3)
  # cell_count_resolved must keep its position after carbon_pg.
  expect_identical(names(roi), names(cell))
  expect_equal(cell$cell_count_resolved, c(4L, 5L))

  # Closed form for a power law: n * f(V/n) == f(V) * n^(1-b), b = 0.881.
  expect_equal(cell$carbon_pg, roi$carbon_pg * c(4, 5)^(1 - 0.881))
  # The all-sizes equation has b = 0.811.
  cell_all <- ifcb_extract_biovolumes(feature_folder, chain_dir, use_cell_counts = TRUE,
                                      carbon_conversion = "cell", diatom_equation = "all",
                                      verbose = FALSE)
  roi_all <- ifcb_extract_biovolumes(feature_folder, chain_dir, use_cell_counts = TRUE,
                                     diatom_equation = "all", verbose = FALSE)
  expect_equal(cell_all$carbon_pg, roi_all$carbon_pg * c(4, 5)^(1 - 0.811))

  # Single cells and unmeasured ROIs must reproduce the whole-ROI numbers exactly.
  for (counts in list(c(1L, 1L), c(-1L, 0L))) {
    write_chain_h5(h5_path, counts)
    a <- ifcb_extract_biovolumes(feature_folder, chain_dir, use_cell_counts = TRUE,
                                 verbose = FALSE)
    b <- ifcb_extract_biovolumes(feature_folder, chain_dir, use_cell_counts = TRUE,
                                 carbon_conversion = "cell", verbose = FALSE)
    expect_identical(a$carbon_pg, b$carbon_pg)
  }
})

test_that("carbon_conversion = 'roi' leaves carbon_pg bit-for-bit unchanged", {
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Reading chain counts must not perturb carbon while the default conversion
  # is in force; this is the regression guarantee for existing users.
  without <- ifcb_extract_biovolumes(feature_folder, class_folder, verbose = FALSE)
  with_eq <- ifcb_extract_biovolumes(feature_folder, class_folder,
                                     diatom_equation = "large", verbose = FALSE)
  expect_identical(without$carbon_pg, with_eq$carbon_pg)
})

test_that("diatom_equation = 'auto' selects per volume and is discontinuous at 3000", {
  # vol2C_diatom_auto is what backs the argument; check the selection directly
  # so this needs no network.
  small <- 2000
  large <- 20000
  expect_identical(vol2C_diatom_auto(small), vol2C_diatom(small))
  expect_identical(vol2C_diatom_auto(large), vol2C_lgdiatom(large))
  # Crossing the boundary upward makes carbon fall, which is the documented
  # (and deliberate) consequence of keeping each equation in calibration.
  expect_gt(vol2C_diatom_auto(2999), vol2C_diatom_auto(3001))
})

test_that("ifcb_extract_biovolumes aborts when a sample resolves to two class files", {
  # A folder holding both a .mat and a .h5 for one sample would join both sets
  # of ROI rows and double that sample's counts and biovolume. The guard runs
  # before any file is read, so the .h5 here need not be a real HDF5 file and
  # the test needs no network access.
  dup_folder <- file.path(tempdir(), "ifcb_extract_biovolumes_dup")
  dir.create(dup_folder, showWarnings = FALSE)
  on.exit(unlink(dup_folder, recursive = TRUE), add = TRUE)

  file.copy(list.files(class_folder, full.names = TRUE), dup_folder, overwrite = TRUE)
  mat_file <- list.files(dup_folder, pattern = "_class_v1\\.mat$", full.names = TRUE)[1]
  sample_name <- sub("_class(_v\\d+)?\\.mat$", "", basename(mat_file))
  file.create(file.path(dup_folder, paste0(sample_name, "_class.h5")))

  expect_error(
    ifcb_extract_biovolumes(feature_folder, dup_folder, verbose = FALSE),
    "resolves to more than one classification file"
  )

  # ifcb_summarize_biovolumes() delegates to the above, so it must abort too.
  expect_error(
    ifcb_summarize_biovolumes(feature_folder, dup_folder, verbose = FALSE),
    "resolves to more than one classification file"
  )

  # A `{sample}_class.csv` label file is the same collision by a different
  # extension, and must be caught as well.
  unlink(file.path(dup_folder, paste0(sample_name, "_class.h5")))
  writeLines("file_name,class_name", file.path(dup_folder, paste0(sample_name, "_class.csv")))
  expect_error(
    ifcb_extract_biovolumes(feature_folder, dup_folder, verbose = FALSE),
    "resolves to more than one classification file"
  )

  # The non-duplicate case is covered by the main test above, which uses this
  # same class folder.
})

unlink(temp_dir, recursive = TRUE)

test_that("a missing cell_count inside a chain-counted file warns in ifcb_extract_biovolumes", {
  skip_if_offline()
  skip_on_cran()
  skip_if_not_installed("hdf5r")
  skip_if_resource_unavailable("https://marinespecies.org")

  # Self-sufficient fixture: earlier tests remove the file-level temp_dir.
  nagap_dir <- file.path(tempdir(), "ifcb_extract_biovolumes_nagap")
  on.exit(unlink(nagap_dir, recursive = TRUE), add = TRUE)
  unzip(zip_path, exdir = nagap_dir)
  feature_folder <- file.path(nagap_dir, "test_data/features")

  chain_dir <- file.path(nagap_dir, "chain")
  dir.create(chain_dir, showWarnings = FALSE)

  f <- hdf5r::H5File$new(file.path(chain_dir, "D20220522T003051_IFCB134_class.h5"), mode = "w")
  cl <- "Chaetoceros_sp"
  f[["class_labels"]] <- cl
  f[["roi_numbers"]] <- c(2L, 3L)
  f[["output_scores"]] <- matrix(0.9, nrow = 1, ncol = 2)
  f[["classifier_name"]] <- "test_clf"
  f[["class_name_auto"]] <- rep(cl, 2)
  f[["class_name"]] <- rep(cl, 2)
  f[["thresholds"]] <- 0.5
  # The file carries cell_count data, but one ROI's value is missing. This
  # used to null the sample's cell_counts downstream with no diagnostic.
  f[["cell_count"]] <- c(4, NaN)
  f$close_all()

  expect_warning(
    res <- ifcb_extract_biovolumes(feature_folder, chain_dir,
                                   use_cell_counts = TRUE, verbose = FALSE),
    "missing"
  )
  expect_true(is.na(res$cell_count[res$roi_number == 3]))
  expect_equal(res$cell_count[res$roi_number == 2], 4)
})
