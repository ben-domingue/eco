#!/usr/bin/env Rscript
# Table:  hartley_2024_cpraealtus_occ
# Source: Dryad doi:10.5061/dryad.bzkh189hx (CC0 1.0, as shown on the Dryad page; version 2,
#         published 2024-04-15). Hartley, R., Blanchard, W., Clemann, N., Schroder, M.,
#         Schulz, M., Lindenmayer, D.B. & Scheele, B.C. (2024). Rare but not lost: Endemic
#         mountain lizard occupancy following mega-fire and grazing disturbances.
# Paper:  Hartley, R. et al. (2024). Rare but not lost: Endemic mountain lizard occupancy
#         following mega-fire and grazing disturbances. Austral Ecology 49, e13431,
#         doi:10.1111/aec.13431. Single-season occupancy of the Alpine she-oak skink
#         (Cyclodomorphus praealtus, Scincidae; endangered under the EPBC Act) against
#         elevation, the 2019-20 fires and an index of grazing by introduced herbivores.
# Data:   Hartley_etal_Cpraealtus_Data.csv, 1,404 rows, one per survey (artificial-cover
#         tile transect checked once): UID (row id), siteID, date (d/m/Y), time (hhmm),
#         air_temp (C at the start of the survey), season (snow-free season code 14-17 =
#         2018-19 .. 2021-22), No.AvailTls (tiles available on the transect, 1-10),
#         tile_temp_av (mean under-tile temperature, C), C_praealtus (0/1), day (day of
#         the snow-free period), elev.1sDEM (m, DEM), fire (burnt 1 / unburnt 0), tgp
#         (grazing index over herbivore signs), temp_diff (interaction of the temperature
#         differential and the mean under-tile temperature), ObsNo (survey number within
#         the season). README.md defines the columns. No missing values.
#         Quirk: eight siteIDs (TN01-TN08) each label two transects: each has two
#         elevations, and fire and tgp follow the elevation, not the siteID; ObsNo then
#         repeats within siteID x season. Keyed by siteID + elevation, ObsNo is unique
#         and runs 1..n within every transect x season, and fire and tgp are constant per
#         transect (asserted). 113 transects. The paper reports 2,045 surveys at 120
#         sites over four years; the deposit holds 1,404 surveys at 113 transects.
#         ObsNo is not in date order (only 11% of surveys match their date rank).
#
# Mapping (standard: occupancy with primary periods, E9 core; the paper fit single-season
#   models per season):
#   unit = transect: siteID, with suffix _a (lower) / _b (higher elevation) for the eight
#   doubled siteIDs; taxon = CYCPRA; period = snow-free season 1..4 (codes 14-17,
#   2018-19 .. 2021-22; __periods); occasion = survey order within transect x season by
#   date and time; y = C_praealtus; date = ISO date. obs_: time (hhmm), air temperature,
#   tiles available (effortColumn), mean under-tile temperature, temp_diff as deposited,
#   the deposited survey number ObsNo. unit_: siteID as deposited, DEM elevation, fire
#   (burnt in the 2019-20 fires; constant across all four seasons, including the pre-fire
#   2018-19 season, as deposited), grazing index. Survey evidence: the deposit is a list
#   of conducted surveys, one row each (sample_table). No coordinates are deposited.
#   Not shipped: UID (row id), day (derivable from date).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hartley_2024_cpraealtus_occ"
dir <- download_dryad("10.5061/dryad.bzkh189hx", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Hartley_etal_Cpraealtus_Data\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f)

# facts about the source
stopifnot(identical(names(raw), c("UID", "siteID", "date", "time", "air_temp", "season", "No.AvailTls", "tile_temp_av",
                                  "C_praealtus", "day", "elev.1sDEM", "fire", "tgp", "temp_diff", "ObsNo")),
          nrow(raw) == 1404, !anyNA(raw), !anyDuplicated(raw$UID), uniqueN(raw$siteID) == 105,
          all(raw$C_praealtus %in% 0:1), sum(raw$C_praealtus) == 139, all(raw$season %in% 14:17),
          all(raw$No.AvailTls %in% 1:10), all(raw$fire %in% 0:1), all(raw$time >= 0 & raw$time <= 2359))
raw[, dt := as.IDate(date, "%d/%m/%Y")]
stopifnot(!anyNA(raw$dt))
dbl <- raw[, uniqueN(elev.1sDEM), by = siteID][V1 > 1, siteID]
stopifnot(identical(sort(dbl), sprintf("TN%02d", 1:8)), raw[, uniqueN(elev.1sDEM), by = siteID][, max(V1)] == 2)
lo <- raw[siteID %in% dbl, .(lo = min(elev.1sDEM)), by = siteID]
raw <- merge(raw, lo, by = "siteID", all.x = TRUE)
raw[, unit := fifelse(siteID %in% dbl, paste0(siteID, fifelse(elev.1sDEM == lo, "_a", "_b")), siteID)]
stopifnot(uniqueN(raw$unit) == 113, raw[, uniqueN(elev.1sDEM), by = unit][, max(V1)] == 1,
          raw[, uniqueN(fire), by = unit][, max(V1)] == 1, raw[, uniqueN(tgp), by = unit][, max(V1)] == 1,
          !anyDuplicated(raw[, .(unit, season, ObsNo)]),
          raw[, identical(sort(ObsNo), seq_len(.N)), by = .(unit, season)][, all(V1)],
          !anyDuplicated(raw[, .(unit, dt, time)]))
