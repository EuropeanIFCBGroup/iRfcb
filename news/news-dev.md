# Version dev

## iRfcb (development version)

### Minor improvements and fixes

- `.h5` classification files are read several times faster, by skipping
  a full garbage collection per file.
- A damaged or incomplete `.h5` classification file now stops with an
  error naming the file and what is wrong with it, instead of a
  misleading `class_labels_auto does not exist` or a raw HDF5 error.
- Fixed the scores of single-class `.h5` classification files being read
  transposed.
