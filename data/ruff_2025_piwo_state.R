#!/usr/bin/env Rscript
# Table:  ruff_2025_piwo_state
# Source: Zenodo doi:10.5281/zenodo.15706949 (CC BY 4.0, as shown on the Zenodo record),
#   published 2025-06-23. Ruff, Z. J., Lesmeister, D. B., Jenkins, J. M. A., et al. Data from:
#   Passive acoustic monitoring captures large-scale Dryocopus pileatus (Pileated Woodpecker)
#   occupancy patterns in the Pacific Northwest, USA.
# Paper:  in preparation at deposit time (the record says it will be updated with a link).
# Data:   PIWO_Occupancy.zip, an R project. data/PIWO_Encounter_Histories_w_Covariates_Raw.csv
#         (3,948 rows): one row per autonomous recording unit (ARU) station in 2023:
#         hex (5-digit code of a 500-ha sampling hexagon), stn (station letter or digit
#         within the hexagon, nominally 4 per hexagon); week_1..week_6 the multi-state
#         encounter history over the first six weeks of recording (step_2_data_prep.r:
#         0 = no Pileated Woodpecker detection, 1 = detections on 3 or fewer days of the
#         week, 2 = detections on 4 or more days; NA = missed survey); date_week_k (day of
#         year), effort_week_k (hours recorded), noise_week_k, precip_mn/precip_total,
#         temp_max/temp_mn/temp_mnmax per week; prov (physiographic province, 10 codes) and
#         62 raw (unstandardised) site covariates (forest structure and composition from
#         gradient-nearest-neighbour vegetation maps within 180 and 360 m, topography,
#         distance to stream, climate), latitude and longitude. Detections are clips with
#         PNW-Cnet v5 score >= 0.95 for the HYPI1 class; stations with <= 10 detections
#         in the six weeks were reviewed manually. Hex_Centroid_Covariate_Values_Raw.csv
#         and the shapefile are the prediction grid (not surveys). step_*.r: RPresence code.
#         Checked: week_k is NA exactly where effort_week_k and date_week_k are NA (398
#         station-weeks), and effort > 0 wherever a week is scored.
#
# Mapping (multi-state occupancy, standard E2 responseType = state):
#   unit = station (hex-stn), cluster_id = hex; occasion = week 1-6; taxon = PIWO;
#   y = the deposited state 0/1/2 (stateCodes from step_2_data_prep.r). Survey evidence:
#   effort_table (a station-week is a survey iff effort_week_k is recorded and > 0).
#   obs_ = day of year of the week (obs_date_doy; the deposit gives no calendar date, and
#   whether it is the first day of the week is not stated, so no date column), hours of
#   recording (obs_effort_hours, also effortColumn), noise and weather summaries as
#   deposited. IUCN assesses the species as Hylatomus pileatus (LC), so iucn_category()
#   returns NA for GBIF's Dryocopus pileatus; LC is set by hand, name as in the source.
#   unit_ = province, the 62 raw site covariates (names as deposited, prefixed),
#   coordinates. Pileated Woodpecker is IUCN Least Concern: not flagged, coordinates kept
#   as published (WGS84 decimal degrees).
#   Not shipped: the hexagon prediction grid and shapefile (not surveys); the model code
#   and any fitted outputs (none deposited as data).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ruff_2025_piwo_state"
zip <- download_cached("https://zenodo.org/records/15706949/files/PIWO_Occupancy.zip?download=1", TABLE, filename = "PIWO_Occupancy.zip")
ex <- file.path(dirname(zip), "z"); if (!dir.exists(ex)) unzip(zip, exdir = ex)
f <- file.path(ex, "PIWO_Occupancy", "data", "PIWO_Encounter_Histories_w_Covariates_Raw.csv")
x <- fread(f, colClasses = list(character = c("hex", "stn")))
stopifnot(nrow(x) == 3948, ncol(x) == 120, !anyDuplicated(x[, .(hex, stn)]), uniqueN(x$hex) == 1008)
wk <- paste0("week_", 1:6)
W <- as.matrix(x[, ..wk]); E <- as.matrix(x[, paste0("effort_week_", 1:6), with = FALSE])
D <- as.matrix(x[, paste0("date_week_", 1:6), with = FALSE])
stopifnot(all(W %in% c(0:2, NA)), sum(is.na(W)) == 398, all(is.na(W) == is.na(E)), all(is.na(W) == is.na(D)),
          all(E[!is.na(E)] > 0), all(D[!is.na(D)] >= 1 & D[!is.na(D)] <= 366))
sitecov <- names(x)[which(names(x) == "prov"):ncol(x)]
stopifnot(length(sitecov) == 64, !anyNA(x[, ..sitecov]), all(c("latitude", "longitude") %in% sitecov),
          all(x$latitude > 36 & x$latitude < 49.5), all(x$longitude > -125 & x$longitude < -119))
x[, unit := paste(hex, stn, sep = "-")]

