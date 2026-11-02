#!/usr/bin/env Rscript
# Table:  doyle_2025_chinalake_tortoise_scr
# Source: Dryad doi:10.5061/dryad.k98sf7mk4 (CC0 1.0 as shown on the dataset JSON), version
#   407815 (published 2025-12-05). Doyle, S., Murphy, S. & Esque, T. Data for fitting spatial
#   capture-recapture (SCR) models to estimate spatially explicit demographics of Mojave desert
#   tortoises on a demography plot in California, USA.
# Paper:  Herpetologica, doi:10.1655/Herpetologica-D-24-00059 (Dryad primary_article).
# Data:   two tab-separated secr input files.
#         ChinaLake_Detections_SexAge.txt: 99 detection records, columns Session (SR1 for all),
#           ID (CL + four digits, or CLtemp### for 5 tortoises not tagged), Occasion (survey
#           day 1-4, September 2022), Trap (grid cell of the detection), Location (Burrow,
#           Mouth, Open, Veg), Sex (F, M, U), Age (A, J), SexAge (FA, MA, J, NA = unknown-sex
#           adult). 24 distinct IDs (the methods text says 25 tortoises). Several records can
#           fall on the same ID x day x cell (one tortoise seen again in another position).
#         ChinaLake_Detectors_Cat.txt: 548 'effective detectors' = 50 m grid cells covering
#           the 1 km2 plot and the surveyors' GPS tracks: Trap, X, Y (UTM NAD83 zone 11N
#           centroid), Effort = four space-separated per-occasion values, an integer search-
#           effort category 0-5 (secr usage; 0 = the cell was not searched that day).
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture, as
#   curveirasantos_2026_phinda_carniv_scr.R): unit = tortoise ID, taxon = GOPAGA, trap = grid
#   cell, occasion = survey day 1-4, one period, y = 1 if the tortoise was recorded in that cell
#   that day, y_raw = number of records (two or more when it was recorded in several positions).
#   Survey evidence: effort_table. A cell x day is surveyed iff its effort category > 0; every
#   individual has a row at every surveyed cell-day (the SCR rectangle); every detection falls
#   on a surveyed cell-day (asserted). obs_effort = the effort category (constant across
#   individuals); obs_location = position(s) at detection (";"-joined), NA on non-detection
#   rows. unit_sex, unit_age, unit_sexage as recorded (asserted constant per tortoise);
#   unit_temp_id = TRUE for the five untagged tortoises.
#   Coordinates: Gopherus agassizii is IUCN Critically Endangered and US-listed threatened.
#   E7 forbids shipping cell centroids finer than 0.1 degree; coarsening a 1 km plot destroys
#   the inter-detector distances the SCR likelihood needs, so __traps carries x_m, y_m = UTM
#   easting/northing minus the grid centroid (local metres), as the Phinda tables do; the
#   centroid is given at 0.1 degree in geographicCoverage.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "doyle_2025_chinalake_tortoise_scr"
dir <- download_dryad("10.5061/dryad.k98sf7mk4", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fd <- file.path(dir, "ChinaLake_Detections_SexAge.txt"); ft <- file.path(dir, "ChinaLake_Detectors_Cat.txt")
stopifnot(file.exists(fd), file.exists(ft))

d <- fread(fd, colClasses = "character", na.strings = NULL)
stopifnot(identical(names(d), c("Session", "ID", "Occasion", "Trap", "Location", "Sex", "Age", "SexAge")),
          nrow(d) == 99L, all(d$Session == "SR1"), uniqueN(d$ID) == 24L, all(grepl("^CL([0-9]{4}|temp[0-9]{3})$", d$ID)),
          all(d$Occasion %in% as.character(1:4)), all(d$Location %in% c("Burrow", "Mouth", "Open", "Veg")),
          all(d$Sex %in% c("F", "M", "U")), all(d$Age %in% c("A", "J")), all(d$SexAge %in% c("FA", "MA", "J", "NA")))
stopifnot(d[, .(uniqueN(Sex), uniqueN(Age), uniqueN(SexAge)), by = ID][, all(V1 == 1L & V2 == 1L & V3 == 1L)])

tl <- sub("\r$", "", readLines(ft)); stopifnot(tl[1] == "Trap\tX\tY\tEffort", length(tl) == 549L)
tp <- rbindlist(lapply(strsplit(tl[-1], "[\t ]+"), function(z)
  data.table(trap = as.integer(z[1]), X = as.numeric(z[2]), Y = as.numeric(z[3]),
             e1 = as.integer(z[4]), e2 = as.integer(z[5]), e3 = as.integer(z[6]), e4 = as.integer(z[7]))))
stopifnot(nrow(tp) == 548L, !anyDuplicated(tp$trap), !anyNA(tp), all(as.matrix(tp[, e1:e4]) %in% 0:5))
stopifnot(diff(range(tp$X)) <= 2000, diff(range(tp$Y)) <= 2000)
eff <- melt(tp[, .(trap, e1, e2, e3, e4)], id.vars = "trap", variable.name = "occ", value.name = "obs_effort")
eff[, occasion := as.integer(sub("e", "", occ))][, occ := NULL]
surveyed <- eff[obs_effort > 0L]
cat(sprintf("  548 detectors x 4 days: %d surveyed cell-days; %d cells never searched\n", nrow(surveyed),
            sum(!tp$trap %in% surveyed$trap)))

d[, `:=`(trap = as.integer(Trap), occasion = as.integer(Occasion))]
stopifnot(all(d$trap %in% tp$trap))
stopifnot(nrow(merge(d, surveyed, by = c("trap", "occasion"))) == nrow(d))     # every detection on a searched cell-day
det <- d[, .(y_raw = .N, obs_location = paste(unique(Location), collapse = ";")), by = .(unit = ID, trap, occasion)]
ind <- unique(d[, .(unit = ID, unit_sex = Sex, unit_age = Age, unit_sexage = SexAge, unit_temp_id = grepl("temp", ID))])
stopifnot(nrow(ind) == 24L)

long <- surveyed[rep(seq_len(.N), times = nrow(ind))]
long[, unit := rep(ind$unit, each = nrow(surveyed))]
long <- merge(long, det, by = c("unit", "trap", "occasion"), all.x = TRUE)
long[, y := as.integer(!is.na(y_raw))][is.na(y_raw), y_raw := 0L]
long <- merge(long, ind, by = "unit")
long[, `:=`(taxon = "GOPAGA", trap = as.character(trap))]
stopifnot(nrow(long) == 24L * nrow(surveyed), sum(long$y) == nrow(det), sum(long$y_raw) == 99L)
long <- order_eco(long)
cat(sprintf("  24 tortoises, %d detections (%d records), %d rows\n", nrow(det), nrow(d), nrow(long)))

# traps: centred local metres (E7, CR species), centroid at 0.1 degree for the metadata
utm_to_ll <- function(E, N, zone) {           # WGS 84 / UTM northern hemisphere (NAD83 differs by < 2 m)
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  list(lat = lat * 180 / pi, lon = (zone - 1) * 6 - 180 + 3 + lon * 180 / pi)
}
cx <- mean(tp$X); cy <- mean(tp$Y)
ctr <- utm_to_ll(cx, cy, zone = 11)
stopifnot(ctr$lat > 35 & ctr$lat < 36.5, ctr$lon > -118 & ctr$lon < -117)
ctr_c <- coarsen_coords(ctr$lat, ctr$lon)
traps <- tp[, .(trap = as.character(trap), x_m = round(X - cx, 1), y_m = round(Y - cy, 1),
                effort_day1 = e1, effort_day2 = e2, effort_day3 = e3, effort_day4 = e4)]
stopifnot(abs(mean(traps$x_m)) < 1, abs(mean(traps$y_m)) < 1)

taxa <- make_taxa("GOPAGA", "Gopherus agassizii", vernacularName = "Mojave Desert Tortoise", taxon_iucnCategory = "CR")
dataset <- list(
  title = "Spatial capture-recapture of 24 Mojave desert tortoises on a 1 km2 demography plot, Naval Air Weapons Station China Lake, California, September 2022",
  creator = "Doyle, Sarah; Murphy, Sean; Esque, Todd", pubDate = "2025", doi = "10.5061/dryad.k98sf7mk4",
  sourceURL = "https://doi.org/10.5061/dryad.k98sf7mk4",
  citation = "Doyle, S., Murphy, S., & Esque, T. (2025). Data for fitting spatial capture-recapture (SCR) models to estimate spatially explicit demographics of Mojave desert tortoises on a demography plot in California, USA [Dataset]. Dryad. https://doi.org/10.5061/dryad.k98sf7mk4",
  paperDOI = "10.1655/Herpetologica-D-24-00059",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Four days of transect searches for Mojave desert tortoises (Gopherus agassizii) on a previously unsampled 1 km x 1 km plot in the South Range of Naval Air Weapons Station China Lake, California, September 2022. Detections of 24 marked tortoises are assigned to 50 m grid cells ('effective detectors') built from the surveyors' GPS tracks, with an effort category per cell and day, as secr input. One row per tortoise x searched cell-day.",
  samplingProtocol = "Walked transect search of a 1 km2 plot on four consecutive days; live tortoises marked and tagged; surveyor GPS tracks discretised to 50 m cells with a per-day effort category used as secr usage.",
  samplingProtocolCode = "transect_search", surveyEvidence = "effort_table",
  surveyEvidenceNote = "ChinaLake_Detectors_Cat.txt gives each of 548 cells an effort category 0-5 for each of the four days; a cell-day is surveyed iff the category is > 0. Every detection falls on a surveyed cell-day.",
  responseType = "detection", unitKind = "individual",
  closure = "period (four consecutive days in September 2022, closed population)",
  geographicCoverage = sprintf("South Range, Naval Air Weapons Station China Lake, Kern/San Bernardino County, California, USA; plot centroid %.1f, %.1f (0.1 degree); detector positions in __traps as local metres centred on the grid", ctr_c$lat, ctr_c$lon),
  temporalCoverage = "2022-09", crs = "local: metres, UTM NAD83 zone 11N easting/northing minus the detector-grid centroid (processor-centred)",
  coordinatesCoarsened = list(value = TRUE, method = "detector coordinates centred on the grid centroid by the processor (local metres; exact UTM positions withheld) because Gopherus agassizii is IUCN Critically Endangered; the centroid is given at 0.1 degree in geographicCoverage"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Detectors are discretised search-track cells, not fixed traps; obs_effort is the secr usage category.",
  covariateNote = "obs_effort is the effort category 1-5 of the cell-day (constant across tortoises; also per day in __traps); obs_location the tortoise's position(s) when recorded.",
  notShipped = list(exact_coordinates = "UTM NAD83 11N detector centroids withheld (CR species); __traps carries them centred on the grid",
                    unsearched_cells = "cell-days with effort 0 (not surveyed) have no rows; the cells stay in __traps"),
  notes = "The methods text says 25 tortoises; the detection file holds 24 IDs. Five tortoises carry temporary IDs (not tagged, unit_temp_id). y_raw counts records of the tortoise in the cell that day (positions recorded more than once).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = "data/doyle_2025_chinalake_tortoise_scr.R")

stage_dict_row(TABLE,
  description = "Spatial capture-recapture of 24 Mojave desert tortoises (Gopherus agassizii) on a 1 km2 plot at Naval Air Weapons Station China Lake, California, over four survey days in September 2022: tortoise x searched 50 m cell x day, effort category per cell-day, sex and age; detector coordinates centred (CR species).",
  url = "https://doi.org/10.5061/dryad.k98sf7mk4",
  reference = "Doyle, S., Murphy, S., & Esque, T. (2025). Spatially explicit demographics of Mojave desert tortoises on a demography plot in California. Herpetologica.",
  doi_paper = "10.1655/Herpetologica-D-24-00059", doi_data = "10.5061/dryad.k98sf7mk4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "SCR (E9 experimental) with discretised search-track detectors and effort categories as secr usage. Detector coordinates centred on the grid (IUCN CR). First reptile SCR table.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Spatial capture-recapture",
  sampling_protocol = "transect_search", design = "Single-season (one session, 4 survey days)", realm = "Terrestrial",
  country = "USA", coordinates = "Coarsened (trap coordinates centred on the grid, local metres; CR species)",
  notes = "Experimental (E9): trap key + __traps; detectors are 50 m search cells with effort categories.")
