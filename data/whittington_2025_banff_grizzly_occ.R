#!/usr/bin/env Rscript
# Table:  whittington_2025_banff_grizzly_occ
# Source: Dryad, doi:10.5061/dryad.g79cnp5wv, version 352578 (version 5, published 2025-03-17), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON). Data collected by Parks Canada and the
#         University of Montana (README, "Sharing/Access information").
#   Whittington, J., Hebblewhite, M., Meyer, M., Johnston, B., Forshner, A., Macbeth, B., Einfeldt, A. & Cherry, M.
#   Data from: One-stage spatial mark-resight analysis reveals an increasing grizzly bear population with declining
#   density near roads [Dataset]. Dryad.
# Paper:  Whittington, J. et al. One-stage spatial mark-resight analysis reveals an increasing grizzly bear population
#         with declining density near roads. Ecosphere. doi:10.1002/ecs2.70246. Not supplied; the design below is
#         from the deposit (Dryad abstract and methods, README.md, tbl_DataDescription_2023-11-13.csv): remote
#         cameras at 625 sites in Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda ecosystem (15,483 km2,
#         Canadian Rocky Mountains), 2012-2021, grizzly bears counted in 14-day occasions; 25 radio-collared bears
#         identifiable on camera; one-stage generalized spatial mark-resight (gSMR) models in nimble.
# Data:   occ_long_cam.csv: 31,180 rows, one per camera site x year x 14-day occasion in which the camera ran:
#           site.id, location (site name with the UTM easting and northing), start, end, occasion (1-14; occasions
#           1-13 are 14-day windows from 1 May, occasion 14 is 30 October alone), NDays (days the camera ran in the
#           occasion, 1-16), Year, NTotal (detections), NEvents (detection events), NFamilyEvents, YOYEvents (events
#           with cubs of the year), Detect (grizzly detected, 0/1), YOY (cub of the year detected, 0/1).
#         site_cam.csv: 625 sites: x, y (UTM zone 11 NAD83), rubtree, underpass, overpass (0/1), Type (trail,
#           rubtree, underpass, overpass), rsf (mean resource selection function value, 30 m), rsf30.spring /
#           .summer / .fall (seasonal RSF bins 0-10), tri (ruggedness), nSpecies, NDays, NEvents, NDetectDays,
#           DetectRate14 (site summaries over a span longer than occ_long_cam: NDays is not its sum; not shipped).
#         detect_year_cam.csv: occ_long_cam summed by site-year (rebuilt exactly and asserted, except
#           NYoyEvents, lower than the occasion sum in 32 site-years; not shipped).
#         detect_marked.csv (per collared bear x site x occasion detections), gps_day.csv (daily GPS of 25 collared
#           bears), tbl_juvenile.csv (parturition and cub fates of collared females), pix_xy.csv, pixel_lookup.csv,
#           d2_cam.csv, tbl_specs.csv, tbl_area_parks.csv and three .sqlite shapefiles (gSMR state space, study
#           area, camera sites): the spatial mark-resight inputs.
# Mapping (camera occupancy over years; responseType detection, unitKind site):
#   unit = camera site ("C001".."C625", from site.id), taxon = URSARC, period = year (1 = 2012 .. 10 = 2021;
#   __periods), occasion = the deposited occasion 1-14, date = the occasion's start (ISO), y = Detect.
#   surveyEvidence = effort_table: a row exists exactly where the camera ran (NDays >= 1 on every row; site-years
#   and occasions without a running camera are absent).
#   Covariates: unit_location (site name as published), unit_x / unit_y (UTM 11N NAD83, EPSG:26911, as
#   published), unit_type, unit_rubtree, unit_underpass, unit_overpass, unit_rsf, unit_rsf_spring / _summer /
#   _fall, unit_tri (habitat values; the RSF is the authors' habitat model from other data, not from these
#   detections); obs_days_active (NDays; effortColumn), obs_end_date, obs_n_detections (NTotal), obs_n_events
#   (NEvents), obs_n_family_events, obs_n_yoy_events, obs_yoy_detected (YOY).
#   Coordinates (E7; re-checked in batch 46, #10, after the ruling on the publisher withdrew the agency exception):
#   not flagged, so kept as published. (b) grizzly bear is IUCN LC (asserted); (a) the deposit does not call the bear
#   threatened or its locations sensitive (its abstract speaks of "species at risk" in general only); (c) it cites no
#   red list (the bear is Special Concern under Canada's SARA, which the deposit does not cite and which is not a
#   threatened category).
# Not shipped: the spatial mark-resight part (detect_marked, gps_day telemetry, tbl_juvenile, state-space pixels,
#   distances, shapefiles): marked-animal resighting with telemetry is not an E9 design; site summaries
#   (site_cam nSpecies, NDays, NEvents, NDetectDays, DetectRate14) and detect_year_cam (aggregates); the
#   authors' density and abundance estimates (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "whittington_2025_banff_grizzly_occ"
dir <- download_dryad("10.5061/dryad.g79cnp5wv", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "352578"),
          length(list.files(dir)) == 16L)

