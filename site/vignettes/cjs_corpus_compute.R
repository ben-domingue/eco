# Companion compute script for site/vignettes/cjs.qmd, section
# "The same model across the corpus".
#
# Fits three Cormack-Jolly-Seber models with `marked` to every individual-level
# capture-history table in eco version 10 that is, or collapses to, one 0/1
# detection per individual per period:
#   phi(.) p(.)      constant survival and recapture
#   phi(.) p(t)      recapture free to vary by period (effort is never constant)
#   phi(tsm) p(t)    survival in the first interval after marking separate from
#                    later intervals (time since marking; Pradel et al. 1997),
#                    which absorbs transients and first-year mortality of
#                    animals marked young
# and runs the U-CARE goodness-of-fit tests (R2ucare::overall_CJS and its
# components 3.SR and 2.CT) on each history matrix. Writes
# cjs_data/cjs_corpus.rds, which the vignette reads instead of refitting (the
# IRW compute-cache pattern, as in occupancy_corpus_compute.R).
#
# How a table becomes a history matrix (the same rules the vignette states):
#   - Tables with an `occasion` column (robust design, or the Volzke seals'
#     breeding/other split) are collapsed to the period: y = 1 if the animal was
#     detected on any occasion of that period.
#   - Rows before an animal's first detection are dropped: CJS conditions on
#     first capture. Animals never detected (none, in these tables) would be dropped.
#   - A cell after first capture with no row means the animal was not at risk
#     (standard E4.4: a gap, mark lost, removed). It enters the history as "0"
#     with p fixed at 0 for that animal and period, so it says nothing about
#     survival or detection; GOF tests, which cannot take a fixed p, read it as 0.
#   - The time between periods comes from __periods (years, months, dates or
#     days, see `intervals()`), and marked raises phi to that power, so phi is
#     per year for multi-year studies and per day for the two within-season
#     butterfly and damselfly studies.
#
# Run from site/vignettes/:   nice -n 15 Rscript cjs_corpus_compute.R
# Takes about 25 minutes, most of it the brant, grass snake and two Macquarie
# elephant seal tables.

suppressPackageStartupMessages({
  library(eco); library(data.table); library(marked); library(R2ucare)
})
eco_set_version(10)

# Left out, with the reason:
#   multistate tables (banik, chabanne, curtis, deprengerlevin, hollanders, leith,
#     mcknight, symons femalecalf): built for multistate models; collapsing the
#     state to "seen" discards what they are for.
#   cleavitt_2017_hbef_*: plant dormancy is a state in which an alive plant cannot
#     be seen, which breaks CJS's equal-catchability assumption.
#   moe_2020_hunder_trout_ld: live recaptures mixed with dead recoveries.
#   neon_2026_*_rd: periods are site x bout across hundreds of sites; a per-site
#     analysis, not one model per table.
#   SCR and oSCR tables: spatial, and their periods are closed sessions.
tables <- c(
  "lebreton_1992_dipper_cjs", "ancona_2016_isabel_booby_cjs", "toledolima_2024_elaenia_cjs",
  "riecke_2018_tutakoke_brant_rd",
  "hastings_2018_seak_sealion_cjs", "schleimer_2019_gsl_finwhale_cjs",
  "volzke_2021_macquarie_seal1950s_cjs", "volzke_2021_macquarie_seal1990s_cjs",
  "oosthuizen_2019_marion_seal_rd",
  "arsocivil_2019_scotland_dolphin_rd", "arsocivil_2019_scotland_dolphincalf_cjs",
  "symons_2018_bunbury_dolphin_rd",
  "karvemo_2024_nacka_grasssnake_cjs", "tetzlaff_2026_crotalus_cjs", "cecala_2026_kiawah_terrapin_cjs",
  "valenzuela_2018_neltume_rhidar_rd",
  "kanno_2022_bluehead_chub_cjs", "kanno_2022_creek_chub_cjs", "kanno_2022_mottled_sculpin_cjs",
  "fabritius_2015_merikarvia_fritillary_cjs", "fabritius_2015_siitama_fritillary_cjs",
  "fabritius_2015_sorila_fritillary_cjs", "khelifa_2021_seybouse_calexul_cjs",
  "martinezvillegas_2024_castilleja_cjs", "martinezvillegas_2024_flaveria_cjs",
  "martinezvillegas_2024_govenia_cjs", "martinezvillegas_2024_mammillaria_cjs",
  "martinezvillegas_2024_neobuxbaumia_cjs")

