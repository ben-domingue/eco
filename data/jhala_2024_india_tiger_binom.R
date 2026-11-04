# Table:  jhala_2024_india_tiger_binom
# Source: Zenodo 10.5281/zenodo.13856111 "Tiger occupancy" (Jhala, Mungi, Gopal & Qureshi),
#         published 2024-09-29, licence CC BY 4.0 (as shown on Zenodo). One file, data28sep24.xlsx.
# Paper:  Jhala, Y. V., Mungi, N. A., Gopal, R., & Qureshi, Q. (2025). Tiger recovery amid people and
#         poverty. Science, 387(6733), 505-510. doi:10.1126/science.adk4827 (Crossref). The Zenodo
#         record predates publication ("in review"); the paper's methods were not fetched (Science is
#         paywalled to the agent), so the survey protocol below is the sheet's own dictionary.
# Data:   sheet "occupancy": 7,183 rows, one per 100 km2 grid cell (G100 = grid number), for the four
#           All-India tiger estimation cycles 2006, 2010, 2014, 2018: preYYYY = "replicates with
#           presence in YYYY", absYYYY = "replicates with absence in YYYY" (sign surveys on
#           replicate segments; the replicate-level histories are not deposited). pre + abs = 0 in
#           566 / 1,295 / 600 / 0 cells for the four cycles (not surveyed that cycle); max 21.
#           Static covariates (standardised, mean 0): habarea (habitat area), roadlen (railway and
#           road length), popt (human population density), agrit (agriculture area), hst (human
#           settlement area), conft (armed-conflict incidences), threat (cumulative threats); pov2
#           "standardized poverty" (mean 1). Cycle-varying covariates y6_/y10_/y14_/y18_: csgt
#           (prey encounter rate), lvsn (livestock encounter rate), ex (extractive-pressure
#           encounter rate), na (nighttime light), flpt (forest loss over the preceding interval),
#           dpat (distance from tiger-occupied protected area, for cycles 2010-2018 "in" the
#           previous cycle's year). Columns header / details are the sheet's variable dictionary.
#           No coordinates, no cell geometry.
#         sheet "cooccurrence": 29,877 rows at 25 km2 grid scale (G25 within G100) of standardised
#           continuous encounter-rate indices for ~110 fauna codes plus landscape indices; no
#           replicate structure and not detections, so not shipped.
# Mapping (standard E2 `binomial_count`, ruling #34): one row per cell x cycle, no `occasion`:
#   unit = "G" + grid number, period = cycle 1-4 (__periods: year 2006/2010/2014/2018), taxon =
#   PANTIG, y = replicates with presence, obs_trials = replicates with presence + absence
#   (effortColumn). A cell-cycle with zero replicates was not surveyed and has no row
#   (surveyEvidence = deposited_matrix). unitKind = site; closure = within a cycle. Static
#   covariates ship as unit_* and cycle-varying ones as period_*, all as the authors' standardised
#   values (the sheet gives no means or SDs, so they cannot be unstandardised). Not shipped: dpat
#   (distance to tiger-occupied protected area is derived from the previous cycle's tiger
#   survey, i.e. from detections in this table's other periods, so it is a data-derived covariate
#   of the response and is dropped per the processing guide), the cooccurrence sheet, and the
#   header/details dictionary (reproduced above). The tiger is IUCN EN; the deposit has no
#   coordinates, so nothing to coarsen.

for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "jhala_2024_india_tiger_binom"
SCRIPT <- "data/jhala_2024_india_tiger_binom.R"
f <- download_cached("https://zenodo.org/api/records/13856111/files/data28sep24.xlsx/content", TABLE, "data28sep24.xlsx")

stopifnot(setequal(excel_sheets(f), c("occupancy", "cooccurrence")))
o <- suppressMessages(as.data.table(read_excel(f, sheet = "occupancy")))
years <- c(2006L, 2010L, 2014L, 2018L); ytag <- c("y6", "y10", "y14", "y18")

