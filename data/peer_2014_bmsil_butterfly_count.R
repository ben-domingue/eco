#!/usr/bin/env Rscript
# Table:  peer_2014_bmsil_butterfly_count
# Source: GBIF sampling-event dataset 647ae6f8-8e26-4189-b448-02b45b7ad884, doi:10.15468/q4lynx,
#         EU BON IPT resource butterflies-monitoring-scheme-il, EML packageId .../v6.17.
#         Licence as shown on GBIF and in the EML: CC0 1.0 ("the publisher has waived all rights to
#         these data and has dedicated them to the Public Domain (CC0 1.0)").
#         Citation (EML): Peer I (2014). Israeli Butterfly Monitoring Scheme (BMS-IL). v6.17. ILS -
#         Israeli Lepidopterists' society. Dataset/Samplingevent.
#         http://cloud.gbif.org/eubon/resource?r=butterflies-monitoring-scheme-il&v=6.17
#         Principal investigator Guy Pe'er (UFZ); content providers D. Benyamini, R. Schwartz-Tzachor.
# Paper:  none for the dataset; the scheme follows the Pollard-walk protocol (Van Swaay et al. 2015,
#         GEO BON Technical Series 1) and is analysed in Schmucki et al. (2016, J. Appl. Ecol.,
#         doi:10.1111/1365-2664.12561), both cited in the EML.
# Data:   Darwin Core Archive, event core with occurrence and measurementorfact extensions.
#   event.txt (7,329 events): one event per transect section in which something was recorded
#     ("<visit>-tr<nnn>-s<k>"), plus one "s00" event per visit in which no butterfly was seen on the
#     whole transect (221; eventRemarks "No occurrences of Lepidoptera recorded for entire
#     transect" on 153 of them). 1,847 visit ids on 39 transects (TR...), 2009-10-02 to 2015-11-13;
#     one date, time window, locality and observer per visit. Section coordinates (up to 12 per
#     transect), uncertainty 25 m. sampleSize 250 m2, "Average of 30 Minutes walk" on every event.
#     Two visit ids (3348, 3349) are the same empty walk of TR003 on 2014-10-29 entered twice.
#   occurrence.txt (13,450 rows): count of a taxon in a section (organismQuantity, individuals);
#     the s00 events carry 'Lepidoptera', 0, absent. 81 species plus records to family or order
#     (Pieridae 314, Lycaenidae 166, Hesperiidae 26, Satyridae 20, Nymphalidae 15, Papilionidae 1,
#     Lepidoptera 1 present). 13 pairs of rows repeat an event x name (visit 3481's Azanus jesous
#     records are entered twice over five sections); they are summed as deposited.
#   measurementorfact.txt (53,800 rows): Temperature (C), Wind Speed (category), Cloudiness (0-8)
#     and Number of sections, one set per occurrence row, constant within a visit (asserted); Wind and
#     Cloudiness have NoData. Temperature is 0 on 240 rows and 60-297 on 78 (probably a dropped
#     decimal point, 209 = 20.9?): not plausible as recorded, so NA.
#     Number of sections is constant per transect, but 94 section events carry a section number
#     beyond it.
#   EML protocol: transects of 50 m sections (300-600 m), walked every two weeks from October to
#     June (visits also occur July-September in the data); every butterfly within a 5 m cube is
#     counted per section; unidentified individuals go to family or a predefined complex; the whole
#     transect is always walked (partial walks are not recorded); a walk with no butterflies is
#     recorded as s00. 'Extra' sightings outside 5 m are not in the archive.
#
# Mapping (standard E1-E5, community repeated counts / Pollard walks):
#   unit = transect (39), taxon = 8-letter code (4 genus + 4 species letters), period = monitoring
#   season from 1 October to 30 September (1 = 2009/10 ... 7 = 2015/16; __periods), occasion =
#   visit within the transect-season in date order, y = butterflies of the species over all
#   sections of the walk (the EML's own instruction for densities: sum the sections); 0 for every
#   species at every visit (all butterflies are counted).
#   surveyEvidence = row_presence: a visit exists where the event table has any row for it,
#   including the explicit s00 rows for empty walks; whole-transect walks only, so the transect
#   visit is the survey. Section-level zeros are not built: an empty section in a non-empty walk
#   has no event, so section x visit would need the stated section count, which 94 events exceed.
#   date = eventDate; observer = pseudonymous id (OBS01... in order of first walk) for the
#   recordedBy volunteer names; obs_start_time / obs_end_time from eventTime (HH:MM, NA where the
#   source writes 00:00); obs_temperature_c (NA where 0 or above 50), obs_wind (category, NA for
#   NoData), obs_cloudiness (0-8). Unit covariates in __units: locality, n of sections as stated,
#   and the centroid of the section coordinates.
#   Coordinates: section coordinates are averaged to one point per transect (not finer than the
#   source); the script checks each species' IUCN category through GBIF and coarsens if any is
#   CR / EN / VU.
#   Records to family or order (unidentified individuals) are their own taxa at that rank (v1.1 E6);
#   the zeros of the species they may belong to stay as recorded.
#   Not shipped: section-level counts (summed into y); subspecies
#   epithets (one per species, kept out of the code); volunteer names; the per-event
#   sampleSize (250 m2) and samplingEffort text (constant).
#   v1.1: closure = open (year-long season of walks), occasionKind = time, taxonInclusion =
#   recorded (species, families and the order with at least one record). IUCN check through
#   iucn_category().
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "peer_2014_bmsil_butterfly_count"

