#!/usr/bin/env Rscript
# Table:  armstrong_2024_hydrilla_dynocc
# Source: Dryad doi:10.5061/dryad.jsxksn0fn, version 296642 (published 2024-05-31), licence CC0 1.0
#         (as shown on Dryad). Armstrong, J. "Regional and local factors interact to shape colonization
#         and extinction dynamics of invasive Hydrilla verticillata in a patchy landscape".
#         Analysis code: Zenodo doi:10.5281/zenodo.7831559 (MIT; Dynamic_Occupancy_Model_Final.Rmd), read
#         for the design, not used.
# Paper:  Armstrong, J. et al. (2024). Regional and local factors interact to shape colonization and
#         extinction dynamics of invasive Hydrilla verticillata in a patchy landscape. Ecology and
#         Evolution 14, e11558. doi:10.1002/ece3.11558
# Data:   All_Data.csv: 4,479 rows, one per pool x survey date: Pool_ID, Date_Collected (M/D/Y), pool
#         depth and volume (averages over the study), Flood_Hgt_M (river height at which the pool floods,
#         m), Dist_River (m), Year, Month, Day (day of year), Hydrilla (0 absent / 1 present) and
#         Dist_hyd_m (distance to the nearest pool occupied on that date). 506 rock pools, 179 dates,
#         2017-2021. 196 pool-dates appear more than once (2-4 rows): 184 are identical copies, 12 carry
#         both a 0 and a 1. The deposit's own visit record (Days_since_occupancy.csv) never has a 0-day
#         interval after a pool's first visit, so a duplicated pool-date is one visit (asserted).
#         near_neigh_dist.csv: 744 pools (the mapped frame) with decimal-degree coordinates, distance to
#         the nearest pool and to the river channel. FiveYearAverages.csv: 506 pools, flood height (ft),
#         days flooded and flood events over the study and per year (river-gauge data, not detections).
#         Days_since_occupancy.csv: days since the previous visit (derivable from the dates).
#         All_dist.csv: Dist_hyd_m per pool-year. Post_Hoc_Dataset.csv: transition probabilities.
#         The paper's model used five within-visit detections per survey (Hyd_detA-E, file
#         simple_data_w_det.csv in the code); that file is not in the deposit, only the per-visit result.
#
# Mapping (standard E9 core, dynamic occupancy; single species): unit = pool, taxon = HYDVER,
#   period = year 1..5 (2017-2021, __periods), occasion = the pool's k-th survey date within the year
#   (dates irregular, 1-10 per pool-year), date = survey date, y = Hydrilla recorded present (1) or
#   absent (0) at the visit; for the 12 conflicting pool-dates y = 1 (present in at least one of the
#   visit's records) and obs_n_records gives the number of source rows behind every visit.
#   Survey evidence: row_presence (a survey exists where All_Data has a row for the pool-date).
#   unit_ covariates: depth, volume, flood height, distance to river (All_Data, constant per pool,
#   asserted), nearest-pool distance and coordinates (near_neigh_dist), flooding summaries
#   (FiveYearAverages; FloodedAt in ft equals Flood_Hgt_M in m, asserted, so only metres are shipped).
#   __units: the 744-pool mapped frame with coordinates and nearest-neighbour/river distances,
#   including the 238 pools never surveyed.
#   Coordinates: Hydrilla is an invasive non-native species, not flagged: kept as published.
#   Not shipped: Dist_hyd_m and All_dist.csv (computed from the Hydrilla detections themselves),
#   Post_Hoc_Dataset.csv (transition probabilities derived from the detection histories, with
#   averaged covariates), Days_since_occupancy.csv (derived from the survey dates, which are shipped).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "armstrong_2024_hydrilla_dynocc"
dir <- download_dryad("10.5061/dryad.jsxksn0fn", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

d  <- fread(file.path(dir, "All_Data.csv"))
nn <- fread(file.path(dir, "near_neigh_dist.csv"))
f5 <- fread(file.path(dir, "FiveYearAverages.csv"))
dsn <- fread(file.path(dir, "Days_since_occupancy.csv"))
stopifnot(nrow(d) == 4479L, uniqueN(d$Pool_ID) == 506L, !anyNA(d), all(d$Hydrilla %in% 0:1),
          nrow(nn) == 744L, !anyDuplicated(nn$Pool_ID), all(d$Pool_ID %in% nn$Pool_ID),
          nrow(f5) == 506L, setequal(f5$Pool_ID, d$Pool_ID), setequal(dsn$Pool_ID, d$Pool_ID))
d[, date := as.IDate(Date_Collected, "%m/%d/%Y")]
stopifnot(!anyNA(d$date), all(year(d$date) == d$Year), all(month(d$date) == d$Month), all(yday(d$date) == d$Day),
          uniqueN(d$date) == 179L, all(d$Year %in% 2017:2021))
# pool-level covariates are constant within pool
stopifnot(all(d[, .(a = uniqueN(Depth_Avg), b = uniqueN(Volume), c = uniqueN(Flood_Hgt_M), e = uniqueN(Dist_River)),
                by = Pool_ID][, a == 1 & b == 1 & c == 1 & e == 1]))
chk <- merge(unique(d[, .(Pool_ID, Dist_River, Flood_Hgt_M)]), nn[, .(Pool_ID, DR = Dist_River)], by = "Pool_ID")
chk <- merge(chk, f5[, .(Pool_ID, FloodedAt)], by = "Pool_ID")
stopifnot(all(abs(chk$Dist_River - chk$DR) < 1e-6), all(abs(chk$FloodedAt * 0.3048 - chk$Flood_Hgt_M) < 1e-3))

# duplicated pool-dates: one visit each (the deposit's visit record has no 0-day intervals after the first visit)
dup <- d[, .(n = .N, u = uniqueN(Hydrilla), rows = uniqueN(.SD)), by = .(Pool_ID, date), .SDcols = names(d)]
stopifnot(sum(dup$n > 1) == 196L, sum(dup$n > 1 & dup$rows == 1) == 184L, sum(dup$u > 1) == 12L, max(dup$n) == 4L)
ds_m <- as.matrix(dsn[, -1]); stopifnot(all(rowSums(ds_m == 0, na.rm = TRUE) <= 1), all(ds_m >= 0, na.rm = TRUE))
nvis_ds <- rowSums(!is.na(ds_m)); ndates <- d[, uniqueN(date), by = Pool_ID][match(dsn$Pool_ID, Pool_ID), V1]
stopifnot(all(nvis_ds <= ndates))          # never more visits in the visit record than distinct dates
v <- d[, .(y = max(Hydrilla), obs_n_records = .N), by = .(Pool_ID, Year, date)]
stopifnot(nrow(v) == 4479L - 268L, sum(v$y) == 375L)
setorder(v, Pool_ID, date)
v[, occasion := seq_len(.N), by = .(Pool_ID, Year)]
v[, period := Year - 2016L]

units <- nn[, .(unit = Pool_ID, unit_decimalLatitude = y, unit_decimalLongitude = x,
                unit_nearest_pool_m = near_neigh_m, unit_dist_river_m = Dist_River)]
stopifnot(all(units$unit_decimalLatitude %between% c(37.5, 37.55)), all(units$unit_decimalLongitude %between% c(-77.48, -77.43)))
pc <- unique(d[, .(unit = Pool_ID, unit_depth_cm = Depth_Avg, unit_volume_cm3 = Volume, unit_flood_height_m = Flood_Hgt_M)])
pc <- merge(pc, units, by = "unit")
pc <- merge(pc, f5[, .(unit = Pool_ID, unit_days_flooded = DaysFlooded, unit_days_flooded_per_year = AvgDaysFlooded,
                       unit_flood_events = TotalEvents, unit_flood_events_per_year = AvgEvents)], by = "unit")
long <- v[, .(unit = Pool_ID, taxon = "HYDVER", y = as.integer(y), period, occasion, date = as.character(date), obs_n_records)]
long <- merge(long, pc, by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 4211L, uniqueN(long$unit) == 506L, max(long$occasion) == 10L,
          !anyDuplicated(long[, .(unit, period, occasion)]))
units[, surveyed := unit %in% long$unit]
stopifnot(sum(units$surveyed) == 506L)

taxa <- make_taxa("HYDVER", "Hydrilla verticillata", vernacularName = "Hydrilla", taxon_status = "invasive non-native (USA)")
periods <- data.table(period = 1:5, year = 2017:2021,
                      first_date = as.character(v[, min(date), by = Year][order(Year), V1]),
                      last_date = as.character(v[, max(date), by = Year][order(Year), V1]),
                      n_dates = v[, uniqueN(date), by = Year][order(Year), V1],
                      n_pools = v[, uniqueN(Pool_ID), by = Year][order(Year), V1])
dataset <- list(
  title = "Hydrilla verticillata presence/absence in 506 riverine rock pools of the James River, Richmond, Virginia, over 4,211 surveys, 2017-2021",
  creator = "Armstrong, Joshua", pubDate = "2024", doi = "10.5061/dryad.jsxksn0fn",
  sourceURL = "https://doi.org/10.5061/dryad.jsxksn0fn",
  citation = "Armstrong, J. (2024). Regional and local factors interact to shape colonization and extinction dynamics of invasive Hydrilla verticillata in a patchy landscape [Dataset]. Dryad. https://doi.org/10.5061/dryad.jsxksn0fn",
  paperDOI = "10.1002/ece3.11558", relatedWorks = c("10.5281/zenodo.7831559"),
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Repeated surveys of the invasive aquatic plant Hydrilla verticillata in riverine rock pools that flood at different river heights, 2017-2021: 506 pools, 179 survey dates (8-70 per year), 1-10 surveys per pool per year. y = Hydrilla recorded present at the survey. Pool depth, volume, flood height, distance to the river channel and to the nearest pool, coordinates, and flooding summaries over the study are unit covariates; the 744-pool mapped frame is in __units.",
  samplingProtocol = "Rock pools on the James River bedrock were visited on irregular dates through each growing season and searched for Hydrilla; the source records presence/absence per pool per visit (the paper's model used five within-visit detections per survey, which are not deposited).",
  samplingProtocolCode = "visual_survey", surveyEvidence = "row_presence",
  surveyEvidenceNote = "A survey exists where All_Data.csv has a row for the pool-date. 196 pool-dates have 2-4 rows (184 identical copies, 12 with both a 0 and a 1); they are one visit each, because the deposit's own visit record (Days_since_occupancy.csv) never shows a 0-day interval after a pool's first visit. For the 12 conflicting visits y = 1; obs_n_records is the number of source rows.",
  responseType = "detection", unitKind = "site",
  closure = "not assumed within year by the source: the authors treat each survey as a primary period (within-year colonisation and extinction); period = year here, occasion = survey within year, so a user fitting colext with years as seasons assumes closure the source did not",
  geographicCoverage = "Rock pools on the bedrock of the James River fall line, Richmond, Virginia, USA (37.53 N, 77.45 W)",
  temporalCoverage = "2017-06/2021-10", coordinatesCoarsened = list(value = FALSE, method = "as published: Hydrilla verticillata is an invasive non-native species, not flagged"),
  crs = "EPSG:4326",
  notes = "Dates are irregular, so occasion k is the pool's k-th survey of the year, not a common visit; use `date` for time. The paper's detection histories (five within-visit detections per survey, Hyd_detA-E) are not in the deposit; y here is the per-visit result as deposited. Pool depth and volume are averages over the study (source).",
  notShipped = list(Dist_hyd_m = "distance to the nearest Hydrilla-occupied pool on the survey date (All_Data.csv, All_dist.csv): computed from the detections themselves",
                    Post_Hoc_Dataset.csv = "per-pool transition probabilities (absence, colonisation, extinction, persistence) derived from the detection histories, with averaged covariates",
                    Days_since_occupancy.csv = "days since the previous visit: derivable from `date`",
                    FloodedAt = "flood height in feet (FiveYearAverages.csv), identical to unit_flood_height_m in metres"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/armstrong_2024_hydrilla_dynocc.R")

stage_dict_row(TABLE,
  description = "Presence/absence of the invasive aquatic plant Hydrilla verticillata in 506 James River rock pools (Richmond, Virginia) over 4,211 irregularly timed surveys, 2017-2021, with pool size, flooding and distance covariates; dynamic occupancy (years as periods).",
  url = "https://doi.org/10.5061/dryad.jsxksn0fn",
  reference = "Armstrong, J., et al. (2024). Regional and local factors interact to shape colonization and extinction dynamics of invasive Hydrilla verticillata in a patchy landscape. Ecology and Evolution, 14, e11558.",
  doi_paper = "10.1002/ece3.11558", doi_data = "10.5061/dryad.jsxksn0fn",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip. Duplicated pool-date rows collapsed to one visit (12 conflicting, y = 1). Distance-to-occupied-pool and transition probabilities not shipped (derived from detections).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Dynamic occupancy",
  sampling_protocol = "visual_survey", design = "Multi-season (5 years, 1-10 irregular surveys per pool-year)",
  realm = "Freshwater", country = "USA", coordinates = "As published",
  notes = "Invasive aquatic plant; first plant dynamic-occupancy table. Within-year closure not assumed by the source.",
  status = "tagged")
