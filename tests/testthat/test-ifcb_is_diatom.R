test_that("ifcb_is_diatom correctly identifies diatoms", {
  # Sample taxa list
  taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")

  # Mock the helper function and extract_class for the test environment
  assignInNamespace("retrieve_worms_records", mocked_worms_records, ns = "iRfcb")
  assignInNamespace("extract_class", mocked_extract_class, ns = "iRfcb")

  # Call the function
  result <- ifcb_is_diatom(taxa_list)

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c(TRUE, TRUE, FALSE, TRUE)

  # Assert the results
  expect_equal(result, expected_result)
})

test_that("retrieve_worms_records retries and fails after max_retries", {
  # Mock the wm_records_names function to always throw an error
  mockery::stub(retrieve_worms_records, "wm_records_names", mocked_wm_records_names_error)

  # Track the number of retries
  retries <- 0
  test_sleep <- function(sleep_time) {
    retries <<- retries + 1
  }

  # Mock Sys.sleep to count retries instead of actually waiting
  mockery::stub(retrieve_worms_records, "Sys.sleep", test_sleep)

  # Expect the function to throw an error after max_retries
  expect_error(
    retrieve_worms_records(c("Nitzschia", "Chaetoceros"), max_retries = 3, sleep_time = 0.1),
    "Error occurred while retrieving WoRMS records after 3 attempts"
  )

  # Check that it retried the correct number of times
  expect_equal(retries, 2)
})
