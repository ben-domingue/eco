# The logged-in route for tables over Redivis' 100 MB anonymous cap. Offline:
# the table listing and the redivis call are stubbed.

big_listing <- function() {
  data.frame(name = c("big_table", "small_table"), rows = c(3, 3),
             bytes = c(150 * 1024^2, 1000), hash = NA_character_,
             updated = as.POSIXct(NA, tz = "UTC"), stringsAsFactors = FALSE)
}

test_that("a table over the cap is flagged in the listing", {
  local_mocked_bindings(.eco_table_listing = function(...) big_listing(), .eco_tag_for = function(...) NULL)
  tabs <- eco_list_tables()
  expect_equal(tabs$needs_login, c(TRUE, FALSE))
})

test_that("without the packages or a login, the route stops with instructions", {
  local_mocked_bindings(.eco_table_listing = function(...) big_listing())
  dest <- tempfile(fileext = ".csv")

  local_mocked_bindings(.eco_missing_auth_pkgs = function() character(),
                        .eco_redivis_credentials_available = function() FALSE)
  expect_error(.eco_download_rows(.eco_core, "big_table", NULL, dest),
               "150 MB.*free Redivis account.*authenticate")
  expect_false(file.exists(dest))

  local_mocked_bindings(.eco_missing_auth_pkgs = function() c("redivis", "arrow"))
  expect_error(.eco_download_rows(.eco_core, "big_table", NULL, dest), "install.packages")
})

test_that("with a login, the table is written as CSV and reads back", {
  local_mocked_bindings(
    .eco_table_listing = function(...) big_listing(),
    .eco_auth_problem = function(...) NULL,
    .eco_redivis_arrow = function(dataset, table, tag) {
      expect_equal(table, "big_table")
      data.frame(unit = c("a", "a", "b"), taxon = "X", y = c(0L, 1L, 0L),
                 date = as.Date(c("2020-06-01", "2020-06-02", NA)))
    })
  dest <- tempfile(fileext = ".csv")
  expect_message(.eco_download_rows(.eco_core, "big_table", "v2.2", dest), "Redivis login")
  d <- .eco_read_csv(dest)
  expect_equal(nrow(d), 3)
  expect_equal(d$y, c(0L, 1L, 0L))
  expect_true(is.na(d$date[3]))
})

test_that("redivis errors are reported by kind", {
  local_mocked_bindings(
    .eco_table_listing = function(...) big_listing(),
    .eco_auth_problem = function(...) NULL,
    .eco_redivis_arrow = function(...) stop("[401 invalid_token] No credentials"))
  expect_error(suppressMessages(.eco_download_rows(.eco_core, "big_table", NULL, tempfile())),
               "did not accept your login")
  local_mocked_bindings(.eco_redivis_arrow = function(...) stop("[429] export quota exceeded"))
  expect_error(suppressMessages(.eco_download_rows(.eco_core, "big_table", NULL, tempfile())),
               "export quota")
})

test_that("a small table never takes the logged-in route", {
  local_mocked_bindings(
    .eco_table_listing = function(...) big_listing(),
    .eco_download_rows_auth = function(...) stop("should not be called"),
    .eco_download = function(url, dest, what) { writeLines("unit,taxon,y", dest); invisible(dest) })
  dest <- tempfile(fileext = ".csv")
  .eco_download_rows(.eco_core, "small_table", NULL, dest)
  expect_true(file.exists(dest))
})