o <- fread(file.path(dir, "occ_long_cam.csv"))
s <- fread(file.path(dir, "site_cam.csv"))
y <- fread(file.path(dir, "detect_year_cam.csv"))
stopifnot(identical(names(o), c("site.id", "location", "start", "end", "occasion", "NDays", "Year", "NTotal", "NEvents",
                                "NFamilyEvents", "YOYEvents", "Detect", "YOY")),
          identical(names(s), c("site.id", "location", "x", "y", "rubtree", "underpass", "overpass", "Type", "rsf",
                                "rsf30.spring", "rsf30.summer", "rsf30.fall", "tri", "nSpecies", "NDays", "NEvents",
                                "NDetectDays", "DetectRate14")),
          nrow(o) == 31180L, nrow(s) == 625L, identical(s$site.id, 1:625), !anyNA(o), !anyNA(s),
          !anyDuplicated(o[, .(site.id, Year, occasion)]), all(o$site.id %in% s$site.id), uniqueN(o$site.id) == 625L,
          identical(sort(unique(o$Year)), 2012:2021), all(o$occasion %in% 1:14),
          all(o$Detect %in% 0:1), all(o$YOY %in% 0:1), all(o$Detect == as.integer(o$NEvents > 0)),
          all(o$YOY == as.integer(o$YOYEvents > 0)), all(o$NTotal >= o$NEvents), all(o$NFamilyEvents <= o$NEvents),
          all(o$YOYEvents <= o$NEvents), all(o$NDays >= 1L), all(o$NDays <= 16L),
          # site names agree between files
          nrow(merge(unique(o[, .(site.id, location)]), s[, .(site.id, location)], by = c("site.id", "location"))) == 625L,
          setequal(unique(s$Type), c("trail", "rubtree", "underpass", "overpass")),
          all(unlist(s[, .(rubtree, underpass, overpass)]) %in% 0:1), all(unlist(s[, .(rsf30.spring, rsf30.summer, rsf30.fall)]) %in% 0:10),
          all(s$x > 4e5 & s$x < 7e5), all(s$y > 5.5e6 & s$y < 5.9e6))
# occasions: the same calendar window in every year; 1-13 are 14 days from 1 May, 14 is 30 October alone
o[, `:=`(start = as.Date(start), end = as.Date(end))]
win <- unique(o[, .(Year, occasion, start, end)])
stopifnot(nrow(win) == 140L, win[, all(start == as.Date(sprintf("%d-05-01", Year)) + 14L * (occasion - 1L))],
          win[occasion <= 13L, all(as.integer(end - start) == 13L)], win[occasion == 14L, all(start == end)])
# NDays exceeds the window length by one or two days in 91 rows (as deposited)
stopifnot(o[, sum(NDays > as.integer(end - start) + 1L)] == 91L)
# detect_year_cam is occ_long_cam summed by site-year
a <- o[, .(nCamOcc = .N, nDetOcc = sum(Detect), NEvents = sum(NEvents), NTotal = sum(NTotal), NFamilyEvents = sum(NFamilyEvents),
           NYoyEvents = sum(YOYEvents)), by = .(site.id, Year)]
