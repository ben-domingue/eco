#!/usr/bin/env Rscript
# Table:  faria_2026_azores_plates_count
# Source: GBIF Portugal IPT resource patella-chthamalus-recruitment, Darwin Core Archive (GBIF pubDate 2026-09-24); GBIF
#         dataset a5ca1de9-a24d-41de-afbe-a944aa94357a, doi:10.15468/h3sywy; EurOBIS / EMODnet Biology IMIS dataset 9141
#         (found on EDITO). Licence: CC BY 4.0 (EML, GBIF, every occurrence row).
#         Citation: Faria J (2026). Recruitment dynamics and seasonal variability of Patella candei and Chthamalus
#         stellatus on rocky intertidal shores of São Miguel Island (Azores, NE Atlantic). Universidade dos Açores.
#         Samplingevent dataset. https://doi.org/10.15468/h3sywy
# Paper:  none named; the data come from Faria's PhD work (Universidade dos Açores). Protocol from the EML: March 2019 to
#         January 2020, four rocky-shore locations around São Miguel; at each, natural-basalt settlement plates
#         (7 x 7 x 2 cm) screwed to the mid-intertidal rock, retrieved and replaced monthly, and the recruits of the limpet
#         Patella candei (shell < 0.5 cm) and the barnacle Chthamalus stellatus counted under a stereomicroscope.
# Data:   Darwin Core Archive, event core with occurrence and extendedMeasurementOrFact extensions.
#   event.txt (583 rows): 44 location-month events (parent; one per location per monthly retrieval; sampleSizeValue =
#     0.0154 m2 x the plates retrieved; samplingEffort '1 plate (7x7x2) deployed for N days') and 539 plate events
#     (<parent>_rep1..15; up to 15 plates per location-month, the missing rep numbers are plates not retrieved).
#     eventDate is the retrieval date: the deployment days equal the gap to the previous retrieval.
#     The plate ids are the source's site codes (CALOURA, CRUZEIRO, FORNO CAL, RIBEIRA TAINHAS); locality gives a place
#     name, and FORNO CAL's March 2019 event says Lagoa where every later one says Ponta Delgada.
#   occurrence.txt (1,078 rows): every plate has a row for each of Patella gomesii (the Azorean P. candei; the title
#     says P. candei) and Chthamalus stellatus, present or absent.
#   extendedmeasurementorfact.txt (621 rows): 'abundance' for the 535 present occurrences, unit 'Number per square
#     metre', remark 'Density calculated from raw counts on 7x7x2 cm (0.0154 m2) settlement plate'; plus sampling area
#     and instrument per location-month.
#   The abundance label is wrong. The values are small whole numbers (1-234) and none is a multiple of 1/0.0154; asked
#   by Ben Domingue (2026-11-13), the author João Faria replied (email, 2026-11-17) that they are raw counts per plate,
#   that 0.0154 m2 is the plate's whole surface (face, sides and bottom of the 7 x 7 x 2 cm stone), and that CRUZEIRO
#   is at Lagoa and FORNO CAL ('Forno da Cal') at Ponta Delgada. He also said some details of the deposit will be
#   corrected; the assertions below fail if a corrected version changes the files.
# Mapping (repeated counts, spatial replicates; responseType count): unit = location (4, the source's site code),
#   period = retrieval month (1-11, 2019-03 to 2020-01), occasion = plate within the location-month (its rep number,
#   occasionKind spatial). taxon = the two species (taxonInclusion = target). y = recruits counted on the plate, the
#   deposited value (0 where the occurrence is absent). date = retrieval date. period_deployDays = days the plates of
#   that location-month were out (constant within unit x period). surveyEvidence = sample_table: the event core lists
#   every retrieved plate and both species have a row on each. unit_locality as the author gave it; unit coordinates
#   as published (one point per location, 50 m; no flagged taxon).
# Not shipped: nothing beyond the per-event sampling area (0.0154 m2 per plate, constant) and instrument (constant).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "faria_2026_azores_plates_count"
zip <- download_cached("https://ipt.gbif.pt/ipt/archive.do?r=patella-chthamalus-recruitment", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE, encoding = "UTF-8"), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("7 × 7 × 2 cm", eml, fixed = TRUE))

rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL, encoding = "UTF-8")
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("extendedmeasurementorfact.txt")
stopifnot(nrow(ev) == 583L, nrow(oc) == 1078L, nrow(mf) == 621L, !anyDuplicated(ev$eventID), !anyDuplicated(oc$occurrenceID),
          all(oc$license == "https://creativecommons.org/licenses/by/4.0/"),
          all(ev$habitat == "mid-intertidal basalt platform"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)))
