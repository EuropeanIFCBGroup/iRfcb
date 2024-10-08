test_that("ifcb_run_image_gallery launches the Shiny app", {
  # Mock shiny::runApp to avoid launching the actual app
  mock_runApp <- mockery::mock()

  # Replace shiny::runApp with the mock
  mockery::stub(ifcb_run_image_gallery, "shiny::runApp", mock_runApp)

  # Call the function and ensure it runs without errors
  expect_silent(ifcb_run_image_gallery())

  # Verify that shiny::runApp was called
  mockery::expect_called(mock_runApp, 1)

  # Additional tests can still check app directory setup and other logic
  app_dir <- system.file("shiny", "ifcb_image_gallery", package = "iRfcb")
  expect_false(app_dir == "")
})
