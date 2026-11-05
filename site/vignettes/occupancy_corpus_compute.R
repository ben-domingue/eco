# Companion compute script for site/vignettes/occupancy.qmd, section
# "The same model across the corpus".
#
# Fits the null single-season occupancy model, occu(~1 ~1), to every species in
# every site-level detection or count table in eco version ECO_VERSION, one
# species at a time, and runs the MacKenzie-Bailey goodness-of-fit test on each
# fit. In the tables whose effort column is mapped below it then fits
# psi(.) p(effort), with effort as standardised log effort (or the
# already-standardised survey intensity of the two Kery tables), on the surveys
# that have an effort value. Count tables are collapsed to detection (y > 0);
# multi-season tables contribute one primary period (see below). Writes
# occupancy_data/occupancy_corpus.rds, which the vignette reads instead of
# refitting (the IRW compute-cache pattern).
#
# The tables are chosen by rule from eco_metadata() and eco_tags(), not listed by
# name: see select_tables(). Designs the model does not fit are excluded by name,
# each with its reason, and tables that cannot be fetched anonymously are skipped
# with theirs; both lists are saved in the .rds so the vignette can print them.
#
# Run from site/vignettes/:
#   Rscript occupancy_corpus_compute.R --list       # print the corpus and stop
#   nice -n 15 Rscript occupancy_corpus_compute.R   # fit it
#   add --big to include the tables over 100 MB (needs a Redivis login)
# (mb.gof.test parallelises the bootstrap over every core, so nice it)

suppressPackageStartupMessages({
  library(eco); library(unmarked); library(AICcmodavg); library(data.table)
})
ECO_VERSION <- 10
eco_set_version(ECO_VERSION)
LIST_ONLY <- "--list" %in% commandArgs(trailingOnly = TRUE)
# Tables over the anonymous cap are held back unless --big is given: they take
# several GB of RAM each and a Redivis login, and the sweep starts without them.
INCLUDE_BIG <- "--big" %in% commandArgs(trailingOnly = TRUE)
NSIM <- 100
set.seed(2026)

# Designs the single-season site model does not describe, excluded by name. The
# rule in select_tables() lets them through because their y is a detection at a
# site with replicate occasions; the replicates are not what the model assumes.
excluded <- c(
  kleiven_2020_varanger_dynocc       = "two spatial scales and 304 occasions; a co-occurrence design",
  chambert_2018_plethodon_fpocc      = "two species with misidentification; needs a false-positive model",
  smith_2019_greatbasin_csf_edna     = "multi-scale eDNA (watershed > site > sample); the unit is not the site the model wants",
  smith_2019_greatbasin_csf_qpcr     = "multi-scale eDNA with false positives (site > sample > qPCR replicate)",
  allen_2021_nj_lanternfly_edna      = "multi-scale eDNA qPCR with a paired visual survey",
  dougherty_2016_rustycrayfish_edna  = "multi-scale eDNA qPCR with trap; occasions mix methods",
  lafferty_2024_tidewatergoby_edna   = "multi-scale, multi-method eDNA (qPCR and metabarcoding)",
  sandercock_2022_norway_insects_edna = "multi-scale eDNA metabarcoding",
  tomke_2025_hellbender_edna         = "multi-scale eDNA (site > filter > qPCR replicate)",
  swedberg_2023_springfish_occ       = "multi-scale (reach > site > survey) with two gears",
  whittington_2015_banff_tracks_comm = "multi-scale (cell > segment > repeat walk) with Markovian detection",
  ziolkowski_2026_bbs_count          = "18 GB, 110 M rows; too large for a per-species sweep (the BCR 15 pilots stand in for BBS)")

