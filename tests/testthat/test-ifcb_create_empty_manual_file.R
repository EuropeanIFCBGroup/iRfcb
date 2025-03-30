test_that("ifcb_create_empty_manual_file creates MAT file with correct parameters", {
  # Skip if Python is not available
  skip_if_no_scipy()

  output_file <- tempfile()

  # Call the function being tested
  ifcb_create_empty_manual_file(
    roi_length = 100,
    class2use = c("unclassified", "Aphanizomenon_spp_filament"),
    output_file = output_file,
    classlist = 1
  )

  classlist <- ifcb_get_mat_variable(output_file,
                                    "classlist")

  expect_equal(nrow(classlist), 100)

  unlink(output_file)
})

test_that("ifcb_create_empty_manual_file handles a custom classlist correctly", {
  # Skip if Python is not available
  skip_if_no_scipy()

  output_file <- tempfile()

  custom_rois <- 200:299

  # Call the function being tested
  ifcb_create_empty_manual_file(
    roi_length = 100,
    class2use = c("unclassified", "Aphanizomenon_spp_filament"),
    output_file = output_file,
    classlist = custom_rois
  )

  classlist <- ifcb_get_mat_variable(output_file,
                                     "classlist")

  expect_equal(nrow(classlist), 100)
  expect_equal(classlist[,2], custom_rois)

  unlink(output_file)
})

test_that("ifcb_create_empty_manual_file handles deprecated arguments correctly", {
  # Skip if Python is not available
  skip_if_no_scipy()

  output_file <- tempfile()

  # Call the function being tested
  lifecycle::expect_deprecated(ifcb_create_empty_manual_file(
    roi_length = 100,
    class2use = c("unclassified", "Aphanizomenon_spp_filament"),
    output_file = output_file,
    unclassified_id = 1
  ))

  classlist <- ifcb_get_mat_variable(output_file,
                                     "classlist")

  expect_equal(nrow(classlist), 100)

  unlink(output_file)
})
