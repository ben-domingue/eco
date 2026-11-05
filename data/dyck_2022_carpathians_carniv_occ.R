#!/usr/bin/env Rscript
# Table:  dyck_2022_carpathians_carniv_occ
# Source: Dryad doi:10.5061/dryad.47d7wm3gp, version 194095 (published 2022-08-30), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record; the deposited README: "Licenses/restrictions placed on
#         the data: No"). Dyck, M. A. (sole Dryad creator) "Data for: Dracula's menagerie: A multispecies occupancy analysis
#         of lynx, wildcat, and wolf in the Romanian Carpathians".
# Paper:  Dyck, M. A., Iosif, R., Promberger-Fuerpass, B. & Popescu, V. D. (2022). Dracula's menagerie: A
#         multispecies occupancy analysis of lynx, wildcat, and wolf in the Romanian Carpathians. Ecology and
#         Evolution 12, e8921, doi:10.1002/ece3.8921 (not read; design from the README).
# Data:   six csv files and README_Draculas_menagerie.txt, for two seasons of camera trapping by Foundation
#         Conservation Carpathia rangers in the Southern Carpathians: "'Winter' files contain data from
#         2018/12/17 to 2019/3/31 and 'autumn' contain data from 2019/10/9 to 2020/1/15".
#         species_matrix_<season>.csv: TrapCode, then Lynx_1..k, Wildcat_1..k, Wolf_1..k (0/1 per session;
#           k = 8 winter, 7 autumn; the README's "_1-_7" for winter is 8 in the file), no NA.
#         Trap_Effort_<season>.csv: TrapCode x Session_1..k, days of camera activity (14 = at least one of the
#           station's cameras worked every day of the 14-day session; a day with both cameras inactive
#           subtracts one). 0 = no camera working. Three winter station-sessions have effort 0 and a detection (two lynx,
#           one wolf; asserted).
#         cams_data_<season>.csv: TrapCode, X/Y (GPS, decimal degrees, 6 decimals), Z (altitude), Impact
#           (anthropogenic impact at the station), distances to national road, settlement, stream and local
#           road (m), local road density (km/km2), TRI5 (terrain roughness, 50 m buffer), CLC2018 (CORINE
#           class at the station), CLC112..CLC512 (proportion of each CORINE class in the 2.7 x 2.7 km cell).
#         Winter has 64 stations, autumn 76 (one is "211_235"); no TrapCode is in both seasons; rows of the
#         three files of a season are in the same order (asserted).
# Mapping (standard E9 single-season multi-species occupancy, two seasons as periods):
#   unit = TrapCode; taxon = LYNLYN, FELSIL, CANLUP; period = 1 (winter 2018/19), 2 (autumn 2019);
#   occasion = session; y = detected in the session (0/1); obs_effort_days = Trap_Effort; unit_lon (X),
#   unit_lat (Y), unit_elev_m (Z), unit_impact and the distance, roughness and CORINE covariates (unit_,
#   since each station is in one season). Survey evidence: effort_table (a station-session is a survey
#   where effort > 0, or where a species was detected although effort is 0: 3 winter cells, kept with
#   obs_effort_days = 0 as deposited).
#   Coordinates: kept as published (all three species IUCN LC, asserted; no flag in the source).
#   Not shipped: nothing.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dyck_2022_carpathians_carniv_occ"
dir <- download_dryad("10.5061/dryad.47d7wm3gp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "194095"), length(list.files(dir)) == 7L)
sp <- data.table(src = c("Lynx", "Wildcat", "Wolf"), taxon = c("LYNLYN", "FELSIL", "CANLUP"),
                 sci = c("Lynx lynx", "Felis silvestris", "Canis lupus"),
                 com = c("Eurasian lynx", "European wildcat", "Grey wolf"))
seasons <- data.table(season = c("winter", "autumn"), period = 1:2, k = c(8L, 7L), n = c(64L, 76L))
rd <- function(f) { d <- fread(file.path(dir, f), colClasses = list(character = "TrapCode"), encoding = "UTF-8")
  setnames(d, 1, "TrapCode"); d }
out <- list()
for (r in seq_len(nrow(seasons))) {
  s <- seasons$season[r]; k <- seasons$k[r]
  m <- rd(paste0("species_matrix_", s, ".csv")); e <- rd(paste0("Trap_Effort_", s, ".csv")); cv <- rd(paste0("cams_data_", s, ".csv"))
  stopifnot(nrow(m) == seasons$n[r], identical(m$TrapCode, e$TrapCode), identical(m$TrapCode, cv$TrapCode),
            !anyDuplicated(m$TrapCode), identical(names(e), c("TrapCode", paste0("Session_", 1:k))),
            identical(names(m), c("TrapCode", paste0(rep(sp$src, each = k), "_", 1:k))))
  E <- as.matrix(e[, -1]); stopifnot(!anyNA(E), all(E %in% 0:14))
  Ys <- lapply(sp$src, function(x) as.matrix(m[, paste0(x, "_", 1:k), with = FALSE]))
  det_any <- Reduce(`|`, lapply(Ys, function(Y) Y == 1L))
  # a session with recorded effort 0 but a detection was surveyed (3 cells, winter only; asserted)
  stopifnot(sum(E == 0L & det_any) == c(winter = 3L, autumn = 0L)[[s]])
  surveyed <- E > 0L | det_any
  for (j in seq_len(nrow(sp))) {
    Y <- Ys[[j]]
    stopifnot(!anyNA(Y), all(Y %in% 0:1))
    Y[!surveyed] <- NA
    L <- data.table(unit = rep(m$TrapCode, k), occasion = rep(1:k, each = nrow(m)), y = c(Y), obs_effort_days = c(E))[!is.na(y)]
    L[, `:=`(taxon = sp$taxon[j], period = seasons$period[r])]
    out[[paste(s, j)]] <- L
  }
  cvs <- cv[, .(unit = TrapCode, unit_lon = X, unit_lat = Y, unit_elev_m = Z, unit_impact = Impact,
                unit_dist_natl_road_m = distnatlro, unit_dist_settlement_m = distsettle, unit_dist_stream_m = diststream,
                unit_local_road_density = denslocalr, unit_dist_local_road_m = distlocalr, unit_tri5 = TRI5,
                unit_clc2018 = CLC2018)]
  clc <- grep("^CLC[0-9]{3}$", names(cv), value = TRUE)
  stopifnot(length(clc) == 14L, all(as.matrix(cv[, ..clc]) >= 0 & as.matrix(cv[, ..clc]) <= 1), all(rowSums(cv[, ..clc]) <= 1.001))
  cvs <- cbind(cvs, setnames(cv[, ..clc], paste0("unit_prop_clc", sub("CLC", "", clc))))
  out[[paste(s, "cov")]] <- NULL
  assign(paste0("cov_", s), cvs)
}
long <- rbindlist(out, use.names = TRUE)
covs <- rbind(cov_winter, cov_autumn)
stopifnot(!anyDuplicated(covs$unit), all(covs$unit_lat > 45 & covs$unit_lat < 46), all(covs$unit_lon > 24.8 & covs$unit_lon < 25.5))
long <- merge(long, covs, by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 3L * (sum(as.matrix(rd("Trap_Effort_winter.csv")[, -1]) > 0) + 3L + sum(as.matrix(rd("Trap_Effort_autumn.csv")[, -1]) > 0)),
          long[obs_effort_days == 0L, .N] == 9L)

taxa <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$com)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, rep("LC", 3)))
periods <- data.table(period = 1:2, period_season = c("winter 2018/19", "autumn 2019"),
                      period_start = c("2018-12-17", "2019-10-09"), period_end = c("2019-03-31", "2020-01-15"))

