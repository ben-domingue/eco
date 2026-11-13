#!/usr/bin/env Rscript
# Table:  faria_2026_azores_patella_count
# Source: GBIF Portugal IPT resource gusphd, Darwin Core Archive version 1.2 (GBIF pubDate 2026-09-24); GBIF dataset
#         f54d6a6a-7eac-4e38-8085-b1c5908b017b, doi:10.15468/h2vu7v; EurOBIS / EMODnet Biology IMIS dataset 9139 (found on
#         EDITO). Licence: CC BY 4.0 (EML, GBIF, every occurrence row).
#         Citation: Faria J, Martins G (2026). Quadrat-based survey of rocky intertidal Patella populations in the Azores
#         (2006). Version 1.2. Universidade dos Açores. Samplingevent dataset. https://doi.org/10.15468/h2vu7v
# Paper:  none named; the data come from Martins' PhD (Martins 2009, Universidade dos Açores). Protocol from the EML:
#         July-September 2006, three locations on each of four islands (Flores, Graciosa, Pico, São Miguel); at each
#         location fifteen 25 x 25 cm quadrats placed haphazardly several metres apart within each of three intertidal
#         levels (low, mid, high shore); all limpets counted in situ at low tide.
# Data:   Darwin Core Archive, event core with occurrence and extendedMeasurementOrFact extensions.
#   event.txt (552 rows): 12 location events (parent; locality, island, one coordinate pair, uncertainty 50 m) and 540
#     quadrat events (<location>_rep1..45; habitat 'low-/mid-/high-intertidal basalt platform' gives the level; rep 1-15,
#     16-30, 31-45 are the three levels). eventDate is the year only ('2006'; verbatim 'July–September 2006').
#   occurrence.txt (1,080 rows): every quadrat has a row for each of two limpets, Patella gomesii (the Azorean P. candei
#     gomesii; the titles say P. candei) and Patella aspera, present or absent.
#   extendedmeasurementorfact.txt (173 rows): 'abundance' for the 149 present occurrences, in individuals per square
#     metre: 'density calculated from raw counts obtained in 25 x 25 cm (0.0625 m2) quadrats', so every value is a
#     multiple of 16; plus the sampling area and instrument per location.
# Mapping (repeated counts, spatial replicates; responseType count): unit = location x shore level (36), cluster_id =
#   location (12), occasion = quadrat within the unit (1-15, occasionKind spatial), no period (one campaign). taxon =
#   the two limpets (taxonInclusion = target). y = individuals in the quadrat = density / 16, an exact back-transform of
#   the deposited density (asserted integer), y_raw = the density as deposited; 0 where the occurrence is absent.
#   surveyEvidence = sample_table: the event core lists every quadrat and both species have a row at each.
#   unit_island, unit_shore_level; unit coordinates as published (one point per location, 50 m; no flagged taxon).
# Not shipped: nothing from the deposit beyond the per-location sampling area and instrument (constant).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "faria_2026_azores_patella_count"
zip <- download_cached("https://ipt.gbif.pt/ipt/archive.do?r=gusphd", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE, encoding = "UTF-8"), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE))

rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL, encoding = "UTF-8")
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("extendedmeasurementorfact.txt")
stopifnot(nrow(ev) == 552L, nrow(oc) == 1080L, nrow(mf) == 173L, !anyDuplicated(ev$eventID), !anyDuplicated(oc$occurrenceID),
          all(oc$license == "https://creativecommons.org/licenses/by/4.0/"), all(ev$eventDate == "2006"))
loc <- ev[parentEventID == ""]; q <- ev[parentEventID != ""]
# the quadrats' parentEventID points at shore1 of their island for all three locations, and their island column says
# Graciosa throughout: publisher errors. The location is the eventID prefix, whose locality and coordinates agree.
q[, loc_id := sub("_rep\\d+$", "", eventID)]
stopifnot(nrow(loc) == 12L, nrow(q) == 540L, uniqueN(loc$locality) == 12L, all(q$loc_id %in% loc$eventID),
          all(q$locality == loc$locality[match(q$loc_id, loc$eventID)]),
          all(q$decimalLatitude == loc$decimalLatitude[match(q$loc_id, loc$eventID)]),
          all(q$decimalLongitude == loc$decimalLongitude[match(q$loc_id, loc$eventID)]),
          sum(q$parentEventID != q$loc_id) == 360L, all(q$island == "Graciosa"),
          setequal(loc$island, c("Graciosa", "São Miguel", "Flores", "Pico")))
q[, island := loc$island[match(loc_id, loc$eventID)]]
q[, rep := as.integer(sub(".*_rep", "", eventID))]
q[, level := sub("-intertidal basalt platform$", "", habitat)]
stopifnot(setequal(q$level, c("low", "mid", "high")), q[, .N, by = .(loc_id, level)][, all(N == 15L)],
          q[, all(sort(rep) == 1:45), by = loc_id][, all(V1)])
q[, occasion := rep - 15L * (match(level, c("low", "mid", "high")) - 1L)]
stopifnot(q[, all(occasion %in% 1:15)])   # reps 1-15 low, 16-30 mid, 31-45 high

ab <- mf[measurementType == "abundance"]
stopifnot(nrow(ab) == 149L, all(ab$measurementUnit == "Number per square metre"), !anyDuplicated(ab$occurrenceID),
          all(grepl("^\\d+$", ab$measurementValue)), all(as.integer(ab$measurementValue) %% 16L == 0L),
          all(grepl("0.0625 m", ab$measurementRemarks, fixed = TRUE)))
