#!/usr/bin/env Rscript
# Table:  whittington_2025_banff_grizzly_smr
# Status: HELD (batch 46, #10). write_table() refuses it: three collared bears were never resighted while collared,
#   and E4.4 / eco-validate never_detected block an individual with every y = 0, whereas the spatial mark-resight
#   ruling (2026-11-06) gives every marked individual a row at every trap x occasion it could have been seen. Dropping
#   them would bias the marked-animal count; waiting for Ben (#141). Not run, not shipped.
# Source: Dryad, doi:10.5061/dryad.g79cnp5wv, version 352578 (version 5, published 2025-03-17), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON). Data collected by Parks Canada and the
#         University of Montana. The same deposit as whittington_2025_banff_grizzly_occ (the camera occupancy table).
#   Whittington, J., Hebblewhite, M., Meyer, M., Johnston, B., Forshner, A., Macbeth, B., Einfeldt, A. & Cherry, M.
#   Data from: One-stage spatial mark-resight analysis reveals an increasing grizzly bear population with declining
#   density near roads [Dataset]. Dryad.
# Paper:  Whittington, J. et al. One-stage spatial mark-resight analysis reveals an increasing grizzly bear population
#         with declining density near roads. Ecosphere. doi:10.1002/ecs2.70246. Not read; design from the deposit.
# Data:   occ_long_cam.csv: 31,180 rows, one per camera site x year x 14-day occasion in which the camera ran, with
#           NDays (days run), NTotal (grizzly detections) and NEvents (grizzly detection events) over all bears.
#         detect_marked.csv: 76,441 rows, one per radio-collared bear x camera site x occasion at which the bear was
#           collared (identifiable on camera) and the camera ran: Detect (0/1) and NTotal ("detection events per
#           occasion", 0-5; Detect = NTotal > 0, asserted). For each bear x year x occasion its rows are exactly the
#           sites operating in that occasion (asserted). 24 bears, 2012-2021.
#         site_cam.csv: 625 sites, x, y (UTM zone 11 NAD83), site name (with the UTM pair), type.
#         gps_day.csv: daily GPS positions of 25 collared bears (sex per bear); tbl_juvenile.csv; state-space pixels,
#           distances and shapefiles (model inputs).
# Mapping (spatial mark-resight, ruling 2026-11-06, E9; responseType count, unitKind individual): unit = collared
#   bear ('B' + the source's animal name) or the reserved unit 'unmarked'; taxon URSARC; trap = camera site
#   ('C001'..'C625', as in the occupancy table); period = year (1 = 2012 .. 10 = 2021); occasion = the 14-day occasion
#   (1-14); date = the occasion's start. A collared bear has a row at every site x occasion in detect_marked (the
#   occasions it was collared, at every operating camera), y = its detection events (NTotal). 'unmarked' has a row at
#   every operating site x occasion (every row of occ_long_cam), y = NEvents minus the collared bears' events there
#   (never negative, asserted: occ_long_cam's events include the collared bears, whose events never exceed them).
#   The source records no sightings of marked-but-unidentified bears, so there is no 'marked_unidentified' unit.
#   obs_days_active = NDays (effortColumn). surveyEvidence = effort_table. __units: reserved flag, sex (gps_day),
#   collared periods and occasions, and the bear's GPS-day count; marks are radio collars (with ear tags) applied
#   by Parks Canada; a bear is marked in the occasions of detect_marked and unmarked (part of 'unmarked') otherwise.
#   __traps: x, y (EPSG:26911) as published, site type.
#   Coordinates: as published; grizzly bear is IUCN LC and the deposit states no sensitivity (see the occupancy
#   table's script for the E7 check).
# Not shipped: gps_day.csv (telemetry, out of scope E9; its daily positions would also reveal bear locations), and
#   tbl_juvenile.csv, pixels, distances and shapefiles (model inputs); the authors' estimates (model output).
#   occ_long_cam's NTotal (detections, as opposed to events) is in whittington_2025_banff_grizzly_occ.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "whittington_2025_banff_grizzly_smr"
# the deposit is cached under the occupancy table's name (one download for both tables)
dir <- download_dryad("10.5061/dryad.g79cnp5wv", "whittington_2025_banff_grizzly_occ")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "352578"))

o <- fread(file.path(dir, "occ_long_cam.csv"))
m <- fread(file.path(dir, "detect_marked.csv"))
s <- fread(file.path(dir, "site_cam.csv"))
g <- fread(file.path(dir, "gps_day.csv"))
stopifnot(identical(names(m), c("site.id", "location", "start", "end", "occasion", "NDays", "Year", "animal_name", "Detect", "NTotal")),
          nrow(o) == 31180L, nrow(m) == 76441L, uniqueN(m$animal_name) == 24L, all(m$Detect == as.integer(m$NTotal > 0L)),
          !anyDuplicated(m[, .(animal_name, site.id, Year, occasion)]), !anyDuplicated(o[, .(site.id, Year, occasion)]),
          all(m$animal_name %in% g$animal_name), g[, uniqueN(sex), by = animal_name][, all(V1 == 1L)])
