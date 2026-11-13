#!/usr/bin/env Rscript
# Table:  evju_2025_hvaler_herminium_count
# Source: GBIF sampling-event dataset 5fcc9f05-0ed9-4e25-8a6a-0894cebd00da, doi:10.15468/rt6t88, version 1.3 (2025),
#         NINA IPT resource herminium_monitoring_nina. Licence as shown on GBIF and in the EML: CC BY 4.0.
#         Citation: Evju M (2025). Monitoring of Herminium monorchis. Version 1.3. Norwegian Institute for Nature
#         Research. Samplingevent dataset. https://doi.org/10.15468/rt6t88
# Paper:  Kravdal L I, Evju M, Klanderud K (2016) Honningblom Herminium monorchis - overvåking av artens tre populasjoner
#         på Hvaler. Blyttia 74: 19-26; NINA reports 2022-2024 (Evju et al. 2022, NINA Rapport 2196; Roos et al. 2024,
#         NINA Rapport 2538), cited in the EML.
# Data:   Darwin Core Archive, event core with occurrence and measurement-or-fact extensions.
#   event.txt (604 rows): 39 locality-year parent events and 565 plot events (one count of one permanent 0.5 x 0.5 m
#     plot: sampleSizeValue '0,25' m2, asserted), with locationID (the plot, 77), locality (Filletassen, Skipstadsand,
#     Skjellvik, Teneskjær), eventDate (late June-July), coordinates (1 or 5 m), habitat.
#   occurrence.txt (684 rows): one Herminium monorchis row for 550 plot events (individualCount = ramets, lifeStage
#     'n fertile m vegetative' on present rows, absent rows 0), and percent-cover rows of 11 other red-listed plants in
#     some plots (not ramet counts). 40 H. monorchis rows say the ramets were counted in a smaller square
#     ('Plot size for counting Herminium 0.140625 m2', 0.0625, 0.015625). The 15 Teneskjær plot events of 2025 have no
#     occurrence row (asserted): the count is not in the archive.
#   measurementorfacts.txt: vegetation cover and height per plot (not shipped).
#   Protocol (EML): 40 permanent plots placed around randomly drawn marked plants at the three populations known in
#     2014 (counted annually except 2018); a fourth population (Filletassen) from 2020; from 2021 further plots at 10 m
#     along transects (67 plots in all); fertile and vegetative ramets with aboveground biomass counted at peak season.
# Mapping (annual counts, single species; responseType count): unit = plot (locationID), cluster_id = locality,
#   period = year 2014..2025 (no 2018), no occasion (one count per plot-year, asserted), date = eventDate, y = ramets
#   counted (individualCount), obs_n_fertile and obs_n_vegetative from lifeStage (counts split by stage, ruling on
#   repeated rows; NA where the two parts do not add up to the total, printed), obs_count_area_m2 = the area in which
#   ramets were counted (0.25 m2 unless the source names a smaller square). surveyEvidence = sample_table: every plot
#   event with a count reports the species (present or absent = 0). taxonInclusion = single.
#   Coordinates: H. monorchis is red-listed in Norway (the monitoring programme is for threatened species, "truet
#   natur", per the source's reports) and the plots carry 1-5 m coordinates: coarsened with coarsen_coords() to the
#   0.1-degree cell centre (E7, source-flagged).
# Not shipped: the 15 Teneskjær plot events of 2025 (no count in the archive); cover of other red-listed plants
#   (percent cover in some plots, not a survey of those species across plots); vegetation structure (eMoF).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "evju_2025_hvaler_herminium_count"
zip <- download_cached("https://ipt.nina.no/archive.do?r=herminium_monitoring_nina", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "measurementorfacts.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("5fcc9f05-0ed9-4e25-8a6a-0894cebd00da/v1.3", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character", na.strings = "")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character", na.strings = "")
pl <- ev[!is.na(parentEventID) & eventID != parentEventID]
h <- oc[scientificName == "Herminium monorchis"]
stopifnot(nrow(ev) == 604L, nrow(pl) == 565L, all(pl$sampleSizeValue == "0,25"), nrow(h) == 550L, !anyDuplicated(h$eventID),
          all(h$eventID %in% pl$eventID), uniqueN(pl$locationID) == 77L,
          setequal(pl[!eventID %in% h$eventID]$eventID, pl[locality == "Teneskjær" & substr(eventDate, 1, 4) == "2025"]$eventID),
          nrow(pl[!eventID %in% h$eventID]) == 15L, !any(pl[!eventID %in% h$eventID]$eventID %in% oc$eventID),
          h[occurrenceStatus == "absent", all(individualCount == "0" & is.na(lifeStage))],
          h[occurrenceStatus == "present", all(as.integer(individualCount) >= 1L & grepl("^\\d+ fertile \\d+ +vegetative$", lifeStage))],
          all(is.na(h$occurrenceRemarks) | grepl("^Plot size for counting Herminium [0-9.]+ m2$", h$occurrenceRemarks)))
pl <- pl[eventID %in% h$eventID]
pl[, year := as.integer(substr(eventDate, 1, 4))]
stopifnot(!anyDuplicated(pl[, .(locationID, year)]), pl[, uniqueN(locality), by = locationID][, all(V1 == 1L)],
          pl[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = locationID][, all(V1 == 1L)])
h[, `:=`(y = as.integer(individualCount),
         nf = as.integer(sub("^(\\d+) fertile.*$", "\\1", lifeStage)), nv = as.integer(sub("^.*fertile +(\\d+) +vegetative$", "\\1", lifeStage)),
         area = fifelse(is.na(occurrenceRemarks), 0.25, as.numeric(sub("^.* ([0-9.]+) m2$", "\\1", occurrenceRemarks))))]