o <- merge(oc[, .(occurrenceID, eventID, occurrenceStatus, sci = sub(" [A-Z(].*$", "", scientificName))],
           ab[, .(occurrenceID, dens = as.integer(measurementValue))], by = "occurrenceID", all.x = TRUE)
stopifnot(all((o$occurrenceStatus == "present") == !is.na(o$dens)), all(o$dens > 0L, na.rm = TRUE),
          setequal(o$sci, c("Patella gomesii", "Patella aspera")), o[, .N, by = eventID][, all(N == 2L)],
          setequal(o$eventID, q$eventID), !anyDuplicated(o[, .(eventID, sci)]))
o[, `:=`(y = fifelse(is.na(dens), 0L, dens %/% 16L), y_raw = fifelse(is.na(dens), NA_character_, as.character(dens)))]
SP <- data.table(sci = c("Patella gomesii", "Patella aspera"), taxon = c("PATGOM", "PATASP"))

q[, `:=`(unit = paste0(gsub("[^A-Za-z0-9]+", "_", iconv(locality, "UTF-8", "ASCII//TRANSLIT")), "_", level),
         cluster_id = gsub("[^A-Za-z0-9]+", "_", iconv(locality, "UTF-8", "ASCII//TRANSLIT")))]
stopifnot(uniqueN(q$unit) == 36L, uniqueN(q$cluster_id) == 12L)
long <- merge(merge(o, SP, by = "sci"),
              q[, .(eventID, unit, occasion, cluster_id, unit_island = island, unit_locality = locality, unit_shore_level = level,
                    unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
                    unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters))], by = "eventID")
long <- long[, .(unit, taxon, y, y_raw, occasion, cluster_id, unit_island, unit_locality, unit_shore_level,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)]
setorder(long, unit, occasion, taxon)
stopifnot(nrow(long) == 1080L, !anyNA(long$y), sum(long$y > 0L) == 149L, sum(long$y) == sum(o$dens, na.rm = TRUE) / 16)

taxa <- make_taxa(SP$taxon, SP$sci, taxonRemarks = c("Azorean limpet; the dataset titles call it Patella candei (P. candei gomesii)", NA))
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa)
stopifnot(!any(taxa$taxon_iucnCategory %in% c("VU", "EN", "CR")))

dataset <- list(
  title = sprintf("Azorean intertidal limpets: quadrat counts of two Patella species at %d locations x 3 shore levels on four islands, 2006",
                  uniqueN(long$cluster_id)),
  creator = "Faria, João; Martins, Gustavo", pubDate = "2026", doi = "10.15468/h2vu7v", sourceURL = "https://doi.org/10.15468/h2vu7v",
  citation = "Faria J, Martins G (2026). Quadrat-based survey of rocky intertidal Patella populations in the Azores (2006). Version 1.2. Universidade dos Açores. Samplingevent dataset. https://doi.org/10.15468/h2vu7v",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Baseline survey of the two harvested Azorean limpets, Patella gomesii (P. candei) and Patella aspera, on rocky intertidal basalt platforms of Flores, Graciosa, Pico and São Miguel in July-September 2006. Three locations per island; at each, fifteen 25 x 25 cm quadrats in each of the low, mid and high shore. One row per quadrat and species, y = limpets counted; the unit is a location x shore level, the occasion a quadrat.",
  samplingProtocol = "Fifteen 25 x 25 cm quadrats placed haphazardly several metres apart within each of three intertidal levels (low, mid, high shore) at each location; all limpets counted in situ at low tide (Faria & Martins 2026, EML).",
  samplingProtocolCode = "quadrat_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "The quadrats of a unit are spatial replicates counted on one low-tide visit.",
  occasionKind = "spatial", taxonInclusion = "target",
  geographicCoverage = "Azores, Portugal: Flores, Graciosa, Pico and São Miguel (one point per location, 50 m uncertainty)",
  temporalCoverage = "2006-07/2006-09",
  coordinatesCoarsened = list(value = FALSE, method = "One point per location as published (50 m); no flagged taxon."),
  notes = "The deposit gives densities (individuals per m2) computed from counts in 0.0625 m2 quadrats; y is the count (density / 16, exact: every density is a multiple of 16) and y_raw the density as deposited. The visit date is given only as July-September 2006, so there is no date column.",
  notShipped = list(densities = "the per-m2 densities are shipped only as y_raw; y is the count they were computed from"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = "Quadrat counts of the limpets Patella gomesii (P. candei) and P. aspera in low, mid and high shore at 12 rocky intertidal locations on four Azorean islands, 2006.",
  url = "https://doi.org/10.15468/h2vu7v",
  reference = "Faria J, Martins G (2026). Quadrat-based survey of rocky intertidal Patella populations in the Azores (2006). Universidade dos Açores. GBIF.",
  doi_paper = "", doi_data = "10.15468/h2vu7v", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "GBIF Portugal IPT DwC-A (gusphd v1.2); found via EDITO / EurOBIS (IMIS 9139). The IPT returned 404 on 2026-11-11 and served the archive on 2026-11-12.",
  source_via = "GBIF Portugal IPT")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, single-season)",
  sampling_protocol = "quadrat_count", design = "Single-season (15 quadrats per location x shore level)",
  realm = "Marine", country = "PRT", coordinates = "As published",
  notes = "Intertidal quadrat counts of two harvested limpets across shore heights.")