zip <- download_cached("https://cloud.gbif.org/eubon/archive.do?r=butterflies-monitoring-scheme-il", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "measurementorfact.txt", "eml.xml", "meta.xml")))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("dedicated them to the", eml, fixed = TRUE)), any(grepl("publicdomain/zero/1.0/legalcode\"><citetitle>Public Domain (CC0 1.0)", eml, fixed = TRUE)),
          any(grepl("647ae6f8-8e26-4189-b448-02b45b7ad884/v6.17", eml, fixed = TRUE)))

rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL)
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("measurementorfact.txt")
stopifnot(nrow(ev) == 7329, !anyDuplicated(ev$eventID), nrow(oc) == 13450, nrow(mf) == 53800,
          all(grepl("^[0-9]+-tr[0-9]+-s[0-9]+$", ev$eventID)),
          all(ev$samplingProtocol == "Pollard walks"), all(ev$sampleSizeValue == "250"), all(ev$country == "Israel"),
          all(ev$coordinateUncertaintyInMeters == "25"))
ev[, `:=`(visit = sub("-.*$", "", eventID), sec = as.integer(sub("^.*-s", "", eventID)))]
stopifnot(all(toupper(sub("^[0-9]+-(tr[0-9]+)-.*$", "\\1", ev$eventID)) == ev$locationID),
          uniqueN(ev$visit) == 1847, uniqueN(ev$locationID) == 39,
          ev[, .(n = uniqueN(paste(locationID, eventDate, eventTime, locality))), by = visit][, all(n == 1)],
          sum(ev$sec == 0) == 221, !any(ev[sec == 0, visit] %in% ev[sec != 0, visit]))

# occurrences
stopifnot(all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID), all(oc$organismQuantityType == "individuals"),
          oc[occurrenceStatus == "absent", all(scientificName == "Lepidoptera" & organismQuantity == "0")],
          setequal(oc[occurrenceStatus == "absent", eventID], ev[sec == 0, eventID]),
          oc[occurrenceStatus == "present", all(as.integer(organismQuantity) >= 1)],
          sum(duplicated(oc[, .(eventID, scientificName)])) == 13)
