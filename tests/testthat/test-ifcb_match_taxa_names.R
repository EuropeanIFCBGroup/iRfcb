test_that("ifcb_match_taxa_names handles errors gracefully", {
  # Sample taxa list
  taxa_list <- c("not_a_valid_taxa", "non/valid")

  # Call the function
  result <- ifcb_match_taxa_names(taxa_list,
                                  verbose = TRUE)

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c("no content", "not found")

  # Assert the results
  expect_equal(result$status, expected_result)
})
