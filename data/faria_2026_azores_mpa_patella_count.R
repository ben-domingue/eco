#!/usr/bin/env Rscript
# Table:  faria_2026_azores_mpa_patella_count
# Source: GBIF Portugal IPT resource gusmpa, Darwin Core Archive version 1.5 (GBIF pubDate 2026-09-24); GBIF dataset
#         8a26c6dc-d210-4021-a9c4-757eba03b3d4, doi:10.15468/m2qvj8; EurOBIS / EMODnet Biology IMIS dataset 9140 (found on
#         EDITO). Licence: CC BY 4.0 (EML, GBIF, every occurrence row).
#         Citation: Faria J, Martins G (2026). Rocky intertidal limpet (Patella candei) populations in the Azores: a
#         quadrat-based comparison between partial and full protection regimes (2006-2008). Version 1.5. Universidade dos
#         Açores. Samplingevent dataset. https://doi.org/10.15468/m2qvj8
# Paper:  none named; Martins' PhD (Martins 2009, Universidade dos Açores). Protocol from the EML: May and September
#         2006-2008, four locations on São Miguel (two in partially and two in fully protected marine areas), two sites
#         (30 m stretches of shore) per location, ten 25 x 25 cm quadrats placed haphazardly at mid shore per site; every
#         Patella candei counted in situ. May is in the closed harvesting season, September in the open season.
# Data:   Darwin Core Archive, event core with occurrence and extendedMeasurementOrFact extensions.
#   event.txt (504 rows): 24 location x campaign events (parent; eventDate YYYY-MM) and 480 quadrat events
#     (<campaign>_GusMPA_1_loc<k>_site<s>_rep1..10), with locality, one coordinate pair per location (50 m), the
#     protection level (locationRemarks: partial or full MPA) and the harvesting season (eventRemarks). Two quadrats name
#     the wrong parent (loc3 for loc4 quadrats in 2007-05); the eventID prefix is used.
#   occurrence.txt (480 rows): one row per quadrat for Patella gomesii (= P. candei gomesii, the dataset's P. candei),
#     present (386) or absent (94).
#   extendedmeasurementorfact.txt (434 rows): 'abundance' for each present occurrence in individuals per square metre,
#     computed from the count in the 0.0625 m2 quadrat (every value a multiple of 16); sampling area and instrument per
#     location-campaign.
# Mapping (repeated counts, spatial replicates, multi-season; responseType count): unit = location x site (8), cluster_id
#   = location (4), period = campaign (1 = May 2006 ... 6 = September 2008), occasion = quadrat within the site-campaign
#   (1-10, occasionKind spatial). taxon = Patella gomesii (single). y = limpets in the quadrat = density / 16 (exact back-
#   transform, asserted integer), y_raw = the density as deposited; 0 where absent. surveyEvidence = sample_table (the
#   event core lists every quadrat, each with an occurrence row). unit_protection (partial / full MPA, from
#   locationRemarks), period facts (year, month, harvest season) in __periods. Coordinates as published (one point per
#   location, 50 m; the two sites of a location share it; no flagged taxon).
# Not shipped: nothing beyond the per-event sampling area and instrument (constant).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "faria_2026_azores_mpa_patella_count"
zip <- download_cached("https://ipt.gbif.pt/ipt/archive.do?r=gusmpa", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE, encoding = "UTF-8"), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("Version 1.5", eml, fixed = TRUE))

rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL, encoding = "UTF-8")
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("extendedmeasurementorfact.txt")
stopifnot(nrow(ev) == 504L, nrow(oc) == 480L, nrow(mf) == 434L, !anyDuplicated(ev$eventID), !anyDuplicated(oc$occurrenceID),
          all(oc$license == "https://creativecommons.org/licenses/by/4.0/"))
loc <- ev[parentEventID == ""]; q <- ev[parentEventID != ""]
q[, `:=`(pre = sub("_site\\d_rep\\d+$", "", eventID), site = as.integer(sub(".*_site(\\d)_rep\\d+$", "\\1", eventID)),
         rep = as.integer(sub(".*_rep", "", eventID)), lk = sub(".*_(loc\\d)_.*", "\\1", eventID))]
stopifnot(nrow(loc) == 24L, nrow(q) == 480L, all(q$pre %in% loc$eventID), sum(q$parentEventID != q$pre) == 2L,
          all(q$eventDate == loc$eventDate[match(q$pre, loc$eventID)]), all(q$locality == loc$locality[match(q$pre, loc$eventID)]),
          setequal(q$eventDate, c("2006-05", "2006-09", "2007-05", "2007-09", "2008-05", "2008-09")),
          q[, uniqueN(paste(locality, decimalLatitude, decimalLongitude, locationRemarks)), by = lk][, all(V1 == 1L)],
          uniqueN(q$locality) == 4L, q[, all(sort(rep) == 1:10), by = .(eventDate, lk, site)][, all(V1)],
          q[, .N, by = .(eventDate, lk, site)][, .N] == 48L)
q[, `:=`(protection = fifelse(grepl(" full ", locationRemarks), "full", fifelse(grepl(" partial ", locationRemarks), "partial", NA_character_)),
         season = fifelse(grepl("closed harvesting season", eventRemarks), "closed", fifelse(grepl("open harvesting season", eventRemarks), "open", NA_character_)))]
stopifnot(!anyNA(q$protection), !anyNA(q$season), all(grepl(" full ", q$eventRemarks) == (q$protection == "full")),
          all((q$season == "closed") == endsWith(q$eventDate, "-05")))

