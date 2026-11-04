#!/usr/bin/env Rscript
# Table:  bison_2024_montblanc_hare_dynocc
# Source: Dryad doi:10.5061/dryad.b2rbnzsp7 (CC0 1.0), version 277486 (2024-02-07)
#   Bison, M., Yoccoz, N.G., Carlson, B.Z., Bayle, A. & Delestrade, A. (2024). Data from: Camera
#   traps reveal seasonal variation in activity and occupancy of the Alpine mountain hare
#   (Lepus timidus varronis). Dryad.
# Paper:  Bison, M., Yoccoz, N.G., Carlson, B.Z., Bayle, A. & Delestrade, A. (2024). Camera traps
#         reveal seasonal variation in activity and occupancy of the Alpine mountain hare Lepus
#         timidus varronis. Wildlife Biology 2024(4): e01186, doi:10.1002/wlb3.01186 (CC BY).
#         Only the abstract was reachable (HAL hal-04891446; Wiley and Munin refuse the agent):
#         46 camera traps along elevation gradients in the Mont-Blanc massif, France, January
#         2018 to June 2022; multi-season occupancy through the year and single-season
#         occupancy in the breeding season, unmarked + camtrapR. The authors' occasion length
#         and season definitions are in the paper and are NOT known here (see Mapping).
# Data:   taghare_1day.csv: 870 rows (Station; Date dd/mm/yyyy), one row per camera-day with at
#         least one mountain hare contact, 2017-10-27 to 2022-07-05, 37 of the 46 stations.
#         camerainfo.csv: 46 stations (semicolon, latin-1): Exposition (aspect), Elevation (m),
#         longitude, Latitude (WGS84, 4-6 decimals), Slope (deg), Habitat, camera Model,
#         setup_date (2016-06-16 to 2021-11-12), and up to 14 Problem[k] / _from / _to
#         triples (185 downtime windows: snow 127, battery, bugs, full SD, destroyed, removed,
#         ...). No retrieval or end date per camera.
#         out_plot.csv: 47 vegetation plots (one per camera; peclerey1400 is named
#         peclerey1400_Reconyx; posettes1800 has no camera): slope class, elevation, aspect,
#         coordinates, relief homogeneity, cover class 0-5 of six vegetation strata.
#         out_height.csv (3,760 point heights) and out_contact.csv (266 pin-touch counts by
#         vegetation type): raw point-intercept measurements per plot.
#         README.md documents every column.
#
# Mapping (standard section 3.6, single-species detection from a record table with a
# deployment table):
#   unit = camera station (46), taxon = LEPTIM, y = 1 if taghare_1day has that camera-day,
#   else 0, responseType detection. A camera-day is a survey iff setup_date <= day <= the
#   study end (2022-06-30, the abstract's "June 2022"; the deposit has no end dates) and the
#   day is inside no Problem window. surveyEvidence = inferred: start and downtime are
#   deposited, the end is from the abstract. 13 contacts fall inside Problem windows (the
#   windows are "camera compromised", e.g. moved by snow, not strictly "camera off") and 2
#   fall after 2022-06-30: dropped and logged, so the survey set and the detections agree.
#   period = meteorological season (Dec-Feb winter, Mar-May spring, Jun-Aug summer, Sep-Nov
#   autumn), integer in time order, labels and dates in __periods; occasion = day index
#   within the season; date = the calendar day, so a user can re-bin to the authors'
#   occasions once the paper is in hand. This season binning is the processor's, not the
#   authors' (theirs is in the paywalled methods).
#   unit_* covariates as deposited: coordinates as published (Least Concern taxon, public
#   mountain terrain), elevation, slope, aspect, habitat, camera model, and from out_plot
#   the relief homogeneity and six strata cover classes. Not shipped: out_height and
#   out_contact (raw per-point vegetation measurements, no aggregation given), the plot
#   without a camera, the Problem cause strings (free text in two languages).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bison_2024_montblanc_hare_dynocc"
dir <- download_dryad("10.5061/dryad.b2rbnzsp7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rd <- function(f) fread(file.path(dir, f), sep = ";", na.strings = c("NA", ""), encoding = "Latin-1")
ci <- rd("camerainfo.csv"); th <- rd("taghare_1day.csv"); op <- rd("out_plot.csv")
oh <- rd("out_height.csv"); oc <- rd("out_contact.csv")
stopifnot(nrow(ci) == 46, ncol(ci) == 51, nrow(th) == 870, nrow(op) == 47, nrow(oh) == 3760, nrow(oc) == 266,
          !anyDuplicated(ci$Station), all(th$Station %in% ci$Station))
th[, date := as.IDate(Date, "%d/%m/%Y")]; ci[, setup := as.IDate(setup_date, "%d/%m/%Y")]
stopifnot(!anyNA(th$date), !anyNA(ci$setup), !anyDuplicated(th[, .(Station, date)]),
          min(th$date) == as.IDate("2017-10-27"), max(th$date) == as.IDate("2022-07-05"),
          min(ci$setup) == as.IDate("2016-06-16"), max(ci$setup) == as.IDate("2021-11-12"),
          uniqueN(th$Station) == 37)
stopifnot(all(ci$Habitat %in% c("forest", "grassland", "prairie", "shrubland", "shrubland sur crete")),
          all(ci$Exposition %in% c("NO", "O", "S", "SE", "SO")), all(ci$Elevation >= 1227 & ci$Elevation <= 2740),
          all(ci$longitude > 6.8 & ci$longitude < 7.1), all(ci$Latitude > 45.8 & ci$Latitude < 46.1))

# downtime windows
pr <- rbindlist(lapply(grep("^Problem[0-9]+$", names(ci), value = TRUE), function(p)
  ci[!is.na(get(p)), .(Station, cause = get(p), from = as.IDate(get(paste0(p, "_from")), "%d/%m/%Y"),
                       to = as.IDate(get(paste0(p, "_to")), "%d/%m/%Y"))]))
stopifnot(nrow(pr) == 185, !anyNA(pr$from), !anyNA(pr$to), all(pr$from <= pr$to),
          all(pr$from >= ci$setup[match(pr$Station, ci$Station)]), sum(grepl("snow", pr$cause, ignore.case = TRUE)) == 136)
STUDY_END <- as.IDate("2022-06-30")

# survey set: camera-days from setup to study end, minus downtime
days <- ci[, .(date = seq(setup, STUDY_END, by = "day")), by = .(unit = Station)]
down <- pr[, .(unit = Station, date = seq(from, to, by = "day")), by = .(w = seq_len(nrow(pr)))][, w := NULL]
down <- unique(down)                                      # 3 stations have overlapping windows
n_all <- nrow(days); days <- days[!down, on = .(unit, date)]
cat(sprintf("  %d camera-days from setup to %s; %d (%.0f%%) inside downtime windows removed; %d surveyed\n",
            n_all, STUDY_END, n_all - nrow(days), 100 * (n_all - nrow(days)) / n_all, nrow(days)))
stopifnot(uniqueN(days$unit) == 46)

# detections that the survey set cannot carry
th[, unit := Station]
in_down <- th[down, on = .(unit, date), nomatch = 0]; late <- th[date > STUDY_END]
stopifnot(nrow(in_down) == 13, nrow(late) == 2, all(th$date >= ci$setup[match(th$unit, ci$Station)]))
cat(sprintf("  dropped %d contacts inside downtime windows and %d after %s\n", nrow(in_down), nrow(late), STUDY_END))
det <- th[!down, on = .(unit, date)][date <= STUDY_END]
stopifnot(nrow(det) == 870 - 13 - 2, nrow(det[!days, on = .(unit, date)]) == 0)

# seasons (meteorological) as periods
season_of <- function(d) { m <- month(d); fifelse(m %in% c(12, 1, 2), "winter", fifelse(m %in% 3:5, "spring", fifelse(m %in% 6:8, "summer", "autumn"))) }
season_year <- function(d) year(d) + (month(d) == 12)        # Dec belongs to the following winter
days[, `:=`(season = season_of(date), syear = season_year(date))]
days[, skey := syear * 10 + match(season, c("winter", "spring", "summer", "autumn"))]
periods <- days[, .(start = min(date), end = max(date), n_units = uniqueN(unit), n_camera_days = .N), by = .(skey, season, syear)][order(skey)]
periods[, period := seq_len(.N)]
periods[, label := ifelse(season == "winter", sprintf("winter %d/%02d", syear - 1L, syear %% 100), sprintf("%s %d", season, syear))]
stopifnot(nrow(periods) == 20, periods$start[1] == as.IDate("2017-09-07"), periods$end[.N] == STUDY_END)   # the 2016 setups sit inside downtime windows until Sept 2017
days <- merge(days, periods[, .(skey, period)], by = "skey")
setorder(days, unit, date); days[, occasion := as.integer(date - min(date)) + 1L, by = .(unit, period)]
stopifnot(all(days$occasion >= 1 & days$occasion <= 92))

# covariates
ci[, Model := gsub("Buchnell", "Bushnell", Model)]
op[, name_camera := sub("^peclerey1400_Reconyx$", "peclerey1400", name_camera)]
stopifnot(setequal(setdiff(op$name_camera, ci$Station), "posettes1800"), all(ci$Station %in% op$name_camera))
op <- op[name_camera != "posettes1800"]; stopifnot(nrow(op) == 46, !anyDuplicated(op$name_camera))
for (k in 0:5) stopifnot(all(op[[paste0("strata.", k)]] %in% c(NA, 0:5)))
cov <- merge(ci[, .(unit = Station, unit_decimalLatitude = Latitude, unit_decimalLongitude = longitude, unit_elevation_m = Elevation,
                    unit_slope_deg = round(Slope, 1), unit_aspect = Exposition, unit_habitat = Habitat, unit_camera_model = Model)],
             op[, .(unit = name_camera, unit_relief_homogeneity = relief.homogeneity, unit_slope_class = slope.class,
                    unit_cover_bare_class = strata.0, unit_cover_lt10cm_class = strata.1, unit_cover_10_40cm_class = strata.2,
                    unit_cover_40_130cm_class = strata.3, unit_cover_130_400cm_class = strata.4, unit_cover_tree_class = strata.5)], by = "unit")
stopifnot(nrow(cov) == 46)

long <- merge(days[, .(unit, period, occasion, date)], det[, .(unit, date, y = 1L)], by = c("unit", "date"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, taxon := "LEPTIM"]
long <- merge(long, cov, by = "unit")
long[, date := format(date)]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(days), sum(long$y) == nrow(det), uniqueN(long$unit) == 46, !anyDuplicated(long[, .(unit, period, occasion)]))

taxa <- make_taxa("LEPTIM", "Lepus timidus", vernacularName = "Alpine mountain hare", taxon_subspecies = "varronis", taxon_iucnCategory = "LC")
periods_out <- periods[, .(period, season_label = label, season, year = syear, start = format(start), end = format(end), n_units, n_camera_days)]

dataset <- list(
  title = "Daily camera-trap detections of the Alpine mountain hare at 46 stations along elevation gradients in the Mont-Blanc massif, France, 2017-2022",
  creator = "Bison, Marjorie; Yoccoz, Nigel G.; Carlson, Bradley Z.; Bayle, Arthur; Delestrade, Anne",
  pubDate = "2024", doi = "10.5061/dryad.b2rbnzsp7", sourceURL = "https://doi.org/10.5061/dryad.b2rbnzsp7",
  citation = "Bison, M., Yoccoz, N. G., Carlson, B. Z., Bayle, A., & Delestrade, A. (2024). Data from: Camera traps reveal seasonal variation in activity and occupancy of the Alpine mountain hare (Lepus timidus varronis) [Dataset]. Dryad. https://doi.org/10.5061/dryad.b2rbnzsp7",
  paperDOI = "10.1002/wlb3.01186",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap contacts of the Alpine mountain hare (Lepus timidus varronis) at 46 stations between 1,227 and 2,740 m in forest, shrubland and grassland of the Mont-Blanc massif (Haute-Savoie, France), with station setup dates, downtime windows, site descriptors and vegetation-structure classes from point-intercept plots. The paper used the data for multi-season occupancy through the year and single-season occupancy in the breeding season.",
  samplingProtocol = "Motion-triggered camera traps (Moultrie 40i/50i, Reconyx HF2X, Bushnell NatureView) at fixed stations along elevation gradients, running continuously from setup; contacts recorded as camera-days with at least one hare photo. Surveyed camera-days = setup date to 30 June 2022 minus the deposited downtime (Problem) windows.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day",
  surveyEvidence = "inferred",
  surveyEvidenceNote = "Setup dates and 185 downtime windows are deposited; no retrieval dates. The study end (2022-06-30) is the paper's 'June 2022' (abstract); every camera is assumed to run from setup to that date outside its downtime windows. 13 contacts inside downtime windows (windows mark compromised as well as dead cameras) and 2 after the study end were dropped so that detections and the survey set agree.",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "period (meteorological season; the processor's binning, not the authors', whose season definition is in the paywalled methods)", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Mont-Blanc massif, Haute-Savoie, France (6.84-7.01 E, 45.88-46.05 N), 1,227-2,740 m",
  temporalCoverage = "2017-09-07/2022-06-30",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published (Least Concern taxon; stations on open mountain terrain)"),
  notShipped = list(out_height.csv = "3,760 vegetation heights at point-intercept points, per plot (raw, unaggregated)",
                    out_contact.csv = "266 pin-touch counts by vegetation type, per plot (raw, unaggregated)",
                    posettes1800 = "vegetation plot with no camera station",
                    `Problem causes` = "free-text downtime causes (snow, battery, bug, destroyed, ...) used only to define downtime",
                    `13 contacts inside downtime windows, 2 after 2022-06-30` = "dropped (see surveyEvidenceNote)",
                    `contacts before 2018-01-01 (23)` = "KEPT although the paper's analysis starts January 2018; the deposit includes them"),
  notes = "period = meteorological season (Dec-Feb, Mar-May, Jun-Aug, Sep-Nov) labelled in __periods; the first surveyed day is 2017-09-07 because the three 2016 and two of the 2017 setups sit inside deposited downtime windows until then; occasion = day within season; date per row allows re-binning to the authors' occasions. Nine stations never recorded a hare. Camera 'Buchnell' in the source is Bushnell.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods_out, script = "data/bison_2024_montblanc_hare_dynocc.R")

stage_dict_row(TABLE,
  description = "Daily detection/non-detection of the Alpine mountain hare at 46 camera-trap stations (1,227-2,740 m) in the Mont-Blanc massif, France, September 2017 to June 2022, binned into 20 meteorological seasons, with surveyed camera-days from setup dates minus deposited downtime windows, station coordinates, elevation, slope, aspect, habitat and six vegetation-cover classes.",
  url = "https://doi.org/10.5061/dryad.b2rbnzsp7",
  reference = "Bison, M., Yoccoz, N. G., Carlson, B. Z., Bayle, A., & Delestrade, A. (2024). Camera traps reveal seasonal variation in activity and occupancy of the Alpine mountain hare Lepus timidus varronis. Wildlife Biology, 2024(4), e01186.",
  doi_paper = "10.1002/wlb3.01186", doi_data = "10.5061/dryad.b2rbnzsp7", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Record-table source (contact days) plus a camera table with setup dates and downtime windows but no end dates: survey set inferred to 2022-06-30 (abstract). Season binning is the processor's; the paper's occasion and season definitions were not reachable. Fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (single species, seasonal)",
  sampling_protocol = "camera_trap", design = "Multi-season (20 meteorological seasons x daily occasions, 2017-2022)", realm = "Terrestrial", country = "France",
  coordinates = "As published", notes = "Survey set inferred from setup dates, downtime windows and the abstract's study end; 13 in-downtime and 2 post-study contacts dropped.",
  status = "tagged")
