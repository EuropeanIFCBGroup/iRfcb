test_that("ifcb_get_trophic_type correctly retrieves trophic types for a list of taxa", {
  # Define the taxa list for testing
  taxa_list <- c("Acanthoceras zachariasii", "Nodularia spumigena", "Acanthoica quattrospina", "Noctiluca", "Gymnodiniales")

  # Call the function with the taxa list
  trophic_types <- ifcb_get_trophic_type(taxa_list)

  # Check if the retrieved trophic types are correct
  expected_trophic_types <- c("AU", "AU", "MX", "HT", "NS")
  expect_equal(trophic_types, expected_trophic_types, info = "Trophic types should match the expected values for the given taxa list")
})

test_that("ifcb_get_trophic_type prints complete list when print_complete_list is TRUE", {
  # Call the function with print_complete_list set to TRUE
  complete_list <- ifcb_get_trophic_type(print_complete_list = TRUE)

  # Expected data frame
  expected_df <- dplyr::tibble(
    scientific_name = c("Acanthoceras zachariasii", "Nodularia spumigena", "Acanthoica quattrospina", "Noctiluca", "Gymnodiniales"),
    trophic_type = c("AU", "AU", "MX", "HT", "NS")
  )

  # Check if the complete list matches the expected data frame
  expect_true(all(expected_df$scientific_name %in% complete_list$scientific_name), info = "All scientific names should be present in the complete list")
  expect_true(all(expected_df$trophic_type %in% complete_list$trophic_type), info = "All trophic types should be present in the complete list")
})

test_that("ifcb_get_trophic_type handles invalid inputs gracefully", {
  # Check if the function handles non-character taxa_list
  expect_error(ifcb_get_trophic_type(taxa_list = 123), "Error: taxa_list must be a character vector.")

  # Check if the function handles non-logical print_complete_list
  expect_error(ifcb_get_trophic_type(print_complete_list = "yes"), "Error: print_complete_list must be a logical value.")

  # Check if the function handles NULL input without print_complete_list
  expect_error(ifcb_get_trophic_type(), "Error: No valid input provided. Please specify either taxa_list or set print_complete_list to TRUE.")

  # Check if the function handles input with print_complete_list
  expect_warning(ifcb_get_trophic_type(taxa_list = "Chaetoceros", print_complete_list = TRUE), "Both taxa_list and print_complete_list are provided. Only the taxa_list results will be returned.")
})
