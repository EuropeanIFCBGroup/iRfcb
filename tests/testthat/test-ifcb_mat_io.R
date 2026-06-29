# Direct unit tests for the internal pure-R MAT-file reader/writer in
# R/ifcb_mat_io.R. The wrapper functions (ifcb_create_class2use(),
# ifcb_correct_annotation(), ifcb_save_classification(), ...) only ever exercise
# this code with do_compression = TRUE, so these tests cover the writer/reader
# directly: both compression modes, every supported variable type, the
# "small data element" size boundary, and the byte-for-byte equivalence with
# scipy.io.savemat that the implementation claims.

# Write `vars`, read them back, and return the parsed specifications. The
# temporary file is removed once it has been read. Asserts the file is created
# so callers can focus on content.
roundtrip_mat <- function(vars, do_compression) {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(path, vars, do_compression = do_compression)
  expect_true(file.exists(path))
  read_mat_v5(path)
}

# Run the same body against both compression settings so neither path can rot
# undetected.
for_each_compression <- function(f) {
  for (compress in c(FALSE, TRUE)) f(compress)
}

test_that("double matrices round-trip (including NaN) under both compression modes", {
  m <- cbind(as.double(1:5), c(1, 1, 2, 2, 3), rep(NaN, 5))

  for_each_compression(function(compress) {
    back <- roundtrip_mat(list(classlist = mat_var_double(m)), compress)

    expect_equal(back$classlist$type, "numeric")
    expect_equal(back$classlist$class_code, 6L) # mxDOUBLE
    expect_equal(dim(back$classlist$data), c(5L, 3L))
    expect_equal(back$classlist$data, m) # expect_equal treats NaN == NaN
  })
})

test_that("uint16 column vectors round-trip and preserve their integer class", {
  v <- matrix(as.integer(c(10, 20, 300, 65535)), ncol = 1)

  for_each_compression(function(compress) {
    back <- roundtrip_mat(list(roinum = mat_var_uint16(v)), compress)

    expect_equal(back$roinum$class_code, 11L) # mxUINT16
    expect_equal(dim(back$roinum$data), c(4L, 1L))
    expect_equal(back$roinum$data, v)
  })
})

test_that("cell arrays of strings round-trip as both row and column vectors", {
  row_cell <- matrix(c("unclassified", "Dinobryon_spp", "Helicostomella_spp"), nrow = 1)
  col_cell <- matrix(c("Nodularia", "Aphanizomenon"), ncol = 1)

  for_each_compression(function(compress) {
    back <- roundtrip_mat(
      list(class2use = mat_var_cell(row_cell), winners = mat_var_cell(col_cell)),
      compress
    )

    expect_equal(back$class2use$type, "cell")
    expect_equal(dim(back$class2use$data), c(1L, 3L))
    expect_equal(as.character(back$class2use$data), as.character(row_cell))

    expect_equal(dim(back$winners$data), c(2L, 1L))
    expect_equal(as.character(back$winners$data), as.character(col_cell))
  })
})

test_that("scalar char arrays round-trip", {
  for_each_compression(function(compress) {
    back <- roundtrip_mat(list(classifierName = mat_var_char("some_model_v1")), compress)

    expect_equal(back$classifierName$type, "char")
    expect_equal(back$classifierName$data, "some_model_v1")
  })
})

test_that("empty 0x0 double arrays round-trip (the class2use_auto case)", {
  empty <- matrix(numeric(0), 0, 0)

  for_each_compression(function(compress) {
    back <- roundtrip_mat(list(class2use_auto = mat_var_double(empty)), compress)

    expect_equal(back$class2use_auto$type, "numeric")
    expect_equal(dim(back$class2use_auto$data), c(0L, 0L))
    expect_equal(length(back$class2use_auto$data), 0L)
  })
})

test_that("the 4-byte small-data-element boundary is encoded and decoded correctly", {
  # `.mat_element()` switches to the "small data element" format when a
  # subelement's data is <= 4 bytes. Exercise both sides of that boundary for
  # char (1 byte/char as UTF-8) and uint16 (2 bytes/value):
  #   - "abcd"  = 4 bytes  -> small ; "abcde" = 5 bytes -> regular + padding
  #   - 2x u16  = 4 bytes  -> small ; 3x u16  = 6 bytes -> regular + padding
  for_each_compression(function(compress) {
    back <- roundtrip_mat(
      list(
        char_small  = mat_var_char("abcd"),
        char_reg    = mat_var_char("abcde"),
        u16_small   = mat_var_uint16(matrix(as.integer(c(1, 2)), ncol = 1)),
        u16_reg     = mat_var_uint16(matrix(as.integer(c(1, 2, 3)), ncol = 1)),
        char_empty  = mat_var_char("")
      ),
      compress
    )

    expect_equal(back$char_small$data, "abcd")
    expect_equal(back$char_reg$data, "abcde")
    expect_equal(as.integer(back$u16_small$data), c(1L, 2L))
    expect_equal(as.integer(back$u16_reg$data), c(1L, 2L, 3L))
    expect_equal(back$char_empty$data, "")
  })
})

