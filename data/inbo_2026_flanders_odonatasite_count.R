#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_odonatasite_count
# Source: GBIF sampling-event dataset e0bbc7b4-c22e-42b7-8c0c-2deb26495948, doi:10.15468/crbudg, version 1.19 (2026),
#         INBO IPT resource meetnetten-libellen-populatietelling-occurrences. Licence as shown on GBIF and in the EML:
#         CC0 1.0 (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, De Knijf G, Brosens D, Westra T, Desmet P, Ledegen H, Pollet M (2026). Meetnetten.be -
#         Population counts for dragonflies in Flanders, Belgium. Version 1.19. Research Institute for Nature and Forest
#         (INBO). Sampling event dataset. https://doi.org/10.15468/crbudg
# Paper:  none; protocol in De Knijf et al. (2019) and Ledegen et al. (2017) (INBO reports, cited in the EML). The
#         companion transect protocol (doi:10.15468/y8u6e9) is inbo_2026_flanders_dragonfly_count; this deposit is the
#         site-count protocol for six other priority species.
# Data:   Darwin Core Archive, event core with occurrence extension.
#   event.txt (900 rows): one row per site count (parentEventID = a visit id, one per event), eventDate, eventRemarks
#     naming the project = target species (Gevlekte witsnuitlibel = Leucorrhinia pectoralis, 474 counts at 27 sites;
#     Kempense heidelibel = Sympetrum depressiusculum, 102 at 8; Maanwaterjuffer = Coenagrion lunulatum, 129 at 8;
#     Speerwaterjuffer = Coenagrion hastulatum, 118 at 9; Hoogveenglanslibel = Somatochlora arctica, 56 at 11;
#     Sierlijke witsnuitlibel = Leucorrhinia caudalis, 21 at 2), locationID (65 sites, each in one project),
#     coordinates generalised by INBO to the centroid of a 5 or 10 km UTM square, 2016-2025.
#   occurrence.txt (28,969 rows): per count the target is reported in six categories (male / female / unknown adult;
#     copula; egg-laying; exuviae), each present with a count or absent = 0, sometimes as several rows (summed);
#     other dragonflies are recorded at some counts only (incidental).
# Mapping (repeated counts, single target per site; responseType count): ONE table (one protocol, ruling #31),
#   __survey_taxa giving each site's target (E4.2). unit = site (locationID), unit_project, period = calendar year
#   2016..2025 as 1..10, occasion = count within the year by date then event id, date = eventDate, y = imagos of the
#   target counted (male, female, unknown, copula, egg-laying summed, as in inbo_2026_flanders_dragonfly_count).
#   surveyEvidence = sample_table: every event is a count with the target's six category rows (asserted).
#   taxonInclusion target. Coordinates: generalised by INBO (an agency); kept as published (E7). Sympetrum
#   depressiusculum is IUCN VU in Europe's red list but LC globally; the IUCN category is read from GBIF.
# Not shipped: exuviae (another life stage, not counted at every count by the same effort; listed per category in the
#   source); the category breakdown (summed); other species (incidental).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_odonatasite_count"
PROJ <- data.table(project = c("Gevlekte witsnuitlibel", "Kempense heidelibel", "Maanwaterjuffer", "Speerwaterjuffer",
                               "Hoogveenglanslibel", "Sierlijke witsnuitlibel"),
                   target = c("Leucorrhinia pectoralis", "Sympetrum depressiusculum", "Coenagrion lunulatum",
                              "Coenagrion hastulatum", "Somatochlora arctica", "Leucorrhinia caudalis"),
                   code = c("LEUPEC", "SYMDEP", "COELUN", "COEHAS", "SOMARC", "LEUCAU"),
                   vern = c("Yellow-spotted Whiteface", "Spotted Darter", "Irish Damselfly", "Spearhead Bluet",
                            "Northern Emerald", "Lilypad Whiteface"),
                   n_events = c(474L, 102L, 129L, 118L, 56L, 21L), n_loc = c(27L, 8L, 8L, 9L, 11L, 2L))
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-libellen-populatietelling-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("e0bbc7b4-c22e-42b7-8c0c-2deb26495948/v1.19", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 900L, nrow(oc) == 28969L, !anyDuplicated(ev$eventID), !anyDuplicated(ev$parentEventID),
          all(ev$samplingProtocol == "dragonfly population count"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), uniqueN(ev$locationID) == 65L,
          all(oc$eventID %in% ev$eventID), all(oc$occurrenceStatus %in% c("present", "absent")),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1L)],
          all(ev$dataGeneralizations %in% c("UTM 5km", "UTM 10km")))
ev[, project := sub("^data collected in the (.*) project$", "\\1", eventRemarks)]
stopifnot(setequal(ev$project, PROJ$project), ev[, uniqueN(project), by = locationID][, all(V1 == 1L)])
cats <- c("male imago present", "female imago present", "unknown imago present", "unknown imago copula",
          "unknown imago egg laying", "unknown exuviae present")
