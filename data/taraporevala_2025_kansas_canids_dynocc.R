#!/usr/bin/env Rscript
# Table:  taraporevala_2025_kansas_canids_dynocc
# Source: Dryad doi:10.5061/dryad.d51c5b0ck (CC0 1.0, as shown on the Dryad page; published
#         2025-02-04). Taraporevala, N., Beckmann, J. & Young, J. Citizen science project on
#         urban canids provides different results from camera traps but generates interest and
#         revenue.
# Paper:  Taraporevala, N., Beckmann, J. & Young, J. (2025). Wildlife Biology,
#         doi:10.1002/wlb3.01382. Camera traps and a citizen-science sighting project on urban
#         coyotes and red foxes; the README dates the citizen sightings March 2023 - February
#         2024 and links advertising to the Kansas Department of Wildlife and Parks (KDWP).
# Data:   coyoteDetectionHistory.csv, redfoxDetectionHistory.csv (74 camera locations (CamLoc =
#         camera id + location A / B, a moved camera being a new location) x 20 weeks: SP1-5,
#         SU1-5, UT1-5 (fall), WI1-5; 1 / 0, NA where the camera did not run);
#         Days_Cameras_Working_by_Week.csv (days active per camera-week, 0-7; 0 exactly where the
#         histories are NA, asserted); cameraCovariates.csv (distance to road and water (m),
#         building density (% within 1 km), median household income (USD within 1 km));
#         separated detection, people and sighting files and advertising data (not detection
#         histories). README.md describes all.
# Mapping (standard: dynamic community occupancy, E9 core): unit = CamLoc; taxon = CANLAT,
#   VULVUL; period = season 1..4 (spring, summer, fall, winter, as deposited; __periods);
#   occasion = week 1..5; y = the cell; NA = no row; obs_effort_days = days active
#   (effortColumn). unit_: the four covariates. Survey evidence: effort_table.
#   Not shipped: people detections and citizen-science sightings (not camera surveys of the
#   canids), advertising data. No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "taraporevala_2025_kansas_canids_dynocc"
dir <- download_dryad("10.5061/dryad.d51c5b0ck", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
co <- rf("coyoteDetectionHistory\\.csv"); rx <- rf("redfoxDetectionHistory\\.csv"); ef <- rf("Days_Cameras_Working_by_Week\\.csv"); cv <- rf("cameraCovariates\\.csv")
W <- paste0(rep(c("SP", "SU", "UT", "WI"), each = 5), 1:5)
stopifnot(identical(names(co), c("CamLoc", W)), identical(names(rx), names(co)), identical(names(ef), names(co)), nrow(co) == 74,
          identical(co$CamLoc, rx$CamLoc), identical(co$CamLoc, ef$CamLoc), setequal(cv$CamLoc, co$CamLoc), !anyDuplicated(co$CamLoc))
E <- as.matrix(ef[, ..W]); C <- as.matrix(co[, ..W]); R <- as.matrix(rx[, ..W])
stopifnot(identical(is.na(C), E == 0), identical(is.na(R), is.na(C)), all(C %in% c(0, 1, NA)), all(R %in% c(0, 1, NA)), all(E >= 0 & E <= 7))
mk <- function(M, code) data.table(unit = rep(co$CamLoc, 20), j = rep(1:20, each = 74), y = as.vector(M), e = as.vector(E), taxon = code)
long <- rbind(mk(C, "CANLAT"), mk(R, "VULVUL"))[!is.na(y)]
long[, `:=`(period = (j - 1L) %/% 5L + 1L, occasion = (j - 1L) %% 5L + 1L, y = as.integer(y), obs_effort_days = as.integer(e))][, c("j", "e") := NULL]
long <- merge(long, cv[, .(unit = CamLoc, unit_road_dist_m = RoadDistM, unit_water_dist_m = DistWaterM, unit_building_density_pct = BuildingDensity, unit_median_income_usd = Income)], by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 2 * sum(!is.na(C)), all(long$obs_effort_days > 0))
periods <- data.table(period = 1:4, period_season = c("spring", "summer", "fall", "winter"))
taxa <- make_taxa(c("CANLAT", "VULVUL"), c("Canis latrans", "Vulpes vulpes"), vernacularName = c("Coyote", "Red fox"))
dataset <- list(
  title = "Weekly camera-trap detections of coyotes and red foxes at 74 urban camera locations in Kansas across four seasons",
  creator = "Taraporevala, Neville; Beckmann, Jon; Young, Julie", pubDate = "2025", doi = "10.5061/dryad.d51c5b0ck", sourceURL = "https://doi.org/10.5061/dryad.d51c5b0ck",
  citation = "Taraporevala, N., Beckmann, J., & Young, J. (2025). Citizen science project on urban canids provides different results from camera traps but generates interest and revenue [Dataset]. Dryad. https://doi.org/10.5061/dryad.d51c5b0ck",
  paperDOI = "10.1002/wlb3.01382",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Weekly detection/non-detection of coyote and red fox at 74 urban camera locations over five weeks in each of spring, summer, fall and winter, with days active per camera-week and distance to road and water, building density and median household income around each camera.",
  samplingProtocol = "Camera traps at urban locations (a camera moved during the study counts as a new location), five weekly occasions per season in four seasons; days active recorded per week.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "closed within a season's five weeks, open between the four seasons", occasionKind = "time",
  taxonInclusion = "target", effortColumn = "obs_effort_days",
  geographicCoverage = "An urban area in Kansas, USA (the project worked with the Kansas Department of Wildlife and Parks; see the paper); no coordinates deposited",
  temporalCoverage = "2023/2024",
  notShipped = list(sightings = "citizen-science sightings and the separated detection / people files (not camera survey histories)", ads = "advertising performance data"),
  notes = "Seasons in deposit order (spring, summer, fall, winter); the camera survey dates are not in the deposit (the citizen-science sightings run March 2023 - February 2024).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/taraporevala_2025_kansas_canids_dynocc.R")
stage_dict_row(TABLE, description = "Weekly camera-trap detections of coyotes and red foxes at 74 urban camera locations in Kansas over four seasons, with effort and urban covariates.",
  url = "https://doi.org/10.5061/dryad.d51c5b0ck", reference = "Taraporevala, N., Beckmann, J., & Young, J. (2025). Citizen science project on urban canids provides different results from camera traps but generates interest and revenue. Wildlife Biology.",
  doi_paper = "10.1002/wlb3.01382", doi_data = "10.5061/dryad.d51c5b0ck", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic two-species occupancy with weekly effort.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic community occupancy",
  sampling_protocol = "camera_trap", design = "Multi-season (4 seasons x 5 weeks)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Urban canids.")
