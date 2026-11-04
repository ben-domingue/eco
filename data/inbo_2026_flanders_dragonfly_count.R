#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_dragonfly_count (replaces inbo_2026_flanders_aesiso_count,
#         inbo_2026_flanders_calvir_count and inbo_2026_flanders_coepul_count; ruling #31)
# Source: GBIF sampling-event dataset 9100f482-848c-42e7-bf7c-19947885ce48, doi:10.15468/y8u6e9,
#         version 1.28 (2026-02-26), INBO IPT resource meetnetten-libellen-transect-occurrences.
#         Licence as shown on GBIF and in the EML: CC0 1.0 (Creative Commons Zero v1.0
#         Universal); INBO asks users to follow its norms for data use.
#         Citation: Piesschaert F, De Knijf G, Brosens D, Westra T, Desmet P, Ledegen H, Pollet M
#         (2026). Meetnetten.be - Transects for dragonflies in Flanders, Belgium. Version 1.28.
#         Research Institute for Nature and Forest (INBO). https://doi.org/10.15468/y8u6e9
# Paper:  none; protocol in De Knijf et al. (2019) and Ledegen et al. (2017) (INBO reports, cited
#         in the EML).
# Data:   Darwin Core Archive, event core with occurrence and measurement-or-fact extensions.
#   event.txt (653 rows): one row per transect count; eventID, parentEventID (a visit id, one
#     per event), eventDate (yyyy-mm-dd), eventRemarks naming the monitoring project, i.e. the
#     target species ("Bosbeekjuffer" = Calopteryx virgo, 240 counts at 30 locations;
#     "Variabele waterjuffer" = Coenagrion pulchellum, 203 at 32; "Vroege glazenmaker" =
#     Aeshna isoceles, 210 at 30), locationID (92 transects, each in one project), locality,
#     decimalLatitude/Longitude generalised by INBO to the centroid of a 1 km (642 events,
#     uncertainty 707 m) or 10 km (11 events, 7071 m) UTM square, 2017-2025.
#   occurrence.txt (10,929 rows): per event, the target species is reported in a fixed set of
#     seven categories (male / female / unknown adult; teneral 'imago'; copula; egg-laying
#     female; exuviae), each with individualCount and occurrenceStatus present / absent
#     (absent = 0). Some events report the categories as one row per individual (point
#     records), so counts are summed within category. Other dragonflies are recorded at some
#     events only (368 of 653 events list the target alone), so they are incidental records.
#   measurementorfacts.txt (653 rows): transect length in metres per event ('unknown' for 379).
#   Protocol (EML): 30 populations per target species, 10 counted each year; in a counting year
#   at least two (C. virgo: three) transect counts while adults fly, in good weather,
#   11:00-16:30; transect 100-500 m along the shore; all adults within 2 m of the bank and
#   3 m (A. isoceles: 5 m) above the water are counted.
#
# Mapping (standard v1.1 E1-E5, repeated counts / N-mixture): ONE table (ruling #31): the three
#   projects are one deposit and one protocol (samplingProtocol "dragonfly transects" on every
#   event; the same transect count of adults, only the height band and the minimum number of
#   counts differ by target), one response type. Each transect belongs to one project and is
#   surveyed for that project's target only, so __survey_taxa lists the taxon per unit (E4.2):
#   "Bosbeekjuffer" = CALVIR (30 transects), "Variabele waterjuffer" = COEPUL (32), "Vroege
#   glazenmaker" = AESISO (30); no invented zeros for the other two targets.
#   unit = locationID, unit_project = the Meetnetten project name, period = calendar year
#   2017..2025 as 1..9 (year in __periods), occasion = count within the year ordered by
#   eventDate then eventID (same-day repeat counts keep separate occasions), y = adults
#   counted = sum of individualCount over the target's adult and imago categories (male,
#   female, unknown, teneral, copula, egg-laying; copula is counted as recorded, the deposit
#   does not say whether pairs or individuals), date = eventDate, obs_transect_length_m (NA
#   where 'unknown'), unit_decimalLatitude / unit_decimalLongitude /
#   unit_coordinateUncertaintyInMeters as INBO published them. closure = closed (counts within
#   one flight season; closureNote: populations may change between years), occasionKind =
#   time, taxonInclusion = target (the three project targets).
#   surveyEvidence = sample_table: every event of a project is a count, and every event has
#   the target's explicit category rows (absent = 0).
#   Coordinates: INBO already generalised them (dataGeneralizations UTM 1 km / 10 km,
#   "original locations available upon request"); agency-published, kept as published. The
#   target species are IUCN LC.
#   Not shipped: exuviae counts (a different life stage and protocol); the category breakdown
#   (summed into y); other dragonfly species (incidental, not reported at every count).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_dragonfly_count"
PROJ <- data.table(project = c("Bosbeekjuffer", "Variabele waterjuffer", "Vroege glazenmaker"),
                   target = c("Calopteryx virgo", "Coenagrion pulchellum", "Aeshna isoceles"),
                   code = c("CALVIR", "COEPUL", "AESISO"),
                   vern = c("Beautiful Demoiselle", "Variable Damselfly", "Green-eyed Hawker"),
                   n_events = c(240L, 203L, 210L), n_loc = c(30L, 32L, 30L))

zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-libellen-transect-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "measurementorfacts.txt", "eml.xml", "meta.xml")))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("Creative Commons Zero v1.0 Universal", eml)), any(grepl("spdx.org/licenses/CC0-1.0", eml)),
          any(grepl("9100f482-848c-42e7-bf7c-19947885ce48/v1.28", eml)))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "measurementorfacts.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 653, nrow(oc) == 10929, nrow(mf) == 653, !anyDuplicated(ev$eventID),
          setequal(mf$id, ev$eventID), all(mf$measurementType == "transect length"), all(mf$measurementUnit == "meter"),
          all(ev$samplingProtocol == "dragonfly transects"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), uniqueN(ev$locationID) == 92,
          all(oc$eventID %in% ev$eventID), all(oc$occurrenceStatus %in% c("present", "absent")),
          all(oc$taxonRank == "species"), all(oc$basisOfRecord == "HumanObservation"))
stopifnot(all(oc[occurrenceStatus == "absent", individualCount] == "0"),
          all(as.integer(oc[occurrenceStatus == "present", individualCount]) >= 1))
ev[, project := sub("^data collected in the (.*) project$", "\\1", eventRemarks)]
stopifnot(setequal(ev$project, c("Bosbeekjuffer", "Variabele waterjuffer", "Vroege glazenmaker")),
          ev[, uniqueN(project), by = locationID][, all(V1 == 1)],
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1)],
          all(ev$geodeticDatum == "WGS84"), all(ev$dataGeneralizations %in% c("UTM 1km", "UTM 10km")))

cats <- c("male adult present", "female adult present", "unknown adult present", "unknown imago present",
          "unknown adult copula", "female adult egg laying", "unknown exuviae present")
stopifnot(sum(PROJ$n_events) == nrow(ev), sum(PROJ$n_loc) == uniqueN(ev$locationID))
e <- rbindlist(lapply(seq_len(nrow(PROJ)), function(i) {
  P <- PROJ[i]; e <- ev[project == P$project]
  stopifnot(nrow(e) == P$n_events, uniqueN(e$locationID) == P$n_loc)
  t <- oc[eventID %in% e$eventID & scientificName == P$target]
  t[, cat := paste(sex, lifeStage, behavior)]
  # every count reports the target in all seven categories (absent = 0)
  stopifnot(all(t$cat %in% cats), t[, uniqueN(cat), by = eventID][, .N == P$n_events && all(V1 == 7)])
  adult <- t[lifeStage %in% c("adult", "imago"), .(y = sum(as.integer(individualCount))), by = eventID]
  stopifnot(nrow(adult) == P$n_events)
  cat(sprintf("  %s: exuviae counted at %d of %d events (not shipped)\n", P$target,
              t[lifeStage == "exuviae" & occurrenceStatus == "present", uniqueN(eventID)], P$n_events))
  e <- merge(e, adult, by = "eventID"); e[, taxon := P$code]; e
}))
e <- merge(e, mf[, .(eventID = id, len = measurementValue)], by = "eventID")
stopifnot(nrow(e) == 653, all(e$len == "unknown" | grepl("^[0-9]+$", e$len)))
e[, obs_transect_length_m := suppressWarnings(as.integer(ifelse(len == "unknown", NA, len)))]
e[, year := as.integer(substr(eventDate, 1, 4))]
years <- 2017:2025
stopifnot(all(e$year %in% years))
setorder(e, locationID, year, eventDate, eventID)
e[, occasion := seq_len(.N), by = .(locationID, year)]
long <- e[, .(unit = locationID, taxon, y, period = match(year, years), occasion, date = eventDate, unit_project = project,
              unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
              unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters), obs_transect_length_m)]
