#!/usr/bin/env Rscript
# Table:  goldberg_2015_manas_leopard_scr
# Source: Dryad, doi:10.5061/dryad.mr1pt, version 18606, licence CC0 1.0 as shown on the Dryad dataset page (asserted
#         from the dataset JSON). Goldberg, J. F., Tempa, T., Norbu, N., Hebblewhite, M., Mills, L. S., Wangchuk, T. R.
#         & Lukacs, P.
# Paper:  Goldberg, J. F. et al. (2015). Examining temporal sample scale and model choice with spatial
#         capture-recapture models in the common leopard Panthera pardus. PLOS ONE 10(11): e0140757,
#         doi:10.1371/journal.pone.0140757 (open access, read). Methods p. 4: pairs of Reconyx cameras at 29 locations
#         in the lower foothills of Royal Manas National Park, Bhutan, mid-November to mid-February, 91 days, cameras
#         not moved during the 91-day period. Results p. 7: 22 leopards captured 82 times between 17 November 2010 and
#         15 February 2011 in 2,639 camera-trapping nights; "We considered camera stations to have operated
#         continuously for the duration of the study, since both cameras at a trap location never malfunctioned
#         simultaneously."
# Data:   'Leopard Camera Trapping Data (for Dryad).csv' (carriage-return line ends): 82 captures: AnimalID (1-22),
#           Sex, Date (d-Mon-yy), TrapID, x, y (the trap's UTM 46N position). 'Leopard Camera Traps (for dryad).csv':
#           cam_id and UTM 46N (WGS84) x, y of the 29 stations.
# Mapping (closed SCR, E9 experimental): unit = leopard, taxon = PANPAR, trap = station, occasion = day 1..91
#   (2010-11-17 + occasion - 1), date, y = 1 if photographed at the trap that day (never more than one capture
#   per leopard-trap-day, asserted, so no y_raw). Survey set: every station x day of the 91 days, for every leopard
#   (29 x 91 = 2,639 trap-nights, the paper's figure), surveyEvidence = inferred from the paper's statement of
#   continuous operation (the deposit has no operation table). unit_sex.
#   Coordinates (E7): leopard is IUCN VU; the trap coordinates are centred on the array (mean subtracted, local
#   metres, E7 ruling 2) and the array centroid is given at 0.1 deg in geographicCoverage; the captures' x, y
#   (duplicates of the trap positions) are not shipped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldberg_2015_manas_leopard_scr"
dir <- download_dryad("10.5061/dryad.mr1pt", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
raw <- readChar(file.path(dir, "Leopard Camera Trapping Data (for Dryad).csv"), 1e6)
cap <- fread(text = gsub("\r", "\n", raw))
tr <- fread(file.path(dir, "Leopard Camera Traps (for dryad).csv"))
stopifnot(identical(names(cap), c("AnimalID", "Sex", "Date", "TrapID", "x", "y")), nrow(cap) == 82L, uniqueN(cap$AnimalID) == 22L,
          nrow(tr) == 29L, !anyDuplicated(tr$cam_id), all(cap$TrapID %in% tr$cam_id), all(cap$Sex %in% c("Male", "Female")),
          cap[, uniqueN(Sex), by = AnimalID][, all(V1 == 1L)])
cap[, d := as.IDate(Date, "%d-%b-%y")]
D1 <- as.IDate("2010-11-17"); days <- seq(D1, by = "day", length.out = 91)
stopifnot(!anyNA(cap$d), min(cap$d) == D1, max(cap$d) == as.IDate("2011-02-15"), max(days) == as.IDate("2011-02-15"))
# capture x, y are the trap positions
m <- merge(cap, tr, by.x = "TrapID", by.y = "cam_id", suffixes = c("", ".t"))
stopifnot(all(abs(m$x - m$x.t) < 1), all(abs(m$y - m$y.t) < 1))
cap[, occasion := as.integer(d - D1) + 1L]
cnt <- cap[, .(y_raw = .N), by = .(unit = as.character(AnimalID), trap = as.character(TrapID), occasion)]
grid <- CJ(unit = as.character(sort(unique(cap$AnimalID))), trap = as.character(tr$cam_id), occasion = 1:91)
long <- cnt[grid, on = .(unit, trap, occasion)]
long[is.na(y_raw), y_raw := 0L]
long[, `:=`(taxon = "PANPAR", y = as.integer(y_raw > 0), date = format(D1 + occasion - 1L))]
long <- merge(long, unique(cap[, .(unit = as.character(AnimalID), unit_sex = tolower(Sex))]), by = "unit")
stopifnot(all(long$y_raw <= 1L))   # one capture per leopard-station-day at most, so y_raw would equal y
long[, y_raw := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 22L * 29L * 91L, sum(long$y) == 82L)
cat(sprintf("  %d rows; %d leopards (%d M), %d captures at %d of 29 stations\n", nrow(long), uniqueN(long$unit),
            long[unit_sex == "male", uniqueN(unit)], sum(long$y), uniqueN(cap$TrapID)))

# traps centred on the array (E7 ruling 2)
cx <- mean(tr$x); cy <- mean(tr$y)
utm_to_ll <- function(E, N, zone) {           # WGS 84 / UTM, northern hemisphere
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6) / cos(phi1)
  list(lat = lat * 180 / pi, lon = (zone * 6 - 183) + lon * 180 / pi) }