obsv <- c("date", "effort", "noise", "precip_mn", "precip_total", "temp_max", "temp_mn", "temp_mnmax")
long <- rbindlist(lapply(1:6, function(k) {
  o <- x[, c("unit", "hex", paste0("week_", k), paste0(obsv, "_week_", k)), with = FALSE]
  setnames(o, c("unit", "cluster_id", "y", paste0("obs_", obsv)))
  o[, occasion := k]
}))
long <- long[!is.na(y)]
setnames(long, c("obs_date", "obs_effort"), c("obs_date_doy", "obs_effort_hours"))
long[, `:=`(taxon = "PIWO", y = as.integer(y), obs_date_doy = as.integer(obs_date_doy))]
uc <- x[, c("unit", sitecov), with = FALSE]
setnames(uc, sitecov, paste0("unit_", sitecov))
setnames(uc, c("unit_latitude", "unit_longitude"), c("unit_decimalLatitude", "unit_decimalLongitude"))
long <- merge(long, uc, by = "unit")
setcolorder(long, c("unit", "taxon", "occasion", "y", "cluster_id"))
setorder(long, unit, occasion)
stopifnot(nrow(long) == 3948 * 6 - 398, sum(long$y == 2) == 7753, sum(long$y == 1) == 7507)

taxa <- make_taxa("PIWO", "Dryocopus pileatus", vernacularName = "Pileated Woodpecker")
# iucn_category() returns NA: IUCN assesses the species as Hylatomus pileatus (Least
# Concern), not GBIF's accepted Dryocopus pileatus. The source's name is kept; the category
# is the IUCN assessment of the same species under its genus.
stopifnot(is.na(iucn_category(taxa$taxonID, taxa$scientificName)))
taxa[, taxon_iucnCategory := "LC"]

dataset <- list(
  title = "Pileated Woodpecker multi-state detections from 3,948 acoustic recording stations, Pacific Northwest, 2023",
  creator = "Ruff, Zachary J.; Lesmeister, Damon B.; Jenkins, Julianna M. A.", pubDate = "2025", doi = "10.5281/zenodo.15706949",
  sourceURL = "https://doi.org/10.5281/zenodo.15706949",
  citation = "Ruff, Z. J., Lesmeister, D. B., Jenkins, J. M. A., et al. (2025). Data from: Passive acoustic monitoring captures large-scale Dryocopus pileatus (Pileated Woodpecker) occupancy patterns in the Pacific Northwest, USA [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.15706949",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Weekly multi-state encounter histories of Pileated Woodpecker at autonomous recording units in about 1,000 500-ha hexagons across the Northwest Forest Plan area (western Washington and Oregon, northwestern California), from the first six weeks of 2023 recordings, with weekly recording effort, noise and weather and raw forest-structure, topographic and climate covariates per station.",
  samplingProtocol = "Passive acoustic monitoring: about four ARUs per 500-ha hexagon recording Mar-Oct 2023; audio classified with the PNW-Cnet v5 neural network (score >= 0.95 for the Pileated Woodpecker class), with manual review at stations with 10 or fewer detections; each of the first six weeks scored 0 (no detection), 1 (detections on 1-3 days) or 2 (detections on 4 or more days).",
  samplingProtocolCode = "acoustic", surveyEvidence = "effort_table", effortColumn = "obs_effort_hours",
  responseType = "state",
  stateCodes = list(`0` = "no Pileated Woodpecker detection in the week", `1` = "detections on 3 or fewer days of the week", `2` = "detections on 4 or more days of the week"),
  unitKind = "site", closure = "closed", closureNote = "six consecutive weeks of recording at each station, one season (2023)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Northwest Forest Plan area: western Washington and Oregon and northwestern California, USA", temporalCoverage = "2023-02/2023-09",
  coordinatesCoarsened = list(value = FALSE, method = "as published; Dryocopus pileatus is IUCN Least Concern, not flagged"),
  notShipped = list(Hex_Centroid_Covariate_Values_Raw.csv = "covariates at the centres of the prediction hexagons, not surveys",
                    shapefiles = "prediction grid of ~47,000 hexagons"),
  notes = "Detections come from an automated classifier (PNW-Cnet v5, threshold 0.95); only stations with 10 or fewer detections in the six weeks were reviewed by hand, so false positives are possible elsewhere. obs_date_doy is the deposited week day-of-year (58-245); no calendar date is reconstructed. Site covariates are raw, as deposited (the authors standardise them in step_2_data_prep.r).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/ruff_2025_piwo_state.R")

stage_dict_row(TABLE,
  description = "Weekly multi-state (0, 1-3 days, 4+ days) acoustic detections of Pileated Woodpecker at 3,948 recording stations in 1,008 hexagons of the US Pacific Northwest, six weeks in 2023, with weekly effort, noise and weather and raw station habitat covariates and coordinates.",
  url = "https://doi.org/10.5281/zenodo.15706949",
  reference = "Ruff, Z. J., Lesmeister, D. B., Jenkins, J. M. A., et al. Passive acoustic monitoring captures large-scale Dryocopus pileatus (Pileated Woodpecker) occupancy patterns in the Pacific Northwest, USA (in preparation at deposit).",
  doi_paper = "", doi_data = "10.5281/zenodo.15706949",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Surveys from the deposited weekly effort (NA exactly where the week is missed). Classifier detections (PNW-Cnet v5). Fetched from Zenodo.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state occupancy",
  sampling_protocol = "acoustic", design = "Single-season (6 weekly occasions)", realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "Autonomous recording units with CNN classification; ordered detection-frequency states.", status = "tagged")
