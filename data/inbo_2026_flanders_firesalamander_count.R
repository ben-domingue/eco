#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_firesalamander_count
# Source: GBIF sampling-event dataset bced6c7a-c7e0-40f7-b009-5f0478104716, doi:10.15468/nbsk9h, version 1.22 (2026),
#         INBO IPT resource meetnetten-vuursalamander-transect-occurrences. Licence as shown on GBIF and in the EML:
#         CC0 1.0 (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026).
#         Meetnetten.be - Transects for fire salamanders in Flanders, Belgium. Version 1.22. Research Institute for
#         Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/nbsk9h
# Paper:  none; protocol De Bruyn et al. (2015), updated by Speybroeck et al. (2020) (INBO reports, cited in the EML).
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (998 rows): one row per transect visit (parentEventID = the visit, one event each, asserted); locationID
#     the transect (83), locality its name, eventDate one night (2016-2025, mostly September-November),
#     decimalLatitude/Longitude generalised by INBO to the centroid of a 5 km UTM square.
#   occurrence.txt (4,591 rows): Salamandra salamandra only, post-metamorphs; 4,538 present rows (individualCount,
#     mostly one row per animal, some rows a group count) and 53 absent rows (count 0), one for each visit with no
#     salamander; every visit has at least one row (asserted). occurrenceRemarks reads 'casual observation' on every
#     row, absent rows included (a constant of the export, not a record type).
#   Protocol (EML): fixed transects of about 1 km walked at night between 15 August and 15 November in humid weather,
#     searching 6 m either side of the trail with a flashlight; each transect visited at least twice a year.
# Mapping (repeated counts, single species; responseType count): unit = transect (locationID, T<number>), period =
#   calendar year 2016..2025, occasion = visit within the year in date order, date = eventDate, y = salamanders counted
#   on the visit (individualCount summed over the visit's rows). surveyEvidence = sample_table: every visit is an event
#   and reports the species (present with a count or absent = 0). taxonInclusion = single.
#   Coordinates: generalised by INBO to 5 km UTM centroids (uncertainty 3,536 m) before publication, which is finer
#   than 0.1 degree. The species is IUCN VU (2022, Bsal declines; asserted from GBIF's IUCN record) in its native range,
#   so under E7 (ruling on the publisher, 2026-11-06: agency coordinates included) the centroid is coarsened with
#   coarsen_coords() to its 0.1-degree cell centre. Uncertainty = the source's 3,536 m plus the cell half-diagonal
#   (the animal is within 3,536 m of the published centroid, which is within a half-diagonal of the cell centre).
#   Rebuilt in batch 46 (#10); before, the 5 km centroids were kept under the withdrawn agency exception.
# Not shipped: nothing beyond the per-row split of a visit's count (summed).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_firesalamander_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-vuursalamander-transect-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("bced6c7a-c7e0-40f7-b009-5f0478104716/v1.22", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 998L, nrow(oc) == 4591L, !anyDuplicated(ev$eventID), !anyDuplicated(ev$parentEventID),
          all(ev$samplingProtocol %in% c("fire salamander transect", "Vuursalamander - Transect")),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          uniqueN(ev$locationID) == 83L, all(ev$dataGeneralizations == "UTM 5km"), all(ev$coordinateUncertaintyInMeters == "3536"),
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, locality)), by = locationID][, all(V1 == 1L)],
          all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID), all(oc$scientificName == "Salamandra salamandra"),
          all(oc$lifeStage == "post-metamorph"), all(oc$occurrenceStatus %in% c("present", "absent")), sum(oc$occurrenceStatus == "absent") == 53L,
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          oc[, sum(occurrenceStatus == "absent") == 0L | .N == 1L, by = eventID][, all(V1)],
          all(oc$occurrenceRemarks == "casual observation"))
vy <- oc[, .(y = sum(as.integer(individualCount)), n_rows = .N), by = eventID]
vis <- merge(ev[, .(eventID, locationID, date = eventDate, lat = decimalLatitude, lon = decimalLongitude, unc = coordinateUncertaintyInMeters)],
             vy, by = "eventID")