ctr <- utm_to_ll(cx, cy, 46); ctr_c <- coarsen_coords(ctr$lat, ctr$lon)
stopifnot(ctr$lat > 26.5, ctr$lat < 27.2, ctr$lon > 90.5, ctr$lon < 91.5)
traps <- tr[, .(trap = as.character(cam_id), x_m = round(x - cx, 1), y_m = round(y - cy, 1), n_days_operating = 91L)]
taxa <- make_taxa("PANPAR", "Panthera pardus", vernacularName = "Leopard")

dataset <- list(
  title = "Spatial capture-recapture of 22 leopards at 29 camera stations over 91 days, Royal Manas National Park, Bhutan, November 2010 to February 2011",
  creator = "Goldberg, Joshua F.; Tempa, Tshering; Norbu, Nawang; Hebblewhite, Mark; Mills, L. Scott; Wangchuk, Tshewang R.; Lukacs, Paul",
  pubDate = "2015", doi = "10.5061/dryad.mr1pt", sourceURL = "https://doi.org/10.5061/dryad.mr1pt",
  citation = "Goldberg, J. F., Tempa, T., Norbu, N., Hebblewhite, M., Mills, L. S., Wangchuk, T. R., & Lukacs, P. (2015). Data from: Examining temporal sample scale and model choice with spatial capture-recapture models in the common leopard Panthera pardus [Dataset]. Dryad. https://doi.org/10.5061/dryad.mr1pt",
  paperDOI = "10.1371/journal.pone.0140757",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Paired camera traps at 29 stations in a 162 km2 grid in the foothills of Royal Manas National Park, Bhutan, run continuously for 91 days (17 November 2010 to 15 February 2011); 22 leopards identified from pelage, 82 captures. The authors compared SCR density estimates under daily, weekly, monthly and quarterly sampling intervals. One row per leopard x station x day.",
  samplingProtocol = "Pairs of Reconyx cameras on paths and animal trails at 29 locations on a 2.5 km grid, unbaited, not moved for 91 days, serviced every two to four weeks; a leopard photographed at a station on a day is a capture.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "The deposit has no camera operation table. The paper (p. 7) states that every station operated continuously for the 91 days (both cameras of a pair never failed together), 2,639 trap-nights = 29 x 91; every station x day is a survey on that statement.",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "a 91-day winter session treated as closed by the authors; daily occasions",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = sprintf("Royal Manas National Park, Bhutan; camera array centroid %.1f N, %.1f E (0.1 degree); trap positions in __traps as local metres centred on the array", ctr_c$lat, ctr_c$lon),
  temporalCoverage = "2010-11/2011-02",
  crs = "local: metres, UTM 46N (WGS84) easting/northing minus the array centroid (processor-centred)",
  coordinatesCoarsened = list(value = TRUE, method = "trap coordinates centred on the array centroid by the processor (local metres; exact UTM 46N positions withheld) because the leopard is IUCN VU; the centroid is given at 0.1 degree in geographicCoverage"),
  notShipped = list(capture_xy = "the x, y of each capture (the trap's UTM position, asserted)", exact_coordinates = "UTM 46N trap positions (centred, E7)",
                    model_output = "density estimates"),
  notes = "At most one capture per leopard, station and day in the deposit.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = "data/goldberg_2015_manas_leopard_scr.R")
stage_dict_row(TABLE,
  description = "Spatial capture-recapture histories of 22 leopards at 29 camera stations over 91 days in Royal Manas National Park, Bhutan, 2010-2011, leopard x station x day; trap coordinates centred on the array.",
  url = "https://doi.org/10.5061/dryad.mr1pt",
  reference = "Goldberg, J. F., Tempa, T., Norbu, N., Hebblewhite, M., Mills, L. S., Wangchuk, T. R., & Lukacs, P. (2015). Examining temporal sample scale and model choice with spatial capture-recapture models in the common leopard Panthera pardus. PLOS ONE, 10(11), e0140757.",
  doi_paper = "10.1371/journal.pone.0140757", doi_data = "10.5061/dryad.mr1pt",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed SCR; survey set from the paper's statement of continuous operation (inferred); traps centred (IUCN VU).",
  source_via = "Dryad (per-file, token)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed, camera traps)",
  sampling_protocol = "camera_trap", design = "Single-season (91 daily occasions; 29 camera stations)",
  realm = "Terrestrial", country = "BTN", coordinates = "Coarsened (trap coordinates centred on the array, local metres; VU)",
  notes = "Experimental (E9): trap key + __traps; survey set from the paper.")
