#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_butterfly_count
# Source: GBIF sampling-event dataset 81b909c7-5612-4148-8e70-99fea2cdb572, doi:10.15468/wwrgcd, version 1.7 (2025),
#         INBO IPT resource bms-occurrences. Maes D, Piesschaert F, Brosens D, Desmet P (2025). Butterfly monitoring
#         scheme in Flanders, Belgium. Version 1.7. Research Institute for Nature and Forest (INBO).
#         Licence: the GBIF registry and the EML intellectualRights give CC BY-NC 4.0; the EML abstract and every
#         event row say CC0 1.0. The stricter licence governs (intake conflict rule; queue hold lifted 2026-11-06):
#         derived licence CC BY-NC 4.0, both recorded in the dictionary row (both asserted).
# Paper:  none; protocol in Maes et al. (2019) Monitoringsprotocol Dagvlinders v2.0 (INBO report, cited in the EML):
#         Pollard walks of transects up to 1 km in 50-m sections, walked repeatedly through the flight season.
# Data:   Darwin Core Archive: event.txt (75,051 rows: one per transect section walk; parentEventID = the visit,
#           8,906 visits; locationID = the route, 112; one date and one route per visit, asserted; coordinates
#           generalised by INBO to 5 km or 10 km UTM square centroids), occurrence.txt (146,475 rows: imago counts
#           per section and species, 50 names incl. 'Pieris spec.' at genus rank; 36 rows 'absent' with count 0),
#           measurementorfacts.txt (cloudiness 'bewolking', temperature, wind force 'windkracht' per section, constant
#           within a visit, asserted; 68,915 more rows, on 34,683 section events, have an empty measurementType).
# Mapping (repeated counts, community; responseType count): unit = route (locationID), period = calendar year
#   1991..2020 as 1..30, occasion = visit within the year in date order, y = imagos of the taxon counted on the
#   visit, summed over sections, date = eventDate, observer none. Pollard-walk rule (batches 17-20): the archive
#   records a section only where something was seen (8 of 75,051 section events have no occurrence, asserted), so
#   the survey is the visit (sections summed). surveyEvidence = row_presence: a visit is a survey; every recorded
#   taxon has a row at every visit, 0 where not counted (taxonInclusion recorded: complete butterfly counts).
#   obs_n_sections_recorded = the sections with an event row on the visit (a lower bound on sections walked),
#   obs_cloudiness, obs_temperature, obs_wind_bft (as deposited). unit_locality, unit_ coordinates as INBO
#   published them (agency-generalised, E7: kept as published).
# Not shipped: section-level counts (the archive omits empty sections, so section zeros are not evidenced); the
#   68,915 measurements with an empty measurementType (undefined, e.g. '19.0', '2'); taxon vernacular names in
#   Dutch (in __taxa as vernacularName where English is unknown).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_butterfly_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=bms-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "measurementorfacts.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Creative Commons Attribution Non Commercial (CC-BY-NC) 4.0 License", eml, fixed = TRUE),
          grepl("by-nc/4.0/legalcode", eml, fixed = TRUE), grepl("Creative Commons Zero waiver", eml, fixed = TRUE),
          grepl("81b909c7-5612-4148-8e70-99fea2cdb572/v1.7", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "measurementorfacts.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 75051L, nrow(oc) == 146475L, nrow(mf) == 104113L, !anyDuplicated(ev$eventID),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"),
          all(ev$samplingProtocol == "Flemish butterfly monitoring scheme"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          uniqueN(ev$parentEventID) == 8906L, uniqueN(ev$locationID) == 112L, all(ev$dataGeneralizations %in% c("UTM 5km", "UTM 10km")),
          ev[, .(uniqueN(locationID), uniqueN(eventDate)), by = parentEventID][, all(V1 == 1L & V2 == 1L)],
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, locality)), by = locationID][, all(V1 == 1L)],
          all(oc$eventID %in% ev$eventID), all(oc$lifeStage == "imago"), all(oc$occurrenceStatus %in% c("present", "absent")),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), sum(oc$occurrenceStatus == "absent") == 36L,
          all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L), uniqueN(oc$scientificName) == 50L,
          sum(!ev$eventID %in% oc$eventID) == 8L)
