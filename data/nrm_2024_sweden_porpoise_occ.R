#!/usr/bin/env Rscript
# Table:  nrm_2024_sweden_porpoise_occ
# Source: GBIF sampling-event dataset fbe080fc-e0c3-4b2c-a6d0-2c017503a3d3, doi:10.15468/b58jkn, version 1.1 (2024),
#         Swedish GBIF IPT resource shark-harbour-porpoise-nat (SHARK, the Swedish Ocean Archive at SMHI). Licence as
#         shown on GBIF and in the EML: CC0 1.0.
#         Citation: Swedish Museum of Natural History, Swedish Agency for Marine and Water Management and Swedish
#         Meteorological and Hydrological Institute (2024). SHARK - National marine environmental monitoring of Harbour
#         porpoise in Sweden. Version 1.1. Sampling event dataset. https://doi.org/10.15468/b58jkn
# Paper:  none; method in the national monitoring manual 'Stationär akustisk övervakning av tumlare' (Swedish Agency for
#         Marine and Water Management), named on every sample.
# Data:   Darwin Core Archive, event core with occurrence and extended measurement-or-fact extensions.
#   event.txt (40,900 rows): DATASET_EVENT-1; 34 'EVENT-n' rows, one per station (locality: the station code, 34
#     stations in the Baltic Sea, Kattegat and Skagerrak; coordinates EPSG:4619 = SWEREF99 geographic; deployment start
#     and end dates in the eMoF); 40,865 'SAMPLE-n' rows, one per station-day (2015-10-01 to 2023-10-02), fieldNumber
#     naming the logger file, eventRemarks 'Irregular C-POD setting (8 cyc)' (13,748) or 'Partly recorded with
#     irregular C-POD setting (8 cyc)' (33) or empty, depth.
#   occurrence.txt (40,865 rows): one Phocoena phocoena record per sample, occurrenceStatus present (21,222) or absent.
#   extendedmeasurementorfact.txt: per sample 'Detection positive minutes per day' (40,687 samples; the C-POD's
#     KERNO-classified narrow-band high-frequency click trains), 'Detection positive days per month' (on the first day
#     of a month), sampler type CPOD, method documentation; per station water depth and deployment dates.
#   178 samples carry no detection-positive minutes, only 'detection positive days per month': all dated the first of
#     a month, 126 of them naming two merged logger files around a logger exchange and sharing their station-date with
#     a daily sample; they are monthly summaries, not station-days.
# Mapping (dynamic occupancy / detection history from a passive acoustic detector; responseType detection): unit =
#   station, taxon PHOPHO, period = calendar year 2015..2023 as 1..9, occasion = day of year (the station-day),
#   date = eventDate, y = 1 if the day had at least one detection-positive minute, else 0, y_raw = detection-positive
#   minutes that day (0-1440), asserted equal to the occurrenceStatus. obs_irregular_setting = 1 where the source marks
#   the day as recorded (wholly or partly) with the irregular C-POD setting, else 0. surveyEvidence = sample_table:
#   every station-day with a detection-positive-minutes value is a recording day. unit_ coordinates = the position the
#   station's daily samples most often give; obs_decimalLatitude/Longitude = the day's logger position (redeployments move up to ~1 km);
#   obs_depth_m.
#   Coordinates: the station positions as published. Not flagged under E7 (re-checked in batch 46, #10, after the
#   ruling on the publisher withdrew the agency exception): (b) the taxon's IUCN category, read from its GBIF key, is LC
#   (asserted); the Baltic Proper harbour porpoise is assessed CR by IUCN as a subpopulation, which is not a taxon with a
#   key of its own, so (b) as written does not reach it; (a) the deposit (EML, event, occurrence and eMoF files) says
#   nothing about sensitive locations or a threatened status; (c) it cites no national red list.
# Not shipped: the 178 monthly-summary samples and the 'detection positive days per month' values (aggregates of the
#   daily rows); laboratory and programme fields (constant).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "nrm_2024_sweden_porpoise_occ"
zip <- download_cached("https://www.gbif.se/ipt/archive.do?r=shark-harbour-porpoise-nat", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("fbe080fc-e0c3-4b2c-a6d0-2c017503a3d3/v1.1", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "extendedmeasurementorfact.txt"), quote = "", colClasses = "character")
s <- ev[grepl("^SAMPLE-", eventID)]
st <- ev[grepl("^EVENT-", eventID)]
stopifnot(nrow(ev) == 40900L, nrow(s) == 40865L, nrow(oc) == 40865L, nrow(st) == 34L, uniqueN(st$locality) == 34L,
          all(s$parentEventID %in% st$eventID), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", s$eventDate)),
          all(oc$scientificName == "Phocoena phocoena"), setequal(oc$eventID, s$eventID), !anyDuplicated(oc$eventID),
          all(oc$occurrenceStatus %in% c("present", "absent")), all(s$geodeticDatum == "EPSG:4619"),
          all(s$locality == st$locality[match(s$parentEventID, st$eventID)]),
          setequal(s$eventRemarks, c("", "Irregular C-POD setting (8 cyc)", "Partly recorded with irregular C-POD setting (8 cyc)")))
