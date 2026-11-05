#!/usr/bin/env Rscript
# Table:  leipold_2025_duskygrouse_roads_count
# Source: Dryad doi:10.5061/dryad.hqbzkh1s7 (CC0 1.0, as shown on the Dryad page; published
#         2025-04-07). Leipold, E., Gower, C. & McNew, L.B. (2025). Data from: Maximizing the
#         detection probabilities of dusky grouse for population monitoring.
# Paper:  Leipold, E., Gower, C. & McNew, L.B. Maximizing the detection probabilities of dusky
#         grouse for population monitoring. Wildlife Biology, doi:10.1002/wlb3.01411.
# Data:   README.md is the codebook. SI_ObserverData.csv: 3,123 rows, one per point x year
#         (2020: 1,648; 2021: 1,475; 2,286 distinct points along road and trail transects in
#         the five Montana FWP regions), four playback point counts in one spring morning:
#         X1-X4 dusky grouse counted, Minutes1-4 (minutes since sunrise), Days1-4 (day of the
#         survey season, 10 April = day 1), Num.Obs1 (observers at the point), CloudCover1-4
#         (classes), Precip1-4 (A.N none, F fog, R rain, S snow), Wind1-4 (km/h), Temp1-4 (C),
#         NoiseLevel1-4 (0-3), Visit1-4 (1 = outbound pass along the route, 2 = return pass),
#         Region, Type (Road/Trail), TransectName, Org (observer affiliation). No NA anywhere.
#         duskydata_det.csv is the same counts with Num.Obs per visit and without Visit/Org
#         (asserted identical counts); route_type_data.csv is a 2019-2021 subset used for the
#         route-type analysis; SI_FemaleData.csv / SI_MaleData.csv split the 2020-2021 counts by
#         sex (35 of 12,492 cells do not sum to the total, unknown-sex birds presumably). The
#         2019 off-trail playback experiment (DuskySpringSurveys.csv, DuskySummerSurveys.csv)
#         is a different design and is leipold_2025_duskygrouse_offtrail_count.
# Mapping: unit = point (PointName); taxon = DUGR (Dendragapus obscurus); period = survey year
#         (1 = 2020, 2 = 2021; 837 points were surveyed in both years); occasion = count 1-4 of
#         the morning; y = number of dusky grouse. date = 10 April + Days - 1 of the survey
#         year (exact, from the deposited day number). unit_region, unit_route_type,
#         unit_transect (constant per point, asserted). obs_minutes_since_sunrise, obs_cloud_cover,
#         obs_precip, obs_wind_kmh, obs_temp_c, obs_noise_level, obs_route_pass (Visit),
#         obs_n_observers and obs_observer_affiliation (one value per point-year, repeated on
#         its four counts). surveyEvidence = deposited_matrix: every point-year row has four
#         non-NA counts and four non-NA survey days (asserted), so every row is a conducted count.
# Not shipped: the male/female split of the counts (a decomposition of y, and 35 cells do not
#         sum to the total); duskydata_det.csv's per-visit Num.Obs (identical counts, fewer
#         columns); model output.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "leipold_2025_duskygrouse_roads_count"
dir <- download_dryad("10.5061/dryad.hqbzkh1s7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

o <- fread(file.path(dir, "SI_ObserverData.csv"))
d <- fread(file.path(dir, "duskydata_det.csv"))
stopifnot(nrow(o) == 3123, !anyNA(o), identical(o[, .N, by = SurveyYear]$N, c(1648L, 1475L)),
          !anyDuplicated(o[, .(PointName, SurveyYear)]), uniqueN(o$PointName) == 2286,
          identical(as.matrix(o[, .(X1, X2, X3, X4)]), as.matrix(d[, .(X1, X2, X3, X4)])),
          identical(o$PointName, d$PointName))
stopifnot(all(o[, .(a = uniqueN(Type), b = uniqueN(Region), c = uniqueN(TransectName)), by = PointName][, a == 1 & b == 1 & c == 1]))
stopifnot(all(o$Type %in% c("Road", "Trail")), all(unlist(o[, paste0("Precip", 1:4), with = FALSE]) %in% c("A.N", "F", "R", "S")))

long <- rbindlist(lapply(1:4, function(k) o[, .(
  unit = PointName, taxon = "DUGR", period = SurveyYear - 2019L, occasion = k,
  y = get(paste0("X", k)),
  date = as.character(as.IDate(sprintf("%d-04-10", SurveyYear)) + get(paste0("Days", k)) - 1L),
  unit_region = Region, unit_route_type = Type, unit_transect = TransectName,
  obs_minutes_since_sunrise = get(paste0("Minutes", k)),
  obs_cloud_cover = get(paste0("CloudCover", k)), obs_precip = get(paste0("Precip", k)),
  obs_wind_kmh = get(paste0("Wind", k)), obs_temp_c = get(paste0("Temp", k)),
  obs_noise_level = get(paste0("NoiseLevel", k)), obs_route_pass = get(paste0("Visit", k)),
  obs_n_observers = Num.Obs1, obs_observer_affiliation = Org)]))
long <- order_eco(long)
stopifnot(nrow(long) == 3123 * 4, sum(long$y) == 570 + 2 * 96 + 3 * 18 + 4 * 8, all(long$y %in% 0:4),
          all(substr(long$date, 6, 7) %in% c("04", "05")))

taxa <- make_taxa("DUGR", "Dendragapus obscurus", vernacularName = "Dusky grouse")
periods <- data.table(period = 1:2, year = 2020:2021, season = "spring")

dataset <- list(
  title = "Repeated playback point counts of dusky grouse at 2,286 road and trail points, western Montana, springs 2020-2021",
  creator = "Leipold, Elizabeth; Gower, Claire; McNew, Lance B.", pubDate = "2025",
  doi = "10.5061/dryad.hqbzkh1s7", sourceURL = "https://doi.org/10.5061/dryad.hqbzkh1s7",
  citation = "Leipold, E., Gower, C., & McNew, L. B. (2025). Data from: Maximizing the detection probabilities of dusky grouse for population monitoring [Dataset]. Dryad. https://doi.org/10.5061/dryad.hqbzkh1s7",
  paperDOI = "10.1002/wlb3.01411",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Four point counts with electronic playback of a female dusky grouse call in one morning (two on the outbound pass along the route, two on the return) at points along roads and trails in the five Montana Fish, Wildlife and Parks regions, spring 2020 and 2021, with per-count weather, timing and noise and the observers' number and affiliation.",
  samplingProtocol = "Playback point counts: four counts per point in one spring morning, two on the outbound and two on the return pass along a road or trail transect; all dusky grouse seen or heard recorded.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "the four counts of one point are in one morning; points resurveyed in the second year are a second period",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "western Montana, USA, Montana FWP regions 1-5 (no coordinates deposited)",
  temporalCoverage = "2020-04/2021-05",
  notShipped = list(
    sex_split = "SI_FemaleData.csv and SI_MaleData.csv split the same counts by sex; a decomposition of y, and 35 of 12,492 cells do not sum to the total",
    duskydata_det = "same counts (asserted) with Num.Obs repeated per visit and without Visit and Org",
    route_type_data = "subset of the same surveys (plus 2019) assembled for the route-type analysis",
    model_output = "detection-model estimates"),
  notes = "The 2019 off-trail playback experiment in the same deposit is leipold_2025_duskygrouse_offtrail_count.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/leipold_2025_duskygrouse_roads_count.R")
stage_dict_row(TABLE,
  description = "Four repeated playback point counts of dusky grouse (Dendragapus obscurus) per point and morning along road and trail transects across western Montana, springs 2020 and 2021, with per-count weather, time since sunrise, noise and observer covariates.",
  url = "https://doi.org/10.5061/dryad.hqbzkh1s7",
  reference = "Leipold, E., Gower, C., & McNew, L. B. Maximizing the detection probabilities of dusky grouse for population monitoring. Wildlife Biology. https://doi.org/10.1002/wlb3.01411",
  doi_paper = "10.1002/wlb3.01411", doi_data = "10.5061/dryad.hqbzkh1s7",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dates exact from the deposited day number (10 April = day 1). Sex-split counts not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "point_count", design = "Multi-season (2 years), 4 counts per morning",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Gamebird monitoring; route pass and observer covariates.")
