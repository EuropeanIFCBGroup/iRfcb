library(testthat)
library(magrittr)
library(purrr)
library(stringr)
library(worrms)
library(mockery)

# Mock wm_records_names to return predefined results
mock_wm_records_names <- function(names, marine_only) {
  records <- list(
    Nitzschia = list(class = "Bacillariophyceae"),
    Chaetoceros = list(class = "Bacillariophyceae"),
    Dinophysis = list(class = "Dinophyceae"),
    Thalassiosira = list(class = "Bacillariophyceae")
  )
  lapply(names, function(name) records[[name]])
}

# Mocking the extract_class function to return the class from the mocked records
mock_extract_class <- function(record) {
  record$class
}

test_that("ifcb_is_diatom correctly identifies diatoms", {
  # Mock the wm_records_names function
  stub(ifcb_is_diatom, 'wm_records_names', mock_wm_records_names)
  # Mock the extract_class function
  stub(ifcb_is_diatom, 'extract_class', mock_extract_class)

  # Define the taxa list for testing
  taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")

  # Call the function with the taxa list
  is_diatom <- ifcb_is_diatom(taxa_list)

  # Check if the function correctly identifies diatoms
  expected_is_diatom <- c(TRUE, TRUE, FALSE, TRUE)
  expect_equal(is_diatom, expected_is_diatom, info = "Diatoms should be correctly identified")
})

test_that("ifcb_is_diatom handles taxa names with different formats", {
  # Mock the wm_records_names function
  stub(ifcb_is_diatom, 'wm_records_names', mock_wm_records_names)
  # Mock the extract_class function
  stub(ifcb_is_diatom, 'extract_class', mock_extract_class)

  # Define the taxa list with different formats
  taxa_list <- c("Nitzschia spp.", "Chaetoceros sp.", "Dinophysis-like", "Thalassiosira single cell")

  # Call the function with the taxa list
  is_diatom <- ifcb_is_diatom(taxa_list)

  # Check if the function correctly identifies diatoms
  expected_is_diatom <- c(TRUE, TRUE, FALSE, TRUE)
  expect_equal(is_diatom, expected_is_diatom, info = "Diatoms should be correctly identified for different name formats")
})

test_that("ifcb_is_diatom handles errors from wm_records_names gracefully", {
  # Mock wm_records_names to throw an error
  stub(ifcb_is_diatom, 'wm_records_names', function(names, marine_only) { stop("API error") })

  # Define the taxa list for testing
  taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")

  # Call the function and check for error handling
  expect_error(ifcb_is_diatom(taxa_list), "Error occurred while retrieving worms records after 3 attempts: API error")
})