# ---- source facts -----------------------------------------------------------------------
stopifnot(nrow(o) == 7183, uniqueN(o$G100) == 7183, !anyNA(o$G100), ncol(o) == 44,
          all(c(paste0("pre", years), paste0("abs", years)) %in% names(o)))
dict <- o[!is.na(header), .(header, details)]
stopifnot(nrow(dict) == 41, dict[header == "pre2006", details] == "replicates with presence in 2006",
          dict[header == "y10_dpat", details] == "distance from tiger occupied protected area in 2006")
for (y in years) {
  p <- o[[paste0("pre", y)]]; a <- o[[paste0("abs", y)]]
  stopifnot(!anyNA(p), !anyNA(a), all(p == round(p)), all(a == round(a)), all(p >= 0), all(a >= 0), max(p + a) == 21)
}
k0 <- sapply(years, function(y) sum(o[[paste0("pre", y)]] + o[[paste0("abs", y)]] == 0))
stopifnot(identical(k0, c(566L, 1295L, 600L, 0L)))
static <- c("habarea", "roadlen", "popt", "agrit", "hst", "conft", "threat", "pov2")
stopifnot(all(abs(colMeans(o[, ..static])[static != "pov2"]) < 1e-6), abs(mean(o$pov2) - 1) < 1e-3)   # pov2 is scaled to mean 1 (0.99986), not z-scored
cat(sprintf("  7,183 cells x 4 cycles; unsurveyed cell-cycles: %s\n", paste(k0, collapse = ", ")))

# ---- long table ----------------------------------------------------------------------------
vary <- c(csgt = "period_prey_encounter_rate", lvsn = "period_livestock_encounter_rate", ex = "period_extractive_pressure_rate",
          na = "period_nighttime_light", flpt = "period_forest_loss")
rows <- lapply(seq_along(years), function(i) {
  y <- years[i]; d <- o[, .(unit = paste0("G", G100), period = i,
                           y = as.integer(get(paste0("pre", y))), obs_trials = as.integer(get(paste0("pre", y)) + get(paste0("abs", y))))]
  for (v in names(vary)) d[[vary[[v]]]] <- o[[paste(ytag[i], v, sep = "_")]]
  d[obs_trials > 0]
})
long <- rbindlist(rows)
long[, taxon := "PANTIG"]
st <- o[, .(unit = paste0("G", G100), unit_habitat_area = habarea, unit_road_rail_length = roadlen, unit_human_pop_density = popt,
            unit_agriculture_area = agrit, unit_settlement_area = hst, unit_armed_conflict = conft,
            unit_cumulative_threat = threat, unit_poverty = pov2)]
long <- merge(long, st, by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 4 * 7183 - sum(k0), all(long$y <= long$obs_trials), all(long$obs_trials >= 1),
          sum(long$y) == 3939 + 4547 + 5517 + 6975, !anyNA(long[, .(y, obs_trials)]), uniqueN(long$unit) == 7183)
cat(sprintf("  %d cell-cycles surveyed, %d replicates, %d with tiger sign\n", nrow(long), sum(long$obs_trials), sum(long$y)))

taxa <- make_taxa("PANTIG", "Panthera tigris", vernacularName = "Tiger", taxon_iucnCategory = "EN")
periods <- data.table(period = 1:4, year = years, label = paste("All-India tiger estimation cycle", years),
                      n_cells_surveyed = as.integer(7183 - k0), n_replicates = sapply(1:4, function(i) sum(long[period == i, obs_trials])))