dpm <- mf[measurementType == "Detection positive minutes per day", .(eventID = id, dpm = as.integer(measurementValue))]
stopifnot(nrow(dpm) == 40687L, !anyDuplicated(dpm$eventID), all(dpm$dpm >= 0L & dpm$dpm <= 1440L),
          all(mf[measurementType == "Sampler type", measurementValue] == "CPOD (C-POD)"))
mon <- s[!eventID %in% dpm$eventID]
stopifnot(nrow(mon) == 178L, all(substr(mon$eventDate, 9, 10) == "01"), sum(grepl("+", mon$fieldNumber, fixed = TRUE)) == 126L,
          all(mon$eventID %in% mf[measurementType == "Detection positive days per month", id]))
s <- merge(s, dpm, by = "eventID")
s <- merge(s, oc[, .(eventID, occurrenceStatus)], by = "eventID")
stopifnot(nrow(s) == 40687L, all((s$dpm > 0L) == (s$occurrenceStatus == "present")))
# two loggers recording the same station on the same day (overlapping deployments): keep the earlier-deployed
# logger's day (its file name sorts first: '<station> <yyyy mm dd> POD...'), drop the other (notShipped)
setorder(s, locality, eventDate, fieldNumber)
ovl <- s[duplicated(s[, .(locality, eventDate)])]
cat(sprintf("  overlapping logger-days dropped: %d (%s)\n", nrow(ovl), paste(unique(ovl$locality), collapse = ", ")))
s <- s[!eventID %in% ovl$eventID]
stopifnot(!anyDuplicated(s[, .(locality, eventDate)]))
s[, year := as.integer(substr(eventDate, 1, 4))]
years <- 2015:2023
stopifnot(all(s$year %in% years))
s[, occasion := as.integer(format(as.Date(eventDate), "%j"))]
# the station position: the position the station's daily samples most often give (the station event rows give
# rounded positions for some stations, e.g. NMN1 at longitude 17)
pos <- s[, .N, by = .(locality, decimalLatitude, decimalLongitude)][order(locality, -N)][!duplicated(locality)]
s <- merge(s, pos[, .(locality, st_lat = as.numeric(decimalLatitude), st_lon = as.numeric(decimalLongitude))], by = "locality")
far <- s[abs(as.numeric(decimalLatitude) - st_lat) > 0.02 | abs(as.numeric(decimalLongitude) - st_lon) > 0.02]
# two stations have days whose logger position is far from the station's usual one, probably mistyped longitudes:
# NMN1 at 17.2026 E (178 days, about 4.5 km west) and 1031 at 16.2179 E (172 days, about 19 km west); kept as published in obs_
stopifnot(setequal(far$locality, c("NMN1", "1031")), nrow(far) == 350L, sum(far$locality == "NMN1") == 178L)
long <- s[, .(unit = locality, taxon = "PHOPHO", y = as.integer(dpm > 0L), y_raw = dpm, period = match(year, years), occasion,
              date = eventDate, unit_decimalLatitude = st_lat, unit_decimalLongitude = st_lon,
              obs_decimalLatitude = as.numeric(decimalLatitude), obs_decimalLongitude = as.numeric(decimalLongitude),
              obs_irregular_setting = as.integer(eventRemarks != ""), obs_depth_m = suppressWarnings(as.numeric(minimumDepthInMeters)))]
cat(sprintf("  %d station-days at %d stations, %d with detections; days per station-year: %s\n", nrow(long), uniqueN(long$unit), sum(long$y),
            paste(range(long[, .N, by = .(unit, period)]$N), collapse = "-")))

