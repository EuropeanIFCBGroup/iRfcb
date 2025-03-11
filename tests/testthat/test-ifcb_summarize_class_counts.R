test_that("ifcb_summarize_class_counts works correctly", {
  # Define paths to the test data
  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_summarize_class_counts")
  unzip(test_data_zip, exdir = temp_dir)

  # Define classpath_generic and hdr_folder based on the extracted data
  classpath_generic <- file.path(temp_dir, "test_data", "class", "classxxxx_v1")
  hdr_folder <- file.path(temp_dir, "test_data", "data")

  # Define the year range to process
  year_range <- 2022

  # Call the function to summarize class counts
  summary_data <- ifcb_summarize_class_counts(classpath_generic, hdr_folder, year_range)

  # Check that the summary data has the correct structure and elements
  expect_type(summary_data, "list")
  expect_named(summary_data, c("class2useTB", "classcountTB", "classcountTB_above_optthresh", "ml_analyzedTB", "mdateTB", "filelistTB", "classpath_generic", "classcountTB_above_adhocthresh", "adhocthresh"))

  # Check the individual elements in the summary data
  expect_type(summary_data$class2useTB, "character")
  expect_type(summary_data$classcountTB, "integer")
  expect_type(summary_data$classcountTB_above_optthresh, "integer")
  expect_type(summary_data$ml_analyzedTB, "double")
  expect_type(summary_data$mdateTB, "double")
  expect_type(summary_data$filelistTB, "character")
  expect_type(summary_data$classpath_generic, "character")

  # Additional checks for dimensions and values
  expect_equal(nrow(summary_data$classcountTB), length(summary_data$filelistTB))
  expect_equal(ncol(summary_data$classcountTB), length(summary_data$class2useTB))
  expect_equal(length(summary_data$ml_analyzedTB), length(summary_data$filelistTB))
  expect_equal(length(summary_data$mdateTB), length(summary_data$filelistTB))

  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})
