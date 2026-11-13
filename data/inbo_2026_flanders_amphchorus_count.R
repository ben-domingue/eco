#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_amphchorus_count
# Source: GBIF sampling-event dataset 9bd8310b-0914-411f-a4ba-0cefdd85df80, doi:10.15468/d4bu8j, version 1.27 (2026),
#         INBO IPT resource meetnetten-amphibia-roepkoren-occurrences. Licence as shown on GBIF and in the EML:
#         CC0 1.0 (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026).
#         Meetnetten.be - Chorus counts for Amphibia in Flanders, Belgium. Version 1.27. Research Institute for Nature
#         and Forest (INBO). Samplingevent dataset. https://doi.org/10.15468/d4bu8j
# Paper:  none; Meetnetten.be protocols (INBO / Natuurpunt Studie), summarised in the EML.
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (963 rows): one row per pond visit (parentEventID = the visit, one event each, asserted); eventRemarks
#     names the monitoring project, one per target species: Boomkikker (Hyla arborea, 634 visits 2016-2025),
#     Knoflookpad (Pelobates fuscus, 145 visits 2017-2025), Rugstreeppad (Epidalea calamita, 27 visits, 2018) and
#     Poelkikker (Pelophylax lessonae, 157 visits 2021-2024). Every pond (locationID, 186) belongs to one project
#     (asserted). Coordinates: INBO generalises them to the centroid of a 1, 5 or 10 km UTM square ("as these are
#     sensitive priority species"; dataGeneralizations, coordinateUncertaintyInMeters 707 / 3536 / 7071).
#   occurrence.txt (1,436 rows): calling adult males, individualCount with occurrenceStatus present or absent (0).
#     Each visit has at least one row of its project's target species, except 44 Poelkikker visits (asserted), plus
#     incidental records of other amphibians (presence only). occurrenceRemarks 'casual observation' on every row,
#     absences included (an export constant, as in the fire-salamander set).
#     A visit can hold several rows of its target species (62 visits, up to 16 rows, absent and present rows mixed);
#     the archive has no field telling them apart (no sublocation, time or observer column). They are read as
#     parts of one visit's count and summed, as in the other Meetnetten count sets; obs_n_records keeps the number.
# Mapping (repeated counts; responseType count): unit = pond (locationID, P<number>), taxon = the target species of
#   the pond's project, period = calendar year, occasion = visit within the year in date order, date = eventDate,
#   y = calling males counted (individualCount summed over the visit's target rows). surveyEvidence = sample_table:
#   every visit is an event and reports its target species (present with a count, or absent = 0).
#   __survey_taxa (E4.2, ruling #31): each pond is surveyed for its project's target species only.
#   obs_protocol = the visit's samplingProtocol label (spadefoot visits are labelled 'amphibia choir count' to 2022
#   and 'Knoflookpad - Roepkoren' from 2018, the network's own protocol; the others have one label each). Coordinates: the species are flagged by the
#   source (sensitive priority species) and the 1 and 5 km centroids are finer than 0.1 degree, so every centroid
#   is coarsened with coarsen_coords() (E7); uncertainty = the source's plus the cell half-diagonal.
# Not shipped: the Poelkikker project (Pelophylax: the archive mixes species, the synklepton under two names
#   ('Pelophylax esculenta synklepton', 'Pelophylax kl. esculentus') and a lessonae/esculentus aggregate, and 44 of
#   its 157 visits have no row for the target species, so its taxon set per visit is not recoverable); incidental
#   records of non-target amphibians (presence only, no survey for them).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_amphchorus_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-amphibia-roepkoren-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Creative Commons Zero", eml, fixed = TRUE), grepl("9bd8310b-0914-411f-a4ba-0cefdd85df80/v1.27", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
ev[, project := sub("^data collected in the (\\w+) project$", "\\1", eventRemarks)]
target <- c(Boomkikker = "Hyla arborea", Knoflookpad = "Pelobates fuscus", Rugstreeppad = "Epidalea calamita",
            Poelkikker = "Pelophylax lessonae")
