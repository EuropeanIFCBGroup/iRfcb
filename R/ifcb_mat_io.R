# Internal pure-R reader and writer for MATLAB Level 5 MAT-files.
#
# This re-implements the subset of `scipy.io` behaviour required by iRfcb, so
# that `.mat` files can be created and edited without calling Python. The
# writer output is byte-for-byte identical to `scipy.io.savemat` (modulo the
# 128-byte text header, which embeds a creation timestamp that necessarily
# differs between runs), including the optional per-variable zlib compression.
# The reader returns variable specifications that round-trip exactly through
# the writer, reproducing the byte layout of the equivalent
# `loadmat -> savemat` Python round-trip used by the "read - modify - write"
# functions (ifcb_correct_annotation, ifcb_replace_mat_values,
# ifcb_adjust_classes).
#
# Supported element types (see the `mat_var_*` constructors):
#   - numeric matrices of any MATLAB class (double, single, int/uint of any
#     width), including empty 0x0 arrays and NaN
#   - cell arrays of character strings (any dimensions)
#   - character arrays: a single string (1xN), or a multi-row char matrix
#     (e.g. filelistTB in ifcb-analysis summary files), held as one string
#     per row
#
# The serialisation follows the MAT-file v5 format documented in the MATLAB
# "MAT-File Format" reference, matching the exact choices scipy makes:
#   - character data is stored as miUTF8
#   - subelements whose data is <= 4 bytes use the "small data element" format
#   - each top-level variable is compressed independently with zlib

# ---- MAT-file datatype codes ----
.MI_INT8   <- 1L
.MI_UINT8  <- 2L
.MI_INT16  <- 3L
.MI_UINT16 <- 4L
.MI_INT32  <- 5L
.MI_UINT32 <- 6L
.MI_SINGLE <- 7L
.MI_DOUBLE <- 9L
.MI_MATRIX <- 14L
.MI_COMPRESSED <- 15L
.MI_UTF8   <- 16L

# ---- MAT-file array class codes ----
# Only the classes the reader and writer act on get a constant. The codes it
# merely refuses are named in .MX_CLASS_NAMES below, where the label alongside
# each key already says which class it is.
.MX_CELL   <- 1L
.MX_CHAR   <- 4L
.MX_DOUBLE <- 6L
.MX_SINGLE <- 7L
.MX_UINT16 <- 11L
.MX_INT32  <- 12L
.MX_UINT32 <- 13L

# Array classes the reader can decode. Anything else (struct, object, sparse,
# function handle) must be rejected rather than fall through to the numeric
# branch, which would read an unrelated subelement as data and return a
# plausible-looking number. That matters because callers such as
# ifcb_adjust_classes() write the parsed variables straight back over the
# original file.
.MX_SUPPORTED <- c(
  .MX_CELL, .MX_CHAR, .MX_DOUBLE,
  7L,  # mxSINGLE
  8L,  # mxINT8
  9L,  # mxUINT8
  10L, # mxINT16
  .MX_UINT16,
  12L, # mxINT32
  13L  # mxUINT32
)

# Human-readable names for the classes we refuse, used in the error message.
# A list rather than a character vector, so that `[[` on an unlisted class code
# (undocumented or corrupt) yields NULL instead of a "subscript out of bounds"
# error and the message below can name the code on its own. Single-bracket
# indexing would not do: it returns a named NA, which is not NULL and renders
# as "(NA)".
.MX_CLASS_NAMES <- list(
  "2" = "struct", "3" = "object", "5" = "sparse",
  "14" = "int64", "15" = "uint64", "16" = "function handle",
  # mxOPAQUE, how MATLAB stores string arrays, tables, categoricals and class
  # objects. Not in the documented class list, but common in files saved by
  # recent MATLAB releases.
  "17" = "opaque (string, table, categorical or object)"
)

# Value ranges of the integer array classes, used by the writer to refuse a
# value that cannot be stored in the class it is being written as. Without the
# check the encoders wrap silently: 300 written into a uint8 classlist (the
# storage MATLAB picks when every value is small) comes back as 44.
.MX_INT_RANGES <- list(
  "8"  = list(label = "int8",   min = -128,        max = 127),
  "9"  = list(label = "uint8",  min = 0,           max = 255),
  "10" = list(label = "int16",  min = -32768,      max = 32767),
  "11" = list(label = "uint16", min = 0,           max = 65535),
  "12" = list(label = "int32",  min = -2147483648, max = 2147483647),
  "13" = list(label = "uint32", min = 0,           max = 4294967295)
)

# Array-flags bits (second byte of the flags word).
.MX_FLAG_LOGICAL <- 0x02L
.MX_FLAG_COMPLEX <- 0x08L

# =============================================================================
# Writer
# =============================================================================

# ---- Low-level raw encoders ----
.raw_u16 <- function(x) writeBin(as.integer(x), raw(), size = 2L, endian = "little")
.raw_u32 <- function(x) writeBin(as.integer(x), raw(), size = 4L, endian = "little")
.raw_dbl <- function(x) writeBin(as.double(x), raw(), size = 8L, endian = "little")

