# Fits the constant occupancy model, occu(~1 ~1), to every repeated-visit detection table
# in output/ (count tables collapsed to y > 0), and colext(~1,~1,~1,~1) to three dynamic
# tables. One-off behind the artifact "Occupancy Across the Corpus" (2026-11-01).
# Run from the repo root: Rscript analysis/occupancy_corpus/fit_occ.R
# Writes occu_fits.csv and colext_fits.csv here. Delete those to refit.
suppressMessages({library(data.table); library(unmarked); library(jsonlite)})
source("Rpkg/R/convert.R")
SP <- "analysis/occupancy_corpus"
dict <- fread("dictionary/dictionary_auto.csv")
single <- c("kery_2008_willowtit_occ","smith_2019_greatbasin_csf_edna","smith_2019_greatbasin_csf_qpcr",
            "hamer_2024_hungary_amph_comm","galvez_2021_araucania_comm","malhotra_2021_loslagos_comm",
            "schank_2015_tapir_occ","tleimat_2023_ecuador_capuchin_occ",
            "kery_2005_mallard_count","kery_2014_mhb_comm")
fit_one <- function(tab, tx, d) {
  d <- copy(d); if (max(d$y) > 1) d[, y := as.integer(y > 0)]
  if (!"period" %in% names(d)) d[, period := 1L]
  d <- d[period == d[, min(period)]]
  umf <- eco_to_umf(d, "occu")
  y <- getY(umf); M <- nrow(y); J <- ncol(y)
  nvis <- rowSums(!is.na(y)); det_units <- sum(rowSums(y, na.rm = TRUE) > 0)
  naive <- det_units / M
  out <- data.table(table = tab, taxon = tx, n_units = M, n_occ = J, mean_visits = round(mean(nvis), 2),
                    n_det_units = det_units, naive = round(naive, 4), n_detections = sum(y, na.rm = TRUE))
  if (det_units == 0) { out[, c("psi","psi_se","p","p_se","status") := list(NA, NA, NA, NA, "no detections")]; return(out) }
  fm <- tryCatch(occu(~1 ~1, umf), error = function(e) NULL)
  if (is.null(fm)) { out[, c("psi","psi_se","p","p_se","status") := list(NA, NA, NA, NA, "fit error")]; return(out) }
  ps <- backTransform(fm, "state"); pd <- backTransform(fm, "det")
  psi <- coef(ps); psi_se <- SE(ps); p <- coef(pd); p_se <- SE(pd)
  status <- if (!is.finite(psi_se) || psi_se > 0.3 || psi > 0.995) "unstable" else "ok"
  out[, c("psi","psi_se","p","p_se","status") := list(round(psi, 4), round(psi_se, 4), round(p, 4), round(p_se, 4), status)]
  # p by occasion for J <= 8
  if (J <= 8 && status == "ok") {
    fmt <- tryCatch(occu(~ obsNum ~1, umf), error = function(e) NULL)
    if (!is.null(fmt)) { nd <- data.frame(obsNum = factor(seq_len(J) - 1, levels = seq_len(J) - 1))
      pr <- tryCatch(predict(fmt, type = "det", newdata = nd), error = function(e) NULL)
      if (!is.null(pr)) out[, p_by_occ := paste(round(pr$Predicted, 3), collapse = ";")]
      out[, aic_const := round(fm@AIC, 1)]; out[, aic_time := round(fmt@AIC, 1)] }
  }
  out
}
res <- list()
for (tab in if (file.exists(file.path(SP,"occu_fits.csv"))) character(0) else single) {
  x <- fread(sprintf("output/%s.csv", tab))
  taxa <- fread(sprintf("output/%s__taxa.csv", tab))
  for (tx in unique(x$taxon)) {
    r <- fit_one(tab, tx, x[taxon == tx])
    r[, sci := taxa[taxon == tx, scientificName][1]]
    r[, common := if ("vernacularName" %in% names(taxa)) taxa[taxon == tx, vernacularName][1] else NA_character_]
    res[[length(res) + 1]] <- r
  }
  cat(tab, ": done\n")
}
if (length(res)) { res <- rbindlist(res, fill = TRUE); res <- merge(res, dict[, .(table, description, reference)], by = "table", all.x = TRUE); fwrite(res, file.path(SP, "occu_fits.csv")) } else res <- fread(file.path(SP, "occu_fits.csv"))
# dynamic: colext on crossbill and marten
dyn <- list()
for (tab in c("kery_2010_crossbill_dynocc", "evans_2021_maine_marten_dynocc", "frimpong_2017_newriver_dynocc")) {
  x <- fread(sprintf("output/%s.csv", tab)); taxa <- fread(sprintf("output/%s__taxa.csv", tab))
  per <- fread(sprintf("output/%s__periods.csv", tab))
  txs <- unique(x$taxon)
  if (tab == "frimpong_2017_newriver_dynocc") { # pick 6 fish with mid-range naive occupancy
    nv <- x[, .(nv = mean(tapply(y, unit, max))), by = taxon]; txs <- nv[order(abs(nv - 0.5))][1:6, taxon] }
  for (tx in txs) {
    d <- x[taxon == tx]
    Tn <- max(d$period); Jm <- max(d[, .N, by = .(unit, period)]$N)
    units <- unique(d$unit); d[, occ := frank(occasion, ties.method = "dense"), by = .(unit, period)]
    y <- matrix(NA_real_, length(units), Tn * Jm)
    y[cbind(match(d$unit, units), (d$period - 1) * Jm + d$occ)] <- d$y
    umf <- unmarkedMultFrame(y = y, numPrimary = Tn)
    fm <- tryCatch(colext(~1, ~1, ~1, ~1, umf), error = function(e) NULL)
    if (is.null(fm)) next
    sm <- smoothed(fm)[2, ]  # occupied state
    pj <- projected(fm)[2, ]
    pe <- function(ty) { b <- backTransform(fm, ty); c(coef(b), SE(b)) }
    dyn[[length(dyn) + 1]] <- data.table(table = tab, taxon = tx, sci = taxa[taxon == tx, scientificName][1],
      n_units = numSites(umf), n_periods = umf@numPrimary, n_occ_per_period = ncol(getY(umf)) / umf@numPrimary,
      psi1 = pe("psi")[1], psi1_se = pe("psi")[2], gamma = pe("col")[1], gamma_se = pe("col")[2],
      eps = pe("ext")[1], eps_se = pe("ext")[2], p = pe("det")[1], p_se = pe("det")[2],
      period_labels = paste(per[[grep("label|year|name", names(per), value = TRUE, ignore.case = TRUE)[1]]], collapse = ";"),
      smoothed = paste(round(sm, 3), collapse = ";"),
      naive = paste(round(sapply(split(d, d$period), function(z) mean(tapply(z$y, z$unit, max))), 3), collapse = ";"))
  }
  cat(tab, ": done\n")
}
dyn <- rbindlist(dyn); fwrite(dyn, file.path(SP, "colext_fits.csv"))
print(res[, .N, by = .(table, status)]); print(dyn[, .(table, sci, psi1, gamma, eps, p)])
