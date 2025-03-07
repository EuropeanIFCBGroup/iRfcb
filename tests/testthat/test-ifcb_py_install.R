test_that("ifcb_py_install creates and uses the virtual environment", {
  # Skip if Python is not available
  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  # Mock the virtualenv_create function
  mock_virtualenv_create <- mockery::mock()
  # Mock the use_virtualenv function
  mock_use_virtualenv <- mockery::mock()

  # Stub the virtualenv_create and use_virtualenv functions
  mockery::stub(ifcb_py_install, 'virtualenv_create', mock_virtualenv_create)
  mockery::stub(ifcb_py_install, 'use_virtualenv', mock_use_virtualenv)

  # Call the function
  ifcb_py_install(envname = Sys.getenv("TEST_VENV_PATH", unset = ""))

  # Capture the arguments passed to virtualenv_create
  args_virtualenv_create <- mockery::mock_args(mock_virtualenv_create)
  # Capture the arguments passed to use_virtualenv
  args_use_virtualenv <- mockery::mock_args(mock_use_virtualenv)

  # Check if virtualenv_create was called with the correct arguments
  expect_equal(args_virtualenv_create[[1]][[1]], Sys.getenv("TEST_VENV_PATH", unset = ""))
  expect_equal(args_virtualenv_create[[1]][[2]], system.file("python", "requirements.txt", package = "iRfcb"))

  # Check if use_virtualenv was called with the correct arguments
  expect_equal(args_use_virtualenv[[1]][[1]], Sys.getenv("TEST_VENV_PATH", unset = ""))
})

test_that("ifcb_py_install handles additional arguments", {
  # Skip if Python is not available
  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  # Mock the virtualenv_create function
  mock_virtualenv_create <- mockery::mock()
  # Mock the use_virtualenv function
  mock_use_virtualenv <- mockery::mock()

  # Stub the virtualenv_create and use_virtualenv functions
  mockery::stub(ifcb_py_install, 'virtualenv_create', mock_virtualenv_create)
  mockery::stub(ifcb_py_install, 'use_virtualenv', mock_use_virtualenv)

  # Call the function with additional arguments
  ifcb_py_install(envname = file.path(tempdir(), "test-venv"), packages = c("numpy", "pandas"))

  # Capture the arguments passed to virtualenv_create
  args_virtualenv_create <- mockery::mock_args(mock_virtualenv_create)
  # Capture the arguments passed to use_virtualenv
  args_use_virtualenv <- mockery::mock_args(mock_use_virtualenv)

  # Check if virtualenv_create was called with the correct arguments
  expect_equal(args_virtualenv_create[[1]][[1]], file.path(tempdir(), "test-venv"))
  expect_equal(args_virtualenv_create[[1]][[2]], system.file("python", "requirements.txt", package = "iRfcb"))
  expect_equal(args_virtualenv_create[[1]]$packages, c("numpy", "pandas"))

  # Check if use_virtualenv was called with the correct arguments
  expect_equal(args_use_virtualenv[[1]][[1]], file.path(tempdir(), "test-venv"))
})