# Encode an unsigned 16-bit integer vector little-endian (handles 0-65535)
.raw_u16vec <- function(x) {
  x <- as.integer(round(x))
  lo <- bitwAnd(x, 255L)
  hi <- bitwAnd(bitwShiftR(x, 8L), 255L)
  as.raw(as.vector(rbind(lo, hi)))
}

# Encode a signed 32-bit integer vector little-endian
.raw_i32vec <- function(x) {
  writeBin(as.integer(x), raw(), size = 4L, endian = "little")
}

# Encode a 32-bit integer vector little-endian from doubles, covering the whole
# int32 and uint32 ranges. R's integer type cannot express either endpoint -
# `as.integer(-2147483648)` and `as.integer(2147483648)` are both NA, since R
# reserves -2^31 for NA itself - so going through as.integer() silently turns
# the extreme value of each type into a missing one. Splitting the double into
# bytes avoids the conversion entirely.
.raw_32vec_from_double <- function(x) {
  x <- as.double(x) %% 4294967296  # fold into [0, 2^32), so int32 wraps to two's complement
  bytes <- rbind(
    x %% 256,
    (x %/% 256) %% 256,
    (x %/% 65536) %% 256,
    (x %/% 16777216) %% 256
  )
  as.raw(as.vector(bytes))
}

# Decode a little-endian 32-bit integer vector as doubles in [0, 2^32). The
# counterpart of .raw_32vec_from_double(): readBin() cannot return either
# endpoint as an R integer, so the bytes are combined directly.
.u32_from_raw <- function(data) {
  # Drop any trailing partial word, as readBin(n = length(data) %/% 4L) did;
  # matrix() would otherwise recycle it into a fabricated value.
  n <- length(data) %/% 4L
  if (n == 0L) return(numeric(0))
  b <- matrix(as.integer(data[seq_len(n * 4L)]), nrow = 4L)
  b[1, ] + b[2, ] * 256 + b[3, ] * 65536 + b[4, ] * 16777216
}

# Write one data element (tag + data). Uses the "small data element" format
# when the data is 4 bytes or fewer, exactly as scipy does. For 0-byte data
# the small and regular formats are byte-identical.
.mat_element <- function(datatype, data_raw) {
  n <- length(data_raw)
  if (n <= 4L) {
    c(.raw_u16(datatype), .raw_u16(n), data_raw, raw(4L - n))
  } else {
    pad <- (8L - (n %% 8L)) %% 8L
    c(.raw_u32(datatype), .raw_u32(n), data_raw, raw(pad))
  }
}

# Array flags subelement (miUINT32, 8 bytes of data)
.mat_array_flags <- function(class_code) {
  word1 <- as.integer(class_code) # complex/global/logical flag byte is 0
  .mat_element(.MI_UINT32, c(.raw_u32(word1), .raw_u32(0L)))
}

# Dimensions subelement (miINT32)
.mat_dims <- function(dims) {
  .mat_element(.MI_INT32, .raw_i32vec(as.integer(dims)))
}

# Array name subelement (miINT8)
.mat_name <- function(name) {
  .mat_element(.MI_INT8, charToRaw(name))
}

# Build a single MATLAB char array (class mxCHAR), stored as miUTF8.
# Used both for top-level char variables and for the elements of a cell array
# (where `name` is ""). A vector of several strings becomes a multi-row char
# matrix, one string per row: rows are space-padded to a common width (as
# MATLAB's char() pads them) and the characters serialised in column-major
# order, matching how MATLAB and scipy lay out 2-D char arrays.
.mat_char_matrix <- function(name, s) {
  if (!is.character(s) || length(s) == 0L || anyNA(s)) {
    cli::cli_abort(
      "Char data for {.val {name}} must be one or more non-{.val {NA}} strings, not {.cls {class(s)}} of length {length(s)}."
    )
  }
  if (length(s) > 1L) {
    s <- enc2utf8(s)
    widths <- nchar(s, type = "chars")
    padded <- paste0(s, strrep(" ", max(widths) - widths))
    codes <- do.call(rbind, lapply(padded, utf8ToInt))
    bytes <- charToRaw(intToUtf8(as.vector(codes)))
    dims <- c(length(s), max(widths))
  } else {
    bytes <- charToRaw(enc2utf8(s))
    nch <- nchar(s, type = "chars")
    dims <- if (nch == 0L) c(0L, 0L) else c(1L, nch)
  }
  body <- c(
    .mat_array_flags(.MX_CHAR),
    .mat_dims(dims),
    .mat_name(name),
    .mat_element(.MI_UTF8, bytes)
  )
  .mat_element(.MI_MATRIX, body)
}