vis[, year := as.integer(substr(date, 1, 4))]
years <- 2016:2025
stopifnot(all(vis$year %in% years))
setorder(vis, locationID, date, eventID)
vis[, occasion := seq_len(.N), by = .(locationID, year)]
long <- vis[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "T", locationID), taxon = "SALSAL", y, period = match(year, years), occasion, date,
                lat = as.numeric(lat), lon = as.numeric(lon), unc = as.integer(unc))]
cc <- coarsen_coords(long$lat, long$lon, 0.1)
long[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
            unit_coordinateUncertaintyInMeters = as.integer(unc + cc$uncertainty_m))]
long[, c("lat", "lon", "unc") := NULL]
stopifnot(nrow(long) == 998L, sum(long$y) == sum(as.integer(oc$individualCount)), sum(long$y == 0L) == 53L)

taxa <- make_taxa("SALSAL", "Salamandra salamandra", vernacularName = "Fire salamander")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa)
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
dataset <- list(
  title = sprintf("Meetnetten.be night transect counts of fire salamanders on %d transects, Flanders, Belgium, %d-%d", uniqueN(long$unit), min(vis$year), max(vis$year)),
  creator = "Piesschaert, Frederik; Speybroeck, Jeroen; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Van de Poel, Sander; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/nbsk9h", sourceURL = "https://doi.org/10.15468/nbsk9h",
  citation = "Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026). Meetnetten.be - Transects for fire salamanders in Flanders, Belgium. Version 1.22. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/nbsk9h",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Repeated night counts of fire salamanders (Salamandra salamandra) on %d fixed forest transects of about 1 km in Flanders, from the Meetnetten.be priority-species monitoring network run by INBO and Natuurpunt Studie with specialised volunteers. Transects are walked between mid-August and mid-November on humid nights, at least twice a year. One row per visit: post-metamorphic salamanders counted.", uniqueN(long$unit)),
  samplingProtocol = "Fixed transect of about 1 km walked at night in humid weather between 15 August and 15 November; salamanders searched for by flashlight within 6 m either side of the trail and counted; at least two visits a year (De Bruyn et al. 2015; Speybroeck et al. 2020).",
  samplingProtocolCode = "transect_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = visit within an autumn season; period = calendar year; the population is treated as closed within the season by the protocol's design (repeat counts for N-mixture models)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Flanders, Belgium (INBO 5 km UTM centroids, coarsened to 0.1-degree cell centres)",
  temporalCoverage = sprintf("%d/%d", min(vis$year), max(vis$year)),
  coordinatesCoarsened = list(value = TRUE, method = "coarsen_coords(): the 5 km UTM-square centroids INBO publishes (coordinateUncertaintyInMeters 3536) snapped to their 0.1-degree cell centre, because Salamandra salamandra is IUCN VU (GBIF IUCN record, asserted) in its native range (E7, ruling on the publisher 2026-11-06); uncertainty = 3536 m plus the cell half-diagonal."),
  notes = sprintf("%d visits are dated outside August-November, kept as published. The source's occurrenceRemarks 'casual observation' is on every row, absences included, and is not a record type.", sum(!as.integer(substr(long$date, 6, 7)) %in% 8:11)),
  notShipped = list(`row-level counts` = "a visit's count is split over several occurrence rows (mostly one per animal); summed into y"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Repeated night transect counts of fire salamanders on %d forest transects of the INBO Meetnetten.be network, Flanders, Belgium, %d-%d.", uniqueN(long$unit), min(vis$year), max(vis$year)),
  url = "https://doi.org/10.15468/nbsk9h",
  reference = "Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026). Meetnetten.be - Transects for fire salamanders in Flanders, Belgium. Version 1.22. INBO.",
  doi_paper = "", doi_data = "10.15468/nbsk9h", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-vuursalamander-transect-occurrences v1.22). INBO 5 km centroids coarsened to 0.1 degree (IUCN VU).",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "transect_count", design = sprintf("Multi-season (%d years x 1-%d visits)", uniqueN(long$period), max(long$occasion)),
  realm = "Terrestrial", country = "BEL", coordinates = "Coarsened (0.1 deg)",
  notes = "Priority-species monitoring with volunteers; night transects in autumn.")