taxa <- make_taxa("PHOPHO", "Phocoena phocoena", vernacularName = "Harbour Porpoise")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
stopifnot(taxa$taxon_iucnCategory == "LC")
periods <- data.table(period = seq_along(years), year = years, n_stations = sapply(years, function(y) uniqueN(s[year == y]$locality)))
dataset <- list(
  title = sprintf("Swedish national monitoring of harbour porpoise: daily C-POD detections at %d stations, 2015-2023", uniqueN(long$unit)),
  creator = "Swedish Museum of Natural History; Swedish Agency for Marine and Water Management; Swedish Meteorological and Hydrological Institute (SHARK)",
  pubDate = "2024", doi = "10.15468/b58jkn", sourceURL = "https://doi.org/10.15468/b58jkn",
  citation = "Swedish Museum of Natural History, Swedish Agency for Marine and Water Management and Swedish Meteorological and Hydrological Institute (2024). SHARK - National marine environmental monitoring of Harbour porpoise in Sweden. Version 1.1. Sampling event dataset. https://doi.org/10.15468/b58jkn",
  intellectualRights = list(spdx = "CC0-1.0", url = "http://creativecommons.org/publicdomain/zero/1.0/legalcode"),
  abstract = "Swedish national marine monitoring of harbour porpoise, financed by the Swedish Agency for Marine and Water Management and run by the Swedish Museum of Natural History: C-POD click detectors moored at fixed stations in the Baltic Sea, Kattegat and Skagerrak log porpoise echolocation continuously and are exchanged periodically. One row per station-day: whether the day had any detection-positive minute (y), with the minutes in y_raw.",
  samplingProtocol = "Static passive acoustic monitoring with C-POD click detectors moored at fixed stations, logging continuously; click trains classified by the KERNO classifier (narrow-band high-frequency) and summarised as detection-positive minutes per day (national monitoring manual 'Stationär akustisk övervakning av tumlare').",
  samplingProtocolCode = "acoustic", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "occasion = day of year within a calendar year (period); porpoises move and use of a station changes seasonally, so the days of a year are not closed; dynamic or time-series models fit the design",
  occasionKind = "time", taxonInclusion = "single", crs = "EPSG:4619 (SWEREF99 geographic, as published; within a metre of WGS 84)",
  geographicCoverage = "Swedish waters of the Baltic Sea, Kattegat and Skagerrak",
  temporalCoverage = "2015-10/2023-10",
  coordinatesCoarsened = list(value = FALSE, method = "Station positions as published. Not flagged (E7): the species is IUCN LC (GBIF IUCN record); the Baltic Proper subpopulation's CR assessment is for a subpopulation, not a taxon, so criterion (b) does not apply; the source states no sensitivity and cites no red list."),
  covariateNote = "y_raw = detection-positive minutes in the day (0-1440); obs_irregular_setting = 1 where the source marks the day as recorded wholly or partly with the irregular C-POD setting (8 cycles), else 0; obs_decimalLatitude / obs_decimalLongitude = the logger's position on the day (deployments move by up to about 1 km within a station; 350 days at NMN1 and 1031 give positions 4.5-19 km off, probably mistyped longitudes, kept as published; unit_ coordinates are the station's most frequent position); obs_depth_m = water depth at the station as given on the sample, NA where not given.",
  notShipped = list(`overlapping logger-days` = sprintf("%d station-days recorded by a second, overlapping logger (%s); the earlier-deployed logger's day is kept", nrow(ovl), paste(unique(ovl$locality), collapse = ", ")),
                    `monthly summaries` = "178 first-of-month samples that merge two logger files around an exchange and carry only 'detection positive days per month' (aggregates of the daily rows)",
                    `programme fields` = "laboratory, accreditation, monitoring programme and purpose (constant)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Daily detection / non-detection of harbour porpoise (Phocoena phocoena) from C-POD click detectors at %d stations of the Swedish national marine monitoring programme, Baltic Sea to Skagerrak, 2015-2023, with detection-positive minutes per day.", uniqueN(long$unit)),
  url = "https://doi.org/10.15468/b58jkn",
  reference = "Swedish Museum of Natural History, Swedish Agency for Marine and Water Management and SMHI (2024). SHARK - National marine environmental monitoring of Harbour porpoise in Sweden. Version 1.1. https://doi.org/10.15468/b58jkn",
  doi_paper = "", doi_data = "10.15468/b58jkn", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Swedish GBIF IPT DwC-A (shark-harbour-porpoise-nat v1.1). Station-days with detection-positive minutes; monthly summary samples dropped.",
  source_via = "GBIF (Swedish GBIF IPT, SHARK / SMHI)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Occupancy (dynamic)",
  sampling_protocol = "acoustic", design = sprintf("Multi-season (%d years x daily occasions)", length(years)), realm = "Marine",
  country = "SWE", coordinates = "As published", notes = "Agency passive acoustic monitoring (C-POD); continuous daily detection histories.")
