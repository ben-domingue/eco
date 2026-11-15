# eco_filter(licence =): offline. The three eco_meta tables are stubbed.

test_that("licence shortcuts classify the corpus's SPDX ids", {
  x <- c("CC0-1.0", "CC-BY-4.0", "CC-BY-3.0-US", "OGL-UK-3.0", "ODC-By-1.0", "GPL-3.0-or-later",
         "CC-BY-NC-4.0", "CC-BY-NC-SA-4.0", "CC-BY-SA-4.0", "ODbL-1.0", "LicenseRef-x", NA, "")
  expect_equal(.eco_licence_ok(x, "permissive"), rep(c(TRUE, FALSE), c(5, 8)))
  expect_equal(.eco_licence_ok(x, "public-domain"), c(TRUE, rep(FALSE, 12)))
  expect_equal(which(.eco_licence_ok(x, c("cc-by-nc-4.0", "ODbL-1.0"))), c(7L, 10L))
})

test_that("eco_filter() keeps tables by licence and reports it", {
  local_mocked_bindings(
    eco_metadata = function() data.frame(table = c("a", "b", "c", "d"), n_units = 50, n_taxa = 1, stringsAsFactors = FALSE),
    eco_tags = function() data.frame(table = c("a", "b", "c", "d"), model_family = "occupancy", stringsAsFactors = FALSE),
    eco_biblio = function() data.frame(table = c("a", "b", "c", "d"),
                                       spdx = c("CC0-1.0", "CC-BY-4.0", "CC-BY-NC-4.0", NA), stringsAsFactors = FALSE))
  expect_equal(eco_filter(licence = "permissive")$table, c("a", "b"))
  expect_equal(eco_filter(licence = "public-domain")$table, "a")
  expect_equal(eco_filter(licence = "CC-BY-NC-4.0")$table, "c")
  all <- eco_filter()
  expect_equal(nrow(all), 4)
  expect_equal(all$licence, c("CC0-1.0", "CC-BY-4.0", "CC-BY-NC-4.0", NA))
})