# Site-level tables whose y is a detection, or a count (or binomial count)
# collapsed to one, with replicate occasions. Response types left out by the rule:
# state (multi-state y), multinomial_cell and ordinal (not detection histories),
# detection_event; unit_kind individual (capture histories). `_exact` siblings
# repeat their coarsened table at finer coordinates (E7.3) and are dropped.
select_tables <- function() {
  meta <- as.data.table(eco_metadata())
  tags <- as.data.table(eco_tags())
  sizes <- as.data.table(eco_list_tables())[, .(table, bytes, needs_login)]
  d <- merge(merge(meta, tags[, .(table, taxon_group, model_family)], by = "table"), sizes, by = "table", all.x = TRUE)
  d <- d[unit_kind == "site" & response_type %in% c("detection", "count", "binomial_count") &
           n_occasions >= 2 & !grepl("_exact", table)]
  d[, status := "fit"][, reason := ""]
  d[table %in% names(excluded), `:=`(status = "excluded", reason = excluded[table])]
  # Tables over Redivis's 100 MB anonymous cap need a Redivis login (eco_fetch()
  # uses it when the redivis and arrow packages and credentials are present).
  # Without one they are skipped, with the reason eco_fetch() would give.
  d[, login := needs_login %in% TRUE]
  if (!INCLUDE_BIG)
    d[status == "fit" & login, `:=`(status = "skipped",
                                    reason = sprintf("%.0f MiB; large tables held back for now (run with --big)", bytes / 2^20))]
  for (i in which(d$status == "fit" & d$login)) {
    why <- eco:::.eco_auth_problem(d$table[i], d$bytes[i])
    if (!is.null(why)) d[i, `:=`(status = "skipped", reason = sprintf("%.0f MiB; needs a Redivis login: %s",
                                                                        bytes / 2^20, sub("\n.*", "", why)))]
  }
  stopifnot(all(names(excluded) %in% d$table))   # an excluded table renamed or withdrawn: fix the list
  setorder(d, status, table)
  d
}
effort_col <- c(
  galvez_2021_araucania_comm = "obs_camera_nights", mctigue_2023_nwarkansas_comm = "obs_camera_days",
  glorioso_2025_atchafalaya_ves = "obs_duration_min", hamer_2024_hungary_amph_comm = "obs_effort_ves_min",
  kery_2014_mhb_comm = "obs_dur_min", kery_2008_willowtit_occ = "obs_ivel_std",
  kery_2005_mallard_count = "obs_ivel_std", malhotra_2021_loslagos_comm = "unit_trapnights",
  schank_2015_tapir_occ = "unit_trapdays",
  # added for eco v10; each is the table's effortColumn in its __dataset.json
  bradferlawrence_2025_ukwood_beetle_comm = "obs_n_traps",      # pitfall traps per visit, 6-15
  clipp_2024_monongahela_comm = "obs_camera_hours",             # camera hours per day-occasion, 4-24
  clipp_2024_wvprivate_comm = "obs_camera_hours",               # camera hours per day-occasion, 4-24
  frimpong_2017_newriver_dynocc = "obs_effort",                 # fish collections per HUC-year, 1-30
  hartley_2024_cpraealtus_occ = "obs_tiles_available",          # cover tiles available per check, 1-10
  hepler_2018_serengeti_gazelle_occ = "obs_camera_days",        # camera days per 8-day occasion, 1-8
  kyaw_2024_myanmar_mamm_comm = "obs_camera_days",              # camera days per occasion, 0.5-10
  maihoff_2023_berchtesgaden_bees_count = "obs_n_days",         # sampling days per visit, 1 or 2 only
  nowicki_2019_sharkbay_count = "obs_transect_km",              # transect length, 1.9-4.5 km
  smith_2024_florida_tegu_dynocc = "obs_camera_days")           # camera days per occasion, 0.5-14

# Tables the metadata flags as having effort that get no effort fit, and why.
no_effort <- c(
  boone_2023_minnesota_bombus_count = "obs_survey_minutes is 60 at every survey; no variation to fit",
  doser_2022_hbef_trends_dynocc = "no effort column; has_effort matched obs_time_of_day_min, a time of day",
  teitsworth_2026_necturus_dynocc = "no effort column; one overnight trap check per occasion (obs_bait_age_days is not effort)")

meta <- as.data.table(eco_metadata())
tags <- as.data.table(eco_tags())

corpus_tables <- select_tables()
tables <- corpus_tables[status == "fit", table]
stopifnot(all(names(effort_col) %in% tables))   # a mapped effort table dropped out: fix the map
corpus_tables[, effort := fifelse(table %in% names(effort_col), "mapped",
                          fifelse(table %in% names(no_effort), "none",
                                  fifelse(has_effort %in% c(TRUE, "TRUE", "True"), "unmapped", "")))]
corpus_tables[effort == "none", reason := no_effort[table]]

cat(sprintf("eco v%d: %d tables pass the rule; %d to fit, %d excluded, %d skipped\n", ECO_VERSION,
            nrow(corpus_tables), length(tables), sum(corpus_tables$status == "excluded"),
            sum(corpus_tables$status == "skipped")))
cat(sep = "", sprintf("to fit: up to %d species (n_taxa summed; never-detected species drop out at fit time); ",
            sum(corpus_tables[status == "fit", n_taxa])),
    sprintf("effort mapped in %d, recorded but unmapped in %d",
            sum(corpus_tables[status == "fit", effort == "mapped"]),
            sum(corpus_tables[status == "fit", effort == "unmapped"])),
    sprintf("; no usable effort in %d\n\n", sum(corpus_tables[status == "fit", effort == "none"])))
