test_that("ifcb_match_taxa_names handles errors gracefully", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()

  # Sample taxa list
  taxa_list <- c("not_a_valid_taxa", "non/valid")

  # Call the function
  result <- ifcb_match_taxa_names(taxa_list,
                                  verbose = TRUE)

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c("no content", "no content")

  # Assert the results
  expect_equal(result$status, expected_result)
})

test_that("deprecated function is still working", {
  skip_if_offline()
  skip_on_cran()

  name <- "Skeletonema"

  lifecycle::expect_deprecated(retrieve_worms_records(name))
  record_results <- suppressWarnings(retrieve_worms_records(name))

  expect_true("AphiaID" %in% names(record_results$Skeletonema))
})