stopifnot(nrow(ev) == 963L, nrow(oc) == 1436L, !anyDuplicated(ev$eventID), !anyDuplicated(ev$parentEventID),
          setequal(ev$project, names(target)), all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)), uniqueN(ev$locationID) == 186L,
          ev[, uniqueN(project), by = locationID][, all(V1 == 1L)],
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1L)],
          all(paste(ev$dataGeneralizations, ev$coordinateUncertaintyInMeters) %in% c("UTM 1km 707", "UTM 5km 3536", "UTM 10km 7071")),
          ev[project != "Knoflookpad", uniqueN(samplingProtocol), by = project][, all(V1 == 1L)],
          setequal(ev[project == "Knoflookpad"]$samplingProtocol, c("amphibia choir count", "Knoflookpad - Roepkoren")),
          all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID),
          all(oc$occurrenceStatus %in% c("present", "absent")), all(oc$sex == "male"), all(oc$lifeStage == "adult"),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"),
          all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          all(oc$occurrenceRemarks == "casual observation"))
m <- merge(oc, ev[, .(eventID, project)], by = "eventID")
m[, is_target := scientificName == target[project]]
nt <- m[is_target == TRUE, .N, by = eventID]
missing_target <- ev[!eventID %in% nt$eventID]
stopifnot(nrow(missing_target) == 44L, all(missing_target$project == "Poelkikker"),
          m[is_target == FALSE & project != "Poelkikker", sum(occurrenceStatus == "absent")] == 1L,
          sum(nt$N > 1L) == 62L, max(nt$N) == 16L)

keep <- ev[project != "Poelkikker"]
vy <- m[is_target == TRUE & project != "Poelkikker",
        .(y = sum(as.integer(individualCount)), obs_n_records = .N), by = eventID]
vis <- merge(keep[, .(eventID, locationID, project, protocol = samplingProtocol, date = eventDate,
                      lat = as.numeric(decimalLatitude), lon = as.numeric(decimalLongitude),
                      unc = as.integer(coordinateUncertaintyInMeters))], vy, by = "eventID")
stopifnot(nrow(vis) == nrow(keep), nrow(vis) == 806L)
vis[, year := as.integer(substr(date, 1, 4))]
years <- sort(unique(vis$year))
setorder(vis, locationID, date, eventID)
vis[, occasion := seq_len(.N), by = .(locationID, year)]
codes <- c(Boomkikker = "HYLARB", Knoflookpad = "PELFUS", Rugstreeppad = "EPICAL")
cc <- coarsen_coords(vis$lat, vis$lon, 0.1)
long <- vis[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "P", locationID), taxon = codes[project], y,
                period = match(year, years), occasion, date, obs_n_records,
                obs_protocol = protocol,
                unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                unit_coordinateUncertaintyInMeters = as.integer(unc + cc$uncertainty_m))]
