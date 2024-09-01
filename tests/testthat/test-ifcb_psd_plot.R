# Mock Data
sample_data <- data.frame(
  sample = c("D20230316T101514", "D20230316T101514"),
  X1 = c(NA, NA),
  X2 = c(NA, NA),
  X3 = c(NA, NA),
  X4 = c(1, 2),
  X5 = c(3, 4)
)
colnames(sample_data)[4:5] <- c("1", "2")  # Simulate particle sizes in micrometers

fit_params <- data.frame(
  sample = "D20230316T101514",
  a = 0.5,
  k = 2,
  R.2 = 0.95
)

test_that("ifcb_psd_plot generates a plot for a given sample", {
  plot <- ifcb_psd_plot(sample_name = "D20230316T101514",
                        data = sample_data,
                        fits = fit_params,
                        start_fit = 1)
  expect_s3_class(plot, "gg")  # Check if the output is a ggplot object
})

test_that("ifcb_psd_plot handles missing sample in data", {
  expect_error(
    ifcb_psd_plot(sample_name = "NonexistentSample",
                  data = sample_data,
                  fits = fit_params,
                  start_fit = 1),
    "No fit parameters found for the specified sample."
  )
})

test_that("ifcb_psd_plot handles missing fit parameters", {
  no_fit_params <- data.frame(
    sample = "D20230316T101514",
    a = NA,
    k = NA,
    R.2 = NA
  )
  plot <- ifcb_psd_plot(sample_name = "D20230316T101514",
                        data = sample_data,
                        fits = no_fit_params,
                        start_fit = 1)
  expect_s3_class(plot, "gg")  # Check if the output is a ggplot object
})

test_that("ifcb_psd_plot adds power curve if R2 is not -Inf", {
  plot <- ifcb_psd_plot(sample_name = "D20230316T101514",
                        data = sample_data,
                        fits = fit_params,
                        start_fit = 1)
  # Extract plot layers
  plot_layers <- ggplot2::ggplot_build(plot)$data
  # Check if the power curve line is present
  power_curve_present <- any(sapply(plot_layers, function(layer) any(layer$colour == "blue")))
  expect_true(power_curve_present)
})

test_that("ifcb_psd_plot annotation contains correct R2 value", {
  plot <- ifcb_psd_plot(sample_name = "D20230316T101514",
                        data = sample_data,
                        fits = fit_params,
                        start_fit = 1)
  # Extract annotation text
  annotation_text <- plot$layers[[3]]$aes_params$label
  expect_true(any(grepl("R² = 0.95", annotation_text)))  # Check annotation for correct R2
})

test_that("ifcb_psd_plot handles start_fit argument correctly", {
  plot <- ifcb_psd_plot(sample_name = "D20230316T101514",
                        data = sample_data,
                        fits = fit_params,
                        start_fit = 2)
  plot_data <- ggplot2::ggplot_build(plot)$data[[1]]
  expect_true(all(plot_data$x >= 2))  # Check that x values below start_fit are excluded
})