# Time between consecutive periods, from each table's __periods, and its unit.
intervals <- function(tb, per) {
  per <- as.data.table(per)[order(period)]
  if (tb == "tetzlaff_2026_crotalus_cjs") {
    # the authors' MARK time intervals, deposited per period
    iv <- per$interval_to_next_yr[-nrow(per)]; stopifnot(!anyNA(iv))
    return(list(iv = iv, unit = "year"))
  }
  if (grepl("^kanno_", tb)) return(list(iv = diff(per$year * 12 + per$month) / 12, unit = "year"))
  if (grepl("^symons_", tb)) {
    mid <- (as.numeric(as.Date(per$period_start)) + as.numeric(as.Date(per$period_end))) / 2
    return(list(iv = diff(mid) / 365.25, unit = "year"))
  }
  if (grepl("^valenzuela_", tb)) return(list(iv = diff(per$months_after_first_primary) / 12, unit = "year"))
  if (grepl("^martinezvillegas_", tb)) return(list(iv = rep(1, nrow(per) - 1), unit = "year"))  # annual census, years not deposited
  if (grepl("^fabritius_", tb)) return(list(iv = diff(per$period), unit = "day"))  # period is the search-day number
  if (grepl("^khelifa_", tb)) return(list(iv = diff(per$julian_day), unit = "day"))
  if (grepl("^toledolima_", tb)) return(list(iv = rep(1, nrow(per) - 1), unit = "session"))  # session dates not deposited
  stopifnot("year" %in% names(per))
  list(iv = diff(per$year), unit = "year")
}

# Long eco table -> history matrix (NA = not at risk) in period order.
to_matrix <- function(d) {
  if ("occasion" %in% names(d)) d <- d[, .(y = as.integer(max(y))), by = .(unit, period)]
  P <- sort(unique(d$period))
  units <- sort(unique(d$unit))
  M <- matrix(NA_integer_, length(units), length(P), dimnames = list(units, P))
  M[cbind(match(d$unit, units), match(d$period, P))] <- as.integer(d$y)
  first <- apply(M, 1, function(r) { w <- which(r == 1L); if (length(w)) w[1] else NA_integer_ })
  M <- M[!is.na(first), , drop = FALSE]; first <- first[!is.na(first)]
  # before first capture: irrelevant to CJS, written as 0
  for (i in which(first > 1)) M[i, seq_len(first[i] - 1)] <- 0L
  list(M = M, first = first, periods = P)
}

# Naive survival: treat an animal as dead after its last sighting. Per interval,
# the share of animals known alive at t (first <= t <= last) still known alive at
# t + 1, raised to 1 / interval length, then averaged with weights = known alive.
naive_phi <- function(M, iv) {
  seen <- !is.na(M) & M == 1L
  first <- apply(seen, 1, function(r) which(r)[1]); last <- apply(seen, 1, function(r) max(which(r)))
  K <- ncol(M); s <- n <- numeric(K - 1)
  for (t in seq_len(K - 1)) {
    ka <- first <= t & last >= t
    n[t] <- sum(ka); s[t] <- if (n[t]) (sum(ka & last >= t + 1) / n[t])^(1 / iv[t]) else NA
  }
  ok <- n > 0
  sum(s[ok] * n[ok]) / sum(n[ok])
}