stopifnot(nrow(long) == 806L, !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
survey_taxa <- unique(long[, .(taxon, unit)])
stopifnot(!anyDuplicated(survey_taxa$unit))

taxa <- make_taxa(unname(codes), unname(target[names(codes)]),
                  vernacularName = c("European tree frog", "Common spadefoot", "Natterjack toad"))
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxonID, taxon_iucnCategory)])
periods <- data.table(period = seq_along(years), year = years)
nyr <- function(p) range(vis[project == p]$year)
dataset <- list(
  title = sprintf("Meetnetten.be chorus counts of three priority anurans at %d ponds, Flanders, Belgium, %d-%d",
                  uniqueN(long$unit), min(years), max(years)),
  creator = "Piesschaert, Frederik; Speybroeck, Jeroen; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Van de Poel, Sander; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/d4bu8j", sourceURL = "https://doi.org/10.15468/d4bu8j",
  citation = "Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026). Meetnetten.be - Chorus counts for Amphibia in Flanders, Belgium. Version 1.27. Research Institute for Nature and Forest (INBO). Samplingevent dataset. https://doi.org/10.15468/d4bu8j",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = paste0("Repeated counts of calling males of three priority anurans at fixed ponds in Flanders, from the Meetnetten.be monitoring networks run by INBO and Natuurpunt Studie with specialised volunteers: European tree frog (Hyla arborea), common spadefoot (Pelobates fuscus) and natterjack toad (Epidalea calamita). Each pond belongs to the network of one species (__survey_taxa) and is visited at least twice in the breeding season; one row per visit with the number of calling males of that species."),
  samplingProtocol = "Chorus count: the number of calling males of the target species is counted at the breeding pond, at least twice a year (Meetnetten.be protocols for tree frog, common spadefoot and natterjack toad; obs_protocol gives the source's protocol label).",
  samplingProtocolCode = "call_survey", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = visit within a breeding season; period = calendar year; the protocol repeats counts within a season for N-mixture estimation",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Flanders, Belgium (INBO 1, 5 and 10 km UTM centroids, coarsened to 0.1-degree cell centres)",
  temporalCoverage = sprintf("%d/%d", min(years), max(years)),
  coordinatesCoarsened = list(value = TRUE, rule = "taxon",
    method = "coarsen_coords(): the UTM-square centroids INBO publishes (1, 5 or 10 km; uncertainty 707, 3536 or 7071 m) snapped to their 0.1-degree cell centre, because the source flags the species as sensitive and generalises their locations (E7); uncertainty = the source's plus the cell half-diagonal."),
  notes = sprintf("Each pond is in one species' network (__survey_taxa). obs_protocol is the source's protocol label per visit (spadefoot visits move from the generic 'amphibia choir count' to the network's own 'Knoflookpad - Roepkoren' protocol between 2018 and 2022). Tree frog %d-%d, spadefoot %d-%d, natterjack %d only. %d visits hold several rows of the target species, absent and present rows mixed, with no field telling them apart; they are summed into y and obs_n_records gives the number of rows. The source's occurrenceRemarks 'casual observation' is on every row, absences included, and is not a record type.",
                  nyr("Boomkikker")[1], nyr("Boomkikker")[2], nyr("Knoflookpad")[1], nyr("Knoflookpad")[2], nyr("Rugstreeppad")[1],
                  sum(long$obs_n_records > 1L)),
  notShipped = list(
    `Poelkikker project` = "157 visits at 49 ponds 2021-2024 for the pool frog: the Pelophylax records mix a lessonae/esculentus aggregate with species-level classes and name the synklepton twice, and 44 visits have no row for P. lessonae, so the taxa surveyed for at a visit cannot be recovered",
    `incidental records` = "non-target amphibians recorded as present (no survey for them)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa,
                  script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Repeated chorus counts (calling males) of tree frog, common spadefoot and natterjack toad at %d ponds of the INBO Meetnetten.be networks, Flanders, Belgium, %d-%d.", uniqueN(long$unit), min(years), max(years)),
  url = "https://doi.org/10.15468/d4bu8j",
  reference = "Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026). Meetnetten.be - Chorus counts for Amphibia in Flanders, Belgium. Version 1.27. INBO.",
  doi_paper = "", doi_data = "10.15468/d4bu8j", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-amphibia-roepkoren-occurrences v1.27). One target species per pond (__survey_taxa); pool-frog project not shipped. Centroids coarsened to 0.1 degree (source-flagged).",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "call_survey", design = sprintf("Multi-season (%d years x 1-%d visits)", uniqueN(long$period), max(long$occasion)),
  realm = "Freshwater", country = "BEL", coordinates = "Coarsened (0.1 deg)",
  notes = "Priority-species monitoring with volunteers; one target species per pond.")
