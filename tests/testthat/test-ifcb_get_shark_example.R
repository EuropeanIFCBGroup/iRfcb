test_that("ifcb_get_shark_example reads the shark column names correctly", {

  # Expected column names (Replace these with the actual column names from your shark_col.txt file)
  expected_colnames <- c("MYEAR","STATN","SAMPLING_PLATFORM","PROJ",
                         "ORDERER","SHIPC","CRUISE_NO","DATE_TIME",
                         "SDATE","STIME","TIMEZONE","LATIT","LONGI",
                         "POSYS","WADEP","MPROG","MNDEP","MXDEP",
                         "SLABO","ACKR_SMP","SMTYP","PDMET","SMVOL","METFP",
                         "IFCBNO","SMPNO","LATNM","SFLAG","LATNM_SFLAG","TRPHY","APHIA_ID",
                         "IMAGE_VERIFICATION", "VERIFIED_BY", "COUNT","ABUND","BIOVOL","C_CONC","QFLAG","COEFF",
                         "CLASS_NAME","CLASS_F1","UNCLASSIFIED_COUNTS","UNCLASSIFIED_ABUNDANCE",
                         "UNCLASSIFIED_VOLUME","METOA","ASSOCIATED_MEDIA",
                         "CLASSPROG","ALABO","ACKR_ANA","ANADATE","METDC",
                         "TRAINING_SET","CLASSIFIER_USED","MANUAL_QC_DATE","PRE_FILTER_SIZE", "PH_FB",
                         "CHL_FB","CDOM_FB","PHYC_FB","PHER_FB","WATERFLOW_FB","TURB_FB","PCO2_FB",
                         "TEMP_FB","PSAL_FB","OSAT_FB","DOXY_FB")

  # Call the function
  shark_colnames <- ifcb_get_shark_example()

  # Check that the result is a data frame
  expect_true(is.data.frame(shark_colnames))

  # Check that the column names are as expected
  expect_equal(colnames(shark_colnames), expected_colnames)

  # Check that the dataframe contains 5 rows
  expect_equal(nrow(shark_colnames), 5)
})
