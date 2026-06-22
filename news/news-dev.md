# Version dev

## iRfcb (development version)

### Minor improvements and fixes

- [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md)
  gains a `feature_tag` argument to control the feature file naming. The
  default (`"features"`) writes `<bin>_features_v4.csv` as before;
  `"fea"` writes `<bin>_fea_v4.csv`, the name served by the IFCB
  Dashboard (pyifcb’s `FeaturesDirectory`).