h[occurrenceStatus == "absent", `:=`(nf = 0L, nv = 0L)]
mism <- h[nf + nv != y]
cat(sprintf("  %d present rows whose fertile + vegetative parts do not add up to the count (parts set to NA): %s\n",
            nrow(mism), paste(sprintf("%s %d+%d vs %d", sub("^NINA.Herminium.Monitoring.", "", mism$eventID), mism$nf, mism$nv, mism$y), collapse = "; ")))
h[nf + nv != y, `:=`(nf = NA_integer_, nv = NA_integer_)]
years <- sort(unique(pl$year))
long <- merge(h[, .(eventID, y, obs_n_fertile = nf, obs_n_vegetative = nv, obs_count_area_m2 = area)],
              pl[, .(eventID, unit = locationID, cluster_id = locality, period = match(year, years), date = eventDate,
                     lat = as.numeric(decimalLatitude), lon = as.numeric(decimalLongitude), unc = as.integer(coordinateUncertaintyInMeters))],
              by = "eventID")
cc <- coarsen_coords(long$lat, long$lon, 0.1)
long[, `:=`(taxon = "HERMON", unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, cu = cc$uncertainty_m)]
long[, unit_coordinateUncertaintyInMeters := as.integer(max(unc) + cu), by = unit]
long <- long[, .(unit, taxon, y, period, date, cluster_id, obs_n_fertile, obs_n_vegetative, obs_count_area_m2,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)]
stopifnot(nrow(long) == 550L, sum(long$y == 0L) == 187L)

stopifnot(grepl("Monitoring of effects of conservation actions on threatened species and habitats", eml, fixed = TRUE))

taxa <- make_taxa("HERMON", "Herminium monorchis", vernacularName = "Musk orchid (honningblom)", taxon_family = "Orchidaceae")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxonID, taxon_iucnCategory)])
periods <- data.table(period = seq_along(years), year = years)
cite <- "Evju M (2025). Monitoring of Herminium monorchis. Version 1.3. Norwegian Institute for Nature Research. Samplingevent dataset. https://doi.org/10.15468/rt6t88"
dataset <- list(
  title = sprintf("NINA monitoring of the musk orchid Herminium monorchis: ramet counts in %d permanent plots at %d localities, Hvaler, Norway, %d-%d", uniqueN(long$unit), uniqueN(long$cluster_id), min(years), max(years)),
  creator = "Evju, Marianne (Norwegian Institute for Nature Research, NINA)", pubDate = "2025",
  doi = "10.15468/rt6t88", sourceURL = "https://doi.org/10.15468/rt6t88", citation = cite,
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
  abstract = "Annual counts of fertile and vegetative ramets of the musk orchid Herminium monorchis in permanent 0.5 x 0.5 m plots at its Norwegian localities on Hvaler (Østfold), from NINA's monitoring of the effects of conservation actions on threatened species. Plots were placed around randomly drawn marked plants in 2014 and along transects from 2021, and a fourth locality was added in 2020. One row per plot-year, y the ramets counted.",
  samplingProtocol = "Count of fertile and vegetative ramets with aboveground biomass in a permanently marked 0.5 x 0.5 m plot at peak growing season (late June-July), annually except 2018; in some dense plots the ramets were counted in a smaller marked square (obs_count_area_m2) (Kravdal et al. 2016; Evju et al. 2022).",
  samplingProtocolCode = "botanical_survey", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "none", closureNote = "one count per plot and year; period = year",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Hvaler, Østfold (Viken), southeast Norway: Filletassen, Skipstadsand, Skjellvik, Teneskjær (plot coordinates coarsened to 0.1-degree cell centres)",
  temporalCoverage = sprintf("%d/%d", min(years), max(years)),
  coordinatesCoarsened = list(value = TRUE, rule = "taxon", method = "coarsen_coords(): plot coordinates (1-5 m) snapped to their 0.1-degree cell centre, because the source monitors the species as threatened in Norway (NINA programme 'Monitoring of effects of conservation actions on threatened species and habitats'; E7, source-flagged); uncertainty = the source's plus the cell half-diagonal."),
  covariateNote = "cluster_id = locality; obs_n_fertile and obs_n_vegetative = ramets by stage from the source's lifeStage text (NA where the parts do not add up to the total); obs_count_area_m2 = area in which ramets were counted (0.25 m2 unless the source names a smaller square).",
  notes = sprintf("No counts in 2018. %d present rows carry fertile/vegetative parts that do not add up to the count; y keeps the count and the parts are NA there. The Teneskjær counts of 2025 are not in the archive (events without occurrences).", nrow(mism)),
  notShipped = list(
    `Teneskjær 2025` = "15 plot events with no occurrence row (the count is not in the archive)",
    `other red-listed plants` = "percent cover of 11 other species in some plots (cover, not counts, and not recorded in every plot)",
    `vegetation structure` = "cover and height of vegetation layers per plot (measurementorfacts)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Annual ramet counts of the threatened musk orchid Herminium monorchis in %d permanent plots at its Norwegian localities on Hvaler, %d-%d (NINA).", uniqueN(long$unit), min(years), max(years)),
  url = "https://doi.org/10.15468/rt6t88", reference = cite, doi_paper = "", doi_data = "10.15468/rt6t88",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "NINA IPT DwC-A (herminium_monitoring_nina v1.3). Coordinates coarsened to 0.1 degree (threatened species).",
  source_via = "GBIF (NINA IPT)")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Count model (single species, multi-season)",
  sampling_protocol = "botanical_survey", design = sprintf("Multi-season (%d years x 1 count per plot-year)", length(years)),
  realm = "Terrestrial", country = "NOR", coordinates = "Coarsened (0.1 deg)",
  notes = "Threatened orchid; permanent plots; fertile and vegetative ramets.")