# Map a MATLAB numeric array class to its (data type, value encoder), matching
# the natural storage type scipy.io.savemat uses for each numpy dtype.
.mat_numeric_codec <- function(class_code) {
  switch(as.character(class_code),
    "6"  = list(mi = .MI_DOUBLE, enc = function(x) .raw_dbl(x)),                                  # mxDOUBLE
    "7"  = list(mi = .MI_SINGLE, enc = function(x) writeBin(as.double(x), raw(), size = 4L, endian = "little")), # mxSINGLE
    "8"  = list(mi = .MI_INT8,   enc = function(x) writeBin(as.integer(x), raw(), size = 1L, endian = "little")), # mxINT8
    "9"  = list(mi = .MI_UINT8,  enc = function(x) as.raw(bitwAnd(as.integer(round(x)), 255L))),  # mxUINT8
    "10" = list(mi = .MI_INT16,  enc = function(x) writeBin(as.integer(x), raw(), size = 2L, endian = "little")), # mxINT16
    "11" = list(mi = .MI_UINT16, enc = function(x) .raw_u16vec(x)),                               # mxUINT16
    # mxINT32 and mxUINT32 both arrive as doubles (see .decode_numeric) and
    # between them span values R cannot hold as integers at either end.
    "12" = list(mi = .MI_INT32,  enc = function(x) .raw_32vec_from_double(x)),                   # mxINT32
    "13" = list(mi = .MI_UINT32, enc = function(x) .raw_32vec_from_double(x)),                   # mxUINT32
    cli::cli_abort("Unsupported numeric MAT array class: {.val {class_code}}")
  )
}

# Build a top-level numeric matrix variable of the given MATLAB array class.
.mat_numeric_matrix <- function(name, mat, class_code) {
  if (!is.numeric(mat)) {
    cli::cli_abort(
      "Variable {.val {name}} must be numeric to be written as a numeric MAT array, not {.cls {class(mat)}}."
    )
  }
  if (is.null(dim(mat))) mat <- matrix(mat, ncol = 1L)
  dims <- dim(mat)
  rng <- .MX_INT_RANGES[[as.character(class_code)]]
  if (!is.null(rng)) {
    vals <- as.vector(mat)
    bad <- !is.finite(vals) | vals < rng$min | vals > rng$max | vals != round(vals)
    if (any(bad)) {
      first <- vals[which(bad)[1L]]
      cli::cli_abort(c(
        "Variable {.val {name}} holds {sum(bad)} value{?s} that cannot be stored as {.field {rng$label}}.",
        "x" = "First offending value: {.val {first}} ({rng$label} holds whole numbers from {rng$min} to {rng$max}).",
        "i" = "Write the variable as double instead, or keep its values inside the {.field {rng$label}} range."
      ))
    }
  }
  codec <- .mat_numeric_codec(class_code)
  body <- c(
    .mat_array_flags(class_code),
    .mat_dims(dims),
    .mat_name(name),
    # column-major order, matching MATLAB / numpy Fortran order
    .mat_element(codec$mi, codec$enc(as.vector(mat)))
  )
  .mat_element(.MI_MATRIX, body)
}

# Build a top-level cell array of strings (class mxCELL).
# `char_mat` is a character matrix (or vector); elements are taken in
# column-major order and each becomes an mxCHAR element.
.mat_cell_array <- function(name, char_mat) {
  # NULL slips in easily - e.g. indexing a read file for a variable it does not
  # hold - and would otherwise serialise as a plausible-looking empty cell,
  # erasing whatever the file held before.
  if (!is.character(char_mat)) {
    cli::cli_abort(
      "Cell array {.val {name}} must be character data, not {.cls {class(char_mat)}}."
    )
  }
  if (anyNA(char_mat)) {
    cli::cli_abort(
      "Cell array {.val {name}} holds {sum(is.na(char_mat))} {.val {NA}} value{?s}; every element must be a string."
    )
  }
  dims <- dim(char_mat)
  if (is.null(dims)) dims <- c(length(char_mat), 1L)
  elems <- as.vector(char_mat)
  children <- if (length(elems) == 0L) {
    raw(0)
  } else {
    do.call(c, lapply(elems, function(s) .mat_char_matrix("", s)))
  }
  body <- c(
    .mat_array_flags(.MX_CELL),
    .mat_dims(dims),
    .mat_name(name),
    children
  )
  .mat_element(.MI_MATRIX, body)
}

# Compress one already-serialised top-level miMATRIX element with zlib,
# wrapping it in a miCOMPRESSED element. R's memCompress(type = "gzip")
# emits a zlib (RFC 1950) stream, identical to Python's zlib.compress.
# Compressed elements are not padded to an 8-byte boundary (matching scipy).
.mat_compress_element <- function(element_raw) {
  z <- memCompress(element_raw, type = "gzip")
  c(.raw_u32(.MI_COMPRESSED), .raw_u32(length(z)), z)
}

# Build the 128-byte MAT-file header, mirroring scipy's text and layout.
.mat_header <- function() {
  ts <- .mat_c_time()
  text <- sprintf("MATLAB 5.0 MAT-file Platform: %s, Created on: %s", "posix", ts)
  raw_text <- charToRaw(text)
  if (length(raw_text) > 116L) raw_text <- raw_text[seq_len(116L)]
  header <- raw(128)
  header[seq_along(raw_text)] <- raw_text
  # bytes 117-124 (subsystem offset) remain 0
  header[125L] <- as.raw(0x00)
  header[126L] <- as.raw(0x01) # version 0x0100
  header[127L] <- charToRaw("I")
  header[128L] <- charToRaw("M") # endian indicator
  header
}

