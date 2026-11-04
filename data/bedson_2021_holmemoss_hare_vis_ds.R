#!/usr/bin/env Rscript
# Table:  bedson_2021_holmemoss_hare_vis_ds
# Source: Dryad doi:10.5061/dryad.3r2280gg0 (CC0 1.0), version 150420 (2021-11-19)
#   Bedson, C. P. E. (2021). Estimating density of mountain hares using distance sampling:
#   a comparison of daylight visual surveys, night-time thermal imaging and camera traps
#   [Data set]. Dryad.
# Paper:  Bedson, C. P. E., Thomas, L., Wheeler, P. M., Reid, N., Harris, W. E., Lloyd, H.,
#         Mallon, D. & Preziosi, R. (2021). Wildlife Biology 2021(3), wlb.00802.
#         doi:10.2981/wlb.00802 (CC BY; read from the QUB repository copy).
# Data:   three tab-separated files "prepared ready for loading in to Software Distance",
#         one per method. This table is Daylight_visual_samping_data.txt: one row per
#         mountain hare detection (41) on the daylight line-transect walks: STUDY_AREA,
#         SITE 1-6 (1 km squares, site 6 a strip), AREA_KM_^2 (8.17 per site), LINE_LENGTH_KM
#         (one square-circuit walk per site, 4.6-8.2 km; the paper: "only one visit per site
#         transect", 5 days, Nov 2017 - May 2018), PERP_DISTANCE_M (0-370 m, from laser
#         range finder + compass), CLUSTER_SIZE (1-2). Every site has at least one detection,
#         so the six walks are all present; a walk is one row per hare, no zero rows needed.
#         Sibling tables: bedson_2021_holmemoss_hare_therm_ds (thermal point transects) and
#         bedson_2021_holmemoss_hare_cam_ds (camera-trap distance sampling).
#
# Mapping (standard E1-E5, E9 declared stretch: binned line-transect distance sampling):
#   unit = site walk S1..S6 (one walk each), taxon = LEPTIM, occasion = perpendicular
#   distance bin 1..5 with y_raw the label, y = number of hare groups (clusters) in the bin,
#   obs_individuals = hares in the bin (sum of cluster sizes); unit_line_length_km (effort),
#   unit_site_area_km2. distanceBreaks = 0,5,10,20,100,400 m: the paper's bins (5, 10, 20,
#   100 m, truncation 100 m) plus one wide bin to the furthest detection (370 m) so that the
#   15 detections beyond the paper's truncation are shipped rather than dropped; a user
#   reproduces the paper by dropping occasion 5. Binning continuous distances is a
#   processing decision recorded here and in notes.
#   Survey evidence = deposited_matrix: the six walks are the six sites, each present.
#   No dates per walk and no coordinates in the deposit (site centroids are in the paper's
#   Fig. 1 only); Lepus timidus is IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bedson_2021_holmemoss_hare_vis_ds"
dir <- download_dryad("10.5061/dryad.3r2280gg0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "Daylight_visual_samping_data.txt", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
v <- fread(f)
v <- v[, .(site = SITE, area_km2 = `AREA_KM_^2`, len_km = LINE_LENGTH_KM, dist = PERP_DISTANCE_M, size = CLUSTER_SIZE)]
stopifnot(nrow(v) == 41, all(v$site %in% 1:6), all(v$area_km2 == 8.17), v[, uniqueN(len_km), by = site][, all(V1 == 1)],
          all(v$dist >= 0), max(v$dist) == 370, all(v$size %in% 1:2), sum(v$size == 2) == 2,
          identical(v[, .N, by = site][order(site), N], c(8L, 11L, 1L, 12L, 5L, 4L)),   # Table 1
          sum(v$dist <= 100) == 26)                                                     # Table 2 n obs after truncation
BREAKS <- c(0, 5, 10, 20, 100, 400)
BINS <- c("0-5 m", "5-10 m", "10-20 m", "20-100 m", "100-400 m")
v[, bin := cut(dist, BREAKS, labels = BINS, include.lowest = TRUE, right = TRUE)]
stopifnot(!anyNA(v$bin))
sites <- unique(v[, .(site, area_km2, len_km)])[order(site)]
stopifnot(nrow(sites) == 6, abs(sum(sites$len_km) - 31.91) < 0.05)   # paper: total 31.91 km (file rounds to 0.1)
cell <- CJ(site = sites$site, bin = factor(BINS, levels = BINS))
agg <- v[, .(groups = .N, individuals = sum(size)), by = .(site, bin)]
cell <- merge(cell, agg, by = c("site", "bin"), all.x = TRUE)[order(site, bin)]
cell[is.na(groups), `:=`(groups = 0L, individuals = 0L)]
y <- matrix(as.integer(cell$groups), nrow = 6, ncol = 5, byrow = TRUE, dimnames = list(paste0("S", sites$site), BINS))
ind <- matrix(as.integer(cell$individuals), nrow = 6, ncol = 5, byrow = TRUE)
stopifnot(sum(y) == 41, sum(ind) == 43)
long <- array_to_eco(y, taxon = "LEPTIM", site_ids = rownames(y),
                     site_covs = data.frame(line_length_km = sites$len_km, site_area_km2 = sites$area_km2),
                     obs_covs = list(individuals = ind),
                     y_raw = matrix(BINS, 6, 5, byrow = TRUE))
long <- order_eco(long)
stopifnot(nrow(long) == 30, sum(long$y) == 41, uniqueN(long$unit) == 6)

taxa <- make_taxa("LEPTIM", "Lepus timidus", vernacularName = "Mountain hare")
dataset <- list(
  title = "Mountain hare daylight line-transect distance sampling, six 1 km sites at Holme Moss, Peak District, winter 2017-18: hare groups in five perpendicular-distance bins per site walk",
  creator = "Bedson, Carlos P. E.", pubDate = "2021", doi = "10.5061/dryad.3r2280gg0", sourceURL = "https://doi.org/10.5061/dryad.3r2280gg0",
  citation = "Bedson, C. P. E. (2021). Estimating density of mountain hares using distance sampling: a comparison of daylight visual surveys, night-time thermal imaging and camera traps [Data set]. Dryad. https://doi.org/10.5061/dryad.3r2280gg0",
  paperDOI = "10.2981/wlb.00802",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daylight visual line-transect surveys for mountain hares (Lepus timidus) at Holme Moss, a blanket-bog plateau in the Peak District, England, November 2017 to May 2018: one square-circuit walk (4.6-8.2 km) around each of six 1 km survey sites, the perpendicular distance of each hare group measured by laser range finder and compass. 41 detections (43 hares). The authors compared this method with night-time thermal imaging and camera-trap distance sampling at the same sites (sibling tables).",
  samplingProtocol = "Line-transect distance sampling on foot in daylight, ~1 km per hour with binoculars; radial distance and angle recorded per hare, converted to perpendicular distance; one walk per site.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  responseType = "multinomial_cell", distanceBreaks = BREAKS, distanceUnits = "m", transectType = "line",
  effortColumn = "unit_line_length_km", unitKind = "site", closure = "closed", closureNote = "occasion (bins of one walk)", occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Holme Moss, Peak District National Park, England (OS SE 40 39 area; six 1 km sites; no coordinates deposited)",
  temporalCoverage = "2017-11/2018-05",
  notes = "Perpendicular distances are deposited to the metre and binned here: the paper's bins (5, 10, 20, 100 m; truncation 100 m, n = 26) plus one 100-400 m bin holding the 15 detections beyond the paper's truncation, so no detection is dropped; drop occasion 5 to reproduce the paper. obs_individuals is the number of hares in the bin (cluster sizes 1-2); y counts groups. Dates of the five survey days are not deposited. Six units: below the sample floor by design.",
  notShipped = list(none = "every row of Daylight_visual_samping_data.txt is represented; the thermal and camera files are the sibling tables"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bedson_2021_holmemoss_hare_vis_ds.R")
stage_dict_row(TABLE,
  description = "Daylight line-transect distance sampling of mountain hares (Lepus timidus) at six 1 km sites on Holme Moss, Peak District, winter 2017-18: hare groups in five perpendicular-distance bins (0-5, 5-10, 10-20, 20-100, 100-400 m) per site walk, with walk length and hares per bin. 41 detections. One of three sibling tables comparing survey methods.",
  url = "https://doi.org/10.5061/dryad.3r2280gg0",
  reference = "Bedson, C. P. E., Thomas, L., Wheeler, P. M., Reid, N., Harris, W. E., Lloyd, H., Mallon, D., & Preziosi, R. (2021). Estimating density of mountain hares using distance sampling: a comparison of daylight visual surveys, night-time thermal imaging and camera traps. Wildlife Biology, 2021(3), wlb.00802.",
  doi_paper = "10.2981/wlb.00802", doi_data = "10.5061/dryad.3r2280gg0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): occasion = distance bin. Continuous distances binned by the processor to the paper's breaks plus a 100-400 m bin. Six walks only. Sibling tables: _therm_ds, _cam_ds.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Distance sampling (line transect, 5 bins)",
  sampling_protocol = "line_transect", design = "Single-season (one walk per site, 6 sites)", realm = "Terrestrial",
  country = "GBR", coordinates = "None in source",
  notes = "Declared stretch: occasion = distance bin. Below floor (6 units). Method-comparison deposit; see the thermal and camera sibling tables.")
