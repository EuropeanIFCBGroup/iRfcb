test_that("ifcb_py_install creates and uses the virtual environment", {
  # Skip on CRAN
  skip_on_cran()

  # Skip if Python is not available
  skip_if_no_python()

  # Create a temporary venv
  venv_dir <- file.path(tempdir(), "test-venv")

  # Call the function and add plotly package to venv
  suppressWarnings(ifcb_py_install(envname = venv_dir,
                                   packages = "plotly"))

  # Check if venv is correctly installed
  expect_true(reticulate::virtualenv_exists(venv_dir))

  # List available packages
  available_packages <- reticulate::py_list_packages(python = reticulate::py_discover_config()$python)

  # Expect that required python packages are installed
  expect_true("scipy" %in% available_packages$package)
  expect_true("matplotlib" %in% available_packages$package)
  expect_true("pandas" %in% available_packages$package)
  expect_true("plotly" %in% available_packages$package)

  suppressWarnings(ifcb_py_install(envname = venv_dir))

  # Check if venv is correctly installed
  expect_true(reticulate::virtualenv_exists(venv_dir))
})

test_that("ifcb_py_install use system Python correctly", {
  # Skip on CRAN
  skip_on_cran()

  # Skip if Python is not available
  skip_if_no_python()

  # Call the function and add plotly package to venv
  suppressWarnings(ifcb_py_install(use_venv = FALSE))

  # Check that Python is available
  expect_true(reticulate::py_available())

  # List declared required packages
  required_packages <- reticulate::py_require()

  # List required packages
  expected_packages <- scan(system.file("python", "requirements.txt", package = "iRfcb"),
                            what = character(),
                            quiet = TRUE)

  # Expect that required python packages are declared
  expect_true(expected_packages[1] %in% required_packages$packages)
  expect_true(expected_packages[2] %in% required_packages$packages)
  expect_true(expected_packages[3] %in% required_packages$packages)
})
