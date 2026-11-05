#!/usr/bin/env Rscript
# Table:  mungi_2025_india_invplant_binom
# Source: Zenodo 10.5281/zenodo.17287410 "Trends in invasive plants in India" (Jhala, Qureshi & Mungi), version 1,
#         published 2025-10-07, licence CC BY 4.0 (as shown on Zenodo). One file, occupancy_matrix.xlsx.
# Paper:  Mungi, N. A., Jhala, Y. V., Svenning, J.-C. & Qureshi, Q. (2025). Socioecological risks amplified by rising
#         plant invasions in India. Nature Sustainability, doi:10.1038/s41893-025-01690-x (closed access, not read;
#         the design below is the record description and the sheet's own dictionary).
# Data:   sheet "header": the variable dictionary (85 rows). sheet "matrix": 21,703 rows, one per 25 km2 grid cell
#           (ID), for the five All-India tiger estimation cycles 2006, 2010, 2014, 2018, 2022:
#           <sp>1..<sp>5 = "presence replicates in <year>" for 11 invasive plants (aa Ageratina adenophora, ac
#             Ageratum conyzoides, co Chromolaena odorata, hs Mesosphaerum suaveolens, lc Lantana camara, mi Mimosa
#             diplotricha, mm Mikania micrantha, ph Parthenium hysterophorus, pj Prosopis juliflora, st Senna tora,
#             xs Xanthium strumarium); <year>_nrep = "replicates in <year>" (1 to 19; every cell has at least one
#             replicate in every cycle, asserted); presence replicates never exceed nrep (asserted).
#           <sp> (no digit) = "habitat suitability <species>": model output, not shipped.
#           Thirteen static cell covariates, standardised by the authors (mean 0): veg_t long-term vegetation change,
#             Wherb / Dherb / herb densities of wild / domestic / all herbivores, ex timber extraction signs, urb
#             urbanization index, fire frequency of fire, smoist_t soil moisture availability, rain_t trend in annual
#             rainfall, maxt_t / mint_t trend in hot-wet / cold season temperature, agri_t change in agriculture
#             area, Dherb_t trend in domestic herbivore density. No coordinates, no cell geometry.
# Mapping (standard E2 binomial_count, ruling #34; one row per cell x cycle x species, no occasion):
#   unit = "C" + ID; period = cycle 1..5 (__periods: 2006..2022); taxon = 6-letter code; y = presence replicates;
#   obs_trials = replicates surveyed (effortColumn). Every cell was surveyed in every cycle and every species was
#   recorded on every replicate sheet, so the table is the full cell x cycle x species grid
#   (surveyEvidence = deposited_matrix: nrep is the survey record, and a cell-cycle with nrep = 0 would have no row;
#   there are none). Covariates ship as unit_* with the authors' standardised values.
#   Not shipped: the eleven habitat-suitability columns (species distribution model outputs fitted to these
#   records); the header sheet (reproduced above).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "mungi_2025_india_invplant_binom"
SCRIPT <- "data/mungi_2025_india_invplant_binom.R"
f <- download_cached("https://zenodo.org/records/17287410/files/occupancy_matrix.xlsx?download=1", TABLE, "occupancy_matrix.xlsx")
stopifnot(setequal(excel_sheets(f), c("matrix", "header")))
m <- suppressMessages(as.data.table(read_excel(f, sheet = "matrix")))
h <- suppressMessages(as.data.table(read_excel(f, sheet = "header")))
setnames(h, c("header", "details", "species"))

sp <- c(aa = "Ageratina adenophora", ac = "Ageratum conyzoides", co = "Chromolaena odorata", hs = "Mesosphaerum suaveolens",
        lc = "Lantana camara", mi = "Mimosa diplotricha", mm = "Mikania micrantha", ph = "Parthenium hysterophorus",
        pj = "Prosopis juliflora", st = "Senna tora", xs = "Xanthium strumarium")
code <- c(aa = "AGEADE", ac = "AGECON", co = "CHRODO", hs = "MESSUA", lc = "LANCAM", mi = "MIMDIP", mm = "MIKMIC",
          ph = "PARHYS", pj = "PROJUL", st = "SENTOR", xs = "XANSTR")
years <- c(2006L, 2010L, 2014L, 2018L, 2022L)

# ---- source facts -----------------------------------------------------------------------
stopifnot(nrow(m) == 21703L, ncol(m) == 85L, !anyDuplicated(m$ID), !anyNA(m), nrow(h) == 85L, identical(h$header, names(m)))
for (s in names(sp)) for (k in 1:5)
  stopifnot(h[header == paste0(s, k), details] == paste("presence replicates in", years[k]), h[header == paste0(s, k), species] == sp[[s]])
for (s in names(sp)) stopifnot(h[header == s, details] == paste("habitat suitability", sp[[s]]))
for (k in 1:5) {
  n <- m[[paste0(years[k], "_nrep")]]
  stopifnot(h[header == paste0(years[k], "_nrep"), details] == paste("replicates in", years[k]), all(n == round(n)), all(n >= 1))
  for (s in names(sp)) { y <- m[[paste0(s, k)]]; stopifnot(all(y == round(y)), all(y >= 0), all(y <= n)) }
}
stopifnot(identical(sapply(years, function(y) max(m[[paste0(y, "_nrep")]])), c(18, 14, 15, 19, 18)))

# ---- long table ----------------------------------------------------------------------------
long <- rbindlist(lapply(1:5, function(k) rbindlist(lapply(names(sp), function(s)
  data.table(unit = paste0("C", m$ID), period = k, taxon = code[[s]], y = as.integer(m[[paste0(s, k)]]),
             obs_trials = as.integer(m[[paste0(years[k], "_nrep")]]))))))
