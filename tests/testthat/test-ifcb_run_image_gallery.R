test_that("ifcb_run_image_gallery launches the Shiny app", {
  # Set up a temporary directory for the Shiny app
  app_dir <- system.file("shiny", "ifcb_image_gallery", package = "iRfcb")

  if (app_dir == "") {
    skip("Shiny app directory not found. Skipping test.")
  }

  # Initialize the Shiny app tester
  app <- shinytest2::AppDriver$new(app_dir, shiny_args = list(display.mode = "normal"))

  # Ensure the app is running by checking its title
  expect_true(app$get_text("title") == "IFCB image gallery", info = "Shiny app should have a title")
})
