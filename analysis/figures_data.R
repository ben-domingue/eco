# Data behind the illustrative figures in the report. Writes analysis/figures.json.
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
rd <- function(t) { d <- fread(file.path(OUT_DIR, paste0(t, ".csv"))); if (!"period" %in% names(d)) d[, period := 1L]; if (!"occasion" %in% names(d)) d[, occasion := 1L]; d[, det := as.integer(y > 0)]; d }
# 1. species as taxa: naive occupancy vs per-survey detection rate, all surveys, three community tables
taxa <- rbindlist(lapply(c("malhotra_2021_loslagos_comm", "palacio_2020_pampasbirds_comm", "frimpong_2017_newriver_dynocc"), function(t) {
  d <- rd(t); r <- d[, .(naive_occ = mean(tapply(det, unit, max)), det_rate = mean(det), n_surveys = .N, n_det = sum(det)), by = taxon]; r[, table := t]; r
}))
# 2. detection-corrected vs naive (from illustrative.R)
est <- fread("analysis/species_estimates.csv")[!is.na(psi)]
# 3. fish: species detected per HUC-year vs effort
f <- rd("frimpong_2017_newriver_dynocc")
eff <- f[, .(n_species = sum(det), effort = obs_effort[1]), by = .(unit, period, occasion)]
eff_sum <- eff[, .(n = .N, median_species = as.numeric(median(n_species)), q1 = as.numeric(quantile(n_species, .25)), q3 = as.numeric(quantile(n_species, .75))), by = .(effort = pmin(effort, 8))][order(effort)]
# 4. loon: year-to-year transitions of territory state (source code 0..4 collapsed: 0 empty, P Pacific, Y Yellow-billed)
l <- fread(file.path(OUT_DIR, "uherkoch_2021_npraloon_dynocc.csv"))[taxon == "GAVPAC", .(unit, period, code = y_raw)]
l[, st := c("0" = "empty", "1" = "Pacific", "2" = "Pacific", "3" = "Yellow-billed", "4" = "Yellow-billed")[as.character(code)]]
setorder(l, unit, period); l[, nxt := shift(st, -1), by = unit]; l[, nxtp := shift(period, -1), by = unit]
tr <- l[!is.na(nxt) & nxtp == period + 1, .N, by = .(from = st, to = nxt)][order(from, to)]
tr[, p := round(N / sum(N), 2), by = from]
# 5. CJS: captures per session and recaptures
c <- rd("toledolima_2024_elaenia_cjs")
cj <- c[, .(captured = sum(det)), by = period]
first <- c[det == 1, .(first = min(period)), by = unit]
cj <- merge(cj, first[, .(new = .N), by = .(period = first)], by = "period", all.x = TRUE)[is.na(new), new := 0L][, recaptured := captured - new][]
write_json(list(taxa = taxa, est = est, fish_effort = eff_sum, loon_transitions = tr, cjs = cj), "analysis/figures.json", pretty = TRUE, digits = 4)
print(taxa[, .(species = .N, naive = round(median(naive_occ), 2), det = round(median(det_rate), 2)), by = table]); print(eff_sum); print(tr); print(cj)
