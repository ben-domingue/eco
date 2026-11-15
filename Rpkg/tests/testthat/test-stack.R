# eco_stack(): offline. eco_metadata(), eco_list_tables(), eco_fetch() and the
# side-table readers are stubbed with a made-up deposit `dep` in two regions;
# region 1 has an `_exact` sibling without the flagged taxon B.

stack_meta <- function(inclusion = "recorded") {
  data.frame(table = c("dep_r1_count", "dep_r1_exact_count", "dep_r2_count", "other_count"),
             partition_of = c("dep", "dep", "dep", NA),
             partition_by = c("unit_region", "unit_region", "unit_region", NA),
             taxon_inclusion = c(inclusion, inclusion, inclusion, "target"),
             stringsAsFactors = FALSE)
}
stack_listing <- function(survey_taxa = FALSE) {
  data.frame(table = c("dep_r1_count", "dep_r1_exact_count", "dep_r2_count", "other_count"),
             survey_taxa = c(FALSE, FALSE, survey_taxa, FALSE), stringsAsFactors = FALSE)
}
r1 <- data.frame(unit = c("u1", "u1", "u2", "u2"), taxon = c("A", "B", "A", "B"),
                 period = 1L, occasion = 1L, y = c(3L, 1L, 0L, 2L),
                 date = c("2020-06-01", "2020-06-01", "2020-06-02", "2020-06-02"),
                 observer = c("o1", "o1", "o2", "o2"), obs_nb = c(1L, 0L, 0L, 2L),
                 taxon_mass = c(10, 50, 10, 50), stringsAsFactors = FALSE)
r2 <- data.frame(unit = c("u3", "u3", "u3", "u3"), taxon = c("A", "C", "A", "C"),
                 period = 1L, occasion = c(1L, 1L, 2L, 2L), y = c(2L, 0L, 1L, 4L),
                 date = c("2020-06-03", "2020-06-03", "2020-06-04", "2020-06-04"),
                 observer = "o3", obs_nb = c(0L, 0L, 1L, 0L),
                 taxon_mass = c(10, 7, 10, 7), stringsAsFactors = FALSE)
stack_core <- list(dep_r1_count = r1, dep_r1_exact_count = r1[r1$taxon != "B", ], dep_r2_count = r2)
stack_taxa <- list(
  dep_r1_count = data.frame(taxon = c("A", "B"), scientificName = c("Aa", "Bb")),
  dep_r1_exact_count = data.frame(taxon = "A", scientificName = "Aa"),
  dep_r2_count = data.frame(taxon = c("A", "C"), scientificName = c("Aa", "Cc")))
stack_units <- list(
  dep_r1_count = data.frame(unit = c("u1", "u2"), unit_region = 1L, unit_lat = c(40.1, 40.2)),
  dep_r1_exact_count = data.frame(unit = c("u1", "u2"), unit_region = 1L, unit_lat = c(40.123, 40.234)),
  dep_r2_count = data.frame(unit = "u3", unit_region = 2L, unit_lat = 35.5))
stack_periods <- function(t) data.frame(period = 1L, period_year = 2020L, n_runs = if (grepl("r2", t)) 2L else 1L)

mock_stack <- function(inclusion = "recorded", survey_taxa = FALSE, env = parent.frame()) {
  fetched <- new.env()
  local_mocked_bindings(
    eco_metadata = function() stack_meta(inclusion),
    eco_list_tables = function() stack_listing(survey_taxa),
    eco_fetch = function(x) { fetched[[x]] <- TRUE; stack_core[[x]] },
    eco_taxa = function(table) stack_taxa[[table]],
    eco_units = function(table) stack_units[[table]],
    eco_periods = function(table) stack_periods(table),
    .env = env)
  fetched
}

test_that("plain tables by default, the _exact sibling with exact = TRUE", {
  f <- mock_stack()
  d <- eco_stack("dep")
  expect_equal(attr(d, "tables"), c("dep_r1_count", "dep_r2_count"))
  expect_equal(nrow(d), 8)
  expect_setequal(unique(d$taxon), c("A", "B", "C"))
  expect_equal(names(d), names(r1))
  expect_false("filled" %in% names(d))
  expect_equal(attr(d, "partition_by"), "unit_region")
  expect_false(exists("dep_r1_exact_count", envir = f))

  e <- eco_stack("dep", exact = TRUE)
  expect_equal(attr(e, "tables"), c("dep_r1_exact_count", "dep_r2_count"))
  expect_false("B" %in% e$taxon)
  expect_equal(attr(e, "units")$unit_lat, c(40.123, 40.234, 35.5))
  expect_equal(sort(attr(e, "taxa")$taxon), c("A", "C"))
})