test_that("multiple variables preserve their file order on read", {
  vars <- list(
    class2use_manual = mat_var_cell(matrix(c("unclassified", "Aphanizomenon_spp"), nrow = 1)),
    class2use_auto   = mat_var_double(matrix(numeric(0), 0, 0)),
    classlist        = mat_var_double(cbind(as.double(1:3), c(1, 1, 1), rep(NaN, 3))),
    list_titles      = mat_var_cell(matrix(c("roi number", "manual", "auto"), nrow = 1))
  )

  for_each_compression(function(compress) {
    back <- roundtrip_mat(vars, compress)
    expect_equal(names(back), names(vars))
  })
})

test_that("compression changes the bytes on disk but not the decoded content", {
  vars <- list(
    class2use = mat_var_cell(matrix(rep("Helicostomella_spp", 50), nrow = 1)),
    classlist = mat_var_double(cbind(as.double(1:100), rep(1, 100), rep(NaN, 100)))
  )

  raw_path <- tempfile(fileext = ".mat")
  zip_path <- tempfile(fileext = ".mat")
  on.exit(unlink(c(raw_path, zip_path)), add = TRUE)
  write_mat_v5(raw_path, vars, do_compression = FALSE)
  write_mat_v5(zip_path, vars, do_compression = TRUE)

  # The compressed file must differ from the uncompressed one (and, for this
  # highly repetitive payload, be smaller).
  expect_false(identical(
    readBin(raw_path, "raw", file.size(raw_path)),
    readBin(zip_path, "raw", file.size(zip_path))
  ))
  expect_lt(file.size(zip_path), file.size(raw_path))

  # ... yet both decode to identical content.
  expect_equal(read_mat_v5(raw_path), read_mat_v5(zip_path))
})

test_that("write_mat_v5 aborts on an unknown variable type", {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  expect_error(
    write_mat_v5(path, list(bad = list(type = "bogus", data = 1))),
    "Unknown MAT variable type"
  )
})

test_that("a failed write leaves an existing file untouched (atomic write)", {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)

  # Write a valid file first, then attempt a write that aborts part-way through.
  write_mat_v5(path, list(classlist = mat_var_double(matrix(as.double(1:6), ncol = 2))),
               do_compression = FALSE)
  original <- readBin(path, "raw", file.size(path))

  expect_error(
    write_mat_v5(path, list(
      ok  = mat_var_double(matrix(1, 1, 1)),
      bad = list(type = "bogus", data = 1)
    )),
    "Unknown MAT variable type"
  )

  # The original file must survive byte-for-byte, and no temp file should leak.
  expect_equal(readBin(path, "raw", file.size(path)), original)
  expect_length(list.files(dirname(path), pattern = "\\.mat\\.tmp$"), 0L)
})

test_that("read_mat_v5 reports a corrupted/truncated compressed file", {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(path, list(classlist = mat_var_double(matrix(as.double(1:100), ncol = 1))),
               do_compression = TRUE)

  # Truncate the file mid-compressed-section to simulate an incomplete write.
  full <- readBin(path, "raw", file.size(path))
  writeBin(full[seq_len(length(full) - 8L)], path)

  expect_error(read_mat_v5(path), "decompress|truncated|corrupted")
})

# ---- scipy interoperability (only when scipy is installed) ------------------

test_that("uncompressed output is byte-for-byte identical to scipy.io.savemat", {
  skip_on_cran()
  skip_if_no_scipy()

  np <- reticulate::import("numpy", convert = FALSE)
  sio <- reticulate::import("scipy.io")

  classes <- c("unclassified", "Dinobryon_spp", "Helicostomella_spp")

  r_path <- tempfile(fileext = ".mat")
  py_path <- tempfile(fileext = ".mat")
  on.exit(unlink(c(r_path, py_path)), add = TRUE)

  write_mat_v5(r_path,
               list(class2use = mat_var_cell(matrix(classes, nrow = 1))),
               do_compression = FALSE)

  arr <- np$array(as.list(classes), dtype = "object")$reshape(reticulate::tuple(1L, length(classes)))
  sio$savemat(py_path, reticulate::dict(class2use = arr), do_compression = FALSE)

  r_bytes <- readBin(r_path, "raw", file.size(r_path))
  py_bytes <- readBin(py_path, "raw", file.size(py_path))

  # The first 128 bytes are a text header that embeds a creation timestamp, so
  # compare everything after it.
  expect_equal(r_bytes[129:length(r_bytes)], py_bytes[129:length(py_bytes)])
})

test_that("scipy.io.loadmat can read a mixed structure written by write_mat_v5", {
  skip_on_cran()
  skip_if_no_scipy()

  sio <- reticulate::import("scipy.io")

  classlist <- cbind(as.double(1:4), c(1, 2, 1, 2), rep(NaN, 4))
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(
    path,
    list(
      class2use = mat_var_cell(matrix(c("unclassified", "Aphanizomenon_spp"), nrow = 1)),
      classlist = mat_var_double(classlist),
      roinum    = mat_var_uint16(matrix(as.integer(c(1, 2, 3, 4)), ncol = 1))
    ),
    do_compression = TRUE
  )

  m <- sio$loadmat(path)
  expect_equal(dim(m$classlist), c(4L, 3L))
  expect_equal(as.integer(m$roinum), c(1L, 2L, 3L, 4L))
  # NaN in the third column survives the round-trip through scipy.
  expect_true(all(is.nan(m$classlist[, 3])))
})
