test_that("ifcb_prepare_whoi_plankton works", {
  # Skip if Python is not available
  skip_if_no_scipy()

  # Skip if offline
  skip_if_offline()
  skip_if_resource_unavailable("https://ifcb-data.whoi.edu")

  # Extract test data and define paths
  zip_path <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_prepare_whoi_plankton")
  unzip(zip_path, exdir = temp_dir)

  # Define paths to the unzipped folders
  png_folder <- file.path(temp_dir, "test_data", "png2", "Mesodinium_rubrum")
  mesodinium_folder <- file.path(temp_dir, "test_data", "whoi_png", "2006", "Mesodinium_sp")

  dir.create(mesodinium_folder, recursive = TRUE)

  # Rename file to mock a MVCO filename
  copy <- file.copy(file.path(png_folder, "D20220522T003051_IFCB134_00003.png"),
                    file.path(mesodinium_folder, "IFCB1_2006_280_035827_00017.png"))


  # Define paths
  raw_folder <- file.path(temp_dir, "test_data", "whoi_raw")
  manual_folder <- file.path(temp_dir, "test_data", "whoi_manual")
  class2use_file <- file.path(temp_dir, "test_data", "whoi_config", "class2use.mat")
  whoi_png_folder <- file.path(temp_dir, "test_data", "whoi_png")
  whoi_blobs_folder <- file.path(temp_dir, "test_data", "whoi_blobs")
  whoi_features_folder <- file.path(temp_dir, "test_data", "whoi_features")

  # List png files
  png_files <- list.files(path = whoi_png_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)

  # Create dataframe with image information
  image_df <- data.frame(year = "2006",
                         folder = folder_name <- basename(dirname(png_files)),
                         image = png_files)

  # Store image data for later use
  write.table(image_df,
              file.path(whoi_png_folder, "2006", "images.txt"),
              na = "",
              sep = "\t",
              quote = FALSE,
              row.names = FALSE)

  # Test the function
  suppressWarnings(ifcb_prepare_whoi_plankton(2006,
                                              whoi_png_folder,
                                              raw_folder,
                                              manual_folder,
                                              class2use_file,
                                              extract_images = TRUE,
                                              download_blobs = TRUE,
                                              blobs_folder = whoi_blobs_folder,
                                              download_features = TRUE,
                                              features_folder = whoi_features_folder,
                                              sleep = 0))

  class2use <- ifcb_get_mat_variable(class2use_file)
  classlist <- ifcb_get_mat_variable(file.path(manual_folder, "D20061007T035827_IFCB1.mat"), "classlist")

  expect_equal(class2use, c("unclassified", "Mesodinium_sp"))
  expect_equal(classlist[17,2], 2)
  expect_true(file.exists(file.path(raw_folder, "2006", "D20061007", "D20061007T035827_IFCB1.adc")))
  expect_true(file.exists(file.path(raw_folder, "2006", "D20061007", "D20061007T035827_IFCB1.hdr")))
  expect_true(file.exists(file.path(manual_folder, "D20061007T035827_IFCB1.mat")))
  expect_equal(length(list.files(file.path(whoi_blobs_folder, "2006", "D20061007"), pattern = ".zip")), 1)

  # Define new paths
  raw_folder <- file.path(temp_dir, "test_data", "whoi_raw2")
  manual_folder <- file.path(temp_dir, "test_data", "whoi_manual2")
  class2use_file <- file.path(temp_dir, "test_data", "whoi_config", "class2use.mat2")
  whoi_png_folder <- file.path(temp_dir, "test_data", "whoi_png2")
  whoi_blobs_folder <- file.path(temp_dir, "test_data", "whoi_blobs2")

  dir.create(whoi_png_folder, showWarnings = FALSE)
  dir.create(file.path(whoi_png_folder, "2006"), showWarnings = FALSE)

  # Create a mock zip file
  zip::zipr(zipfile = file.path(whoi_png_folder, "2006.zip"), files = file.path(temp_dir, "test_data", "whoi_png", "2006"))

  # Store image data for later use
  write.table(image_df,
              file.path(whoi_png_folder, "2006", "images.txt"),
              na = "",
              sep = "\t",
              quote = FALSE,
              row.names = FALSE)

  # Test the function with extract_images TRUE
  ifcb_prepare_whoi_plankton(2006,
                             whoi_png_folder,
                             raw_folder,
                             manual_folder,
                             class2use_file,
                             extract_images = FALSE,
                             download_blobs = FALSE,
                             blobs_folder = whoi_blobs_folder,
                             quiet = TRUE,
                             sleep = 0)

  class2use <- ifcb_get_mat_variable(class2use_file)
  classlist <- ifcb_get_mat_variable(file.path(manual_folder, "D20061007T035827_IFCB1.mat"), "classlist")

  expect_equal(class2use, c("unclassified", "Mesodinium_sp"))
  expect_equal(classlist[17,2], 2)
  expect_true(file.exists(file.path(raw_folder, "2006", "D20061007", "D20061007T035827_IFCB1.adc")))
  expect_true(file.exists(file.path(raw_folder, "2006", "D20061007", "D20061007T035827_IFCB1.hdr")))
  expect_true(file.exists(file.path(manual_folder, "D20061007T035827_IFCB1.mat")))

  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_prepare_whoi_plankton throws errors", {
  # Skip if Python is not available
  skip_if_no_scipy()

  # Check error
  expect_error(ifcb_prepare_whoi_plankton(2,
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_file"),
               "No valid years specified.")

  # Check error
  expect_error(ifcb_prepare_whoi_plankton(2,
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_file",
                                          download_features = TRUE),
               "`features_folder` must be specified when `download_features = TRUE`")

  # Check error
  expect_error(ifcb_prepare_whoi_plankton(2,
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_file",
                                          download_blobs = TRUE),
               "`blobs_folder` must be specified when `download_blobs = TRUE`")

})
