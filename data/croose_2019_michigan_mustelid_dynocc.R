#!/usr/bin/env Rscript
# Table:  croose_2019_michigan_mustelid_dynocc
# Source: Dryad doi:10.5061/dryad.452n6d3 (CC0 1.0, as shown on the Dryad page; published
#         2019-04-03). Croose, E., Bled, F., Fowler, N.L., Beyer, D.E. Jr. & Belant, J.L. Data
#         from: American marten and fisher do not segregate in space and time during winter in a
#         mixed-forest system.
# Paper:  Croose, E. et al. (2019). Ecology and Evolution 9(8), doi:10.1002/ece3.5097. Camera
#         traps in 64 grid cells in the Upper Peninsula of Michigan, three winters (2012-13 to
#         2014-15), "each with 4 secondary periods (i.e. data pooled in 4, 2-week sessions per
#         site, per year)" (README); dynamic occupancy (unmarked colext).
# Data:   one xlsx: Covariates (64 cells: Site.ID, Easting, Northing (UTM, zone not named;
#         values fit UTM 16N), standardized road, hydrology, distance to hydrology, DEA, and
#         land-cover proportions); Marten / Fisher detection data (64 cells x 12 periods
#         1.1-3.4 = year.session, 0/1, NA where not surveyed: 18 cells, identical in both,
#         asserted); Effort (camera-days per cell-period, 0-16; 0 exactly where detections are
#         NA, asserted); Temporal data (photo date-times per detection, seasons 12-13 to 14-15:
#         not shipped, the detections behind the histories); R code.
# Mapping (standard: dynamic community occupancy, E9 core): unit = cell number; taxon = MARAME,
#   PEKPEN; period = winter 1..3 (__periods); occasion = 2-week session 1..4; y = the cell;
#   NA = no row; obs_effort_days (effortColumn). unit_: covariates; coordinates as published
#   (both species IUCN LC).
#   Survey evidence: effort_table: a survey is a cell-session with effort > 0 (= detections not NA).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "croose_2019_michigan_mustelid_dynocc"
dir <- download_dryad("10.5061/dryad.452n6d3", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
g <- function(s) { d <- as.data.frame(suppressMessages(read_excel(f, s, col_names = FALSE, skip = 2))); m <- suppressWarnings(matrix(as.numeric(as.matrix(d[, 2:13])), nrow(d))); list(id = as.character(d[[1]]), m = m) }
a <- g("Marten detection data"); b <- g("Fisher detection data"); e <- g("Effort")
stopifnot(length(a$id) == 64, identical(a$id, b$id), identical(a$id, e$id), identical(is.na(a$m), is.na(b$m)), !anyNA(e$m), identical(is.na(a$m), e$m == 0),
          sum(is.na(a$m)) == 18, all(a$m %in% c(0, 1, NA)), all(b$m %in% c(0, 1, NA)))
e$m[e$m == 0] <- NA
cv <- as.data.table(read_excel(f, "Covariates")); stopifnot(identical(as.character(cv$`Cell number`), a$id))
Y <- array(c(a$m, b$m), dim = c(64, 12, 2), dimnames = list(a$id, NULL, c("MARAME", "PEKPEN")))
sc <- as.data.frame(cv[, .(easting = Easting, northing = Northing, road_std = road.cell, hydro_std = hydro.cell, dist_hydro_std = dist.from.hydro,
                           dea_std = DEA, evergreen = Evergreen, mixed = Mixed, shrub = Shrub, grass = Grass, ww = WW, ehw = EHW, unsuitable = Unsuitable, aspen = Aspen)])
long <- array_to_eco(Y, site_ids = a$id, site_covs = sc, obs_covs = list(effort_days = e$m), period = rep(1:3, each = 4))
long <- order_eco(long)
stopifnot(nrow(long) == 2 * sum(!is.na(a$m)), all(long$obs_effort_days > 0), max(long$occasion) == 4)
periods <- data.table(period = 1:3, period_winter = c("2012-13", "2013-14", "2014-15"))
taxa <- make_taxa(c("MARAME", "PEKPEN"), c("Martes americana", "Pekania pennanti"), vernacularName = c("American marten", "Fisher"))
dataset <- list(
  title = "Camera-trap detections of American marten and fisher in 64 cells of Michigan's Upper Peninsula, three winters x four 2-week sessions",
  creator = "Croose, Elizabeth; Bled, Florent; Fowler, Nicholas L.; Beyer, Dean E., Jr.; Belant, Jerrold L.", pubDate = "2019",
  doi = "10.5061/dryad.452n6d3", sourceURL = "https://doi.org/10.5061/dryad.452n6d3",
  citation = "Croose, E., Bled, F., Fowler, N. L., Beyer, D. E., Jr., & Belant, J. L. (2019). Data from: American marten and fisher do not segregate in space and time during winter in a mixed-forest system [Dataset]. Dryad. https://doi.org/10.5061/dryad.452n6d3",
  paperDOI = "10.1002/ece3.5097",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of American marten and fisher in four 2-week sessions per winter at camera traps in 64 grid cells of the Upper Peninsula of Michigan, winters 2012-13 to 2014-15, with camera-days per session and cell land-cover covariates and coordinates.",
  samplingProtocol = "Camera traps in grid cells operated through winter; detections pooled into four 2-week sessions per winter, with camera-days operating per session.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "closed within a winter's four sessions, open between winters (colext)", occasionKind = "time",
  taxonInclusion = "target", effortColumn = "obs_effort_days", crs = "UTM as deposited, zone not named (values consistent with UTM zone 16N)",
  geographicCoverage = "Upper Peninsula of Michigan, USA", temporalCoverage = "2013-01/2015-03",
  coordinatesCoarsened = list(value = FALSE, method = "as published: American marten and fisher are IUCN LC"),
  notShipped = list(temporal_data = "photo date-times behind the histories (activity overlap analysis)"),
  notes = "Covariates other than land-cover proportions are standardized as deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/croose_2019_michigan_mustelid_dynocc.R")
stage_dict_row(TABLE, description = "Camera-trap detections of American marten and fisher in 64 cells of Michigan's Upper Peninsula, three winters x four 2-week sessions, with effort.",
  url = "https://doi.org/10.5061/dryad.452n6d3", reference = "Croose, E. et al. (2019). American marten and fisher do not segregate in space and time during winter in a mixed-forest system. Ecology and Evolution, 9(8).",
  doi_paper = "10.1002/ece3.5097", doi_data = "10.5061/dryad.452n6d3", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic two-species occupancy with effort.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic community occupancy",
  sampling_protocol = "camera_trap", design = "Multi-season (3 winters x 4 sessions)", realm = "Terrestrial",
  country = "USA", coordinates = "As published", notes = "Marten and fisher.")
