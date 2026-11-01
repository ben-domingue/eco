# Online: the anonymous Redivis route. Skipped without a network.

skip_if_offline <- function() {
  if (!requireNamespace("curl", quietly = TRUE) || !curl::has_internet()) skip("no network")
  if (nzchar(Sys.getenv("ECO_SKIP_REMOTE"))) skip("ECO_SKIP_REMOTE set")
}

test_that("the corpus lists and the metadata tables agree with it", {
  skip_if_offline()
  tabs <- eco_list_tables()
  expect_true(nrow(tabs) >= 6)
  expect_true(all(tabs$taxa))
  expect_false(any(grepl("__", tabs$table)))
  m <- eco_metadata(); b <- eco_biblio(); t <- eco_tags()
  expect_setequal(m$table, tabs$table)
  expect_setequal(b$table, tabs$table)
  expect_setequal(t$table, tabs$table)
  expect_true(all(c("n_units", "n_occasions", "response_type", "sample_floor") %in% names(m)))
})

test_that("fetch, side tables and info work for the smallest table", {
  skip_if_offline()
  withr::local_options(eco.cache = FALSE)
  d <- eco_fetch("schank_2015_tapir_occ")
  expect_equal(nrow(d), nrow(schank_2015_tapir_occ))
  expect_equal(attr(d, "eco_table"), "schank_2015_tapir_occ")
  expect_true(eco_check(d)$ok)
  taxa <- eco_taxa(d)
  expect_equal(taxa$taxon, "TAPBAI")
  expect_null(eco_periods("schank_2015_tapir_occ"))
  expect_message(eco_info("schank_2015_tapir_occ"), "Tapir|tapir")
  expect_error(eco_fetch("no_such_table"), "no table")
})

test_that("filter feeds fetch and the pin round-trips", {
  skip_if_offline()
  f <- eco_filter(model_family = "occupancy", response_type = "detection", multi_species = FALSE)
  expect_true("schank_2015_tapir_occ" %in% f$table)
  expect_true(all(f$n_taxa == 1))
  expect_equal(nrow(eco_filter(min_units = 1e9)), 0L)
  withr::local_options(eco.cache = FALSE)
  got <- eco_fetch(head(f[f$table == "schank_2015_tapir_occ", ], 1))
  expect_true(is.data.frame(got))
  m <- eco_manifest()
  expect_true(all(c("eco_version", "eco_redivis_version") %in% names(m)))
  eco_set_version(1)
  on.exit(eco_reset_version(), add = TRUE)
  v <- suppressMessages(eco_version())
  expect_true(v$pinned); expect_equal(v$eco, "v1.0")
  expect_true(nrow(eco_list_tables()) >= 6)
  eco_reset_version()
  expect_false(suppressMessages(eco_version())$pinned)
  expect_error(eco_set_version(999), "no eco version")
})

test_that("bibtex entries are produced", {
  skip_if_offline()
  bib <- eco_save_bibtex("schank_2015_tapir_occ")
  expect_match(bib, "^@", all = TRUE)
  expect_match(bib, "schank_2015_tapir_occ")
})
