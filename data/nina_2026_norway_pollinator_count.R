#!/usr/bin/env Rscript
# Tables: nina_2026_norway_pollinator_count (all taxa; coordinates coarsened) and
#         nina_2026_norway_pollinator_exact_count (E7.3 sibling without Bombus alpinus, coordinates
#         as published)
# Source: GBIF sampling-event dataset aea17af8-5578-4b04-b5d3-7adf0c5a1e60, doi:10.15468/mpsa4g,
#         version 1.12 (2026-05-04), NINA IPT resource butterflies_bumblebees2020. Licence as shown
#         on GBIF and in the EML: CC BY 4.0 ("This work is licensed under a Creative Commons
#         Attribution (CC-BY) 4.0 License"). Owner institution: Miljødirektoratet (Norwegian
#         Environment Agency); surveys by NINA with citizen-science volunteers (Sabima).
#         Citation: Gohli J, Åström J (2026). Bumblebees and butterflies in Norway. Version 1.12.
#         Norwegian Institute for Nature Research. Samplingevent dataset. https://doi.org/10.15468/mpsa4g
# Paper:  none; the protocol is in the EML (methods, sampling) and the export recipe
#         github.com/jenast/NBBM_data_export (cited by the EML).
# Data:   Darwin Core Archive, event core + occurrence extension (no measurement extension).
#   event.txt (52,911 rows), two levels:
#     2,548 square visits (sampleSizeValue 1000 m, eventRemarks "Fixed 1.5x1.5km square with 20 fixed
#       transect walks of 50m each.", locationRemarks "... known as square: <code>", 92 squares of
#       the LUCAS-based 18 km grid, footprint polygon, no point coordinates, no dynamicProperties);
#     50,363 transect-section walks (sampleSizeValue 50 m, parentEventID = the square visit, same
#       eventDate as the parent, locationRemarks "... known as transect: <square>-<n>", locationID
#       (2,651; one section code maps to 1-3 locationIDs where a section was moved), point
#       coordinates (WGS84, coordinateUncertaintyInMeters 5) and footprint line, eventTime
#       start/end, dynamicProperties JSON: observerID (73 pseudonymous UUIDs), habitatType
#       (forest / grassland / wetland, constant per locationID), cloudCover%, temperatureCelsius,
#       flowerCover0123 (0-3 in half steps)). 2,474 visits have all 20 section walks; 74 have fewer.
#     samplingProtocol "Sweep netting" on every event; 2009-2025.
#   occurrence.txt (45,859 rows): presence records only (occurrenceStatus present, lifeStage Adult,
#     no sex), individualCount, scientificName (94 names: species, slash aggregates such as
#     "Plebejus argus/idas", "Bombus sensu stricto", and "Bombus spp.", "Pieridae spp.",
#     "Lepidoptera spp."), on section walks; 565 event x name pairs have more than one record
#     (summed); 25 records on 16 eventIDs absent from event.txt (all modified 2025-09-29).
#   EML: "Earlier versions of this dataset contained specific absences of all unobserved taxa within
#     the scope of the study. These are now removed, but can be inferred by the user by adding
#     zeroes for all butterfly species (Papilionoidea) and bumblebee species (Bombus)." Methods:
#     each section is walked three times a summer (late spring, mid-summer, late summer) between
#     10:00 and 17:00 in suitable weather; butterflies and bumblebees 2.5 m to each side and 5 m
#     ahead are recorded to species and counted, caught with a sweep net when needed; "All species
#     of the genus Bombus found are registered ... and all species of the butterfly families
#     Papilionidae, Hesperiidae, Pieridae, Lycaenidae, Nymphalidae, and Zygaenidae found are
#     registered."
#
# Mapping (community counts, unitKind site; one deposit x protocol x response type, ruling #31:
#   bumblebees and butterflies are recorded on the same section walk by the same observer under one
#   counting rule, so they are one table):
#   unit = transect section (locationID), coded by the source's section code "<square>-<n>", with a
#   suffix a/b/c (by first walk) where a moved section has several locationIDs; cluster_id = square
#   code; period = calendar year 2009..2025 as 1..17 (__periods); obs_visit = the square visit's rank
#   within the square-year (by date, then the visit's first start time); occasion = the visit's slot
#   in the square-year, equal to obs_visit except that six visits (2024-2025) walked one section
#   twice as two events: both walks are surveys (E3), so such a visit takes two slots and the
#   repeat walk is the second; shared by the sections of one visit; date = eventDate; observer = observerID recoded O01..O73 (sorted UUIDs; NA for 40
#   walks without one); y = individuals counted (sum of individualCount over the event's records of
#   the taxon; 0 where none). taxon = every name in the occurrence file, each its own taxon at the
#   rank recorded (E6), including Zygaena exulans / Z. filipendulae: Zygaenidae are in the EML's list
#   of registered families although the absence note names Papilionoidea and Bombus only.
#   Survey evidence = sample_table: every section-walk event is a survey (empty walks are events
#   with no occurrences), and every taxon gets a row at every walk (the EML's zero-inference rule;
#   the registered taxa are the same everywhere, so no __survey_taxa). taxonInclusion = recorded.
#   closure = open (three visits spanning the flight season, chosen to cover different species'
#   phenology); occasionKind = time.
#   obs_: obs_temperature_c, obs_cloud_cover_pct, obs_flower_cover (0-3), obs_time_start /
#   obs_time_end (HH:MM, NA for 100 walks without a time), obs_visit. Unit-level facts go in __units
#   (as barea_2021_sierranevada_butterfly_count; repeating them on 4.7M rows would double the file):
#   unit_habitat, unit_county (stateProvince), coordinates.
#   Coordinates (E7): Bombus alpinus is IUCN VU (global, via GBIF; native in Norway) and the section
#   coordinates are 5 m, so the whole table ships with coordinates coarsened to 0.1-degree cell
#   centres (coarsen_coords()) and without locality / municipality names (E7.4; unit and cluster
#   codes are grid codes, not place names); nina_2026_norway_pollinator_exact_count omits
#   B. alpinus and keeps the coordinates as published, with municipality, locality and the
#   section footprint in its __units table. The data owner is a government agency, but the
#   squares are not on public land by design, so E7's agency exception is not used. Other taxa:
#   no CR / EN / VU category (four Bombus DD); the source cites no national red list.
#   Not shipped: the 2,548 square-visit events (containers of the section walks; no own records);
#   25 records on eventIDs missing from event.txt (no survey to attach them to); footprintWKT in the
#   coarsened table; observer UUIDs (recoded).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "nina_2026_norway_pollinator_count"
TABLE_X <- "nina_2026_norway_pollinator_exact_count"
SCRIPT <- "data/nina_2026_norway_pollinator_count.R"
zip <- download_cached("https://ipt.nina.no/archive.do?r=butterflies_bumblebees2020&v=1.12", TABLE, "dwca_v1.12.zip")
dwca <- file.path(dirname(zip), "dwca_v1.12")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE, encoding = "UTF-8")
stopifnot(any(grepl("aea17af8-5578-4b04-b5d3-7adf0c5a1e60/v1.12", eml, fixed = TRUE)),
          any(grepl("Creative Commons Attribution (CC-BY) 4.0 License", eml, fixed = TRUE)),
          any(grepl("adding zeroes for all butterfly species (Papilionoidea) and bumblebee species (Bombus)", eml, fixed = TRUE)),
          any(grepl("Papilionidae, Hesperiidae, Pieridae, Lycaenidae, Nymhalidae, and Zygaenidae found are registered", eml, fixed = TRUE)))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character", encoding = "UTF-8")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character", encoding = "UTF-8")

