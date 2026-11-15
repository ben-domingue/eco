# eco_cite(): offline. The shard listings and the eco_meta biblio are stubbed,
# as in test-deposits.R; eco_version() is stubbed for eco's own entry.

cite_listing <- function(dataset, tag = NULL) {
  nm <- switch(dataset$name, eco = c("a", "a__taxa", "b", "b__taxa", "c", "c__taxa", "d", "d__taxa", "p", "p__taxa"),
               eco_2 = character())
  data.frame(name = nm, rows = seq_along(nm), bytes = 10, hash = NA_character_,
             updated = as.POSIXct(NA, tz = "UTC"), stringsAsFactors = FALSE)
}
# a and b: one deposit (DOI written two ways) and one paper. c: its own deposit,
# the same paper as a/b. d: its own deposit and paper, no cached BibTeX. p: an R
# package's example data, no DOI, paper by reference text only.
cite_biblio <- function() {
  bib_ab <- function(t) paste0("@misc{", t, ",\n  doi = {10.5061/dryad.x1},\n  title = {Smith data}\n}\n\n",
                               "@article{", t, "_paper, DOI={10.1/paper.s}, title={Smith paper} }")
  d <- data.frame(
    table = c("a", "b", "c", "d", "p"),
    title = c("Smith data", "Smith data", "Jones data", "Zed data", "Pkg data"),
    creator = c("Smith", "Smith", "Jones", "Zed", "Pkg"),
    pub_date = c("2020", "2020", "2021", "2022", "2019"),
    citation = c("Smith (2020). Data.", "Smith (2020). Data.", "Jones (2021). Data.", "Zed (2022). Data.", "Pkg manual."),
    reference = c("Smith (2020). Paper.", "Smith (2020). Paper.", "Smith (2020). Paper.", "Zed (2022). Paper.", "Original study (1999)."),
    doi_paper = c("10.1/paper.s", "https://doi.org/10.1/PAPER.S", "10.1/paper.s", "10.1/paper.z", ""),
    doi_data = c("10.5061/DRYAD.X1", "https://doi.org/10.5061/dryad.x1", "10.5281/zenodo.9", "10.5281/zenodo.10", ""),
    source_url = c("https://doi.org/10.5061/dryad.x1", "https://doi.org/10.5061/dryad.x1", "https://doi.org/10.5281/zenodo.9",
                   "https://doi.org/10.5281/zenodo.10", "https://cran.r-project.org/package=unmarked/"),
    spdx = "CC0-1.0",
    bibtex = c(bib_ab("a"), bib_ab("b"),
               "@misc{c,\n  doi = {10.5281/zenodo.9}\n}\n\n@article{c_paper, DOI={10.1/paper.s}, title={Smith paper} }",
               "", ""),
    stringsAsFactors = FALSE)
  f <- tempfile(fileext = ".csv"); write.csv(d, f, row.names = FALSE); f
}

with_cite_stubs <- function(code) {
  .eco_env$pin <- NULL
  .eco_clear_session_cache()
  withr::defer({ .eco_env$pin <- NULL; .eco_clear_session_cache() })
  local_mocked_bindings(.eco_table_listing = cite_listing,
                        .eco_core_tags = function() c(eco = "v1.1", eco_2 = NA),
                        .eco_resolved_tag = function(dataset) "v1.0",
                        .eco_table_file = function(dataset, table, tag) cite_biblio(),
                        eco_version = function() list(eco_version = 15L, released = "2026-11-06T00:00:00Z"))
  force(code)
}

test_that("text: one entry per deposit and per paper, eco last", {
  with_cite_stubs({
    x <- eco_cite(c("b", "a", "c"))
    expect_equal(x[1:3], c("Jones (2021). Data.", "Smith (2020). Data.", "Smith (2020). Paper."))
    expect_length(x, 4)
    expect_match(x[4], "eco: a warehouse.*version 15")
    expect_length(eco_cite("a", eco = FALSE), 2)
  })
})

test_that("bibtex: keys do not depend on the tables asked for", {
  with_cite_stubs({
    x <- eco_cite("b", "bibtex", eco = FALSE)
    expect_length(x, 2)
    expect_match(x[1], "^@misc\\{a,")          # the deposit's first table, not b
    expect_match(x[2], "^@article\\{a_paper,")
    y <- eco_cite(c("a", "b", "c"), "bibtex")
    expect_equal(sum(grepl("_paper,", y)), 1)    # c's paper is a/b's
    expect_true(any(grepl("^@misc\\{c,", y)))
    expect_match(y[length(y)], "^@misc\\{eco_v15,")
  })
})

test_that("no cached BibTeX: a @misc for the deposit, no paper entry", {
  with_cite_stubs({
    x <- eco_cite("d", "bibtex", eco = FALSE)
    expect_length(x, 1)
    expect_match(x, "^@misc\\{d,")
    expect_match(x, "doi = \\{10.5281/zenodo.10\\}")
    expect_equal(eco_cite("d", eco = FALSE), c("Zed (2022). Data.", "Zed (2022). Paper."))
  })
})

test_that("no DOI: deposit and paper from the text columns", {
  with_cite_stubs({
    expect_equal(eco_cite("p", eco = FALSE), c("Original study (1999).", "Pkg manual."))
  })
})

test_that("file, data.frame input, unknown tables, the wrapper", {
  with_cite_stubs({
    f <- tempfile(fileext = ".bib")
    expect_invisible(eco_save_bibtex(data.frame(table = c("a", "c")), f))
    expect_true(any(grepl("^@misc\\{eco_v15,", readLines(f))))
    expect_warning(x <- eco_cite(c("a", "nope"), eco = FALSE), "no bibliography row for: nope")
    expect_length(x, 2)
  })
})

test_that("the fetch reminder prints once per session and can be silenced", {
  .eco_clear_session_cache(); .eco_env$cite_reminded <- NULL
  withr::defer(.eco_env$cite_reminded <- NULL)
  expect_message(.eco_cite_reminder(), "eco_cite")
  expect_silent(.eco_cite_reminder())
  .eco_env$cite_reminded <- NULL
  withr::local_options(eco.cite_reminder = FALSE)
  expect_silent(.eco_cite_reminder())
})
