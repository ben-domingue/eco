#!/usr/bin/env Rscript
# Table:  betancur_2021_antioquia_birds_count
# Source: Dryad doi:10.5061/dryad.w9ghx3fmc, version 301890 (version 9, published 2024-06-27),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Parra, J., Betancur, J. & Morales, A. "Occupancy of two Colombian endemic birds (Habia
#         gutturalis) and White-Mantled Barbet (Capito hypoleucus) in fragmented forests of the
#         Central Andes in Colombia".
# Paper:  Betancur, J. S., Morales-Rozo, A. & Parra, J. L. (2021). Occupancy of the Sooty
#         Ant-Tanager (Habia gutturalis) and White-Mantled Barbet (Capito hypoleucus) in
#         fragmented forests of the Central Andes in Colombia. Ornitología Colombiana, e383,
#         doi:10.59517/oc.e383 (not read; design from the Dryad methods, README and scripts).
# Data:   README.md; CH_single_season.R and HG_single_season.R (the authors' unmarked scripts,
#         read: they bind Detection_histories rows to the point covariates by row order);
#   Detection_histories.csv  140 rows: Species, then the number of individuals counted at each of
#                            four visits (2014-1, 2014-2, 2015-1, 2015-2); rows 1-70 Capito
#                            hypoleucus, 71-140 Habia gutturalis, each in the point order of the
#                            covariate files (no point id column; the authors' scripts read it so).
#                            No NA: every point was visited four times.
#   Detection_covariates.csv per point x covariate, four visit columns: survey time for each
#                            species (the times differ between the species at some visits), its
#                            arcsine-sqrt transform (the authors' derivation), daily mean
#                            temperature (deg C), precipitation of the previous day (mm).
#   Occupancy_covariates.csv per point: elevation (m), forest and mosaic cover (% of a 125 m
#                            radius), distance to streams and to impoundments (m), nests depredated
#                            in an artificial-nest experiment in 2014 and 2015.
#   Point_counts.csv         per point: department, municipality, WGS 84 longitude / latitude.
#   Design (Dryad methods): 70 point counts of 125 m radius (14 transects of five points 250 m
#   apart) in the buffer zones of two hydroelectric impoundments, Antioquia; each point surveyed
#   for 30 min on two consecutive days (one observer per year) in June-July 2014 and 2015.
#
# Mapping (standard E9 community abundance / N-mixture, responseType count, unitKind site):
#   unit = point id (trimmed), taxon = CAPHYP, HABGUT, period = year 1..2 (2014, 2015), occasion =
#   visit 1..2 within the year, y = individuals counted; cluster_id = transect (the point id
#   before the last underscore). observer = AMR (2014) or JSB (2015), from the methods.
#   obs_time_local (HH:MM, the species' own survey time; varies across taxa within a visit, E5),
#   obs_temp, obs_precip_prev_day; unit_elevation, unit_forest, unit_mosaic, unit_dist_stream,
#   unit_dist_impoundment, unit_department, unit_municipality, unit_lat, unit_lon;
#   period_nests_depredated.
#   Survey evidence: deposited_matrix (complete; every point x visit has a count for both species).
#   Coordinates: the source calls both species endangered endemics (Dryad abstract), so they are
#   flagged taxa (E7) and point coordinates are coarsened to the 0.1 degree cell with
#   coarsen_coords().
#   Not shipped: the arcsine-sqrt time transforms (derived by the authors); exact coordinates
#   (coarsened).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "betancur_2021_antioquia_birds_count"
dir <- download_dryad("doi:10.5061/dryad.w9ghx3fmc", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "301890"), length(list.files(dir)) == 7L)
h  <- fread(file.path(dir, "Detection_histories.csv"))
dc <- fread(file.path(dir, "Detection_covariates.csv"), colClasses = "character")
oc <- fread(file.path(dir, "Occupancy_covariates.csv"))
pc <- fread(file.path(dir, "Point_counts.csv"))
setnames(dc, 2, "pt"); dc[, pt := trimws(pt)]
pts <- trimws(oc[[1]])
stopifnot(identical(names(h), c("Species", "2014-1", "2014-2", "2015-1", "2015-2")), nrow(h) == 140L,
          identical(h$Species, rep(c("Capito hypoleucus", "Habia gutturalis"), each = 70L)),
          !anyNA(h), all(unlist(h[, -1]) %in% 0:4),
          length(pts) == 70L, !anyDuplicated(pts), identical(trimws(pc[[3]]), pts),
          all(vapply(split(dc$pt, dc$covariate), identical, logical(1), pts)), uniqueN(dc$covariate) == 6L,
          identical(as.integer(table(unlist(h[, -1]))), c(461L, 69L, 22L, 7L, 1L)))
