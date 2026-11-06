#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_alconegg_count
# Source: GBIF sampling-event dataset 53b55f0b-eace-46da-b414-351f092e1223, doi:10.15468/hsfq2u, version 1.26 (2026),
#         INBO IPT resource meetnetten-butterflies-egg-occurrences. Licence as shown on GBIF and in the EML: CC0 1.0
#         (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, Maes D, Brosens D, Westra T, Desmet P, Ledegen H, Veraghtert W, Van de Poel S, Pollet M
#         (2026). Meetnetten.be - Egg counts for butterflies in Flanders, Belgium. Version 1.26. Research Institute for
#         Nature and Forest (INBO). Samplingevent dataset. https://doi.org/10.15468/hsfq2u
# Paper:  none; protocol Maes et al. (2019) Monitoringsprotocol Dagvlinders 2.0, doi:10.21436/inbor.16744530 (EML): Alcon
#         blue eggs are counted on the host plant (marsh gentian) in 10 x 10 m plots at the locations with the highest
#         gentian density, once a year in August.
# Data:   Darwin Core Archive, event core with occurrence extension.
#   event.txt (178 rows): one per plot count; parentEventID = the visit (160; one location and date each, asserted),
#     locationID = the monitoring location (19), eventDate 2016-2025 (July to September, mostly August), locality (place
#     names), coordinates generalised by INBO to the centroid of a 5 or 10 km UTM square.
#   occurrence.txt (22,010 rows): Phengaris alcon egg records, individualCount >= 1 (present) or 0 (absent), 1 to 641 per
#     count; the archive does not say what one record is (the protocol counts eggs per gentian plant).
# Mapping (repeated counts, single species): unit = location (locationID, "P" + its number), period = year 2016..2025 as
#   1..10, occasion = plot count within the location-year in date order (most location-years have one count; up to 8 in
#   2017 at one location), y = eggs counted (sum of individualCount over the count's records), obs_n_records = the
#   count's occurrence records (0 and positive). surveyEvidence = sample_table: every count is an event with explicit
#   absent records. Coordinates as generalised by INBO (an agency), kept.
# Not shipped: locality (place names); the per-record split (summed per count).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_alconegg_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-butterflies-egg-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("53b55f0b-eace-46da-b414-351f092e1223/v1.26", eml, fixed = TRUE), grepl("Creative Commons Zero", eml, fixed = TRUE))
ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 178L, nrow(oc) == 22010L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol == "butterfly egg counts"),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), uniqueN(ev$locationID) == 19L,
          uniqueN(ev$parentEventID) == 160L, ev[, .(uniqueN(locationID), uniqueN(eventDate)), by = parentEventID][, all(V1 == 1L & V2 == 1L)],
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)), all(substr(ev$eventDate, 6, 7) %in% c("07", "08", "09")),
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1L)],
          all(oc$scientificName == "Phengaris alcon"), all(oc$lifeStage == "egg"), all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L))
cnt <- oc[, .(y = sum(as.integer(individualCount)), n_rec = .N), by = eventID]
ev <- merge(ev, cnt, by = "eventID")
ev[, year := as.integer(substr(eventDate, 1, 4))]
years <- 2016:2025
stopifnot(all(ev$year %in% years))
setorder(ev, locationID, eventDate, eventID)
ev[, occasion := seq_len(.N), by = .(locationID, year)]
long <- ev[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "P", locationID), taxon = "PHEALC", y, period = match(year, years), occasion, date = eventDate,
               unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
               unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters), obs_n_records = n_rec)]
stopifnot(sum(long$y) == sum(as.integer(oc$individualCount)), nrow(long) == 178L)
taxa <- make_taxa("PHEALC", "Phengaris alcon", vernacularName = "Alcon blue")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# GBIF's IUCN record for the key is Phengaris alcon as a synonym of Maculinea alcon, category NOT_EVALUATED, so
# iucn_category() returns NA on the name check; the record's category is NE either way.
stopifnot(is.na(taxa$taxon_iucnCategory)); taxa[, taxon_iucnCategory := "NE"]
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
dataset <- list(
  title = sprintf("Meetnetten.be egg counts of the Alcon blue (Phengaris alcon) at %d locations, Flanders, Belgium, 2016-2025", uniqueN(long$unit)),
  creator = "Piesschaert, Frederik; Maes, Dirk; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Veraghtert, Wouter; Van de Poel, Sander; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/hsfq2u", sourceURL = "https://doi.org/10.15468/hsfq2u",
  citation = "Piesschaert F, Maes D, Brosens D, Westra T, Desmet P, Ledegen H, Veraghtert W, Van de Poel S, Pollet M (2026). Meetnetten.be - Egg counts for butterflies in Flanders, Belgium. Version 1.26. Research Institute for Nature and Forest (INBO). Samplingevent dataset. https://doi.org/10.15468/hsfq2u",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Alcon blue monitoring in the Meetnetten.be priority-species network (INBO and Natuurpunt Studie with volunteers): eggs on marsh gentians counted in 10 x 10 m plots at fixed locations in wet heathland, once a year in August.",
  samplingProtocol = "Egg counts of Phengaris alcon on its host plant Gentiana pneumonanthe in 10 x 10 m plots at the locations with the highest gentian density, once a year in August (Maes et al. 2019, Meetnetten.be butterfly protocol 2.0).",
  samplingProtocolCode = "egg_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = plot count within one August season; most location-years have one count",
  occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_n_records",
  geographicCoverage = "Flanders, Belgium (coordinates generalised by INBO to 5 or 10 km UTM square centroids)",
  temporalCoverage = "2016/2025",
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO, a government agency) to the centroid of a 5 or 10 km UTM square before publication; kept as published."),
  notes = "y = eggs counted, summed over the count's occurrence records; obs_n_records = number of records (absent and present) in the count, which the archive does not define further.",
  notShipped = list(locality = "location place names", `per-record counts` = "summed per count (obs_n_records)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))
stage_dict_row(TABLE,
  description = sprintf("Annual August egg counts of the Alcon blue (Phengaris alcon) on marsh gentians at %d locations of the INBO Meetnetten.be monitoring network, Flanders, Belgium, 2016-2025.", uniqueN(long$unit)),
  url = "https://doi.org/10.15468/hsfq2u",
  reference = "Piesschaert F, Maes D, Brosens D, Westra T, Desmet P, Ledegen H, Veraghtert W, Van de Poel S, Pollet M (2026). Meetnetten.be - Egg counts for butterflies in Flanders, Belgium. Version 1.26. INBO.",
  doi_data = "10.15468/hsfq2u", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-butterflies-egg-occurrences v1.26). Eggs summed per plot count; coordinates generalised by INBO.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "egg_count", design = sprintf("Multi-season (%d years, 1-%d counts a year)", uniqueN(long$period), max(long$occasion)),
  realm = "Terrestrial", country = "BEL", coordinates = "As published",
  notes = "Priority-species monitoring with volunteers; eggs on the host plant.")