dataset <- list(
  title = "Camera-trap detections of Eurasian lynx, European wildcat and grey wolf at 140 stations in the Southern Carpathians, Romania, winter 2018/19 and autumn 2019",
  creator = "Dyck, Marissa A.",
  pubDate = "2022", doi = "10.5061/dryad.47d7wm3gp", sourceURL = "https://doi.org/10.5061/dryad.47d7wm3gp",
  citation = "Dyck, M. A. (2022). Data for: Dracula's menagerie: A multispecies occupancy analysis of lynx, wildcat, and wolf in the Romanian Carpathians [Dataset]. Dryad. https://doi.org/10.5061/dryad.47d7wm3gp",
  paperDOI = "10.1002/ece3.8921",
  abstract = "Camera trapping by Foundation Conservation Carpathia rangers in the forests of the Southern Carpathians, Romania, in two seasons (December 2018 to March 2019 at 64 stations; October 2019 to January 2020 at 76 other stations), pooled into 14-day sessions, with each station's terrain, road, settlement and land-cover covariates. The authors fitted multispecies occupancy models to ask how the three carnivores co-occur.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Camera-trap stations (paired cameras) run for a season; detections pooled to 14-day sessions; obs_effort_days counts the session's days with at least one working camera.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", effortColumn = "obs_effort_days",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "sessions within one season; each season is a separate set of stations",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Southern Carpathians (Fagaras mountains area), Romania; station coordinates as published",
  temporalCoverage = "2018-12/2020-01",
  coordinatesCoarsened = list(value = FALSE, method = "station coordinates as deposited (decimal degrees, 6 decimals); all three species IUCN Least Concern and none flagged by the source"),
  covariateNote = "unit_impact: anthropogenic impact at the station as recorded (None, Low, Logging, Tourism, Village, Isolated buildings). Distances in metres; unit_local_road_density in km/km2; unit_tri5: terrain roughness index in a 50 m buffer; unit_clc2018: CORINE 2018 class at the station; unit_prop_clcNNN: proportion of CORINE class NNN in the station's 2.7 x 2.7 km cell.",
  notes = "Winter has 8 sessions and autumn 7. Stations are different in the two seasons, so period separates two station sets rather than revisits. Station-sessions with no working camera have no rows, except three winter sessions with recorded effort 0 and a detection, which are kept as surveyed with obs_effort_days = 0 as deposited.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dyck_2022_carpathians_carniv_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection of Eurasian lynx, European wildcat and grey wolf in 14-day sessions at 140 stations in the Southern Carpathians, Romania, winter 2018/19 and autumn 2019, with effort and landscape covariates.",
  url = "https://doi.org/10.5061/dryad.47d7wm3gp",
  reference = "Dyck, M. A., Iosif, R., Promberger-Fuerpass, B., & Popescu, V. D. (2022). Dracula's menagerie: A multispecies occupancy analysis of lynx, wildcat, and wolf in the Romanian Carpathians. Ecology and Evolution, 12, e8921.",
  doi_paper = "10.1002/ece3.8921", doi_data = "10.5061/dryad.47d7wm3gp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; two seasons stacked as periods; effort per session shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-species, single season)",
  sampling_protocol = "camera_trap", design = "Single-season (two seasons at different stations, 7-8 sessions of 14 days)",
  realm = "Terrestrial", country = "ROU", coordinates = "As published",
  notes = "European large carnivores; effort-weighted sessions.")
