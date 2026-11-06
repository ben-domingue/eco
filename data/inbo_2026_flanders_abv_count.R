#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_abv_count
# Source: GBIF sampling-event dataset 99047b1e-ee53-4053-ba69-2e28eaaa45d9, doi:10.15468/pj2v6h, version 1.23
#         (2026), INBO IPT resource meetnetten-abv2-occurrences. Licence as shown on GBIF and in the EML
#         intellectualRights: CC0 1.0 (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, Vermeersch G, Brosens D, Westra T, Desmet P, Feys S, Van de Poel S, Pollet M,
#         Cooleman S (2026). ABV - Common breeding birds in Flanders, Belgium (post 2016). Version 1.23. Research
#         Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/pj2v6h
# Paper:  none; protocol in Vermeersch, Ledegen & Feys (2018), Methodehandleiding ABV, INBO report 93
#         (doi:10.21436/inbor.15674942), cited in the EML; trends in Onkelinx et al. (2025), INBO report 8.
# Data:   Darwin Core Archive (event core, occurrence and Humboldt ecological-inventory extensions):
#         event.txt (29,029 rows): one row per 5-minute point count; parentEventID = the visit to a 1 x 1 km UTM
#           square (4,973 visits; one date and one square per visit, asserted), locationID = the point (4,562; each
#           in one square), verbatimLocality = the square (ABV_<UTM>, 757), eventDate (2017-03-01 to 2025-07-15),
#           eventTime (start, empty for 3,827), decimalLatitude/Longitude = the centroid of the square
#           (georeferenceRemarks; uncertainty 707 m), samplingProtocol = the ABV manual URL on every row.
#         occurrence.txt (285,661 rows): adult birds per point count, one row per record: a species can have several
#           rows in one count (10,234 event x species pairs; the app records groups separately), summed here;
#           6,326 rows 'absent' with count 0 (31 counts have only absent rows, i.e. nothing seen); 181 names
#           (178 species, three subspecies: Carduelis flammea cabaret, Motacilla alba yarelli, Motacilla flava
#           flavissima, 3 to 11 records each, alongside their species), euring taxonIDs, Dutch vernacular names.
#         humboldtecologicalinventory.txt (4,973 rows, one per visit): siteCount = points counted on the visit (1-6),
#           samplingEffortValue (person-minutes), targetTaxonomicScope Aves, excludedTaxonomicScope 'foraging gulls,
#           herons ... breeding elsewhere, or flocks of corvids, starlings ... flying over', targetLifeStageScope adult.
#         Protocol (EML): 1,200 randomly selected 1 km squares stratified by habitat, six random points per square,
#           all points of a square counted on one day, three times a year in fixed windows (1 Mar-15 Apr,
#           16 Apr-31 May, 1 Jun-15 Jul), at least two weeks apart, 5 minutes per point, every adult breeding bird
#           seen or heard counted; each square surveyed at least once every three years.
# Mapping (repeated counts of 1 km squares, community abundance; responseType count): the survey is the count of
#   one square on one date (all its points are counted on one day, by protocol). The point is not a usable unit:
#   in 598 visits (mostly 2018) every point count of the visit carries the same locationID, so the points cannot be
#   told apart, and in a few squares one day's points were entered as several visits. So unit = the 1 km square
#   (verbatimLocality), period = calendar year 2017..2025 as 1..9, occasion = the square's count dates within the
#   year in order (normally 1-3, the three windows), date = eventDate, y = adults of the taxon summed over the
#   point counts of that square-date (the Pollard-walk rule of batches 17-20 applied to points: the visit is the
#   survey and its sub-units are summed), obs_points_counted = point counts made that day (1-6, the effort),
#   obs_start_time = earliest start time of the day's counts (HH:MM, NA where none recorded).
#   surveyEvidence = sample_table: the event core lists every point count, and the protocol is a complete count of
#   breeding birds, so a taxon with no record on a square-date was counted zero (taxonInclusion recorded: the 180
#   names recorded in the kept surveys; Netta rufina is recorded only in a dropped one). 14 square-dates hold more
#   than the six point counts the protocol allows (7 to 12, each from two or three visits of the same square entered
#   on the same date, i.e. double entry): dropped (asserted, notShipped). 4,936 - 14 = 4,922 square-dates x 180 taxa = 885,960 rows.
#   Coordinates: INBO publishes only the centroid of each 1 km square (point locations withheld): agency-published,
#   kept as published (E7).
# Not shipped: the per-point counts (point identity is not recoverable for 598 visits; the square-date sum is
#   shipped); the 14 double-entered square-dates; vernacular names in Dutch (in __taxa, as the source gives them).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_abv_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-abv2-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "humboldtecologicalinventory.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("99047b1e-ee53-4053-ba69-2e28eaaa45d9/v1.23", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
hu <- fread(file.path(dwca, "humboldtecologicalinventory.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 29029L, nrow(oc) == 285661L, nrow(hu) == 4973L, !anyDuplicated(ev$eventID),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), uniqueN(ev$samplingProtocol) == 1L,
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)), uniqueN(ev$parentEventID) == 4973L,
          uniqueN(ev$locationID) == 4562L, uniqueN(ev$verbatimLocality) == 757L, all(ev$coordinateUncertaintyInMeters == "707"),
          ev[, .(uniqueN(verbatimLocality), uniqueN(eventDate)), by = parentEventID][, all(V1 == 1L & V2 == 1L)],
          ev[, uniqueN(paste(verbatimLocality, decimalLatitude, decimalLongitude)), by = locationID][, all(V1 == 1L)],
          ev[, .N, by = .(parentEventID, locationID)][N > 1, uniqueN(parentEventID)] == 598L,
          setequal(hu$id, ev$parentEventID), all(hu$targetTaxonomicScope == "Aves"), all(hu$targetLifeStageScope == "adult"),
          all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID), all(oc$lifeStage == "adult"),
          all(oc$occurrenceStatus %in% c("present", "absent")), sum(oc$occurrenceStatus == "absent") == 6326L,
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"),
          all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          uniqueN(oc$scientificName) == 181L, oc[, uniqueN(taxonID), by = scientificName][, all(V1 == 1L)],
          oc[, uniqueN(scientificName), by = taxonID][, all(V1 == 1L)])
