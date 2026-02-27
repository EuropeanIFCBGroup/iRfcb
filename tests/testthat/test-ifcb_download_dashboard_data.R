test_that("ifcb_download_dashboard_data download data correctly", {

  # Skip the test if the internet connection is not available
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable("https://ifcb-data.whoi.edu")

  dest_dir <- file.path(tempdir(), "ifcb_download_dashboard_data")

  # Download hdr data
  ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu/data",
    samples = "IFCB1_2014_188_222013",
    file_types = "hdr",
    dest_dir = dest_dir,
    convert_filenames = FALSE,
    convert_adc = FALSE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  )

  # Expect that the destination folder is not empty
  expect_true(dir.exists(dest_dir))

  # Expect that the destination folder contains the expected files
  expect_equal(length(list.files(dest_dir, recursive = TRUE)), 1)

  # Download hdr data and convert it
  ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu",
    samples = "IFCB1_2014_188_222013",
    file_types = "hdr",
    dest_dir = dest_dir,
    convert_filenames = TRUE,
    convert_adc = FALSE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  )

  # Expect that the destination folder contains the expected files
  expect_equal(length(list.files(dest_dir, recursive = TRUE)), 2)

  # Download adc data and convert it
  ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu",
    samples = "IFCB1_2006_237_000054",
    file_types = "adc",
    dest_dir = dest_dir,
    convert_filenames = TRUE,
    convert_adc = TRUE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  )

  # Expect that the destination folder contains the expected files
  expect_equal(length(list.files(dest_dir, recursive = TRUE)), 3)

  adc_data <- read.csv(file.path(dest_dir, "D20060825", "D20060825T000054_IFCB1.adc"))

  expect_equal(ncol(adc_data), 20)

  # Store the creation time of the hdr file
  ctime <- file.info(file.path(dest_dir, "D20060825", "D20060825T000054_IFCB1.adc"))$ctime

  # Download adc data again
  ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu",
    samples = "IFCB1_2006_237_000054",
    file_types = "adc",
    dest_dir = dest_dir,
    convert_filenames = TRUE,
    convert_adc = TRUE,
    max_retries = 1,
    sleep_time = 0,
    quiet = FALSE
  )

  # Expect that the destination folder contains the expected files
  expect_equal(length(list.files(dest_dir, recursive = TRUE)), 3)

  # Expect that the creation time of the hdr file is the same
  expect_equal(file.info(file.path(dest_dir, "D20060825", "D20060825T000054_IFCB1.adc"))$ctime, ctime)

  # Download autoclass data
  ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu/mvco/",
    samples = "IFCB1_2006_237_000054",
    file_types = "autoclass",
    dest_dir = dest_dir,
    convert_filenames = FALSE,
    convert_adc = FALSE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  )

  # Expect that the destination folder contains the expected files
  expect_equal(length(list.files(dest_dir, recursive = TRUE)), 4)

  # Verify that helper function works as expected
  date_object <- process_ifcb_string("D20240101T120000_IFCB1")
  expect_equal(date_object, "D20240101")

  date_object <- process_ifcb_string("non-valid-format")
  expect_true(is.na(date_object))

  # Download autoclass data
  ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu/mvco/",
    samples = "D20190402T200352_IFCB010",
    file_types = "features",
    dest_dir = dest_dir,
    convert_filenames = FALSE,
    convert_adc = FALSE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  )

  # Expect that the destination folder contains the expected files
  expect_equal(length(list.files(dest_dir, recursive = TRUE)), 5)

  # Clean up
  unlink(dest_dir, recursive = TRUE)
})

test_that("ifcb_download_dashboard_data handles errors gracefully", {

  dest_dir <- file.path(tempdir(), "ifcb_download_dashboard_data")

  # Download hdr data and expect error
  expect_error(ifcb_download_dashboard_data(
    dashboard_url = "https://ifcb-data.whoi.edu/data",
    samples = "IFCB1_2014_188_222013",
    file_types = "nonvalid_extension",
    dest_dir = dest_dir,
    convert_filenames = FALSE,
    convert_adc = FALSE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  ), "Invalid extension")

  # Download hdr data and expect error
  expect_warning(ifcb_download_dashboard_data(
    dashboard_url = "https://nodashboard.com",
    samples = "IFCB1_2014_188_222013",
    file_types = "hdr",
    dest_dir = dest_dir,
    convert_filenames = FALSE,
    convert_adc = FALSE,
    max_retries = 1,
    sleep_time = 0,
    quiet = TRUE
  ), "Some downloads failed")

  # Clean up
  unlink(dest_dir, recursive = TRUE)
})