# C-locale timestamp matching Python's time.asctime(), e.g.
# "Sat Jun 20 00:14:34 2026" (day-of-month space-padded).
.mat_c_time <- function(now = Sys.time()) {
  wd <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  mo <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  lt <- as.POSIXlt(now)
  sprintf("%s %s %2d %02d:%02d:%02d %d",
          wd[lt$wday + 1L], mo[lt$mon + 1L], as.integer(lt$mday),
          as.integer(lt$hour), as.integer(lt$min), as.integer(lt$sec),
          lt$year + 1900L)
}

# ---- Variable specification constructors ----
# Each returns a list describing one MATLAB variable; consumed by write_mat_v5()
# and produced by read_mat_v5(). Numeric variables carry the MATLAB array class
# code so the exact storage type (double, uint8, uint16, int32, ...) is
# preserved on a read - write round-trip.
mat_var_numeric <- function(data, class_code) {
  list(type = "numeric", data = data, class_code = as.integer(class_code))
}
mat_var_double <- function(data) mat_var_numeric(data, .MX_DOUBLE)
mat_var_uint16 <- function(data) mat_var_numeric(data, .MX_UINT16)
mat_var_cell   <- function(data) list(type = "cell", data = data)
mat_var_char   <- function(data) list(type = "char", data = data)

# Widen a numeric variable read from a file to double when its data no longer
# fits the storage class it arrived with. Callers that modify data in place
# (ifcb_correct_annotation, ifcb_replace_mat_values) run their edits through
# this so that assigning, say, class id 300 into a classlist MATLAB stored as
# uint8 writes a double array - which MATLAB reads fine - instead of tripping
# the writer's range refusal.
.mat_widen_numeric <- function(spec) {
  if (!identical(spec$type, "numeric")) return(spec)
  rng <- .MX_INT_RANGES[[as.character(spec$class_code)]]
  if (is.null(rng)) return(spec)
  vals <- as.vector(spec$data)
  fits <- is.finite(vals) & vals >= rng$min & vals <= rng$max & vals == round(vals)
  if (!all(fits)) spec$class_code <- .MX_DOUBLE
  spec
}

#' Write a MATLAB v5 MAT-file from R (internal)
#'
#' @param filename Output path.
#' @param vars A named list of variable specifications created with
#'   `mat_var_double()`, `mat_var_uint16()`, `mat_var_cell()` or
#'   `mat_var_char()`. List names become MATLAB variable names.
#' @param do_compression Logical; compress each variable with zlib.
#' @noRd
write_mat_v5 <- function(filename, vars, do_compression = TRUE) {
  # An unnamed element would silently be skipped by the `names(vars)` loop
  # below, producing a valid-looking file with a variable missing.
  if (!is.list(vars)) {
    cli::cli_abort("{.arg vars} must be a named list of variable specifications, not {.cls {class(vars)}}.")
  }
  nms <- names(vars)
  if (length(vars) > 0L && (is.null(nms) || any(!nzchar(nms)) || anyNA(nms))) {
    cli::cli_abort("Every element of {.arg vars} must be named; the names become the MATLAB variable names.")
  }
  if (anyDuplicated(nms)) {
    cli::cli_abort("Variable names in {.arg vars} must be unique; duplicated: {.val {unique(nms[duplicated(nms)])}}.")
  }
  # Serialise to a temporary file in the same directory and rename it into place
  # only once the whole file has been written. This keeps the write atomic: if
  # serialisation aborts part-way (e.g. an unsupported variable type), an
  # existing `.mat` at `filename` is left untouched rather than truncated.
  tmp <- tempfile(tmpdir = dirname(filename), fileext = ".mat.tmp")
  con <- file(tmp, "wb")
  con_open <- TRUE
  # Clean up the temp file (and connection) unless we successfully renamed it
  # away below. `isOpen()` errors once a connection has been closed/destroyed,
  # so track the open state ourselves.
  on.exit({
    if (con_open) try(close(con), silent = TRUE)
    if (file.exists(tmp)) unlink(tmp)
  })

  writeBin(.mat_header(), con)

  for (nm in names(vars)) {
    spec <- vars[[nm]]
    element <- switch(spec$type,
      numeric = .mat_numeric_matrix(nm, spec$data, spec$class_code),
      cell    = .mat_cell_array(nm, spec$data),
      char    = .mat_char_matrix(nm, spec$data),
      cli::cli_abort("Unknown MAT variable type: {.val {spec$type}}")
    )
    if (do_compression) element <- .mat_compress_element(element)
    writeBin(element, con)
  }

  close(con)
  con_open <- FALSE
  if (!file.rename(tmp, filename)) {
    # rename can fail across devices or if the destination is locked; fall back
    # to copy + remove so the result still lands at `filename`.
    if (!file.copy(tmp, filename, overwrite = TRUE)) {
      cli::cli_abort("Failed to write MAT file: {.file {filename}}")
    }
  }

  invisible(filename)
}

