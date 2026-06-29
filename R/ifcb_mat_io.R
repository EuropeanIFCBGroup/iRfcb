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
#   - character arrays (single strings)
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
.MX_CELL   <- 1L
.MX_CHAR   <- 4L
.MX_DOUBLE <- 6L
.MX_UINT16 <- 11L

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
# (where `name` is "").
.mat_char_matrix <- function(name, s) {
  if (is.na(s)) s <- ""
  bytes <- charToRaw(enc2utf8(s))
  nch <- nchar(s, type = "chars")
  dims <- if (nch == 0L) c(0L, 0L) else c(1L, nch)
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
    "12" = list(mi = .MI_INT32,  enc = function(x) .raw_i32vec(x)),                               # mxINT32
    "13" = list(mi = .MI_UINT32, enc = function(x) .raw_i32vec(x)),                               # mxUINT32
    cli::cli_abort("Unsupported numeric MAT array class: {.val {class_code}}")
  )
}

# Build a top-level numeric matrix variable of the given MATLAB array class.
.mat_numeric_matrix <- function(name, mat, class_code) {
  if (is.null(dim(mat))) mat <- matrix(mat, ncol = 1L)
  dims <- dim(mat)
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

#' Write a MATLAB v5 MAT-file from R (internal)
#'
#' @param filename Output path.
#' @param vars A named list of variable specifications created with
#'   `mat_var_double()`, `mat_var_uint16()`, `mat_var_cell()` or
#'   `mat_var_char()`. List names become MATLAB variable names.
#' @param do_compression Logical; compress each variable with zlib.
#' @noRd
write_mat_v5 <- function(filename, vars, do_compression = TRUE) {
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
  tag4 <- readBin(raw[off:(off + 3L)], "integer", size = 4L, endian = "little")
  nbytes_small <- bitwShiftR(tag4, 16L)
  if (nbytes_small != 0L) {
    # small data element: low 16 bits = type, high 16 bits = byte count
    type <- bitwAnd(tag4, 0xFFFFL)
    nb <- nbytes_small
    data <- if (nb > 0L) raw[(off + 4L):(off + 3L + nb)] else raw(0)
    list(type = type, data = data, next_off = off + 8L)
  } else {
    type <- tag4
    nb <- readBin(raw[(off + 4L):(off + 7L)], "integer", size = 4L, endian = "little")
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
    "5" = readBin(data, "integer", n = length(data) %/% 4L, size = 4L, endian = "little"),      # miINT32
    "6" = readBin(data, "integer", n = length(data) %/% 4L, size = 4L, endian = "little"),      # miUINT32
    "4" = readBin(data, "integer", n = length(data) %/% 2L, size = 2L, endian = "little", signed = FALSE), # miUINT16
    "3" = readBin(data, "integer", n = length(data) %/% 2L, size = 2L, endian = "little"),      # miINT16
    "2" = as.integer(data),                                                                     # miUINT8
    "1" = as.integer(data),                                                                     # miINT8
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
  } else if (type == 4L || type == 3L) {
    # miUINT16 / miINT16 (UTF-16-ish; class names are ASCII so this suffices)
    codes <- readBin(data, "integer", n = length(data) %/% 2L, size = 2L,
                     endian = "little", signed = FALSE)
    intToUtf8(codes)
  } else {
    cli::cli_abort("Unsupported char MAT data type: {.val {type}}")
  }
}

# Parse the body of a miMATRIX element (everything after its tag) into a
# variable specification. Returns list(name, spec).
.parse_matrix_body <- function(body) {
  off <- 1L

  flags_el <- .read_element(body, off); off <- flags_el$next_off
  class_code <- bitwAnd(
    readBin(flags_el$data[1:4], "integer", size = 4L, endian = "little"), 0xFFL)

  dims_el <- .read_element(body, off); off <- dims_el$next_off
  dims <- readBin(dims_el$data, "integer", n = length(dims_el$data) %/% 4L,
                  size = 4L, endian = "little")

  name_el <- .read_element(body, off); off <- name_el$next_off
  name <- if (length(name_el$data) == 0L) "" else rawToChar(name_el$data)

  spec <- if (class_code == .MX_CELL) {
    nel <- prod(dims)
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
    mat_var_char(.decode_char(data_el$type, data_el$data))
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
    vals <- if (out_class == .MX_DOUBLE || out_class == 7L) as.double(vals) else as.integer(vals)
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

    if (typ == .MI_COMPRESSED) {
      element <- tryCatch(
        memDecompress(raw_all[data_start:(data_start + ln - 1L)], type = "gzip"),
        error = function(e) {
          cli::cli_abort(c(
            "Could not decompress {.file {basename(filename)}}.",
            "i" = "A compressed section is truncated or corrupted (the file may have been written incompletely).",
            "x" = conditionMessage(e)
          ))
        }
      )
      # element is a full miMATRIX element: strip its 8-byte tag, parse the body
      body_len <- readBin(element[5:8], "integer", size = 4L, endian = "little")
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

  vars
}