fit_table <- function(tb) {
  d <- as.data.table(eco_fetch(tb))
  per <- eco_periods(tb)
  h <- to_matrix(d)
  M <- h$M
  ivl <- intervals(tb, per)
  stopifnot(length(ivl$iv) == ncol(M) - 1, all(ivl$iv > 0))
  n_gap <- sum(is.na(M))
  Mz <- M; Mz[is.na(Mz)] <- 0L
  ch <- apply(Mz, 1, paste, collapse = "")
  x <- data.frame(ch = ch, stringsAsFactors = FALSE)
  # With not-at-risk cells, p is fixed per animal, so histories cannot be pooled.
  pr <- process.data(x, model = "CJS", time.intervals = ivl$iv, accumulate = n_gap == 0)
  ddl <- make.design.data(pr)
  if (n_gap) {
    na_cells <- which(is.na(M), arr.ind = TRUE)   # (animal, period column)
    key <- paste(as.integer(as.character(ddl$p$id)), ddl$p$occ)
    hit <- key %in% paste(na_cells[, 1], na_cells[, 2])
    ddl$p$fix[hit] <- 0
  }
  ddl$Phi$tsm <- factor(ifelse(ddl$Phi$Age == 0, "first", "later"), levels = c("later", "first"))
  # p(t): a period in which no animal is free to be recaptured has no data;
  # pool it with the first period that has some, so the model stays identified.
  free <- is.na(ddl$p$fix) | ddl$p$fix != 0
  tt <- as.character(ddl$p$time)
  ok_t <- unique(tt[free])
  tt[!tt %in% ok_t] <- ok_t[1]
  ddl$p$tt <- factor(tt)

  fit <- function(phi, p) {
    m <- tryCatch(suppressMessages(suppressWarnings(capture.output(
      r <- crm(pr, ddl, model.parameters = list(Phi = list(formula = phi), p = list(formula = p)),
               hessian = TRUE, accumulate = FALSE)))), error = function(e) NULL)
    if (is.null(m)) return(NULL)
    r
  }
  m_a <- fit(~1, ~1); m_b <- fit(~1, ~tt); m_c <- fit(~tsm, ~tt)

  # A real parameter (intercept, or intercept + one level) and its delta-method SE.
  est <- function(m, par = "Phi", lev = NULL) {
    if (is.null(m)) return(c(NA_real_, NA_real_))
    b <- m$results$beta[[par]]; v <- m$results$beta.vcv
    nm <- paste0(par, ".", names(b))
    w <- setNames(numeric(length(b)), nm); w[1] <- 1
    if (!is.null(lev)) w[paste0(par, ".", lev)] <- 1
    eta <- sum(w * b)
    se <- if (is.null(v)) NA_real_ else sqrt(drop(t(w) %*% v[nm, nm, drop = FALSE] %*% w))
    c(plogis(eta), se * plogis(eta) * (1 - plogis(eta)))
  }
  ok_se <- function(m) !is.null(m) && !is.null(m$results$beta.vcv) && all(is.finite(diag(m$results$beta.vcv))) &&
    all(diag(m$results$beta.vcv) > 0)
  pa <- est(m_a); pa_p <- est(m_a, "p")
  pc_later <- est(m_c); pc_first <- est(m_c, "Phi", "tsmfirst")
  p_c <- if (!is.null(m_c)) { pp <- predict(m_c)$p; median(pp$estimate) } else NA

  # U-CARE tests on the full 0/1 matrix (not-at-risk cells read as 0).
  freq <- rep(1, nrow(Mz))
  g <- tryCatch(suppressWarnings(overall_CJS(Mz, freq)), error = function(e) NULL)
  t3 <- tryCatch(suppressWarnings(test3sr(Mz, freq)), error = function(e) NULL)
  t2 <- tryCatch(suppressWarnings(test2ct(Mz, freq)), error = function(e) NULL)

  data.table(
    table = tb, taxon = d$taxon[1], n_ind = nrow(M), n_periods = ncol(M),
    n_captures = sum(M == 1L, na.rm = TRUE), n_gap_cells = n_gap,
    collapsed = "occasion" %in% names(d),
    interval_unit = ivl$unit, span = sum(ivl$iv), median_interval = median(ivl$iv),
    naive_phi = naive_phi(M, ivl$iv),
    phi_a = pa[1], phi_a_se = pa[2], p_a = pa_p[1], p_a_se = pa_p[2],
    phi_later = pc_later[1], phi_later_se = pc_later[2],
    phi_first = pc_first[1], phi_first_se = pc_first[2], p_c_median = p_c,
    aic_a = if (!is.null(m_a)) m_a$results$AIC else NA,
    aic_b = if (!is.null(m_b)) m_b$results$AIC else NA,
    aic_c = if (!is.null(m_c)) m_c$results$AIC else NA,
    se_ok_a = ok_se(m_a), se_ok_c = ok_se(m_c),
    gof_chi2 = if (!is.null(g)) g$chi2 else NA, gof_df = if (!is.null(g)) g$degree_of_freedom else NA,
    gof_p = if (!is.null(g)) g$p_value else NA,
    t3sr_z = if (!is.null(t3)) t3$test3sr[["sign_test"]] else NA,
    t3sr_p = if (!is.null(t3)) t3$test3sr[["p_val"]] else NA,
    t2ct_z = if (!is.null(t2)) t2$test2ct[["sign_test"]] else NA,
    t2ct_p = if (!is.null(t2)) t2$test2ct[["p_val"]] else NA)
}

res <- list()
for (tb in tables) {
  t0 <- Sys.time()
  r <- fit_table(tb)
  res[[tb]] <- r
  cat(sprintf("%-42s n=%6d K=%2d %-7s naive=%.2f phi.=%.2f p.=%.2f phi_later=%.2f phi_first=%.2f dAIC(c-a)=%.0f chat=%.2f  %.0fs\n",
              tb, r$n_ind, r$n_periods, r$interval_unit, r$naive_phi, r$phi_a, r$p_a, r$phi_later, r$phi_first,
              r$aic_c - r$aic_a, r$gof_chi2 / r$gof_df, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
res <- rbindlist(res)
tags <- as.data.table(eco_tags())
taxa <- rbindlist(lapply(tables, function(tb) {
  x <- as.data.table(eco_taxa(tb)); data.table(table = tb, scientificName = x$scientificName[1])
}))
res <- merge(res, taxa, by = "table")
res <- merge(res, tags[, .(table, taxon_group)], by = "table", all.x = TRUE)

dir.create("cjs_data", showWarnings = FALSE)
saveRDS(list(fits = res, date_run = Sys.Date(), eco_version = suppressMessages(eco_version())),
        "cjs_data/cjs_corpus.rds")
cat("wrote cjs_data/cjs_corpus.rds:", nrow(res), "tables\n")