# =============================================================================
# Reader
# =============================================================================

# Read a single data element starting at 1-based offset `off` within `raw`.
# Handles both the regular and "small data element" tag formats.
# Returns list(type, data, next_off).
.read_element <- function(raw, off) {
  # Out-of-range raw subsetting yields 00 bytes rather than an error, so every
  # read has to be bounds-checked explicitly; otherwise a truncated file is
  # silently zero-filled and those zeros are written back as real data.
  .need <- function(last) {
    if (last > length(raw)) {
      cli::cli_abort(c(
        "Malformed or truncated MAT-file element.",
        "i" = "Needed {last} byte{?s} but the element data ends at {length(raw)}."
      ))
    }
  }

  .need(off + 3L)
  tag4 <- readBin(raw[off:(off + 3L)], "integer", size = 4L, endian = "little")
  nbytes_small <- bitwShiftR(tag4, 16L)
  if (nbytes_small != 0L) {
    # small data element: low 16 bits = type, high 16 bits = byte count
    type <- bitwAnd(tag4, 0xFFFFL)
    nb <- nbytes_small
    .need(off + 3L + nb)
    data <- if (nb > 0L) raw[(off + 4L):(off + 3L + nb)] else raw(0)
    list(type = type, data = data, next_off = off + 8L)
  } else {
    type <- tag4
    .need(off + 7L)
    nb <- readBin(raw[(off + 4L):(off + 7L)], "integer", size = 4L, endian = "little")
    if (is.na(nb) || nb < 0L) {
      cli::cli_abort("Malformed MAT-file element: invalid byte count {.val {nb}}.")
    }
    .need(off + 7L + nb)
    data <- if (nb > 0L) raw[(off + 8L):(off + 7L + nb)] else raw(0)
    pad <- (8L - (nb %% 8L)) %% 8L
    list(type = type, data = data, next_off = off + 8L + nb + pad)
  }
}

# Map a MAT data element storage type to the array class scipy would assign
# after a loadmat -> savemat round-trip (the numpy dtype follows the data type).
.mat_data_type_to_class <- function(mi_type) {
  switch(as.character(mi_type),
    "9" = .MX_DOUBLE, # miDOUBLE -> mxDOUBLE
    "7" = 7L,         # miSINGLE -> mxSINGLE
    "1" = 8L,         # miINT8   -> mxINT8
    "2" = 9L,         # miUINT8  -> mxUINT8
    "3" = 10L,        # miINT16  -> mxINT16
    "4" = 11L,        # miUINT16 -> mxUINT16
    "5" = 12L,        # miINT32  -> mxINT32
    "6" = 13L,        # miUINT32 -> mxUINT32
    .MX_DOUBLE
  )
}

# Decode the data bytes of a numeric subelement to an R numeric vector.
.decode_numeric <- function(type, data) {
  switch(as.character(type),
    "9" = readBin(data, "double", n = length(data) %/% 8L, size = 8L, endian = "little"),       # miDOUBLE
    "7" = readBin(data, "double", n = length(data) %/% 4L, size = 4L, endian = "little"),       # miSINGLE
    # miINT32. Decoded from the raw bytes rather than by readBin(), because R
    # cannot hold -2147483648 as an integer (that bit pattern is NA_integer_),
    # so the most negative int32 would read back as missing.
    "5" = {
      v <- .u32_from_raw(data)
      v[v >= 2147483648] <- v[v >= 2147483648] - 4294967296
      v
    },
    # miUINT32. R has no unsigned 32-bit type, and values above 2147483647 do
    # not fit an R integer at all, so these stay doubles.
    "6" = .u32_from_raw(data),
    "4" = readBin(data, "integer", n = length(data) %/% 2L, size = 2L, endian = "little", signed = FALSE), # miUINT16
    "3" = readBin(data, "integer", n = length(data) %/% 2L, size = 2L, endian = "little"),      # miINT16
    "2" = as.integer(data),                                                                     # miUINT8
    # miINT8. as.integer() on raw is unsigned, which read -128 back as 128 and
    # -1 as 255. MATLAB stores a double array of small values compactly, so this
    # is how an ordinary negative value can arrive.
    "1" = readBin(data, "integer", n = length(data), size = 1L, signed = TRUE),                 # miINT8
    cli::cli_abort("Unsupported numeric MAT data type: {.val {type}}")
  )
}

