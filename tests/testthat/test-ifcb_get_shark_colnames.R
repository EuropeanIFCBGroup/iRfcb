# Load the testthat package
library(testthat)

# Define the test for the ifcb_get_shark_colnames function
test_that("ifcb_get_shark_colnames reads the shark column names correctly", {

  # Expected column names (Replace these with the actual column names from your shark_col.txt file)
  expected_colnames <- c("MYEAR","STATN","SAMPLING_PLATFORM","PROJ",
                         "ORDERER","SHIPC","CRUISE_NO","DATE_TIME",
                         "SDATE","TIMEZONE","STIME","LATIT","LONGI",
                         "POSYS","WADEP","MSTAT","MPROG","MNDEP","MXDEP",
                         "SLABO","ACKR_SMP","SMTYP","PDMET","SMVOL","METFP",
                         "IFCBNO","SMPNO","LATNM","SFLAG","TRPHY","APHIA_ID",
                         "COUNT","ABUND","BIOVOL","C_CONC","QFLAG","COEFF",
                         "CLASS_NAME","CLASS_PD","CLASS_PR","CLASS_PM","METOA",
                         "COUNTPROG","ALABO","ACKR_ANA","ANADATE","METDC",
                         "TRAINING_SET","TRAINING_SET_ANNOTATED_BY","CLASSIFIER_CREATED_BY",
                         "CLASSIFIER_USED","MANUAL_QC_DATE","PRE_FILTER_SIZE")

  # Call the function
  shark_colnames <- ifcb_get_shark_colnames()

  # Check that the result is a data frame
  expect_true(is.data.frame(shark_colnames))

  # Check that the column names are as expected
  expect_equal(colnames(shark_colnames), expected_colnames)

  # Optionally, you can also check the contents if needed
  # expected_data <- data.frame(Column1 = c(...), Column2 = c(...), Column3 = c(...))
  # expect_equal(shark_colnames, expected_data)
})
