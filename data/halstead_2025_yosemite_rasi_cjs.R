#!/usr/bin/env Rscript
# Table:  halstead_2025_yosemite_rasi_cjs
# Source: USGS ScienceBase doi:10.5066/P1F3Y3Z6 (USGS data release, published 2025-06-11;
#         "This work is marked with Creative Commons Zero v1.0 Universal")
#   Halstead, B.J., Kleeman, P.M., Rose, J.P., and Fellers, G.M., 2025, Capture-mark-recapture
#   and covariate data for demography of Sierra Nevada yellow-legged frogs (Rana sierrae) at
#   Summit Meadow, Yosemite National Park, California, 2003-2022: U.S. Geological Survey data
#   release.
# Paper:  Climatological effects on survival, recruitment, and possible extirpation of a Sierra
#         Nevada anuran. Climate Change Ecology (2025), doi:10.1016/j.ecochg.2025.100099.
# Data:   rasi_cap_data.csv: 4,995 capture records (PIT, year, day of year); survey_data.csv:
#         14 survey slots per year 2003-2022 (year, survey_no, day of year, days since snowmelt),
#         day of year NA for a slot not surveyed (192 surveys done); rasi_ind_data.csv: per frog
#         capture count, mean SUL (cm), mean mass (g), sex (0 female / 1 male / NA);
#         rasi_annual_data.csv: surveys, captures and individuals per year; weather_data.csv:
#         remotely sensed April snow water equivalent and September PDSI by interval year.
#         Quirks, asserted: eight capture records have no PIT (NA: a frog handled but not tagged; dropped); eight capture records repeat a
#         frog on the same survey day (the individual file counts them as captures; here they
#         make one detection); every capture's (year, day) is a survey; the
#         number of surveys per year equals rasi_annual_data's; nine PIT codes in the
#         individual file were mangled into E-notation by a spreadsheet (4526383E12 written as
#         4526383E18) and are matched back to the capture file's codes by their mantissa.
#         Visual encounter surveys of the meadow and stream by day, 3-14 days a summer in
#         primary periods of 3-4 consecutive days.
#
# Mapping (E4.4 capture histories): unit = frog (PIT), taxon = RANSIE, period = year (2003-2022,
#   __periods), occasion = survey day within the year (survey_no; obs_doy, obs_days_since_
#   snowmelt), y = 1 if the frog was captured that day. Wild-caught adults: every frog has a row
#   for every survey from the study's first year to its last (no removals are recorded).
#   unit_ sex, mean SUL and mass (per frog, as deposited). surveyEvidence sample_table (the
#   survey file). No coordinates. Not shipped: weather_data (derived remote-sensing covariates
#   on an interval-year basis; available in the release), the per-frog and per-year counts
#   (derived from the captures, asserted).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "halstead_2025_yosemite_rasi_cjs"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/66be9541d34e0338828296e3?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f, ...) fread(download_cached(fl[[f]], TABLE, filename = f), ...)
cap <- rd("rasi_cap_data.csv", colClasses = list(character = "PIT"), na.strings = c("NA", ""))
srv <- rd("survey_data.csv"); ind <- rd("rasi_ind_data.csv", colClasses = list(character = "PIT")); ann <- rd("rasi_annual_data.csv")
stopifnot(nrow(cap) == 4995, sum(is.na(cap$PIT)) == 8, nrow(srv) == 280, nrow(ind) == 1251, nrow(ann) == 20)
cap_all <- copy(cap); cap <- cap[!is.na(PIT)]
stopifnot(sum(duplicated(cap)) == 8); cap <- unique(cap)
srv <- srv[!is.na(doy)]
stopifnot(nrow(srv) == 192, identical(srv[, .N, by = year]$N, ann$surveys), !anyDuplicated(srv[, .(year, doy)]))
cap <- merge(cap, srv[, .(year, doy, survey_no)], by = c("year", "doy"), all.x = TRUE)
stopifnot(!anyNA(cap$survey_no))
# repair the nine spreadsheet-mangled PITs of the individual file
bad_c <- setdiff(unique(cap$PIT), ind$PIT); bad_i <- setdiff(ind$PIT, cap$PIT)
stopifnot(length(bad_c) == 9, length(bad_i) == 9)
key <- function(x) sub("E.*$", "", x)
stopifnot(!anyDuplicated(key(bad_i)), setequal(key(bad_c), key(bad_i)))
ind[PIT %in% bad_i, PIT := bad_c[match(key(PIT), key(bad_c))]]
stopifnot(setequal(ind$PIT, unique(cap$PIT)), !anyDuplicated(ind$PIT))
stopifnot(all(merge(cap_all[!is.na(PIT), .(n = .N), by = PIT], ind, by = "PIT")[, n == caps]))   # same-day repeats count as captures there
stopifnot(all(merge(cap_all[, .(c = .N), by = year], ann, by = "year")[, c == caps]))   # yearly totals include the untagged records
years <- 2003:2022
grid <- CJ(PIT = ind$PIT, k = seq_len(nrow(srv)))
grid <- cbind(grid[, .(PIT)], srv[grid$k, .(year, survey_no, doy, dssm)])
grid <- merge(grid, unique(cap[, .(PIT, year, survey_no, y = 1L)]), by = c("PIT", "year", "survey_no"), all.x = TRUE)
grid[is.na(y), y := 0L]
stopifnot(sum(grid$y) == nrow(unique(cap[, .(PIT, year, survey_no)])), nrow(grid) == 1251 * 192)
long <- merge(grid, ind[, .(PIT, unit_sex = fifelse(sex == 1L, "M", fifelse(sex == 0L, "F", NA_character_)), unit_sul_mean_cm = svl, unit_mass_mean_g = mass)], by = "PIT")
long <- long[, .(unit = PIT, taxon = "RANSIE", y, period = match(year, years), occasion = survey_no,
                 unit_sex, unit_sul_mean_cm, unit_mass_mean_g, obs_doy = doy, obs_days_since_snowmelt = dssm)]
