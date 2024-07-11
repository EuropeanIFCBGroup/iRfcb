utils::globalVariables(c("x", "y"))
#' Generate PSD Plot for a Given Sample
#'
#' This function generates a plot for a given sample from PSD data and fits.
#'
#' @param sample_name The name of the sample to plot.
#' @param data A data frame containing the PSD data, where each row represents a sample and each column represents the PSD values at different particle sizes.
#' @param fits A data frame containing the fit parameters for the power curve, where each row represents a sample and the columns include the parameters `a`, `k`, and `R2`.
#' @param start_fit The x-value threshold below which data should be excluded from the plot and fit.
#'
#' @importFrom ggplot2 ggplot aes geom_line stat_function annotate labs theme_minimal theme element_blank element_rect
#' @importFrom dplyr filter
#'
#' @return A ggplot object representing the PSD plot for the sample.
#' @export
#'
#' @examples
#' \dontrun{
#' plot <- ifcb_psd_plot(sample_name = "Sample1", data = data, fits = fits, start_fit = 10)
#' }
ifcb_psd_plot <- function(sample_name, data, fits, start_fit) {
  # Extract the sample data
  sample_data <- data %>% filter(sample == sample_name)
  x_values <- as.numeric(gsub("X(\\d+)u", "\\1", colnames(sample_data)[4:ncol(sample_data)]))
  y_values <- as.numeric(sample_data[1, 4:ncol(sample_data)])

  # Create a data frame for plotting and fitting
  plot_data <- data.frame(x = x_values, y = y_values)

  # Filter out values below start_fit
  plot_data <- plot_data %>% filter(x >= start_fit)

  # Extract the fit parameters
  fit_params <- fits %>% filter(sample == sample_name)
  a <- fit_params$a
  k <- fit_params$k
  R2 <- fit_params$R.2

  # Generate the power curve function
  power_curve <- function(x) { a * x^k }

  # Create the equation text
  equation_text <- paste0("y = ", format(a, scientific = TRUE, digits = 3), " * x^", format(k, digits = 3), "\nR^2 = ", format(R2, digits = 3))

  # Plot the data
  p <- ggplot(plot_data, aes(x = x, y = y)) +
    geom_line() +
    stat_function(fun = power_curve, color = "blue") +
    annotate("text", x = max(plot_data$x) * 0.5, y = max(plot_data$y) * 0.9, label = equation_text, hjust = 0, vjust = 1, size = 5, color = "black") +
    labs(title = paste("Sample:", sample_name),
         x = "ESD (μm)",
         y = "N'(D) [c/L⁻]") +
    theme_minimal() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA)
    )

  return(p)
}
