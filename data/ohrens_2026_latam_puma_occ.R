#!/usr/bin/env Rscript
# Table:  ohrens_2026_latam_puma_occ
# Source: Dryad, doi:10.5061/dryad.k6djh9wj8, version 472409 (version 9, published 2026-10-30), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON). Ohrens, O., Williams, S., Elbroch, L. M.,
#         and 222 more contributors (225 authors). Data from: Collaborative camera-trap detection data set for pumas across Latin
#         America. Fetched file by file with a short-lived Dryad token (the 703 MB version zip is refused, HTTP 405).
# Paper:  the data paper this deposit accompanies (not read); the design is from the Dryad methods and README:
#         contributors (over 200, recruited by literature review and snowball sampling, plus Panthera's PantheraIDS)
#         submitted station x survey-day detection matrices (1 detected, 0 not, NA camera inactive); the authors
#         validated coordinates and dates, dropped invalid locations and two datasets not shareable, and published one
#         row per camera station and date with sampling effort.
# Data:   puma_rangewide_effort_detection_data.csv (1,169,563 rows): row number, country (19), survey (1,221
#           contributor labels), station_id (13,148; one per unique XY, asserted), longitude, latitude (WGS84), date
#           (2001-08-24 to 2023-07-16), effort (1 on every row: only active camera-days are listed), detection (1/0;
#           12,312 detections). The same rows in .Rdata, .shp/.dbf/.shx/.prj and .geojson; R scripts 0a-2 (the
#           authors' cleaning and summaries). README.md.
# Mapping (single-species occupancy over years; responseType detection, unitKind site): unit = station_id, taxon =
#   PUMCON, period = calendar year (2001..2023 as 1..23; __periods), occasion = camera-day within the station-year in
#   date order, date = the day, y = detection. obs_survey = the contributor's survey label (a station can belong to
#   more than one survey across years, so it is a row covariate), unit_country, unit_decimalLatitude /
#   unit_decimalLongitude as deposited. surveyEvidence = effort_table: a row is a station-day with effort (the
#   deposit lists only active camera-days, effort = 1 on every row, asserted); days absent from the deposit were not
#   sampled. No station-day is duplicated (asserted).
#   Coordinates (E7): the puma is IUCN LC; coordinates kept as deposited.
# Not shipped: the duplicate spatial formats (.shp, .dbf, .geojson, .Rdata: the same rows), the effort column
#   (constant 1), the row-number column, the authors' scripts.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ohrens_2026_latam_puma_occ"
dir <- download_dryad("10.5061/dryad.k6djh9wj8", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "472409"))
d <- fread(file.path(dir, "puma_rangewide_effort_detection_data.csv"))
stopifnot(identical(names(d), c("V1", "country", "survey", "station_id", "longitude", "latitude", "date", "effort", "detection")),
          nrow(d) == 1169563L, all(d$effort == 1L), all(d$detection %in% 0:1), sum(d$detection) == 12312L,
          uniqueN(d$country) == 19L, uniqueN(d$survey) == 1221L, uniqueN(d$station_id) == 13148L,
          d[, uniqueN(paste(longitude, latitude)), by = station_id][, all(V1 == 1L)], uniqueN(d[, .(longitude, latitude)]) == 13148L,
          d[, uniqueN(country), by = station_id][, all(V1 == 1L)], !anyDuplicated(d[, .(station_id, date)]),
          !anyNA(d[, .(longitude, latitude, date)]), all(abs(d$latitude) <= 90), all(abs(d$longitude) <= 180),
          min(d$date) == as.IDate("2001-08-24"), max(d$date) == as.IDate("2023-07-16"))
years <- 2001:2023
d[, period := match(year(date), years)]
setorder(d, station_id, date)
d[, occasion := seq_len(.N), by = .(station_id, period)]
long <- d[, .(unit = as.character(station_id), taxon = "PUMCON", y = detection, period, occasion, date = format(date),
              unit_country = country, unit_decimalLatitude = latitude, unit_decimalLongitude = longitude, obs_survey = survey)]