# Decode the data bytes of a character subelement to an R string.
.decode_char <- function(type, data) {
  if (length(data) == 0L) return("")
  if (type == 16L || type == 1L || type == 2L) {
    # miUTF8 / miINT8 / miUINT8
    out <- rawToChar(data)
    Encoding(out) <- "UTF-8"
    out
  } else if (type == 17L || type == 4L || type == 3L) {
    # miUTF16 / miUINT16 / miINT16. MATLAB-generated char arrays are stored as
    # miUTF16; scipy round-trips them as miUINT16. Both are decoded as
    # little-endian 16-bit code units (the BMP class/label strings iRfcb deals
    # with are identical under UTF-16 and bare UCS-2).
    codes <- readBin(data, "integer", n = length(data) %/% 2L, size = 2L,
                     endian = "little", signed = FALSE)
    intToUtf8(codes)
  } else if (type == 18L) {
    # miUTF32
    codes <- readBin(data, "integer", n = length(data) %/% 4L, size = 4L,
                     endian = "little")
    intToUtf8(codes)
  } else {
    cli::cli_abort("Unsupported char MAT data type: {.val {type}}")
  }
}

# Inflate a zlib (RFC 1950) stream incrementally, returning whatever decodes
# before the stream ends. Used only as a fallback for a stream `memDecompress()`
# rejects outright, which it does for a section that stops without its
# terminator even though the deflate blocks up to that point are sound.
#
# Base R offers no incremental zlib reader, but `gzcon()` is an incremental gzip
# (RFC 1952) reader, and the two formats wrap the same deflate data: swapping the
# 2-byte zlib header for a minimal gzip header lets `gzcon()` decode it.
#
# The trailers differ, so a stream that runs to completion would fail the gzip
# checksum. That does not arise on the path this is used for: a stream stopping
# short ends at EOF before any trailer is reached, and the caller only reaches
# here when `memDecompress()` has already refused the stream. Input that is not
# deflate data at all can still make the connection layer print a checksum line
# straight to stderr, which no R-level handler can suppress, but such input
# yields nothing and the caller then aborts as before.
#
# The recovered bytes are validated by the element-length check in the caller,
# so a genuinely short read is caught there rather than returned as data.
.inflate_incremental <- function(blob) {
  if (length(blob) < 3L) return(raw(0))

  gz_header <- as.raw(c(0x1f, 0x8b, 0x08, 0x00, 0, 0, 0, 0, 0x00, 0xff))
  con <- tryCatch(gzcon(rawConnection(c(gz_header, blob[-(1:2)]), "rb")),
                  error = function(e) NULL)
  if (is.null(con)) return(raw(0))
  on.exit(try(close(con), silent = TRUE), add = TRUE, after = FALSE)

  chunks <- list()
  n <- 0L
  repeat {
    chunk <- tryCatch(readBin(con, "raw", 1048576L), error = function(e) raw(0))
    if (length(chunk) == 0L) break
    n <- n + 1L
    chunks[[n]] <- chunk
  }

  if (n == 0L) raw(0) else do.call(c, chunks)
}

