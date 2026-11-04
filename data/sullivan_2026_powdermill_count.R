#!/usr/bin/env Rscript
# Table:  sullivan_2026_powdermill_count
# Source: GBIF sampling-event dataset 2b6825d6-ea5a-4d82-bd71-5176dac22250, doi:10.15468/23qhtm,
#         version 1.3 (published 2026-10-05), Carnegie Museum of Natural History IPT
#         (https://ipt.carnegiemnh.org/ipt/resource?r=pnr_bird_point_counts). Licence as shown on
#         GBIF and in the EML: Creative Commons Attribution (CC-BY) 4.0.
#         Citation: Sullivan K (2026). Powdermill Nature Reserve Bird Point Count Surveys.
#         Version 1.3. Carnegie Museums. Sampling event dataset https://doi.org/10.15468/23qhtm.
# Paper:  none (a long-term monitoring dataset of the Powdermill Nature Reserve "Biotic Change
#         Over Time" project, PI K. Sullivan, funded by the Richard King Mellon Foundation).
# Data:   Darwin Core Archive, event core with two extensions.
#         event.txt (2,203 rows): one row per 10-minute, 150 m radius point count; eventID,
#           eventDate (ISO with time, UTC), year/month/day, locationID (the grid point, UTM
#           easting-northing stem, 101 named points plus one event with an empty id), decimalLatitude/Longitude
#           (WGS84; empty for 5 points and the unnamed one), minimumElevationInMeters,
#           eventRemarks (free text). 2013 and 2016-2025 cover ~95-101 points, twice each
#           (62 point-years have one visit); 2014 and 2015 are partial (31 and 23 single visits).
#         occurrence.txt (49,810 rows): one row per detected individual or group, organismQuantity
#           (individuals; 1 in 83%, up to 90), occurrenceStatus (40 'Absent' rows with an empty
#           taxon and quantity 0, remark 'likely 0 presence counts?', all in events that also hold
#           Present rows), verbatimIdentification (4-letter alpha code), scientificName (CMNH's
#           nomenclature, partly pre-2011: Dendroica, Wilsonia, Carduelis), taxonRank (species,
#           8 subspecies SCJU, 22 hybrid YSFL, 90 'Piciformes sp.' UNWO), occurrenceRemarks
#           (free text: 'early protocol' for 2013-2015, 'flyover', 'inner/outer circle', sex, ...).
#           Time bins (3:20/6:40/10 min in 2013, 3/5/10 min from 2014) and inner/outer circle are
#           recorded only as remarks, not as fields, so y is the 10-minute, 150 m total.
#         humboldtecologicalinventory.txt (2,203 rows): Humboldt extension per event; protocolNames
#           PointCount, samplingEffort 10 personMinutes, targetTaxonomicScope Aves,
#           isTaxonomicScopeFullyReported TRUE, isAbundanceReported TRUE, isAbsenceReported FALSE,
#           samplingPerformedBy (observer initials, sometimes two), reportedWeather
#           ('Temp=..C; WindSpeed_Beaufort=..; CloudCover_Percent=..' with cloud cover as a 0-1
#           fraction despite the name; 24 events have Temp=NA), samplingEffortProtocol (the time-bin
#           protocol text).
#
# Mapping (standard section 3.2, N-mixture counts, multi-species -> community abundance):
#   unit = locationID (grid point), period = calendar year (1..13 for 2013..2025, __periods),
#   occasion = visit within the year ordered by eventDate (1 or 2; two points were counted twice on
#   one day in 2020 and keep occasions 1 and 2 by time), taxon = alpha code, y = sum of
#   organismQuantity over the event's Present rows for the species. The survey set is the event
#   core (surveyEvidence = sample_table): the Humboldt extension declares the taxonomic scope
#   (Aves) fully reported with abundance, so a species without a row at an event was counted
#   zero. date = eventDate, observer = samplingPerformedBy, obs_temp_c, obs_wind_beaufort,
#   obs_cloud_cover (fraction), unit_lat, unit_lon, unit_elevation_m. Period-level: calendar
#   year and the time-bin protocol in __periods.
#   Taxa: YSFL (Northern Flicker intergrade) merged into NOFL and SCJU (Slate-colored Junco) into
#   DEJU, the same species. Not shipped: UNWO (woodpecker sp., 90 rows, not a taxon); the 40
#   'Absent' placeholder rows (empty taxon, zero quantity); STCA 'Streak-crowned Antvireo' (2 rows)
#   and LUWA "Lucy's Warbler" (1 row), Neotropical/south-western species that cannot occur on a
#   Pennsylvania breeding count and are evidently code-mapping errors; the one event with an empty
#   locationID (2020-06-11, 32 rows). Flyovers are kept in y (only a free-text remark marks them).
#   Coordinates: as published by CMNH for its own reserve (120 m grid); no IUCN VU+ taxon.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sullivan_2026_powdermill_count"
zip <- download_cached("https://ipt.carnegiemnh.org/ipt/archive.do?r=pnr_bird_point_counts", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(file.exists(file.path(dwca, c("event.txt", "occurrence.txt", "humboldtecologicalinventory.txt", "eml.xml", "meta.xml"))))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("Creative Commons Attribution \\(CC-BY\\) 4.0 License", eml)))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
hu <- fread(file.path(dwca, "humboldtecologicalinventory.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 2203, nrow(oc) == 49810, nrow(hu) == 2203, !anyDuplicated(ev$eventID),
          setequal(ev$eventID, hu$id), all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID))
