# Path to temporary test folder
test_feature_folder <- file.path(tempdir(), "test_features")

test_that("ifcb_read_features reads all feature files correctly", {
  setup_test_files(test_feature_folder)

  features <- ifcb_read_features(test_feature_folder)

  expect_equal(length(features), 2)
  expect_equal(names(features), c("D20230316T101514_fea_v2.csv", "D20230316T101516_fea_v2.csv"))

  cleanup_test_files(test_feature_folder)
})

test_that("ifcb_read_features reads all feature files correctly", {
  setup_test_files(test_feature_folder)

  features <- ifcb_read_features(test_feature_folder, biovolume_only = TRUE, feature_version = 2)

  expect_equal(length(features), 2)
  expect_equal(ncol(features[[1]]), 2)
  expect_equal(names(features), c("D20230316T101514_fea_v2.csv", "D20230316T101516_fea_v2.csv"))

  cleanup_test_files(test_feature_folder)
})

test_that("ifcb_read_features filters multiblob files correctly", {
  setup_test_files(test_feature_folder)

  multiblob_features <- ifcb_read_features(test_feature_folder, multiblob = TRUE)

  expect_equal(length(multiblob_features), 1)
  expect_equal(names(multiblob_features), "D20230316T101515_multiblob_fea_v2.csv")

  single_blob_features <- ifcb_read_features(test_feature_folder, multiblob = FALSE)

  expect_equal(length(single_blob_features), 2)
  expect_equal(names(single_blob_features), c("D20230316T101514_fea_v2.csv", "D20230316T101516_fea_v2.csv"))

  cleanup_test_files(test_feature_folder)
})

test_that("ifcb_read_features returns an empty list if no feature files are present", {
  # Create an empty directory
  empty_dir <- file.path(tempdir(), "empty_feature_folder")
  if (!dir.exists(empty_dir)) {
    dir.create(empty_dir)
  }

  features <- ifcb_read_features(empty_dir)

  expect_equal(length(features), 0)

  # Clean up
  unlink(empty_dir, recursive = TRUE)
})

test_that("ifcb_read_features returns named list of data frames", {
  setup_test_files(test_feature_folder)

  features <- ifcb_read_features(test_feature_folder)

  expect_true(all(sapply(features, is.data.frame)))

  cleanup_test_files(test_feature_folder)
})