# facts about the source
stopifnot(nrow(ev) == 52911L, nrow(oc) == 45859L, !anyDuplicated(ev$eventID), all(ev$type == "Event"),
          all(ev$samplingProtocol == "Sweep netting"), all(ev$sampleSizeValue %in% c("50", "1000")),
          all(ev$sampleSizeUnit == "metre"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          all(oc$occurrenceStatus == "present"), all(oc$lifeStage == "Adult"), all(oc$sex == ""),
          all(oc$basisOfRecord == "HumanObservation"), !anyNA(as.integer(oc$individualCount)),
          all(as.integer(oc$individualCount) >= 1L))
vis <- ev[sampleSizeValue == "1000"]; tr <- ev[sampleSizeValue == "50"]
stopifnot(nrow(vis) == 2548L, nrow(tr) == 50363L, all(vis$parentEventID == ""), all(tr$parentEventID %in% vis$eventID),
          all(vis$eventID %in% tr$parentEventID),
          all(vis$eventRemarks == "Fixed 1.5x1.5km square with 20 fixed transect walks of 50m each."),
          all(tr$eventRemarks == "Fixed transect walk of 50m."),
          all(grepl("^In the original data this is known as square: \\d+$", vis$locationRemarks)),
          all(grepl("^In the original data this is known as transect: \\d+(-\\d+){1,2}$", tr$locationRemarks)),
          all(tr$coordinateUncertaintyInMeters == "5"), all(tr$geodeticDatum == "WGS84"),
          all(vis$decimalLatitude == ""), !any(tr$decimalLatitude == ""),
          identical(tr$eventDate, vis$eventDate[match(tr$parentEventID, vis$eventID)]))
stopifnot(identical(as.integer(table(table(tr$parentEventID))[["20"]]), 2474L))
vis[, square := sub(".*square: ", "", locationRemarks)]
tr[, `:=`(sec = sub(".*transect: ", "", locationRemarks), square = vis$square[match(parentEventID, vis$eventID)])]
stopifnot(uniqueN(vis$square) == 92L, tr[, all(sub("-.*", "", sec) == square)],
          uniqueN(tr$locationID) == 2651L, tr[, uniqueN(sec), by = locationID][, all(V1 == 1L)],
          tr[, uniqueN(paste(decimalLatitude, decimalLongitude, footprintWKT, municipality, locality, stateProvince)), by = locationID][, all(V1 == 1L)])
# occurrences: on section walks, or on eventIDs missing from the event core
orph <- oc[!eventID %in% ev$eventID]
stopifnot(all(oc$eventID %in% tr$eventID | !oc$eventID %in% ev$eventID), nrow(orph) == 25L, uniqueN(orph$eventID) == 16L)
oc <- oc[eventID %in% tr$eventID]
stopifnot(nrow(oc) == 45834L, sum(duplicated(oc[, .(eventID, scientificName)])) == 565L)

# dynamicProperties: one flat JSON object per section walk
dp <- rbindlist(lapply(tr$dynamicProperties, function(s) as.data.table(fromJSON(s))), fill = TRUE)
stopifnot(nrow(dp) == nrow(tr), setequal(names(dp), c("observerID", "habitatType", "cloudCover%", "temperatureCelsius", "flowerCover0123")),
          !anyNA(dp$habitatType), all(dp$habitatType %in% c("forest", "grassland", "wetland")),
          all(na.omit(dp$flowerCover0123) %in% seq(0, 3, 0.5)), sum(is.na(dp$observerID)) == 40L)
tr <- cbind(tr, dp)
stopifnot(tr[, uniqueN(habitatType), by = locationID][, all(V1 == 1L)])

# units: section code, suffixed where a moved section has several locationIDs
loc <- tr[, .(first = min(eventDate), sec = sec[1], square = square[1], lat = as.numeric(decimalLatitude[1]),
              lon = as.numeric(decimalLongitude[1]), habitat = habitatType[1], county = stateProvince[1],
              municipality = municipality[1], locality = locality[1], wkt = footprintWKT[1]), by = locationID]
setorder(loc, sec, first, locationID)
loc[, k := seq_len(.N), by = sec][, nk := .N, by = sec]
loc[, unit := ifelse(nk == 1L, sec, paste0(sec, letters[k]))]
stopifnot(!anyDuplicated(loc$unit), nrow(loc) == 2651L, max(loc$nk) == 3L, uniqueN(loc$sec) == 2450L)
cc <- coarsen_coords(loc$lat, loc$lon, 0.1)
loc[, `:=`(c_lat = cc$lat, c_lon = cc$lon, c_unc = cc$uncertainty_m)]

# visits: occasion = rank within square-year
tr[, t0 := ifelse(nzchar(eventTime), substr(eventTime, 12, 16), NA_character_)]
tr[, t1 := ifelse(nzchar(eventTime), substr(sub("^[^/]*/", "", eventTime), 12, 16), NA_character_)]
stopifnot(sum(is.na(tr$t0)) == 100L, all(grepl("^\\d{2}:\\d{2}$", na.omit(tr$t0))), all(grepl("^\\d{2}:\\d{2}$", na.omit(tr$t1))))
vv <- tr[, .(date = eventDate[1], square = square[1], t = if (all(is.na(t0))) NA_character_ else min(t0, na.rm = TRUE)), by = parentEventID]
vv[, year := as.integer(substr(date, 1, 4))]
setorder(vv, square, year, date, t, parentEventID)
vv[, occasion := seq_len(.N), by = .(square, year)]
stopifnot(max(vv$occasion) == 7L, vv[, uniqueN(date), by = .(square, year, occasion)][, all(V1 == 1L)])
YEARS <- 2009:2025
stopifnot(setequal(vv$year, YEARS))
vv[, period := match(year, YEARS)]
obs_ids <- sort(unique(na.omit(tr$observerID)))
stopifnot(length(obs_ids) == 73L)
surv <- tr[, .(eventID, locationID, parentEventID, date = eventDate,
               observer = ifelse(is.na(observerID), NA_character_, sprintf("O%02d", match(observerID, obs_ids))),
               obs_temperature_c = as.numeric(temperatureCelsius), obs_cloud_cover_pct = as.numeric(`cloudCover%`),
               obs_flower_cover = as.numeric(flowerCover0123), obs_time_start = t0, obs_time_end = t1)]
surv <- merge(surv, vv[, .(parentEventID, period, obs_visit = occasion)], by = "parentEventID")
surv <- merge(surv, loc[, .(locationID, unit, cluster_id = square)], by = "locationID")
# six visits (2024-2025) walked one section twice, as two events at different times: both are surveys,
# so a visit with a repeated walk takes two occasion slots in its square-year (the repeat second, by start
# time); occasion = slot rank within square-year, obs_visit = the visit
dup2 <- surv[, .N, by = .(parentEventID, unit)][N > 1L]
stopifnot(nrow(dup2) == 6L, all(dup2$N == 2L))
setorder(surv, unit, period, obs_visit, obs_time_start, eventID)
surv[, rep := seq_len(.N), by = .(parentEventID, unit)]
slots <- unique(surv[, .(cluster_id, period, obs_visit, rep)])
setorder(slots, cluster_id, period, obs_visit, rep)
slots[, occasion := seq_len(.N), by = .(cluster_id, period)]
surv <- merge(surv, slots, by = c("cluster_id", "period", "obs_visit", "rep"))
surv[, rep := NULL]
stopifnot(nrow(surv) == 50363L, !anyDuplicated(surv[, .(unit, period, occasion)]), nrow(slots) == 2548L + 6L,
          surv[, all(occasion >= obs_visit)])
stopifnot(identical(as.vector(table(surv$occasion - surv$obs_visit)), c(50258L, 84L, 21L)))   # square 2008 had two such visits in 2024

# taxa
TX <- unique(oc[, .(scientificName, family, genus, specificEpithet)])
stopifnot(nrow(TX) == 94L, !anyDuplicated(TX$scientificName),
          setequal(TX[family == "", scientificName], c("Bombus spp.", "Lepidoptera spp.", "Leptidea sinapis/juvernica", "Pieridae spp.")),
          setequal(unique(TX$family), c("", "Apidae", "Hesperiidae", "Lycaenidae", "Nymphalidae", "Papilionidae", "Pieridae", "Zygaenidae")),
          TX[family == "Apidae", all(genus == "Bombus")], TX[family == "Zygaenidae", setequal(scientificName, c("Zygaena exulans", "Zygaena filipendulae"))])
TX[, sp2 := sub(" .*", "", scientificName)]
TX[, rank := fcase(scientificName %in% c("Bombus spp."), "genus", scientificName == "Pieridae spp.", "family",
                   scientificName == "Lepidoptera spp.", "order", grepl("/| sensu stricto", scientificName), "speciesAggregate",
                   default = "species")]
TX[, lookup := fcase(rank == "genus", "Bombus", rank == "family", "Pieridae", rank == "order", "Lepidoptera",
                     rank == "speciesAggregate", sp2, scientificName == "Lycaena hippothoe", "Lycaena hippothoe (Linnaeus, 1761)",
                     default = scientificName)]
TX[, code := fcase(rank == "genus", "BOMSPP", rank == "family", "PIERIDAE", rank == "order", "LEPIDOPTERA",
                   scientificName == "Bombus sensu stricto", "BOMBSSTR",
                   default = toupper(paste0(substr(sp2, 1, 3), substr(gsub("[^a-z]", "", sub("^\\S+ ", "", scientificName)), 1, 3))))]
TX[rank == "speciesAggregate" & scientificName != "Bombus sensu stricto",
   code := toupper(paste0(substr(sp2, 1, 3), substr(sub("^\\S+ ([a-z]+)/.*$", "\\1", scientificName), 1, 3),
                          substr(sub("^.*/", "", scientificName), 1, 3)))]
stopifnot(!anyDuplicated(TX$code), sum(TX$rank == "speciesAggregate") == 5L, sum(TX$rank == "species") == 86L)
TX[, remarks := fcase(
  scientificName == "Bombus sensu stricto", "Species aggregate as recorded: the subgenus Bombus s. str. (B. terrestris / lucorum / cryptarum / magnus, not separable in the field); taxonID is the genus Bombus",
  rank == "speciesAggregate", sprintf("Species aggregate as recorded by the source (%s not separated); taxonID is the genus", scientificName),
  rank == "genus", "Bumblebees not identified to species (Bombus spp.); taxonID is the genus",
  rank == "family", "Whites not identified below family (Pieridae spp.); taxonID is the family",
  rank == "order", "Butterflies or burnets not identified below order (Lepidoptera spp.); taxonID is the order",
  default = NA_character_)]
TX[scientificName == "Lycaena hippothoe", remarks := "Matched on GBIF as Lycaena hippothoe (Linnaeus, 1761); the bare name is a homonym the strict match resolves only to the family"]
setorder(TX, code)
taxa <- make_taxa(TX$code, TX$scientificName, taxonRank = TX$rank, lookupName = TX$lookup, taxonRemarks = TX$remarks,
                  taxon_family = TX$family, allow_higher = TX[rank != "species", code])
taxa[, taxon_family := ifelse(taxon_family == "", NA_character_, taxon_family)]
taxa[taxon == "PIERIDAE", taxon_family := "Pieridae"]; taxa[taxon %in% c("BOMSPP", "LEPSINJUV"), taxon_family := c(BOMSPP = "Apidae", LEPSINJUV = "Pieridae")[taxon]]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
taxa[taxonRank != "species", taxon_iucnCategory := NA_character_]
# GBIF's IUCN endpoint matched synonyms of these names; the assessed record is the deposited name, NE
stopifnot(identical(sort(taxa[taxonRank == "species" & is.na(taxon_iucnCategory), scientificName]),
                    sort(c("Agriades optilete", "Boloria euphrosyne", "Lasiommata petropolitana", "Lycaena helle",
                           "Ochlodes sylvanus", "Polyommatus amandus", "Lycaena hippothoe"))))
taxa[taxonRank == "species" & is.na(taxon_iucnCategory), taxon_iucnCategory := "NE"]
FLAG <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
stopifnot(identical(FLAG, "BOMALP"))

# counts and the explicit-zero grid
oc <- merge(oc, TX[, .(scientificName, taxon = code)], by = "scientificName")
cnt <- oc[, .(y = sum(as.integer(individualCount))), by = .(eventID, taxon)]
stopifnot(nrow(cnt) == 45834L - 565L)
grid <- CJ(i = seq_len(nrow(surv)), taxon = TX$code)
long <- cbind(surv[grid$i, .(eventID, locationID, unit, period, occasion, date, observer, cluster_id, obs_temperature_c,
                             obs_cloud_cover_pct, obs_flower_cover, obs_time_start, obs_time_end, obs_visit)], taxon = grid$taxon)
rm(grid); invisible(gc())
long <- merge(long, cnt, by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(nrow(long) == 50363L * 94L, sum(long$y) == sum(as.integer(oc$individualCount)), sum(long$y > 0) == nrow(cnt))
long[, eventID := NULL]
long <- merge(long, loc[, .(locationID, unit_habitat = habitat, unit_county = county, lat, lon, c_lat, c_lon, c_unc)], by = "locationID")
long[, locationID := NULL]
cat(sprintf("  %d rows: %d sections in %d squares, %d walks, 94 taxa, %d individuals\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), nrow(surv), sum(long$y)))
periods <- data.table(period = seq_along(YEARS), period_year = YEARS)

common <- list(
  creator = "Gohli, Jostein; Åström, Jens",
  pubDate = "2026", doi = "10.15468/mpsa4g", sourceURL = "https://doi.org/10.15468/mpsa4g",
  citation = "Gohli J, Åström J (2026). Bumblebees and butterflies in Norway. Version 1.12. Norwegian Institute for Nature Research. Samplingevent dataset. https://doi.org/10.15468/mpsa4g",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
  samplingProtocol = "National monitoring of butterflies and bumblebees (NINA for the Norwegian Environment Agency): in each 1.5 x 1.5 km square of an 18 km grid over lowland Norway, 20 fixed 50 m transect sections in open forest and grassland are walked three times each summer (late spring, mid-summer, late summer) between 10:00 and 17:00 in suitable weather (above 15 C, at most 60% cloud, little wind) by trained volunteers; all bumblebees (Bombus) and butterflies and burnets (Papilionidae, Hesperiidae, Pieridae, Lycaenidae, Nymphalidae, Zygaenidae) within 2.5 m to each side and 5 m ahead are identified and counted, caught with a sweep net when needed; flower cover (0-3), temperature, cloud and time recorded per section.",
  samplingProtocolCode = "transect_count",
  surveyEvidence = "sample_table",
  surveyEvidenceNote = "Every 50 m section walk is an event in the event core, including walks with no records; the publisher states that absences were removed and are inferred by adding zeros for all bumblebee and butterfly taxa at every event. Each walk carries a row for every taxon in the occurrence file.",
  responseType = "count", unitKind = "site",
  closure = "open", occasionKind = "time", taxonInclusion = "recorded",
  closureNote = "not assumed: the three visits of a summer are timed to late spring, mid-summer and late summer to cover different species' flight periods; period = calendar year",
  temporalCoverage = "2009-05/2025-09",
  notes = "unit = 50 m transect section (the source's section code; a/b/c where a moved section has several locationIDs), cluster_id = 1.5 km square code, obs_visit = the square visit's rank in its year (most square-years have three visits, a few one to seven; 74 visits walked fewer than 20 sections); occasion = the visit's slot in the square-year, equal to obs_visit except where six visits in 2024-2025 walked one section twice (two events at different times, both kept): such a visit has two slots, the repeat walk in the second, and later visits shift by one. y = individuals counted (records of one taxon on one walk summed: 565 cases). Taxa are as recorded: five species aggregates (including Bombus sensu stricto), Bombus spp., Pieridae spp. and Lepidoptera spp. are their own taxa, so a zero for a species does not exclude individuals recorded only to the aggregate. Zygaena (burnets) are included because the EML lists Zygaenidae among the registered families, although its zero-inference note names Papilionoidea and Bombus only. Observers are pseudonymous UUIDs in the source, recoded O01..O73. Regions joined over time (Ostfold/Vestfold 2009, Trondelag 2011, Agder/Rogaland 2013, Vestland/More og Romsdal later, northern Norway 2025), so the unit set grows with period.",
  geographicCoverage = "Lowland Norway: 92 survey squares in Viken, Vestfold og Telemark, Trondelag, Agder, Rogaland, Vestland, More og Romsdal, Nordland and Troms og Finnmark")
emit <- function(TT, exact) {
  lg <- if (exact) long[taxon != "BOMALP"] else copy(long)
  lg[, c("unit_habitat", "unit_county", "lat", "lon", "c_lat", "c_lon", "c_unc") := NULL]
  lg <- order_eco(lg)
  # unit-level facts in __units (as barea_2021_sierranevada_butterfly_count), not repeated on 4.7M rows
  units <- if (exact) loc[, .(unit, unit_habitat = habitat, unit_county = county, unit_decimalLatitude = lat,
                              unit_decimalLongitude = lon, unit_coordinateUncertaintyInMeters = 5L, unit_locationID = locationID,
                              unit_section_code = sec, unit_municipality = municipality, unit_locality = locality,
                              unit_footprintWKT = wkt)]
           else loc[, .(unit, unit_habitat = habitat, unit_county = county, unit_decimalLatitude = c_lat,
                        unit_decimalLongitude = c_lon, unit_coordinateUncertaintyInMeters = c_unc)]
  setorder(units, unit)
  stopifnot(setequal(units$unit, lg$unit))
  ds <- write_table(lg, TT, c(common, list(
    title = paste0("Bumblebee and butterfly counts on 50 m transect sections, three visits a summer, Norwegian national pollinator monitoring 2009-2025",
                   if (exact) " (without Bombus alpinus, coordinates as published)" else ""),
    abstract = paste0("Counts of bumblebees (Bombus: 22 species, 3 aggregates and Bombus spp.) and butterflies and burnets (Papilionoidea and Zygaena: 64 species, 2 aggregates, Pieridae spp. and Lepidoptera spp.) on 50 m transect sections, 20 per 1.5 km square, in 92 squares of a grid over lowland Norway, walked three times each summer 2009-2025 by trained volunteers for the Norwegian national monitoring programme run by NINA; with per-walk temperature, cloud cover, flower cover and time, and section habitat. Absences are the explicit zeros of every taxon at every walk, as the publisher instructs.",
                      if (exact) " This table omits Bombus alpinus (IUCN VU) so that section coordinates ship at the published 5 m precision." else " Section coordinates are coarsened to 0.1 degree because Bombus alpinus (IUCN VU) is among the taxa."),
    coordinatesCoarsened = if (exact) list(value = FALSE, method = "As published (section centre points, coordinateUncertaintyInMeters 5): Bombus alpinus (IUCN VU) is not in this table (E7.3); nina_2026_norway_pollinator_count has it with coarsened coordinates")
      else list(value = TRUE, method = "coarsen_coords() to 0.1-degree cell centres, uncertainty the cell half-diagonal: the source's section coordinates are 5 m and Bombus alpinus (IUCN VU, native) is among the taxa; municipality, locality and section footprint not shipped (E7.4); unit and cluster_id are grid codes, kept"),
    components = list(if (exact) TABLE else TABLE_X),
    notShipped = c(list(`square-visit events` = "2,548 parent events (the 1.5 km square visit) that contain the section walks and carry no records of their own",
                        `orphan records` = "25 occurrence records on 16 eventIDs absent from event.txt (no survey to attach them to)",
                        `observer UUIDs` = "recoded to O01..O73"),
                   if (exact) list(BOMALP = "Bombus alpinus (IUCN VU): in nina_2026_norway_pollinator_count only, whose coordinates are coarsened")
                   else list(`municipality, locality, footprintWKT` = "place names and 5 m section geometry (E7.4); in nina_2026_norway_pollinator_exact_count and its __units")))),
    taxa = if (exact) taxa[taxon != "BOMALP"] else taxa, periods = periods, units = units, script = SCRIPT)
  stage_dict_row(TT,
    description = paste0("Norwegian national monitoring of bumblebees and butterflies (NINA): counts of ", if (exact) "93" else "94",
                         " taxa on 50 m transect sections (20 per 1.5 km square, 92 squares), three visits each summer 2009-2025, with zeros at every walk; walk weather and flower cover, section habitat; ",
                         if (exact) "without Bombus alpinus, coordinates as published." else "coordinates coarsened to 0.1 degree (Bombus alpinus, IUCN VU)."),
    url = "https://doi.org/10.15468/mpsa4g",
    reference = "Gohli J, Åström J (2026). Bumblebees and butterflies in Norway. Version 1.12. Norwegian Institute for Nature Research. Samplingevent dataset. https://doi.org/10.15468/mpsa4g",
    doi_paper = "", doi_data = "10.15468/mpsa4g", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = if (exact) "E7.3 sibling of nina_2026_norway_pollinator_count without Bombus alpinus; section coordinates, municipality, locality and footprint (in __units) as published." else
      "Zeros added at every walk for every taxon as the publisher instructs; coordinates coarsened for Bombus alpinus; nina_2026_norway_pollinator_exact_count has the other taxa at published precision.",
    source_via = "GBIF / NINA IPT (DwC-A v1.12)")
  stage_tag_row(TT, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, open; Pollard-type section counts)",
    sampling_protocol = "transect_count", design = "Multi-season (2009-2025, three visits per summer)", realm = "Terrestrial",
    country = "NOR", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = if (exact) "About 4.8M rows; Bombus alpinus withheld for precision." else "About 4.8M rows; Bombus alpinus (IUCN VU) among the taxa.")
}
emit(TABLE, exact = FALSE)
emit(TABLE_X, exact = TRUE)
