#!/usr/bin/env Rscript
# Table:  doser_2022_neon2015_removal
# Source: spOccupancy package dataset neon2015 (GPL >= 3; CRAN spOccupancy 0.8.2, data/
#         neon2015.rda fetched from github.com/doserjef/spOccupancy, main branch). The package
#         authors' subset of NEON Breeding landbird point counts, RELEASE-2021 (DP1.10003.001,
#         doi:10.48443/s730-dy13, accessed 2021-10-10) at the Bartlett Experimental Forest site
#         (BART), New Hampshire, 2015, as analysed in Doser, Leuenberger, Sillett, Hallworth &
#         Zipkin (2022, MEE, doi:10.1111/2041-210X.13811).
# Data:   neon2015 is a list: y[12 species, 80 sites, 3 intervals] with the time-removal
#         encoding the Rd documents: one 6-minute, 125 m radius count per site split into three
#         2-minute intervals; 1 in the interval of first detection, 0 in the intervals before,
#         NA in the intervals after (the species is "removed"); 0 0 0 = never detected.
#         occ.covs (80 x 1) elevation; det.covs$day (80) day of year, det.covs$tod (80) hour the
#         count began; coords (80 x 2) UTM zone 19 NAD83. No site names: sites are 1..80 in
#         array order. Asserted: every NA follows exactly one 1 within the same site x species,
#         so NA is removal structure, not a missing survey; every site was surveyed once.
# Mapping (standard E9 declared stretch, responseType = multinomial_cell, multinomialType =
#   removal; cf. chandler_2009_alfl_removal): unit = site 1..80, taxon = AOU alpha code,
#   occasion = removal interval 1..3 with y_raw = "int1".."int3", y = 1 if the species was first
#   detected in that interval else 0 (the deposit's NA after detection = 0 new detections);
#   every species carries three cells at every site (community rule). unit_elevation_m,
#   unit_day_of_year, unit_time_of_day_h (one count per site, so unit level), date from day of
#   year and 2015, unit_decimalLatitude / unit_decimalLongitude converted from UTM 19N,
#   unit_utm19_easting_m / _northing_m as published. Two species (BLPW, NAWA) were never
#   detected and ship as all-zero taxa (E4 note 2). surveyEvidence = deposited_matrix.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "doser_2022_neon2015_removal"
CACHE <- "doser_2022_spoccupancy"   # shared with doser_2022_hbef_trends_dynocc

rda <- download_cached("https://raw.githubusercontent.com/doserjef/spOccupancy/main/data/neon2015.rda", CACHE, "neon2015.rda")
e <- new.env(); load(rda, e); n <- e$neon2015
y <- n$y
stopifnot(dim(y) == c(12, 80, 3), is.null(dimnames(y)), all(y[!is.na(y)] %in% 0:1), sum(is.na(y)) == 461)
sp <- c("AMRE", "BAWW", "BHVI", "BLBW", "BLPW", "BTBW", "BTNW", "CAWA", "MAWA", "NAWA", "OVEN", "REVI")   # Rd species order
# removal encoding: NA iff after the single 1 in the site x species history; no NA in interval 1
for (s in 1:12) for (i in 1:80) {
  v <- y[s, i, ]; w <- which(is.na(v)); f <- which(v == 1)
  stopifnot(length(f) <= 1, if (length(w)) (length(f) == 1 && identical(w, seq(f + 1L, 3L))) else TRUE)
}
stopifnot(all(!is.na(y[, , 1])))
first_int <- apply(y, c(1, 2), function(v) { f <- which(v == 1); if (length(f)) f else 0L })
stopifnot(sum(first_int == 1) == 218, sum(first_int == 2) == 25, sum(first_int == 3) == 9, sum(first_int == 0) == 708)
det_by_sp <- apply(y, 1, sum, na.rm = TRUE); names(det_by_sp) <- sp
stopifnot(det_by_sp[["BLPW"]] == 0, det_by_sp[["NAWA"]] == 0, sum(det_by_sp) == 252)
stopifnot(length(n$det.covs$day) == 80, length(n$det.covs$tod) == 80, all(n$det.covs$day %in% 165:171), all(n$det.covs$tod %in% 5:10),
          nrow(n$occ.covs) == 80, all(n$occ.covs[, 1] >= 268 & n$occ.covs[, 1] <= 766))
stopifnot(nrow(n$coords) == 80, !anyDuplicated(n$coords), all(n$coords[, 1] > 314000 & n$coords[, 1] < 319000),
          all(n$coords[, 2] > 4878000 & n$coords[, 2] < 4881500))
cat(sprintf("  12 species x 80 sites x 3 removal intervals; %d species-site detections (%d / %d / %d by interval); 2 species never detected\n",
            sum(first_int > 0), sum(first_int == 1), sum(first_int == 2), sum(first_int == 3)))

utm_to_ll <- function(E, N, zone = 19) {
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  lon0 <- (zone - 1) * 6 - 180 + 3
  list(lat = lat * 180 / pi, lon = lon0 + lon * 180 / pi)
}
ll <- utm_to_ll(n$coords[, 1], n$coords[, 2])
stopifnot(all(ll$lat > 44.03 & ll$lat < 44.08), all(ll$lon > -71.33 & ll$lon < -71.24))   # Bartlett Experimental Forest

