# Define the path to the test .mat file
summary_file_path <- system.file("exdata/example_summary.mat", package = "iRfcb")

# Directory to extract files
exdir <- file.path(tempdir(), "ifcb_read_summary")

# Extract the files
unzip(test_path("test_data/test_data.zip"), exdir = exdir)

# Define the path to the example HDR file in the package
hdr_directory_path <- file.path(exdir, "test_data/data")

test_that("ifcb_read_summary correctly reads and processes the summary file", {
  # Call the function with the .mat file and header directory
  summary_data <- ifcb_read_summary(summary_file_path, hdr_directory = hdr_directory_path, biovolume = FALSE, threshold = "opt")

  # Check that the returned object is a data frame
  expect_type(summary_data, "list")

  # Check that the data frame has the expected columns
  expected_columns <- c("sample", "timestamp", "date", "year", "month", "day", "time", "ifcb_number",
                        "gpsLatitude", "gpsLongitude", "ml_analyzed", "species", "counts", "counts_per_liter")
  expect_true(all(expected_columns %in% names(summary_data)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(summary_data), 0)

  # Check some specific values (replace with expected values based on your .mat file)
  expected_sample <- "D20230810T113059_IFCB134"
  expect_true(expected_sample %in% summary_data$sample)

  # Example checks for specific columns
  expect_equal(summary_data$ml_analyzed[summary_data$sample == expected_sample][1], 3.171845, tolerance = 1e-7)
  expect_equal(summary_data$gpsLatitude[summary_data$sample == expected_sample][1], 58.25984, tolerance = 1e-7)
  expect_equal(summary_data$counts_per_liter[summary_data$sample == expected_sample][1], 315.27394, tolerance = 1e-8)
})

test_that("ifcb_read_summary correctly reads and processes the summary file with python", {

  skip_if_no_scipy()

  # Call the function with the .mat file and header directory
  summary_data <- ifcb_read_summary(summary_file_path, hdr_directory = hdr_directory_path, biovolume = FALSE, use_python = TRUE, threshold = "opt")

  # Check that the returned object is a data frame
  expect_type(summary_data, "list")

  # Check that the data frame has the expected columns
  expected_columns <- c("sample", "timestamp", "date", "year", "month", "day", "time", "ifcb_number",
                        "gpsLatitude", "gpsLongitude", "ml_analyzed", "species", "counts", "counts_per_liter")
  expect_true(all(expected_columns %in% names(summary_data)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(summary_data), 0)

  # Check some specific values (replace with expected values based on your .mat file)
  expected_sample <- "D20230810T113059_IFCB134"
  expect_true(expected_sample %in% summary_data$sample)

  # Example checks for specific columns
  expect_equal(summary_data$ml_analyzed[summary_data$sample == expected_sample][1], 3.171845, tolerance = 1e-7)
  expect_equal(summary_data$gpsLatitude[summary_data$sample == expected_sample][1], 58.25984, tolerance = 1e-7)
  expect_equal(summary_data$counts_per_liter[summary_data$sample == expected_sample][1], 315.27394, tolerance = 1e-8)
})

test_that("ifcb_read_summary reads a summary holding more than one sample", {
  # countcells_allTBnew_user_training stores filelistTB as an N x 24 char
  # matrix, one fixed-width row per sample. The example_summary.mat fixture
  # holds a single sample, where that collapses to an ordinary 1 x 24 char
  # array, so only a multi-sample summary exercises the multi-row layout.
  samples <- c("D20220522T003051_IFCB134", "D20220712T210855_IFCB134")
  counts <- matrix(c(5, 3, 0, 7), nrow = 2)
  summary_path <- tempfile(fileext = ".mat")
  on.exit(unlink(summary_path), add = TRUE)
  write_mat_v5(summary_path, list(
    class2useTB = mat_var_cell(matrix(c("Mesodinium_rubrum", "unclassified"), ncol = 1)),
    classcountTB = mat_var_double(counts),
    classcountTB_above_optthresh = mat_var_double(counts),
    ml_analyzedTB = mat_var_double(matrix(c(3, 4), ncol = 1)),
    mdateTB = mat_var_double(matrix(c(738662, 738713), ncol = 1)),
    filelistTB = mat_var_char(samples),
    adhocthresh = mat_var_double(matrix(c(0.5, 0.5), ncol = 1)),
    classpath_generic = mat_var_char("C:\\classifier\\classxxxx_v1")
  ))

  summary_data <- ifcb_read_summary(summary_path, biovolume = FALSE, threshold = "opt")

  expect_setequal(unique(summary_data$sample), samples)
  expect_equal(
    summary_data$counts[summary_data$sample == samples[1] &
                          summary_data$species == "Mesodinium_rubrum"],
    5
  )
  expect_equal(
    summary_data$counts[summary_data$sample == samples[2] &
                          summary_data$species == "unclassified"],
    7
  )
})

test_that("ifcb_read_summary handles non-existent file gracefully", {
  # Define a non-existent file path
  non_existent_file <- "non_existent_file.mat"

  # Call the function and expect an error
  expect_error(ifcb_read_summary(non_existent_file))
})

test_that("ifcb_read_summary throws an error if biovolume is requested but missing", {
  # Call the function with biovolume TRUE
  expect_error(
    summary_data <- ifcb_read_summary(summary_file_path, hdr_directory = hdr_directory_path, biovolume = TRUE, threshold = "opt"),
    "Biovolume data for threshold"
  )
})

test_that("ifcb_read_summary handles lists correctly", {

  # Define classpath_generic and hdr_folder based on the extracted data
  classpath_generic <- file.path(exdir, "test_data", "class", "classxxxx_v1")
  hdr_folder <- file.path(exdir, "test_data", "data")

  # Define the year range to process
  year_range <- 2022

  # Call the function to summarize class counts
  summary_data <- ifcb_summarize_class_counts(classpath_generic, hdr_folder, year_range)

  # Call the function with the list and header directory
  data <- ifcb_read_summary(summary_data, hdr_directory = hdr_directory_path, biovolume = FALSE, threshold = "opt")

  # Check some specific values (replace with expected values based on your .mat file)
  expected_sample <- "D20220522T003051_IFCB134"
  expect_true(expected_sample %in% data$sample)

  # Mock biovolume information
  summary_data$classbiovolTB_above_optthresh <- matrix(1, nrow = 1, ncol = 46)

  # Call the function with biovolume data
  data <- ifcb_read_summary(summary_data, hdr_directory = hdr_directory_path, biovolume = TRUE, threshold = "opt")

  expect_equal(ncol(data), 17)
})

unlink(exdir)