cv <- m[, .(unit = paste0("C", ID), unit_vegetation_change = veg_t, unit_wild_herbivore_density = Wherb,
            unit_domestic_herbivore_density = Dherb, unit_herbivore_density = herb, unit_timber_extraction = ex,
            unit_urbanization = urb, unit_fire_frequency = fire, unit_soil_moisture = smoist_t,
            unit_rainfall_trend = rain_t, unit_hot_season_temp_trend = maxt_t, unit_cold_season_temp_trend = mint_t,
            unit_agriculture_change = agri_t, unit_domestic_herbivore_trend = Dherb_t)]
stopifnot(all(abs(colMeans(cv[, -1])) < 1e-6))
long <- order_eco(merge(long, cv, by = "unit"))
stopifnot(nrow(long) == 21703L * 5L * 11L, all(long$y <= long$obs_trials), all(long$obs_trials >= 1L))
cat(sprintf("  %d rows; %d cell-cycles; detections in %d rows\n", nrow(long), 21703L * 5L, sum(long$y > 0)))

taxa <- make_taxa(unname(code), unname(sp))
periods <- data.table(period = 1:5, year = years, label = paste("All-India tiger estimation cycle", years),
                      n_replicates = sapply(years, function(y) sum(m[[paste0(y, "_nrep")]])))

dataset <- list(
  title = "Invasive plant sign-survey replicates in 25 km2 grid cells across India's forests in five estimation cycles, 2006 to 2022: replicates with each of 11 species out of replicates surveyed",
  creator = "Jhala, Yadvendradev; Qureshi, Qamar; Mungi, Ninad",
  pubDate = "2025", doi = "10.5281/zenodo.17287410", sourceURL = "https://doi.org/10.5281/zenodo.17287410",
  citation = "Jhala, Y., Qureshi, Q., & Mungi, N. (2025). Trends in invasive plants in India [Data set]. Zenodo. https://doi.org/10.5281/zenodo.17287410",
  paperDOI = "10.1038/s41893-025-01690-x",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Occupancy survey data behind Mungi et al. (2025, Nature Sustainability) on the spread of invasive plants in India. For each 25 km2 grid cell of the forested landscapes surveyed in the All-India tiger estimation, and each of its five cycles (2006, 2010, 2014, 2018, 2022), the number of survey replicates on which each of 11 invasive plants (among them Lantana camara, Prosopis juliflora, Parthenium hysterophorus, Chromolaena odorata and Mikania micrantha) was present, out of the replicates surveyed. The replicate-level records are not deposited, so each cell-cycle-species is one row with y = replicates with presence and obs_trials = replicates surveyed (responseType binomial_count). Thirteen static cell covariates (vegetation change, herbivore densities, timber extraction, urbanization, fire, soil moisture, climate and agriculture trends) are the authors' standardised values. No coordinates are deposited.",
  samplingProtocol = "Field surveys of the All-India tiger estimation, in which invasive plants are recorded on replicate surveys within each forest grid cell in each cycle; the deposit gives per 25 km2 cell and cycle the number of replicates and, per species, the number with the species present (1 to 19 replicates). Protocol details are in the paper and the NTCA/WII status reports.",
  samplingProtocolCode = "botanical_survey", surveyEvidence = "deposited_matrix",
  effortColumn = "obs_trials",
  responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "occupancy is treated as closed within a cycle and open between the five cycles; the replicates of a cycle are collapsed into obs_trials",
  occasionKind = "none", taxonInclusion = "target",
  geographicCoverage = "Forested tiger landscapes of India (25 km2 grid cells; no coordinates deposited)",
  temporalCoverage = "2006/2022",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit (grid cell ids only)"),
  covariateNote = "All unit_ covariates are the authors' standardised values (mean 0; no means or SDs are given, so raw values cannot be recovered), with the sheet's own labels: vegetation change (long-term), wild / domestic / all herbivore densities, timber extraction signs, urbanization index, fire frequency, soil moisture availability, annual rainfall trend, hot-wet and cold season temperature trends, change in agriculture area, trend in domestic herbivore density.",
  notes = "Every cell was surveyed in every cycle (1 to 19 replicates), and every species is recorded for every cell-cycle. Grid cell ids are as deposited, prefixed with C.",
  notShipped = list(habitat_suitability = "Eleven 'habitat suitability' columns, one per species: species distribution model outputs derived from these records.",
                    header = "The sheet's variable dictionary, reproduced in the script header."))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)

stage_dict_row(TABLE,
  description = "Invasive plant occupancy across India's forested tiger landscapes: 25 km2 grid cells x five estimation cycles (2006-2022) x 11 species, each as replicates with the species out of replicates surveyed (binomial_count), with standardised cell covariates; no coordinates.",
  url = "https://doi.org/10.5281/zenodo.17287410",
  reference = "Mungi, N. A., Jhala, Y. V., Svenning, J.-C., & Qureshi, Q. (2025). Socioecological risks amplified by rising plant invasions in India. Nature Sustainability.",
  doi_paper = "10.1038/s41893-025-01690-x", doi_data = "10.5281/zenodo.17287410",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "binomial_count (ruling #34): replicate-level records not deposited. Habitat-suitability model outputs not shipped. Paper closed access; protocol from the record and the sheet dictionary.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Dynamic occupancy (binomial counts of survey replicates, multi-species)",
  sampling_protocol = "botanical_survey", design = "Multi-season (5 cycles 2006-2022, replicates collapsed to a count)", realm = "Terrestrial",
  country = "IND", coordinates = "None in source",
  notes = "responseType binomial_count (#34): y = replicates with the species, obs_trials = replicates surveyed; 11 invasive plants; no coordinates.")
