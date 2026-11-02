# Offline: the converters on the bundled table.

tapir <- schank_2015_tapir_occ

test_that("bundled table passes eco_check and round-trips through an array", {
  v <- eco_check(tapir)
  expect_true(v$ok)
  expect_equal(v$n_units, 22L); expect_equal(v$n_taxa, 1L)
  a <- eco_to_array(tapir)
  expect_equal(dim(a$y), c(22L, 72L))
  expect_equal(sum(is.na(a$y)), 22L * 72L - nrow(tapir))
  back <- array_to_eco(a$y, taxon = a$taxa, site_ids = a$site_ids, site_covs = a$site_covs)
  expect_equal(nrow(back), nrow(tapir))
  expect_equal(sum(back$y), sum(tapir$y))
})

test_that("eco_check reports clause ids", {
  bad <- tapir; bad$y[1] <- NA
  expect_match(eco_check(bad)$problems, "^E4", all = FALSE)
  dup <- rbind(tapir, tapir[1, ])
  expect_match(eco_check(dup)$problems, "^E3", all = FALSE)
  stray <- tapir; stray$elevation <- 1
  expect_match(eco_check(stray)$problems, "E1/E5", all = FALSE)
})

test_that("eco_to_unmarked infers occu and fits", {
  skip_if_not_installed("unmarked")
  expect_message(umf <- eco_to_unmarked(tapir), "occu")
  expect_s4_class(umf, "unmarkedFrameOccu")
  expect_equal(dim(unmarked::getY(umf)), c(22L, 72L))
  fit <- unmarked::occu(~1 ~1, umf)
  expect_true(is.finite(unmarked::coef(fit)[1]))
  back <- umf_to_eco(umf, taxon = "TAPBAI")
  expect_equal(nrow(back), nrow(tapir))
})

test_that("eco_to_unmarked refuses a multi-taxon table and maps a list", {
  two <- rbind(tapir, transform(tapir, taxon = "OTHER"))
  expect_error(eco_to_unmarked(two), "2 taxa")
  skip_if_not_installed("unmarked")
  out <- suppressMessages(eco_to_unmarked(list(a = tapir, b = tapir)))
  expect_named(out, c("a", "b"))
})

test_that("counts become pcount, several periods colext", {
  skip_if_not_installed("unmarked")
  counts <- tapir; counts$y <- counts$y * 3L
  expect_message(eco_to_unmarked(counts), "pcount")
  multi <- tapir; multi$period <- ifelse(multi$occasion <= 36, 1L, 2L)
  multi$occasion <- ifelse(multi$period == 1L, multi$occasion, multi$occasion - 36L)
  expect_message(umf <- eco_to_unmarked(multi), "colext")
  expect_equal(umf@numPrimary, 2L)
})

test_that("binomial_count rows expand to an exchangeable history", {
  b <- data.frame(unit = c("a", "b"), taxon = "X", y = c(2L, 0L), obs_trials = c(3L, 2L), unit_elev = c(1, 2))
  expect_true(eco_check(b)$ok)
  bad <- b; bad$y[1] <- 5L
  expect_match(eco_check(bad)$problems, "obs_trials", all = FALSE)
  h <- binomial_to_history(b)
  expect_equal(nrow(h), 5L)
  expect_equal(sum(h$y), 2L)
  expect_true(all(h$occasion[h$unit == "a"] == 1:3))
  expect_false("obs_trials" %in% names(h))
  skip_if_not_installed("unmarked")
  expect_message(umf <- eco_to_unmarked(b), "binomial_count")
  expect_equal(dim(umf@y), c(2L, 3L))
})

test_that("capture histories round-trip", {
  d <- data.frame(ch = c("1011", "0101", "1011"), sex = c("f", "m", "f"), stringsAsFactors = FALSE)
  long <- ch_to_eco(d, taxon = "CINCIN")
  expect_equal(nrow(long), 12L)
  expect_true(eco_check(long)$ok)
  back <- eco_to_ch(long)
  expect_equal(sum(back$freq), 3L)
  expect_setequal(back$ch, c("1011", "0101"))
})

test_that("eco_to_irw renames and converts dates", {
  d <- tapir[1:3, ]; d$date <- c("2014-06-01", "2014-06-01T12:30Z", "2014-06-01T12:30:15Z")
  v <- eco_to_irw(d)
  expect_true(all(c("id", "item", "resp", "cov_trapdays") %in% names(v)))
  expect_false(any(c("unit", "taxon", "y") %in% names(v)))
  expect_equal(v$date[1], as.integer(as.POSIXct("2014-06-01", tz = "UTC")))
  expect_equal(v$date[3] - v$date[2], 15L)
})

test_that("eco_to_irw folds trap into item", {
  scr <- data.frame(unit = c("a", "a", "b"), taxon = "RAT", y = c(0, 1, 0), trap = c("t1", "t2", "t1"),
                    period = 1L, occasion = 1L, stringsAsFactors = FALSE)
  v <- eco_to_irw(scr)
  expect_false("trap" %in% names(v))
  expect_equal(v$item, c("RAT:t1", "RAT:t2", "RAT:t1"))
  expect_false(anyDuplicated(v[, c("id", "item", "period", "occasion")]) > 0)
})

test_that("order_eco puts fixed columns first", {
  shuffled <- tapir[, rev(names(tapir))]
  expect_equal(names(order_eco(shuffled))[1:3], c("unit", "taxon", "y"))
})