# Parse the body of a miMATRIX element (everything after its tag) into a
# variable specification. Returns list(name, spec).
.parse_matrix_body <- function(body) {
  off <- 1L

  flags_el <- .read_element(body, off); off <- flags_el$next_off
  flags_word <- readBin(flags_el$data[1:4], "integer", size = 4L, endian = "little")
  class_code <- bitwAnd(flags_word, 0xFFL)
  flag_bits <- bitwAnd(bitwShiftR(flags_word, 8L), 0xFFL)

  dims_el <- .read_element(body, off); off <- dims_el$next_off
  dims <- readBin(dims_el$data, "integer", n = length(dims_el$data) %/% 4L,
                  size = 4L, endian = "little")

  name_el <- .read_element(body, off); off <- name_el$next_off
  name <- if (length(name_el$data) == 0L) "" else rawToChar(name_el$data)

  # Refuse anything we cannot represent faithfully. Decoding these as numeric
  # would silently replace the variable with unrelated bytes, and callers write
  # the result back over the source file.
  if (!class_code %in% .MX_SUPPORTED) {
    label <- .MX_CLASS_NAMES[[as.character(class_code)]]
    cli::cli_abort(c(
      "Unsupported MATLAB array class {.val {class_code}}{if (!is.null(label)) paste0(' (', label, ')') else ''} in variable {.val {name}}.",
      "i" = "Cell arrays of strings, character arrays and numeric arrays are supported; structs, objects, sparse, string, table, categorical and 64-bit integer arrays are not."
    ))
  }
  if (bitwAnd(flag_bits, .MX_FLAG_COMPLEX) != 0L) {
    cli::cli_abort(c(
      "Variable {.val {name}} is a complex array, which is not supported.",
      "i" = "Reading it would silently discard the imaginary part."
    ))
  }
  if (bitwAnd(flag_bits, .MX_FLAG_LOGICAL) != 0L) {
    cli::cli_abort(c(
      "Variable {.val {name}} is a logical array, which is not supported.",
      "i" = "Reading it would demote it to {.code uint8}, breaking logical indexing in MATLAB."
    ))
  }
  if (length(dims) > 2L) {
    cli::cli_abort(c(
      "Variable {.val {name}} has {length(dims)} dimensions; only 2-D arrays are supported.",
      "i" = "Reading it would silently keep only the first two dimensions."
    ))
  }

  # Bound the declared element count against the bytes actually present before
  # anything allocates on the strength of it. prod() returns a double, so
  # corrupt dimensions arrive here as values far beyond what the body could
  # hold, or as NA. Left unchecked they are worse than a crash: the cell branch
  # ties up gigabytes before .read_element()'s bounds check fires, or dies on a
  # bare "vector size specified is too large" naming neither file nor variable,
  # while matrix() in the numeric branch does not even error - it allocates and
  # recycles the short data silently, fabricating values. No encoding stores an
  # element in less than a byte, and the body also carries the flags, dimensions
  # and name, so this bound never rejects an honest file.
  nel <- prod(as.double(dims))
  if (is.na(nel) || nel < 0 || nel > length(body)) {
    cli::cli_abort(c(
      "Malformed MAT-file: variable {.val {name}} declares {nel} elements.",
      "i" = "The element data is {length(body)} bytes, which cannot hold that many."
    ))
  }

  spec <- if (class_code == .MX_CELL) {
    strs <- character(nel)
    if (nel > 0L) {
      for (k in seq_len(nel)) {
        child <- .read_element(body, off); off <- child$next_off
        child_spec <- .parse_matrix_body(child$data)$spec
        # iRfcb only writes/reads cell arrays of strings. A non-char child
        # (e.g. a nested struct or numeric cell) is unsupported; fail clearly
        # rather than coercing a multi-element value and dying on assignment.
        if (!identical(child_spec$type, "char")) {
          cli::cli_abort(c(
            "Unsupported cell array element of type {.val {child_spec$type}}.",
            "i" = "Only cell arrays of character strings are supported."
          ))
        }
        strs[k] <- if (is.null(child_spec$data)) "" else child_spec$data
      }
    }
    cm <- matrix(strs, nrow = dims[1], ncol = if (length(dims) > 1) dims[2] else 1L)
    mat_var_cell(cm)
  } else if (class_code == .MX_CHAR) {
    data_el <- .read_element(body, off)
    decoded <- .decode_char(data_el$type, data_el$data)
    nr <- if (length(dims) > 0L) dims[1] else 0L
    if (nr > 1L) {
      # Multi-row char array, e.g. filelistTB in ifcb-analysis summary files
      # (one fixed-width, space-padded row per sample). The characters are
      # stored in column-major order, so string i is row i of the reshaped
      # code-point matrix. Rows keep their padding, matching scipy and R.matlab.
      codes <- utf8ToInt(decoded)
      # matrix() below recycles a short vector silently, so dimensions that
      # disagree with the decoded data would fabricate rows; refuse instead.
      if (length(codes) != nel) {
        cli::cli_abort(c(
          "Malformed MAT-file: variable {.val {name}} declares a {dims[1]}x{dims[2]} character array but carries {length(codes)} character{?s}.",
          "i" = "Reading it would recycle the data to fill the declared rows."
        ))
      }
      mat_var_char(apply(matrix(codes, nrow = nr), 1L, intToUtf8))
    } else {
      mat_var_char(decoded)
    }
  } else {
    # Any numeric array (double, single, int/uint of any width). MATLAB stores
    # numeric data compactly (e.g. a "double" array of small integers can be
    # stored as uint8), and scipy's loadmat -> savemat round-trip adopts the
    # *data* storage type rather than the (wider) array-flags class. Mirror that
    # here so class files round-trip identically.
    data_el <- .read_element(body, off)
    out_class <- .mat_data_type_to_class(data_el$type)
    vals <- if (length(data_el$data) == 0L) numeric(0) else .decode_numeric(data_el$type, data_el$data)
    nr <- if (length(dims) > 0) dims[1] else 0L
    nc <- if (length(dims) > 1) dims[2] else 1L
    # matrix() recycles rather than complaining when the data is shorter than
    # the dimensions claim, so dimensions that disagree with the payload would
    # be read back as repeated values. Refuse instead: the caller may write the
    # result straight back over the source file.
    if (length(vals) != nel) {
      cli::cli_abort(c(
        "Malformed MAT-file: variable {.val {name}} declares {nr}x{nc} but carries {length(vals)} values.",
        "i" = "Reading it would recycle the data to fill the declared dimensions."
      ))
    }
    # The 32-bit integer classes reach values R cannot hold in an integer (-2^31
    # for int32, everything above 2^31-1 for uint32), so they stay doubles.
    # Everything narrower is exact as an integer.
    vals <- if (out_class %in% c(.MX_DOUBLE, .MX_SINGLE, .MX_INT32, .MX_UINT32)) {
      as.double(vals)
    } else {
      as.integer(vals)
    }
    mat_var_numeric(matrix(vals, nrow = nr, ncol = nc), out_class)
  }

  list(name = name, spec = spec)
}

