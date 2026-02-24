# ── Integration test (requires network access) ────────────────────────────────

test_that("ifcb_classify_models returns a character vector of model names", {
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable("https://irfcb-classify.hf.space/gradio_api/info")

  models <- ifcb_classify_models()

  expect_type(models, "character")
  expect_true(length(models) >= 1)
})
