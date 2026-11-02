# Companion compute script for site/vignettes/occupancy.qmd, section
# "The same model across the corpus".
#
# Fits the null single-season occupancy model, occu(~1 ~1), to every species in
# every site-level detection table in eco version 2, one species at a time, and
# runs the MacKenzie-Bailey goodness-of-fit test on each fit. Count tables are
# collapsed to detection (y > 0); multi-season tables contribute one primary
# period (see below). Writes occupancy_data/occupancy_corpus.rds, which the
# vignette reads instead of refitting (the IRW compute-cache pattern).
#
# Run from site/vignettes/:   nice -n 15 Rscript occupancy_corpus_compute.R
# (mb.gof.test parallelises the bootstrap over every core, so nice it)
# Takes about twenty minutes, most of it the bootstrap.

suppressPackageStartupMessages({
  library(eco); library(unmarked); library(AICcmodavg); library(data.table)
})
eco_set_version(2)
NSIM <- 100
set.seed(2026)

# Site-level tables whose y is a detection, or a count collapsed to one.
# Left out, with the reason: kleiven_2020_varanger_dynocc (two spatial scales and
# 304 occasions, a co-occurrence design); smith_2019_greatbasin_* (multi-scale eDNA,
# the unit is not the site the model wants); uherkoch (multi-state y);
# multinomial_cell and ordinal tables (not detection histories).
tables <- c(
  "addis_2026_rmap_bt_dynocc", "addis_2026_rmap_mbrt_dynocc",
  "evans_2021_maine_marten_dynocc", "frimpong_2017_newriver_dynocc",
  "galvez_2021_araucania_comm", "glorioso_2025_atchafalaya_ves",
  "hamer_2024_hungary_amph_comm", "kery_2005_mallard_count",
  "kery_2008_willowtit_occ", "kery_2010_crossbill_dynocc", "kery_2014_mhb_comm",
  "malhotra_2021_loslagos_comm", "margenau_2021_rowsongbirds_nmix",
  "mctigue_2023_nwarkansas_comm", "palacio_2020_pampasbirds_comm",
  "schank_2015_tapir_occ", "tleimat_2023_ecuador_capuchin_occ")

meta <- as.data.table(eco_metadata())
tags <- as.data.table(eco_tags())

fit_one <- function(long, table, taxon) {
  umf <- suppressMessages(eco_to_unmarked(long, family = "occu"))
  Y <- getY(umf)
  n_sites <- nrow(Y); J <- median(rowSums(!is.na(Y)))
  naive <- mean(rowSums(Y, na.rm = TRUE) > 0)
  out <- data.table(table = table, taxon = taxon, n_sites = n_sites, J = J, naive = naive,
                    psi = NA_real_, psi_se = NA_real_, p = NA_real_, p_se = NA_real_,
                    chisq = NA_real_, gof_p = NA_real_, c_hat = NA_real_, converged = FALSE)
  m <- tryCatch(occu(~1 ~1, umf), error = function(e) NULL)
  if (is.null(m)) return(out)
  # A singular Hessian (a boundary fit) makes SE() error rather than return NA.
  se <- tryCatch(SE(m), error = function(e) NA_real_)
  bs <- backTransform(m, "state"); bd <- backTransform(m, "det")
  out[, `:=`(psi = coef(bs), p = coef(bd), converged = all(is.finite(se)))]
  if (!out$converged) return(out)
  out[, `:=`(psi_se = SE(bs), p_se = SE(bd))]
  # Boundary fits (psi -> 1 or p -> 0) make the bootstrap meaningless; skip it there.
  if (out$psi < 0.995 && out$p > 0.005 && naive < 1) {
    g <- tryCatch(suppressWarnings(mb.gof.test(m, nsim = NSIM, plot.hist = FALSE)), error = function(e) NULL)
    if (!is.null(g)) out[, `:=`(chisq = g$chi.square, gof_p = g$p.value, c_hat = g$c.hat.est)]
  }
  out
}

res <- list()
for (tb in tables) {
  d <- as.data.table(eco_fetch(tb))
  period_used <- NA_integer_
  if ("period" %in% names(d)) {
    period_used <- d[, .N, by = period][order(-N, period)]$period[1]
    d <- d[period == period_used]; d[, period := NULL]
  }
  collapsed <- any(d$y > 1)
  if (collapsed) d[, y := as.integer(y > 0)]
  d[, y := as.integer(y)]
  for (tx in unique(d$taxon)) {
    s <- d[taxon == tx]
    if (sum(s$y) == 0) next                       # never detected in this period: nothing to fit
    if (median(s[, .N, by = unit]$N) < 2) next     # one survey per site: psi and p are not separable
    r <- fit_one(s, tb, tx)
    r[, `:=`(collapsed_from_count = collapsed, period_used = period_used)]
    res[[length(res) + 1]] <- r
    cat(sprintf("%-34s %-10s n=%3d J=%4.0f naive=%.2f psi=%.2f p=%.2f chat=%s\n", tb, tx, r$n_sites, r$J,
                r$naive, r$psi, r$p, if (is.na(r$c_hat)) "-" else sprintf("%.1f", r$c_hat)))
  }
}
res <- rbindlist(res)
res <- merge(res, meta[, .(table, sample_floor)], by = "table")
res <- merge(res, tags[, .(table, taxon_group, model_family)], by = "table")
setorder(res, table, taxon)

dir.create("occupancy_data", showWarnings = FALSE)
saveRDS(list(fits = res, nsim = NSIM, date_run = Sys.Date(),
             eco_version = suppressMessages(eco_version())),
        "occupancy_data/occupancy_corpus.rds")
cat("wrote occupancy_data/occupancy_corpus.rds:", nrow(res), "species fits in", uniqueN(res$table), "tables\n")