#' Read a MATLAB v5 MAT-file into writer-compatible specifications (internal)
#'
#' @param filename Path to the `.mat` file.
#' @return A named list of variable specifications (see the `mat_var_*`
#'   constructors) preserving file order, suitable for modification and
#'   re-writing with `write_mat_v5()`.
#' @noRd
read_mat_v5 <- function(filename) {
  raw_all <- readBin(filename, "raw", n = file.size(filename))
  n <- length(raw_all)
  pos <- 129L # skip the 128-byte header
  vars <- list()

  while (pos + 7L <= n) {
    typ <- readBin(raw_all[pos:(pos + 3L)], "integer", size = 4L, endian = "little")
    ln <- readBin(raw_all[(pos + 4L):(pos + 7L)], "integer", size = 4L, endian = "little")
    data_start <- pos + 8L

    if (is.na(ln) || ln < 0L) {
      cli::cli_abort(c(
        "Malformed {.file {basename(filename)}}: invalid element length {.val {ln}}.",
        "i" = "The file may have been written incompletely."
      ))
    }
    if (data_start + ln - 1L > n) {
      cli::cli_abort(c(
        "{.file {basename(filename)}} is truncated.",
        "i" = "An element declares {ln} byte{?s} of data but only {n - data_start + 1L} remain{?s/} in the file."
      ))
    }

    if (typ == .MI_COMPRESSED) {
      blob <- raw_all[data_start:(data_start + ln - 1L)]
      # The 4 pad bytes protect against R builds linked to zlib-ng (Fedora's
      # system zlib): its inflate answers a stream cut off before its Adler-32
      # trailer with "give me more output space" rather than an error, so
      # `memDecompress()` doubles its buffer forever until the OOM killer stops
      # the process. With the pad, the deflate data still ends inside the input
      # and the bytes after it fail the Adler-32 check, turning the runaway
      # into the ordinary error handled below. A complete stream ignores
      # trailing bytes, so intact sections decode as before.
      element <- tryCatch(
        memDecompress(c(blob, raw(4L)), type = "gzip"),
        error = function(e) {
          # Some MATLAB-written files carry a compressed section whose zlib
          # stream never reaches its terminator. `memDecompress()` is one-shot
          # and refuses the whole stream, but the deflate blocks before the end
          # are intact and hold the data. `R.matlab` and `SciPy` both decode
          # these incrementally and so read such files, so refusing them here
          # would lose files that earlier versions of iRfcb could read.
          recovered <- .inflate_incremental(blob)
          if (length(recovered) < 8L) {
            cli::cli_abort(c(
              "Could not decompress {.file {basename(filename)}}.",
              "i" = "A compressed section is truncated or corrupted (the file may have been written incompletely).",
              "x" = conditionMessage(e)
            ))
          }
          cli_warn(c(
            "{.file {basename(filename)}} contains a compressed section that ends without its stream terminator.",
            "i" = "The data was recovered by decoding the section incrementally. The file was likely written incompletely; consider rewriting it."
          ))
          recovered
        }
      )
      # element is a full miMATRIX element: strip its 8-byte tag, parse the body
      if (length(element) < 8L) {
        cli::cli_abort("Malformed {.file {basename(filename)}}: compressed section is too short to hold an element tag.")
      }
      element_type <- readBin(element[1:4], "integer", size = 4L, endian = "little")
      if (element_type != .MI_MATRIX) {
        cli::cli_abort(c(
          "Unexpected element type {.val {element_type}} inside a compressed section of {.file {basename(filename)}}.",
          "i" = "Only matrix elements are supported at the top level."
        ))
      }
      body_len <- readBin(element[5:8], "integer", size = 4L, endian = "little")
      if (is.na(body_len) || body_len < 0L || 8L + body_len > length(element)) {
        cli::cli_abort(c(
          "Malformed {.file {basename(filename)}}: a compressed element declares {body_len} byte{?s} but only {length(element) - 8L} were decompressed.",
          "i" = "The file may have been written incompletely."
        ))
      }
      parsed <- .parse_matrix_body(element[9:(8L + body_len)])
      pos <- data_start + ln # compressed elements are not 8-byte padded
    } else if (typ == .MI_MATRIX) {
      parsed <- .parse_matrix_body(raw_all[data_start:(data_start + ln - 1L)])
      pad <- (8L - (ln %% 8L)) %% 8L
      pos <- data_start + ln + pad
    } else {
      cli::cli_abort("Unexpected top-level MAT element type: {.val {typ}}")
    }

    vars[[parsed$name]] <- parsed$spec
  }

  # The loop exits when fewer than 8 bytes remain - not necessarily at the end
  # of the file. Stray trailing bytes are the start of an element that was cut
  # off mid-tag; reading such a file as a success would silently drop that
  # variable, and a subsequent write-back would make the loss permanent.
  # (pos beyond n + 1 is fine: it only means the final element's 8-byte
  # padding was omitted at EOF, which loses nothing.)
  if (pos <= n) {
    cli::cli_abort(c(
      "{.file {basename(filename)}} is truncated.",
      "x" = "{n - pos + 1L} stray byte{?s} follow{?s/} the last complete element - the start of an element that was cut off.",
      "i" = "The file may have been written incompletely."
    ))
  }

  vars
}
