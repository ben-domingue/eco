#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_priobutterfly_count
# Source: GBIF sampling-event dataset 63938753-1fec-4c08-ae39-e9f8a6576521, doi:10.15468/kfhvy4, version 1.40 (2026),
#         INBO IPT resource meetnetten-butterflies-occurrences. Licence as shown on GBIF and in the EML: CC0 1.0 (INBO
#         asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, Maes D, Brosens D, Westra T, Desmet P, Ledegen H, Veraghtert W, Van de Poel S, Pollet M
#         (2026). Meetnetten.be - Transects for butterflies in Flanders, Belgium. Version 1.40. Research Institute for
#         Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/kfhvy4
# Paper:  none; protocol in Maes et al. (2019) Monitoringsprotocol Dagvlinders and Ledegen et al. (INBO reports, cited in
#         the EML). Not the Flemish butterfly monitoring scheme of inbo_2026_flanders_butterfly_count (doi:10.15468/wwrgcd,
#         general Pollard walks 1991-2020); this is the Meetnetten.be priority-species network, 2016-2025.
# Data:   Darwin Core Archive, event core with occurrence and measurement-or-fact extensions.
#   event.txt (40,233 rows): one row per transect section count; parentEventID = the visit (2,598; one date and one
#     transect each, asserted), locationID = the transect (144; each in one project), eventRemarks = the project, i.e.
#     the target species (nine projects), locality, decimalLatitude/Longitude generalised by INBO to the centroid of a
#     1, 5 or 10 km UTM square (dataGeneralizations; 'original locations available upon request').
#   occurrence.txt (80,342 rows): imago counts per section; the project's target is reported at 40,224 of the 40,233
#     section events (present with a count, or absent = 0; asserted), sometimes as several rows (summed); other
#     butterflies are reported at some sections only (incidental records).
#   measurementorfacts.txt: weather per section (bewolking, temperature, windkracht; many empty measurementType rows).
#   Protocol (EML): fixed transects in sections, walked in good weather during the target's flight period; each
#     population counted in some years; every imago of the target within the transect band counted.
# Mapping (repeated counts, single target per transect; responseType count): ONE table for the nine projects (one
#   protocol, ruling #31), __survey_taxa listing each transect's target (E4.2). unit = transect (locationID),
#   unit_project = the project, period = calendar year 2016..2025 as 1..10, occasion = visit within the year in date
#   order (then visit id), date = eventDate, y = imagos of the target counted on the visit, summed over its sections
#   (the Pollard-walk rule of batches 17-20: the visit is the survey), obs_n_sections = sections of the visit with a
#   target row. surveyEvidence = sample_table: every visit is a count, and the target is reported (absent = 0) at its
#   sections. taxonInclusion = target. Three visits have no target row at any section (no evidence of a target count):
#   dropped (asserted, notShipped); nine single sections without a target row are left out of the sum.
#   Coordinates: generalised by INBO (an agency) before publication; kept as published (E7).
# Not shipped: section-level counts (summed); other butterflies (incidental, not reported at every section);
#   weather (per section, incomplete); the three visits with no target record.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_priobutterfly_count"
PROJ <- data.table(project = c("Argusvlinder", "Veldparelmoervlinder", "Heivlinder", "Kommavlinder", "Bruin dikkopje",
                               "Aardbeivlinder", "Oranje zandoogje", "Klaverblauwtje", "Moerasparelmoervlinder"),
                   target = c("Lasiommata megera", "Melitaea cinxia", "Hipparchia semele", "Hesperia comma", "Erynnis tages",
                              "Pyrgus malvae", "Pyronia tithonus", "Cyaniris semiargus", "Euphydryas aurinia"),
                   code = c("LASMEG", "MELCIN", "HIPSEM", "HESCOM", "ERYTAG", "PYRMAL", "PYRTIT", "CYASEM", "EUPAUR"),
                   vern = c("Wall", "Glanville Fritillary", "Grayling", "Silver-spotted Skipper", "Dingy Skipper",
                            "Grizzled Skipper", "Gatekeeper", "Mazarine Blue", "Marsh Fritillary"))
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-butterflies-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "measurementorfacts.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("63938753-1fec-4c08-ae39-e9f8a6576521/v1.40", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 40233L, nrow(oc) == 80342L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol == "butterfly transects"),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          uniqueN(ev$parentEventID) == 2598L, uniqueN(ev$locationID) == 144L,
          ev[, .(uniqueN(locationID), uniqueN(eventDate)), by = parentEventID][, all(V1 == 1L & V2 == 1L)],
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1L)],
          all(ev$dataGeneralizations %in% c("UTM 1km", "UTM 5km", "UTM 10km")),
          all(oc$eventID %in% ev$eventID), all(oc$lifeStage == "imago"), all(oc$occurrenceStatus %in% c("present", "absent")),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L))
ev[, project := sub("^data collected in the (.*) project$", "\\1", eventRemarks)]
stopifnot(setequal(ev$project, PROJ$project), ev[, uniqueN(project), by = locationID][, all(V1 == 1L)])
ev[, target := PROJ$target[match(project, PROJ$project)]]
oc <- merge(oc, ev[, .(eventID, parentEventID, target)], by = "eventID")
t <- oc[scientificName == target]
stopifnot(uniqueN(t$eventID) == 40224L)
vis <- ev[, .(locationID = locationID[1], project = project[1], date = eventDate[1], lat = decimalLatitude[1], lon = decimalLongitude[1],
              unc = coordinateUncertaintyInMeters[1]), by = parentEventID]
