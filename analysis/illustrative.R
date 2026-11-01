# Illustrative analysis across the built tables: per species (taxon), naive occupancy
# (share of units with >= 1 detection) vs. a single-season occupancy estimate
# (unmarked::occu, psi ~ 1, p ~ 1), plus per-survey detection probability.
# Species are the "taxa": p is the taxon's detectability, psi the latent-state prevalence.
# Writes analysis/species_estimates.csv.
suppressPackageStartupMessages({ library(data.table); library(unmarked) })
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
tabs <- c("malhotra_2021_loslagos_comm", "schank_2015_tapir_occ", "palacio_2020_pampasbirds_comm",
          "frimpong_2017_newriver_dynocc", "uherkoch_2021_npraloon_dynocc", "toledolima_2024_elaenia_cjs")
out <- list()
for (t in tabs) {
  d <- fread(file.path(OUT_DIR, paste0(t, ".csv")))
  if (!"period" %in% names(d)) d[, period := 1L]
  if (!"occasion" %in% names(d)) d[, occasion := 1L]
  d[, det := as.integer(y > 0)]
  # one closed "season" per table for the illustration: first period only for multi-period data,
  # except the CJS table (individuals as units; p here is recapture probability given alive, so skip occu)
  dd <- if (t == "toledolima_2024_elaenia_cjs") d else d[period == min(period)]
  for (sp in unique(dd$taxon)) {
    s <- dd[taxon == sp]
    naive <- s[, .(any = max(det)), by = unit][, mean(any)]
    prate <- s[, mean(det)]
    psi <- p <- NA_real_
    if (t != "toledolima_2024_elaenia_cjs" && uniqueN(s$occasion) > 1 && sum(s$det) > 0 && naive < 1) {
      y <- eco_to_array(s[, .(unit, taxon, y = det, occasion)])$y
      fit <- try(occu(~1 ~1, unmarkedFrameOccu(y = y)), silent = TRUE)
      if (!inherits(fit, "try-error")) { psi <- plogis(coef(fit)[1]); p <- plogis(coef(fit)[2]) }
    }
    out[[length(out) + 1]] <- data.table(table = t, taxon = sp, n_units = uniqueN(s$unit), n_surveys = nrow(s),
                                         n_detections = sum(s$det), naive_occ = naive, det_rate = prate, psi = psi, p = p)
  }
}
res <- rbindlist(out)
res <- res[!is.na(psi) | table == "toledolima_2024_elaenia_cjs"]
fwrite(res, "analysis/species_estimates.csv")
print(res[, .(species = .N, median_naive = round(median(naive_occ), 2), median_psi = round(median(psi, na.rm = TRUE), 2),
              median_p = round(median(p, na.rm = TRUE), 2)), by = table])
cat(sprintf("\n%d species with occupancy estimates; psi > naive for %d of them\n", sum(!is.na(res$psi)), sum(res$psi > res$naive_occ, na.rm = TRUE)))