stopifnot(oc[, .N, by = .(eventID, scientificName)][N > 1, .N] == 10234L,
          oc[, all(occurrenceStatus == "absent"), by = eventID][, sum(V1)] == 31L)
ev[, year := as.integer(substr(eventDate, 1, 4))]
years <- 2017:2025
stopifnot(all(ev$year %in% years), sum(!substr(ev$eventDate, 6, 7) %in% sprintf("%02d", 3:7)) == 18L)   # 18 point counts dated January-February (outside the protocol windows; kept as published)

# square-date surveys
ev[, `:=`(unit = sub("^ABV_", "", verbatimLocality),
          start = ifelse(grepl("^\\d{2}:\\d{2}", eventTime), substr(eventTime, 1, 5), NA_character_))]
sv <- ev[, .(n_pc = .N, n_visits = uniqueN(parentEventID), start = if (all(is.na(start))) NA_character_ else min(start, na.rm = TRUE),
             lat = decimalLatitude[1], lon = decimalLongitude[1], year = year[1]), by = .(unit, eventDate)]
stopifnot(nrow(sv) == 4936L, ev[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = unit][, all(V1 == 1L)])
dbl <- sv[n_pc > 6L]
stopifnot(nrow(dbl) == 14L, all(dbl$n_visits >= 2L))
sv <- sv[n_pc <= 6L]
setorder(sv, unit, eventDate)
sv[, occasion := seq_len(.N), by = .(unit, year)]
ev <- ev[paste(unit, eventDate) %in% paste(sv$unit, sv$eventDate)]
cat(sprintf("  %d square-dates (%d dropped as double entry); counts per square-year: %s\n", nrow(sv), nrow(dbl),
            paste(names(table(sv[, .N, by = .(unit, year)]$N)), table(sv[, .N, by = .(unit, year)]$N), sep = ":", collapse = " ")))

