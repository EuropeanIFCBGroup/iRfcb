test_that("ifcb_create_empty_manual_file creates MAT file with correct parameters", {
  # Skip if Python is not available
  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

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