e <- rbindlist(lapply(seq_len(nrow(PROJ)), function(i) {
  P <- PROJ[i]; e <- ev[project == P$project]
  stopifnot(nrow(e) == P$n_events, uniqueN(e$locationID) == P$n_loc)
  t <- oc[eventID %in% e$eventID & scientificName == P$target]
  t[, cat := paste(sex, lifeStage, behavior)]
  stopifnot(all(t$cat %in% cats), t[, uniqueN(cat), by = eventID][, .N == P$n_events && all(V1 == 6L)])
  adult <- t[lifeStage == "imago", .(y = sum(as.integer(individualCount))), by = eventID]
  stopifnot(nrow(adult) == P$n_events)
  e <- merge(e, adult, by = "eventID"); e[, taxon := P$code]; e
}))
e[, year := as.integer(substr(eventDate, 1, 4))]
years <- 2016:2025
stopifnot(nrow(e) == 900L, all(e$year %in% years))
setorder(e, locationID, year, eventDate, eventID)
e[, occasion := seq_len(.N), by = .(locationID, year)]
long <- e[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "S", locationID), taxon, y, period = match(year, years), occasion, date = eventDate,
              unit_project = project, unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
              unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters))]
stopifnot(!anyNA(long$y), long[, uniqueN(taxon), by = unit][, all(V1 == 1L)])
survey_taxa <- unique(long[, .(taxon, unit)])
n_out <- sum(!as.integer(substr(long$date, 6, 7)) %in% 4:9)

taxa <- make_taxa(PROJ$code, PROJ$target, vernacularName = PROJ$vern)
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxon_iucnCategory)])
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
dataset <- list(
  title = sprintf("Meetnetten.be site counts of six priority dragonflies, Flanders, Belgium, %d-%d", min(e$year), max(e$year)),
  creator = "Piesschaert, Frederik; De Knijf, Geert; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/crbudg", sourceURL = "https://doi.org/10.15468/crbudg",
  citation = "Piesschaert F, De Knijf G, Brosens D, Westra T, Desmet P, Ledegen H, Pollet M (2026). Meetnetten.be - Population counts for dragonflies in Flanders, Belgium. Version 1.19. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/crbudg",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Repeated site counts of adult %s at %d monitored sites in Flanders, from the Meetnetten.be priority-species monitoring network run by INBO and Natuurpunt Studie with specialised volunteers. Each site belongs to one species' project and is counted for that species only, several times in a counting year while adults fly.", paste(PROJ$target, collapse = ", "), uniqueN(long$unit)),
  samplingProtocol = "Population count of adults at a fen, bog or pool in good dragonfly weather during the flight period, counting all adults of the target species at the site (De Knijf et al. 2019); several counts in a counting year.",
  samplingProtocolCode = "area_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = count within one flight season; populations may change between years (period)",
  occasionKind = "time", taxonInclusion = "target",
  surveyTaxaNote = "Each site is monitored for its own project's target species only; __survey_taxa gives the taxon per unit, unit_project the project.",
  geographicCoverage = "Flanders, Belgium (coordinates generalised by INBO to 5 km or 10 km UTM square centroids)",
  temporalCoverage = sprintf("%d/%d", min(e$year), max(e$year)),
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO, a government agency) to the centroid of a 5 km (3536 m) or 10 km (7071 m) UTM square before publication; kept as published."),
  notes = sprintf("y sums the adult categories the app records (male, female, unknown, copula, egg-laying), as in inbo_2026_flanders_dragonfly_count. %d count(s) are dated outside April-September, kept as published.", n_out),
  notShipped = list(
    exuviae = "the exuviae category (another life stage)",
    `category breakdown` = "sex / copula / egg-laying counts summed into y",
    `other species` = "dragonflies other than the project's target, recorded at some counts only (incidental)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Repeated site counts of six priority dragonflies at %d monitored sites of the INBO Meetnetten.be network, Flanders, Belgium, %d-%d; each site counted for one target species (__survey_taxa).", uniqueN(long$unit), min(e$year), max(e$year)),
  url = "https://doi.org/10.15468/crbudg",
  reference = "Piesschaert F, De Knijf G, Brosens D, Westra T, Desmet P, Ledegen H, Pollet M (2026). Meetnetten.be - Population counts for dragonflies in Flanders, Belgium. Version 1.19. INBO.",
  doi_paper = "", doi_data = "10.15468/crbudg", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-libellen-populatietelling-occurrences v1.19). Target species only; adults summed over categories; coordinates generalised by INBO.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "area_count", design = sprintf("Multi-season (%d years x 1-%d counts)", uniqueN(long$period), max(long$occasion)),
  realm = "Freshwater", country = "BEL", coordinates = "As published",
  notes = "Priority-species monitoring with volunteers; one target species per site; adults summed over sex and behaviour categories.")