taxa <- make_taxa("RANSIE", "Rana sierrae", vernacularName = "Sierra Nevada yellow-legged frog")
dataset <- list(
  title = "Capture histories of 1,251 PIT-tagged Sierra Nevada yellow-legged frogs at Summit Meadow, Yosemite National Park, 2003-2022",
  creator = "Halstead, Brian J.; Kleeman, Patrick M.; Rose, Jonathan P.; Fellers, Gary M.", pubDate = "2025",
  doi = "10.5066/P1F3Y3Z6", sourceURL = "https://doi.org/10.5066/P1F3Y3Z6",
  citation = "Halstead, B.J., Kleeman, P.M., Rose, J.P., and Fellers, G.M., 2025, Capture-mark-recapture and covariate data for demography of Sierra Nevada yellow-legged frogs (Rana sierrae) at Summit Meadow, Yosemite National Park, California, 2003-2022: U.S. Geological Survey data release, https://doi.org/10.5066/P1F3Y3Z6.",
  paperDOI = "10.1016/j.ecochg.2025.100099",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
  abstract = "Capture and survey information for a meadow population of endangered Sierra Nevada yellow-legged frogs at Yosemite National Park, California, 2003-2022, collected to estimate survival, recruitment, abundance and population growth and their relation to winter and drought severity.",
  samplingProtocol = "Visual encounter surveys along the stream and through the meadow on 3-14 days each summer (June-September) in primary periods of 3-4 consecutive days; frogs > 40 mm SUL captured by hand or dip net, PIT-tagged, measured, sexed and released.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "sample_table", responseType = "detection", unitKind = "individual",
  closure = "open", closureNote = "occasion = survey day within a summer; days fall in several primary periods of 3-4 consecutive days, so the season is not closed (the source fits an open model)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = list(description = "Summit Meadow, Yosemite National Park, California, USA"),
  temporalCoverage = "2003/2022",
  notes = "Rows run from the study's first survey to its last for every frog (wild-caught; E4.4). Nine PIT codes in the individual file, mangled to E-notation, are matched back to the capture file's codes.",
  notShipped = list(no_pit_capture = "eight capture records with no PIT (not attributable to an individual)", same_day_repeats = "eight second captures of a frog on the same survey day (one detection per day)",
                    weather = "weather_data.csv: remotely sensed SWE and PDSI by interval year (derived covariates; in the release)",
                    summaries = "per-frog capture counts and per-year totals (derived; asserted against the captures)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = seq_along(years), year = years),
                  script = "data/halstead_2025_yosemite_rasi_cjs.R")
stage_dict_row(TABLE,
  description = "Daily capture histories of 1,251 PIT-tagged Sierra Nevada yellow-legged frogs (IUCN EN) over 192 visual-encounter survey days at Summit Meadow, Yosemite National Park, 2003-2022, with sex, mean size and mass, and days since snowmelt.",
  url = "https://doi.org/10.5066/P1F3Y3Z6",
  reference = "Halstead, B.J., Kleeman, P.M., Rose, J.P., & Fellers, G.M. (2025). Climatological effects on survival, recruitment, and possible extirpation of a Sierra Nevada anuran. Climate Change Ecology, 100099.",
  doi_paper = "10.1016/j.ecochg.2025.100099", doi_data = "10.5066/P1F3Y3Z6", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Robust-design-like data: period = year, occasion = survey day. No coordinates.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "CJS / Jolly-Seber (robust design)", sampling_protocol = "visual_encounter",
  design = "Multi-season (20 years x 3-14 survey days)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Endangered frog; population collapsed after 2013.")
