#!/usr/bin/env Rscript
# Tables: howe_2017_tai_duiker_ds, howe_2017_tai_duikerpeak_ds
# Source: Dryad doi:10.5061/dryad.b4c70, version 21413, licence CC0 1.0 (as shown on Dryad).
#         Howe, E. J., Buckland, S. T., Després-Einspenner, M.-L. & Kühl, H. S. "Data from:
#         Distance sampling with camera traps" (2018). The peak-activity file is also the
#         Distance package's DuikerCameraTraps (GPL); the deposit is built instead (CC0, both
#         files, camera coordinates).
# Paper:  Howe, E. J., Buckland, S. T., Després-Einspenner, M.-L. & Kühl, H. S. (2017). Distance
#         sampling with camera traps. Methods in Ecology and Evolution 8, 1558-1565.
#         doi:10.1111/2041-210X.12790 (not read; design from the Dryad README and the Distance
#         help page).
# Data:   DaytimeDistances.txt (11,181 rows) and PeakDistances.txt (6,277 rows): one row per
#         filmed Maxwell's duiker (Philantomba maxwellii) at a 2-second snapshot, with distance
#         (midpoint of its distance interval, m), Sample.Label (camera, 21 cameras), Effort
#         (number of 2-s time steps the camera operated: all daytime hours, or the peak-activity
#         hours only), Region.Label (Tai), Area (40.37 km2, m2 here), multiplier (42/360, the
#         camera's field of view), utm.e, utm.n (camera position, UTM 29N). A camera with no
#         detection has one row with distance NA (1 in the daytime file, 3 in the peak file).
#         VideoStartTimes_FullDays.txt: start times of the videos (not per detection; not
#         shipped). Taï National Park, Côte d'Ivoire, 2014.
#         Distance intervals: the midpoints are 1.5, 2.5, ..., 7.5, 9, 11, 13.5 and 18 m, which
#         fix the intervals (1,2], ..., (7,8], (8,10], (10,12], (12,15], (15,21] (each midpoint
#         is the centre of exactly one such interval; asserted). No detection is recorded within
#         1 m; whether the authors had a (0,1] interval is not in the deposit.
# Mapping (standard E9 declared stretch: camera-trap distance sampling, multinomial_cell with
#   distanceBreaks and snapshotInterval, as bedson_2021_holmemoss_hare_cam_ds):
#   unit = camera, taxon = PHIMAX, occasion = distance interval 1-11, y = number of snapshot
#   detections in it over the camera's deployment (0 where none); y_raw = the interval label.
#   unit_effort_steps = 2-s time steps operated (effortColumn); unit coordinates (WGS84 from UTM
#   29N, the source's metres; Maxwell's duiker is IUCN Least Concern). Survey evidence =
#   deposited_matrix: every camera appears, with an NA row when it detected nothing.
#   Two tables: all daytime hours, and the peak-activity hours subset the paper analysed
#   (which cannot be derived from the daytime table: detection times are not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/howe_2017_tai_duiker_ds.R"
dir <- download_dryad("10.5061/dryad.b4c70", "howe_2017_tai_duiker_ds")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "21413"),
          setequal(list.files(dir), c("DaytimeDistances.txt", "PeakDistances.txt", "VideoStartTimes_FullDays.txt")))