z <- merge(y, a, by = c("site.id", "Year"))
stopifnot(nrow(y) == nrow(a), nrow(z) == nrow(a),
          z[, all(nCamOcc.x == nCamOcc.y & nDetOcc.x == nDetOcc.y & NEvents.x == NEvents.y & NTotal.x == NTotal.y &
                  NFamilyEvents.x == NFamilyEvents.y)],
          # cub-of-the-year events: the yearly file is lower in 32 site-years (never higher), so it is not a plain sum
          z[, sum(NYoyEvents.x != NYoyEvents.y)] == 32L, z[, all(NYoyEvents.x <= NYoyEvents.y)])

long <- o[, .(unit = sprintf("C%03d", site.id), site.id, taxon = "URSARC", y = as.integer(Detect), period = Year - 2011L,
              occasion = as.integer(occasion), date = format(start), obs_days_active = as.integer(NDays),
              obs_end_date = format(end), obs_n_detections = as.integer(NTotal), obs_n_events = as.integer(NEvents),
              obs_n_family_events = as.integer(NFamilyEvents), obs_n_yoy_events = as.integer(YOYEvents),
              obs_yoy_detected = as.integer(YOY))]
long <- merge(long, s[, .(site.id, unit_location = location, unit_x = x, unit_y = y, unit_type = Type, unit_rubtree = rubtree,
                          unit_underpass = underpass, unit_overpass = overpass, unit_rsf = rsf, unit_rsf_spring = rsf30.spring,
                          unit_rsf_summer = rsf30.summer, unit_rsf_fall = rsf30.fall, unit_tri = tri)], by = "site.id")
long[, site.id := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 31180L, uniqueN(long$unit) == 625L, sum(long$y) == 5716L)
cat(sprintf("  %d rows, %d cameras, %d site-years, %d occasions with a grizzly\n", nrow(long), uniqueN(long$unit),
            uniqueN(long[, .(unit, period)]), sum(long$y)))

taxa <- make_taxa("URSARC", "Ursus arctos", vernacularName = "Grizzly bear")
stopifnot(identical(iucn_category(taxa$taxonID, taxa$scientificName), "LC"))
taxa[, taxon_iucnCategory := "LC"]
periods <- data.table(period = 1:10, year = 2012:2021, first_date = sprintf("%d-05-01", 2012:2021), last_date = sprintf("%d-10-30", 2012:2021),
                      n_cameras = as.integer(long[, uniqueN(unit), by = period][order(period)]$V1))

