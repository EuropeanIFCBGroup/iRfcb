test_that("ifcb_create_empty_manual_file creates MAT file with correct parameters", {

  output_file <- tempfile()

  # Call the function being tested
  ifcb_create_empty_manual_file(
    roi_length = 100,
    class2use = c("unclassified", "Aphanizomenon_spp_filament"),
    output_file = output_file,
    unclassified_id = 1
  )

  classlist <- ifcb_get_mat_variable(output_file,
                                    "classlist")

  expect_equal(nrow(classlist), 100)

  unlink(output_file)
})