oc[, `:=`(visit = sub("-.*$", "", eventID), name = gsub("\\s+", " ", trimws(scientificName)))]
stopifnot(oc[, .(n = uniqueN(recordedBy)), by = visit][, all(n == 1)])
higher <- c("Lepidoptera", "Pieridae", "Lycaenidae", "Hesperiidae", "Satyridae", "Nymphalidae", "Papilionidae")
stopifnot(all(higher %in% oc$name), all(grepl(" ", setdiff(unique(oc$name), higher))))
# v1.1 (E6): records the source identified only to family or order are their own taxa at that rank
spo <- oc[occurrenceStatus == "present"]
sp <- data.table(binomial = sort(unique(spo$name)))
sp[, higher := binomial %in% higher]
sp[, taxon := fifelse(higher, toupper(substr(binomial, 1, 8)),
                      toupper(paste0(substr(sub(" .*$", "", binomial), 1, 4), substr(sub("^\\S+ ", "", binomial), 1, 4))))]
sp[, rank := fifelse(!higher, "species", fifelse(binomial == "Lepidoptera", "order", "family"))]
stopifnot(sum(!sp$higher) == 81, setequal(sp[higher == TRUE, binomial], higher), !anyDuplicated(sp$taxon),
          spo[!name %in% higher, uniqueN(infraspecificEpithet), by = name][, all(V1 == 1)])
counts <- spo[, .(y = sum(as.integer(organismQuantity))), by = .(visit, name)]
counts[, taxon := sp$taxon[match(name, sp$binomial)]]

# visits (the survey set); the duplicated empty walk of TR003 on 2014-10-29 is one survey
vis <- ev[!duplicated(visit), .(visit, unit = locationID, date = eventDate, eventTime, locality)]
stopifnot(sum(duplicated(vis[, .(unit, date)])) == 1,
          identical(sort(vis[duplicated(vis[, .(unit, date)]) | duplicated(vis[, .(unit, date)], fromLast = TRUE), visit]), c("3348", "3349")),
          !any(c("3348", "3349") %in% counts$visit))
vis <- vis[visit != "3349"]
vis[, d := as.IDate(date)]
stopifnot(!anyNA(vis$d), min(vis$d) == as.IDate("2009-10-02"), max(vis$d) == as.IDate("2015-11-13"))
vis[, season := year(d) - (month(d) < 10L)]
seasons <- 2009:2015
stopifnot(setequal(vis$season, seasons))
setorder(vis, unit, d)
vis[, occasion := seq_len(.N), by = .(unit, season)]
vis[, period := match(season, seasons)]
# eventTime is "HH:MM:02Z/HH:MM:02Z" (local walk times with a constant 2 s and a Z); some carry stray
# spaces or a truncated end ("09:50:02Z/:02Z"); 00:00 means not recorded
vis[, eventTime := gsub(" ", "", eventTime)]
stopifnot(mean(grepl("^\\d{2}:\\d{2}:02Z/\\d{2}:\\d{2}:02Z$", vis$eventTime)) > 0.99)
hm <- function(x) { x <- substr(x, 1, 5); fifelse(!grepl("^\\d{2}:\\d{2}$", x) | x == "00:00", NA_character_, x) }
vis[, `:=`(obs_start_time = hm(sub("/.*$", "", eventTime)), obs_end_time = hm(sub("^.*/", "", eventTime)))]
obs <- oc[!duplicated(visit), .(visit, recordedBy)]
vis[, rec := obs$recordedBy[match(visit, obs$visit)]]
first <- vis[order(d), .(f = d[1]), by = rec][order(f, rec)]
first[, observer := sprintf("OBS%02d", seq_len(.N))]
vis[, observer := first$observer[match(rec, first$rec)]]
stopifnot(!anyNA(vis$observer), uniqueN(vis$observer) == 35)

# visit-level weather and transect length
# one measurement set per occurrence row (13,450 x 4), repeated within an event: identical (asserted)
stopifnot(mf[, .N, by = measurementType][, all(N == 13450)],
          mf[, uniqueN(measurementValue), by = .(id, measurementType)][, all(V1 == 1)])