# taxa
tx <- unique(oc[, .(scientificName, taxonID, vernacularName, rank = taxonRank)])
stopifnot(nrow(tx) == 181L, setequal(tx$rank, c("species", "subspecies")), sum(tx$rank == "subspecies") == 3L)
w <- strsplit(tx$scientificName, " ")
tx[, taxon := toupper(sapply(w, function(s) paste0(substr(s[1], 1, 3), substr(s[2], 1, 3), if (length(s) > 2) paste0("_", substr(s[3], 1, 3)) else "")))]
dup <- tx[duplicated(taxon) | duplicated(taxon, fromLast = TRUE)]
cat("  code collisions: ", paste(dup$scientificName, collapse = "; "), "\n")
tx[taxon %in% dup$taxon, taxon := toupper(sapply(strsplit(scientificName, " "), function(s) paste0(substr(s[1], 1, 4), substr(s[2], 1, 4))))]
tx[grepl(" var\\. domestica$", scientificName), `:=`(taxon = sub("_VAR$", "_DOM", taxon), rank = "form")]
stopifnot(!anyDuplicated(tx$taxon), sum(tx$rank == "form") == 2L)
# the source's misspellings and older names, sent to GBIF as the backbone spells them (scientificName keeps the source's)
LOOKUP <- c("Alopochen aegyptiacus" = "Alopochen aegyptiaca", "Dendrocopus medius" = "Dendrocopos medius",
            "Lululla arborea" = "Lullula arborea", "Regulus ignicapillus" = "Regulus ignicapilla",
            "Dendrocopus minor" = "Dendrocopos minor", "Ardeae cinerea" = "Ardea cinerea", "Athena noctua" = "Athene noctua",
            "Motacilla alba yarelli" = "Motacilla alba yarrellii", "Phylloscopus sibilatrix" = "Phylloscopus sibillatrix",
            "Delichon urbica" = "Delichon urbicum", "Cignus atratus" = "Cygnus atratus",
            "Acrocephalus arundinaceu" = "Acrocephalus arundinaceus", "Jynx torquila" = "Jynx torquilla",
            "Anas platyrhynchos var. domestica" = "Anas platyrhynchos domesticus", "Anser anser var. domestica" = "Anser anser domesticus")
stopifnot(all(names(LOOKUP) %in% tx$scientificName))
tx[, lookup := ifelse(scientificName %in% names(LOOKUP), LOOKUP[scientificName], scientificName)]
oc <- merge(oc, tx[, .(scientificName, taxon)], by = "scientificName")
oc <- merge(oc, ev[, .(eventID, unit, eventDate)], by = "eventID")
lost <- tx[!taxon %in% oc[individualCount != "0", taxon]]
stopifnot(identical(lost$scientificName, "Netta rufina"))   # recorded only in a dropped double-entered square-date
tx <- tx[!taxon %in% lost$taxon]
cnt <- oc[, .(y = sum(as.integer(individualCount))), by = .(unit, eventDate, taxon)]
g <- CJ(i = seq_len(nrow(sv)), taxon = tx$taxon)
g[, `:=`(unit = sv$unit[i], eventDate = sv$eventDate[i])]
g <- cnt[g, on = .(unit, eventDate, taxon)]
g[is.na(y), y := 0L]
g <- merge(g, sv, by = c("unit", "eventDate"))
years <- 2017:2025
long <- g[, .(unit, taxon, y, period = match(year, years), occasion, date = eventDate,
              unit_decimalLatitude = as.numeric(lat), unit_decimalLongitude = as.numeric(lon), unit_coordinateUncertaintyInMeters = 707L,
              obs_points_counted = n_pc, obs_start_time = start)]
stopifnot(nrow(long) == 4922L * 180L, sum(long$y) == sum(as.integer(oc$individualCount)), !anyNA(long$period))

taxa <- make_taxa(tx$taxon, tx$scientificName, vernacularName = tx$vernacularName,
                  taxonRank = tx$rank, lookupName = tx$lookup,
                  taxonRemarks = ifelse(tx$rank == "subspecies",
                    sprintf("Recorded at subspecies rank; the species is also a taxon of this table (records not identified to subspecies). Source code %s; vernacularName is the source's Dutch name.", tx$taxonID),
                  ifelse(tx$rank == "form", sprintf("Domestic form, recorded separately from the wild species. Source code %s; vernacularName is the source's Dutch name.", tx$taxonID),
                    sprintf("Source code %s; vernacularName is the source's Dutch name.", tx$taxonID))))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
cat("  IUCN CR/EN/VU: ", paste(sprintf("%s=%s", taxa$taxon, iu)[iu %in% c("CR", "EN", "VU")], collapse = " "), "\n")
periods <- data.table(period = seq_along(years), year = years,
                      n_squares_counted = sapply(years, function(y) uniqueN(sv[year == y]$unit)))

