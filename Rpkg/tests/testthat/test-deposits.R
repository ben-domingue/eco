# eco_list_deposits(): offline. The shard listings and the eco_meta biblio are
# stubbed, as in test-shards.R.

dep_listing <- function(dataset, tag = NULL) {
  nm <- switch(dataset$name,
               eco = c("a", "a__taxa", "b", "b__taxa", "c", "c__taxa"),
               eco_2 = c("p", "p__taxa"))
  data.frame(name = nm, rows = seq_along(nm), bytes = 10, hash = NA_character_,
             updated = as.POSIXct(NA, tz = "UTC"), stringsAsFactors = FALSE)
}
# Tables a and b share a deposit (one DOI, written two ways); c has its own; p
# is an R package's example data (no DOI); u is built but not released, from
# a deposit no released table comes from.
biblio_csv <- function(with_deposit) {
  d <- data.frame(
    table = c("a", "b", "c", "p", "u"),
    citation = c("Smith 2020", "Smith 2020", "Jones 2021", "Pkg manual", "New 2026"),
    creator = c("Smith", "Smith", "Jones", "Pkg", "New"),
    doi_data = c("10.5061/DRYAD.X1", "https://doi.org/10.5061/dryad.x1", "10.5281/zenodo.9", "", "10.1/new"),
    source_url = c("https://doi.org/10.5061/dryad.x1", "https://doi.org/10.5061/dryad.x1",
                   "https://doi.org/10.5281/zenodo.9", "https://cran.r-project.org/package=unmarked/", "https://doi.org/10.1/new"),
    source_via = c("Dryad", "Dryad", "Zenodo", "R package (unmarked)", "Zenodo"),
    stringsAsFactors = FALSE)
  if (with_deposit)
    d$deposit <- c("https://doi.org/10.5061/dryad.x1", "https://doi.org/10.5061/dryad.x1",
                   "https://doi.org/10.5281/zenodo.9", "https://cran.r-project.org/package=unmarked",
                   "https://doi.org/10.1/new")
  f <- tempfile(fileext = ".csv"); write.csv(d, f, row.names = FALSE); f
}

for (with_deposit in c(TRUE, FALSE)) {
  test_that(paste("one row per deposit, released tables only; deposit column", if (with_deposit) "read" else "derived"), {
    .eco_env$pin <- NULL
    .eco_clear_session_cache()
    withr::defer({ .eco_env$pin <- NULL; .eco_clear_session_cache() })
    local_mocked_bindings(.eco_table_listing = dep_listing,
                          .eco_core_tags = function() c(eco = "v1.1", eco_2 = "v1.0"),
                          .eco_resolved_tag = function(dataset) "v1.0",
                          .eco_table_file = function(dataset, table, tag) biblio_csv(with_deposit))
    d <- eco_list_deposits()
    expect_equal(nrow(d), 3)
    expect_equal(sum(d$n_tables), nrow(eco_list_tables()))
    expect_equal(d$deposit[1], "https://doi.org/10.5061/dryad.x1")
    expect_equal(d$n_tables[1], 2L)
    expect_equal(d$tables[1], "a, b")
    expect_equal(d$citation[1], "Smith 2020")
    expect_true("https://cran.r-project.org/package=unmarked" %in% d$deposit)
    expect_true(is.na(d$doi[d$tables == "p"]))
    expect_false("u" %in% unlist(strsplit(d$tables, ", ")))
    expect_equal(attr(d, "unreleased"), "https://doi.org/10.1/new")
  })
}