loc <- ev[parentEventID == ""]; q <- ev[parentEventID != ""]
SITES <- data.table(site = c("CALOURA", "CRUZEIRO", "FORNO CAL", "RIBEIRA TAINHAS"),
                    unit = c("Caloura", "Cruzeiro", "Forno_da_Cal", "Ribeira_Tainhas"),
                    locality = c("Caloura", "Lagoa", "Ponta Delgada", "Ribeira das Taínhas"))  # author, 2026-11-17
loc[, site := sub("^.*?T00:00(-01:00|Z)", "", eventID)]
loc[, month := substr(eventDate, 1, 7)]
stopifnot(nrow(loc) == 44L, nrow(q) == 539L, setequal(loc$site, SITES$site), all(q$parentEventID %in% loc$eventID),
          !anyDuplicated(loc[, .(site, month)]), uniqueN(loc$month) == 11L, loc[, .N, by = month][, all(N == 4L)],
          # source locality agrees with the author's key except FORNO CAL in March 2019 ('Lagoa')
          loc[locality != SITES$locality[match(site, SITES$site)], .N] == 1L,
          loc[locality != SITES$locality[match(site, SITES$site)], site == "FORNO CAL" & month == "2019-03"],
          loc[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = site][, all(V1 == 1L)],
          all(loc$coordinateUncertaintyInMeters == "50"))
loc[, deploy_days := as.integer(sub("^1 plate \\(7x7x2\\) deployed for (\\d+) days$", "\\1", samplingEffort))]
q[, rep := as.integer(sub("^.*_rep", "", eventID))]
q <- merge(q[, .(eventID, parentEventID, rep, eventDate, samplingEffort)],
           loc[, .(parentEventID = eventID, site, month, ldate = eventDate, deploy_days, ssv = as.numeric(sampleSizeValue),
                   lat = as.numeric(decimalLatitude), lon = as.numeric(decimalLongitude))], by = "parentEventID")
stopifnot(!anyNA(loc$deploy_days), all(q$eventDate == q$ldate), all(q$rep %in% 1:15), !anyDuplicated(q[, .(parentEventID, rep)]),
          q[, .(n = .N, ssv = ssv[1]), by = parentEventID][, all(abs(ssv - 0.0154 * n) < 1e-9)],   # area = 0.0154 m2 x plates
          all(q$samplingEffort == loc$samplingEffort[match(q$parentEventID, loc$eventID)]))
# eventDate is the retrieval date: each deployment span equals the gap since that location's previous retrieval
setorder(loc, site, eventDate)
gap <- loc[, .(d = deploy_days[-1], g = as.integer(diff(as.Date(eventDate)))), by = site]
stopifnot(gap[, mean(d == g) > 0.9])

ab <- mf[measurementType == "abundance"]
stopifnot(nrow(ab) == 535L, all(ab$measurementUnit == "Number per square metre"), !anyDuplicated(ab$occurrenceID),
          all(grepl("^\\d+$", ab$measurementValue)), all(grepl("0.0154 m", ab$measurementRemarks, fixed = TRUE)),
          max(as.integer(ab$measurementValue)) == 234L)   # whole numbers: a count x 1/0.0154 would not be
o <- merge(oc[, .(occurrenceID, eventID, occurrenceStatus, sci = sub(" [A-Z(].*$", "", scientificName))],
           ab[, .(occurrenceID, n = as.integer(measurementValue))], by = "occurrenceID", all.x = TRUE)
stopifnot(all((o$occurrenceStatus == "present") == !is.na(o$n)), all(o$n > 0L, na.rm = TRUE),
          setequal(o$sci, c("Patella gomesii", "Chthamalus stellatus")), o[, .N, by = eventID][, all(N == 2L)],
          setequal(o$eventID, q$eventID), !anyDuplicated(o[, .(eventID, sci)]))
o[, y := fifelse(is.na(n), 0L, n)]
SP <- data.table(sci = c("Patella gomesii", "Chthamalus stellatus"), taxon = c("PATGOM", "CHTSTE"))

months <- sort(unique(loc$month))
q[, `:=`(period = match(month, months), unit = SITES$unit[match(site, SITES$site)],
         unit_locality = SITES$locality[match(site, SITES$site)])]
long <- merge(merge(o, SP, by = "sci"),
              q[, .(eventID, unit, period, occasion = rep, date = eventDate, unit_locality, unit_sourceSiteCode = site,
                    unit_decimalLatitude = lat, unit_decimalLongitude = lon, unit_coordinateUncertaintyInMeters = 50L,
                    period_deployDays = deploy_days)], by = "eventID")
long <- long[, .(unit, taxon, y, period, occasion, date, unit_locality, unit_sourceSiteCode, unit_decimalLatitude,
                 unit_decimalLongitude, unit_coordinateUncertaintyInMeters, period_deployDays)]
