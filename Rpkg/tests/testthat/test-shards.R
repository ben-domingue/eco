# Core shards (eco, eco_2, ...): listing, lookup and pinning. Offline: the
# Redivis calls and the manifest are stubbed.

listing <- function(names) {
  data.frame(name = names, rows = seq_along(names), bytes = 10, hash = NA_character_,
             updated = as.POSIXct(NA, tz = "UTC"), stringsAsFactors = FALSE)
}
shard_listing <- function(dataset, tag = NULL) {
  switch(dataset$name,
         eco = listing(c("a", "a__taxa", "b", "b__taxa")),
         eco_2 = listing(c("c", "c__taxa", "c__periods")))
}
manifest <- function() {
  data.frame(eco_version = 1:3, date = c("2026-11-01", "2026-11-02", "2026-11-03"),
             eco_redivis_version = c("v1.0", "v1.1", "v1.1"),
             eco_2_redivis_version = c("", "", "v1.0"),
             eco_meta_redivis_version = c("v1.0", "v2.0", "v3.0"),
             n_tables = c("4", "4", "7"), note = "", stringsAsFactors = FALSE)
}
fresh <- function(env = parent.frame()) {
  .eco_env$pin <- NULL
  .eco_clear_session_cache()
  withr::defer({ .eco_env$pin <- NULL; .eco_clear_session_cache() }, envir = env)
}

test_that("the shards are listed together and each table knows its shard", {
  fresh()
  local_mocked_bindings(.eco_table_listing = shard_listing,
                        .eco_core_tags = function() c(eco = "v1.1", eco_2 = "v1.0"))
  tabs <- eco_list_tables()
  expect_equal(tabs$table, c("a", "b", "c"))
  expect_equal(tabs$dataset, c("eco", "eco", "eco_2"))
  expect_equal(tabs$periods, c(FALSE, FALSE, TRUE))
  expect_equal(.eco_shard_of("c__periods")$name, "eco_2")
  expect_equal(.eco_shard_of("a")$ref, "4j5q")
  expect_null(.eco_shard_of("zzz"))
  expect_error(.eco_locate("zzz"), "no table")
})

test_that("a shard not in the version contributes nothing", {
  fresh()
  local_mocked_bindings(.eco_table_listing = shard_listing,
                        .eco_core_tags = function() c(eco = "v1.1", eco_2 = NA))
  expect_equal(eco_list_tables()$table, c("a", "b"))
})

test_that("a name in two shards resolves to the newest", {
  fresh()
  local_mocked_bindings(.eco_table_listing = function(dataset, tag = NULL) listing("x"),
                        .eco_core_tags = function() c(eco = "v1.1", eco_2 = "v1.0"))
  expect_equal(.eco_shard_of("x")$name, "eco_2")
})

test_that("fetch and side tables read from the table's own shard", {
  fresh()
  seen <- new.env()
  local_mocked_bindings(.eco_table_listing = shard_listing,
                        .eco_core_tags = function() c(eco = "v1.1", eco_2 = "v1.0"),
                        .eco_table_file = function(dataset, table, tag) {
                          seen[[table]] <- paste(dataset$name, tag)
                          f <- tempfile(fileext = ".csv"); writeLines(c("unit,taxon,y", "u,T,1"), f); f
                        })
  d <- eco_fetch("c")
  expect_equal(attr(d, "eco_redivis_dataset"), "eco_2")
  expect_equal(attr(d, "eco_redivis_version"), "v1.0")
  expect_equal(seen[["c"]], "eco_2 v1.0")
  eco_periods("c")
  expect_equal(seen[["c__periods"]], "eco_2 v1.0")
  eco_taxa("a")
  expect_equal(seen[["a__taxa"]], "eco v1.1")
  expect_null(eco_periods("a"))
  expect_error(eco_taxa("zzz"), "no table")
})

test_that("pinning takes every shard's tag from the manifest, blank meaning absent", {
  fresh()
  local_mocked_bindings(.eco_manifest = manifest,
                        .eco_dataset_props = function(...) stop("no network in a pinned read"))
  eco_set_version(2)
  expect_equal(.eco_core_tags(), c(eco = "v1.1", eco_2 = NA))
  expect_equal(vapply(.eco_cores_in_force(), `[[`, "", "name"), "eco")
  eco_set_version(3)
  expect_equal(.eco_core_tags(), c(eco = "v1.1", eco_2 = "v1.0"))
  expect_equal(vapply(.eco_cores_in_force(), `[[`, "", "name"), c("eco_2", "eco"))
  expect_equal(.eco_resolved_tag(.eco_meta), "v3.0")
})

test_that("eco_version() matches the manifest row on every shard", {
  fresh()
  local_mocked_bindings(.eco_manifest = manifest,
                        .eco_dataset_props = function(dataset, tag = NULL)
                          list(version = list(tag = c(eco = "v1.1", eco_2 = "v1.0", eco_meta = "v3.0")[[dataset$name]])))
  v <- suppressMessages(eco_version())
  expect_equal(v$eco_version, 3L)
  expect_equal(v$eco, "v1.1"); expect_equal(v$eco_2, "v1.0")
  expect_false(v$pinned)
})

test_that("current read: an unreleased new shard is skipped, an old one failing is an error", {
  fresh()
  props <- function(dataset, tag = NULL) {
    if (dataset$name == "eco_2") stop("401")
    list(version = list(tag = "v1.1"))
  }
  m2 <- function() { m <- manifest(); m$eco_2_redivis_version <- ""; m }
  local_mocked_bindings(.eco_manifest = m2, .eco_dataset_props = props)
  expect_equal(.eco_core_tags(), c(eco = "v1.1", eco_2 = NA))
  .eco_clear_session_cache()
  local_mocked_bindings(.eco_manifest = manifest)   # the manifest says eco_2 has been released
  expect_error(.eco_core_tags(), "401")
})
