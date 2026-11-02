# Assembles occ_data.json from the two fit CSVs and inlines it into
# occupancy_template.html to produce occupancy_corpus.html, the file published as
# the artifact. Run from the repo root after fit_occ.R.
suppressMessages({library(data.table); library(jsonlite)})
SP <- "analysis/occupancy_corpus"

r <- fread(file.path(SP,"occu_fits.csv")); d <- fread(file.path(SP,"colext_fits.csv"))
dict <- fread("dictionary/dictionary_auto.csv")
short <- c(kery_2008_willowtit_occ="Swiss MHB willow tit", smith_2019_greatbasin_csf_edna="Great Basin frog eDNA (filter samples)", smith_2019_greatbasin_csf_qpcr="Great Basin frog eDNA (qPCR replicates)", hamer_2024_hungary_amph_comm="Hungarian pond amphibians", galvez_2021_araucania_comm="Araucanía camera traps", malhotra_2021_loslagos_comm="Los Lagos camera traps", schank_2015_tapir_occ="Nicaragua tapir cameras", tleimat_2023_ecuador_capuchin_occ="Ecuador capuchin cameras", kery_2005_mallard_count="Swiss MHB mallard (counts to 0/1)", kery_2014_mhb_comm="Swiss MHB 2014 community (counts to 0/1)", kery_2010_crossbill_dynocc="Swiss MHB crossbill", evans_2021_maine_marten_dynocc="Maine marten cameras", frimpong_2017_newriver_dynocc="New River fish records")
r[, label := ifelse(!is.na(common) & common != "", common, sci)]
single <- r[table != "kery_2014_mhb_comm", .(table, short = short[table], taxon, label, sci, n_units, n_occ, mean_visits, n_det_units, naive, psi, psi_se, p, p_se, status)]
mhb <- r[table == "kery_2014_mhb_comm", .(taxon, sci, common, naive, psi, psi_se, p, p_se, n_det_units, status)]
tabs <- unique(r[, .(table)]); tabs <- rbind(tabs, unique(d[, .(table)]))
tabs <- merge(tabs, dict[, .(table, description, reference)], by = "table"); tabs[, short := short[table]]
dyn <- lapply(seq_len(nrow(d)), function(i) list(table = d$table[i], short = short[d$table[i]], sci = d$sci[i], n_units = d$n_units[i], n_periods = d$n_periods[i], J = d$n_occ_per_period[i], psi1 = d$psi1[i], psi1_se = d$psi1_se[i], gamma = d$gamma[i], gamma_se = d$gamma_se[i], eps = d$eps[i], eps_se = d$eps_se[i], p = d$p[i], p_se = d$p_se[i], labels = strsplit(d$period_labels[i], ";")[[1]], smoothed = as.numeric(strsplit(d$smoothed[i], ";")[[1]]), naive = as.numeric(strsplit(d$naive[i], ";")[[1]])))
mp <- fread("output/evans_2021_maine_marten_dynocc__periods.csv")
for (i in seq_along(dyn)) if (dyn[[i]]$table == "evans_2021_maine_marten_dynocc") { dyn[[i]]$labels <- mp$season; dyn[[i]]$active <- mp$n_stations_active }
fp <- sort(unique(fread("output/frimpong_2017_newriver_dynocc.csv")$period))   # period 3 has no surveys
for (i in seq_along(dyn)) if (dyn[[i]]$table == "frimpong_2017_newriver_dynocc") { nv <- rep(NA, 26); nv[fp] <- dyn[[i]]$naive; dyn[[i]]$naive <- nv }
js <- toJSON(list(single = single, mhb = mhb, dyn = dyn, tables = tabs), auto_unbox = TRUE, na = "null", digits = 4)
writeLines(js, file.path(SP, "occ_data.json"))
tpl <- paste(readLines(file.path(SP, "occupancy_template.html"), warn = FALSE), collapse = "\n")
writeLines(sub("__DATA__", js, tpl, fixed = TRUE), file.path(SP, "occupancy_corpus.html"))
cat("wrote", file.path(SP, "occupancy_corpus.html"), "\n")