setorder(long, unit, period, occasion, taxon)
stopifnot(nrow(long) == 1078L, uniqueN(long$unit) == 4L, uniqueN(long$period) == 11L, !anyNA(long$y),
          sum(long$y > 0L) == 535L, sum(long$y) == sum(o$n, na.rm = TRUE),
          long[, uniqueN(unit), by = period][, all(V1 == 4L)])

taxa <- make_taxa(SP$taxon, SP$sci, taxonRemarks = c("Azorean limpet; the dataset title calls it Patella candei; recruits (shell < 0.5 cm) only",
                                                     "recruits only"))
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa)
stopifnot(!any(taxa$taxon_iucnCategory %in% c("VU", "EN", "CR")))
periods <- loc[, .(period_start = min(eventDate), period_end = max(eventDate)), by = month][order(month)]
periods <- periods[, .(period = match(month, months), month, retrieval_start = period_start, retrieval_end = period_end)]
stopifnot(nrow(periods) == 11L, identical(periods$period, 1:11))

dataset <- list(
  title = "Recruitment of the limpet Patella candei and the barnacle Chthamalus stellatus on monthly settlement plates at 4 rocky-shore locations, São Miguel (Azores), 2019-2020",
  creator = "Faria, João", pubDate = "2026", doi = "10.15468/h3sywy", sourceURL = "https://doi.org/10.15468/h3sywy",
  citation = "Faria J (2026). Recruitment dynamics and seasonal variability of Patella candei and Chthamalus stellatus on rocky intertidal shores of São Miguel Island (Azores, NE Atlantic). Universidade dos Açores. Samplingevent dataset. https://doi.org/10.15468/h3sywy",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Natural-basalt settlement plates (7 x 7 x 2 cm), up to 15 per location, screwed to the mid-intertidal rock at four locations around São Miguel and retrieved and replaced monthly from March 2019 to January 2020; recruits of the limpet Patella candei (recorded as Patella gomesii; shell under 0.5 cm) and the barnacle Chthamalus stellatus counted under a stereomicroscope. One row per plate and species, y = recruits counted; the unit is a location, the period a retrieval month, the occasion a plate.",
  samplingProtocol = "Settlement plates of natural basalt (7 x 7 x 2 cm) screwed onto mid-intertidal rock, left to colonise for about a month (20-51 days), then retrieved, replaced, and examined under a stereomicroscope; recruits of both species counted per plate (Faria 2026, EML).",
  samplingProtocolCode = "settlement_plate", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "The plates of a location-month are spatial replicates exposed over the same interval and retrieved together; the recruit supply changes between months.",
  occasionKind = "spatial", taxonInclusion = "target",
  geographicCoverage = "São Miguel, Azores, Portugal: Caloura, Cruzeiro (Lagoa), Forno da Cal (Ponta Delgada), Ribeira das Taínhas; one point per location, 50 m uncertainty",
  temporalCoverage = "2019-03/2020-01",
  coordinatesCoarsened = list(value = FALSE, method = "One point per location as published (50 m); no flagged taxon."),
  notes = "The deposit labels the values individuals per m2 'calculated from raw counts on a 0.0154 m2 plate', but they are raw counts per plate: the author, João Faria, confirmed this by email to Ben Domingue on 2026-11-17 (0.0154 m2 is the plate's whole surface, face, sides and bottom). y is the deposited value. He also gave the plate-site key (Cruzeiro is at Lagoa, Forno da Cal at Ponta Delgada; the deposit's March 2019 Forno da Cal event says Lagoa) and said some details of the deposit would be corrected. Missing plate numbers within a location-month are plates not retrieved (no row). date is the retrieval date; period_deployDays the days those plates were out.",
  notShipped = list(sampling_area = "0.0154 m2 per plate, constant; the per-event total is 0.0154 x the plates retrieved",
                    sampling_instrument = "'7x7x2 cm settlement plate', constant"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = "Monthly settlement-plate counts of limpet (Patella candei) and barnacle (Chthamalus stellatus) recruits at 4 mid-intertidal locations on São Miguel (Azores), March 2019 to January 2020.",
  url = "https://doi.org/10.15468/h3sywy",
  reference = "Faria J (2026). Recruitment dynamics and seasonal variability of Patella candei and Chthamalus stellatus on rocky intertidal shores of São Miguel Island (Azores, NE Atlantic). Universidade dos Açores. GBIF.",
  doi_paper = "", doi_data = "10.15468/h3sywy", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "GBIF Portugal IPT DwC-A (patella-chthamalus-recruitment); found via EDITO / EurOBIS (IMIS 9141). Values labelled per m2 in the deposit are counts per plate (author email 2026-11-17).",
  source_via = "GBIF Portugal IPT")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "settlement_plate", design = "Multi-season (11 monthly retrievals; up to 15 plates per location x month)",
  realm = "Marine", country = "PRT", coordinates = "As published",
  notes = "Intertidal larval settlement: monthly recruitment plates for a limpet and a barnacle.")