ab <- mf[measurementType == "abundance"]
stopifnot(nrow(ab) == 386L, all(ab$measurementUnit == "Number per square metre"), !anyDuplicated(ab$occurrenceID),
          all(grepl("^\\d+$", ab$measurementValue)), all(as.integer(ab$measurementValue) %% 16L == 0L),
          all(grepl("0.0625 m", ab$measurementRemarks, fixed = TRUE)))
o <- merge(oc[, .(occurrenceID, eventID, occurrenceStatus, sci = sub(" [A-Z(].*$", "", scientificName))],
           ab[, .(occurrenceID, dens = as.integer(measurementValue))], by = "occurrenceID", all.x = TRUE)
stopifnot(all((o$occurrenceStatus == "present") == !is.na(o$dens)), all(o$sci == "Patella gomesii"), setequal(o$eventID, q$eventID),
          !anyDuplicated(o$eventID))
o[, `:=`(y = fifelse(is.na(dens), 0L, dens %/% 16L), y_raw = fifelse(is.na(dens), NA_character_, as.character(dens)))]

camp <- data.table(eventDate = sort(unique(q$eventDate)))[, period := .I]
q <- merge(q, camp, by = "eventDate")
q[, `:=`(cluster_id = gsub("[^A-Za-z0-9]+", "_", locality), unit = paste0(gsub("[^A-Za-z0-9]+", "_", locality), "_site", site))]
long <- merge(o, q[, .(eventID, unit, period, occasion = rep, cluster_id, unit_locality = locality, unit_site = site,
                       unit_protection = protection, unit_decimalLatitude = as.numeric(decimalLatitude),
                       unit_decimalLongitude = as.numeric(decimalLongitude),
                       unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters))], by = "eventID")
long[, taxon := "PATGOM"]
long <- long[, .(unit, taxon, y, y_raw, period, occasion, cluster_id, unit_locality, unit_site, unit_protection,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)]
setorder(long, unit, period, occasion)
stopifnot(nrow(long) == 480L, uniqueN(long$unit) == 8L, !anyNA(long$y), sum(long$y > 0L) == 386L,
          long[, .N, by = .(unit, period)][, all(N == 10L)])

taxa <- make_taxa("PATGOM", "Patella gomesii", taxonRemarks = "Azorean limpet; the dataset title calls it Patella candei (P. candei gomesii)")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("VU", "EN", "CR")))
periods <- unique(q[, .(period, year = as.integer(substr(eventDate, 1, 4)), month = as.integer(substr(eventDate, 6, 7)),
                        harvest_season = season)])
setorder(periods, period)
stopifnot(nrow(periods) == 6L)

dataset <- list(
  title = "Azorean limpet Patella candei inside partially and fully protected marine areas: quadrat counts at 8 sites on São Miguel, May and September 2006-2008",
  creator = "Faria, João; Martins, Gustavo", pubDate = "2026", doi = "10.15468/m2qvj8", sourceURL = "https://doi.org/10.15468/m2qvj8",
  citation = "Faria J, Martins G (2026). Rocky intertidal limpet (Patella candei) populations in the Azores: a quadrat-based comparison between partial and full protection regimes (2006-2008). Version 1.5. Universidade dos Açores. Samplingevent dataset. https://doi.org/10.15468/m2qvj8",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Counts of the harvested Azorean limpet Patella candei (recorded as Patella gomesii) in 25 x 25 cm mid-shore quadrats at four locations around São Miguel, two inside partially and two inside fully protected marine areas, two sites per location, ten quadrats per site, each May (closed harvesting season) and September (open season) of 2006-2008. One row per quadrat, y = limpets counted; the unit is a site, the period a campaign, the occasion a quadrat.",
  samplingProtocol = "Ten 25 x 25 cm quadrats placed haphazardly at mid shore on each of two 30 m sites per location; every Patella candei counted in situ (Faria & Martins 2026, EML).",
  samplingProtocolCode = "quadrat_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "The quadrats of a site-campaign are spatial replicates counted on one low-tide visit; quadrats are placed afresh at each campaign.",
  occasionKind = "spatial", taxonInclusion = "single",
  geographicCoverage = "São Miguel, Azores, Portugal: Cruzeiro, Fenais (partial MPA), Maia, Caloura (full MPA); one point per location, 50 m uncertainty",
  temporalCoverage = "2006-05/2008-09",
  coordinatesCoarsened = list(value = FALSE, method = "One point per location as published (50 m); the two sites of a location share it; no flagged taxon."),
  notes = "The deposit gives densities (individuals per m2) computed from counts in 0.0625 m2 quadrats; y is the count (density / 16, exact: every density is a multiple of 16) and y_raw the density as deposited. Campaign dates are to the month (period); there is no date column.",
  notShipped = list(densities = "the per-m2 densities are shipped only as y_raw; y is the count they were computed from"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = "Quadrat counts of the harvested limpet Patella candei at 8 mid-shore sites in partially and fully protected marine areas of São Miguel (Azores), May and September 2006-2008.",
  url = "https://doi.org/10.15468/m2qvj8",
  reference = "Faria J, Martins G (2026). Rocky intertidal limpet (Patella candei) populations in the Azores: a quadrat-based comparison between partial and full protection regimes (2006-2008). Universidade dos Açores. GBIF.",
  doi_paper = "", doi_data = "10.15468/m2qvj8", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "GBIF Portugal IPT DwC-A (gusmpa v1.5); found via EDITO / EurOBIS (IMIS 9140). The IPT returned 404 on 2026-11-11 and served the archive on 2026-11-12.",
  source_via = "GBIF Portugal IPT")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (single-species, multi-season)",
  sampling_protocol = "quadrat_count", design = "Multi-season (6 campaigns; 10 quadrats per site x campaign)",
  realm = "Marine", country = "PRT", coordinates = "As published",
  notes = "Harvested limpet inside partial and full marine protected areas, closed and open harvesting seasons.")
