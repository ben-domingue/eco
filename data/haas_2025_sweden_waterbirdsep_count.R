#!/usr/bin/env Rscript
# Table:  haas_2025_sweden_waterbirdsep_count
# Source: GBIF sampling-event dataset ecebee66-f913-4105-acb6-738430d0edc9, doi:10.15468/puqjx8, version 1.1 (2025),
#         Department of Biology, Lund University, via the Swedish GBIF IPT (https://www.gbif.se/ipt/resource?r=lu_ssis).
#         Licence as shown on GBIF and in the EML: CC0 1.0 ("the publisher has waived all rights to these data").
#         Citation: Haas F, Jönsson A (2025). Swedish Bird Survey: Swedish waterbird census (September). Version 1.1.
#         Department of Biology, Lund University. Sampling event dataset. https://doi.org/10.15468/puqjx8
# Paper:  none specific; the September census was started in 1973 as a complement to the January census
#         (haas_2025_sweden_waterbird_count, the same scheme layout and the same publisher).
# Data:   Darwin Core Archive, event core with occurrence and extended measurement-or-fact extensions.
#         event.txt (11,813 rows): 52 'season' parent events (SFTssis:<year>:September) and 11,761 'event' rows, one per
#           count of a counting sector: eventID SFTssis:<yyyymmdd>:<sector>:<method letter> (L = from land, 10,973;
#           B = from boat, 586; F = from aeroplane, 202), eventDate a one-day range (September, 23 in October),
#           sampleSizeValue = sector area in km2 (decimal comma; constant per sector), locality SFTssi:siteId:<sector>
#           (1,645 sectors, 1:1 with locationID), county, decimalLatitude/Longitude = the sector centre (8 km uncertainty).
#         occurrence.txt (66,756 rows): individuals per species per count, one row per species per event (asserted);
#           66,661 species rows (48 species) and 95 'Aves' rows with count 0 and occurrenceStatus absent, one for each
#           count that saw no waterbird. recordedBy (pseudonymous observer id) on 10,155 rows, one observer per event.
#         extendedmeasurementorfact.txt: per event noObservations (true on exactly the 95 empty counts, asserted),
#           locationType (coastal / inland), locationProtected (all 'no'); per occurrence euTaxonID.
#         Protocol (EML): about 1,100 coastal and 600 inland sectors have been counted in September; counted once in
#           mid-September; a sector may be counted more than once in a year only by different methods; all waterbirds
#           counted.
# Mapping (annual counts, community abundance; responseType count): unit = counting sector (S<siteId>), period =
#   census year 1973..2024 (the source's season, parentEventID; asserted equal to the count's calendar year), occasion
#   = the sector's counts within a year ordered by method (land, boat, aeroplane; 3 sector-years have two counts, by
#   different methods, asserted), occasionKind = method, obs_method, date = eventDate, observer = recordedBy (NA where
#   not given), unit_location_type, unit_area_km2, unit_county, unit_ coordinates (sector centre, as published).
#   y = individuals of the species counted. surveyEvidence = sample_table: the event core lists every count, the
#   protocol counts all waterbirds, and a count with nothing seen is published (noObservations, an Aves row with 0), so
#   a species with no row at a count was counted zero. taxonInclusion recorded (48 species).
#   Coordinates: the sector centres the source publishes (8 km uncertainty; the data owner is the Swedish
#   Environmental Protection Agency). Taxa IUCN VU in their native range winter here (asserted from GBIF's IUCN records:
#   long-tailed duck, velvet scoter, Steller's eider, common pochard, horned grebe, Atlantic puffin), so under E7 (ruling
#   on the publisher, 2026-11-06, which withdrew the agency exception; batch 46, #10) two tables ship (E7 scope, 3):
#   this one, every taxon, with the sector centre snapped to its 0.1-degree cell centre (uncertainty = 8,000 m plus the
#   cell half-diagonal), and haas_2025_sweden_waterbirdse_exact_count, without the flagged taxa, at the published
#   centres. unit_county (a county, coarser than the cell) and the sector ids (codes, not names) are kept.
# Not shipped: the 'Aves' zero rows (they mark empty counts, which are y = 0 for every taxon here); euTaxonID;
#   locationProtected (constant 'no'); the 52 season parent events.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "haas_2025_sweden_waterbirdsep_count"
zip <- download_cached("https://www.gbif.se/ipt/archive.do?r=lu_ssis", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("ecebee66-f913-4105-acb6-738430d0edc9/v1.1", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "extendedmeasurementorfact.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 11813L, nrow(oc) == 66756L, !anyDuplicated(ev$eventID), sum(ev$eventType == "season") == 52L)
ev <- ev[eventType == "event"]
METH <- c(L = "from land", B = "from boat", F = "from aeroplane")
ev[, mcode := sub("^.*:", "", eventID)]
stopifnot(nrow(ev) == 11761L, all(grepl("^SFTssis:\\d{8}:[A-Za-z0-9]+:[LBF]$", ev$eventID)),
          all(ev$samplingProtocol == METH[ev$mcode]), sum(ev$mcode == "L") == 10973L,
          all(substr(ev$eventDate, 1, 10) == substr(ev$eventDate, 12, 21)),
          all(gsub("-", "", substr(ev$eventDate, 1, 10)) == sub("^SFTssis:(\\d{8}):.*$", "\\1", ev$eventID)),
          all(ev$sampleSizeUnit == "square kilometres"), uniqueN(ev$locality) == 1645L, uniqueN(ev$locationID) == 1645L,
          nrow(unique(ev[, .(locality, locationID, county, decimalLatitude, decimalLongitude, sampleSizeValue)])) == 1645L,
          all(ev$coordinateUncertaintyInMeters == "8000"), all(ev$geodeticDatum == "EPSG:4326"),
          all(sub("^SFTssi:siteId:", "", ev$locality) == sub("^SFTssis:\\d{8}:([A-Za-z0-9]+):.*$", "\\1", ev$eventID)))
stopifnot(all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID), !anyDuplicated(oc[, .(eventID, scientificName)]),
          all(oc$organismQuantityType == "individuals"), all(oc$individualCount == oc$organismQuantity),
          oc[scientificName == "Aves", all(individualCount == "0" & occurrenceStatus == "absent")], sum(oc$scientificName == "Aves") == 95L,
          oc[scientificName != "Aves", all(occurrenceStatus == "present" & as.integer(individualCount) >= 1L)],
          oc[scientificName == "Aves", .N, by = eventID][, all(N == 1L)], oc[, sum(scientificName == "Aves") == 0L | .N == 1L, by = eventID][, all(V1)],
          all(oc[scientificName != "Aves"]$taxonRank == "species"),
          oc[recordedBy != "", uniqueN(recordedBy), by = eventID][, all(V1 == 1L)])
nob <- mf[measurementType == "noObservations"]
stopifnot(nrow(nob) == 11761L, setequal(nob[measurementValue == "true", id], oc[scientificName == "Aves", eventID]),
          all(mf[measurementType == "locationProtected", measurementValue] == "no"))
lt <- mf[measurementType == "locationType", .(eventID = id, unit_location_type = sub("^counting sector, ", "", measurementValue))]
stopifnot(nrow(lt) == 11761L, sum(mf$measurementType == "snowIceCover") == 0L, setequal(lt$unit_location_type, c("coastal", "inland")))

# counts
ev[, `:=`(year = as.integer(sub("^SFTssis:(\\d{4}):September$", "\\1", parentEventID)), unit = sub("^SFTssi:siteId:", "S", locality), date = substr(eventDate, 1, 10),
          method = c(L = "land", B = "boat", F = "aeroplane")[mcode], mord = match(mcode, c("L", "B", "F")))]
years <- 1973:2024
ev[, mon := substr(date, 6, 7)]
stopifnot(all(ev$year %in% years), all(ev$year == as.integer(substr(ev$date, 1, 4))), all(ev$mon %in% c("09", "10")),
          sum(ev$mon == "10") == 23L, !anyDuplicated(ev[, .(unit, year, mcode)]))
cat(sprintf("  months: %s\n", paste(names(table(substr(ev$date, 6, 7))), table(substr(ev$date, 6, 7)), collapse = " ")))
setorder(ev, unit, year, mord)
ev[, occasion := seq_len(.N), by = .(unit, year)]
stopifnot(ev[, .N, by = .(unit, year)][N > 1, .N] == 3L, max(ev$occasion) == 2L)
ev <- merge(ev, lt, by = "eventID")
obs <- unique(oc[recordedBy != "", .(eventID, observer = sub("^SFT:recorderId:", "O", recordedBy))])
ev <- merge(ev, obs, by = "eventID", all.x = TRUE)
stopifnot(nrow(ev) == 11761L, ev[, uniqueN(unit_location_type), by = unit][, all(V1 == 1L)])

# taxa
sp <- unique(oc[scientificName != "Aves", .(taxonID, scientificName, taxonRank, genus, specificEpithet, vernacularName)])
stopifnot(nrow(sp) == 48L, !anyDuplicated(sp$scientificName), !anyDuplicated(sp$taxonID))
sp[, taxon := toupper(paste0(substr(genus, 1, 3), substr(ifelse(specificEpithet == "", "spp", specificEpithet), 1, 3)))]
dup <- sp[taxon %in% sp[duplicated(taxon), taxon]]
cat("  code collisions: ", paste(dup$scientificName, collapse = "; "), "\n")
sp[taxon %in% dup$taxon, taxon := toupper(paste0(substr(genus, 1, 4), substr(specificEpithet, 1, 4)))]
stopifnot(!anyDuplicated(sp$taxon))
oc <- merge(oc[scientificName != "Aves"], sp[, .(scientificName, taxon)], by = "scientificName")
oc[, y := as.integer(individualCount)]

long <- CJ(eventID = ev$eventID, taxon = sp$taxon)
long <- merge(long, oc[, .(eventID, taxon, y)], by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, ev[, .(eventID, unit, year, occasion, date, observer, unit_county = county, unit_location_type,
                          unit_area_km2 = as.numeric(sub(",", ".", sampleSizeValue)),
                          unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
                          obs_method = method)], by = "eventID")
long[, `:=`(period = match(year, years), unit_coordinateUncertaintyInMeters = 8000L)]
long <- long[, .(unit, taxon, y, period, occasion, date, observer, unit_county, unit_location_type, unit_area_km2,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters, obs_method)]
stopifnot(nrow(long) == 11761L * 48L, sum(long$y) == sum(oc$y), sum(long$y > 0) == nrow(oc), !anyNA(long$period))
cat(sprintf("  %s rows = %d counts x %d taxa; %d counts saw nothing\n", format(nrow(long), big.mark = ","), nrow(ev), nrow(sp), 95L))

lookup <- sp$scientificName
taxa <- make_taxa(sp$taxon, sp$scientificName, vernacularName = sp$vernacularName, taxonRank = sp$taxonRank,
                  lookupName = lookup, taxon_dyntaxaID = sp$taxonID,
                  taxonRemarks = "vernacularName is the source's Swedish name")
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
flag <- taxa[iu %in% c("CR", "EN", "VU"), sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  IUCN CR/EN/VU: ", paste(flag, collapse = "; "), "\n")
periods <- ev[, .(n_counts = .N, n_sectors = uniqueN(unit)), by = year][order(year)]
periods <- data.table(period = match(periods$year, years), periods)

fl <- taxa[iu %in% c("CR", "EN", "VU"), taxon]
stopifnot(length(fl) >= 1L)
# E7 (ruling on the publisher, 2026-11-06): the sector centres are coarsened to their 0.1-degree cell centre in the
# table with every taxon; the _exact sibling drops the flagged taxa and keeps the centres as published (E7 scope, 3)
cc <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude, 0.1)
long_c <- copy(long)[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                             unit_coordinateUncertaintyInMeters = as.integer(8000L + cc$uncertainty_m))]
EXACT <- "haas_2025_sweden_waterbirdse_exact_count"
emit <- function(TABLE, exact) {
  lt <- if (exact) long[!taxon %in% fl] else long_c
  tt <- if (exact) taxa[!taxon %in% fl] else taxa
  nt <- nrow(tt)
  stopifnot(nrow(lt) == nrow(ev) * nt)
  dataset <- list(
    title = paste0(sprintf("Swedish waterbird census (September): counts of %d waterbird species on %s counting sectors, 1973-2024", nt, format(uniqueN(ev$unit), big.mark = ",")), if (exact) " (taxa that are not IUCN-threatened; coordinates as published)" else ""),
    creator = "Haas, Fredrik; Jönsson, Annelie (Department of Biology, Lund University)", pubDate = "2025",
    doi = "10.15468/puqjx8", sourceURL = "https://doi.org/10.15468/puqjx8",
    citation = "Haas F, Jönsson A (2025). Swedish Bird Survey: Swedish waterbird census (September). Version 1.1. Department of Biology, Lund University. Sampling event dataset. https://doi.org/10.15468/puqjx8",
    intellectualRights = list(spdx = "CC0-1.0", url = "http://creativecommons.org/publicdomain/zero/1.0/legalcode"),
    abstract = "The Swedish September waterbird census, started in 1973 as a complement to the midwinter census and run by Lund University within the Swedish Bird Survey: volunteers count all roosting and migrating waterbirds on fixed counting sectors of coast, lakes and rivers once in mid-September, from land (standard), boat or aeroplane; a sector may be counted more than once in a year only by different methods. One row per sector count and species, y the individuals counted; a count that saw nothing is published by the source and is y = 0 for every species.",
    samplingProtocol = "September waterbird count of a fixed counting sector (coastal or inland), once in mid-September, from land (one or more vantage points), boat or aeroplane; all waterbirds in the sector counted (Swedish Bird Survey).",
    samplingProtocolCode = "area_count", surveyEvidence = "sample_table",
    responseType = "count", unitKind = "site",
    closure = "closed", closureNote = "occasion = the counts of a sector within one September by different methods (3 sector-years have two); period = census year; nearly all sector-years have one count",
    occasionKind = "method", taxonInclusion = "recorded",
    geographicCoverage = "Sweden, coast and inland waters (counting-sector centres)",
    temporalCoverage = sprintf("%s/%s", substr(min(ev$date), 1, 7), substr(max(ev$date), 1, 7)), crs = "EPSG:4326",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("Sector centre points as published by the scheme (uncertainty 8 km). The taxa IUCN VU in this range are not in this table (E7 scope, 3): %s; haas_2025_sweden_waterbirdsep_count has them, with coordinates coarsened.", paste(flag, collapse = ", "))) else
      list(value = TRUE, method = sprintf("coarsen_coords(): the published sector centres snapped to their 0.1-degree cell centre, because taxa IUCN VU in their native range are in the table (E7, ruling on the publisher 2026-11-06, which withdrew the agency exception): %s. Uncertainty = the source's 8,000 m plus the cell half-diagonal. haas_2025_sweden_waterbirdse_exact_count keeps the other taxa at the published centres.", paste(flag, collapse = ", "))),
    covariateNote = "obs_method = how the sector was counted (land, boat, aeroplane); unit_location_type = coastal or inland sector; unit_area_km2 = sector area; observer = the source's pseudonymous recorder id, NA where not given.",
    notes = "One count per sector-year by default, so the replication is across years (an annual index); counts by two methods in one year are occasions. Names are the source's (Dyntaxa) spelling; vernacularName is Swedish. Companion of haas_2025_sweden_waterbird_count (January census).",
    notShipped = c(if (exact) list(`IUCN VU taxa` = sprintf("%s: in haas_2025_sweden_waterbirdsep_count only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "))), list(
      `Aves zero rows` = "95 placeholder rows marking counts with no waterbird (noObservations = true); those counts are y = 0 for every species",
      euTaxonID = "EU Article 12 species codes per occurrence (eMoF)",
      locationProtected = "constant 'no'",
      seasons = "the 52 season parent events (one per year)")))
  ds <- write_table(lt, TABLE, dataset, taxa = tt, periods = periods, script = sprintf("data/%s.R", TABLE))

  stage_dict_row(TABLE,
    description = sprintf("September counts of %d waterbird species on %s counting sectors of the Swedish waterbird census (September), 1973-2024, %s counts from land, boat or aeroplane, with explicit zeros (empty counts published by the source).", nt, format(uniqueN(ev$unit), big.mark = ","), format(nrow(ev), big.mark = ",")),
    url = "https://doi.org/10.15468/puqjx8",
    reference = "Haas F, Jönsson A (2025). Swedish Bird Survey: Swedish waterbird census (September). Version 1.1. Department of Biology, Lund University. https://doi.org/10.15468/puqjx8",
    doi_paper = "", doi_data = "10.15468/puqjx8",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste0(if (exact) "E7 sibling without the IUCN VU taxa; " else "Sector centres coarsened to 0.1 degree (IUCN VU taxa); ", "Swedish GBIF IPT DwC-A (lu_ssis v1.1). Survey set = event core; empty counts flagged noObservations. Sector-centre coordinates as published in the _exact sibling."),
    source_via = "GBIF (Swedish GBIF IPT, Lund University)")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture / annual count index (multi-species, multi-season)",
    sampling_protocol = "area_count", design = sprintf("Multi-season (%d years x 1-2 counts per sector-year)", nrow(periods)),
    realm = "Freshwater", country = "SWE", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = "National September waterbird census; coastal and inland sectors; method as occasion.")
}
emit("haas_2025_sweden_waterbirdsep_count", exact = FALSE)
emit(EXACT, exact = TRUE)