dataset <- list(
  title = "Grizzly bear detections in 14-day occasions at 625 remote camera sites in Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda, Alberta and British Columbia, May-October 2012-2021",
  creator = "Whittington, Jesse; Hebblewhite, Mark; Meyer, Mike; Johnston, Brenda; Forshner, Anne; Macbeth, Bryan; Einfeldt, Abbie; Cherry, Mike",
  pubDate = "2025", doi = "10.5061/dryad.g79cnp5wv", sourceURL = "https://doi.org/10.5061/dryad.g79cnp5wv",
  citation = "Whittington, J., Hebblewhite, M., Meyer, M., Johnston, B., Forshner, A., Macbeth, B., Einfeldt, A., & Cherry, M. (2025). Data from: One-stage spatial mark-resight analysis reveals an increasing grizzly bear population with declining density near roads [Dataset]. Dryad. https://doi.org/10.5061/dryad.g79cnp5wv",
  paperDOI = "10.1002/ecs2.70246",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Parks Canada remote cameras on trails, bear rub trees and mineral licks, and highway underpasses and overpasses across Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda ecosystem recorded grizzly bears from May to October, 2012-2021. Detections are summarised per camera in 14-day occasions with the days the camera ran, event counts and family-group and cub-of-the-year events. The authors combined these unmarked counts with resightings of 25 radio-collared bears and their GPS telemetry in a one-stage spatial mark-resight model of density.",
  samplingProtocol = "Remote cameras at fixed sites (trails, rub trees or mineral licks, highway crossing structures), run May to October; grizzly bear detections pooled into 14-day occasions from 1 May (the fourteenth occasion is 30 October alone), with the number of days the camera ran in each.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", effortColumn = "obs_days_active",
  responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "occasions span May to October each year; bears move widely across that season, so occupancy within a year is site use. Years are periods.",
  occasionKind = "time", taxonInclusion = "single",
  crs = "EPSG:26911",
  coordinatesCoarsened = list(value = FALSE, method = "camera positions as published (UTM zone 11N NAD83, also embedded in every site name). Not flagged (E7): grizzly bear is IUCN LC (GBIF IUCN record), the deposit states no sensitivity or threatened status and cites no red list."),
  geographicCoverage = "Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda ecosystem, Rocky Mountains, Alberta and British Columbia, Canada (UTM 11N 482334-629027 E, 5607028-5787216 N)",
  temporalCoverage = "2012-05/2021-10",
  covariateNote = "unit_type: trail, rubtree (rub tree or mineral lick), underpass, overpass (overpass or open-span underpass); unit_rubtree / unit_underpass / unit_overpass: 0/1 as deposited. unit_rsf: mean grizzly resource selection function value (30 m); unit_rsf_spring / _summer / _fall: seasonal RSF bins 0-10; unit_tri: vector ruggedness. obs_days_active: days the camera ran in the occasion (as deposited, up to 16 in a 14-day window). obs_n_detections, obs_n_events: detections and detection events (NTotal, NEvents); obs_n_family_events, obs_n_yoy_events: family-group events and events with cubs of the year; obs_yoy_detected: a cub of the year was seen (0/1). date is the occasion start, obs_end_date its end.",
  notShipped = list(
    spatial_mark_resight = "detect_marked.csv (collared-bear resightings), gps_day.csv (daily GPS of 25 collared bears), tbl_juvenile.csv, pix_xy.csv, pixel_lookup.csv, d2_cam.csv, tbl_specs.csv, tbl_area_parks.csv and the .sqlite shapefiles: inputs of the mark-resight model with telemetry, not an E9 design",
    site_summaries = "site_cam nSpecies, NDays, NEvents, NDetectDays, DetectRate14 (summaries over a span longer than the occasion table) and detect_year_cam.csv (occ_long_cam summed by site-year, asserted; its cub-of-the-year event count is lower than the occasion sum in 32 site-years)",
    model_output = "the authors' density, abundance and trend estimates"),
  notes = "Occasion 14 is a single day (30 October). In 91 rows the camera-days exceed the window length by one or two days, as deposited. The paper was not read; the design is from the deposit's metadata and data description.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/whittington_2025_banff_grizzly_occ.R")
stage_dict_row(TABLE,
  description = "Grizzly bear (Ursus arctos) detections per 14-day occasion at 625 Parks Canada camera sites in Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda, May-October 2012-2021, with camera-days, event counts, cubs of the year and site habitat.",
  url = "https://doi.org/10.5061/dryad.g79cnp5wv",
  reference = "Whittington, J., Hebblewhite, M., Meyer, M., Johnston, B., Forshner, A., Macbeth, B., Einfeldt, A., & Cherry, M. One-stage spatial mark-resight analysis reveals an increasing grizzly bear population with declining density near roads. Ecosphere. https://doi.org/10.1002/ecs2.70246",
  doi_paper = "10.1002/ecs2.70246", doi_data = "10.5061/dryad.g79cnp5wv",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Unmarked camera part of a spatial mark-resight deposit; the marked-animal and telemetry part is not shipped (not an E9 design).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (single species, camera)",
  sampling_protocol = "camera_trap", design = "Multi-season (10 years x 14 occasions of 14 days; 625 camera sites)",
  realm = "Terrestrial", country = "CAN", coordinates = "As published (UTM 11N)",
  notes = "Unmarked grizzly detections from a spatial mark-resight study; collared-bear resightings and telemetry not shipped.")