mw <- dcast(unique(mf[, .(id, measurementType, measurementValue)]), id ~ measurementType, value.var = "measurementValue")
stopifnot(setequal(mw$id, ev$eventID), setequal(names(mw), c("id", "Cloudiness", "Number of sections", "Temperature", "Wind Speed")))
mw[, visit := sub("-.*$", "", id)]
stopifnot(mw[, .(a = uniqueN(Cloudiness), b = uniqueN(Temperature), c = uniqueN(`Wind Speed`), e = uniqueN(`Number of sections`)), by = visit][, all(a == 1 & b == 1 & c == 1 & e == 1)])
mv <- mw[!duplicated(visit)]
tmp <- as.numeric(mv$Temperature); stopifnot(!anyNA(tmp))
mv[, obs_temperature_c := fifelse(tmp == 0 | tmp > 50, NA_real_, tmp)]
stopifnot(all(mv$`Wind Speed` %in% c("No", "Light", "Light to Modest", "Modest", "Modest To Strong", "Strong", "NoData")),
          all(mv$Cloudiness %in% c(0:8, "NoData")))
mv[, `:=`(obs_wind = fifelse(`Wind Speed` == "NoData", NA_character_, `Wind Speed`),
          obs_cloudiness = fifelse(Cloudiness == "NoData", NA_integer_, suppressWarnings(as.integer(Cloudiness))))]
vis <- merge(vis, mv[, .(visit, obs_temperature_c, obs_wind, obs_cloudiness)], by = "visit")

ev[, nsec := mw$`Number of sections`[match(eventID, mw$id)]]
stopifnot(ev[, uniqueN(nsec), by = locationID][, all(V1 == 1)], sum(ev$sec > as.integer(ev$nsec)) == 94)
# coordinates: one per section (some with a leading space; TR017, Naale near Bet Arye, 57 events, has none: NA)
ev[, `:=`(lat = as.numeric(gsub("[^0-9.]", "", decimalLatitude)), lon = as.numeric(gsub("[^0-9.]", "", decimalLongitude)))]
stopifnot(sum(is.na(ev$lat)) == 57, all(ev[is.na(lat), locationID] == "TR017"), all(is.na(ev$lat) == is.na(ev$lon)))
units <- ev[!is.na(lat), .(unit_decimalLatitude = mean(unique(lat)), unit_decimalLongitude = mean(unique(lon)),
                           spread_m = 111320 * max(diff(range(lat)), diff(range(lon)) * cos(mean(lat) * pi / 180))), by = .(unit = locationID)]
stopifnot(nrow(units) == 38, !"TR017" %in% units$unit, max(units$spread_m) < 2000,
          all(units$unit_decimalLatitude > 29 & units$unit_decimalLatitude < 34), all(units$unit_decimalLongitude > 34 & units$unit_decimalLongitude < 36))
cat(sprintf("  section-coordinate spread per transect: median %.0f m, max %.0f m\n", median(units$spread_m), max(units$spread_m)))
units <- merge(ev[, .(unit_locality = locality[1], unit_n_sections = as.integer(nsec[1])), by = .(unit = locationID)],
               units[, .(unit, unit_decimalLatitude, unit_decimalLongitude, spread_m)], by = "unit", all.x = TRUE)
stopifnot(nrow(units) == 39)

# taxa and the IUCN check
look <- c("Anaphaeis aurota" = "Belenois aurota", "Apharitis cilissa" = "Cigaritis cilissa",   # source spellings GBIF does not match
          # v1.1 make_taxa(exact = TRUE): bare "Melitaea ornata" fell to the genus Melitaea (HIGHERRANK)
          # in v1.0; with its authority it matches the species name EXACTLY (GBIF files it as a synonym
          # of M. phoebe, gbifAcceptedName). Tarucus rosaceus is the backbone's T. rosacea (gender ending).
          "Melitaea ornata" = "Melitaea ornata Christoph, 1893", "Tarucus rosaceus" = "Tarucus rosacea")
