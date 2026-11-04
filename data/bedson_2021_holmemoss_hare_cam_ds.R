#!/usr/bin/env Rscript
# Table:  bedson_2021_holmemoss_hare_cam_ds
# Source: Dryad doi:10.5061/dryad.3r2280gg0 (CC0 1.0), version 150420 (2021-11-19)
#   Bedson, C. P. E. (2021). Estimating density of mountain hares using distance sampling:
#   a comparison of daylight visual surveys, night-time thermal imaging and camera traps
#   [Data set]. Dryad.
# Paper:  Bedson, C. P. E., Thomas, L., Wheeler, P. M., Reid, N., Harris, W. E., Lloyd, H.,
#         Mallon, D. & Preziosi, R. (2021). Wildlife Biology 2021(3), wlb.00802.
#         doi:10.2981/wlb.00802 (CC BY; read from the QUB repository copy).
# Data:   Camera_trap_data.txt, "prepared ready for loading in to Software Distance" as point
#         transects: 3,796 rows = 3,706 night-time hare detections (SITE 1-6, AREA_KM_2 8.17,
#         CAM_ID, SURVEY_EFFORT_SECONDS = total seconds the camera was deployed, written
#         with a thousands comma, RADIAL_DISTANCE_M = distance to the hare in whole metres
#         1-12 read against marker canes at 2, 4, 6, 8, 10 m, CLUSTER_SIZE 1-2) plus one
#         empty-distance row per camera for 90 of the 91 cameras (camera 53249, 46
#         detections, has none; 12-16 cameras per site, deployed sequentially
#         site 1 to site 6 for 2-5 weeks each, Nov 2017 - Mar 2018). Cameras triggered at
#         1 s intervals; the paper's snapshot interval k = 1 s and field of view 42 degrees
#         (effort k x 42/360 in the Distance analysis). The paper excludes 78 daytime
#         detections and 1,329 "attraction" images before deposit; the file has 3,706 detections
#         against the paper's 3,705 (site 5: 474 vs 479; the other five sites match) and 76
#         cameras with a detection against the paper's 77; recorded, not resolved.
#
# Mapping (standard E1-E5, E9 declared stretch: camera-trap distance sampling):
#   unit = camera (91; id C<CAM_ID>), cluster_id = site, taxon = LEPTIM, occasion = radial
#   distance bin 1..12 with y_raw the label, y = hare groups (snapshot detections) in the
#   bin, obs_individuals = hares in the bin; unit_effort_seconds (deployed seconds, the
#   effort unit), unit_site_area_km2. Distances are deposited as whole metres d, taken as
#   the bin (d-1, d] m: distanceBreaks = 0..12 m; the paper truncated at 5 m and used bins
#   at 1, 2, 3-4, 5 m (n = 3,506 = detections at <= 5 m, asserted); nothing is dropped here,
#   a user keeps occasions 1-5 and merges 3 and 4 to reproduce it. snapshotInterval = 1 s,
#   fieldOfViewDegrees = 42.
#   Survey evidence = deposited_matrix: the file lists every camera with its effort (90 with
#   an empty row, one through its detections only), so the 91 cameras are the survey set
#   (15 made no detection; the paper says 14).
#   No deployment dates per camera and no coordinates (cameras 333 m apart along the OS 1 km
#   grid lines of each site; Fig. 1 of the paper only). Lepus timidus is IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bedson_2021_holmemoss_hare_cam_ds"
dir <- download_dryad("10.5061/dryad.3r2280gg0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "Camera_trap_data.txt", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
c <- fread(f, fill = TRUE)
c <- c[, .(site = SITE, area_km2 = AREA_KM_2, cam = CAM_ID, eff = as.numeric(gsub("[^0-9]", "", SURVEY_EFFORT_SECONDS)),
           dist = RADIAL_DISTANCE_M, size = CLUSTER_SIZE)]
stopifnot(nrow(c) == 3796, all(c$site %in% 1:6), all(c$area_km2 == 8.17), !anyNA(c$cam), !anyNA(c$eff), all(c$eff > 0),
          identical(is.na(c$dist), is.na(c$size)), all(c$dist[!is.na(c$dist)] %in% 1:12), all(c$size[!is.na(c$size)] %in% 1:2))
cams <- unique(c[, .(site, cam, area_km2, eff)])[order(site, cam)]
stopifnot(nrow(cams) == 91, !anyDuplicated(cams$cam), c[, uniqueN(eff), by = cam][, all(V1 == 1)],
          identical(cams[, .N, by = site][order(site), N], c(16L, 16L, 12L, 16L, 16L, 15L)),            # Table 1 cameras per site
          sum(is.na(c$dist)) == 90, c[, sum(is.na(dist)), by = cam][V1 != 1, identical(cam, 53249L)],   # one empty row per camera but 53249
          sum(!is.na(c$dist)) == 3706,                                                                  # paper Table 1: 3,705
          identical(c[!is.na(dist), .N, by = site][order(site), N], c(768L, 550L, 213L, 1128L, 474L, 573L)),   # paper: 768,550,213,1128,479,573
          sum(c$dist <= 5, na.rm = TRUE) == 3506,                                                       # Table 2 n obs after 5 m truncation
          c[!is.na(dist), uniqueN(cam)] == 76, sum(c$size == 2, na.rm = TRUE) == 89)                   # paper: 77 cameras with a detection, 14 without
BREAKS <- 0:12
BINS <- paste0(head(BREAKS, -1), "-", tail(BREAKS, -1), " m")
cell <- CJ(cam = cams$cam, bin = seq_along(BINS))
agg <- c[!is.na(dist), .(groups = .N, individuals = sum(size)), by = .(cam, bin = dist)]
cell <- merge(cell, agg, by = c("cam", "bin"), all.x = TRUE)[order(match(cam, cams$cam), bin)]
cell[is.na(groups), `:=`(groups = 0L, individuals = 0L)]
M <- nrow(cams); J <- length(BINS)
y <- matrix(as.integer(cell$groups), M, J, byrow = TRUE, dimnames = list(paste0("C", cams$cam), BINS))
ind <- matrix(as.integer(cell$individuals), M, J, byrow = TRUE)
stopifnot(sum(y) == 3706, sum(ind) == 3706 + 89, sum(rowSums(y) == 0) == 15)
long <- array_to_eco(y, taxon = "LEPTIM", site_ids = rownames(y),
                     site_covs = data.frame(effort_seconds = as.integer(cams$eff), site_area_km2 = cams$area_km2),
                     obs_covs = list(individuals = ind),
                     y_raw = matrix(BINS, M, J, byrow = TRUE))
long[, cluster_id := paste0("S", cams$site[match(unit, paste0("C", cams$cam))])]
long <- order_eco(long)
stopifnot(nrow(long) == M * J, sum(long$y) == 3706, uniqueN(long$unit) == 91, uniqueN(long$cluster_id) == 6)

taxa <- make_taxa("LEPTIM", "Lepus timidus", vernacularName = "Mountain hare")
dataset <- list(
  title = "Mountain hare camera-trap distance sampling, 91 cameras at six 1 km sites on Holme Moss, Peak District, winter 2017-18: night-time snapshot detections in twelve 1 m radial-distance bins per camera",
  creator = "Bedson, Carlos P. E.", pubDate = "2021", doi = "10.5061/dryad.3r2280gg0", sourceURL = "https://doi.org/10.5061/dryad.3r2280gg0",
  citation = "Bedson, C. P. E. (2021). Estimating density of mountain hares using distance sampling: a comparison of daylight visual surveys, night-time thermal imaging and camera traps [Data set]. Dryad. https://doi.org/10.5061/dryad.3r2280gg0",
  paperDOI = "10.2981/wlb.00802",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap distance sampling (Howe et al. 2017) for mountain hares (Lepus timidus) at Holme Moss, Peak District, England: 91 Bushnell cameras 333 m apart at six 1 km sites, deployed site by site for two to five weeks each between November 2017 and March 2018 (1,800 camera-nights), triggering at 1 s intervals, with marker canes at 2, 4, 6, 8 and 10 m to read the radial distance of each hare to the metre. 3,706 night-time (sunset to sunrise) detections in the file (the paper reports 3,705) after the authors removed daytime and attraction images; cluster size 1-2. Sibling tables hold the daylight line-transect and thermal point-transect surveys of the same sites.",
  samplingProtocol = "Camera-trap distance sampling: fixed cameras triggering at 1 s intervals, 42-degree field of view, radial distance of each hare read against marker canes; snapshot interval 1 s; effort = seconds deployed.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "multinomial_cell", distanceBreaks = BREAKS, distanceUnits = "m", transectType = "point",
  snapshotInterval = "1 s", fieldOfViewDegrees = 42,
  effortColumn = "unit_effort_seconds", unitKind = "site", closure = "closed", closureNote = "occasion (bins of one camera deployment)", occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Holme Moss, Peak District National Park, England (OS SE 40 39 area; six 1 km sites; no coordinates deposited)",
  temporalCoverage = "2017-11/2018-03",
  notes = "Distances are deposited as whole metres d (1-12) and taken as the bin (d-1, d]; the paper truncated at 5 m and used bins at 1, 2, 3-4 and 5 m (n = 3,506, asserted), nothing is dropped here. Effort is the deposited total seconds per camera (the paper multiplies by 42/360 for the field of view; not applied). The file has 3,706 detections and 76 cameras with a detection against the paper's 3,705 and 77 (site 5: 474 vs 479; the other sites match). obs_individuals is hares in the bin (cluster sizes 1-2); y counts snapshot detections. Deployment dates per camera and camera-night counts are only in the paper's supporting information.",
  notShipped = list(none = "every row of Camera_trap_data.txt is represented; the visual and thermal files are the sibling tables"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bedson_2021_holmemoss_hare_cam_ds.R")
stage_dict_row(TABLE,
  description = "Camera-trap distance sampling of mountain hares (Lepus timidus) at Holme Moss, Peak District, winter 2017-18: 91 cameras at six 1 km sites, night-time 1 s snapshot detections in twelve 1 m radial-distance bins per camera, with seconds deployed as effort and hares per bin. 3,706 detections. First camera-trap distance-sampling table; one of three sibling tables comparing survey methods.",
  url = "https://doi.org/10.5061/dryad.3r2280gg0",
  reference = "Bedson, C. P. E., Thomas, L., Wheeler, P. M., Reid, N., Harris, W. E., Lloyd, H., Mallon, D., & Preziosi, R. (2021). Estimating density of mountain hares using distance sampling: a comparison of daylight visual surveys, night-time thermal imaging and camera traps. Wildlife Biology, 2021(3), wlb.00802.",
  doi_paper = "10.2981/wlb.00802", doi_data = "10.5061/dryad.3r2280gg0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): camera-trap distance sampling, occasion = 1 m radial bin, snapshotInterval 1 s, effort in seconds. Sibling tables: _vis_ds, _therm_ds.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Distance sampling (camera trap, 1 s snapshots, 1 m bins)",
  sampling_protocol = "camera_trap", design = "Single-season (91 cameras, 6 sites deployed sequentially, 2-5 weeks each)", realm = "Terrestrial",
  country = "GBR", coordinates = "None in source",
  notes = "Declared stretch: CTDS, occasion = distance bin. First camera-trap distance-sampling table. Method-comparison deposit; see the visual and thermal sibling tables.")