# a collared bear's rows in an occasion are exactly the cameras operating in it
op <- o[, .(sites = list(sort(site.id))), by = .(Year, occasion)]
mk <- m[, .(sites = list(sort(site.id))), by = .(animal_name, Year, occasion)]
mk <- merge(mk, op, by = c("Year", "occasion"))
stopifnot(nrow(mk) == uniqueN(m[, .(animal_name, Year, occasion)]), all(mapply(identical, mk$sites.x, mk$sites.y)))
# the rows' days and dates agree with the occasion table
z <- merge(m, o[, .(site.id, Year, occasion, NDays_o = NDays, start_o = start, NEvents)], by = c("site.id", "Year", "occasion"))
stopifnot(nrow(z) == nrow(m), all(z$NDays == z$NDays_o), all(z$start == z$start_o))
me <- m[, .(E = sum(NTotal)), by = .(site.id, Year, occasion)]
uo <- merge(o, me, by = c("site.id", "Year", "occasion"), all.x = TRUE)
uo[is.na(E), E := 0L]
uo[, y := NEvents - E]
stopifnot(all(uo$y >= 0L))

mlong <- m[, .(unit = sprintf("B%03d", animal_name), trap = sprintf("C%03d", site.id), period = Year - 2011L,
               occasion = as.integer(occasion), date = format(as.IDate(start)), y = as.integer(NTotal), obs_days_active = as.integer(NDays))]
ulong <- uo[, .(unit = "unmarked", trap = sprintf("C%03d", site.id), period = Year - 2011L,
                occasion = as.integer(occasion), date = format(as.IDate(start)), y = as.integer(y), obs_days_active = as.integer(NDays))]
long <- rbind(mlong, ulong)
long[, taxon := "URSARC"]
long <- order_eco(long[, .(unit, taxon, trap, period, occasion, date, y, obs_days_active)])
stopifnot(nrow(long) == 76441L + 31180L, sum(long$y) == sum(o$NEvents))
never <- long[unit != "unmarked", .(n = sum(y)), by = unit][n == 0L, unit]
cat(sprintf("  %s rows: %d collared bears (%d events; never resighted: %s), unmarked %d events at %d site-occasions\n",
            format(nrow(long), big.mark = ","), uniqueN(mlong$unit), sum(mlong$y), paste(never, collapse = ", "), sum(ulong$y), nrow(ulong)))

sex <- unique(g[, .(unit = sprintf("B%03d", animal_name), sex)])
gd <- g[, .(n_gps_days = .N), by = .(unit = sprintf("B%03d", animal_name))]
cov <- m[, .(occ = sprintf("%d:%d", Year, occasion)), by = .(unit = sprintf("B%03d", animal_name), Year, occasion)][
  , .(unit_marked_years = paste(sort(unique(Year)), collapse = ";"), unit_marked_occasions = .N), by = unit]
units <- merge(cov, sex, by = "unit")
units <- merge(units, gd, by = "unit")
units <- rbind(units[, .(unit, unit_reserved = 0L, unit_sex = sex, unit_mark = "radio collar (collared bears are identifiable on camera)",
                         unit_marked_years, unit_marked_occasions, unit_n_gps_days = n_gps_days)],
               data.table(unit = "unmarked", unit_reserved = 1L, unit_sex = NA_character_,
                          unit_mark = "reserved: detection events of bears not collared at the time", unit_marked_years = NA_character_,
                          unit_marked_occasions = NA_integer_, unit_n_gps_days = NA_integer_))
traps <- s[, .(trap = sprintf("C%03d", site.id), x, y, location, type = Type)]
taxa <- make_taxa("URSARC", "Ursus arctos", vernacularName = "Grizzly bear")
stopifnot(identical(iucn_category(taxa$taxonID, taxa$scientificName), "LC"))
taxa[, taxon_iucnCategory := "LC"]
periods <- data.table(period = 1:10, year = 2012:2021, n_collared = as.integer(mlong[, uniqueN(unit), keyby = period][J(1:10)]$V1))
periods[is.na(n_collared), n_collared := 0L]