stopifnot(all(ev$sampleSizeValue == "150"), all(ev$sampleSizeUnit == "m_radius"), all(ev$year %in% 2013:2025),
          all(ev$month %in% 5:7), all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", ev$eventDate)))
stopifnot(all(hu$protocolNames == "PointCount"), all(hu$samplingEffortValue == "10"), all(hu$samplingEffortUnit == "personMinutes"),
          all(hu$targetTaxonomicScope == "Aves"), all(hu$isTaxonomicScopeFullyReported == "TRUE"),
          all(hu$isAbundanceReported == "TRUE"), all(hu$isAbsenceReported == "FALSE"), all(hu$samplingPerformedBy != ""))
stopifnot(all(oc$basisOfRecord == "HumanObservation"), all(oc$organismQuantityType == "individuals"),
          all(oc$occurrenceStatus %in% c("Present", "Absent")))
absent <- oc$occurrenceStatus == "Absent"
stopifnot(sum(absent) == 40, all(oc$scientificName[absent] == ""), all(oc$organismQuantity[absent] == "0"),
          all(oc$scientificName[!absent] != ""), all(as.integer(oc$organismQuantity[!absent]) >= 1))
stopifnot(sum(ev$locationID == "") == 1, uniqueN(ev$locationID[ev$locationID != ""]) == 101)

# weather fields from the Humboldt extension
wx <- "^Temp=(NA|[-0-9.]+)C; WindSpeed_Beaufort=([0-9]+); CloudCover_Percent=([0-9.]+)$"
stopifnot(all(grepl(wx, hu$reportedWeather)))
hu[, obs_temp_c := suppressWarnings(as.numeric(sub(wx, "\\1", reportedWeather)))]
hu[, obs_wind_beaufort := as.integer(sub(wx, "\\2", reportedWeather))]
hu[, obs_cloud_cover := as.numeric(sub(wx, "\\3", reportedWeather))]
stopifnot(sum(is.na(hu$obs_temp_c)) == 24, all(hu$obs_wind_beaufort %in% 0:7), all(hu$obs_cloud_cover >= 0 & hu$obs_cloud_cover <= 1))
early <- "10 minute counts of birds observed from a central point and recorded into time interval bins at 3:20 min, 6:40 min, and 10 min."
later <- "10 minute counts of birds observed from a central point and recorded into time interval bins at 3 min, 5 min, and 10 min."
stopifnot(all(hu$samplingEffortProtocol %in% c(early, later)))
hu[, time_bins := ifelse(samplingEffortProtocol == early, "3:20/6:40/10 min", "3/5/10 min")]

# surveys = events with a named point
surveys <- merge(ev[locationID != ""], hu[, .(eventID = id, observer = samplingPerformedBy, obs_temp_c, obs_wind_beaufort, obs_cloud_cover, time_bins)], by = "eventID")
stopifnot(nrow(surveys) == 2202)
surveys[, year := as.integer(year)]
stopifnot(surveys[, uniqueN(time_bins), by = year][, all(V1 == 1)])      # protocol constant within a year
stopifnot(surveys[time_bins == "3:20/6:40/10 min", unique(year)] == 2013)
setorder(surveys, locationID, year, eventDate)
surveys[, occasion := seq_len(.N), by = .(locationID, year)]
stopifnot(all(surveys$occasion %in% 1:2), sum(surveys[, .N, by = .(locationID, year)]$N == 1) == 62)
surveys[, period := year - 2012L]
# point-level covariates constant across events
pts <- unique(surveys[, .(locationID, decimalLatitude, decimalLongitude, minimumElevationInMeters)])
stopifnot(nrow(pts) == 101, all((pts$decimalLatitude == "") == (pts$decimalLongitude == "")),
          sum(pts$decimalLatitude == "") == 5, all(ev$geodeticDatum[ev$decimalLatitude != ""] == "WGS84"))
pts[, unit_lat := round(as.numeric(ifelse(decimalLatitude == "", NA, decimalLatitude)), 6)]
pts[, unit_lon := round(as.numeric(ifelse(decimalLongitude == "", NA, decimalLongitude)), 6)]
pts[, unit_elevation_m := round(as.numeric(ifelse(minimumElevationInMeters == "", NA, minimumElevationInMeters)), 1)]
stopifnot(all(pts$unit_lat > 40.13 & pts$unit_lat < 40.17, na.rm = TRUE), all(pts$unit_lon > -79.29 & pts$unit_lon < -79.24, na.rm = TRUE))
surveys <- merge(surveys, pts[, .(locationID, unit_lat, unit_lon, unit_elevation_m)], by = "locationID")

# detections: drop placeholders, non-taxa, impossible species, the unnamed point; merge intergrade / subspecies
det <- oc[!absent & eventID %in% surveys$eventID]
stopifnot(nrow(det) == 49810 - 40 - 32)
det[, code := verbatimIdentification]
stopifnot(det[, uniqueN(scientificName), by = code][, all(V1 == 1)], det[, uniqueN(code), by = scientificName][, all(V1 == 1)])
stopifnot(det[taxonRank != "species", sort(unique(code))] == c("SCJU", "UNWO", "YSFL"))
stopifnot(det[code == "STCA", unique(scientificName)] == "Dysithamnus striaticeps", det[code == "LUWA", unique(scientificName)] == "Vermivora luciae",
          det[code == "STCA", .N] == 2, det[code == "LUWA", .N] == 1, det[code == "UNWO", .N] == 90)
dropped <- det[code %in% c("UNWO", "STCA", "LUWA")]
det <- det[!code %in% c("UNWO", "STCA", "LUWA")]
det[code == "YSFL", code := "NOFL"]; det[code == "SCJU", code := "DEJU"]
stopifnot(det[code == "NOFL", unique(scientificName)] %in% c("Colaptes auratus", "Colaptes auratus auratus x cafer"))
det[, n := as.integer(organismQuantity)]
counts <- det[, .(y = sum(n)), by = .(eventID, taxon = code)]
species <- sort(unique(counts$taxon)); stopifnot(length(species) == 105)

long <- surveys[, .(eventID, unit = locationID, period, occasion, date = eventDate, observer,
                    unit_lat, unit_lon, unit_elevation_m, obs_temp_c, obs_wind_beaufort, obs_cloud_cover)]
long <- long[rep(seq_len(.N), each = length(species))][, taxon := rep(species, times = nrow(surveys))]
long <- merge(long, counts, by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(nrow(long) == nrow(surveys) * length(species), sum(long$y) == sum(det$n), !anyNA(long$y))
long[, eventID := NULL]
setorder(long, unit, taxon, period, occasion)

# taxa: the source's names (CMNH nomenclature) sent to GBIF, which resolves synonyms to accepted names
sp <- unique(det[, .(code, scientificName, vernacularName)])
sp <- sp[!(code == "NOFL" & scientificName != "Colaptes auratus") & !(code == "DEJU" & scientificName != "Junco hyemalis")]
stopifnot(nrow(sp) == 105, !anyDuplicated(sp$code))
sp <- sp[match(species, code)]
taxa <- make_taxa(species, sp$scientificName, vernacularName = sp$vernacularName)
periods <- surveys[, .(time_bins = unique(time_bins), n_points = uniqueN(locationID), n_counts = .N), by = .(period, year)]
setorder(periods, period); stopifnot(nrow(periods) == 13)
periods[, note := ifelse(year %in% 2014:2015, "partial season: a subset of points, one visit each", "")]

dataset <- list(
  title = "Breeding-season bird point counts on a 120 m grid across Powdermill Nature Reserve, Pennsylvania, 2013-2025",
  creator = "Sullivan, Kathryn (Carnegie Museum of Natural History)", pubDate = "2026-10-05", doi = "10.15468/23qhtm",
  sourceURL = "https://www.gbif.org/dataset/2b6825d6-ea5a-4d82-bd71-5176dac22250",
  citation = "Sullivan K (2026). Powdermill Nature Reserve Bird Point Count Surveys. Version 1.3. Carnegie Museums. Sampling event dataset https://doi.org/10.15468/23qhtm accessed via GBIF.org.",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
  abstract = "Ten-minute, 150 m radius point counts of all birds at the central points of a contiguous grid of 120 m blocks across Powdermill Nature Reserve (Carnegie Museum of Natural History, Rector, PA). The reserve is split into 10 sectors of 8-11 points; one sector is counted per day, twice per breeding season (late May to July). Full seasons in 2013 and 2016-2025 (95-101 points); 2014 and 2015 are partial. Published on GBIF as a Darwin Core sampling-event dataset with the Humboldt extension declaring full taxonomic scope (Aves) and abundance.",
  samplingProtocol = "Point count, 10 minutes, 150 m radius, time bins 3:20/6:40/10 min (2013) or 3/5/10 min (2014 onward; bins are remarks only, not shipped); each detected individual or group recorded with a count; y is the total individuals per species per count.",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion (two visits within a breeding season); period = calendar year", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Powdermill Nature Reserve, Westmoreland County, Pennsylvania, USA (40.13-40.17 N, 79.29-79.25 W)",
  temporalCoverage = "2013-06/2025-07", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by the Carnegie Museum of Natural History for its own reserve (120 m grid); no taxon is IUCN VU or higher; 5 points have no coordinates in the source"),
  effortColumn = NA,
  notShipped = list(
    time_bins = "3 time intervals per count exist only as free-text remarks; y is the 10-minute total",
    distance = "inner/outer circle moves are free-text remarks; the 150 m radius is the only distance field",
    UNWO = "90 'Piciformes sp.' records (unidentified woodpecker), not a taxon",
    STCA_LUWA = "Streak-crowned Antvireo (2) and Lucy's Warbler (1): Neotropical / south-western species impossible on a Pennsylvania breeding count, treated as code-mapping errors",
    absent_rows = "40 'Absent' rows with an empty taxon and quantity 0 (remark 'likely 0 presence counts?'), in events that also hold detections",
    unnamed_point = "one 2020-06-11 event with an empty locationID and no coordinates (32 records)",
    eventRemarks_occurrenceRemarks = "free text (sex, flyover, behaviour, data-entry notes)"),
  notes = "YSFL (Northern Flicker intergrade, 22 records) merged into NOFL and SCJU (Slate-colored Junco, 8) into DEJU, the same species. Flyovers are kept in y because only a remark marks them. Scientific names in __taxa are the source's (partly pre-2011 nomenclature); gbifAcceptedName gives the current name. obs_cloud_cover is a 0-1 fraction although the source field is named CloudCover_Percent. obs_temp_c is NA for 24 counts (Temp=NA in the source). 2014 and 2015 are partial seasons with one visit per point.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/sullivan_2026_powdermill_count.R")

stage_dict_row(TABLE,
  description = "Counts of 105 bird species on 2,202 ten-minute 150 m point counts at 101 grid points across Powdermill Nature Reserve, Pennsylvania (2013-2025), two visits per point per breeding season, with date-time, observer, weather, point coordinates and elevation; built from the GBIF Darwin Core event core (survey set) and per-individual occurrence records.",
  url = "https://www.gbif.org/dataset/2b6825d6-ea5a-4d82-bd71-5176dac22250",
  reference = "Sullivan K (2026). Powdermill Nature Reserve Bird Point Count Surveys. Version 1.3. Carnegie Museums. Sampling event dataset https://doi.org/10.15468/23qhtm accessed via GBIF.org.",
  doi_paper = "", doi_data = "10.15468/23qhtm",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Survey set = DwC event core; Humboldt extension declares full Aves scope with abundance. Time bins and inner/outer circle exist only as remarks, so y is the 10-minute total. UNWO, two impossible species (STCA, LUWA), 40 empty 'Absent' placeholder rows and one unnamed point dropped; YSFL->NOFL, SCJU->DEJU. Fetched as the IPT Darwin Core Archive.",
  source_via = "GBIF (CMNH IPT)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (13 years x 2 visits)", realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "Long-term monitoring grid; 2014-2015 partial seasons. Rows = 2,202 counts x 105 species.",
  status = "tagged")
