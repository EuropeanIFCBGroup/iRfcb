test_that("ifcb_is_diatom correctly identifies diatoms", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

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
  skip_if_resource_unavailable("https://marinespecies.org")

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

test_that("ifcb_is_diatom overrides ", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Sample taxa list
  taxa_list <- c("Navicula", "Actinocyclus", "Dinophysis_norvegica")

  # Call the function
  result <- ifcb_is_diatom(taxa_list)

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c(TRUE, FALSE, FALSE)

  # Assert the results
  expect_equal(result, expected_result)

  # Call the function with the diatom_include argument
  result_diatom_include <- ifcb_is_diatom(taxa_list,
                                          diatom_include = c("Navicula", "Actinocyclus"))

  # Expected logical vector (true for diatoms, false for others)
  expected_result <- c(TRUE, TRUE, FALSE)

  # Assert the results
  expect_equal(result_diatom_include, expected_result)
})

test_that("ifcb_is_diatom details surfaces the resolved WoRMS class for homonyms", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  taxa_list <- c("Actinocyclus", "Chaetoceros_sp", "Dinophysis_norvegica")

  details <- ifcb_is_diatom(taxa_list, details = TRUE)

  # Returns a data frame with one row per input taxon and the documented columns
  expect_s3_class(details, "data.frame")
  expect_identical(nrow(details), length(taxa_list))
  expect_named(details, c("taxa", "genus", "worms_class", "is_diatom"))
  expect_identical(details$taxa, taxa_list)

  # is_diatom is consistent with the default (logical-vector) return
  expect_identical(details$is_diatom, ifcb_is_diatom(taxa_list))

  # The homonym (Actinocyclus, a diatom genus shared with animals) is exposed:
  # it resolves to a non-diatom WoRMS class, so the user can spot it and add it
  # to diatom_include.
  actinocyclus <- details[details$taxa == "Actinocyclus", ]
  expect_false(actinocyclus$is_diatom)
  expect_false(isTRUE(actinocyclus$worms_class == "Bacillariophyceae"))

  # A genuine diatom resolves to Bacillariophyceae
  chaetoceros <- details[details$taxa == "Chaetoceros_sp", ]
  expect_true(chaetoceros$is_diatom)
  expect_identical(chaetoceros$worms_class, "Bacillariophyceae")
})
