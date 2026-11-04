#!/usr/bin/env Rscript
# Table:  bedson_2021_holmemoss_hare_therm_ds
# Source: Dryad doi:10.5061/dryad.3r2280gg0 (CC0 1.0), version 150420 (2021-11-19)
#   Bedson, C. P. E. (2021). Estimating density of mountain hares using distance sampling:
#   a comparison of daylight visual surveys, night-time thermal imaging and camera traps
#   [Data set]. Dryad.
# Paper:  Bedson, C. P. E., Thomas, L., Wheeler, P. M., Reid, N., Harris, W. E., Lloyd, H.,
#         Mallon, D. & Preziosi, R. (2021). Wildlife Biology 2021(3), wlb.00802.
#         doi:10.2981/wlb.00802 (CC BY; read from the QUB repository copy).
# Data:   Thermal_imager_data.txt, "prepared ready for loading in to Software Distance":
#         245 rows = 206 hare detections (one row each: SITE 1-6, AREA_KM_2 8.17,
#         OBSERVATION_POINT = vantage-point id, SURVEY_EFFORT = 1, RADIAL_DISTANCE_M 30-740,
#         CLUSTER_SIZE 1-8) plus 39 rows with an empty distance = a point visit without a
#         detection. Points were visited 1-3 times over eleven nights (Nov 2017 - May 2018)
#         and "appear several times" (usage notes) without a visit label. Rows are in survey
#         order, so a visit is a maximal run of consecutive rows with the same point: that
#         gives 114 visits, 20/22/27/22/12/11 per site, exactly the paper's Table 1
#         replicates (asserted), and 71 points (12 per site, 11 at site 6). 35 visits have
#         no detection; four further empty rows sit inside a run (CVT5 twice in a row, and
#         one after the detections of CVT6, CVT7 and CLO11) and carry nothing, since a
#         separate visit there would break the paper's replicate counts.
#
# Mapping (standard E1-E5, E9 declared stretch: binned point-transect distance sampling):
#   unit = point visit (114; id <point>_v<k>), cluster_id = site, taxon = LEPTIM, occasion =
#   radial-distance bin 1..8 with y_raw the label, y = hare groups in the bin,
#   obs_individuals = hares in the bin; unit_point (vantage point id), unit_visit (k),
#   unit_site_area_km2, unit_survey_effort (1 per visit, the deposit's effort unit).
#   distanceBreaks = 0,50,100,...,350,750 m: the paper fitted exact distances truncated at
#   350 m (n = 152); binning is the processor's (seven 50 m bins to the truncation plus one
#   350-750 m bin holding the 54 detections beyond it, so nothing is dropped).
#   Survey evidence = deposited_matrix: visits without detections are deposited as empty
#   rows, so the 114 visits are the survey set (35 with no detection).
#   No dates, no coordinates (points were 333 m apart along the OS 1 km grid lines of each
#   site; the paper's Fig. 1 only). Lepus timidus is IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bedson_2021_holmemoss_hare_therm_ds"
dir <- download_dryad("10.5061/dryad.3r2280gg0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "Thermal_imager_data.txt", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
t <- fread(f, fill = TRUE)
t <- t[, .(site = SITE, area_km2 = AREA_KM_2, point = trimws(OBSERVATION_POINT), effort = SURVEY_EFFORT,
           dist = RADIAL_DISTANCE_M, size = CLUSTER_SIZE)]
stopifnot(nrow(t) == 245, all(t$site %in% 1:6), all(t$area_km2 == 8.17), all(t$effort == 1), all(nzchar(t$point)),
          identical(is.na(t$dist), is.na(t$size)), sum(!is.na(t$dist)) == 206, min(t$dist, na.rm = TRUE) == 30,
          max(t$dist, na.rm = TRUE) == 740, all(t$size[!is.na(t$size)] %in% c(1:5, 8)), sum(t$size, na.rm = TRUE) == 285,
          sum(t$dist <= 350, na.rm = TRUE) == 152,                                       # Table 2 n obs
          identical(t[!is.na(dist), .N, by = site][order(site), N], c(26L, 38L, 30L, 87L, 12L, 13L)))   # Table 1
# visits: maximal runs of the same point, in file order
t[, visit_run := rleid(site, point)]
t[, visit := match(visit_run, unique(visit_run)), by = .(site, point)]
visits <- t[, .(site = site[1], point = point[1], visit = visit[1], area_km2 = area_km2[1], n_det = sum(!is.na(dist))), by = visit_run]
stopifnot(nrow(visits) == 114, identical(visits[, .N, by = site][order(site), N], c(20L, 22L, 27L, 22L, 12L, 11L)),   # Table 1 replicates
          uniqueN(visits$point) == 71, identical(visits[, uniqueN(point), by = site][order(site), V1], c(12L, 12L, 12L, 12L, 12L, 11L)),
          sum(visits$n_det == 0) == 35, sum(is.na(t$dist)) == 39, !anyDuplicated(visits[, .(point, visit)]))
BREAKS <- c(0, 50, 100, 150, 200, 250, 300, 350, 750)
BINS <- paste0(head(BREAKS, -1), "-", tail(BREAKS, -1), " m")
t[, bin := cut(dist, BREAKS, labels = BINS, include.lowest = TRUE, right = TRUE)]
stopifnot(all(!is.na(t$bin) | is.na(t$dist)))
visits[, unit := sprintf("%s_v%d", point, visit)]
cell <- CJ(visit_run = visits$visit_run, bin = factor(BINS, levels = BINS))
agg <- t[!is.na(dist), .(groups = .N, individuals = sum(size)), by = .(visit_run, bin)]
cell <- merge(cell, agg, by = c("visit_run", "bin"), all.x = TRUE)[order(visit_run, bin)]
cell[is.na(groups), `:=`(groups = 0L, individuals = 0L)]
M <- nrow(visits); J <- length(BINS)
y <- matrix(as.integer(cell$groups), M, J, byrow = TRUE, dimnames = list(visits$unit, BINS))
ind <- matrix(as.integer(cell$individuals), M, J, byrow = TRUE)
stopifnot(sum(y) == 206, sum(ind) == 285, sum(rowSums(y) == 0) == 35)
long <- array_to_eco(y, taxon = "LEPTIM", site_ids = visits$unit,
                     site_covs = data.frame(point = visits$point, visit = visits$visit, site_area_km2 = visits$area_km2, survey_effort = 1L),
                     obs_covs = list(individuals = ind),
                     y_raw = matrix(BINS, M, J, byrow = TRUE))
long[, cluster_id := paste0("S", visits$site[match(unit, visits$unit)])]
long <- order_eco(long)
stopifnot(nrow(long) == M * J, sum(long$y) == 206, uniqueN(long$unit) == 114, uniqueN(long$cluster_id) == 6)

taxa <- make_taxa("LEPTIM", "Lepus timidus", vernacularName = "Mountain hare")
dataset <- list(
  title = "Mountain hare night-time thermal-imaging point-transect distance sampling, 114 vantage-point visits at six 1 km sites on Holme Moss, Peak District, winter 2017-18: hare groups in eight radial-distance bins",
  creator = "Bedson, Carlos P. E.", pubDate = "2021", doi = "10.5061/dryad.3r2280gg0", sourceURL = "https://doi.org/10.5061/dryad.3r2280gg0",
  citation = "Bedson, C. P. E. (2021). Estimating density of mountain hares using distance sampling: a comparison of daylight visual surveys, night-time thermal imaging and camera traps [Data set]. Dryad. https://doi.org/10.5061/dryad.3r2280gg0",
  paperDOI = "10.2981/wlb.00802",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Night-time point-transect surveys for mountain hares (Lepus timidus) with a tripod-mounted thermal imager and laser range finder at Holme Moss, Peak District, England, November 2017 to May 2018: 71 vantage points 333 m apart along the 1 km grid lines of six survey sites, each visited one to three times (114 visits over eleven nights) with a 360-degree scan of 10-20 minutes, radial distance and group size recorded per detection. 206 detections (285 hares). Sibling tables hold the daylight line-transect and camera-trap surveys of the same sites.",
  samplingProtocol = "Point-transect distance sampling by night with a thermal imager (360-degree scans, 10-20 min per point, one hour after sunset); radial distance by laser range finder, cluster size recorded; points visited 1-3 times.",
  samplingProtocolCode = "point_transect", surveyEvidence = "deposited_matrix",
  responseType = "multinomial_cell", distanceBreaks = BREAKS, distanceUnits = "m", transectType = "point",
  effortColumn = "unit_survey_effort", unitKind = "site", closure = "closed", closureNote = "occasion (bins of one point visit)", occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Holme Moss, Peak District National Park, England (OS SE 40 39 area; six 1 km sites; no coordinates deposited)",
  temporalCoverage = "2017-11/2018-05",
  notes = "The deposit has no visit label; a visit is a maximal run of consecutive rows with the same vantage point in file order, which reproduces the paper's 114 replicates per site exactly (20, 22, 27, 22, 12, 11). Radial distances are deposited to the metre and binned here (50 m bins to the paper's 350 m truncation, plus one 350-750 m bin holding the 54 detections beyond it); the paper fitted exact distances. obs_individuals is hares in the bin (cluster sizes 1-8); y counts groups. Three leveret sightings were excluded by the authors before deposit. No dates or coordinates deposited.",
  notShipped = list(none = "every row of Thermal_imager_data.txt is represented; the visual and camera files are the sibling tables"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bedson_2021_holmemoss_hare_therm_ds.R")
stage_dict_row(TABLE,
  description = "Night-time thermal-imaging point-transect distance sampling of mountain hares (Lepus timidus) at Holme Moss, Peak District, winter 2017-18: 114 visits to 71 vantage points at six 1 km sites, hare groups in eight radial-distance bins (50 m to 350 m, then 350-750 m) per visit, with hares per bin. 206 detections. One of three sibling tables comparing survey methods.",
  url = "https://doi.org/10.5061/dryad.3r2280gg0",
  reference = "Bedson, C. P. E., Thomas, L., Wheeler, P. M., Reid, N., Harris, W. E., Lloyd, H., Mallon, D., & Preziosi, R. (2021). Estimating density of mountain hares using distance sampling: a comparison of daylight visual surveys, night-time thermal imaging and camera traps. Wildlife Biology, 2021(3), wlb.00802.",
  doi_paper = "10.2981/wlb.00802", doi_data = "10.5061/dryad.3r2280gg0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): occasion = radial-distance bin (point transect). Visits recovered from row order (matches the paper's replicate counts). Processor-binned distances. Sibling tables: _vis_ds, _cam_ds.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Distance sampling (point transect, thermal imager, 8 bins)",
  sampling_protocol = "point_transect", design = "Single-season (71 points x 1-3 visits = 114 visits, 6 sites)", realm = "Terrestrial",
  country = "GBR", coordinates = "None in source",
  notes = "Declared stretch: occasion = distance bin. Visits inferred from row order and asserted against the paper. Method-comparison deposit; see the visual and camera sibling tables.")
