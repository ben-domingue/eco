# Companion compute script for site/vignettes/traits.qmd.
#
# Collects a null-model detection probability, p-hat from occu(~1 ~1), for
# every bird and mammal species in the site-level detection tables of eco
# version 3. The sixteen tables already swept for the occupancy vignette are
# read from occupancy_data/occupancy_corpus.rds (built under eco v2; a released
# table never changes, so the fits stand). Eight tables added in v3 are fitted
# here with the same recipe: counts collapsed to detection (y > 0), multi-season
# tables reduced to their largest primary period, species never detected or
# with a median of fewer than two surveys per site skipped. No goodness-of-fit
# bootstrap, so this runs in a few minutes. Writes traits_data/traits_corpus.rds.
#
# Nothing from AVONET or COMBINE is written here: the vignette fetches the trait
# tables with eco_traits() when it renders.
#
# Run from site/vignettes/:   nice -n 15 Rscript traits_compute.R

suppressPackageStartupMessages({ library(eco); library(unmarked); library(data.table) })
eco_set_version(3)

tags <- as.data.table(eco_tags()); meta <- as.data.table(eco_metadata())

# Bird and mammal tables with a p-hat in the occupancy sweep.
occ <- readRDS("occupancy_data/occupancy_corpus.rds")
prior <- as.data.table(occ$fits)[taxon_group %in% c("Birds", "Mammals"),
  .(table, taxon, n_sites, J, naive, psi, p, p_se, converged, collapsed_from_count, period_used, fitted_in = "occupancy_corpus")]

# Site-level bird and mammal detection or count tables in v3 not in that sweep.
# Left out: rooney_2025_snapshotusa_comm (800 MB, over the 100 MB anonymous cap
# of the Redivis endpoint, so eco_fetch() refuses it); lindstrom_2025 (one
# occasion per period, psi and p not separable); feng_2021 and rich_2016
# (binomial_count, one row per site; expandable with binomial_to_history() but
# a constant-p expansion would only reproduce the naive rate); kleiven_2020
# (genus-level codes, co-occurrence design); capture-recapture and distance
# tables (the unit is an animal or a distance bin, not a site).
# whittington_2015 is attempted but yields nothing: most segments are walked
# once per winter, so every species fails the two-surveys-per-site rule.
new_tables <- c(
  "dettling_2021_marin_riparian_count", "doser_2022_hbef_trends_dynocc",
  "henry_2020_karoo_birds_comm", "kyaw_2024_myanmar_mamm_comm",
  "lebeuftaylor_2026_boreal_edges_aru_comm", "obrist_2024_gooseisland_birds_count",
  "sullivan_2026_powdermill_count", "whittington_2015_banff_tracks_comm")
stopifnot(all(new_tables %in% tags$table), !any(new_tables %in% prior$table))

fit_one <- function(long, table, taxon) {
  umf <- suppressMessages(eco_to_unmarked(long, family = "occu"))
  Y <- getY(umf)
  out <- data.table(table = table, taxon = taxon, n_sites = nrow(Y), J = median(rowSums(!is.na(Y))),
                    naive = mean(rowSums(Y, na.rm = TRUE) > 0),
                    psi = NA_real_, p = NA_real_, p_se = NA_real_, converged = FALSE)
  m <- tryCatch(occu(~1 ~1, umf), error = function(e) NULL)
  if (is.null(m)) return(out)
  se <- tryCatch(SE(m), error = function(e) NA_real_)
  bs <- backTransform(m, "state"); bd <- backTransform(m, "det")
  out[, `:=`(psi = coef(bs), p = coef(bd), converged = all(is.finite(se)))]
  if (out$converged) out[, p_se := SE(bd)]
  out
}

res <- list()
for (tb in new_tables) {
  d <- as.data.table(eco_fetch(tb))
  period_used <- NA_integer_
  if ("period" %in% names(d)) {
    period_used <- d[, .N, by = period][order(-N, period)]$period[1]
    d <- d[period == period_used]; d[, period := NULL]
  }
  collapsed <- any(d$y > 1)
  if (collapsed) d[, y := as.integer(y > 0)]
  d[, y := as.integer(y)]
  keep <- setdiff(names(d), grep("^(obs|unit|period)_", names(d), value = TRUE))
  d <- d[, keep, with = FALSE]
  for (tx in unique(d$taxon)) {
    s <- d[taxon == tx]
    if (sum(s$y) == 0) next
    if (median(s[, .N, by = unit]$N) < 2) next
    r <- fit_one(s, tb, tx)
    r[, `:=`(collapsed_from_count = collapsed, period_used = period_used, fitted_in = "traits_compute")]
    res[[length(res) + 1]] <- r
    cat(sprintf("%-40s %-10s n=%4d J=%3.0f naive=%.2f psi=%.2f p=%.2f\n", tb, tx, r$n_sites, r$J, r$naive, r$psi, r$p))
  }
}
fits <- rbind(prior, rbindlist(res), fill = TRUE)
fits <- merge(fits, tags[, .(table, taxon_group, sampling_protocol)], by = "table")
fits <- merge(fits, meta[, .(table, n_taxa, sample_floor)], by = "table")
setorder(fits, table, taxon)

dir.create("traits_data", showWarnings = FALSE)
saveRDS(list(fits = fits, date_run = Sys.Date(), eco_version = suppressMessages(eco_version()),
             occupancy_sweep_date = occ$date_run), "traits_data/traits_corpus.rds")
cat("wrote traits_data/traits_corpus.rds:", nrow(fits), "species fits in", uniqueN(fits$table), "tables\n")