taxa <- make_taxa(sp$taxon, sp$binomial, taxonRank = sp$rank,
                  lookupName = fifelse(sp$binomial %in% names(look), look[sp$binomial], sp$binomial),
                  allow_higher = sp[higher == TRUE, taxon])
stopifnot(!anyNA(taxa$taxonID))
taxa[taxon %in% sp[higher == TRUE, taxon],
     taxonRemarks := "individuals the walker could not identify to species, recorded by the source at this rank; not a sum of the species rows"]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# ten NA answers: GBIF keys these under another accepted name (Cigaritis acamas, Pseudophilotes
# baton, ...), but each IUCN record carries the source's own name, so it is the same species;
# every one of the ten records says NE (checked 2026-11-03), taken as NE
NA10 <- c("APHAACAM", "CHILGALB", "COLILIBA", "EUCHCHAR", "LYCATHER", "MELIORNA", "PSEUVICR", "SATYILIC", "SATYSPIN", "SPIAORBI")
stopifnot(setequal(taxa[is.na(taxon_iucnCategory) & taxonRank == "species", taxon], NA10))
taxa[taxon %in% NA10, taxon_iucnCategory := "NE"]
taxa[taxonRank != "species", taxon_iucnCategory := NA_character_]   # IUCN assesses species, not families
print(taxa[, .N, by = taxon_iucnCategory])
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
cat("  IUCN flagged:", if (nrow(flagged)) paste(flagged$scientificName, flagged$taxon_iucnCategory) else "none", "\n")
COARSEN <- nrow(flagged) > 0
if (COARSEN) {
  cc <- coarsen_coords(units$unit_decimalLatitude, units$unit_decimalLongitude)
  units[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m)]
} else {
  units[, `:=`(unit_decimalLatitude = round(unit_decimalLatitude, 6), unit_decimalLongitude = round(unit_decimalLongitude, 6),
               unit_coordinateUncertaintyInMeters = round(spread_m / 2 + 25))]   # centroid: half the section spread + 25 m
}

units[, spread_m := NULL]

# long table
surveys <- vis[, .(visit, unit, period, occasion, date = format(d), observer, obs_start_time, obs_end_time,
                   obs_temperature_c, obs_wind, obs_cloudiness)]