test_that("taxa restricts the rows and the __taxa side table", {
  mock_stack()
  d <- eco_stack("dep", taxa = "C")
  expect_equal(nrow(d), 2)
  expect_equal(unique(d$taxon), "C")
  expect_equal(attr(d, "taxa")$taxon, "C")
})

test_that("side tables: units bound, periods stacked with their table, taxa de-duplicated", {
  mock_stack()
  d <- eco_stack("dep")
  u <- attr(d, "units")
  expect_equal(u$unit, c("u1", "u2", "u3"))
  expect_equal(u$unit_region, c(1L, 1L, 2L))
  p <- attr(d, "periods")
  expect_equal(names(p)[1], "table")
  expect_equal(p$table, c("dep_r1_count", "dep_r2_count"))
  expect_equal(p$n_runs, c(1L, 2L))
  tx <- attr(d, "taxa")
  expect_equal(tx$taxon, c("A", "B", "C"))
  expect_equal(attr(d, "eco_partition"), "dep")
})

test_that("fill_zeros adds a zero at every survey of a region lacking the taxon", {
  mock_stack()
  d <- eco_stack("dep", fill_zeros = TRUE)
  expect_equal(nrow(d), 12)
  z <- d[d$filled, ]
  expect_equal(nrow(z), 4)
  expect_true(all(z$y == 0))
  expect_true(is.integer(d$y))
  # region 1 gets C at u1 and u2; region 2 gets B at its two occasions
  zc <- z[z$taxon == "C", ]; zc <- zc[order(zc$unit), ]
  expect_equal(zc$unit, c("u1", "u2"))
  expect_equal(zc$date, c("2020-06-01", "2020-06-02"))
  expect_equal(zc$observer, c("o1", "o2"))
  zb <- z[z$taxon == "B", ]; zb <- zb[order(zb$occasion), ]
  expect_equal(zb$unit, c("u3", "u3"))
  expect_equal(zb$occasion, 1:2)
  expect_equal(zb$date, c("2020-06-03", "2020-06-04"))
  # obs_nb varies by taxon within a survey: NA on a filled row
  expect_true(all(is.na(z$obs_nb)))
  # taxon_ columns copied from the taxon's own rows
  expect_equal(unique(zb$taxon_mass), 50)
  expect_equal(unique(zc$taxon_mass), 7)
  # no observed row was changed, and no survey has two rows for a taxon
  expect_false(any(d$filled[d$y != 0 & !is.na(d$obs_nb) & d$obs_nb > 0]))
  expect_equal(anyDuplicated(d[, c("unit", "taxon", "period", "occasion")]), 0L)
})

test_that("fill_zeros with taxa fills only those taxa, from the full survey set", {
  mock_stack()
  d <- eco_stack("dep", taxa = "B", fill_zeros = TRUE)
  expect_equal(nrow(d), 4)
  expect_equal(sum(d$filled), 2)
  expect_equal(sort(d$unit[d$filled]), c("u3", "u3"))
  # with exact = TRUE the flagged B is in no stacked part: zeros would be false
  expect_error(eco_stack("dep", taxa = "B", fill_zeros = TRUE, exact = TRUE), "no part of `dep` has taxon B")
  e <- eco_stack("dep", taxa = "C", fill_zeros = TRUE, exact = TRUE)
  expect_equal(sort(e$unit[e$filled]), c("u1", "u2"))
  expect_error(eco_stack("dep", taxa = "ZZ", fill_zeros = TRUE), "no part of `dep` has taxon ZZ")
})

test_that("fill_zeros refuses unless every part is a recorded complete list", {
  mock_stack(inclusion = "target")
  expect_error(eco_stack("dep", fill_zeros = TRUE), "taxon_inclusion is not \"recorded\"")
  expect_silent(eco_stack("dep"))
  mock_stack(survey_taxa = TRUE)
  expect_error(eco_stack("dep", fill_zeros = TRUE), "dep_r2_count has a __survey_taxa")
})

test_that("an unknown partition is an error naming the partitioned deposits", {
  mock_stack()
  expect_error(eco_stack("nope"), "no table in this eco version is a part of `nope`.*partitioned deposits: dep")
  expect_error(eco_stack(c("a", "b")), "one deposit-level name")
  local_mocked_bindings(eco_metadata = function() stack_meta()[, c("table", "taxon_inclusion")])
  expect_error(eco_stack("dep"), "records no partitions")
})
