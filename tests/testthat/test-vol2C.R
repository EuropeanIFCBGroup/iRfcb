test_that("vol2C conversion functions match Menden-Deuer and Lessard (2000)", {
  volume <- c(300, 1000, 3000, 10000)

  # Large-diatom relationship: log a = -0.933, b = 0.881
  expect_equal(vol2C_lgdiatom(volume), 10^(-0.933 + 0.881 * log10(volume)))

  # All-sizes diatom relationship: log a = -0.541, b = 0.811
  expect_equal(vol2C_diatom(volume), 10^(-0.541 + 0.811 * log10(volume)))

  # Non-diatom protist relationship: log a = -0.665, b = 0.939
  expect_equal(vol2C_nondiatom(volume), 10^(-0.665 + 0.939 * log10(volume)))
})

test_that("all-sizes diatom equation assigns more carbon to small cells than the large-diatom equation", {
  small <- c(100, 300, 1000)
  expect_true(all(vol2C_diatom(small) > vol2C_lgdiatom(small)))
})

test_that("the two diatom equations are not continuous at 3000 micron^3", {
  # vol2C_diatom predicts ~190 pgC and vol2C_lgdiatom ~135 pgC at the boundary
  expect_gt(vol2C_diatom(3000), vol2C_lgdiatom(3000))
})

test_that("vol2C functions are vectorised and preserve length", {
  volume <- c(500, 5000, 50000)
  expect_length(vol2C_diatom(volume), length(volume))
  expect_length(vol2C_lgdiatom(volume), length(volume))
  expect_length(vol2C_nondiatom(volume), length(volume))
})

test_that("vol2C_diatom_auto picks the equation from the volume it is given", {
  expect_identical(vol2C_diatom_auto(c(5000, 10000)), vol2C_lgdiatom(c(5000, 10000)))
  expect_identical(vol2C_diatom_auto(c(100, 2999)), vol2C_diatom(c(100, 2999)))
  # The boundary itself is not "> 3000", so it takes the all-sizes equation.
  expect_identical(vol2C_diatom_auto(3000), vol2C_diatom(3000))
  # Mixed input selects element-wise, and length is preserved.
  v <- c(100, 5000, 2999, 20000)
  expect_equal(vol2C_diatom_auto(v),
               ifelse(v > 3000, vol2C_lgdiatom(v), vol2C_diatom(v)))
  expect_length(vol2C_diatom_auto(v), length(v))
})

test_that("scale_vol2C_per_cell returns the original function when cells is NULL", {
  # This is the regression guarantee for carbon_conversion = "roi": the very same
  # function object is called, so the result cannot drift by so much as an ulp.
  expect_identical(scale_vol2C_per_cell(vol2C_lgdiatom, NULL), vol2C_lgdiatom)
  expect_identical(scale_vol2C_per_cell(vol2C_diatom, NULL), vol2C_diatom)
  expect_identical(scale_vol2C_per_cell(vol2C_nondiatom, NULL), vol2C_nondiatom)
})

test_that("scale_vol2C_per_cell applies the equation per cell and sums over the chain", {
  volume <- c(8000, 8000, 8000)
  # Closed form for a power law: n * f(V/n) == f(V) * n^(1-b).
  for (spec in list(list(f = vol2C_lgdiatom,  b = 0.881),
                    list(f = vol2C_diatom,    b = 0.811),
                    list(f = vol2C_nondiatom, b = 0.939))) {
    n <- c(2, 8, 20)
    g <- scale_vol2C_per_cell(spec$f, n)
    expect_equal(g(volume), spec$f(volume) * n^(1 - spec$b))
  }
})

test_that("scale_vol2C_per_cell is a no-op for single cells and unmeasured ROIs", {
  volume <- c(500, 5000, 50000)
  # cell_count_resolved is 1 for -1/0 under the default single_cell_values, and
  # NA where no chain data was available at all. All must reproduce vol2C exactly.
  for (n in list(c(1, 1, 1), c(NA, NA, NA), c(0, 0, 0), c(-1, -1, -1))) {
    g <- scale_vol2C_per_cell(vol2C_lgdiatom, n)
    expect_identical(g(volume), vol2C_lgdiatom(volume))
  }
})

test_that("scale_vol2C_per_cell handles zero volume and mixed counts", {
  g <- scale_vol2C_per_cell(vol2C_lgdiatom, c(1, 4, NA, 3))
  out <- g(c(0, 8000, 8000, 0))
  # Zero-volume ROIs survive when drop_zero_volume = FALSE; they must stay 0.
  expect_identical(out[c(1, 4)], c(0, 0))
  expect_false(any(is.nan(out)))
  expect_length(out, 4L)
  # The NA count falls back to one cell, i.e. the whole-ROI value.
  expect_identical(out[3], vol2C_lgdiatom(8000))
})

test_that("an 8-cell chain gains about 28 percent carbon under the large-diatom equation", {
  # The multiplier on the current number is n^(1-b); the shortfall of the current
  # number against the corrected one is 1 - n^(b-1).
  expect_equal(8^(1 - 0.881), 1.281, tolerance = 1e-3)
  expect_equal(1 - 8^(0.881 - 1), 0.219, tolerance = 1e-3)
  expect_equal(20^(1 - 0.881), 1.428, tolerance = 1e-3)
})
