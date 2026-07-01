test_that("ifcb_create_empty_manual_file creates MAT file with correct parameters", {

  output_file <- tempfile()

  # Call the function being tested
  lifecycle::expect_deprecated(ifcb_create_empty_manual_file(
    roi_length = 100,
    class2use = c("unclassified", "Aphanizomenon_spp_filament"),
    output_file = output_file,
    classlist = 1
  ))

  unlink(output_file)
})

test_that("ifcb_create_empty_manual_file handles deprecated arguments correctly", {

  output_file <- tempfile()

  # Call the function being tested
  lifecycle::expect_deprecated(
    lifecycle::expect_deprecated(ifcb_create_empty_manual_file(
      roi_length = 100,
      class2use = c("unclassified", "Aphanizomenon_spp_filament"),
      output_file = output_file,
      unclassified_id = 1
    )
    )
  )

  unlink(output_file)
})
