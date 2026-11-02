#!/usr/bin/env Rscript
# Table:  hepler_2018_serengeti_gazelle_occ
# Source: Dryad doi:10.5061/dryad.34kb373 (CC0 1.0, version 5974, published 2019-05-03)
#   Hepler, S. A., Erhardt, R., Anderson, T. M. (2019). Data from: Identifying drivers of
#   spatial variation in occupancy with limited replication camera trap data. Dryad.
# Paper:  Hepler, S. A., Erhardt, R. J., Anderson, T. M. (2018). Identifying drivers of
#   spatial variation in occupancy with limited replication camera trap data. Ecology
#   99(10):2152-2158. doi:10.1002/ecy.2396 (paywalled; the abstract and the deposit README
#   are the sources used here). Cameras are the Snapshot Serengeti grid (Swanson et al.
#   2015, Scientific Data 2:150026).
# Data:   one CSV, 5,669 rows x 14 columns, one row per camera x 8-day time window in which
#         the camera was on for at least one day: Camera (1-194), TimePeriod (1-46; the
#         windows are calendar-aligned across cameras, since Rain is constant within a
#         window), NDVI (MODIS, per camera x window), Rain (1 if monthly rainfall at the
#         window's start date exceeded 100 mm; per window), River Distance (m, per camera),
#         Fire (per camera x window, 10 rows), Sparse / Moderate / Dense Tree indicators
#         (per camera; 1-10, 11-30, >30 trees > 2 m within 50 m; 688 rows have none of the
#         three), Latitude, Longitude (degrees, per camera), Days (1-8, days the camera was
#         on and functioning in the window), Forest (= Moderate or Dense), Thomson's
#         Gazelle (1 if observed at the camera during the window). No NA anywhere. The
#         README gives no calendar date for window 1 and no year; the rain pattern (windows
#         13-16 and 43-46 wet) matches the Serengeti short and long rains, so the 46 windows
#         (368 days) span about one year, but the year is not recoverable from the deposit.
#
# Mapping (standard E9, single-season occupancy from a camera x window table with effort):
#   unit = camera (deposit index), taxon = EUDTHO, occasion = TimePeriod (1-46, 8-day
#   window, calendar-aligned), y = Thomson's Gazelle 0/1, one period. The paper treats each
#   window as a season with one survey and borrows strength across space and time; the
#   same rows serve a plain occupancy fit with 46 occasions. Survey evidence: a row exists
#   iff the camera was on for >= 1 day in the window (Days >= 1, asserted), so
#   surveyEvidence = effort_table with obs_camera_days the effort. No `date`: the window's
#   calendar date is not deposited (E8 forbids a bare window index as a date).
#   Covariates: obs_ndvi, obs_rain_gt100mm (constant within a window across cameras, so
#   occasion-level; carried as obs_ since there is no occasion prefix), obs_fire,
#   obs_camera_days; unit_river_distance_m, unit_sparse_tree, unit_moderate_tree,
#   unit_dense_tree, unit_forest, unit_decimalLatitude, unit_decimalLongitude as published
#   (Thomson's gazelle is IUCN Least Concern; Snapshot Serengeti publishes camera
#   locations). NDVI is a satellite index, not a model output, and is kept.
#   Not shipped: nothing; every deposited column is carried.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hepler_2018_serengeti_gazelle_occ"
dir <- download_dryad("10.5061/dryad.34kb373", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
raw <- fread(file.path(dir, "Serengeti_Thomsons_Gazelle_Application_Data.csv"))
setnames(raw, c("camera", "window", "ndvi", "rain", "river_dist", "fire", "sparse", "moderate", "dense",
                "lat", "lon", "days", "forest", "gazelle"))

# facts about the source
stopifnot(nrow(raw) == 5669, ncol(raw) == 14, !anyNA(raw),
          uniqueN(raw$camera) == 194, setequal(raw$camera, 1:194),
          uniqueN(raw$window) == 46, setequal(raw$window, 1:46),
          !anyDuplicated(raw[, .(camera, window)]),
          all(raw$days %in% 1:8), sum(raw$days == 8) == 5081,
          all(raw$gazelle %in% 0:1), sum(raw$gazelle) == 878,
          all(raw$rain %in% 0:1), sum(raw$fire) == 10,
          all(raw$sparse + raw$moderate + raw$dense %in% 0:1), sum(raw$sparse + raw$moderate + raw$dense == 0) == 688,
          all(raw$forest == pmax(raw$moderate, raw$dense)),
          all(raw$lat > -2.7 & raw$lat < -2.3), all(raw$lon > 34.7 & raw$lon < 35.3))
# camera-level columns are constant within camera; rain is constant within window
unit_const <- raw[, lapply(.SD, uniqueN), by = camera, .SDcols = c("river_dist", "sparse", "moderate", "dense", "forest", "lat", "lon")]
stopifnot(all(unit_const[, -1] == 1))
stopifnot(all(raw[, uniqueN(rain), by = window]$V1 == 1))
wet <- raw[, .(rain = rain[1]), by = window][order(window)]
stopifnot(identical(wet[rain == 1, window], c(13:16, 43:46)))

long <- raw[, .(unit = camera, taxon = "EUDTHO", y = gazelle, occasion = window,
                unit_river_distance_m = river_dist, unit_sparse_tree = sparse, unit_moderate_tree = moderate,
                unit_dense_tree = dense, unit_forest = forest, unit_decimalLatitude = lat, unit_decimalLongitude = lon,
                obs_camera_days = days, obs_ndvi = ndvi, obs_rain_gt100mm = rain, obs_fire = fire)]
long <- order_eco(long)
stopifnot(nrow(long) == 5669, uniqueN(long$unit) == 194, sum(long$y) == 878)
cat(sprintf("  %d cameras, %d camera-windows, %d camera-days, %d windows with a detection\n",
            uniqueN(long$unit), nrow(long), sum(long$obs_camera_days), sum(long$y)))

taxa <- make_taxa("EUDTHO", "Eudorcas thomsonii", vernacularName = "Thomson's gazelle")
dataset <- list(
  title = "Thomson's gazelle detection/non-detection per camera and 8-day window, Snapshot Serengeti grid, Tanzania",
  creator = "Hepler, Staci A.; Erhardt, Robert J.; Anderson, T. Michael", pubDate = "2019", doi = "10.5061/dryad.34kb373",
  sourceURL = "https://doi.org/10.5061/dryad.34kb373",
  citation = "Hepler, S. A., Erhardt, R., Anderson, T. M. (2019). Data from: Identifying drivers of spatial variation in occupancy with limited replication camera trap data [Dataset]. Dryad. https://doi.org/10.5061/dryad.34kb373",
  paperCitation = "Hepler, S. A., Erhardt, R. J., Anderson, T. M. (2018). Identifying drivers of spatial variation in occupancy with limited replication camera trap data. Ecology 99(10):2152-2158. https://doi.org/10.1002/ecy.2396",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Occupancy models are widely used in camera trap studies to analyze species presence, abundance, and geographic distribution. These models account for imperfect detection using a latent variable to distinguish between true presence/absence and observed detection. Under certain experimental setups, parameter estimation in a latent variable framework can be challenging. Several studies have issued guidelines on the number of independent replicated surveys needed for each unchanging occupancy field (season) to ensure reliable estimation. The paper presents a spatio-temporal occupancy model that can be fit to data obtained from a single survey per season, so long as the number of seasons is sufficiently large, with an application to camera-trap data on the Thomson's gazelle in the Serengeti, Tanzania (paper abstract). The deposit is the application data: 194 Snapshot Serengeti cameras x 46 eight-day windows, with MODIS NDVI, a monthly-rainfall indicator, fire, tree density classes, distance to river, camera coordinates and camera-days of operation.",
  samplingProtocol = "Snapshot Serengeti camera-trap grid (Swanson et al. 2015); for each camera and consecutive 8-day window, 1 if a Thomson's gazelle was photographed at the camera during the window, 0 otherwise; days the camera was on and functioning in the window (1-8) in obs_camera_days.",
  samplingProtocolCode = "camera_trap", occasionLength = "8 days", effortColumn = "obs_camera_days",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = list(description = "Snapshot Serengeti camera grid, central Serengeti National Park, Tanzania",
                            boundingBox = list(west = min(long$unit_decimalLongitude), east = max(long$unit_decimalLongitude),
                                               south = min(long$unit_decimalLatitude), north = max(long$unit_decimalLatitude))),
  temporalCoverage = "46 consecutive 8-day windows (368 days); calendar dates and year not deposited",
  crs = "WGS84 assumed (README: degrees N / degrees E)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published; Thomson's gazelle is IUCN Least Concern and Snapshot Serengeti publishes its camera locations"),
  notes = "Occasions are calendar-aligned 8-day windows shared by all cameras (the rainfall indicator is constant within a window), so the table can be read either as the paper's one-survey-per-season design with 46 seasons or as one season with 46 occasions. The window's start date is not deposited, so there is no date column; the wet windows (13-16, 43-46) fall where the Serengeti short and long rains would. obs_rain_gt100mm is constant within an occasion across cameras (occasion-level), carried under the obs_ prefix. The three tree-density indicators and unit_forest are shipped as deposited (unit_forest = unit_moderate_tree or unit_dense_tree); 688 camera-windows (at cameras with no trees within 50 m) have all three indicators 0.",
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/hepler_2018_serengeti_gazelle_occ.R")

stage_dict_row(TABLE,
  description = "Thomson's gazelle detection/non-detection at 194 Snapshot Serengeti cameras over 46 consecutive 8-day windows (5,669 camera-windows with >= 1 operating day), with camera-days of effort, MODIS NDVI and a rainfall indicator per window, fire, tree-density classes, distance to river and camera coordinates.",
  url = "https://doi.org/10.5061/dryad.34kb373",
  reference = "Hepler, S. A., Erhardt, R. J., Anderson, T. M. (2018). Identifying drivers of spatial variation in occupancy with limited replication camera trap data. Ecology 99(10):2152-2158.",
  doi_paper = "10.1002/ecy.2396", doi_data = "10.5061/dryad.34kb373",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Rows exist only for camera-windows with >= 1 operating day (effort in obs_camera_days). Window start dates and the year are not deposited, so no date column. Coordinates as published (Least Concern taxon).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (spatio-temporal, one survey per 8-day season in the paper)",
  sampling_protocol = "camera_trap", design = "Single-season (46 calendar-aligned 8-day windows)", realm = "Terrestrial", country = "TZA",
  coordinates = "As published", notes = "878 detections in 5,669 camera-windows; 194 cameras; effort 1-8 days per window.",
  status = "tagged")