stopifnot(nrow(surveys) == 1846, !anyDuplicated(surveys[, .(unit, period, occasion)]))
long <- surveys[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(surveys))]
long <- merge(long, counts[, .(visit, taxon, y)], by = c("visit", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, visit := NULL]
stopifnot(nrow(long) == 1846 * nrow(sp), sum(long$y) == sum(as.integer(spo$organismQuantity)))
long <- order_eco(long)

periods <- data.table(period = seq_along(seasons), period_season = sprintf("%d/%02d", seasons, (seasons + 1) %% 100),
                      period_start = sprintf("%d-10-01", seasons), period_end = sprintf("%d-09-30", seasons + 1),
                      period_n_visits = sapply(seasons, function(s) sum(vis$season == s)))
bb <- units[, .(w = min(unit_decimalLongitude, na.rm = TRUE), e = max(unit_decimalLongitude, na.rm = TRUE), s = min(unit_decimalLatitude, na.rm = TRUE), n = max(unit_decimalLatitude, na.rm = TRUE))]
dataset <- list(
  title = "Pollard-walk counts of 81 butterfly species on 39 transects of the Israeli Butterfly Monitoring Scheme (BMS-IL), 2009-2015",
  creator = "Peer, Israel; Pe'er, Guy; Benyamini, Dubi; Schwartz-Tzachor, Racheli", pubDate = "2016-12-23",
  sourceURL = "https://doi.org/10.15468/q4lynx",
  citation = "Peer I (2014). Israeli Butterfly Monitoring Scheme (BMS-IL). v6.17. ILS - Israeli Lepidopterists' society. Dataset/Samplingevent. https://doi.org/10.15468/q4lynx (CC0 1.0).",
  dataDOI = "10.15468/q4lynx",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Volunteer Pollard walks of the Israeli Butterfly Monitoring Scheme: 39 transects of 50 m sections (300-600 m) across Israel, walked about every two weeks, mostly October to June, with every butterfly within 5 m counted per section. 1,846 walks from October 2009 to November 2015, 220 of them with no butterfly seen; counts summed over the sections of a walk; 81 species plus 7 family- or order-level taxa for butterflies the walker could not identify to species.",
  samplingProtocol = "Pollard walk: the whole transect is walked (partial walks are not recorded), every butterfly within an imaginary 5 x 5 x 5 m cube counted per 50 m section; unidentified individuals recorded to family (shipped as family-level taxa); a walk with no butterfly recorded as an explicit absence event; start time and weather recorded per walk.",
  samplingProtocolCode = "transect_count", occasionLength = "one transect walk (about 30 minutes)",
  surveyEvidence = "row_presence",
  surveyEvidenceNote = "A walk exists where event.txt has any row for its visit id: section events for walks with sightings and an explicit s00 absence event (Lepidoptera, 0) for each of the 221 walks with none; the protocol records only whole-transect walks. Two visit ids that are one empty walk of TR003 on 2014-10-29 are one survey.",
  responseType = "count", unitKind = "site",
  closure = "open", closureNote = "not assumed: visits every two weeks through a season of up to a year follow each species' flight period; period = monitoring season from 1 October",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Israel, from the Golan and Galilee to the Negev (39 transects)",
                            boundingBox = list(west = bb$w, east = bb$e, south = bb$s, north = bb$n)),
  temporalCoverage = sprintf("%s/%s", min(vis$d), max(vis$d)),
  coordinatesCoarsened = if (COARSEN) list(value = TRUE, method = sprintf("0.1 degree cell centres (coarsen_coords), because %s is IUCN %s", paste(flagged$scientificName, collapse = ", "), paste(flagged$taxon_iucnCategory, collapse = ", "))) else
    list(value = FALSE, method = "As published, averaged: the centroid of each transect's section coordinates, uncertainty half the section spread + 25 m; TR017 has no coordinates in the source; no species is IUCN CR, EN or VU (checked through GBIF)"),
  notShipped = list(`section counts` = "summed over the sections of each walk into y (the EML's own instruction); section-level zeros cannot be evidenced because empty sections have no event",
                                        `recordedBy` = "volunteer names, replaced by pseudonymous observer ids",
                    `infraspecificEpithet` = "one subspecies name per species where given; not part of the taxon code",
                    `duplicate rows` = "13 repeated event x taxon rows (visit 3481's Azanus jesous records over five sections appear twice) are summed as deposited",
                    `measurementorfact temperature` = "values of 0 (240 section events) and above 50 are set to NA in obs_temperature_c"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/peer_2014_bmsil_butterfly_count.R")

stage_dict_row(TABLE,
  description = "Counts of 81 butterfly species on 1,846 Pollard walks of 39 transects of the Israeli Butterfly Monitoring Scheme (BMS-IL), October 2009 to November 2015, summed over the 50 m sections of each walk, with pseudonymous observer, start time, temperature, wind and cloudiness.",
  url = "https://doi.org/10.15468/q4lynx",
  reference = "Peer I (2014). Israeli Butterfly Monitoring Scheme (BMS-IL). v6.17. ILS - Israeli Lepidopterists' society. Dataset/Samplingevent.",
  doi_data = "10.15468/q4lynx", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Zeros from the walk list (empty walks carry an explicit absence event). Sections summed. Family- and order-level records are their own taxa (E6). Season = 1 October to 30 September. Temperature 0 / >50 set to NA.",
  source_via = "GBIF (EU BON IPT)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "transect_count", design = "Multi-season (7 seasons x up to 27 fortnightly walks per transect)",
  realm = "Terrestrial", country = "Israel", coordinates = if (COARSEN) "Coarsened (0.1 deg)" else "As published (centroid of section coordinates)",
  notes = "Volunteer butterfly monitoring scheme, Pollard walks; counts are per walk, summed over sections.", status = "tagged")