long <- order_eco(long)
stopifnot(nrow(long) == 1169563L, sum(long$y) == 12312L)
cat(sprintf("  %d station-days at %d stations, %d station-years, %d detections\n", nrow(long), uniqueN(long$unit),
            uniqueN(long[, .(unit, period)]), sum(long$y)))

taxa <- make_taxa("PUMCON", "Puma concolor", vernacularName = "Puma")
stopifnot(identical(unname(iucn_category(taxa$taxonID, taxa$scientificName)), "LC"))
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]

dataset <- list(
  title = "Daily camera-trap detections of pumas at 13,148 stations in 19 countries, Mexico and the USA to Patagonia, 2001-2023",
  creator = "Ohrens, Omar; Williams, Sara; Elbroch, L. Mark; Robertson, Jamie; Robinson, Hugh; and 220 further contributors (see the Dryad record)", pubDate = "2026",
  doi = "10.5061/dryad.k6djh9wj8", sourceURL = "https://doi.org/10.5061/dryad.k6djh9wj8",
  citation = "Ohrens, O., et al. (2026). Data from: Collaborative camera-trap detection data set for pumas across Latin America [Dataset]. Dryad. https://doi.org/10.5061/dryad.k6djh9wj8",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Puma (Puma concolor) detections from camera-trap surveys compiled from over 200 contributors and Panthera's PantheraIDS, 1,169,563 camera-trap days at 13,148 stations in 19 countries from Sonora, Mexico (and Big Bend, Texas) to southern Patagonia, 2001-2023. One row per camera station and active day, with a 0/1 puma detection.",
  samplingProtocol = "Camera traps deployed by many independent surveys with their own designs; each contributor coded each station x survey day as detected, not detected or inactive; the authors kept active days only. A day with any puma image is a detection.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "occasions are the active days of a station within a calendar year, which can span many months and more than one deployment; period = calendar year. The deposit does not give deployment boundaries.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Latin America and the southwestern USA: 19 countries from Sonora, Mexico and Big Bend, Texas to southern Patagonia, Chile",
  temporalCoverage = "2001-08/2023-07",
  coordinatesCoarsened = list(value = FALSE, method = "Puma concolor is IUCN LC; station coordinates kept as deposited"),
  covariateNote = "obs_survey: the contributor's survey or project label (a station appears under up to 7 labels across years). unit_country: the station's country.",
  notShipped = list(duplicate_formats = "the .Rdata, shapefile and GeoJSON copies of the same rows",
                    effort = "the effort column (1 on every row)", scripts = "the authors' R cleaning and summary scripts"),
  notes = "A compilation of many surveys with different camera designs and seasons; obs_survey identifies the contributing survey. Station-days absent from the deposit had no camera effort.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ohrens_2026_latam_puma_occ.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detections of pumas at 13,148 stations in 19 countries of Latin America and the southwestern USA, 2001-2023, compiled from over 200 contributors (1.17 million camera-days).",
  url = "https://doi.org/10.5061/dryad.k6djh9wj8",
  reference = "Ohrens, O., et al. (2026). Collaborative camera-trap detection data set for pumas across Latin America. Dryad. https://doi.org/10.5061/dryad.k6djh9wj8",
  doi_paper = "", doi_data = "10.5061/dryad.k6djh9wj8",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Station x active day; period = calendar year. Fetched file by file with a short-lived Dryad token (version zip refused, 405).",
  source_via = "Dryad (per-file, token)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy",
  sampling_protocol = "camera_trap", design = "Multi-season (23 calendar years; daily occasions; 13,148 stations)",
  realm = "Terrestrial", country = "ARG,BLZ,BOL,BRA,CHL,COL,CRI,ECU,GTM,GUY,HND,MEX,PAN,PRY,PER,SUR,URY,USA,VEN", coordinates = "As published",
  notes = "Range-wide compilation of camera-trap surveys for one large carnivore.")