# cells: y = 1 in the interval of first detection, 0 otherwise (NA after detection = no new detection)
Y <- aperm(y, c(2, 3, 1)); Y[is.na(Y)] <- 0L                   # 80 x 3 x 12
dimnames(Y) <- list(as.character(1:80), NULL, sp)
stopifnot(sum(Y) == 252, all(apply(Y, c(1, 3), sum) <= 1))
y_raw <- array(rep(c("int1", "int2", "int3"), each = 80), dim = dim(Y))
site_covs <- data.frame(elevation_m = round(n$occ.covs[, 1], 2), day_of_year = n$det.covs$day, time_of_day_h = n$det.covs$tod,
                        decimalLatitude = round(ll$lat, 5), decimalLongitude = round(ll$lon, 5),
                        utm19_easting_m = round(n$coords[, 1], 2), utm19_northing_m = round(n$coords[, 2], 2))
long <- array_to_eco(Y, site_ids = as.character(1:80), site_covs = site_covs, y_raw = y_raw)
long[, date := format(as.Date(unit_day_of_year - 1, origin = "2015-01-01"))]
long <- order_eco(long)
stopifnot(nrow(long) == 80 * 3 * 12, uniqueN(long$unit) == 80, uniqueN(long$taxon) == 12, max(long$occasion) == 3,
          all(long[occasion == 2, y_raw] == "int2"), sum(long$y) == 252, all(grepl("^2015-06-", long$date)))

codes <- fread("data/aux/bird_alpha_codes.csv"); stopifnot(all(sp %in% codes$code))
taxa <- make_taxa(sp, codes$scientificName[match(sp, codes$code)], vernacularName = codes$commonName[match(sp, codes$code)])
dataset <- list(
  title = "NEON Bartlett Experimental Forest 2015: time-removal detections of 12 foliage-gleaning bird species in three 2-minute intervals at 80 point-count sites (spOccupancy::neon2015)",
  creator = "National Ecological Observatory Network (NEON); Doser, Jeffrey W. (spOccupancy subset)",
  pubDate = "2022", sourceURL = "https://cran.r-project.org/package=spOccupancy",
  citation = "Doser, J. W., Leuenberger, W., Sillett, T. S., Hallworth, M. T. & Zipkin, E. F. (2022). Integrated community occupancy models: A framework to assess occurrence and biodiversity dynamics using multiple data sources. Methods in Ecology and Evolution 13, 919-932. https://doi.org/10.1111/2041-210X.13811. Data: spOccupancy::neon2015 (Doser, Finley, Kery & Zipkin 2022, MEE 13, 1670-1678), from NEON Breeding landbird point counts RELEASE-2021 (DP1.10003.001), https://doi.org/10.48443/s730-dy13, Bartlett Experimental Forest.",
  paperDOI = "10.1111/2041-210X.13811",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook time-removal community dataset: one 6-minute, 125 m radius point count at each of 80 NEON sites in Bartlett Experimental Forest, New Hampshire, June 2015, split into three 2-minute intervals; for each of 12 foliage-gleaning songbirds the cell of first detection is 1 and the others 0 (the package encodes intervals after detection as NA, which here is zero new detections). Two species were never detected and ship as all-zero taxa. Site elevation, coordinates, survey day and start hour.",
  samplingProtocol = "6-minute point count with a 125 m radius, one per site, split into three 2-minute removal intervals; species recorded in the interval of first detection and mentally removed thereafter.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "multinomial_cell", multinomialType = "removal", unitKind = "site", closure = "closed", occasionKind = "cell", taxonInclusion = "target",
  geographicCoverage = "Bartlett Experimental Forest (NEON site BART), New Hampshire, USA (80 point-count sites)",
  temporalCoverage = "2015-06-14/2015-06-20",
  crs = "EPSG:4269 (NAD83) UTM zone 19N as published in unit_utm19_*; unit_decimalLatitude/Longitude converted in-script, NAD83 ~ WGS84",
  coordinatesCoarsened = list(value = FALSE, method = "as published in spOccupancy (NEON site coordinates to the metre); common species, none IUCN CR/EN/VU"),
  notes = "occasion indexes the 2-minute removal interval (E9 declared stretch), y_raw = int1..int3. One count per site, so day of year and start hour are unit-level covariates. The package's NA-after-detection encoding is converted to y = 0 (no new detection in later intervals); the cell-probability function (multinomialType = removal) recovers the authors' occupancy reading. NEON's full point-count product (all species, distance and minute of detection, 47 sites) is queued separately and needs an API token.",
  notShipped = list(none = "every object in neon2015 is shipped"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/doser_2022_neon2015_removal.R")
stage_dict_row(TABLE,
  description = "Time-removal detections of 12 foliage-gleaning bird species (first-detection interval of three 2-minute intervals) at 80 NEON point-count sites in Bartlett Experimental Forest, NH, June 2015, with elevation, coordinates, survey day and hour (spOccupancy::neon2015; Doser et al. 2022). Two species never detected.",
  url = "https://cran.r-project.org/package=spOccupancy",
  reference = "Doser, J. W., Leuenberger, W., Sillett, T. S., Hallworth, M. T. & Zipkin, E. F. (2022). Integrated community occupancy models. Methods in Ecology and Evolution 13, 919-932. Package: Doser, Finley, Kery & Zipkin (2022) MEE 13, 1670-1678.",
  doi_paper = "10.1111/2041-210X.13811", original_license = "GPL-3", derived_license = "GPL-3",
  notes = "Textbook dataset bundled with an R package (spOccupancy). Removal design on species detection (not individuals): occasion = 2-minute interval, multinomialType = removal; NA-after-detection in the package array shipped as 0.",
  source_via = "R package (spOccupancy, via GitHub source)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (time-removal; multinomial cells)",
  sampling_protocol = "point_count", design = "Single-season (one 6-min count x 3 removal intervals)", realm = "Terrestrial", country = "USA",
  coordinates = "As published (NEON site coordinates, UTM 19N and WGS84)", notes = "Textbook dataset (spOccupancy). Declared stretch: occasion = removal interval. 2 of 12 species all-zero.")