ev[, year := as.integer(substr(eventDate, 1, 4))]
stopifnot(all(ev$year %in% 1991:2020))

# visits
vis <- ev[, .(locationID = locationID[1], date = eventDate[1], year = year[1], n_sec = .N), by = parentEventID]
setorder(vis, locationID, date, parentEventID)
vis[, occasion := seq_len(.N), by = .(locationID, year)]
# weather per visit (constant across a visit's sections)
m <- merge(mf[measurementType != ""], ev[, .(id = eventID, parentEventID)], by = "id")
stopifnot(m[, uniqueN(measurementValue), by = .(parentEventID, measurementType)][, all(V1 == 1L)],
          setequal(unique(m$measurementType), c("bewolking", "temperature", "windkracht")), sum(mf$measurementType == "") == 68915L, uniqueN(mf[measurementType == ""]$id) == 34683L)
w <- dcast(unique(m[, .(parentEventID, measurementType, measurementValue)]), parentEventID ~ measurementType, value.var = "measurementValue")
vis <- merge(vis, w, by = "parentEventID", all.x = TRUE)

# counts per visit and taxon, every recorded taxon at every visit
oc <- merge(oc, ev[, .(eventID, parentEventID)], by = "eventID")
cnt <- oc[, .(y = sum(as.integer(individualCount))), by = .(parentEventID, scientificName)]
tx <- data.table(scientificName = sort(unique(oc$scientificName)))
tx[, taxon := toupper(ifelse(scientificName == "Pieris spec.", "PIERIS_SP", paste0(substr(sub(" .*", "", scientificName), 1, 3),
                                                                                       substr(sub("^[^ ]+ ", "", scientificName), 1, 3))))]
stopifnot(!anyDuplicated(tx$taxon))
grid <- CJ(parentEventID = vis$parentEventID, scientificName = tx$scientificName)
cnt <- cnt[grid, on = .(parentEventID, scientificName)]
cnt[is.na(y), y := 0L]
cnt <- merge(cnt, tx, by = "scientificName")
cnt <- merge(cnt, vis, by = "parentEventID")
loc <- unique(ev[, .(locationID, locality, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)])
cnt <- merge(cnt, loc, by = "locationID")
years <- 1991:2020
long <- cnt[, .(unit = sub("^INBO:MEETNET:LOCATION:", "", locationID), taxon, y, period = match(year, years), occasion, date,
                unit_locality = locality, unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
                unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters),
                obs_n_sections_recorded = n_sec, obs_cloudiness = bewolking, obs_temperature = suppressWarnings(as.numeric(temperature)),
                obs_wind_bft = windkracht)]
long <- order_eco(long)
stopifnot(nrow(long) == 8906L * 50L, sum(long$y) == sum(as.integer(oc$individualCount)))
cat(sprintf("  %d rows: %d visits x %d taxa; %d imagos; %d visits with nothing counted\n", nrow(long), nrow(vis), nrow(tx),
            sum(long$y), long[, sum(y), by = .(unit, period, occasion)][V1 == 0, .N]))

vn <- unique(oc[, .(scientificName, vernacularName)])
stopifnot(!anyDuplicated(vn$scientificName))
tx <- merge(tx, vn, by = "scientificName")
taxa <- make_taxa(tx$taxon, ifelse(tx$scientificName == "Pieris spec.", "Pieris", tx$scientificName),
                  vernacularName = tx$vernacularName, taxonRank = ifelse(tx$taxon == "PIERIS_SP", "genus", "species"),
                  lookupName = ifelse(tx$taxon == "PIERIS_SP", "Pieris Schrank, 1801",
                                      ifelse(tx$taxon == "LIMCAM", "Limenitis camilla (Linnaeus, 1764)", tx$scientificName)),
                  taxonRemarks = ifelse(tx$taxon == "PIERIS_SP", "Recorded as 'Pieris spec.': whites not identified to species (Pieris brassicae, P. rapae, P. napi, P. mannii are also recorded); vernacularName is the source's Dutch name", "vernacularName is the source's Dutch name"))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
cat("  IUCN: ", paste(sprintf("%s=%s", taxa$taxon, iu)[iu %in% c("CR", "EN", "VU")], collapse = " "), "\n")
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]