sea <- raw[, .(start = min(dt), end = max(dt), n_units = uniqueN(unit), n_surveys = .N), by = season][order(season)]
stopifnot(identical(sea$season, 14:17), all(year(sea$start) == 2018:2021), all(sea$end < as.IDate(paste0(2019:2022, "-07-01"))))

setorder(raw, unit, season, dt, time)
raw[, occasion := seq_len(.N), by = .(unit, season)]
raw[, period := season - 13L]
long <- raw[, .(unit, taxon = "CYCPRA", y = C_praealtus, period, occasion, date = format(dt),
                obs_time_hhmm = sprintf("%04d", time), obs_air_temp_c = air_temp, obs_tiles_available = No.AvailTls,
                obs_tile_temp_mean_c = tile_temp_av, obs_temp_diff = temp_diff, obs_survey_no = ObsNo,
                unit_site_id = siteID, unit_elevation_m = elev.1sDEM, unit_burnt_2019_20 = fire, unit_grazing_index = tgp)]
stopifnot(nrow(long) == 1404, sum(long$y) == 139, max(long$occasion) == 8,
          !anyDuplicated(long[, .(unit, period, occasion)]))

taxa <- make_taxa("CYCPRA", "Cyclodomorphus praealtus", vernacularName = "Alpine she-oak skink",
                  taxon_conservationStatus = "Endangered (EPBC Act, Australia)")
periods <- sea[, .(period = season - 13L, season_code = season,
                   season_label = sprintf("snow-free season %d-%02d", year(start), (year(start) + 1L) %% 100),
                   start = format(start), end = format(end), n_units, n_surveys)]

dataset <- list(
  title = "Artificial-cover-tile surveys of the Alpine she-oak skink at 113 transects in the Australian Alps over four snow-free seasons, 2018-2022",
  creator = "Hartley, Renée; Blanchard, Wade; Clemann, Nick; Schroder, Mellesa; Schulz, Martin; Lindenmayer, David B.; Scheele, Ben C.",
  pubDate = "2024", doi = "10.5061/dryad.bzkh189hx", sourceURL = "https://doi.org/10.5061/dryad.bzkh189hx",
  citation = "Hartley, R., Blanchard, W., Clemann, N., Schroder, M., Schulz, M., Lindenmayer, D. B., & Scheele, B. C. (2024). Rare but not lost: Endemic mountain lizard occupancy following mega-fire and grazing disturbances [Dataset]. Dryad. https://doi.org/10.5061/dryad.bzkh189hx",
  paperDOI = "10.1111/aec.13431",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the Alpine she-oak skink (Cyclodomorphus praealtus), an endangered endemic of the Australian Alps, in repeated checks of artificial cover-tile transects across four snow-free seasons (2018-19 to 2021-22) spanning the 2019-20 mega-fires, with survey-level air and under-tile temperatures and tile availability, and transect elevation, fire history and an index of grazing by introduced herbivores. The paper fit single-season occupancy models; occupancy was positively associated with grazing and not with fire or elevation.",
  samplingProtocol = "Transects of up to 10 artificial cover tiles checked repeatedly within each snow-free season; a survey records the tiles available (under 1/3 ant-occupied, not displaced, shattered or flooded), air and mean under-tile temperatures, and whether the skink was found. Protocol detail beyond the README is in the paper.",
  samplingProtocolCode = "cover_board", effortColumn = "obs_tiles_available",
  surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "period (snow-free season; the paper fit single-season models per season)", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Australian Alps bioregion, south-eastern Australia (New South Wales, Victoria, ACT); no coordinates deposited",
  temporalCoverage = "2018-11-16/2022-04-10",
  coordinatesCoarsened = NA,
  notShipped = list(UID = "row identifier", day = "day of the snow-free period, derivable from date"),
  notes = "Eight siteIDs (TN01-TN08) each label two transects in the deposit (two elevations, with fire and grazing following elevation); they are split into units <siteID>_a (lower) and _b (higher), and unit_site_id keeps the deposited code. occasion is the survey's date order within transect x season; the deposited ObsNo (obs_survey_no) is not chronological. unit_burnt_2019_20 is the deposit's fire flag, constant across seasons including the pre-fire 2018-19 season. The paper reports 2,045 surveys at 120 sites; the deposit has 1,404 surveys at 113 transects. obs_temp_diff is as deposited (an interaction term the authors computed; its components are not deposited).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hartley_2024_cpraealtus_occ.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of the endangered Alpine she-oak skink (Cyclodomorphus praealtus) in 1,404 checks of artificial cover-tile transects at 113 sites in the Australian Alps over four snow-free seasons (2018-19 to 2021-22), with air and under-tile temperatures, tiles available, elevation, 2019-20 fire and a grazing index.",
  url = "https://doi.org/10.5061/dryad.bzkh189hx",
  reference = "Hartley, R., Blanchard, W., Clemann, N., Schroder, M., Schulz, M., Lindenmayer, D. B., & Scheele, B. C. (2024). Rare but not lost: Endemic mountain lizard occupancy following mega-fire and grazing disturbances. Austral Ecology, 49, e13431.",
  doi_paper = "10.1111/aec.13431", doi_data = "10.5061/dryad.bzkh189hx",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First lizard occupancy table. Eight deposited site codes each cover two transects and are split by elevation. No coordinates deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Occupancy (single-season per season; stacked or dynamic)",
  sampling_protocol = "cover_board", design = "Multi-season (4 snow-free seasons, up to 8 surveys each)", realm = "Terrestrial",
  country = "AUS", coordinates = "None in source", notes = "139 detections in 1,404 surveys; endangered skink.")