dataset <- list(
  title = "Spatial mark-resight of grizzly bears: detection events of 24 radio-collared bears and of uncollared bears at 625 remote cameras in Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda, 2012-2021",
  creator = "Whittington, Jesse; Hebblewhite, Mark; Meyer, Mike; Johnston, Brenda; Forshner, Anne; Macbeth, Bryan; Einfeldt, Abbie; Cherry, Mike",
  pubDate = "2025", doi = "10.5061/dryad.g79cnp5wv", sourceURL = "https://doi.org/10.5061/dryad.g79cnp5wv",
  citation = "Whittington, J., Hebblewhite, M., Meyer, M., Johnston, B., Forshner, A., Macbeth, B., Einfeldt, A., & Cherry, M. (2025). Data from: One-stage spatial mark-resight analysis reveals an increasing grizzly bear population with declining density near roads [Dataset]. Dryad. https://doi.org/10.5061/dryad.g79cnp5wv",
  paperDOI = "10.1002/ecs2.70246",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Parks Canada remote cameras across Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda recorded grizzly bears from May to October, 2012-2021, in 14-day occasions; 24 bears carried radio collars and were identifiable on camera while collared. The authors fitted one-stage generalized spatial mark-resight models with telemetry. One row per collared bear x camera x occasion while it was collared, and per camera x occasion for the detection events of uncollared bears.",
  samplingProtocol = "Remote cameras at fixed sites (trails, rub trees or mineral licks, highway crossing structures), run May to October; detection events pooled into 14-day occasions from 1 May (the fourteenth is 30 October alone). Collared bears identified on camera; other bears counted as unmarked.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", effortColumn = "obs_days_active",
  responseType = "count", unitKind = "individual",
  closure = "open", closureNote = "occasions span May to October; the authors' model treats each year as a primary period with bears' activity centres fixed within a year. Years are periods.",
  occasionKind = "time", taxonInclusion = "single", crs = "EPSG:26911",
  coordinatesCoarsened = list(value = FALSE, method = "camera positions as published (UTM zone 11N NAD83). Not flagged (E7): grizzly bear is IUCN LC (GBIF IUCN record), and the deposit states no sensitivity and cites no red list."),
  geographicCoverage = "Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda ecosystem, Rocky Mountains, Alberta and British Columbia, Canada",
  temporalCoverage = "2012-05/2021-10",
  covariateNote = "obs_days_active: days the camera ran in the occasion. __units: unit_reserved (1 for 'unmarked'), unit_sex, unit_mark, unit_marked_years and unit_marked_occasions (when the bear was collared and so identifiable), unit_n_gps_days (days with a GPS position in the deposit). __traps: x, y (EPSG:26911), location (site name as published), type.",
  designNote = "Spatial mark-resight (E9 ruling 2026-11-06). 'unmarked' y = the camera-occasion's detection events (occ_long_cam NEvents, all bears) minus the collared bears' events there; the source records no marked-but-unidentified sightings.",
  notes = sprintf("Collared bears never resighted on camera while collared keep their rows (all y = 0): %s. Bear 178 has GPS data but no camera rows in the deposit and is not a unit.", paste(never, collapse = ", ")),
  notShipped = list(telemetry = "gps_day.csv daily GPS positions of 25 collared bears (telemetry: out of scope, E9)",
                    juveniles = "tbl_juvenile.csv parturition and cub fates",
                    model_inputs = "state-space pixels, distances, specs and shapefiles",
                    model_output = "the authors' density, abundance and trend estimates"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, traps = traps,
                  script = "data/whittington_2025_banff_grizzly_smr.R")
stage_dict_row(TABLE,
  description = "Spatial mark-resight of grizzly bears at 625 Parks Canada remote cameras in Banff, Kootenay and Yoho National Parks and the Ya Ha Tinda, 2012-2021: detection events per 14-day occasion of 24 radio-collared bears while collared, and of uncollared bears.",
  url = "https://doi.org/10.5061/dryad.g79cnp5wv",
  reference = "Whittington, J., Hebblewhite, M., Meyer, M., Johnston, B., Forshner, A., Macbeth, B., Einfeldt, A., & Cherry, M. One-stage spatial mark-resight analysis reveals an increasing grizzly bear population with declining density near roads. Ecosphere. https://doi.org/10.1002/ecs2.70246",
  doi_paper = "10.1002/ecs2.70246", doi_data = "10.5061/dryad.g79cnp5wv",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Spatial mark-resight (ruling 2026-11-06): collared bears plus reserved unit 'unmarked'; telemetry not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial mark-resight (camera traps)",
  sampling_protocol = "camera_trap", design = "Multi-season (10 years x 14 occasions of 14 days; 625 camera sites)",
  realm = "Terrestrial", country = "CAN", coordinates = "As published (UTM 11N)",
  notes = "Experimental (E9): spatial mark-resight, radio-collared marks, trap key + __traps + __units.")