dataset <- list(
  title = "Flemish butterfly monitoring scheme: Pollard-walk counts of 50 butterfly taxa on 112 routes, Flanders, Belgium, 1991-2020",
  creator = "Maes, Dirk; Piesschaert, Frederik; Brosens, Dimitri; Desmet, Peter (Research Institute for Nature and Forest, INBO)",
  pubDate = "2025", doi = "10.15468/wwrgcd", sourceURL = "https://doi.org/10.15468/wwrgcd",
  citation = "Maes D, Piesschaert F, Brosens D, Desmet P (2025). Butterfly monitoring scheme in Flanders, Belgium. Version 1.7. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/wwrgcd",
  intellectualRights = list(spdx = "CC-BY-NC-4.0", url = "https://creativecommons.org/licenses/by-nc/4.0/",
                            note = "GBIF registry and EML intellectualRights: CC BY-NC 4.0; EML abstract and event rows: CC0 1.0; the stricter governs"),
  abstract = "Butterfly transect counts (Pollard walks) of the Flemish butterfly monitoring scheme, run by INBO with volunteers since 1991: routes of up to 1 km in 50 m sections walked repeatedly through the flight season, every butterfly within the transect counted. One row per route visit and taxon: imagos counted on the visit summed over the sections, with the visit's weather.",
  samplingProtocol = "Pollard walk: a fixed route of up to 1 km divided into 50 m sections, walked at a steady pace in suitable weather through the flight season; all butterflies within a band along the route counted per section (Maes et al. 2019).",
  samplingProtocolCode = "transect_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "open", closureNote = "visits span the whole flight season (April to October), across which species emerge and decline",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Flanders, Belgium (route coordinates generalised by INBO to 5 km or 10 km UTM square centroids)",
  temporalCoverage = "1991/2020",
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO, a government agency) to the centroid of a 5 km (uncertainty in coordinateUncertaintyInMeters) or 10 km UTM square before publication; kept as published."),
  covariateNote = "obs_n_sections_recorded: number of the route's 50 m sections with a record on the visit (sections with nothing seen are not in the archive, so this is a lower bound on sections walked, not effort). obs_cloudiness (eighths, as text), obs_temperature (deg C), obs_wind_bft (Beaufort, as text) as deposited; NA where not recorded.",
  notShipped = list(sections = "section-level counts: the archive keeps a section only where something was seen (8 of 75,051 section events are empty), so the survey is the visit and counts are summed over sections",
                    undefined_measurements = "68,915 measurement rows (on 34,683 section events) with an empty measurementType",
                    model_output = "none in the source"),
  notes = "Routes can lose sections over the years (the protocol drops a section that becomes inaccessible or unsuitable), so a route's visit total is not a fixed-effort count. Most routes are walked in a subset of years.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))
stage_dict_row(TABLE,
  description = "Pollard-walk counts of 50 butterfly taxa on 112 routes of the Flemish butterfly monitoring scheme, Flanders, Belgium, 1991-2020, one row per route visit and taxon (sections summed), with visit weather.",
  url = "https://doi.org/10.15468/wwrgcd",
  reference = "Maes D, Piesschaert F, Brosens D, Desmet P (2025). Butterfly monitoring scheme in Flanders, Belgium. Version 1.7. INBO. https://doi.org/10.15468/wwrgcd",
  doi_paper = "", doi_data = "10.15468/wwrgcd",
  original_license = "CC BY-NC 4.0 (GBIF registry, EML intellectualRights) vs CC0 1.0 (EML abstract, event rows); stricter governs",
  derived_license = "CC BY-NC 4.0",
  notes = "INBO IPT DwC-A (bms-occurrences, v1.7). Visit = survey, sections summed (Pollard-walk rule). Coordinates generalised by INBO.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season, community)",
  sampling_protocol = "transect_count", design = sprintf("Multi-season (%d years x 1-%d visits; 112 routes)", uniqueN(long$period), max(long$occasion)),
  realm = "Terrestrial", country = "BEL", coordinates = "As published",
  notes = "Long-running national butterfly monitoring (Pollard walks), CC BY-NC.")