vis <- c("Survey2014_1", "Survey2014_2", "Survey2015_1", "Survey2015_2")
cov <- function(name) { m <- as.matrix(dc[covariate == name, ..vis]); stopifnot(nrow(m) == 70L); m }
TM <- list(CAPHYP = cov("time of the survey Capito hypoleucus"), HABGUT = cov("time of the survey Habia gutturalis"))
TEMP <- matrix(as.numeric(cov("daily average temperatureduring the survey")), 70)
PREC <- matrix(as.numeric(cov("precipitation of the previous day")), 70)
stopifnot(!anyNA(TEMP), !anyNA(PREC), all(grepl("^[0-9]{1,2}:[0-9]{2}:00 [AP]M$", unlist(TM))))
hhmm <- function(x) format(as.POSIXct(x, format = "%I:%M:%S %p", tz = "UTC"), "%H:%M")

long <- rbindlist(lapply(c("CAPHYP", "HABGUT"), function(tx) {
  Y <- as.matrix(h[if (tx == "CAPHYP") 1:70 else 71:140, -1])
  rbindlist(lapply(1:4, function(v) data.table(
    unit = pts, taxon = tx, y = as.integer(Y[, v]), period = (v + 1L) %/% 2L, occasion = 2L - v %% 2L,
    observer = if (v <= 2L) "AMR" else "JSB", cluster_id = sub("_[0-9]+$", "", pts),
    obs_time_local = hhmm(TM[[tx]][, v]), obs_temp = TEMP[, v], obs_precip_prev_day = PREC[, v])))
}))
cc <- coarsen_coords(pc[[5]], pc[[4]])
uc <- data.table(unit = pts, unit_department = pc$Departament, unit_municipality = pc$Municipality,
                 unit_lat = cc$lat, unit_lon = cc$lon,
                 unit_elevation = oc[["Elevation (m)"]], unit_forest = oc[["Forest (%)"]], unit_mosaic = oc[["Mosaic (%)"]],
                 unit_dist_stream = oc[["Euclidean distance to streams (m)"]],
                 unit_dist_impoundment = oc[["Euclidean distance to impoundments (m)"]])
pr <- rbind(data.table(unit = pts, period = 1L, period_nests_depredated = oc[["Nests depredated_2014"]]),
            data.table(unit = pts, period = 2L, period_nests_depredated = oc[["Nests depredated_2015"]]))
long <- merge(merge(long, uc, by = "unit"), pr, by = c("unit", "period"))
long <- order_eco(long)
stopifnot(nrow(long) == 70L * 4L * 2L, sum(long$y) == 69L + 2L * 22L + 3L * 7L + 4L,
          all(pc[[5]] > 5.5 & pc[[5]] < 7), all(pc[[4]] > -76 & pc[[4]] < -74))

