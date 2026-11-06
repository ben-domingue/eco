#!/usr/bin/env Rscript
# Table:  valente_2018_indiana_birds_comm
# Source: Dryad doi:10.5061/dryad.5d8s7 (CC0 1.0 as shown on the dataset JSON), version 21606
#   (published 2018-06-12). Valente, J. J., Hutchinson, R. A. & Betts, M. G. Data from:
#   Distinguishing distribution dynamics from temporary emigration using dynamic occupancy models.
# Paper:  Valente, J. J., Hutchinson, R. A. & Betts, M. G. (2017). Methods in Ecology and Evolution
#   8(12), 1707-1716, doi:10.1111/2041-210x.12840. Tests whether repeat visits within a breeding
#   season are closed or open to temporary emigration, with 19 forest bird species at 193 point
#   count stations in Indiana as one of three empirical case studies.
# Data:   Case Study Data.csv: 11,001 rows = 193 stations x 3 visits x 19 species (asserted), one per
#           species x visit: species / scientific / sppcode (4-letter banding code), property (6
#           public properties), plot (12 forest plots), point (station id), utm.x / utm.y (UTM zone
#           16, per README), date (ISO), julian, year (all 2014), observer (1-4), time (minutes after
#           midnight), temp (F), wind (Beaufort 0-3), cloud (%), visit (1-3), det.interval1-3
#           (detected inside the 50 m circle in each 3 min 20 s interval of the 10-min count),
#           det.visit (detected in any interval; asserted equal to the maximum of the three).
#         README_for_Case Study Data.docx: the variables above; detections only inside 50 m.
# Mapping (community occupancy, single season): unit = point, taxon = sppcode, occasion = visit,
#   y = det.visit, cluster_id = plot, date, observer. The three within-count intervals ship as
#   obs_det_interval1..3 (0/1), so a time-to-detection or interval-removal model can be fitted
#   from the same rows. obs_time_min, obs_temp_f, obs_wind_beaufort, obs_cloud_pct are constant
#   within point x visit across species (asserted). unit_property, unit_x / unit_y (UTM 16N).
#   Survey evidence = deposited_matrix: every station x visit x species row is deposited with an
#   explicit 0 or 1, and every station has all three visits (asserted).
#   Coordinates kept as published: none of the 19 species is IUCN CR / EN / VU, and the source
#   flags none.
# Not shipped: julian (day of year of the shipped date). The other species recorded at the
#   counts are not in the deposit: the authors deposited the 19 species of their case study.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "valente_2018_indiana_birds_comm"
dir <- download_dryad("10.5061/dryad.5d8s7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
d <- fread(file.path(dir, "Case Study Data.csv"))
setnames(d, 1, "row")
stopifnot(nrow(d) == 11001L, uniqueN(d$point) == 193L, uniqueN(d$sppcode) == 19L, all(d$year == 2014L),
          all(d$visit %in% 1:3), all(d$observer %in% 1:4), all(d$wind %in% 0:3),
          !anyDuplicated(d[, .(point, visit, sppcode)]), nrow(d) == 193L * 3L * 19L,
          all(d[, uniqueN(scientific), by = sppcode]$V1 == 1L), all(d[, uniqueN(sppcode), by = scientific]$V1 == 1L))
I <- c("det.interval1", "det.interval2", "det.interval3")
stopifnot(all(unlist(d[, c(I, "det.visit"), with = FALSE]) %in% 0:1),
          all(d$det.visit == pmax(d$det.interval1, d$det.interval2, d$det.interval3)))
# survey-level and point-level fields are constant where they should be
stopifnot(all(d[, lapply(.SD, uniqueN), by = .(point, visit), .SDcols = c("date", "observer", "time", "temp", "wind", "cloud")][, -(1:2)] == 1L),
          all(d[, lapply(.SD, uniqueN), by = point, .SDcols = c("utm.x", "utm.y", "plot", "property")][, -1] == 1L),
          all(d[, uniqueN(date), by = point]$V1 == 3L))
d[, dt := as.IDate(date)]
stopifnot(!anyNA(d$dt), all(yday(d$dt) == d$julian), all(d$dt %between% as.IDate(c("2014-06-16", "2014-07-16"))))
stopifnot(all(d$utm.x %between% c(5e5, 6.5e5)), all(d$utm.y %between% c(4.28e6, 4.36e6)))

long <- d[, .(unit = as.character(point), taxon = sppcode, y = det.visit, occasion = visit, date = as.character(dt),
              observer = as.character(observer), cluster_id = plot, unit_property = property, unit_x = utm.x, unit_y = utm.y,
              obs_det_interval1 = det.interval1, obs_det_interval2 = det.interval2, obs_det_interval3 = det.interval3,
              obs_time_min = time, obs_temp_f = temp, obs_wind_beaufort = wind, obs_cloud_pct = cloud)]
long <- order_eco(long)
stopifnot(nrow(long) == 11001L, sum(long$y) == 2987L)

sp <- unique(d[, .(sppcode, scientific, species)])[order(sppcode)]
taxa <- make_taxa(sp$sppcode, sp$scientific, vernacularName = sp$species)

dataset <- list(
  title = "Point-count detections of 19 forest bird species at 193 stations on 12 plots in southern Indiana, three visits, June-July 2014",
  creator = "Valente, Jonathon J.; Hutchinson, Rebecca A.; Betts, Matthew G.",
  pubDate = "2018", doi = "10.5061/dryad.5d8s7", sourceURL = "https://doi.org/10.5061/dryad.5d8s7",
  citation = "Valente, J. J., Hutchinson, R. A., & Betts, M. G. (2018). Data from: Distinguishing distribution dynamics from temporary emigration using dynamic occupancy models [Dataset]. Dryad. https://doi.org/10.5061/dryad.5d8s7",
  paperDOI = "10.1111/2041-210x.12840",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Ten-minute, 50 m radius point counts at 193 stations on 12 forest plots within six public properties in southern Indiana, each visited three times between 16 June and 16 July 2014 by one of four observers, with detection of each of 19 forest bird species recorded in three 3 min 20 s intervals. The paper uses the data to ask whether repeat visits within a season are closed or open to temporary emigration.",
  samplingProtocol = "10-minute point count, 50 m fixed radius, split into three 3 min 20 s intervals; three visits per station in the 2014 breeding season; time, temperature, wind and cloud recorded per visit.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "open", occasionKind = "time", taxonInclusion = "recorded",
  closureNote = "the three visits span 16 June to 16 July 2014; the paper's question is whether visits within a season are closed, and it found dynamic (open) models better supported than closed ones for all 19 species in its empirical data. obs_det_interval1-3 are the three intervals within one count.",
  geographicCoverage = "Southern Indiana, USA: Crane Army Ammunition Plant, Big Oaks National Wildlife Refuge, Martin and Owen-Putnam State Forests, Spring Mill and McCormick's Creek State Parks",
  temporalCoverage = "2014-06/2014-07",
  crs = "UTM zone 16N metres as the README states (datum not stated; NAD83 / WGS 84 differ by about 1 m): unit_x = easting, unit_y = northing",
  coordinatesCoarsened = list(value = FALSE, method = "Station coordinates kept as published: none of the 19 species is IUCN CR, EN or VU, and the source flags none"),
  notShipped = list(julian = "day of year of the shipped date",
                    other_species = "species recorded at the counts other than the 19 of the case study are not in the deposit (the authors' selection)"),
  notes = "y = detection in any interval (det.visit); obs_det_interval1-3 hold the interval detections for time-to-detection or removal-type models. Taxon codes are the 4-letter banding codes. Only detections inside 50 m were recorded.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/valente_2018_indiana_birds_comm.R")

stage_dict_row(TABLE,
  description = "Detection / non-detection of 19 forest bird species in three-visit 10-minute point counts at 193 stations on 12 plots in southern Indiana, June-July 2014, with per-interval detections, observer, weather and station coordinates.",
  url = "https://doi.org/10.5061/dryad.5d8s7",
  reference = "Valente, J. J., Hutchinson, R. A., & Betts, M. G. (2017). Distinguishing distribution dynamics from temporary emigration using dynamic occupancy models. Methods in Ecology and Evolution, 8(12), 1707-1716.",
  doi_paper = "10.1111/2041-210x.12840", doi_data = "10.5061/dryad.5d8s7",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community occupancy, single season, three visits; three within-count intervals as obs_ columns; 19 species selected by the authors.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (single season; within-count intervals for time-to-detection)",
  sampling_protocol = "point_count", design = "Single-season (3 visits, 3 intervals per count; stations within plots)",
  realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Temporary emigration test data; closure questioned by the source.")
