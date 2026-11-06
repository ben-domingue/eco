#!/usr/bin/env Rscript
# Table:  rogers_2024_bighunting_sculpin_cjs
# Source: USGS ScienceBase doi:10.5066/P1X9JF86 (USGS data release, published 2024-07-19; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Rogers, K.M., Kelly, Z.A., and Hitt, N.P., 2024, Capture-recapture data for a restored population
#   of Blue Ridge sculpin (Cottus caeruleomentum) with environmental covariates: U.S. Geological
#   Survey data release.
# Data:   BRS_PITdata_2023.csv: 2,315 PIT-tag detections of 385 sculpin translocated into Big Hunting
#         Creek, Maryland (Catoctin Mountain Park), from four source populations, on 11 survey days
#         (2022-09-23 to 2023-09-19), with the GNSS position snapped to the stream line (the
#         earliest detection of a tag on a survey day), source population, weight, total length and
#         Fulton's K (constant per fish). 80 tag-days appear twice, the second time with no
#         position; 29 other detections have no position. BRS_FlowData_2023.csv: stream flow on 10
#         of the 11 survey days (none for 2023-09-13). BRS_StreamTemperature_2023.csv: 20-minute
#         water temperature at gauges. Asserted: every fish was first recorded on 2022-09-23 (the
#         tagging and release survey), and fish attributes are constant per tag.
# Mapping: unit = fish (TagID), period = survey day (1..11), y = detected on that survey by the mobile
#   PIT antenna, one row per fish x survey from the first survey (all fish released before or at
#   it, E4.4). surveyEvidence inferred: the survey days are the days with any detection (the flow
#   file lists 10 of them; 2023-09-13 has detections and no flow); a survey day with no detection
#   of any fish would be absent. obs_latitude / obs_longitude: the detection's snapped position
#   (empty where no fix or not detected; finer locations than a unit coordinate, kept as
#   published); period_flow_m3s in __periods. unit_ source population, weight, length, condition.
# Not shipped: the duplicate tag-day rows without a position; the stream-temperature series
#   (gauge time series, not linked to detections); flow in ft3/s (same as m3/s).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "rogers_2024_bighunting_sculpin_cjs"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/6695560bd34eba98af25c6ac?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
p <- fread(download_cached(fl[["BRS_PITdata_2023.csv"]], TABLE, filename = "BRS_PITdata_2023.csv"))
q <- fread(download_cached(fl[["BRS_FlowData_2023.csv"]], TABLE, filename = "BRS_FlowData_2023.csv"))
p[, d := as.IDate(Date, format = "%m/%d/%Y")]; q[, d := as.IDate(Date, format = "%m/%d/%Y")]
stopifnot(nrow(p) == 2315, uniqueN(p$TagID) == 385, !anyNA(p$d), nrow(q) == 10,
          p[, .(uniqueN(SourcePop), uniqueN(Weight_g), uniqueN(TL_mm), uniqueN(Fulton_K)), by = TagID][, all(V1 == 1 & V2 == 1 & V3 == 1 & V4 == 1)])
dup <- p[duplicated(p[, .(TagID, d)]) | duplicated(p[, .(TagID, d)], fromLast = TRUE)]
stopifnot(nrow(dup) == 160, dup[, .(sum(is.na(Latitude))), by = .(TagID, d)][, all(V1 == 1)])
p <- p[order(TagID, d, is.na(Latitude))][!duplicated(p[order(TagID, d, is.na(Latitude)), .(TagID, d)])]
stopifnot(nrow(p) == 2235, sum(is.na(p$Latitude)) == 29)
days <- sort(unique(p$d)); stopifnot(length(days) == 11, all(q$d %in% days), setdiff(days, q$d) == as.IDate("2023-09-13"))
stopifnot(all(p[, min(d), by = TagID]$V1 == days[1]))
fish <- unique(p[, .(TagID, SourcePop, Weight_g, TL_mm, Fulton_K)])
grid <- CJ(TagID = fish$TagID, period = seq_along(days))
grid[, d := days[period]]
long <- merge(grid, p[, .(TagID, d, Latitude, Longitude)], by = c("TagID", "d"), all.x = TRUE)
long[, y := as.integer(TagID %in% p$TagID & !is.na(match(paste(TagID, d), paste(p$TagID, p$d))))]
long <- merge(long, fish, by = "TagID")
long <- long[, .(unit = TagID, taxon = "COTCAE", y, period, date = format(d), unit_source_pop = SourcePop, unit_weight_g = Weight_g,
                 unit_total_length_mm = TL_mm, unit_fulton_k = Fulton_K, obs_latitude = Latitude, obs_longitude = Longitude)]
