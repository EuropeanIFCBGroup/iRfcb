test_that("get_latest_github_release returns the latest release tag", {
  skip_on_cran()
  skip_if_offline()

  tag <- get_latest_github_release("WHOIGit/ifcb-features")

  # The repository has published releases, so a tag should be returned.
  # If GitHub rate-limits the request, the helper returns NULL; skip in that case
  # rather than failing on a transient API limit.
  skip_if(is.null(tag), "GitHub API unavailable or rate limited")

  expect_type(tag, "character")
  expect_length(tag, 1)
  expect_match(tag, "^v?[0-9]")  # e.g. "v1.0.0" or "1.0.0"
})

test_that("get_latest_github_release returns NULL for a nonexistent repository", {
  skip_on_cran()
  skip_if_offline()

  expect_null(get_latest_github_release("WHOIGit/this-repo-does-not-exist-xyz123"))
})

test_that("resolve_ifcb_features_url builds a pinned URL for an explicit ref", {
  # An explicit ref does not require a network call.
  expect_equal(
    resolve_ifcb_features_url("v1.0.0"),
    "git+https://github.com/WHOIGit/ifcb-features.git@v1.0.0"
  )
  expect_equal(
    resolve_ifcb_features_url("main"),
    "git+https://github.com/WHOIGit/ifcb-features.git@main"
  )
})
