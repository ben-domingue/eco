#!/usr/bin/env Rscript
# Table:  kuczkowska_2026_warsaw_owl_occ
# Source: GBIF sampling-event dataset b004c221-4e29-4148-88b6-04e9ea2e3e5e, doi:10.15468/32eg3p, version 1.1 (2026),
#         Polish GBIF IPT resource sowy_warszawa (University of Warsaw). Licence as shown on GBIF and in the EML:
#         CC BY 4.0 ("This work is licensed under a Creative Commons Attribution (CC-BY 4.0) License").
#         Citation: Kuczkowska K, Sadkowski D, Baranowska W, Rapczyński J, Chalecki K (2026). Playback survey of owls in
#         Warsaw in 2024. Version 1.1. University of Warsaw. Sampling event dataset. https://doi.org/10.15468/32eg3p
# Paper:  none; design from the EML (methods, sampling).
# Data:   Darwin Core Archive, event core with occurrence extension.
#   event.txt (1,724 rows): 431 parent events (one per survey point, WAW_<n>, the season) and 1,293 child events, one per
#     point and month (WAW_<n>_202402, _202403, _202404: three playback surveys, February, March and April 2024);
#     eventDate a day or, for 166 surveys, a range of days ('2024-02-21/27'), eventTime start (empty for 166 surveys),
#     sampleSizeValue = survey duration in minutes (10-50), point coordinates (uncertainty 100 m).
#   occurrence.txt (3,370 rows): EML: 'for each species surveyed at each point, there is either an absence record or one
#     or more presence records'; five species (Strix aluco, Asio otus, Athene noctua, Aegolius funereus, Tyto alba);
#     presence rows carry individualCount 1-4 and sometimes sex and life stage; records made away from a point are
#     matched to the nearest survey point (informationWithheld).
#   Protocol (EML): 431 points on a 1 x 1 km grid over Warsaw, three surveys each; the list of species surveyed at a
#     point was set from its habitat; for each species, from the smallest to the largest, listening, playback and
#     listening in a fixed sequence of about 10 minutes, playback stopped at the first response; small species not
#     played where tawny owls were calling. Glaucidium passerinum was a species of interest but is not surveyed at any
#     point in the deposit.
# Mapping (single-season occupancy, community; responseType detection): unit = survey point (WAW_<n>), period none (one
#   season), occasion = survey 1-3 (February, March, April; six February surveys were made in early March), y = 1 if the species was recorded on the survey, 0 for an
#   absence record; y_raw = individuals recorded (sum of the presence rows' counts, 0 for an absence). date = eventDate
#   where it is one day (NA for the 166 range-dated surveys; obs_event_date keeps the source's value), obs_start_time,
#   obs_duration_min. The taxa surveyed for differ between points (habitat-based lists), so __survey_taxa lists them per
#   point and survey (E4.2, from the source's explicit absence-or-presence rows). surveyEvidence = sample_table.
#   taxonInclusion target (the species surveyed; Tyto alba, surveyed at 124 points, is never detected).
#   Coordinates: survey points as published (all five owls IUCN LC; the publisher already replaced nest locations by
#   survey points).
# Not shipped: sex and life stage of presence records (sparse); occurrence remarks (Polish free text); the parent events.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "kuczkowska_2026_warsaw_owl_occ"
zip <- download_cached("https://ipt.gbif.pl/archive.do?r=sowy_warszawa", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Creative Commons Attribution (CC-BY 4.0) License", eml, fixed = TRUE), grepl("sowy_warszawa/v1.1", eml, fixed = TRUE),
          grepl("either an absence record or one or more presence records", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
sv <- ev[parentEventID != ""]
stopifnot(nrow(ev) == 1724L, nrow(oc) == 3370L, nrow(sv) == 1293L, uniqueN(sv$locationID) == 431L,
          all(sv$samplingProtocol == "playback survey"), all(sv$eventID == paste0(sv$parentEventID, "_", sub("^.*_", "", sv$eventID))),
          setequal(sub("^.*_", "", sv$eventID), c("202402", "202403", "202404")), sv[, .N, by = locationID][, all(N == 3L)],
          all(sv$sampleSizeUnit == "minutes"), all(grepl("^2024-0[234]-\\d{2}(/(\\d{2}|2024-05-01))?$", sv$eventDate)),
          sv[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = locationID][, all(V1 == 1L)],
          all(oc$eventID %in% sv$eventID), all(sv$eventID %in% oc$eventID), all(oc$occurrenceStatus %in% c("present", "absent")),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          oc[, .(a = sum(occurrenceStatus == "absent"), p = sum(occurrenceStatus == "present")), by = .(eventID, scientificName)][, all((a == 1L & p == 0L) | (a == 0L & p >= 1L))],
          !any(grepl("Glaucidium", oc$scientificName)))
SP <- data.table(scientificName = c("Strix aluco", "Asio otus", "Athene noctua", "Aegolius funereus", "Tyto alba"),
                 taxon = c("STRALU", "ASIOTU", "ATHNOC", "AEGFUN", "TYTALB"),
                 vern = c("Tawny Owl", "Long-eared Owl", "Little Owl", "Boreal Owl", "Western Barn Owl"))
stopifnot(setequal(oc$scientificName, SP$scientificName))
oc <- merge(oc, SP[, .(scientificName, taxon)], by = "scientificName")
d <- oc[, .(y_raw = sum(as.integer(individualCount))), by = .(eventID, taxon)]
d[, y := as.integer(y_raw > 0)]
sv[, `:=`(occasion = match(sub("^.*_", "", eventID), c("202402", "202403", "202404")),
          date = ifelse(grepl("^\\d{4}-\\d{2}-\\d{2}$", eventDate), eventDate, NA_character_))]
stopifnot(sum(is.na(sv$date)) == 166L, sum(substr(sv$eventDate, 6, 7) != sprintf("%02d", sv$occasion + 1L)) == 6L)   # six February surveys made in early March
long <- merge(d, sv[, .(eventID, unit = locationID, occasion, date, unit_decimalLatitude = as.numeric(decimalLatitude),
                        unit_decimalLongitude = as.numeric(decimalLongitude), unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters),
                        obs_event_date = eventDate, obs_start_time = ifelse(eventTime == "", NA_character_, eventTime),
                        obs_duration_min = as.numeric(sampleSizeValue))], by = "eventID")
long[, eventID := NULL]
stopifnot(nrow(long) == oc[, uniqueN(paste(eventID, taxon))], !anyNA(long$y))
survey_taxa <- unique(long[, .(taxon, unit, occasion)])
cat(sprintf("  %d rows; surveys %d; species lists per point: %s\n", nrow(long), nrow(sv),
            paste(names(table(long[, uniqueN(taxon), by = .(unit, occasion)]$V1)), table(long[, uniqueN(taxon), by = .(unit, occasion)]$V1), sep = ":", collapse = " ")))
print(long[, .(n = .N, det = sum(y)), by = taxon])

taxa <- make_taxa(SP$taxon, SP$scientificName, vernacularName = SP$vern)
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Playback survey of owls in Warsaw, 2024: detections of five owl species at 431 points on three surveys",
  creator = "Kuczkowska, Karolina; Sadkowski, Dawid; Baranowska, Weronika; Rapczyński, Jan; Chalecki, Kajetan (University of Warsaw)",
  pubDate = "2026", doi = "10.15468/32eg3p", sourceURL = "https://doi.org/10.15468/32eg3p",
  citation = "Kuczkowska K, Sadkowski D, Baranowska W, Rapczyński J, Chalecki K (2026). Playback survey of owls in Warsaw in 2024. Version 1.1. University of Warsaw. Sampling event dataset. https://doi.org/10.15468/32eg3p",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
  abstract = "A city-wide owl survey of Warsaw in 2024 by the Ornithology Science Club 'Jajo' (University of Warsaw) with partners: 431 points on a 1 km grid, each surveyed three times (February, March, April) with a fixed listening and playback sequence for each species on the point's habitat-based list. One row per point, survey and species surveyed: detected (1) or not (0), with the individuals recorded in y_raw.",
  samplingProtocol = "Night playback survey at a fixed point: for each species on the point's list, from the smallest to the largest, at least 120 s listening, 10 s playback, 60 s listening, 30 s playback, 120 s listening, 60 s playback, at least 120 s listening, stopped at the first response of the species; small owls not played where tawny owls were calling; three surveys a season (February, March, April), by pairs of observers.",
  samplingProtocolCode = "playback", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "three surveys within one breeding season (February to April 2024)",
  occasionKind = "time", taxonInclusion = "target",
  surveyTaxaNote = "The species surveyed at a point were chosen from its habitat; the source gives an absence or presence record for each species surveyed at each survey, and __survey_taxa lists them per point and survey.",
  geographicCoverage = "Warsaw, Poland (431 survey points on a 1 km grid)",
  temporalCoverage = "2024-02/2024-04",
  coordinatesCoarsened = list(value = FALSE, method = "Survey-point coordinates as published (uncertainty 100 m); records away from a point are matched by the publisher to the nearest point; no taxon is IUCN CR/EN/VU."),
  covariateNote = "y_raw = individuals recorded on the survey (0 for an absence); obs_event_date = the source's eventDate (a day, or a range of days for 166 surveys whose date is NA); obs_start_time = start time (local, NA where not recorded); obs_duration_min = survey duration in minutes.",
  notes = "Glaucidium passerinum was a species of interest but is not on any point's list in the deposit, so it has no rows. Tyto alba is on the list at 124 points and was never detected (all its rows are 0).",
  notShipped = list(`sex and life stage` = "recorded on a few presence records only", occurrenceRemarks = "free-text field notes in Polish",
                    `season events` = "the 431 parent events (one per point)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, survey_taxa = survey_taxa, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = "Detection / non-detection of five owl species (tawny, long-eared, little, boreal and barn owl) in three night playback surveys at 431 grid points across Warsaw, Poland, February-April 2024, with habitat-based species lists per point (__survey_taxa).",
  url = "https://doi.org/10.15468/32eg3p",
  reference = "Kuczkowska K, Sadkowski D, Baranowska W, Rapczyński J, Chalecki K (2026). Playback survey of owls in Warsaw in 2024. Version 1.1. University of Warsaw.",
  doi_paper = "", doi_data = "10.15468/32eg3p", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Polish GBIF IPT DwC-A (sowy_warszawa v1.1). Explicit absence records per species surveyed.", source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Occupancy (single-season, multi-species)",
  sampling_protocol = "playback", design = "Single-season (3 surveys)", realm = "Terrestrial", country = "POL",
  coordinates = "As published", notes = "Urban owl playback survey; species lists differ between points (__survey_taxa).")
