#!/usr/bin/env Rscript
# Table:  distiller_2020_cockscomb_jaguar_scr
# Source: Dryad doi:10.5061/dryad.n2z34tmv2 (CC0 1.0), version 250395 (published 2021-08-28)
#   Distiller, G., Borchers, D., Foster, R. & Harmsen, B. (2021). Camera trap survey of
#   jaguars from Cockscomb Basin Wildlife Sanctuary in Belize. Dryad.
# Paper:  Distiller, G. B., Borchers, D. L., Foster, R. J. & Harmsen, B. J. (2020). Using
#         Continuous-Time Spatial Capture-Recapture models to make inference about animal
#         activity patterns. Ecology and Evolution 10(20), 11826-11837.
#         doi:10.1002/ece3.6822 (open access, CC BY 4.0, PMC7593165).
# Data:   three files. JagsCaptures.csv (334 rows): one row per detection of an identified
#         jaguar: Sex (M/F/U), ID, Station (camera station id), Date (dd-Mon-yy), Time
#         (H:MM, minute resolution), X, Y (station coordinates, repeated). JagsTraps.csv
#         (20 rows): Station (name), Station ID, X, Y, then one 0/1 column per calendar day
#         23-Aug-13 .. 21-Feb-14 (183 days) = station operating that day, and an unnamed
#         trailing column with the row total. JagMasks.RData: habitat masks for the SCR
#         state space (not needed for the table, not shipped).
#         Paper: twenty paired camera stations (Pantheracam v3) along the trail network of
#         the eastern Cockscomb Basin, 2.0 km mean spacing, data downloaded every 2 weeks,
#         6 months Aug 2013 - Feb 2014; 287 detections of 19 males and 44 of 8 females
#         analysed; "three individuals with sex not determined" excluded (the file has 3
#         detections of 2 unsexed ids). Asserted below: 334 detections = 287 M + 44 F + 3 U,
#         29 ids, every capture on a day its station was operating, at most one detection
#         per individual x station x day, capture coordinates equal station coordinates,
#         the trailing totals equal the row sums, CAM16 never detected a jaguar.
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture, closed population):
#   unit = individual jaguar (deposit id), trap = station id (CAM*, SSP*), occasion = survey
#   day 1..183 from 2013-08-23 (one period: the paper treats the 6 months as one closed
#   survey), date = that calendar day (ISO), y = 1 if the individual was photographed at
#   that station that day, else 0 (never more than one detection per individual x station
#   x day, so no y_raw). Survey set = effort_table: the operating matrix in JagsTraps.csv;
#   a station-day is surveyed iff its cell is 1 (3,580 of 3,660 station-days). Every
#   individual carries the full rectangle of surveyed station-days (the SCR / CJS
#   convention, BATCH_LOG batch 5), 29 x 3,580 = 103,820 rows. unitKind = individual.
#   unit_sex as deposited (F / M / U); the paper's analyses drop U, a user can filter.
#   obs_capture_time = the deposit's time of the photograph (HH:MM) on detection rows, NA
#   otherwise: the continuous-time model needs the exact times and this keeps them.
#   __traps: trap, station name, x, y (UTM zone 16N, EPSG:32616; the readme gives no CRS
#   but the eastings 326-346 km and northings 1847-1858 km place the eastern Cockscomb
#   Basin at about 16.7 N, 88.6 W), n_days_operating. Jaguar is IUCN Near Threatened, not
#   a flagged category; coordinates kept as published.
#   NOT shipped: JagMasks.RData (state-space masks with spatial covariates; an analysis
#   input, not an observation); the station names are in __traps.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "distiller_2020_cockscomb_jaguar_scr"
SCRIPT <- "data/distiller_2020_cockscomb_jaguar_scr.R"
dir <- download_dryad("10.5061/dryad.n2z34tmv2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("JagMasks.RData", "JagsCaptures.csv", "JagsTraps.csv")))

cp <- fread(file.path(dir, "JagsCaptures.csv"))
tr <- fread(file.path(dir, "JagsTraps.csv"))
stopifnot(identical(names(cp), c("Sex", "ID", "Station", "Date", "Time", "X", "Y")), nrow(cp) == 334,
          identical(names(tr)[1:4], c("Station", "Station ID", "X", "Y")), nrow(tr) == 20)

# --- stations and the operating matrix (the survey set) -------------------------------
daycols <- names(tr)[grepl("^[0-9]{2}-[A-Za-z]{3}-[0-9]{2}$", names(tr))]
stopifnot(length(daycols) == 183, ncol(tr) == 4 + 183 + 1)      # trailing unnamed total column
setnames(tr, c("Station", "Station ID"), c("name", "trap"))
tot <- tr[[ncol(tr)]]
op <- melt(tr[, c("trap", daycols), with = FALSE], id.vars = "trap", variable.name = "day", value.name = "on")
op[, date := as.IDate(as.character(day), format = "%d-%b-%y")]
stopifnot(!anyNA(op$date), all(op$on %in% 0:1), uniqueN(op$date) == 183,
          identical(as.character(range(op$date)), c("2013-08-23", "2014-02-21")),
          identical(op[, sum(on), by = trap][match(tr$trap, trap), V1], as.integer(tot)))   # row totals as deposited
days <- data.table(date = sort(unique(op$date)))[, occasion := seq_len(.N)]
op <- merge(op[on == 1, .(trap, date)], days, by = "date")
stopifnot(nrow(op) == 3580, !anyDuplicated(tr$trap), all(tr$X > 326e3 & tr$X < 347e3), all(tr$Y > 1847e3 & tr$Y < 1858e3))
traps <- tr[, .(trap, name, x = as.numeric(X), y = as.numeric(Y), n_days_operating = as.integer(tot))][order(trap)]
cat(sprintf("  %d stations, %d calendar days, %d surveyed station-days\n", nrow(traps), nrow(days), nrow(op)))

# --- captures --------------------------------------------------------------------------
cp[, date := as.IDate(Date, format = "%d-%b-%y")]
stopifnot(!anyNA(cp$date), all(cp$Sex %in% c("F", "M", "U")),
          cp[, .N, by = Sex][order(Sex), N] == c(44L, 287L, 3L), uniqueN(cp$ID) == 29,
          cp[, uniqueN(ID), by = Sex][order(Sex), V1] == c(8L, 19L, 2L),
          all(cp[, uniqueN(Sex), by = ID]$V1 == 1),
          all(cp$Station %in% traps$trap), identical(setdiff(traps$trap, cp$Station), "CAM16"),
          all(grepl("^[0-9]{1,2}:[0-9]{2}$", cp$Time)))
m <- merge(cp, traps[, .(trap, x, y)], by.x = "Station", by.y = "trap")
stopifnot(nrow(m) == 334, all(m$X == m$x & m$Y == m$y))
stopifnot(nrow(cp[!op, on = .(Station = trap, date)]) == 0)          # every capture on an operating station-day
stopifnot(!anyDuplicated(cp[, .(ID, Station, date)]))               # at most one detection per individual x station x day
cp[, time := sprintf("%02d:%02d", as.integer(sub(":.*", "", Time)), as.integer(sub(".*:", "", Time)))]
cat(sprintf("  %d detections of %d jaguars (%d M, %d F, %d unsexed); %d individual-days at more than one station\n",
            nrow(cp), uniqueN(cp$ID), uniqueN(cp[Sex == "M", ID]), uniqueN(cp[Sex == "F", ID]), uniqueN(cp[Sex == "U", ID]),
            nrow(cp[, uniqueN(Station), by = .(ID, date)][V1 > 1])))

# --- the rectangle: individual x surveyed station-day -----------------------------------
inds <- unique(cp[, .(unit = ID, sex = Sex)])[order(unit)]
long <- CJ(unit = inds$unit, i = seq_len(nrow(op)))
long <- cbind(long[, .(unit)], op[long$i])
long <- merge(long, cp[, .(unit = ID, trap = Station, date, y = 1L, time)], by = c("unit", "trap", "date"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, inds, by = "unit")
stopifnot(nrow(long) == 29 * 3580, sum(long$y) == 334)
long <- long[, .(unit, taxon = "PANONC", y, trap, occasion, date = format(date), unit_sex = sex, obs_capture_time = time)]
long <- order_eco(long)

taxa <- make_taxa("PANONC", "Panthera onca", vernacularName = "Jaguar", taxon_iucnCategory = "NT")

dataset <- list(
  title = "Spatial capture-recapture of jaguars at Cockscomb Basin Wildlife Sanctuary, Belize: 29 individuals x 20 camera stations x 183 days, Aug 2013 - Feb 2014",
  creator = "Distiller, Greg; Borchers, David; Foster, Rebecca; Harmsen, Bart",
  pubDate = "2021", doi = "10.5061/dryad.n2z34tmv2", sourceURL = "https://doi.org/10.5061/dryad.n2z34tmv2",
  citation = "Distiller, G., Borchers, D., Foster, R., & Harmsen, B. (2021). Camera trap survey of jaguars from Cockscomb Basin Wildlife Sanctuary in Belize [Data set]. Dryad. https://doi.org/10.5061/dryad.n2z34tmv2",
  paperDOI = "10.1002/ece3.6822",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap detections of individually identified jaguars (Panthera onca) at 20 paired camera stations along the trail network of the eastern Cockscomb Basin Wildlife Sanctuary, Belize, over 183 consecutive days from 23 August 2013 to 21 February 2014. The deposit gives every detection with its station, date and time to the minute, and a station x day operating matrix. The table is one row per jaguar x station x operating day with y = 1 on detection; the time of the photograph is kept in obs_capture_time so the authors' continuous-time SCR model can be refitted. 29 individuals: 19 males, 8 females and 2 of undetermined sex (unit_sex; the paper's analyses used males, then both sexes, and excluded the unsexed).",
  samplingProtocol = "Twenty paired Pantheracam v3 camera stations along 65 km of trails, mean neighbour spacing 2.0 km (1.1-3.1 km), photographs downloaded every two weeks; individuals identified from coat patterns; station operating days recorded.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  surveyEvidenceNote = "JagsTraps.csv is a station x calendar-day 0/1 operating matrix (183 days); a station-day is surveyed iff its cell is 1 (3,580 of 3,660). Every individual carries all surveyed station-days, including before its first and after its last detection.",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "single period: the 6-month survey is treated as one closed population (the paper's continuous-time SCR); occasion = calendar day", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Eastern Cockscomb Basin Wildlife Sanctuary, Stann Creek District, Belize; station coordinates in __traps",
  temporalCoverage = "2013-08-23/2014-02-21",
  crs = "EPSG:32616 (WGS 84 / UTM zone 16N; inferred from the coordinate range, the readme names no CRS)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: the jaguar is IUCN Near Threatened, not a flagged category; stations on protected-area trails"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Closed population, daily occasions with per-row dates. The deposit's minute-resolution detection times are carried on the detection rows (obs_capture_time), so the continuous-time likelihood (which drops the occasion structure) can be rebuilt from the table; a conventional occasion-based SCR fit uses y as is.",
  notes = "Jaguars were photographed at more than one station on the same day 31 times (kept as separate y = 1 rows). CAM16 operated 160 days and never detected a jaguar. Station names (IE, SNOOK, MITCH, ...) are in __traps. unit_sex = U for the two unsexed individuals the paper excluded.",
  notShipped = list(JagMasks.RData = "habitat masks of the state space with spatial covariates: an analysis input, not an observation",
                    row_total_column = "the unnamed trailing column of JagsTraps.csv (days operating per station) is reproduced in __traps.n_days_operating and asserted against the row sums"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Spatial capture-recapture detections of 29 identified jaguars at 20 camera stations over 183 days in Cockscomb Basin Wildlife Sanctuary, Belize (Aug 2013 - Feb 2014), one row per jaguar x station x operating day, with the time of each photograph and station coordinates (UTM 16N) in __traps.",
  url = "https://doi.org/10.5061/dryad.n2z34tmv2",
  reference = "Distiller, G. B., Borchers, D. L., Foster, R. J., & Harmsen, B. J. (2020). Using Continuous-Time Spatial Capture-Recapture models to make inference about animal activity patterns. Ecology and Evolution, 10(20), 11826-11837.",
  doi_paper = "10.1002/ece3.6822", doi_data = "10.5061/dryad.n2z34tmv2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed-population SCR (E9 experimental): trap key + __traps. Survey set = deposited station x day operating matrix. Detection times kept in obs_capture_time for the continuous-time model. Unsexed individuals included with unit_sex = U.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, continuous-time capable)",
  sampling_protocol = "camera_trap", design = "Single-season (183 daily occasions, 20 camera stations)", realm = "Terrestrial",
  country = "BLZ", coordinates = "As published (station coordinates in __traps, UTM 16N)",
  notes = "Experimental (E9): trap key + __traps. Individuals as unit, full rectangle of surveyed station-days. Photograph times on detection rows.")
