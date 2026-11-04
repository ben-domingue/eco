#!/usr/bin/env Rscript
# Table:  lindstrom_2025_sweden_summerpoints_count
# Source: GBIF sampling-event dataset 7059595f-0e00-4bd6-bfa9-8869dd6b6096, doi:10.15468/2aajk9,
#         version 1.8 (published 2025-07-10), Department of Biology, Lund University, via the
#         Swedish GBIF IPT (https://www.gbif.se/ipt/resource?r=lu_sft_spkt). Licence as shown on
#         GBIF and in the EML: CC0 1.0 ("the publisher has waived all rights to these data").
#         Citation: Lindström Å, Green M, Jönsson A (2025). Swedish Bird Survey: Summer point
#         count routes (Sommarpunktrutterna). Version 1.8. Department of Biology, Lund University.
#         Sampling event dataset https://doi.org/10.15468/2aajk9.
# Paper:  none specific; the scheme is the Swedish Bird Survey (Svensk Fågeltaxering), summer point
#         count routes started 1975 (Lindström, Green et al., annual reports; e.g. Lindström Å,
#         Green M (2025) Övervakning av fåglarnas populationsutveckling, Lund University).
# Data:   Darwin Core Archive, event core with two extensions.
#         event.txt (11,011 rows): one row per route x year count ("point transect survey"):
#           eventID SFTspkt:<yyyymmdd>:<routeId>, eventDate as a one-day range (72 night counts
#           span midnight and have a two-day range), eventTime start/end (3 empty, 5 without start, 24 without end),
#           startDayOfYear, locationID (a station-register URL), locality SFTpkt:siteId:<routeId>
#           (1,256 routes, 1:1 with locationID), county (21), decimalLatitude/Longitude EPSG:4326
#           = the centre of the 25 x 25 km survey grid square that contains the route
#           (locationRemarks; coordinateUncertaintyInMeters 17,700), informationWithheld: eleven
#           security-class-4 species are not shown (black stork, lesser white-fronted goose,
#           golden, spotted and white-tailed eagle, pallid and Montagu's harrier, peregrine,
#           gyrfalcon, eagle owl, white-backed woodpecker).
#         occurrence.txt (490,869 rows): one row per species per event with individualCount
#           (= organismQuantity, individuals, 1 to 5,176), occurrenceStatus present only,
#           occurrenceRemarks "sum total from all of the twenty points on the route", recordedBy
#           SFT:recorderId:<n> (712 observers, one per event), taxonID (Dyntaxa LSID), scientificName,
#           taxonRank (269 species; Loxia at genus, 2,429 rows, the protocol allows crossbills at
#           genus), vernacularName (Swedish). No species appears twice in an event.
#         extendedmeasurementorfact.txt (528,115 rows): per event locationProtected (all "no"),
#           locationType (all "Point"), noObservations (all "false"), transportMethod (4 classes,
#           140 events without); per occurrence euTaxonID (Article 12 code, 484,211 rows).
#
# Mapping (standard E9 core, "repeated-count indices with within-route replication" without the
# within-route replication: the deposit sums the 20 points, so one count per route per year):
#   unit = route (R<routeId>), period = year (1 = 1975 ... 50 = 2024, __periods with the year and
#   the number of routes counted), no occasion (one visit per year), taxon = six-letter code from
#   genus + epithet (seven collisions resolved explicitly, LOXSPP for Loxia), y = individualCount
#   summed over the route's 20 points (responseType count, N-mixture family across years with
#   closure "period" only in the index sense). The survey set is the event core (surveyEvidence =
#   sample_table): the protocol registers all birds seen or heard identified to species at every
#   point, every event has noObservations = false and at least one occurrence, so a species
#   without a row at an event was counted zero. date = the count's start date, observer =
#   recordedBy, obs_start_time, obs_end_time (HH:MM, NA where incomplete), obs_day_of_year,
#   obs_transport (on foot or skis / by bike or moped / by car or motorcycle / other / NA);
#   unit_county, unit_decimalLatitude/Longitude (the 25 km grid-square centre as published),
#   unit_coordinateUncertaintyInMeters = 17700; __units carries the station-register URL and the
#   route's first/last year and years counted.
#   Coordinates: already coarsened by the source to 25 x 25 km grid centres (coarser than the
#   0.1 degree rule), so nothing further although VU species (Aythya ferina, Melanitta fusca,
#   Streptopelia turtur) are in the table. Not shipped: the eleven withheld species (absent from
#   the deposit, so their zeros are not zeros: documented), euTaxonID, locationProtected,
#   locationType (constant), the 20-point structure (not deposited), biotope data (on request).
#   v1.1: closure = none, occasionKind = none (one count per route-year), taxonInclusion =
#   recorded, taxaWithheld = the eleven security-class-4 species (E10); LOXSPP carries
#   taxonRemarks (genus-rank record). Not E7.3: the source itself publishes only 25 km centres.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lindstrom_2025_sweden_summerpoints_count"
zip <- download_cached("https://www.gbif.se/ipt/archive.do?r=lu_sft_spkt", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(file.exists(file.path(dwca, c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml"))))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("Public Domain \\(CC0 1.0\\)", eml)), any(grepl("<identifier>CC0-1.0</identifier>", eml)))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "extendedmeasurementorfact.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 11011, nrow(oc) == 490869, nrow(mf) == 528115, !anyDuplicated(ev$eventID),
          all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID))
stopifnot(all(ev$samplingProtocol == "point transect survey"), all(ev$geodeticDatum == "EPSG:4326"),
          all(ev$coordinateUncertaintyInMeters == "17700"), all(ev$decimalLatitude != ""), uniqueN(ev$locationRemarks) == 1,
          all(grepl("^SFTspkt:\\d{8}:\\d+$", ev$eventID)), all(grepl("^SFTpkt:siteId:\\d+$", ev$locality)),
          all(sub("^SFTspkt:\\d{8}:", "", ev$eventID) == sub("^SFTpkt:siteId:", "", ev$locality)),
          all(substr(ev$eventID, 9, 16) == gsub("-", "", substr(ev$eventDate, 1, 10))),
          uniqueN(ev$locationID) == 1256, nrow(unique(ev[, .(locationID, locality)])) == 1256,
          nrow(unique(ev[, .(locationID, county, decimalLatitude, decimalLongitude)])) == 1256, uniqueN(ev$county) == 21)
stopifnot(all(oc$basisOfRecord == "HumanObservation"), all(oc$occurrenceStatus == "present"),
          all(oc$organismQuantityType == "individuals"), all(oc$individualCount == oc$organismQuantity),
          all(as.integer(oc$individualCount) >= 1), !anyDuplicated(oc[, .(eventID, taxonID)]),
          uniqueN(oc$occurrenceRemarks) == 1, grepl("sum total from all of the twenty points", oc$occurrenceRemarks[1]),
          oc[, uniqueN(recordedBy), by = eventID][, all(V1 == 1)], all(oc$taxonRank %in% c("species", "genus")),
          oc[taxonRank == "genus", unique(scientificName)] == "Loxia", oc[taxonRank == "genus", .N] == 2429)
evm <- mf[measurementType != "euTaxonID"]
stopifnot(all(evm$occurrenceID == ""), evm[, .N, by = .(id, measurementType)][, all(N == 1)],
          all(evm[measurementType == "noObservations", measurementValue] == "false"),
          all(evm[measurementType == "locationProtected", measurementValue] == "no"),
          all(evm[measurementType == "locationType", measurementValue] == "Point"),
          setequal(evm[measurementType == "transportMethod", unique(measurementValue)],
                   c("on foot or skis", "by bike or moped", "by car or motorcycle", "other")))
withheld <- c("Ciconia nigra", "Anser erythropus", "Aquila chrysaetos", "Clanga clanga", "Haliaeetus albicilla",
              "Circus macrourus", "Circus pygargus", "Falco peregrinus", "Falco rusticolus", "Bubo bubo", "Dendrocopos leucotos")
stopifnot(all(vapply(withheld, function(s) grepl(s, ev$informationWithheld[1], fixed = TRUE), TRUE)), !any(oc$scientificName %in% withheld))

# surveys: one route count per event
ev[, year := as.integer(substr(eventDate, 1, 4))]
stopifnot(all(ev$year %in% 1975:2024), !anyDuplicated(ev[, .(locationID, year)]),
          sum(substr(ev$eventDate, 1, 10) != substr(ev$eventDate, 12, 21)) == 72, all(as.integer(substr(ev$eventDate, 6, 7)) %in% 4:7))
ev[, unit := paste0("R", sub("^SFTpkt:siteId:", "", locality))]
ev[, period := year - 1974L]
ev[, date := substr(eventDate, 1, 10)]
tm <- "^(\\d{2}:\\d{2})?/(\\d{2}:\\d{2})?$"
stopifnot(all(grepl(tm, ev$eventTime) | ev$eventTime == ""))
ev[, obs_start_time := ifelse(grepl(tm, eventTime) & sub(tm, "\\1", eventTime) != "", sub(tm, "\\1", eventTime), NA_character_)]
ev[, obs_end_time := ifelse(grepl(tm, eventTime) & sub(tm, "\\2", eventTime) != "", sub(tm, "\\2", eventTime), NA_character_)]
stopifnot(sum(ev$eventTime == "") == 3, sum(is.na(ev$obs_start_time)) == 8, sum(is.na(ev$obs_end_time)) == 27)   # 3 empty, 5 missing start, 24 missing end
ev[, obs_day_of_year := as.integer(startDayOfYear)]
stopifnot(all(ev$obs_day_of_year == as.POSIXlt(as.Date(ev$date))$yday + 1L))
transport <- evm[measurementType == "transportMethod", .(eventID = id, obs_transport = measurementValue)]
ev <- merge(ev, transport, by = "eventID", all.x = TRUE)
stopifnot(sum(is.na(ev$obs_transport)) == 11011 - 10871)
obs <- oc[, .(eventID, observer = recordedBy)][!duplicated(eventID)]
ev <- merge(ev, obs, by = "eventID")
ev[, unit_decimalLatitude := as.numeric(decimalLatitude)][, unit_decimalLongitude := as.numeric(decimalLongitude)]
stopifnot(all(ev$unit_decimalLatitude > 55 & ev$unit_decimalLatitude < 69.1), all(ev$unit_decimalLongitude > 10.9 & ev$unit_decimalLongitude < 24.2))
ev[, unit_county := county][, unit_coordinateUncertaintyInMeters := 17700L]
cat(sprintf("  %d route counts on %d routes, %d-%d, %d observers\n", nrow(ev), uniqueN(ev$unit), min(ev$year), max(ev$year), uniqueN(ev$observer)))

# taxa: six-letter codes from genus + epithet; collisions resolved explicitly
sp <- unique(oc[, .(taxonID, scientificName, taxonRank, genus, specificEpithet, vernacularName)])
stopifnot(nrow(sp) == 270, !anyDuplicated(sp$scientificName), !anyDuplicated(sp$taxonID))
sp[, taxon := toupper(paste0(substr(genus, 1, 3), substr(ifelse(specificEpithet == "", "spp", specificEpithet), 1, 3)))]
fix <- c("Corvus cornix" = "CORCNX", "Corvus corax" = "CORCRX", "Corvus corone" = "CORCRN",
         "Phylloscopus trochilus" = "PHYTRL", "Phylloscopus trochiloides" = "PHYTRD",
         "Sterna paradisaea" = "STEPRD", "Stercorarius parasiticus" = "STCPAR")
stopifnot(setequal(sp[taxon %in% sp[duplicated(taxon), taxon], scientificName], names(fix)))
sp[scientificName %in% names(fix), taxon := fix[scientificName]]
stopifnot(!anyDuplicated(sp$taxon), sp[scientificName == "Loxia", taxon] == "LOXSPP")
setorder(sp, taxon)
oc <- merge(oc, sp[, .(taxonID, taxon)], by = "taxonID")
oc[, y := as.integer(individualCount)]

# long table: every taxon at every route count
long <- ev[, .(eventID, unit, taxon = NA_character_, period, date, observer, unit_county, unit_decimalLatitude, unit_decimalLongitude,
               unit_coordinateUncertaintyInMeters, obs_day_of_year, obs_start_time, obs_end_time, obs_transport)]
long <- long[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(ev))]
long <- merge(long, oc[, .(eventID, taxon, y)], by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(nrow(long) == nrow(ev) * nrow(sp), sum(long$y) == sum(oc$y), !anyNA(long$y), sum(long$y > 0) == nrow(oc))
long[, eventID := NULL]
long <- order_eco(long)
cat(sprintf("  %s rows = %d counts x %d taxa; %d non-zero\n", format(nrow(long), big.mark = ","), nrow(ev), nrow(sp), nrow(oc)))

# GBIF strict match returns "multiple equal matches" for the bare binomial Chloris chloris (a plant genus homonym); the authorship resolves it
lookup <- ifelse(sp$scientificName == "Chloris chloris", "Chloris chloris (Linnaeus, 1758)", sp$scientificName)
# GBIF's backbone spells the wood warbler with Bechstein's original double l (FUZZY otherwise): same species
lookup[lookup == "Phylloscopus sibilatrix"] <- "Phylloscopus sibillatrix"
taxa <- make_taxa(sp$taxon, sp$scientificName, vernacularName = sp$vernacularName, taxonRank = sp$taxonRank,
                  lookupName = lookup, taxon_dyntaxaID = sp$taxonID,
                  taxonRemarks = fifelse(sp$taxon == "LOXSPP", "crossbills registered at genus, as the protocol allows; the species-level Loxia records are their own taxa", NA_character_))
stopifnot(!anyNA(taxa$taxonID))
periods <- ev[, .(year = unique(year), n_routes = uniqueN(unit)), by = period][order(period)]
stopifnot(nrow(periods) == 50, all(periods$year == 1974L + periods$period))
units <- ev[, .(station_register_url = unique(locationID), county = unique(unit_county),
                decimalLatitude = unique(unit_decimalLatitude), decimalLongitude = unique(unit_decimalLongitude),
                coordinateUncertaintyInMeters = 17700L, first_year = min(year), last_year = max(year), n_years = .N), by = unit][order(unit)]
stopifnot(nrow(units) == 1256)

dataset <- list(
  title = "Swedish Bird Survey summer point count routes: route totals of all bird species, 1,256 free-choice routes of 20 points, 1975-2024",
  creator = "Lindström, Åke; Green, Martin; Jönsson, Annelie (Department of Biology, Lund University)", pubDate = "2025-07-10",
  doi = "10.15468/2aajk9", sourceURL = "https://www.gbif.org/dataset/7059595f-0e00-4bd6-bfa9-8869dd6b6096",
  citation = "Lindström Å, Green M, Jönsson A (2025). Swedish Bird Survey: Summer point count routes (Sommarpunktrutterna). Version 1.8. Department of Biology, Lund University. Sampling event dataset https://doi.org/10.15468/2aajk9 accessed via GBIF.org.",
  intellectualRights = list(spdx = "CC0-1.0", url = "http://creativecommons.org/publicdomain/zero/1.0/legalcode"),
  abstract = "The summer point count routes (sommarpunktrutterna) of the Swedish Bird Survey, run by Lund University since 1975: volunteer ornithologists count all birds seen or heard for 5 minutes at each of 20 self-chosen points at least 200-300 m apart, once per year in the breeding season (April to mid-July), ideally on the same date, start time and point order each year. Routes are personal and end when the surveyor stops; new routes start. The deposit gives one event per route per year with the total individuals per species over the 20 points (the point level is not deposited), the observer id, date, start and end time, transport between points, county, and the centre of the 25 x 25 km grid square containing the route. Eleven security-class-4 species are withheld by the publisher.",
  samplingProtocol = "Point count route: 20 points at least 200 m (forest) or 300 m (open) apart, 5 minutes per point, all birds seen or heard registered and identified to species (crossbills may be registered as Loxia), one count per route per year in April to July; y is the route total of individuals per species.",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "none", closureNote = "period = calendar year (one count per route per year; no occasion); the 20 points per route are summed by the source, so there is no within-year replication",
  occasionKind = "none", taxonInclusion = "recorded",
  taxaWithheld = c("Ciconia nigra", "Anser erythropus", "Aquila chrysaetos", "Clanga clanga", "Haliaeetus albicilla", "Circus macrourus",
                   "Circus pygargus", "Falco peregrinus", "Falco rusticolus", "Bubo bubo", "Dendrocopos leucotos"),
  geographicCoverage = "Sweden, all 21 counties, concentrated in the southern half (55.0-69.1 N, 11.0-24.2 E; route positions given as 25 x 25 km grid-square centres)",
  temporalCoverage = "1975-04-12/2024-07-02", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = TRUE, method = "by the source: the centre of the 25 x 25 km survey grid square containing the route (coordinateUncertaintyInMeters 17,700), coarser than the 0.1 degree rule; VU taxa (Aythya ferina, Melanitta fusca, Streptopelia turtur) are in the table"),
  effortColumn = NA,
  surveyEvidenceNote = "The event core lists every route count; the protocol registers every bird identified to species at every point, every event has noObservations = false and at least one species, and the occurrence remark states that counts are the sum over the 20 points, so a species absent from an event's occurrences was counted zero.",
  notShipped = list(
    withheld_species = "eleven security-class-4 species are not in the deposit (Ciconia nigra, Anser erythropus, Aquila chrysaetos, Clanga clanga, Haliaeetus albicilla, Circus macrourus, Circus pygargus, Falco peregrinus, Falco rusticolus, Bubo bubo, Dendrocopos leucotos); they have no rows here and their absence is not a zero",
    point_level = "the 20 points per route are not deposited; only the route total",
    euTaxonID = "EU Article 12 species codes per occurrence (eMoF)",
    locationProtected_locationType = "constant per event (no / Point)",
    biotope = "per-point biotope data available from the provider on request, not in the deposit"),
  notes = "Route ids are the source's siteId with an R prefix; __units carries the station-register URL. observer is the source's pseudonymous recorder id. 72 night counts span midnight (date is the start date). Loxia (crossbills) is a genus-level taxon the protocol allows. Species names are the source's (Dyntaxa) spelling; gbifAcceptedName gives GBIF's accepted name where it differs. The design is an annual index (one count per route-year); N-mixture models across years need the closure assumption stated by the user.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/lindstrom_2025_sweden_summerpoints_count.R")

stage_dict_row(TABLE,
  description = "Route totals of 270 bird taxa on 11,011 annual counts of 1,256 Swedish Bird Survey summer point count routes (20 points x 5 minutes, free-choice routes, 1975-2024), with date, start/end time, observer id, transport, county and 25 km grid-square centre; built from the GBIF Darwin Core event core (survey set) and per-species occurrence records.",
  url = "https://www.gbif.org/dataset/7059595f-0e00-4bd6-bfa9-8869dd6b6096",
  reference = "Lindström Å, Green M, Jönsson A (2025). Swedish Bird Survey: Summer point count routes (Sommarpunktrutterna). Version 1.8. Department of Biology, Lund University. Sampling event dataset https://doi.org/10.15468/2aajk9 accessed via GBIF.org.",
  doi_paper = "", doi_data = "10.15468/2aajk9",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Survey set = DwC event core (every route count; protocol registers all species; noObservations false everywhere). One count per route per year, 20 points summed by the source, so no within-year replication. Eleven security-class-4 raptors/owls/storks withheld by the publisher (no rows). Coordinates are 25 x 25 km grid centres as published. Fetched as the IPT Darwin Core Archive.",
  source_via = "GBIF (Swedish GBIF IPT, Lund University)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture / annual count index (multi-species, multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (50 years x 1 count per route-year; 20 points summed)", realm = "Terrestrial", country = "SWE",
  coordinates = "Coarsened (by the source: 25 x 25 km grid centres)", notes = "National volunteer scheme, free-choice routes; 1,256 routes, 11,011 route-years; 11 species withheld by the publisher.",
  status = "tagged")
