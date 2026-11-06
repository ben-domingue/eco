#!/usr/bin/env Rscript
# Table:  hunter_2025_georgia_pinesavanna_occ
# Source: USGS ScienceBase doi:10.5066/P13965WX (USGS data release, published 2025-02-03;
#         "This work is marked with Creative Commons Zero v1.0 Universal")
#   Hunter, E.A., and Allred, C.R., 2025, Avian occupancy and habitat data in Georgia pine
#   savannas in 2022: U.S. Geological Survey data release.
# Data:   GABirds_DataRelease.csv: 161 survey points at seven Georgia WMAs / NWR (site, point,
#         coordinates), detection 0/1 of Bachman's Sparrow (bacs.y.1-3) and Northern Bobwhite
#         (nobo.y.1-3) on three visits at least two weeks apart (May-July 2022), visit date,
#         time (minutes after sunrise), temperature (F) and primary observer, Sentinel-2 indices
#         and texture metrics, burn frequency 2018-2022 and field vegetation measures. The two
#         coordinate columns are labelled the wrong way round (the "longitude" column holds
#         latitudes 30-34 N, asserted); they are swapped here. GABirds_DataRelease_RCW.csv:
#         one Red-cockaded Woodpecker detection value per point for the 2022 season at 192
#         points of three sites, with no visit structure.
#
# Mapping: unit = point (ids unique across sites), taxon = BACS / NOBO, one season (no period),
#   occasion = visit 1-3, y = 0/1; no missing cells, every point visited three times
#   (surveyEvidence deposited_matrix). obs_ date, minutes after sunrise, temperature, observer
#   (the observer column); unit_ site, coordinates, imagery and vegetation metrics, burn
#   frequency (all measured independently of the bird surveys). Coordinates kept as published
#   (neither species is IUCN CR/EN/VU). Not shipped: the RCW file (one season-level detection
#   per point, no replicate visits: a single-visit design, not eligible).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hunter_2025_georgia_pinesavanna_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/671298a6d34eb6a152fc7434?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
d <- fread(download_cached(fl[["GABirds_DataRelease.csv"]], TABLE, filename = "GABirds_DataRelease.csv"))
stopifnot(nrow(d) == 161, !anyDuplicated(d$point), !anyNA(d),
          all(d$longitude > 30 & d$longitude < 35), all(d$latitude < -80 & d$latitude > -86))   # labels swapped
setnames(d, c("longitude", "latitude"), c("lat_", "lon_"))
Y <- array(NA_integer_, dim = c(161, 3, 2), dimnames = list(as.character(d$point), NULL, c("BACS", "NOBO")))
Y[, , "BACS"] <- as.matrix(d[, .(bacs.y.1, bacs.y.2, bacs.y.3)]); Y[, , "NOBO"] <- as.matrix(d[, .(nobo.y.1, nobo.y.2, nobo.y.3)])
stopifnot(all(Y %in% 0:1), sum(Y) == 245)
dates <- as.matrix(d[, lapply(.SD, function(z) format(as.IDate(z, "%m/%d/%Y"))), .SDcols = c("date.1", "date.2", "date.3")])
stopifnot(!anyNA(dates), all(substr(dates, 1, 4) == "2022"), all(dates[, 1] < dates[, 2] & dates[, 2] < dates[, 3]))
long <- array_to_eco(Y, site_ids = as.character(d$point),
  site_covs = d[, .(site, decimalLatitude = lat_, decimalLongitude = lon_, cri2, evi, texture_corr = constant_corr,
                    texture_inertia = constant_inertia, texture_shade = constant_shade, texture_prom = constant_prom,
                    burn_freq, grass_cover_pct = grascov, woody_cover_pct = woocov, canopy_cover_pct = cancov,
                    woody_height = wood_height, forb_height)],
  obs_covs = list(.date = dates, min_after_sunrise = as.matrix(d[, .(time.1, time.2, time.3)]),
                  temp_f = as.matrix(d[, .(temp.1, temp.2, temp.3)]), .observer = as.matrix(d[, .(obs.1, obs.2, obs.3)])))
setnames(long, c("obs_.date", "obs_.observer"), c("date", "observer"))
stopifnot(nrow(long) == 161 * 3 * 2)
taxa <- make_taxa(c("BACS", "NOBO"), c("Peucaea aestivalis", "Colinus virginianus"), vernacularName = c("Bachman's Sparrow", "Northern Bobwhite"))
dataset <- list(
  title = "Bachman's Sparrow and Northern Bobwhite detections on three visits to 161 points in Georgia pine savannas, 2022",
  creator = "Hunter, Elizabeth A.; Allred, Cory R.", pubDate = "2025", doi = "10.5066/P13965WX", sourceURL = "https://doi.org/10.5066/P13965WX",
  citation = "Hunter, E.A., and Allred, C.R., 2025, Avian occupancy and habitat data in Georgia pine savannas in 2022: U.S. Geological Survey data release, https://doi.org/10.5066/P13965WX.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
  abstract = "Detections of Bachman's Sparrow and Northern Bobwhite at 161 locations in Georgia, USA, with detection covariates (date, time, temperature, observer) and habitat metrics from satellite imagery and on-the-ground vegetation measurements, collected to understand how habitat features and prescribed burning influence occupancy.",
  samplingProtocol = "Point counts at 161 survey points stratified by prescribed-burn frequency in six Wildlife Management Areas and Piedmont NWR, each visited three times at least two weeks apart, May-July 2022, recording detection of the target species.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one breeding season; the source fits single-season occupancy", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = list(description = "Pine savannas in six Wildlife Management Areas and Piedmont National Wildlife Refuge, Georgia, USA",
                            boundingBox = list(west = min(d$lon_), east = max(d$lon_), south = min(d$lat_), north = max(d$lat_))),
  temporalCoverage = "2022-05/2022-07",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS (columns swapped back); neither species is IUCN CR/EN/VU"),
  notes = "The release labels the coordinate columns the wrong way round; they are swapped here (latitudes 30-34 N, asserted).",
  notShipped = list(rcw_file = "GABirds_DataRelease_RCW.csv: one season-level Red-cockaded Woodpecker detection per point, no repeat visits (single-visit design)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/hunter_2025_georgia_pinesavanna_occ.R")
stage_dict_row(TABLE,
  description = "Detection / non-detection of Bachman's Sparrow and Northern Bobwhite on three point-count visits to 161 points in Georgia pine savannas, May-July 2022, with observer, time and temperature, burn frequency, satellite and field vegetation metrics and coordinates.",
  url = "https://doi.org/10.5066/P13965WX", reference = "Hunter, E.A., and Allred, C.R. (2025). Avian occupancy and habitat data in Georgia pine savannas in 2022. U.S. Geological Survey data release.",
  doi_data = "10.5066/P13965WX", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Coordinate columns swapped back (mislabelled in the release). RCW file not shipped (single visit).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Single-season occupancy", sampling_protocol = "point_count",
  design = "Single-season (3 visits)", realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Prescribed-fire gradient; two target species.")