vy <- t[, .(y = sum(as.integer(individualCount)), n_sec = uniqueN(eventID)), by = parentEventID]
nov <- vis[!parentEventID %in% vy$parentEventID]
stopifnot(nrow(nov) == 3L)
vis <- merge(vis, vy, by = "parentEventID")
vis[, year := as.integer(substr(date, 1, 4))]
years <- 2016:2025
stopifnot(all(vis$year %in% years))
setorder(vis, locationID, date, parentEventID)
vis[, occasion := seq_len(.N), by = .(locationID, year)]
vis[, taxon := PROJ$code[match(project, PROJ$project)]]
long <- vis[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "T", locationID), taxon, y, period = match(year, years), occasion, date,
                unit_project = project, unit_decimalLatitude = as.numeric(lat), unit_decimalLongitude = as.numeric(lon),
                unit_coordinateUncertaintyInMeters = as.integer(unc), obs_n_sections = n_sec)]
stopifnot(nrow(long) == 2595L, !anyNA(long$y), sum(long$y) == sum(as.integer(t$individualCount)))
survey_taxa <- unique(long[, .(taxon, unit)])
n_out_season <- sum(!as.integer(substr(long$date, 6, 7)) %in% 4:9)

taxa <- make_taxa(PROJ$code, PROJ$target, vernacularName = PROJ$vern)
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxon_iucnCategory)])
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
dataset <- list(
  title = sprintf("Meetnetten.be transect counts of nine priority butterflies, Flanders, Belgium, %d-%d", min(vis$year), max(vis$year)),
  creator = "Piesschaert, Frederik; Maes, Dirk; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Veraghtert, Wouter; Van de Poel, Sander; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/kfhvy4", sourceURL = "https://doi.org/10.15468/kfhvy4",
  citation = "Piesschaert F, Maes D, Brosens D, Westra T, Desmet P, Ledegen H, Veraghtert W, Van de Poel S, Pollet M (2026). Meetnetten.be - Transects for butterflies in Flanders, Belgium. Version 1.40. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/kfhvy4",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Repeated transect counts of nine priority butterflies (%s) on %d transects in Flanders, from the Meetnetten.be priority-species monitoring network run by INBO and Natuurpunt Studie with specialised volunteers. Each transect belongs to one species' project and is counted for that species only, several times in its flight period in counting years. One row per visit: imagos of the target counted, summed over the transect's sections.", paste(PROJ$target, collapse = ", "), uniqueN(long$unit)),
  samplingProtocol = "Fixed butterfly transect divided into sections, walked in good weather during the target species' flight period; all imagos of the target within the transect band counted per section (Maes et al. 2019); several visits per counting year.",
  samplingProtocolCode = "transect_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "occasion = visit within a flight season, across which the adult population emerges and declines; period = calendar year",
  occasionKind = "time", taxonInclusion = "target",
  surveyTaxaNote = "Each transect is monitored for its own project's target species only; __survey_taxa gives the taxon per unit, unit_project the project.",
  geographicCoverage = "Flanders, Belgium (coordinates generalised by INBO to 1, 5 or 10 km UTM square centroids)",
  temporalCoverage = sprintf("%d/%d", min(vis$year), max(vis$year)),
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO, a government agency) to the centroid of a 1, 5 or 10 km UTM square (coordinateUncertaintyInMeters 707, 3536 or 7071) before publication; kept as published."),
  covariateNote = "obs_n_sections = number of the transect's sections with a target record on the visit (sections are listed only when walked; nine sections without a target row are left out of y).",
  notes = sprintf("%d visits are dated outside April-September, kept as published.", n_out_season),
  notShipped = list(
    `section counts` = "summed into the visit's y",
    `other species` = "butterflies other than the project's target, recorded at some sections only (incidental)",
    weather = "cloudiness, temperature and wind per section, incomplete",
    `visits without a target record` = sprintf("%d visits with no target row at any section: %s", nrow(nov), paste(nov$parentEventID, collapse = ", "))))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Repeated transect counts of nine priority butterflies on %d transects of the INBO Meetnetten.be monitoring network, Flanders, Belgium, %d-%d; each transect counted for one target species (__survey_taxa), sections summed per visit.", uniqueN(long$unit), min(vis$year), max(vis$year)),
  url = "https://doi.org/10.15468/kfhvy4",
  reference = "Piesschaert F, Maes D, Brosens D, Westra T, Desmet P, Ledegen H, Veraghtert W, Van de Poel S, Pollet M (2026). Meetnetten.be - Transects for butterflies in Flanders, Belgium. Version 1.40. INBO.",
  doi_paper = "", doi_data = "10.15468/kfhvy4", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-butterflies-occurrences v1.40). Target species only; coordinates generalised by INBO.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "transect_count", design = sprintf("Multi-season (%d years x 1-%d visits)", uniqueN(long$period), max(long$occasion)),
  realm = "Terrestrial", country = "BEL", coordinates = "As published",
  notes = "Priority-species monitoring with volunteers; one target species per transect; sections summed per visit.")
