#!/usr/bin/env Rscript
# Table:  lindstrom_2025_sweden_winterpoints_count
# Source: GBIF sampling-event dataset 78d97723-3ac0-460f-9d9e-b8e603489883, doi:10.15468/n5nuuc, version 1.7 (2025),
#         Department of Biology, Lund University, via the Swedish GBIF IPT (https://www.gbif.se/ipt/resource?r=lu_sft_vpkt).
#         Licence as shown on GBIF and in the EML: CC0 1.0 ("the publisher has waived all rights to these data").
#         Citation: Lindström Å, Green M, Jönsson A (2025). Swedish Bird Survey: Winter point count routes
#         (Vinterpunktrutterna). Version 1.7. Department of Biology, Lund University. Sampling event dataset.
#         https://doi.org/10.15468/n5nuuc
# Paper:  none specific; the Swedish Bird Survey's winter point count routes, started 1975 (Lund University annual
#         reports). Companion of lindstrom_2025_sweden_summerpoints_count (same publisher, same route layout).
# Data:   Darwin Core Archive, event core with occurrence and extended measurement-or-fact extensions.
#         event.txt (39,900 rows): 49 'season' events (winters 1975-1976 to 2023-2024), 245 'period' events (five survey
#           periods per winter, each about three weeks: 1 October-November start, 2 November, 3 around Christmas-New
#           Year, 4 late January-February, 5 March) and 39,606 'event' rows, one per route count:
#           eventID SFTvpkt:<yyyymmdd>:<routeId>, parentEventID the survey period, eventDate a one-day range,
#           eventTime start/end, startDayOfYear, locality SFTpkt:siteId:<routeId> (2,452 routes, 1:1 with locationID),
#           county, decimalLatitude/Longitude = the centre of the 25 x 25 km grid square containing the route
#           (coordinateUncertaintyInMeters 17,700); informationWithheld lists eleven security-class-4 species not shown.
#         occurrence.txt (899,774 rows): individuals per taxon per route count, 'the sum total from all of the twenty
#           points on the route'; 899,768 present rows (887,115 species, 12,486 genus: Loxia, Larus, Passer; 167
#           Acanthis flammea exilipes, a subspecies) and 6 'Aves' absent rows, one for each count that saw no bird
#           (noObservations = true on exactly those 6 events, asserted). recordedBy one observer per event.
#         extendedmeasurementorfact.txt: per event noObservations, locationProtected ('no'), locationType ('Point'),
#           snowIceCover (23,752 events), transportMethod (23,708 events); per occurrence euTaxonID.
#         Protocol (EML): free-choice routes of 20 points, 5 minutes per point, all birds seen or heard counted; a
#           route may be counted in any of the five survey periods of a winter, once per period.
# Mapping (repeated counts within winters, bird community; responseType count): unit = route (R<routeId>), period =
#   winter (1975-1976 .. 2023-2024 as 1..49), occasion = survey period within the winter (1..5, from parentEventID;
#   one count per route per survey period, asserted), date = eventDate, observer = recordedBy, obs_start_time /
#   obs_end_time (HH:MM, NA where not given), obs_snow_cover, obs_transport (NA where not recorded), unit_county,
#   unit_ coordinates (25 km grid-square centre as published). taxon = the 262 taxa recorded (genus-level Loxia, Larus
#   and Passer and the subspecies exilipes are their own taxa, as recorded). y = route total of individuals.
#   surveyEvidence = sample_table: the event core lists every route count and the protocol counts all birds, so a taxon
#   without a row at a count was counted zero; the 6 empty counts are published (noObservations). taxonInclusion
#   recorded; taxaWithheld = the eleven security-class-4 species (no rows; their absence is not a zero).
#   39,606 counts x 262 taxa = 10.4 million rows: written in winter parts with write_table_parts() (E4).
#   Coordinates: the source publishes only 25 x 25 km grid-square centres (coarser than 0.1 degree); kept.
# Not shipped: the 'Aves' zero rows (empty counts, y = 0 for every taxon); euTaxonID; locationProtected and
#   locationType (constants); the 20-point structure (not deposited); the eleven withheld species (not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lindstrom_2025_sweden_winterpoints_count"
zip <- download_cached("https://www.gbif.se/ipt/archive.do?r=lu_sft_vpkt", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("78d97723-3ac0-460f-9d9e-b8e603489883/v1.7", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character",
            select = c("eventID", "taxonID", "scientificName", "taxonRank", "genus", "specificEpithet", "vernacularName",
                       "individualCount", "organismQuantity", "organismQuantityType", "occurrenceStatus", "occurrenceRemarks", "recordedBy"))
mf <- fread(file.path(dwca, "extendedmeasurementorfact.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 39900L, nrow(oc) == 899774L, !anyDuplicated(ev$eventID),
          sum(ev$eventType == "season") == 49L, sum(ev$eventType == "period") == 245L)
ev <- ev[eventType == "event"]
stopifnot(nrow(ev) == 39606L, all(ev$samplingProtocol == "point transect survey"), all(grepl("^SFTvpkt:\\d{8}:\\d+$", ev$eventID)),
          all(grepl("^SFTvpkt:\\d{4}-\\d{4}:per[1-5]$", ev$parentEventID)), all(grepl("^SFTpkt:siteId:\\d+$", ev$locality)),
          all(sub("^SFTvpkt:\\d{8}:", "", ev$eventID) == sub("^SFTpkt:siteId:", "", ev$locality)),
          all(substr(ev$eventDate, 1, 10) == substr(ev$eventDate, 12, 21)),
          all(substr(ev$eventID, 9, 16) == gsub("-", "", substr(ev$eventDate, 1, 10))),
          uniqueN(ev$locationID) == 2452L, nrow(unique(ev[, .(locationID, locality)])) == 2452L,
          nrow(unique(ev[, .(locationID, county, decimalLatitude, decimalLongitude)])) == 2452L,
          all(ev$coordinateUncertaintyInMeters == "17700"), all(ev$geodeticDatum == "EPSG:4326"), uniqueN(ev$locationRemarks) == 1L)
withheld <- c("Anser erythropus", "Aquila chrysaetos", "Clanga clanga", "Haliaeetus albicilla", "Circus macrourus", "Falco peregrinus",
              "Falco rusticolus", "Tyto alba", "Bubo bubo", "Bubo scandiacus", "Dendrocopos leucotos")
stopifnot(all(vapply(withheld, function(s) grepl(s, ev$informationWithheld[1], fixed = TRUE), TRUE)), !any(oc$scientificName %in% withheld))
stopifnot(all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID), all(oc$organismQuantityType == "individuals"),
          all(oc$individualCount == oc$organismQuantity), uniqueN(oc$occurrenceRemarks) == 1L,
          grepl("sum total from all of the twenty points", oc$occurrenceRemarks[1]),
          oc[scientificName == "Aves", all(individualCount == "0" & occurrenceStatus == "absent")], sum(oc$scientificName == "Aves") == 6L,
          oc[scientificName != "Aves", all(occurrenceStatus == "present" & as.integer(individualCount) >= 1L)],
          oc[, sum(scientificName == "Aves") == 0L | .N == 1L, by = eventID][, all(V1)], !anyDuplicated(oc[, .(eventID, taxonID)]),
          oc[recordedBy != "", uniqueN(recordedBy), by = eventID][, all(V1 == 1L)],
          setequal(oc[taxonRank == "genus", unique(scientificName)], c("Loxia", "Larus", "Passer")),
          oc[taxonRank == "subspecies", unique(scientificName)] == "Acanthis flammea exilipes")
evm <- mf[measurementType != "euTaxonID"]
stopifnot(evm[, .N, by = .(id, measurementType)][, all(N == 1L)],
          setequal(evm[measurementType == "noObservations" & measurementValue == "true", id], oc[scientificName == "Aves", eventID]),
          all(evm[measurementType == "locationProtected", measurementValue] == "no"), all(evm[measurementType == "locationType", measurementValue] == "Point"))

# surveys
ev[, `:=`(winter = sub("^SFTvpkt:(\\d{4}-\\d{4}):per\\d$", "\\1", parentEventID), occasion = as.integer(sub("^.*:per", "", parentEventID)),
          unit = paste0("R", sub("^SFTpkt:siteId:", "", locality)), date = substr(eventDate, 1, 10))]
winters <- sprintf("%d-%d", 1975:2023, 1976:2024)
stopifnot(all(ev$winter %in% winters), !anyDuplicated(ev[, .(unit, winter, occasion)]),
          all(as.integer(substr(ev$date, 1, 4)) %in% as.integer(substr(ev$winter, c(1, 6), c(4, 9)))))
ev[, period := match(winter, winters)]
tm <- "^(\\d{2}:\\d{2})?/(\\d{2}:\\d{2})?$"
stopifnot(all(grepl(tm, ev$eventTime) | ev$eventTime == ""))
ev[, obs_start_time := ifelse(grepl(tm, eventTime) & sub(tm, "\\1", eventTime) != "", sub(tm, "\\1", eventTime), NA_character_)]
ev[, obs_end_time := ifelse(grepl(tm, eventTime) & sub(tm, "\\2", eventTime) != "", sub(tm, "\\2", eventTime), NA_character_)]
ev <- merge(ev, evm[measurementType == "transportMethod", .(eventID = id, obs_transport = measurementValue)], by = "eventID", all.x = TRUE)
ev <- merge(ev, evm[measurementType == "snowIceCover", .(eventID = id, obs_snow_cover = measurementValue)], by = "eventID", all.x = TRUE)
ev <- merge(ev, unique(oc[recordedBy != "", .(eventID, observer = sub("^SFT:recorderId:", "O", recordedBy))]), by = "eventID", all.x = TRUE)
ev[, `:=`(unit_county = county, unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
          unit_coordinateUncertaintyInMeters = 17700L)]
stopifnot(nrow(ev) == 39606L, sum(!is.na(ev$obs_transport)) == 23708L, sum(!is.na(ev$obs_snow_cover)) == 23752L)

# taxa
sp <- unique(oc[scientificName != "Aves", .(taxonID, scientificName, taxonRank, genus, specificEpithet, vernacularName)])
stopifnot(nrow(sp) == 262L, !anyDuplicated(sp$scientificName), !anyDuplicated(sp$taxonID))
sp[, taxon := toupper(paste0(substr(genus, 1, 3), substr(ifelse(specificEpithet == "", "spp", specificEpithet), 1, 3)))]
sp[taxonRank == "subspecies", taxon := toupper(paste0(substr(genus, 1, 3), substr(sub("^.* ", "", scientificName), 1, 3)))]
dup <- sp[taxon %in% sp[duplicated(taxon), taxon]]
cat("  code collisions: ", paste(dup$scientificName, collapse = "; "), "\n")
fix <- c("Corvus cornix" = "CORCNX", "Corvus corax" = "CORCRX", "Corvus corone" = "CORCRN", "Saxicola rubetra" = "SAXRBT",
         "Saxicola rubicola" = "SAXRBC", "Sterna paradisaea" = "STEPRD", "Stercorarius parasiticus" = "STCPAR")   # as the summer table, plus Saxicola
stopifnot(setequal(dup$scientificName, names(fix)))
sp[scientificName %in% names(fix), taxon := fix[scientificName]]
stopifnot(!anyDuplicated(sp$taxon))
setorder(sp, taxon)
oc <- merge(oc[scientificName != "Aves", .(eventID, taxonID, y = as.integer(individualCount))], sp[, .(taxonID, taxon)], by = "taxonID")
stopifnot(nrow(oc) == 899768L)
lookup <- sp$scientificName
lookup[lookup == "Chloris chloris"] <- "Chloris chloris (Linnaeus, 1758)"
lookup[lookup == "Phylloscopus sibilatrix"] <- "Phylloscopus sibillatrix"
rank <- sp$taxonRank
taxa <- make_taxa(sp$taxon, sp$scientificName, vernacularName = sp$vernacularName, taxonRank = rank, lookupName = lookup,
                  taxon_dyntaxaID = sp$taxonID,
                  taxonRemarks = fifelse(sp$taxonRank == "genus", "registered at genus, as recorded; the species-level records of the genus are their own taxa; vernacularName Swedish",
                                         fifelse(sp$taxonRank == "subspecies", "Arctic redpoll registered as a subspecies of Acanthis flammea, as recorded; vernacularName Swedish",
                                                 "vernacularName is the source's Swedish name")),
                  allow_higher = setdiff(sp[taxonRank == "genus", taxon], "PASSPP"), no_key = "PASSPP")
# Passer is a homonym on the GBIF backbone (the strict match falls to a phylum); matched with Passeridae as a hint
h <- gbif_taxon_hinted("Passer", list(kingdom = "Animalia", class = "Aves", family = "Passeridae"))
stopifnot(identical(h$canonicalName, "Passer"), identical(h$kingdom, "Animalia"), identical(h$rank, "genus"))
taxa[taxon == "PASSPP", `:=`(taxonID = h$taxonID, gbifMatchType = paste0(h$matchType, " (hinted)"),
     taxonRemarks = paste0(taxonRemarks, "; a homonym on the GBIF backbone, matched with family Passeridae as a hint"))]
stopifnot(!any(kingdom_taxonID(taxa$taxonID)), !anyNA(taxa$taxonID))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
flag <- taxa[iu %in% c("CR", "EN", "VU"), sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  IUCN CR/EN/VU: ", paste(flag, collapse = "; "), "\n")
periods <- ev[, .(n_counts = .N, n_routes = uniqueN(unit)), by = .(period, winter)][order(period)]
units <- ev[, .(station_register_url = unique(locationID), first_winter = winters[min(period)], last_winter = winters[max(period)],
                n_counts = .N), by = unit][order(unit)]
stopifnot(nrow(periods) == 49L, nrow(units) == 2452L)

evcols <- ev[, .(eventID, unit, period, occasion, date, observer, unit_county, unit_decimalLatitude, unit_decimalLongitude,
                 unit_coordinateUncertaintyInMeters, obs_start_time, obs_end_time, obs_snow_cover, obs_transport)]
build <- function(ps) {
  e <- evcols[period %in% ps]
  l <- e[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(e))]
  l <- merge(l, oc[eventID %in% e$eventID, .(eventID, taxon, y)], by = c("eventID", "taxon"), all.x = TRUE)
  l[is.na(y), y := 0L]
  stopifnot(nrow(l) == nrow(e) * nrow(sp), sum(l$y) == sum(oc[eventID %in% e$eventID]$y))
  l[, eventID := NULL]
  setcolorder(l, c("unit", "taxon", "y", "period", "occasion", "date", "observer"))
  l
}
parts <- split(1:49, ceiling(seq_along(1:49) / 10))
dataset <- list(
  title = sprintf("Swedish Bird Survey winter point count routes: route totals of %d bird taxa on %s routes, five survey periods a winter, 1975-2024", nrow(sp), format(nrow(units), big.mark = ",")),
  creator = "Lindström, Åke; Green, Martin; Jönsson, Annelie (Department of Biology, Lund University)", pubDate = "2025",
  doi = "10.15468/n5nuuc", sourceURL = "https://doi.org/10.15468/n5nuuc",
  citation = "Lindström Å, Green M, Jönsson A (2025). Swedish Bird Survey: Winter point count routes (Vinterpunktrutterna). Version 1.7. Department of Biology, Lund University. Sampling event dataset. https://doi.org/10.15468/n5nuuc",
  intellectualRights = list(spdx = "CC0-1.0", url = "http://creativecommons.org/publicdomain/zero/1.0/legalcode"),
  abstract = "The winter point count routes (vinterpunktrutterna) of the Swedish Bird Survey, run by Lund University since 1975: volunteers count all birds seen or heard for 5 minutes at each of 20 self-chosen points, in up to five fixed survey periods per winter (October-November, November, Christmas-New Year, January-February, March). The deposit gives one event per route count with the total individuals per taxon over the 20 points, the observer id, date, times, transport, snow cover, county and the centre of the 25 x 25 km grid square containing the route. Eleven security-class-4 species are withheld by the publisher.",
  samplingProtocol = "Point count route: 20 points, 5 minutes per point, all birds seen or heard registered; one count per route in any of five three-week survey periods per winter; y is the route total of individuals per taxon (summed by the source).",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "period = winter (October to March); occasion = the scheme's survey period (1-5), across which wintering populations change (migration, weather); at most one count per route per survey period",
  occasionKind = "time", taxonInclusion = "recorded", taxaWithheld = withheld,
  geographicCoverage = "Sweden, all counties, concentrated in the south (route positions as 25 x 25 km grid-square centres)",
  temporalCoverage = sprintf("%s/%s", substr(min(ev$date), 1, 7), substr(max(ev$date), 1, 7)), crs = "EPSG:4326",
  coordinatesCoarsened = list(value = TRUE, method = sprintf("by the source: the centre of the 25 x 25 km survey grid square containing the route (coordinateUncertaintyInMeters 17,700), coarser than the 0.1 degree rule; IUCN-listed taxa in the table: %s", if (length(flag)) paste(flag, collapse = ", ") else "none")),
  surveyEvidenceNote = "The event core lists every route count; the protocol registers every bird at every point, and the 6 counts that saw no bird are published (noObservations = true), so a taxon absent from a count's occurrences was counted zero.",
  covariateNote = "obs_snow_cover and obs_transport as the source records them, NA where not recorded; obs_start_time/obs_end_time HH:MM, NA where not given; observer = pseudonymous recorder id.",
  notes = "Genus-level Loxia, Larus and Passer and the subspecies Acanthis flammea exilipes are taxa as recorded; their species-level records are separate taxa. Names are the source's (Dyntaxa) spelling; vernacularName is Swedish. Companion of lindstrom_2025_sweden_summerpoints_count. Stored in winter parts (E4).",
  notShipped = list(
    withheld_species = paste("eleven security-class-4 species are not in the deposit:", paste(withheld, collapse = ", "), "- no rows; their absence is not a zero"),
    `Aves zero rows` = "6 placeholder rows marking counts with no bird; those counts are y = 0 for every taxon",
    point_level = "the 20 points per route are summed by the source",
    euTaxonID = "EU Article 12 species codes per occurrence (eMoF)",
    locationProtected_locationType = "constants (no / Point)"))
ds <- write_table_parts(parts, build, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Route totals of %d bird taxa on %s counts of %s Swedish Bird Survey winter point count routes (20 points x 5 minutes, up to five survey periods a winter), winters 1975-1976 to 2023-2024.", nrow(sp), format(nrow(ev), big.mark = ","), format(nrow(units), big.mark = ",")),
  url = "https://doi.org/10.15468/n5nuuc",
  reference = "Lindström Å, Green M, Jönsson A (2025). Swedish Bird Survey: Winter point count routes (Vinterpunktrutterna). Version 1.7. Department of Biology, Lund University. https://doi.org/10.15468/n5nuuc",
  doi_paper = "", doi_data = "10.15468/n5nuuc", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Swedish GBIF IPT DwC-A (lu_sft_vpkt v1.7). Survey set = event core; survey period as occasion. Eleven security-class-4 species withheld by the publisher. 25 km grid-square centres as published. Stored in winter parts.",
  source_via = "GBIF (Swedish GBIF IPT, Lund University)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (49 winters x up to 5 survey periods; 20 points summed)", realm = "Terrestrial", country = "SWE",
  coordinates = "Coarsened (by the source: 25 x 25 km grid centres)", notes = "National volunteer winter scheme, free-choice routes; 11 species withheld by the publisher.")
