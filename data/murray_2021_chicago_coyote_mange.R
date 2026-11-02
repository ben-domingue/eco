#!/usr/bin/env Rscript
# Table:  murray_2021_chicago_coyote_mange
# Source: Dryad doi:10.5061/dryad.x3ffbg7js (CC0 1.0), version 118054 (published 2021-05-04)
#   Murray, M., Fidino, M., Lehrer, E.W., Simonis, J.L. & Magle, S.B. (2021). A multi-state
#   occupancy model to non-invasively monitor visible signs of wildlife health with camera
#   traps that accounts for image quality [Dataset]. Dryad.
#   Code: github.com/mfidino/coyote-mange (doi:10.5281/zenodo.4721864).
# Paper:  Murray, M.H., Fidino, M., Lehrer, E.W., Simonis, J.L. & Magle, S.B. (2021). A
#         multi-state occupancy model to non-invasively monitor visible signs of wildlife
#         health with camera traps that accounts for image quality. Journal of Animal
#         Ecology 90(8), 1973-1985, doi:10.1111/1365-2656.13515
# Data:   coyote_detection_data.csv: 54,656 rows = 122 camera stations x 16 seasons x 28 days
#         (Season code SP/SU/FA/WI + 2-digit year; Week 1-4; Date; StationID; SurveyID =
#         station-season; Coyote = NA camera not active, 0 active and no coyote, 1 coyote
#         detected that day). Every station-season has exactly 28 consecutive dates, the same
#         dates for every station in a season (asserted). 607 station-seasons have no active
#         day, 856 are partly active; 7 stations are never active.
#         coydata_merged_sites.csv: 3,971 coyote images with the image date, surveyid, site,
#         Mange_signs_present (0/1, 213 images with signs), blur (Laplacian variance, higher =
#         sharper), In_color, propbodyvis (proportion of the body visible, 0.01-0.55).
#         3,686 images fall on a detection day with Coyote = 1 and none on a Coyote = 0 day
#         (asserted); 270 are dated outside the 28-day sampling windows and 15 fall on
#         inactive (NA) days. The authors' prep_data.R drops both groups by an inner join on
#         surveyid + date; so does this script.
#         model_covariates.csv: house (houses per km2), tree (tree cover), imp (impervious
#         cover) within 1 km of 113 sites. raw_site_coords.csv: UTM zone 16N for 136 sites.
#         Murray_et_al_README.pdf: column definitions; no use restriction on coordinates.
#
# Mapping (standard E9, multi-state occupancy with a disease state):
#   unit = camera station (115 with at least one active day), period = season in time order
#   (SP10 = 1 ... WI14 = 16; __periods carries the code, season, year, dates and sampling
#   week), occasion = day 1-28 of the season's sampling window, date = that calendar date,
#   taxon = CANLAT. y = 0 camera active and no coyote; 1 coyote detected, no image that day
#   shows mange signs; 2 at least one image that day shows visible signs of sarcoptic mange
#   (responseType = state, stateCodes in metadata). The authors modelled weekly coyote
#   detection (binomial over 4 weeks) with a separate per-image mange classification layer
#   conditional on site-season mange state; the day-level state code here is the same
#   information at the deposited resolution (obs_week gives their aggregation).
#   Survey evidence: a station-day is surveyed iff Coyote is not NA (effort_table: the
#   deposited operability flag). Observation covariates per station-day from the images:
#   obs_n_images, obs_n_mange_images, obs_mean_blur, obs_prop_in_color, obs_max_propbodyvis
#   (NA on days without an image). Site covariates: unit_house_km2, unit_tree_cover,
#   unit_impervious_cover as deposited (NA for 2 stations not in model_covariates.csv);
#   unit_decimalLatitude / unit_decimalLongitude converted from the deposited UTM 16N
#   (coyote is not a flagged taxon; kept at source precision).
#   Not shipped: images outside the sampling windows or on inactive days; the authors' PCA
#   urbanisation axes and the seasonal temperature vector (both derived in their code, not
#   deposited); their exclusion of stations with fewer than 2 seasons of data (all active
#   stations are shipped; filter on __periods / unit as needed).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "murray_2021_chicago_coyote_mange"
dir <- download_dryad("10.5061/dryad.x3ffbg7js", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

det <- fread(file.path(dir, "coyote_detection_data.csv"))
img <- fread(file.path(dir, "coydata_merged_sites.csv"))
cov <- fread(file.path(dir, "model_covariates.csv"))
xy  <- fread(file.path(dir, "raw_site_coords.csv"))
stopifnot(nrow(det) == 54656, nrow(img) == 3971, nrow(cov) == 113, nrow(xy) == 136,
          identical(names(det), c("Season", "Week", "Date", "SeasonWeek", "StationID", "SurveyID", "IDWeek", "Coyote")),
          all(det$Coyote %in% c(NA, 0L, 1L)), uniqueN(det$StationID) == 122, uniqueN(det$Season) == 16,
          all(img$Mange_signs_present %in% 0:1), sum(img$Mange_signs_present) == 213, all(img$site == substr(img$surveyid, 1, 8)))
det[, Date := as.IDate(Date)]; img[, date := as.IDate(date)]
det[, week := as.integer(sub("^[Ww]eek ?", "", Week))]; stopifnot(all(det$week %in% 1:4))

# seasons: 16 consecutive sampling windows of 28 days, identical dates across stations
seasons <- data.table(code = c("SP10", "SU10", "FA10", "WI11", "SP11", "SU11", "FA11", "WI12", "SP12", "SU12", "FA12", "WI13", "SP13", "SU13", "FA13", "WI14"))
seasons[, period := .I]
win <- det[, .(start = min(Date), end = max(Date), n_dates = uniqueN(Date), n_rows = .N), by = Season]
stopifnot(setequal(win$Season, seasons$code), all(win$n_dates == 28), all(win$end - win$start == 27), all(win$n_rows == 122 * 28))
seasons <- merge(seasons, win[, .(code = Season, start, end)], by = "code")[order(period)]
stopifnot(all(diff(seasons$start) > 0), all(det[, .N, by = .(SurveyID)]$N == 28))
det <- merge(det, seasons[, .(Season = code, period, start)], by = "Season")
det[, occasion := as.integer(Date - start) + 1L]; stopifnot(all(det$occasion %in% 1:28))

# survey set = active station-days
act <- det[!is.na(Coyote)]
stopifnot(nrow(act) == 32898, sum(act$Coyote) == 2027, uniqueN(act$StationID) == 115)
cat(sprintf("  %d active station-days at %d stations (%d of 1,952 station-seasons never active)\n",
            nrow(act), uniqueN(act$StationID), det[, all(is.na(Coyote)), by = SurveyID][, sum(V1)]))

# images -> station-day (inner join on surveyid + date, as the authors' prep_data.R)
im <- merge(img, act[, .(SurveyID, Date, Coyote)], by.x = c("surveyid", "date"), by.y = c("SurveyID", "Date"))
stopifnot(nrow(im) == 3686, all(im$Coyote == 1), nrow(img) - nrow(im) == 285, sum(im$Mange_signs_present) == 199)
cat(sprintf("  %d of %d images fall on an active detection day; %d outside the sampling windows / on inactive days dropped (%d of them with mange signs)\n",
            nrow(im), nrow(img), nrow(img) - nrow(im), sum(img$Mange_signs_present) - sum(im$Mange_signs_present)))
imday <- im[, .(n_images = .N, n_mange = sum(Mange_signs_present), mean_blur = round(mean(blur), 1),
                prop_color = round(mean(In_color), 3), max_bodyvis = max(propbodyvis)), by = .(SurveyID = surveyid, Date = date)]

long <- merge(act, imday, by = c("SurveyID", "Date"), all.x = TRUE)
long[, y := fifelse(Coyote == 0L, 0L, fifelse(!is.na(n_mange) & n_mange > 0L, 2L, 1L))]
stopifnot(all(long[y == 0, Coyote] == 0), all(long[y > 0, Coyote] == 1), sum(long$y == 2) == uniqueN(im[Mange_signs_present == 1, paste(surveyid, date)]))
cat(sprintf("  y: %d no coyote, %d coyote without mange signs, %d coyote with mange signs (%d station-seasons with signs)\n",
            sum(long$y == 0), sum(long$y == 1), sum(long$y == 2), uniqueN(long[y == 2, SurveyID])))

# site covariates and coordinates (UTM zone 16N -> WGS84)
utm_to_ll <- function(E, N, zone = 16) {
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
ll <- utm_to_ll(xy$utmEast, xy$utmNorth)
xy[, `:=`(lat = round(ll$lat, 5), lon = round(ll$lon, 5))]
stopifnot(all(xy$lat > 41.3 & xy$lat < 42.4), all(xy$lon > -88.5 & xy$lon < -87.4), !anyDuplicated(xy$site), !anyDuplicated(cov$site))
stations <- data.table(unit = sort(unique(long$StationID)))
stopifnot(all(stations$unit %in% xy$site), sum(!stations$unit %in% cov$site) == 2)
stations <- merge(stations, xy[, .(unit = site, lat, lon)], by = "unit")
stations <- merge(stations, cov[, .(unit = site, house, tree, imp)], by = "unit", all.x = TRUE)

long <- merge(long, stations, by.x = "StationID", by.y = "unit")
long <- long[, .(unit = StationID, taxon = "CANLAT", y, period, occasion, date = format(Date),
                 unit_decimalLatitude = lat, unit_decimalLongitude = lon,
                 unit_house_km2 = house, unit_tree_cover = tree, unit_impervious_cover = imp,
                 obs_week = week, obs_n_images = n_images, obs_n_mange_images = n_mange, obs_mean_blur = mean_blur,
                 obs_prop_in_color = prop_color, obs_max_propbodyvis = max_bodyvis)]
long <- order_eco(long)
stopifnot(nrow(long) == 32898, uniqueN(long$unit) == 115, !anyDuplicated(long[, .(unit, period, occasion)]))

taxa <- make_taxa("CANLAT", "Canis latrans", vernacularName = "Coyote")
periods <- merge(seasons, long[, .(n_units_active = uniqueN(unit), n_units_mange = uniqueN(unit[y == 2])), by = period], by = "period")
periods <- periods[, .(period, code, season = c(SP = "spring", SU = "summer", FA = "fall", WI = "winter")[substr(code, 1, 2)],
                       year = 2000L + as.integer(substr(code, 3, 4)), start = format(start), end = format(end), n_units_active, n_units_mange)]

dataset <- list(
  title = "Daily camera-trap detections of coyotes with and without visible signs of sarcoptic mange at 115 stations across the Chicago metropolitan area, 16 seasons 2010-2014",
  creator = "Murray, Maureen; Fidino, Mason; Lehrer, Elizabeth W.; Simonis, Juniper L.; Magle, Seth B.",
  pubDate = "2021", doi = "10.5061/dryad.x3ffbg7js", sourceURL = "https://doi.org/10.5061/dryad.x3ffbg7js",
  citation = "Murray, M., Fidino, M., Lehrer, E. W., Simonis, J. L., & Magle, S. B. (2021). A multi-state occupancy model to non-invasively monitor visible signs of wildlife health with camera traps that accounts for image quality [Dataset]. Dryad. https://doi.org/10.5061/dryad.x3ffbg7js",
  paperDOI = "10.1111/1365-2656.13515",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap data from the Urban Wildlife Information Network's Chicago transect (Lincoln Park Zoo): motion-triggered cameras deployed for 28 days each season (spring, summer, fall, winter) from spring 2010 to winter 2014 at sites along an urbanisation gradient. Every coyote image was scored for visible signs of sarcoptic mange (hair loss), image clarity (Laplacian-variance blur metric), colour versus greyscale and the proportion of the body visible, to fit a multi-state occupancy model with a mange-detection layer that accounts for image quality.",
  samplingProtocol = "Motion-triggered trail cameras, one per site, 28 consecutive days per season; daily coyote detection / non-detection (NA when the camera was not active); each coyote image classified for visible mange signs and three image-quality measures.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day", effortColumn = NA,
  surveyEvidence = "effort_table",
  surveyEvidenceNote = "The deposited daily Coyote column is NA when the camera was not active and 0/1 otherwise; a row exists iff the camera was active that day. 607 of 1,952 station-seasons and 7 of 122 stations were never active and have no rows.",
  responseType = "state", unitKind = "site",
  closure = "period (coyote occupancy and mange state are modelled per site-season; days within the 28-day window are replicate observations)",
  stateCodes = list(`0` = "camera active, no coyote detected", `1` = "coyote detected, no image that day shows signs of mange", `2` = "coyote detected and at least one image that day shows visible signs of sarcoptic mange"),
  geographicCoverage = list(description = "Chicago metropolitan area, Illinois, USA (Cook, DuPage, Kane, Lake, McHenry and Will counties), urban to exurban green space",
                            boundingBox = list(west = round(min(stations$lon), 2), east = round(max(stations$lon), 2), south = round(min(stations$lat), 2), north = round(max(stations$lat), 2))),
  temporalCoverage = "2010-05-04/2014-02-09",
  coordinatesCoarsened = list(value = FALSE, method = "deposited UTM zone 16N converted to WGS84 decimal degrees (5 dp); coyote is not a flagged taxon and the README places no restriction on the coordinates"),
  notShipped = list(`285 images` = "270 images dated outside the 28-day sampling windows and 15 on inactive camera-days, dropped as in the authors' prep_data.R (inner join on surveyid + date); 14 of them show mange signs",
                    `urbanisation PCA axes, seasonal temperature` = "derived in the authors' code repository, not deposited; the three raw urbanisation covariates are shipped",
                    `station exclusion` = "the authors dropped stations with fewer than 2 seasons of data; all 115 active stations are shipped",
                    `weekly aggregation` = "the authors' detection model used 4 weekly occasions (max over days); obs_week lets a user reproduce it"),
  notes = "y = 2 requires an image with mange signs on that day; days with a coyote detection but no retained image (331 of 2,027) are y = 1. Image-quality covariates (blur, colour, proportion of body visible) are per-day aggregates of per-image values and are NA on days without an image. Two active stations (R02-GFP1, D03-STB1) have no entry in model_covariates.csv, so their unit_house_km2 / unit_tree_cover / unit_impervious_cover are NA.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/murray_2021_chicago_coyote_mange.R")

stage_dict_row(TABLE,
  description = "Daily multi-state camera-trap observations of coyotes (0 none / 1 detected / 2 detected with visible sarcoptic mange signs) at 115 Chicago-area camera stations over 16 seasons (2010-2014, 28 days each), with per-day image-quality covariates, site urbanisation covariates and coordinates.",
  url = "https://doi.org/10.5061/dryad.x3ffbg7js",
  reference = "Murray, M. H., Fidino, M., Lehrer, E. W., Simonis, J. L., & Magle, S. B. (2021). A multi-state occupancy model to non-invasively monitor visible signs of wildlife health with camera traps that accounts for image quality. Journal of Animal Ecology, 90(8), 1973-1985.",
  doi_paper = "10.1111/1365-2656.13515", doi_data = "10.5061/dryad.x3ffbg7js", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-state (disease) occupancy. Survey set from the deposited daily operability flag (NA = inactive). 285 images outside windows / on inactive days dropped as in the authors' code. UTM 16N converted to WGS84. Fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state dynamic occupancy (disease state)",
  sampling_protocol = "camera_trap", design = "Multi-season (16 seasons x 28 days)", realm = "Terrestrial", country = "USA",
  coordinates = "As published (UTM 16N converted to decimal degrees)",
  notes = "Urban Wildlife Information Network, Chicago. y = 2 is a visible-mange image on that camera-day; image-quality covariates per day.",
  status = "tagged")