dataset <- list(
  title = "Tiger sign-survey occupancy data for 7,183 100 km2 grid cells across India in four estimation cycles (2006, 2010, 2014, 2018): replicates with tiger sign out of replicates surveyed",
  creator = "Jhala, Yadvendradev; Mungi, Ninad Avinash; Gopal, Rajesh; Qureshi, Qamar",
  pubDate = "2024", doi = "10.5281/zenodo.13856111", sourceURL = "https://doi.org/10.5281/zenodo.13856111",
  citation = "Jhala, Y., Mungi, N. A., Gopal, R., & Qureshi, Q. (2024). Tiger occupancy [Data set]. Zenodo. https://doi.org/10.5281/zenodo.13856111",
  paperDOI = "10.1126/science.adk4827",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Occupancy survey data behind Jhala et al. (2025, Science) 'Tiger recovery amid people and poverty': for each of 7,183 100 km2 grid cells of India's tiger landscapes and each of the four All-India tiger estimation cycles (2006, 2010, 2014, 2018), the number of survey replicates with tiger sign and the number without. The replicate-level histories are not deposited, so each cell-cycle is one row with y = replicates with presence and obs_trials = replicates surveyed (responseType binomial_count); a cell-cycle with no replicates is not a row. Covariates are the authors' standardised values: eight static cell covariates (habitat area, road and rail length, human population density, agriculture and settlement area, armed conflict, cumulative threat, poverty) and five cycle-varying ones (prey, livestock and extractive-pressure encounter rates, nighttime light, forest loss over the preceding interval). No coordinates are deposited.",
  samplingProtocol = "Sign surveys (tiger sign on replicate walks) per 100 km2 grid cell in each All-India tiger estimation cycle; the deposit gives per cell and cycle the count of replicates with and without tiger sign (max 21 replicates). Protocol details are in the paper and the NTCA/WII status reports.",
  samplingProtocolCode = "sign_survey", surveyEvidence = "deposited_matrix",
  effortColumn = "obs_trials",
  responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "period: occupancy is closed within an estimation cycle and open between the four cycles; the replicates of a cycle are collapsed into obs_trials", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Tiger landscapes of India (7,183 grid cells of 100 km2; no coordinates deposited)",
  temporalCoverage = "2006/2018",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit (grid numbers only); the tiger is IUCN EN, so none can be added"),
  notes = "Covariates are the authors' standardised values (mean 0, except unit_poverty with mean 1); the sheet gives no means or SDs, so raw values cannot be recovered. period_forest_loss for cycle 1 covers 2001-2006, later ones the preceding four-year interval. Cells unsurveyed in a cycle (566, 1,295, 600, 0) have no row for that period; every cell was surveyed in 2018.",
  notShipped = list(`y*_dpat` = "distance from tiger-occupied protected area: for cycles 2010-2018 it is computed from the previous cycle's tiger survey, i.e. from this table's own detections in another period, so it is a data-derived covariate of the response and is dropped (processing guide); the 2006 column's basis is undocumented and is dropped with it",
                    `sheet cooccurrence` = "29,877 25 km2 cells with standardised continuous encounter-rate indices for ~110 fauna codes and landscape indices; not detection data (no replicate structure)",
                    `header / details` = "the sheet's variable dictionary, reproduced in the script header"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)

stage_dict_row(TABLE,
  description = "Tiger sign-survey occupancy across India: 7,183 100 km2 grid cells x four estimation cycles (2006-2018), each cell-cycle as replicates with tiger sign out of replicates surveyed (binomial_count), with eight static and five cycle-varying standardised covariates; no coordinates.",
  url = "https://doi.org/10.5281/zenodo.13856111",
  reference = "Jhala, Y. V., Mungi, N. A., Gopal, R., & Qureshi, Q. (2025). Tiger recovery amid people and poverty. Science, 387(6733), 505-510.",
  doi_paper = "10.1126/science.adk4827", doi_data = "10.5281/zenodo.13856111",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "binomial_count (ruling #34): replicate-level histories not deposited. Covariates standardised by the authors. dpat (distance to tiger-occupied PA, derived from the previous cycle's survey) not shipped. Science paper paywalled; protocol from the sheet dictionary.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (binomial counts of sign-survey replicates)",
  sampling_protocol = "sign_survey", design = "Multi-season (4 cycles 2006-2018 x up to 21 replicates collapsed to a count)", realm = "Terrestrial",
  country = "IND", coordinates = "None in source",
  notes = "responseType binomial_count (#34): y = replicates with tiger sign, obs_trials = replicates surveyed; 7,183 cells; EN taxon, no coordinates.")