taxa <- make_taxa(c("CAPHYP", "HABGUT"), c("Capito hypoleucus", "Habia gutturalis"),
                  vernacularName = c("White-mantled barbet", "Sooty ant-tanager"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
periods <- data.table(period = 1:2, year = 2014:2015, observer = c("AMR", "JSB"), months = "June-July")

dataset <- list(
  title = "Repeated point counts of two endemic birds (white-mantled barbet, sooty ant-tanager) at 70 points in fragmented Andean forest, Antioquia, Colombia, 2014-2015",
  creator = "Parra, Juan; Betancur, Jefry; Morales, Andrea",
  pubDate = "2024", doi = "10.5061/dryad.w9ghx3fmc", sourceURL = "https://doi.org/10.5061/dryad.w9ghx3fmc",
  citation = "Parra, J., Betancur, J., & Morales, A. (2024). Occupancy of two Colombian endemic birds (Habia gutturalis) and White-Mantled Barbet (Capito hypoleucus) in fragmented forests of the Central Andes in Colombia [Dataset]. Dryad. https://doi.org/10.5061/dryad.w9ghx3fmc",
  paperDOI = "10.59517/oc.e383",
  abstract = "Counts of Capito hypoleucus and Habia gutturalis, endemic birds of Colombia, at 70 point counts in fragmented secondary forest in the buffer zones of two hydroelectric impoundments in the Central Andes (Antioquia), each surveyed on two consecutive days in June-July of 2014 and 2015, with landscape, weather and nest-predation covariates. The paper fits single-season occupancy models to the detections.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Point counts of 125 m radius on 14 transects of five points 250 m apart; after three minutes of silence an observer recorded all individuals of the two target species seen or heard during 30 minutes between 06:00 and 10:00, on two consecutive days per year (one observer in 2014, another in 2015).",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "two visits on consecutive days within each year; the paper treats all four visits as one season",
  occasionKind = "time", taxonInclusion = "target",
  temporalCoverage = "2014-06/2015-07",
  geographicCoverage = "Buffer zones of the Punchiná and San Lorenzo hydroelectric impoundments, San Carlos, San Rafael, Alejandría and San Roque, Antioquia, Colombia (580-1420 m)",
  coordinatesCoarsened = list(value = TRUE, method = "point coordinates (WGS 84, deposited to 1e-8 degree) coarsened to the 0.1 degree cell centre with coarsen_coords(): the source describes both species as endangered endemics"),
  notes = "The count rows are bound to point ids by row order, as in the authors' scripts (Detection_histories.csv has no id column; the order of the covariate files is asserted identical). obs_time_local is the species' own survey time and differs between the two species at some visits. The paper analyses detection / non-detection (counts > 0); the deposit gives counts. Observers per year from the Dryad methods. taxon_iucnCategory is GBIF's IUCN record (LC for both); coordinates are coarsened because the source itself calls both species endangered (E7 flag: the source says so).",
  notShipped = list(time_transforms = "arcsine-square-root transforms of survey time (derived by the authors)",
                    exact_coordinates = "coarsened to 0.1 degree (flagged taxa)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/betancur_2021_antioquia_birds_count.R")
stage_dict_row(TABLE,
  description = "Repeated counts of two endemic Colombian birds (Capito hypoleucus, Habia gutturalis) at 70 point counts in fragmented Andean forest around two hydroelectric impoundments in Antioquia, two visits a year in 2014 and 2015, with landscape, weather and nest-predation covariates; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.w9ghx3fmc",
  reference = "Betancur, J. S., Morales-Rozo, A., & Parra, J. L. (2021). Occupancy of the Sooty Ant-Tanager (Habia gutturalis) and White-Mantled Barbet (Capito hypoleucus) in fragmented forests of the Central Andes in Colombia. Ornitología Colombiana, e383.",
  doi_paper = "10.59517/oc.e383", doi_data = "10.5061/dryad.w9ghx3fmc",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Counts bound to points by row order (as the authors' scripts); coordinates coarsened (source calls both species endangered).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture / occupancy (two target species, two seasons)",
  sampling_protocol = "point_count", design = "Multi-season (2 years x 2 visits)",
  realm = "Terrestrial", country = "COL", coordinates = "Coarsened (0.1 deg)",
  notes = "Two endemic target species; counts of individuals per 30-min point count.")
