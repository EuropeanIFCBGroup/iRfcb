test_that("ifcb_annotate_batch creates and updates mat files as expected", {

  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual_folder")
  out_folder <- file.path(tempdir(), "out")
  new_folder <- file.path(tempdir(), "new")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = c("test_data/manual/D20220522T003051_IFCB134.mat",
                  "test_data/config/class2use.mat",
                  "test_data/data/D20220522T003051_IFCB134.adc"),
        exdir = manual_folder,
        junkpaths = TRUE)

  adc_folder <- file.path(manual_folder, "2022", "D20220522")

  if (!dir.exists(adc_folder)) {
    dir.create(adc_folder, recursive = TRUE)
  }

  file.copy(file.path(manual_folder, "D20220522T003051_IFCB134.adc"),
            file.path(adc_folder, "D20220522T003051_IFCB134.adc"))

  # Create a new file
  ifcb_annotate_batch(png_images = c("D20220522T003051_IFCB134_00002.png",
                                     "D20220522T003051_IFCB134_00003.png"),
                      class = "Nodularia_spumigena",
                      manual_folder = new_folder,
                      adc_folder = manual_folder,
                      class2use_file = file.path(manual_folder, "class2use.mat"))

  classlist <- ifcb_get_mat_variable(file.path(new_folder, "D20220522T003051_IFCB134.mat"),
                                     "classlist")

  expect_equal(nrow(classlist), 3)

  # Update existing file
  ifcb_annotate_batch(png_images = c("D20220522T003051_IFCB134_00002.png",
                                     "D20220522T003051_IFCB134_00003.png"),
                      class = "Nodularia_spumigena",
                      manual_folder = manual_folder,
                      adc_folder = manual_folder,
                      class2use_file = file.path(manual_folder, "class2use.mat"))

  classlist_new <- ifcb_get_mat_variable(file.path(manual_folder, "D20220522T003051_IFCB134.mat"),
                                         "classlist")


  expect_equal(classlist_new[,2], c(NaN, 10, 10))

  # Clean up
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
  unlink(new_folder, recursive = TRUE)
  unlink(adc_folder, recursive = TRUE)
})

test_that("ifcb_annotate_batch handles errors gracefully", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual_folder")
  out_folder <- file.path(tempdir(), "out")
  new_folder <- file.path(tempdir(), "new")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = c("test_data/manual/D20220522T003051_IFCB134.mat",
                  "test_data/config/class2use.mat",
                  "test_data/data/D20220522T003051_IFCB134.adc"),
        exdir = manual_folder,
        junkpaths = TRUE)

  adc_folder <- file.path(manual_folder, "2022", "D20220522")

  if (!dir.exists(adc_folder)) {
    dir.create(adc_folder, recursive = TRUE)
  }

  file.copy(file.path(manual_folder, "D20220522T003051_IFCB134.adc"),
            file.path(adc_folder, "D20220522T003051_IFCB134.adc"))

  # Expect error for non exisiting class2use file
  expect_error(ifcb_annotate_batch(png_images = c("D20220522T003051_IFCB134_00002.png",
                                                  "D20220522T003051_IFCB134_00003.png"),
                                   class = "Nodularia_spumigena",
                                   manual_folder = new_folder,
                                   adc_folder = manual_folder,
                                   class2use_file = file.path(manual_folder, "non_exisiting_file")),
               "The specified class2use_file file does not exist")

  # Expect error for non exisiting class
  expect_error(ifcb_annotate_batch(png_images = c("D20220522T003051_IFCB134_00002.png",
                                                  "D20220522T003051_IFCB134_00003.png"),
                                   class = "non_exisiting_class",
                                   manual_folder = new_folder,
                                   adc_folder = manual_folder,
                                   class2use_file = file.path(manual_folder, "class2use.mat")),
               "Class non_exisiting_class not found in class2use")

  unlink(adc_folder, recursive = TRUE)

  # Expect error for non exisiting class
  expect_warning(ifcb_annotate_batch(png_images = c("D20220522T003051_IFCB134_00002.png",
                                                    "D20220522T003051_IFCB134_00003.png"),
                                     class = "Nodularia_spumigena",
                                     manual_folder = new_folder,
                                     adc_folder = manual_folder,
                                     class2use_file = file.path(manual_folder, "class2use.mat")),
                 "ADC file not found for sample")

  # Clean up
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
  unlink(new_folder, recursive = TRUE)
})