dataset <- list(
  title = sprintf("ABV common breeding bird monitoring, Flanders: point counts of %d bird taxa summed per visit in %d 1 km squares, 2017-2025", nrow(tx), uniqueN(sv$unit)),
  creator = "Piesschaert, Frederik; Vermeersch, Glenn; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Feys, Sam; Van de Poel, Sander; Pollet, Marc; Cooleman, Stijn (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/pj2v6h", sourceURL = "https://doi.org/10.15468/pj2v6h",
  citation = "Piesschaert F, Vermeersch G, Brosens D, Westra T, Desmet P, Feys S, Van de Poel S, Pollet M, Cooleman S (2026). ABV - Common breeding birds in Flanders, Belgium (post 2016). Version 1.23. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/pj2v6h",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "The Flemish common breeding bird monitoring scheme (Algemene Broedvogelmonitoring Vlaanderen, ABV), run by INBO and Natuurpunt Studie with volunteers through Meetnetten.be: up to six random points in each of a stratified random sample of 1 km UTM squares, all counted on one day, three times in a breeding season in fixed windows, five minutes per point, every adult breeding bird seen or heard counted. One row per square-date (a visit) and taxon, y the number of adults counted over the visit's point counts (obs_points_counted gives how many); zeros by complement of the complete count.",
  samplingProtocol = "Five-minute point count of all adult breeding birds seen or heard at up to six random points in a 1 x 1 km UTM square, all points on the same day, three visits a year in fixed windows (1 March-15 April, 16 April-31 May, 1 June-15 July) at least two weeks apart (Vermeersch, Ledegen & Feys 2018); foraging gulls and herons breeding elsewhere and flocks flying over are excluded.",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site",
  closure = "open", closureNote = "occasion = the point's counts within a breeding season (March to mid-July), across which arrivals and breeding change detectability and numbers; period = calendar year; squares are counted in some years only (at least once every three years)",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Flanders, Belgium (coordinates are the centroids of 1 km UTM squares, as published by INBO)",
  temporalCoverage = "2017-03/2025-07",
  coordinatesCoarsened = list(value = FALSE, method = "INBO, a government agency, publishes only the centroid of each 1 km UTM square (uncertainty 707 m); point locations are withheld. Kept as published."),
  covariateNote = "obs_points_counted = number of five-minute point counts made in the square that day (1-6; effort); obs_start_time = start time of the day's first count (HH:MM, local; NA where not recorded).",
  notes = sprintf("y sums all records of a taxon over the point counts of one square-date (the app stores groups as separate records; %d point-count x taxon pairs had more than one record). The point is not the unit: 598 visits record every point under one locationID, so points cannot be told apart. Three subspecies are their own taxa alongside their species, as recorded. 18 point counts (3 square-dates) are dated January-February, outside the protocol windows, probably day and month swapped in entry; kept as published.", 10234L),
  notShipped = list(
    `per-point counts` = "summed per square-date (point identity is not recoverable in 598 visits)",
    `double entries` = sprintf("%d square-dates with 7 to 12 point counts from two or three visits entered for one square and date (the protocol allows six): %s", nrow(dbl), paste(sprintf("%s %s", dbl$unit, dbl$eventDate), collapse = "; ")),
    `taxa only in dropped surveys` = "Netta rufina (red-crested pochard), recorded only in a dropped double-entered square-date",
    `Humboldt effort fields` = "person-minutes per visit (5 minutes x points counted; obs_points_counted carries it)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Counts of %d bird taxa in %d 1 km UTM squares of the Flemish common breeding bird monitoring scheme (ABV), summed over up to six five-minute point counts per visit, three visits a breeding season, 2017-2025, with explicit zeros from the complete-count protocol.", nrow(tx), uniqueN(sv$unit)),
  url = "https://doi.org/10.15468/pj2v6h",
  reference = "Piesschaert F, Vermeersch G, Brosens D, Westra T, Desmet P, Feys S, Van de Poel S, Pollet M, Cooleman S (2026). ABV - Common breeding birds in Flanders, Belgium (post 2016). Version 1.23. INBO.",
  doi_paper = "", doi_data = "10.15468/pj2v6h",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-abv2-occurrences v1.23); square-date sums of point counts; square-centroid coordinates as published.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "point_count", design = sprintf("Multi-season (%d years x up to %d visits)", length(years), max(sv$occasion)),
  realm = "Terrestrial", country = "BEL", coordinates = "As published",
  notes = "National (regional) breeding bird scheme; unit = 1 km square, point counts summed per visit; squares rotate across years.")