stopifnot(nrow(long) == 385 * 11, sum(long$y) == 2235)
periods <- data.table(period = seq_along(days), date = format(days))[q[, .(date = format(d), flow_m3s = `Q_m3/s`)], on = "date", flow_m3s := i.flow_m3s]
taxa <- make_taxa("COTCAE", "Cottus caeruleomentum", vernacularName = "Blue Ridge sculpin")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "PIT-tag resight histories of 385 translocated Blue Ridge sculpin on 11 mobile-antenna surveys, Big Hunting Creek, Maryland, 2022-2023",
  creator = "Rogers, Karli M.; Kelly, Zachary A.; Hitt, Nathaniel P.",
  pubDate = "2024", doi = "10.5066/P1X9JF86", sourceURL = "https://doi.org/10.5066/P1X9JF86",
  citation = "Rogers, K.M., Kelly, Z.A., and Hitt, N.P., 2024, Capture-recapture data for a restored population of Blue Ridge sculpin (Cottus caeruleomentum) with environmental covariates: U.S. Geological Survey data release, https://doi.org/10.5066/P1X9JF86.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Blue Ridge sculpin from four source populations were PIT-tagged and released into Big Hunting Creek, Maryland, to restore the species there; the reach was resurveyed with a rod-mounted mobile PIT antenna and GNSS ten times over the following year to assess movement and survival.",
  samplingProtocol = "Mobile PIT-tag surveys: a rod-mounted antenna swept along the creek with a GNSS receiver; each tag's earliest detection on a survey day is kept with its position snapped to the stream line.",
  samplingProtocolCode = "pit_resight", surveyEvidence = "inferred",
  surveyEvidenceNote = "The survey days are the 11 days with any detection (the flow file lists 10 of them); a survey on which no fish was detected would be absent.",
  responseType = "detection", unitKind = "individual", closure = "none", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = list(description = "Big Hunting Creek, Catoctin Mountain Park, Frederick County, Maryland, USA",
                            boundingBox = list(west = -77.5, east = -77.41, south = 39.61, north = 39.68)),
  temporalCoverage = "2022-09/2023-09",
  coordinatesCoarsened = list(value = FALSE, method = "detection positions as published (obs_latitude / obs_longitude)"),
  notShipped = list(duplicate_rows = "80 tag-days deposited a second time without a position (one row kept)",
                    temperature = "BRS_StreamTemperature_2023.csv: gauge time series, not linked to detections",
                    flow_cfs = "Q_ft3/s: the same flow in cubic feet per second"),
  notes = "Survey 1 (2022-09-23) is the release survey at which every fish was first recorded.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/rogers_2024_bighunting_sculpin_cjs.R")
stage_dict_row(TABLE,
  description = "Detection histories of 385 PIT-tagged Blue Ridge sculpin translocated into Big Hunting Creek, Maryland, over 11 mobile-antenna surveys (2022-2023), with source population, size, condition, detection positions and survey-day stream flow.",
  url = "https://doi.org/10.5066/P1X9JF86",
  reference = "Rogers, K.M., Kelly, Z.A., and Hitt, N.P. (2024). Capture-recapture data for a restored population of Blue Ridge sculpin (Cottus caeruleomentum) with environmental covariates. U.S. Geological Survey data release.",
  doi_data = "10.5066/P1X9JF86", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "CJS over survey days; detection positions as obs_ columns.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "CJS", sampling_protocol = "pit_resight",
  design = "Multi-session (11 survey days)", realm = "Freshwater", country = "USA", coordinates = "As published",
  notes = "Translocated (restored) population; mobile PIT antenna.")
