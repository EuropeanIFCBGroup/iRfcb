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

test_that("read_mat_v5 decodes miUTF16 char data from a real MATLAB class file", {
  # MATLAB-generated .mat files store char arrays as miUTF16 (data type 17),
  # unlike scipy's miUTF8/miUINT16. This regression guards that the reader
  # decodes type 17 (so the package no longer needs R.matlab to read genuine
  # ifcb-analysis output). The fixture is a real class result file.
  temp_dir <- file.path(tempdir(), "mat_io_utf16")
  utils::unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)
  class_file <- file.path(temp_dir, "test_data", "class", "class2022_v1",
                          "D20220522T003051_IFCB134_class_v1.mat")
  skip_if(!file.exists(class_file), "class fixture not available")

  vars <- read_mat_v5(class_file)

  # Char scalar: the classifierName path embeds a non-ASCII character
  # ("Tångesund"); a correct UTF-16 decode reproduces it intact.
  expect_equal(vars$classifierName$type, "char")
  expect_true(grepl("Tångesund", vars$classifierName$data, fixed = TRUE))

  # Cell array of class label strings decodes to plain character values.
  expect_equal(vars$class2useTB$type, "cell")
  expect_true("Alexandrium_pseudogonyaulax" %in% as.vector(vars$class2useTB$data))

  unlink(temp_dir, recursive = TRUE)
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

# ---- rejecting data the reader cannot represent faithfully ------------------
#
# These all used to be decoded silently into plausible-looking numbers. That
# matters because ifcb_adjust_classes() reads a manual file and writes the
# parsed variables straight back over it, so a misdecode is committed to the
# user's annotation file rather than merely returned.

# Write one uncompressed numeric variable and return its raw bytes. In this
# layout the array-flags data word starts at byte 145: byte 145 is the array
# class, byte 146 the flag bits (logical 0x02, complex 0x08).
mat_flag_bytes <- function() {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(path, list(classlist = mat_var_double(matrix(as.double(1:3), ncol = 1))),
               do_compression = FALSE)
  readBin(path, "raw", file.size(path))
}

# Write `raw` to a temp file and read it back, expecting an error.
expect_mat_rejected <- function(raw, pattern) {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  writeBin(raw, path)
  expect_error(read_mat_v5(path), pattern)
}

test_that("read_mat_v5 rejects array classes it cannot represent", {
  raw <- mat_flag_bytes()

  # mxSTRUCT: previously decoded as a 1x1 numeric holding the field-name length.
  struct <- raw
  struct[145] <- as.raw(2L)
  expect_mat_rejected(struct, "[Uu]nsupported MATLAB array class")

  # mxOBJECT and mxSPARSE fall through the same branch.
  object <- raw
  object[145] <- as.raw(3L)
  expect_mat_rejected(object, "[Uu]nsupported MATLAB array class")

  sparse <- raw
  sparse[145] <- as.raw(5L)
  expect_mat_rejected(sparse, "[Uu]nsupported MATLAB array class")
})

test_that("read_mat_v5 names the class code even when it has no readable label", {
  raw <- mat_flag_bytes()

  # mxOPAQUE, how recent MATLAB releases store string arrays, tables,
  # categoricals and class objects. It is not in the documented class list.
  opaque <- raw
  opaque[145] <- as.raw(17L)
  expect_mat_rejected(opaque, "[Uu]nsupported MATLAB array class.*opaque")

  # A code with no label at all - corrupt, or a class MATLAB has yet to define.
  # Looking the label up used to raise "subscript out of bounds", losing the
  # diagnostic entirely, so assert the intended message rather than just any
  # error.
  for (code in c(0L, 18L, 19L)) {
    unknown <- raw
    unknown[145] <- as.raw(code)
    expect_mat_rejected(unknown, "[Uu]nsupported MATLAB array class")
    expect_mat_rejected(unknown, as.character(code))
  }
})

test_that("read_mat_v5 rejects complex and logical arrays rather than degrading them", {
  raw <- mat_flag_bytes()

  # Complex: the imaginary part would have been dropped silently.
  cplx <- raw
  cplx[146] <- as.raw(8L)
  expect_mat_rejected(cplx, "complex")

  # Logical: would have been demoted to uint8, breaking MATLAB logical indexing.
  lgl <- raw
  lgl[146] <- as.raw(2L)
  expect_mat_rejected(lgl, "logical")
})

test_that("read_mat_v5 reports a truncated uncompressed file instead of zero-filling", {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(path, list(classlist = mat_var_double(matrix(as.double(1:100), ncol = 1))),
               do_compression = FALSE)

  full <- readBin(path, "raw", file.size(path))
  truncated <- full[seq_len(length(full) - 400L)]

  # Out-of-range raw subsetting yields 00 bytes rather than an error, so this
  # used to return all 100 values with 50 silent trailing zeros.
  expect_mat_rejected(truncated, "truncated|[Mm]alformed")
})

# Write one uncompressed variable and return its raw bytes. In this layout the
# 4-byte dimension words start at byte 161 (rows) and 165 (columns), directly
# after the 8-byte dimensions tag at 153.
mat_dim_bytes <- function(spec) {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(path, list(v = spec), do_compression = FALSE)
  readBin(path, "raw", file.size(path))
}

# Overwrite the two dimension words in place.
mat_set_dims <- function(raw, nrow, ncol) {
  raw[161:164] <- writeBin(as.integer(nrow), raw(), size = 4L, endian = "little")
  raw[165:168] <- writeBin(as.integer(ncol), raw(), size = 4L, endian = "little")
  raw
}

test_that("read_mat_v5 bounds a declared element count against the bytes available", {
  cell <- mat_dim_bytes(mat_var_cell(matrix(c("a", "bb", "ccc"), nrow = 1)))

  # A 208-byte element cannot hold 2e8 cells. The reader used to allocate
  # character(2e8) - about 1.6 GB - and only then reach the bounds check inside
  # the loop, so the clean diagnostic arrived long after the memory did.
  expect_mat_rejected(mat_set_dims(cell, 1L, 200000000L), "[Mm]alformed MAT-file.*declares")

  # Larger still: prod(dims) exceeds what character() can allocate at all, which
  # used to escape as a bare "vector size specified is too large" naming neither
  # the file nor the variable.
  huge <- 2L^30L
  expect_mat_rejected(mat_set_dims(cell, huge, huge), "[Mm]alformed MAT-file.*declares")

  # A negative dimension from a flipped sign bit must not reach character().
  expect_mat_rejected(mat_set_dims(cell, 1L, -3L), "[Mm]alformed MAT-file.*declares")

  # The numeric branch is the worse case: matrix() neither errors nor warns
  # audibly there, it allocates and recycles, so the read used to succeed and
  # return 1.6 GB of fabricated values.
  num <- mat_dim_bytes(mat_var_double(matrix(as.double(1:4), nrow = 2)))
  expect_mat_rejected(mat_set_dims(num, 1L, 200000000L), "[Mm]alformed MAT-file.*declares")

  # The honest dimensions still read back, so the bound does not reject valid input.
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  writeBin(cell, path)
  expect_equal(as.vector(read_mat_v5(path)$v$data), c("a", "bb", "ccc"))
})

test_that("read_mat_v5 reads a multi-row character array as one string per row", {
  # ifcb-analysis summary files (countcells_allTBnew_user_training) store
  # filelistTB as an N x 24 char matrix, one fixed-width row per sample, with
  # the characters in column-major order. Reuse the dimension-flipping
  # helpers: "adbecf" stored as 2x3 is rows "abc" and "def".
  raw <- mat_dim_bytes(mat_var_char("adbecf"))
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  writeBin(mat_set_dims(raw, 2L, 3L), path)

  got <- read_mat_v5(path)$v
  expect_equal(got$type, "char")
  expect_equal(got$data, c("abc", "def"))

  # Dimensions that disagree with the decoded character count are refused;
  # matrix() would otherwise recycle the data into fabricated rows.
  expect_mat_rejected(mat_set_dims(raw, 2L, 4L), "carries")
})

test_that("multi-row char arrays round-trip, padding rows to a fixed width", {
  rows <- c("D20220522T003051_IFCB134", "D20220712T210855_IFCB134")

  for_each_compression(function(compress) {
    back <- roundtrip_mat(list(filelistTB = mat_var_char(rows)), compress)
    expect_equal(back$filelistTB$type, "char")
    expect_equal(back$filelistTB$data, rows)
  })

  # Unequal widths are space-padded on write, as MATLAB's char() pads them,
  # so the padding survives the round-trip rather than the short row growing
  # stray characters from its neighbour.
  back <- roundtrip_mat(list(v = mat_var_char(c("abc", "z"))), FALSE)
  expect_equal(back$v$data, c("abc", "z  "))
})

test_that("read_mat_v5 rejects an array with more than two dimensions", {
  # Byte-flipping cannot add a third dimension: the dimensions subelement has to
  # grow from 8 to 12 bytes of data, which shifts everything after it. Splice a
  # three-word dimensions element in and widen the enclosing miMATRIX to match.
  raw <- mat_dim_bytes(mat_var_double(matrix(as.double(1:8), nrow = 2)))

  i32 <- function(x) writeBin(as.integer(x), raw(), size = 4L, endian = "little")
  # miINT32 tag declaring 12 bytes, three dimension words, then 4 bytes of
  # padding back to the 8-byte boundary the format requires.
  new_dims <- c(i32(5L), i32(12L), i32(2L), i32(2L), i32(2L), raw(4))

  spliced <- c(raw[1:152], new_dims, raw[169:length(raw)])
  # The outer miMATRIX byte count lives at 133-136 and must grow by the 8 bytes
  # the new dimensions element added, or the name after it reads as truncated.
  nbytes <- readBin(spliced[133:136], "integer", size = 4L, endian = "little")
  spliced[133:136] <- i32(nbytes + 8L)

  expect_mat_rejected(spliced, "3 dimensions.*2-D arrays are supported")
})

test_that("read_mat_v5 recovers a compressed section that lacks its terminator", {
  # Some MATLAB-written classification files carry a compressed section whose
  # zlib stream stops before its 4-byte Adler-32 trailer. The deflate blocks are
  # intact, so `R.matlab` and `SciPy` both read such files, but `memDecompress()`
  # is one-shot and rejects the stream outright. Reproduce that shape by writing
  # a compressed file and dropping the trailer from its first element.
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  values <- matrix(as.double(rep(seq_len(50), 40)), ncol = 1)
  write_mat_v5(path, list(classlist = mat_var_double(values)), do_compression = TRUE)

  raw_all <- readBin(path, "raw", file.size(path))
  typ <- readBin(raw_all[129:132], "integer", size = 4L, endian = "little")
  expect_equal(typ, 15L)  # miCOMPRESSED, else the fixture is not what we think
  ln <- readBin(raw_all[133:136], "integer", size = 4L, endian = "little")

  # Drop the trailing Adler-32 and shrink the declared length to match, so the
  # element is self-consistent and only the zlib stream is unterminated.
  i32 <- function(x) writeBin(as.integer(x), raw(), size = 4L, endian = "little")
  truncated <- c(
    raw_all[1:132], i32(ln - 4L),
    raw_all[137:(136L + ln - 4L)],
    if (length(raw_all) > 136L + ln) raw_all[(137L + ln):length(raw_all)] else raw(0)
  )

  bad <- tempfile(fileext = ".mat")
  on.exit(unlink(bad), add = TRUE)
  writeBin(truncated, bad)

  # Single word: cli wraps the message at console width, and a multi-word
  # pattern fails when the wrap lands inside it (seen on r-hub's nosuggests).
  expect_warning(got <- read_mat_v5(bad), "terminator")
  expect_equal(as.vector(got$classlist$data), as.vector(values))
})

test_that("read_mat_v5 still reports a compressed section it cannot recover", {
  # The lenient path must not turn genuinely unreadable input into silence: with
  # the deflate data itself destroyed there is nothing to recover, so the abort
  # has to survive.
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)
  write_mat_v5(path, list(classlist = mat_var_double(matrix(as.double(1:200), ncol = 1))),
               do_compression = TRUE)

  raw_all <- readBin(path, "raw", file.size(path))
  # Overwrite the compressed payload with bytes that are not a deflate stream.
  ln <- readBin(raw_all[133:136], "integer", size = 4L, endian = "little")
  raw_all[137:(136L + ln)] <- as.raw(rep(0xff, ln))

  expect_mat_rejected(raw_all, "Could not decompress|[Mm]alformed|too short")
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

test_that("scipy-written multi-row char arrays decode row-wise", {
  skip_on_cran()
  skip_if_no_scipy()

  np <- reticulate::import("numpy", convert = FALSE)
  sio <- reticulate::import("scipy.io")

  # A numpy unicode array of equal-width strings is what a filelistTB written
  # from Python looks like: scipy stores it as an N x W mxCHAR matrix, the same
  # layout MATLAB uses for its char matrices.
  samples <- c("D20220522T003051_IFCB134", "D20220712T210855_IFCB134")
  py_path <- tempfile(fileext = ".mat")
  on.exit(unlink(py_path), add = TRUE)
  sio$savemat(py_path, reticulate::dict(filelistTB = np$array(samples)),
              do_compression = TRUE)

  got <- read_mat_v5(py_path)$filelistTB
  expect_equal(got$type, "char")
  expect_equal(got$data, samples)
})

test_that("read_mat_v5 decodes every numeric class it accepts", {
  skip_on_cran()
  skip_if_no_scipy()

  np <- reticulate::import("numpy", convert = FALSE)
  sio <- reticulate::import("scipy.io")

  # .MX_SUPPORTED admits mxSINGLE and mxINT8..mxUINT32 as well as mxDOUBLE. The
  # round-trip tests only ever exercised double and uint16, so accepting a class
  # was never the same as reading it correctly: int8 came back unsigned (-1 as
  # 255) and uint32 came back signed (4e9 as -294967296). Both matter because
  # MATLAB stores a double array of small values in the narrowest type that
  # fits, and because callers write what they read straight back.
  cases <- list(
    list(name = "i8",  dtype = "int8",    values = c(-128, -1, 0, 127),   class = 8L),
    list(name = "u8",  dtype = "uint8",   values = c(0, 255),             class = 9L),
    list(name = "i16", dtype = "int16",   values = c(-32768, 32767),      class = 10L),
    list(name = "u16", dtype = "uint16",  values = c(0, 65535),           class = 11L),
    # Both 32-bit endpoints are included deliberately: R cannot hold either as
    # an integer (-2^31 is the NA_integer_ bit pattern, and 2^31 overflows), so
    # a decoder routed through as.integer() returns NA for exactly these.
    list(name = "i32", dtype = "int32",   values = c(-2147483648, 2147483647), class = 12L),
    list(name = "u32", dtype = "uint32",  values = c(0, 2147483648, 4294967295), class = 13L),
    list(name = "sgl", dtype = "float32", values = c(1.5, -2.25),         class = 7L),
    list(name = "dbl", dtype = "float64", values = c(0.1, -1e10),         class = 6L)
  )

  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)

  py_vars <- lapply(cases, function(cs) {
    np$array(as.list(cs$values), dtype = cs$dtype)$reshape(
      reticulate::tuple(1L, length(cs$values)))
  })
  names(py_vars) <- vapply(cases, function(cs) cs$name, character(1))
  sio$savemat(path, do.call(reticulate::dict, py_vars), do_compression = FALSE)

  got <- read_mat_v5(path)

  for (cs in cases) {
    expect_equal(got[[cs$name]]$class_code, cs$class, info = cs$dtype)
    expect_equal(as.vector(got[[cs$name]]$data), cs$values, info = cs$dtype)
  }
})

test_that("every accepted numeric class survives a read - write round-trip", {
  skip_on_cran()
  skip_if_no_scipy()

  np <- reticulate::import("numpy", convert = FALSE)
  sio <- reticulate::import("scipy.io")

  # Write-back is the path the reader's guards exist to protect, so decoding
  # correctly is only half of it: the value has to survive being written out
  # again. uint32 above 2^31-1 is the sharp case, since it can only be held as
  # a double on the R side.
  src <- tempfile(fileext = ".mat")
  out <- tempfile(fileext = ".mat")
  on.exit(unlink(c(src, out)), add = TRUE)

  sio$savemat(src, reticulate::dict(
    i8  = np$array(list(-128L, 127L), dtype = "int8")$reshape(reticulate::tuple(1L, 2L)),
    i32 = np$array(list(-2147483648, 2147483647), dtype = "int32")$reshape(reticulate::tuple(1L, 2L)),
    u32 = np$array(list(2147483648, 4294967295), dtype = "uint32")$reshape(reticulate::tuple(1L, 2L)),
    sgl = np$array(list(1.5, -2.25), dtype = "float32")$reshape(reticulate::tuple(1L, 2L))
  ), do_compression = FALSE)

  write_mat_v5(out, read_mat_v5(src), do_compression = FALSE)

  src_bytes <- readBin(src, "raw", file.size(src))
  out_bytes <- readBin(out, "raw", file.size(out))
  # The first 128 bytes are a header carrying a creation timestamp.
  expect_equal(out_bytes[129:length(out_bytes)], src_bytes[129:length(src_bytes)])

  # And scipy still sees the original values in what we wrote. The comparison
  # is made in float64: reticulate maps a numpy int32 onto an R integer, and
  # -2147483648 is R's NA, so an int32 endpoint would fail on the way back into
  # R even when the file holds it correctly.
  m <- sio$loadmat(out)
  as_dbl <- function(x) as.vector(reticulate::py_to_r(np$asarray(x, dtype = "float64")))
  expect_equal(as_dbl(m$i8), c(-128, 127))
  expect_equal(as_dbl(m$i32), c(-2147483648, 2147483647))
  expect_equal(as_dbl(m$u32), c(2147483648, 4294967295))
  expect_equal(as_dbl(m$sgl), c(1.5, -2.25))
})

test_that("read_mat_v5 rejects dimensions that disagree with the payload", {
  # matrix() recycles a short vector to fill the declared dimensions without
  # complaint, so a corrupt dimension used to fabricate values rather than fail.
  raw <- mat_dim_bytes(mat_var_double(matrix(as.double(1:4), nrow = 2)))
  expect_mat_rejected(mat_set_dims(raw, 2L, 3L), "declares 2x3 but carries 4 values")
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

test_that("the writer refuses values that do not fit the declared integer class", {
  for_each_compression(function(compress) {
    path <- tempfile(fileext = ".mat")
    on.exit(unlink(path), add = TRUE)

    # One case per bound: above uint8, below int8, above uint16, non-integral.
    expect_error(
      write_mat_v5(path, list(v = mat_var_numeric(matrix(c(1, 300)), 9L)), compress),
      "cannot be stored as"
    )
    expect_error(
      write_mat_v5(path, list(v = mat_var_numeric(matrix(-200), 8L)), compress),
      "cannot be stored as"
    )
    expect_error(
      write_mat_v5(path, list(v = mat_var_uint16(matrix(70000))), compress),
      "cannot be stored as"
    )
    expect_error(
      write_mat_v5(path, list(v = mat_var_uint16(matrix(1.5))), compress),
      "cannot be stored as"
    )
    # NaN is representable in double but in no integer class.
    expect_error(
      write_mat_v5(path, list(v = mat_var_numeric(matrix(NaN), 9L)), compress),
      "cannot be stored as"
    )
    # An abort must not leave a partial file behind.
    expect_false(file.exists(path))
  })
})

test_that("the writer refuses variable specifications it would previously mangle", {
  path <- tempfile(fileext = ".mat")
  on.exit(unlink(path), add = TRUE)

  # NULL cell data - e.g. indexing a read file for a variable it does not
  # hold - used to serialise as an empty cell, erasing real data on write-back.
  expect_error(write_mat_v5(path, list(c2u = mat_var_cell(NULL))), "must be character")
  # NA elements used to be written as empty strings.
  expect_error(
    write_mat_v5(path, list(c2u = mat_var_cell(matrix(c("a", NA), nrow = 1)))),
    "NA"
  )
  # Unnamed elements used to be skipped silently, dropping the variable.
  expect_error(write_mat_v5(path, list(mat_var_double(matrix(1)))), "must be named")
  expect_error(
    write_mat_v5(path, setNames(list(mat_var_double(matrix(1)), mat_var_double(matrix(2))), c("a", "a"))),
    "unique"
  )
  expect_error(write_mat_v5(path, "not a list"), "named list")
  expect_false(file.exists(path))
})

test_that(".mat_widen_numeric promotes a narrow class only when the data outgrew it", {
  fits <- mat_var_numeric(matrix(c(1, 255)), 9L)
  expect_identical(.mat_widen_numeric(fits), fits)

  outgrown <- mat_var_numeric(matrix(c(1, 300)), 9L)
  expect_equal(.mat_widen_numeric(outgrown)$class_code, 6L) # mxDOUBLE

  # Non-numeric and already-double specs pass through untouched.
  dbl <- mat_var_double(matrix(1e10))
  expect_identical(.mat_widen_numeric(dbl), dbl)
  cell <- mat_var_cell(matrix("a"))
  expect_identical(.mat_widen_numeric(cell), cell)
})

# ---- CRAN-runnable decoder fixtures -----------------------------------------
# Hand-crafted MAT-file bytes, built with writeBin directly rather than the
# package's own encoders, so a symmetric encode/decode bug cannot cancel out.
# These run everywhere (no scipy, no skip): they guard the int8/int32/uint32
# endpoint decoding fixed in 0.10.0, which previously had scipy-gated tests
# only.
build_numeric_mat_file <- function(class_code, mi_type, data_raw) {
  u32 <- function(x) writeBin(as.integer(x), raw(), size = 4L, endian = "little")
  header <- raw(128)
  txt <- charToRaw("MATLAB 5.0 MAT-file, handcrafted test fixture")
  header[seq_along(txt)] <- txt
  header[125:128] <- as.raw(c(0x00, 0x01, 0x49, 0x4D)) # version 0x0100 + "IM"

  flags <- c(u32(6L), u32(8L), u32(class_code), u32(0L))  # miUINT32, 8 bytes
  n_el <- length(data_raw) / c("1" = 1, "3" = 2, "5" = 4, "6" = 4, "7" = 4)[[as.character(mi_type)]]
  dims <- c(u32(5L), u32(8L), u32(n_el), u32(1L))          # miINT32, Nx1
  name <- c(u32(1L), u32(1L), charToRaw("v"), raw(7))      # miINT8 "v" + pad
  pad <- (8L - (length(data_raw) %% 8L)) %% 8L
  data <- c(u32(mi_type), u32(length(data_raw)), data_raw, raw(pad))

  body <- c(flags, dims, name, data)
  path <- tempfile(fileext = ".mat")
  writeBin(c(header, u32(14L), u32(length(body)), body), path)
  path
}

test_that("hand-crafted int8/int16/single bytes decode to the exact values", {
  cases <- list(
    list(class = 8L, mi = 1L,
         bytes = writeBin(c(-128L, -1L, 0L, 127L), raw(), size = 1L, endian = "little"),
         values = c(-128, -1, 0, 127)),
    list(class = 10L, mi = 3L,
         bytes = writeBin(c(-32768L, 32767L), raw(), size = 2L, endian = "little"),
         values = c(-32768, 32767)),
    list(class = 7L, mi = 7L,
         bytes = writeBin(c(1.5, -2.25), raw(), size = 4L, endian = "little"),
         values = c(1.5, -2.25))
  )
  for (cs in cases) {
    path <- build_numeric_mat_file(cs$class, cs$mi, cs$bytes)
    on.exit(unlink(path), add = TRUE)
    back <- read_mat_v5(path)
    expect_equal(back$v$class_code, cs$class)
    expect_equal(as.vector(back$v$data), cs$values)
    # and the writer reproduces the same values under the same class
    write_mat_v5(path, back)
    again <- read_mat_v5(path)
    expect_equal(again$v$class_code, cs$class)
    expect_equal(as.vector(again$v$data), cs$values)
  }
})

test_that("int32/uint32 endpoints that R cannot hold as integers decode exactly", {
  # -2147483648 and values above 2^31 - 1 cannot be written via as.integer()
  # (R reserves -2^31 for NA), so their little-endian bytes are spelled out.
  int32_bytes <- as.raw(c(0x00, 0x00, 0x00, 0x80,   # -2147483648
                          0xFF, 0xFF, 0xFF, 0x7F))  #  2147483647
  path <- build_numeric_mat_file(12L, 5L, int32_bytes)
  on.exit(unlink(path), add = TRUE)
  back <- read_mat_v5(path)
  expect_equal(as.vector(back$v$data), c(-2147483648, 2147483647))
  write_mat_v5(path, back)
  expect_equal(as.vector(read_mat_v5(path)$v$data), c(-2147483648, 2147483647))

  uint32_bytes <- as.raw(c(0x00, 0x00, 0x00, 0x00,   # 0
                           0x00, 0x00, 0x00, 0x80,   # 2147483648
                           0xFF, 0xFF, 0xFF, 0xFF))  # 4294967295
  path2 <- build_numeric_mat_file(13L, 6L, uint32_bytes)
  on.exit(unlink(path2), add = TRUE)
  back2 <- read_mat_v5(path2)
  expect_equal(as.vector(back2$v$data), c(0, 2147483648, 4294967295))
  write_mat_v5(path2, back2)
  expect_equal(as.vector(read_mat_v5(path2)$v$data), c(0, 2147483648, 4294967295))
})

test_that("stray bytes after the last complete element are reported, not dropped", {
  for_each_compression(function(compress) {
    path <- tempfile(fileext = ".mat")
    on.exit(unlink(path), add = TRUE)
    write_mat_v5(path, list(a = mat_var_double(matrix(1:4, 2)),
                            b = mat_var_double(matrix(5))), compress)

    # 1-7 stray bytes are the start of an element cut off mid-tag. The loop
    # used to exit quietly, reading the file as a success with a variable
    # silently missing - and a write-back then made the loss permanent.
    stray <- readBin(path, "raw", file.size(path))
    writeBin(c(stray, as.raw(c(0x0F, 0x00, 0x00))), path)
    expect_error(read_mat_v5(path), "stray byte")
  })
})
