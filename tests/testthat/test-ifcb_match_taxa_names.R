test_that("ifcb_match_taxa_names handles errors gracefully", {
  # Sample taxa list
  taxa_list <- c("not_a_valid_taxa", "non/valid")

  # Check for internet connection and skip the test if offline
  skip_if_offline()

  # Call the function
  result <- ifcb_match_taxa_names(taxa_list,
                                  verbose = TRUE)

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c("no content", "no content")

  # Assert the results
  expect_equal(result$status, expected_result)
})

test_that("deprecated helpers are still working", {
  record <- dplyr::tibble(AphiaID = c(12345))

  lifecycle::expect_deprecated(iRfcb:::extract_aphia_id(record))
  record_results <- suppressWarnings(iRfcb:::extract_aphia_id(record))

  expect_equal(12345, record_results)

  classes <- dplyr::tibble(class = c("Class"))

  lifecycle::expect_deprecated(iRfcb:::extract_class(classes))
  classes_results <- suppressWarnings(iRfcb:::extract_class(classes))

  expect_equal("Class", classes_results)
})

test_that("deprecated helper is still working", {
  skip_if_offline()

  name <- "Skeletonema"

  lifecycle::expect_deprecated(iRfcb:::retrieve_worms_records(name))
  record_results <- suppressWarnings(iRfcb:::retrieve_worms_records(name))

  expect_true("AphiaID" %in% names(record_results$Skeletonema))
})