stopifnot(nrow(long) == 653, !anyNA(long$y), all(long$y >= 0), long[, uniqueN(taxon), by = unit][, all(V1 == 1)])
survey_taxa <- unique(long[, .(taxon, unit)])
n_out <- sum(!as.integer(substr(long$date, 6, 7)) %in% 5:8)

taxa <- make_taxa(PROJ$code, PROJ$target, vernacularName = PROJ$vern, taxon_iucnCategory = "LC")
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
dataset <- list(
  title = sprintf("Meetnetten.be transect counts of three priority dragonflies (%s), Flanders, Belgium, %d-%d", paste(PROJ$target, collapse = ", "), min(e$year), max(e$year)),
  creator = "Piesschaert, Frederik; De Knijf, Geert; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/y8u6e9", sourceURL = "https://doi.org/10.15468/y8u6e9",
  citation = "Piesschaert F, De Knijf G, Brosens D, Westra T, Desmet P, Ledegen H, Pollet M (2026). Meetnetten.be - Transects for dragonflies in Flanders, Belgium. Version 1.28. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/y8u6e9",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Repeated transect counts of adult %s at %d monitored populations in Flanders, from the Meetnetten.be priority-species monitoring network run by INBO and Natuurpunt Studie with specialised volunteers. Each transect belongs to one species' project and is counted for that species only; each population is counted in some years (10 of 30 per species per year), at least twice in a counting year while adults fly.", paste(PROJ$target, collapse = ", "), uniqueN(long$unit)),
  samplingProtocol = "Transect count of adults along a 100-500 m shore transect in good dragonfly weather, 11:00-16:30, within 2 m of the bank and 3-5 m above the water (De Knijf et al. 2019); at least two counts in a counting year.",
  samplingProtocolCode = "transect_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "target",
  closureNote = "occasion within period (counts within one flight season); populations may change between years",
  surveyTaxaNote = "Each transect is monitored for its own project's target species only (Bosbeekjuffer = Calopteryx virgo, Variabele waterjuffer = Coenagrion pulchellum, Vroege glazenmaker = Aeshna isoceles); __survey_taxa gives the taxon per unit, unit_project the project.",
  geographicCoverage = "Flanders, Belgium (coordinates generalised by INBO to 1 km or 10 km UTM square centroids)",
  temporalCoverage = sprintf("%d/%d", min(e$year), max(e$year)),
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO) to the centroid of a 1 km (uncertainty 707 m) or 10 km (7071 m) UTM square before publication; kept as published."),
  notes = sprintf("y sums all adult and teneral categories the app records (male, female, unknown, teneral, copula, egg-laying); copula is summed as recorded. %d count(s) are dated outside May-August as published (e.g. 2025-12-11), probably data-entry errors in the date; kept. obs_transect_length_m is NA where INBO gives 'unknown'.", n_out),
  notShipped = list(
    exuviae = "the exuviae category (a different life stage, counted under a separate Meetnetten protocol)",
    `category breakdown` = "sex / teneral / copula / egg-laying counts are summed into y",
    `other species` = "dragonflies other than the project's target are recorded at some counts only (incidental); not a complete community record"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Repeated transect counts of adult %s at %d monitored populations in Flanders, Belgium, %d-%d, from the INBO Meetnetten.be priority-species monitoring network; each transect is counted for one target species (__survey_taxa).", paste(sprintf("%s (%s)", PROJ$target, PROJ$vern), collapse = ", "), uniqueN(long$unit), min(e$year), max(e$year)),
  url = "https://doi.org/10.15468/y8u6e9",
  reference = "Piesschaert F, De Knijf G, Brosens D, Westra T, Desmet P, Ledegen H, Pollet M (2026). Meetnetten.be - Transects for dragonflies in Flanders, Belgium. Version 1.28. INBO.",
  doi_paper = "", doi_data = "10.15468/y8u6e9",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = sprintf("INBO IPT DwC-A (meetnetten-libellen-transect-occurrences, v1.28). Replaces inbo_2026_flanders_aesiso_count, _calvir_count and _coepul_count (ruling #31). Coordinates generalised by INBO."),
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "transect_count", design = sprintf("Multi-season (%d years x 1-%d counts)", uniqueN(long$period), max(long$occasion)), realm = "Freshwater",
  country = "BEL", coordinates = "As published",
  notes = "Agency monitoring with volunteers; each population counted in a subset of years; adults summed over sex and behaviour categories.")
