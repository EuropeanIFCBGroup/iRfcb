test_that("ifcb_is_diatom correctly identifies diatoms", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()

  # Sample taxa list
  taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")

  # Call the function
  result <- ifcb_is_diatom(taxa_list)

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c(TRUE, TRUE, FALSE, TRUE)

  # Assert the results
  expect_equal(result, expected_result)
})

test_that("ifcb_match_taxa_names retries and fails after max_retries", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()

  # Mock the wm_records_names function to always throw an error
  mockery::stub(ifcb_match_taxa_names, "wm_records_names", mocked_wm_records_names_error)

  # Track the number of retries
  retries <- 1
  test_sleep <- function(sleep_time) {
    retries <<- retries + 1
  }

  # Mock Sys.sleep to count retries instead of actually waiting
  mockery::stub(ifcb_match_taxa_names, "Sys.sleep", test_sleep)

  # Expect the function to throw an error after max_retries
  expect_error(
    ifcb_match_taxa_names(c("Nitzschia", "Chaetoceros"), max_retries = 3, sleep_time = 0.1, return_list = TRUE),
    "Error retrieving WoRMS records"
  )

  # Check that it retried the correct number of times
  expect_equal(retries, 3)
})