BRK <- c(1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 15, 21)
MID <- (head(BRK, -1) + tail(BRK, -1)) / 2
LAB <- sprintf("%g-%g", head(BRK, -1), tail(BRK, -1))
stopifnot(identical(MID, c(1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 9, 11, 13.5, 18)))
cams <- NULL
build <- function(file, TABLE, n_rows, n_na, peak) {
  d <- fread(file.path(dir, file))
  stopifnot(nrow(d) == n_rows, identical(names(d), c("distance", "Sample.Label", "Effort", "Region.Label", "Area", "multiplier", "utm.e", "utm.n")),
            sum(is.na(d$distance)) == n_na, all(d$distance %in% c(MID, NA)), uniqueN(d$Sample.Label) == 21L,
            all(d$Region.Label == "Tai"), all(d$Area == 40370000), all(abs(d$multiplier - 42 / 360) < 1e-6),
            d[, uniqueN(paste(Effort, utm.e, utm.n)), by = Sample.Label][, all(V1 == 1L)])
  cam <- unique(d[, .(unit = Sample.Label, unit_effort_steps = as.integer(Effort), e = utm.e, n = utm.n)])
  if (is.null(cams)) cams <<- cam[, .(unit, e, n)] else stopifnot(identical(cams, cam[, .(unit, e, n)]))
  cnt <- d[!is.na(distance), .N, by = .(unit = Sample.Label, occasion = match(distance, MID))]
  long <- CJ(unit = cam$unit, occasion = seq_along(MID))
  long <- merge(long, cnt, by = c("unit", "occasion"), all.x = TRUE)
  long[is.na(N), N := 0L]
  long <- merge(long, cam, by = "unit")
  ll <- sf_free_utm29(long$e, long$n)
  long[, `:=`(y = N, y_raw = LAB[occasion], unit_decimalLatitude = ll$lat, unit_decimalLongitude = ll$lon)]
  stopifnot(sum(long$y) == sum(!is.na(d$distance)), nrow(long) == 21L * 11L)
  long <- order_eco(long[, .(unit, taxon = "PHIMAX", y, y_raw, occasion, unit_effort_steps, unit_decimalLatitude, unit_decimalLongitude)])
  taxa <- make_taxa("PHIMAX", "Philantomba maxwellii", vernacularName = "Maxwell's duiker", taxon_iucnCategory = "LC")
  span <- if (peak) "the hours of peak duiker activity" else "all daytime hours"
  dataset <- list(
    title = sprintf("Camera-trap distance sampling of Maxwell's duikers at 21 cameras in Taï National Park, Côte d'Ivoire, 2014: %s", if (peak) "peak-activity hours" else "daytime"),
    creator = "Howe, Eric J.; Buckland, Stephen T.; Després-Einspenner, Marie-Lyne; Kühl, Hjalmar S.", pubDate = "2018",
    doi = "10.5061/dryad.b4c70", sourceURL = "https://doi.org/10.5061/dryad.b4c70",
    citation = "Howe, E. J., Buckland, S. T., Després-Einspenner, M.-L., & Kühl, H. S. (2018). Data from: Distance sampling with camera traps [Dataset]. Dryad. https://doi.org/10.5061/dryad.b4c70",
    paperDOI = "10.1111/2041-210X.12790",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Maxwell's duikers (Philantomba maxwellii) filmed by 21 camera traps in Taï National Park, Côte d'Ivoire, in 2014, for the first application of point-transect distance sampling to camera traps (Howe et al. 2017). At each 2-second snapshot a filmed duiker was assigned to a distance interval from the camera (11 intervals from 1 to 21 m). This table covers %s: one row per camera x distance interval, y = snapshot detections in the interval over the deployment, with the camera's temporal effort (2-s steps) and position.", span),
    samplingProtocol = "Camera traps (42-degree field of view) recording video; duikers in view at 2-second snapshot moments assigned to distance intervals from reference markers; effort = number of 2-s steps operated during the hours analysed.",
    samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
    surveyEvidenceNote = sprintf("Every camera appears in the file; a camera with no detection in the hours covered has a single row with no distance (%d here). Each camera has a row in every distance interval (0 where nothing was recorded).", n_na),
    responseType = "multinomial_cell", distanceBreaks = BRK, snapshotInterval = "2 s", fieldOfViewDegrees = 42,
    effortColumn = "unit_effort_steps", unitKind = "site", closure = "closed", closureNote = "occasion (distance intervals of one camera deployment)",
    occasionKind = "cell", taxonInclusion = "single",
    geographicCoverage = "Taï National Park, south-western Côte d'Ivoire (about 5.82 N, 7.27 W); camera positions as unit_decimalLatitude/Longitude",
    temporalCoverage = "2014", crs = "EPSG:4326, converted from the deposit's UTM 29N metres (EPSG:32629)",
    coordinatesCoarsened = list(value = FALSE, method = "camera positions as published (UTM metres, converted); Philantomba maxwellii is IUCN Least Concern"),
    notes = sprintf("Distance intervals inferred from the deposited midpoints (help page: 'recorded distances are the midpoints of the intervals'): (1,2], ..., (7,8], (8,10], (10,12], (12,15], (15,21] m; nothing is recorded within 1 m. y counts snapshot detections (a duiker seen at several 2-s steps counts at each), as in the paper's camera-trap distance sampling. Area 40.37 km2 and the field-of-view multiplier 42/360 are constants of the deposit. %s",
                    if (peak) "Sibling: howe_2017_tai_duiker_ds (all daytime hours). This peak subset is the Distance package's DuikerCameraTraps." else "Sibling: howe_2017_tai_duikerpeak_ds (peak-activity hours only, the paper's main analysis)."),
    notShipped = list(VideoStartTimes_FullDays.txt = "video start times, not linked to detections", Area_multiplier = "constants of the deposit (in notes)"))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Camera-trap distance sampling of Maxwell's duikers at 21 cameras in Taï National Park, Côte d'Ivoire, 2014 (%s): snapshot detections per camera and distance interval (1-21 m), with effort and camera positions.", span),
    url = "https://doi.org/10.5061/dryad.b4c70",
    reference = "Howe, E. J., Buckland, S. T., Després-Einspenner, M.-L., & Kühl, H. S. (2017). Distance sampling with camera traps. Methods in Ecology and Evolution, 8, 1558-1565.",
    doi_paper = "10.1111/2041-210X.12790", doi_data = "10.5061/dryad.b4c70", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Camera-trap distance sampling (multinomial_cell, snapshotInterval 2 s, FOV 42 deg). Interval bounds inferred from the deposited midpoints.",
    source_via = "Dryad (version zip)")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Camera-trap distance sampling",
    sampling_protocol = "camera_trap", design = "Single-season (one deployment per camera, 11 distance intervals)", realm = "Terrestrial",
    country = "CIV", coordinates = "As published (camera positions, converted from UTM)", notes = "Camera-trap distance sampling; Dryad original of Distance::DuikerCameraTraps.")
}
# UTM zone 29N (WGS84) to latitude/longitude, without sf/proj (not installed here): the
# standard Transverse Mercator inverse series (Snyder 1987), accurate to well under 1 m
sf_free_utm29 <- function(E, N) {
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  lon0 <- (-9) * pi / 180; x <- E - 500000; y <- N
  M <- y / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) +
          (151 * e1^3 / 96) * sin(6 * mu) + (1097 * e1^4 / 512) * sin(8 * mu)
  C1 <- ep2 * cos(phi1)^2; T1 <- tan(phi1)^2; N1 <- a / sqrt(1 - e2 * sin(phi1)^2)
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
         (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- lon0 + (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  list(lat = round(lat * 180 / pi, 6), lon = round(lon * 180 / pi, 6))
}
chk <- sf_free_utm29(691000, 644000)                      # pyproj gives 5.823628 N, -7.274943
stopifnot(abs(chk$lat - 5.823628) < 1e-5, abs(chk$lon + 7.274943) < 1e-5)
build("DaytimeDistances.txt", "howe_2017_tai_duiker_ds", 11182L - 1L, 1L, FALSE)
build("PeakDistances.txt", "howe_2017_tai_duikerpeak_ds", 6277L, 3L, TRUE)
