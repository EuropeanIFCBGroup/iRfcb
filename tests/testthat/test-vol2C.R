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