options(width = 200, max.print = 1e5)
print(corpus_tables[status == "fit", .(table, response_type, taxon_group, n_units, n_taxa, n_periods,
                                       n_occasions, MiB = round(bytes / 2^20, 1), login, effort)],
      nrows = Inf, class = FALSE, row.names = FALSE)
cat("\n")
print(corpus_tables[status != "fit" | effort == "none", .(status, effort, table, reason)],
      nrows = Inf, class = FALSE, row.names = FALSE)
if (LIST_ONLY) quit(save = "no")

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

# psi(.) p(effort) against psi(.) p(.) on the same surveys. `long` carries
# obs_effort_std and only rows where it is known.
fit_effort <- function(long, table, taxon) {
  umf <- suppressMessages(eco_to_unmarked(long, family = "occu"))
  out <- data.table(table = table, taxon = taxon, n_surveys = nrow(long),
                    slope = NA_real_, slope_se = NA_real_, p_at_mean = NA_real_,
                    aic_null = NA_real_, aic_effort = NA_real_, c_hat_effort = NA_real_, converged = FALSE)
  m0 <- tryCatch(occu(~1 ~1, umf), error = function(e) NULL)
  m1 <- tryCatch(occu(~effort_std ~1, umf), error = function(e) NULL)
  if (is.null(m0) || is.null(m1)) return(out)
  se <- tryCatch(SE(m1), error = function(e) NA_real_)
  if (!all(is.finite(se))) return(out)
  cf <- coef(m1)
  out[, `:=`(slope = cf[["p(effort_std)"]], slope_se = se[["p(effort_std)"]],
             p_at_mean = plogis(cf[["p(Int)"]]), aic_null = m0@AIC, aic_effort = m1@AIC, converged = TRUE)]
  J <- median(rowSums(!is.na(getY(umf))))
  psi1 <- plogis(cf[["psi(Int)"]])
  if (J <= 10 && psi1 < 0.995 && psi1 > 0.005 && out$p_at_mean > 0.005) {
    g <- tryCatch(suppressWarnings(mb.gof.test(m1, nsim = NSIM, plot.hist = FALSE)), error = function(e) NULL)
    if (!is.null(g)) out[, c_hat_effort := g$c.hat.est]
  }
  out
}

res <- list(); res_effort <- list()
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
  has_effort <- tb %in% names(effort_col)
  if (has_effort) {
    e <- d[[effort_col[[tb]]]]
    if (effort_col[[tb]] != "obs_ivel_std") { stopifnot(all(e[!is.na(e)] > 0)); e <- log(e) }
    d[, obs_effort_std := as.numeric(scale(e))]
  }
  for (tx in unique(d$taxon)) {
    s <- d[taxon == tx]
    if (sum(s$y) == 0) next                       # never detected in this period: nothing to fit
    if (median(s[, .N, by = unit]$N) < 2) next     # one survey per site: psi and p are not separable
    r <- fit_one(s, tb, tx)
    r[, `:=`(collapsed_from_count = collapsed, period_used = period_used)]
    res[[length(res) + 1]] <- r
    if (has_effort) {
      se_ <- s[!is.na(obs_effort_std)]
      keep <- setdiff(names(se_), grep("^(obs|unit)_", names(se_), value = TRUE))
      se_ <- se_[, c(keep, "obs_effort_std"), with = FALSE]
      if (sum(se_$y) > 0 && median(se_[, .N, by = unit]$N) >= 2) {
        re <- fit_effort(se_, tb, tx)
        re[, effort_variable := effort_col[[tb]]]
        res_effort[[length(res_effort) + 1]] <- re
      }
    }
    cat(sprintf("%-34s %-10s n=%3d J=%4.0f naive=%.2f psi=%.2f p=%.2f chat=%s\n", tb, tx, r$n_sites, r$J,
                r$naive, r$psi, r$p, if (is.na(r$c_hat)) "-" else sprintf("%.1f", r$c_hat)))
  }
}
res <- rbindlist(res)
res <- merge(res, meta[, .(table, sample_floor)], by = "table")
res <- merge(res, tags[, .(table, taxon_group, model_family)], by = "table")
setorder(res, table, taxon)

dir.create("occupancy_data", showWarnings = FALSE)
effort <- rbindlist(res_effort)
saveRDS(list(fits = res, effort = effort, corpus_tables = corpus_tables, nsim = NSIM, date_run = Sys.Date(),
             eco_version = suppressMessages(eco_version())),
        "occupancy_data/occupancy_corpus.rds")
cat("wrote occupancy_data/occupancy_corpus.rds:", nrow(res), "species fits in", uniqueN(res$table), "tables;",
    nrow(effort), "effort fits in", uniqueN(effort$table), "tables\n")
