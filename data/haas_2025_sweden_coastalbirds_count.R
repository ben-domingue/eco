#!/usr/bin/env Rscript
# Table:  haas_2025_sweden_coastalbirds_count (and the E7 sibling haas_2025_sweden_coastal_exact_count)
# Source: GBIF sampling-event dataset 093d659d-99e1-4bd0-9de7-6330b361ea54, doi:10.15468/sg5spw, version 1.8 (2025),
#         Department of Biology, Lund University, via the Swedish GBIF IPT (https://www.gbif.se/ipt/resource?r=lu_sft_kfr).
#         Licence as shown on GBIF and in the EML: CC0 1.0 ("the publisher has waived all rights to these data").
#         Citation: Haas F, Green M, Jönsson A (2025). Swedish Bird Survey: Swedish coastal bird monitoring programme
#         (Nationella kustfågelövervakningen). Version 1.8. Department of Biology, Lund University. Samplingevent dataset.
#         https://doi.org/10.15468/sg5spw
# Paper:  none; protocol at https://www.fageltaxering.lu.se/inventera#kust (summarised in the EML).
# Data:   Darwin Core Archive, event core with occurrence and extended measurement-or-fact extensions.
#   event.txt (1,941 rows): one count of one archipelago square in one breeding season, 2015-2024 (May-June, one in
#     July): eventID SFTkfr:<yyyymmdd>:<square>, eventDate a one-day range, eventTime start/end, sampleSizeValue = the
#     square's area in m2, locality SFTkfr:siteId:<square> (200 squares, 1:1 with locationID), county, decimalLatitude/
#     Longitude = the centre of the 5 x 5 km grid square that holds the survey square's centre (uncertainty 3,500 m).
#     Each square is counted once a year (asserted).
#   occurrence.txt (35,431 rows): one row per species, life stage and count; occurrenceID <event>:<euring>:total:<stage>.
#     34,040 'adult' rows (every species, present only) and 1,391 eider 'pulli' rows (348 present, 1,015 absent = 0) at
#     the 1,363 counts where eider ducklings were counted (eMoF eiderPulliCounted = yes, asserted equal). Larus fuscus is
#     reported as two subspecies (fuscus, intermedius), never at species level. 28 rows of mammals (American mink,
#     badger, red fox) are presence records without a count.
#   extendedmeasurementorfact.txt: per event noObservations (false everywhere), locationType ('Square'),
#     locationProtected ('yes' everywhere), span ('original' or 'redrawn', constant per square), eiderPulliCounted; per
#     occurrence euTaxonID (EU Birds Directive code) and pulliSizeClass for 339 eider pulli rows.
#   Protocol (EML): 200 fixed 2 x 2 km squares along the coast, allocated to the 14 coastal counties by island count;
#     every island in a square is scanned from a boat at most 50 m away and some predetermined islands are walked;
#     all birds counted; once in the breeding season. Withheld (EML informationWithheld): species of Artdatabanken
#     security class 4 or higher (white-tailed eagle, Haliaeetus albicilla) everywhere, and razorbill (Alca torda) on
#     square I0002 (Stora Karlsö).
# Mapping (annual counts, community abundance; responseType count): unit = square (Q<siteId>), period = year 2015..2024,
#   no occasion (one count per square-year), date = eventDate, observer = recordedBy (pseudonymous ids, several joined
#   by '|'), obs_time = eventTime (start/end, as published), unit_county, unit_area_km2, unit_span (square boundary
#   'original' or 'redrawn'). y = individuals counted; for common eider, y = adults + ducklings (ruling on repeated rows
#   within a visit: counts split by life stage are summed, each stage an obs_ column): obs_n_adult on every row,
#   obs_n_pulli on eider rows where ducklings were counted (NA otherwise, and NA for every other species),
#   obs_pulli_size_class (the source's size class of the ducklings, where given). surveyEvidence = sample_table: the
#   event core lists every count and the protocol counts all birds in the square, so a species with no row at a count
#   was counted zero. taxonInclusion = recorded (the birds recorded at least once). __survey_taxa: every taxon at every
#   square, except razorbill at I0002, withheld by the publisher (no rows there).
#   Coordinates: the 5 km grid centres the source publishes (uncertainty 3,500 m). Taxa IUCN VU in their native range
#   breed or stage here (GBIF IUCN records, printed and asserted non-empty), so under E7 (ruling on the publisher,
#   2026-11-06; E7 scope, 3) two tables ship, as for the September waterbird census: this one, every taxon, with the
#   grid centre snapped to its 0.1-degree cell centre (uncertainty = 3,500 m plus the cell half-diagonal), and
#   haas_2025_sweden_coastal_exact_count, without the flagged taxa, at the published centres.
# Not shipped: the mammal rows (presence without a count, not a survey of mammals); euTaxonID; noObservations
#   (constant false), locationType and locationProtected (constants).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "haas_2025_sweden_coastalbirds_count"
EXACT <- "haas_2025_sweden_coastal_exact_count"
zip <- download_cached("https://www.gbif.se/ipt/archive.do?r=lu_sft_kfr", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("093d659d-99e1-4bd0-9de7-6330b361ea54/v1.8", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "extendedmeasurementorfact.txt"), quote = "", colClasses = "character")
ev[, `:=`(sq = sub("^SFTkfr:siteId:", "", locality), date = substr(eventDate, 1, 10), year = as.integer(substr(eventDate, 1, 4)))]
stopifnot(nrow(ev) == 1941L, nrow(oc) == 35431L, !anyDuplicated(ev$eventID),
          all(grepl("^SFTkfr:\\d{8}:[A-Z0-9]+$", ev$eventID)), all(substr(ev$eventDate, 1, 10) == substr(ev$eventDate, 12, 21)),
          all(gsub("-", "", ev$date) == sub("^SFTkfr:(\\d{8}):.*$", "\\1", ev$eventID)),
          all(ev$sq == sub("^SFTkfr:\\d{8}:", "", ev$eventID)), uniqueN(ev$sq) == 200L, uniqueN(ev$locationID) == 200L,
          nrow(unique(ev[, .(sq, locationID, county, decimalLatitude, decimalLongitude, sampleSizeValue)])) == 200L,
          all(ev$sampleSizeUnit == "square metre"), all(ev$coordinateUncertaintyInMeters == "3500"),
          all(ev$geodeticDatum == "EPSG:4326"), !anyDuplicated(ev[, .(sq, year)]), all(ev$year %in% 2015:2024),
          all(substr(ev$date, 6, 7) %in% c("05", "06", "07")),
          grepl("Haliaeetus albicilla", ev$informationWithheld[1], fixed = TRUE),
          grepl("Alca torda) on Stora Karlsö (square I0002)", ev$informationWithheld[1], fixed = TRUE))
stopifnot(all(oc$eventID %in% ev$eventID), all(ev$eventID %in% oc$eventID))
mam <- oc[class == "Mammalia"]
stopifnot(nrow(mam) == 28L, all(mam$individualCount == ""), all(mam$occurrenceStatus == "present"))
oc <- oc[class == "Aves"]
oc[, stage := sub("^.*:total:", "", occurrenceID)]
stopifnot(nrow(oc) == 35403L, all(oc$stage == oc$lifeStage), setequal(oc$stage, c("adult", "pulli")),
          all(oc[stage == "pulli"]$scientificName == "Somateria mollissima"),
          all(oc$organismQuantityType == "individuals"), all(oc$individualCount == oc$organismQuantity),
          oc[stage == "adult", all(occurrenceStatus == "present" & as.integer(individualCount) >= 1L)],
          oc[stage == "pulli" & occurrenceStatus == "absent", all(individualCount == "0")], sum(oc$occurrenceStatus == "absent") == 1015L,
          !anyDuplicated(oc[, .(eventID, scientificName, stage)]), setequal(oc$taxonRank, c("species", "subspecies")),
          !"Larus fuscus" %in% oc$scientificName, !"Alca torda" %in% oc[grepl(":I0002$", eventID)]$scientificName,
          !"Haliaeetus albicilla" %in% oc$scientificName)
mv <- function(t) mf[measurementType == t, .(id, occurrenceID, v = measurementValue)]
stopifnot(all(mv("noObservations")$v == "false"), all(mv("locationProtected")$v == "yes"), all(mv("locationType")$v == "Square"),
          nrow(mv("eiderPulliCounted")) == 1941L,
          setequal(mv("eiderPulliCounted")[v == "yes", id], oc[stage == "pulli", eventID]))
span <- unique(merge(mv("span")[, .(eventID = id, span = v)], ev[, .(eventID, sq)], by = "eventID")[, .(sq, span)])
stopifnot(nrow(span) == 200L, setequal(span$span, c("original", "redrawn")))
psz <- mv("pulliSizeClass")[, .(occurrenceID, pulli_size = v)]
stopifnot(nrow(psz) == 339L, all(psz$occurrenceID %in% oc[stage == "pulli"]$occurrenceID))

# taxa: genus3 + epithet3 codes, the two Larus fuscus subspecies by their third name
sp <- unique(oc[, .(taxonID, scientificName, taxonRank, genus, specificEpithet, infraspecificEpithet, vernacularName)])
stopifnot(nrow(sp) == 84L, !anyDuplicated(sp$scientificName), !anyDuplicated(sp$taxonID))
sp[, taxon := toupper(paste0(substr(genus, 1, 3), substr(specificEpithet, 1, 3), substr(infraspecificEpithet, 1, 3)))]
dup <- sp[taxon %in% sp[duplicated(taxon), taxon]]
cat("  code collisions: ", paste(dup$scientificName, collapse = "; "), "\n")
sp[taxon %in% dup$taxon, taxon := toupper(paste0(substr(genus, 1, 4), substr(specificEpithet, 1, 4), substr(infraspecificEpithet, 1, 4)))]
sp[taxon %in% sp[duplicated(taxon), taxon], taxon := toupper(paste0(substr(genus, 1, 5), substr(specificEpithet, 1, 4)))]
stopifnot(!anyDuplicated(sp$taxon))
oc <- merge(oc, sp[, .(scientificName, taxon)], by = "scientificName")
oc <- merge(oc, psz, by = "occurrenceID", all.x = TRUE)
cnt <- oc[, .(y = sum(as.integer(individualCount)), obs_n_adult = sum(as.integer(individualCount[stage == "adult"])),
              obs_n_pulli = if (any(stage == "pulli")) as.integer(individualCount[stage == "pulli"]) else NA_integer_,
              obs_pulli_size_class = if (any(!is.na(pulli_size))) pulli_size[!is.na(pulli_size)] else NA_character_),
          by = .(eventID, taxon)]

obs <- unique(oc[recordedBy != "", .(eventID, observer = gsub("SFT:recorderId:", "O", recordedBy))])
stopifnot(!anyDuplicated(obs$eventID))
ev <- merge(ev, obs, by = "eventID", all.x = TRUE)
ev <- merge(ev, span, by = "sq")
ev[, eider_pulli := eventID %in% oc[stage == "pulli", eventID]]

st <- CJ(sq = unique(ev$sq), taxon = sp$taxon)[!(sq == "I0002" & taxon == sp[scientificName == "Alca torda", taxon])]
long <- merge(ev[, .(eventID, sq)], st, by = "sq", allow.cartesian = TRUE)
long <- merge(long, cnt, by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, obs_n_adult = 0L)]
eid <- sp[scientificName == "Somateria mollissima", taxon]
long[taxon == eid & is.na(obs_n_pulli) & eventID %in% ev[eider_pulli == TRUE, eventID], obs_n_pulli := 0L]
stopifnot(long[taxon == eid, sum(!is.na(obs_n_pulli))] == sum(ev$eider_pulli), long[taxon != eid, all(is.na(obs_n_pulli))])
years <- 2015:2024
long <- merge(long, ev[, .(eventID, year, date, observer, obs_time = eventTime, unit_county = county,
                          unit_area_km2 = round(as.numeric(sampleSizeValue) / 1e6, 4), unit_span = span,
                          lat = as.numeric(decimalLatitude), lon = as.numeric(decimalLongitude))], by = "eventID")
long <- long[, .(unit = paste0("Q", sq), taxon, y, period = match(year, years), date, observer, obs_time,
                 obs_n_adult, obs_n_pulli, obs_pulli_size_class, unit_county, unit_area_km2, unit_span,
                 unit_decimalLatitude = lat, unit_decimalLongitude = lon, unit_coordinateUncertaintyInMeters = 3500L)]
stopifnot(nrow(long) == 1941L * 84L - sum(ev$sq == "I0002"), sum(long$y) == sum(as.integer(oc$individualCount)),
          sum(long$obs_n_adult) == sum(as.integer(oc[stage == "adult"]$individualCount)), !anyNA(long$period))
survey_taxa <- st[, .(taxon, unit = paste0("Q", sq))]

taxa <- make_taxa(sp$taxon, sp$scientificName, vernacularName = sp$vernacularName, taxonRank = sp$taxonRank,
                  taxon_dyntaxaID = sp$taxonID, taxonRemarks = "vernacularName is the source's Swedish name")
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
fl <- taxa[iu %in% c("CR", "EN", "VU"), taxon]
flag <- taxa[taxon %in% fl, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  IUCN CR/EN/VU: ", paste(flag, collapse = "; "), "\n")
stopifnot(length(fl) >= 1L)
periods <- ev[, .(n_counts = .N), by = year][order(year)]
periods <- data.table(period = match(periods$year, years), periods)

cc <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude, 0.1)
long_c <- copy(long)[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                             unit_coordinateUncertaintyInMeters = as.integer(3500L + cc$uncertainty_m))]
emit <- function(name, exact) {
  lt <- if (exact) long[!taxon %in% fl] else long_c
  tt <- if (exact) taxa[!taxon %in% fl] else taxa
  stx <- survey_taxa[taxon %in% tt$taxon]
  if (exact && eid %in% fl) lt[, c("obs_n_pulli", "obs_pulli_size_class") := NULL]
  nt <- nrow(tt)
  dataset <- list(
    title = paste0(sprintf("Swedish coastal bird monitoring: breeding-season counts of %d bird taxa on %d archipelago squares, 2015-2024", nt, uniqueN(lt$unit)),
                   if (exact) " (taxa that are not IUCN-threatened; coordinates as published)" else ""),
    creator = "Haas, Fredrik; Green, Martin; Jönsson, Annelie (Department of Biology, Lund University)", pubDate = "2025",
    doi = "10.15468/sg5spw", sourceURL = "https://doi.org/10.15468/sg5spw",
    citation = "Haas F, Green M, Jönsson A (2025). Swedish Bird Survey: Swedish coastal bird monitoring programme (Nationella kustfågelövervakningen). Version 1.8. Department of Biology, Lund University. Samplingevent dataset. https://doi.org/10.15468/sg5spw",
    intellectualRights = list(spdx = "CC0-1.0", url = "http://creativecommons.org/publicdomain/zero/1.0/legalcode"),
    abstract = "The Swedish national coastal bird monitoring programme (the archipelago squares), started in 2015 and run by Lund University within the Swedish Bird Survey: 200 fixed 2 x 2 km squares along the Swedish coast, each with at least one island, are counted once in the breeding season, mainly from a boat circling every island at most 50 m off, with some predetermined islands walked. All birds are counted. One row per square-year and species, y the individuals counted; for common eider, ducklings are counted at most squares and added to the adults (both kept as obs_ columns).",
    samplingProtocol = "Breeding-season count of a fixed 2 x 2 km archipelago square, once a year (May-June): all islands scanned from a boat at most 50 m away, predetermined islands walked; all birds counted, eider ducklings counted where the surveyor chose to (Swedish Bird Survey, https://www.fageltaxering.lu.se/inventera#kust).",
    samplingProtocolCode = "area_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
    closure = "none", closureNote = "one count per square and year; period = year; the replication is across years (an annual index)",
    occasionKind = "none", taxonInclusion = "recorded",
    taxaWithheld = "Haliaeetus albicilla",
    geographicCoverage = "Swedish coast, 14 coastal counties (centres of the 5 x 5 km grid squares holding the survey squares)",
    temporalCoverage = sprintf("%s/%s", substr(min(ev$date), 1, 7), substr(max(ev$date), 1, 7)), crs = "EPSG:4326",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("Centres of the 5 x 5 km grid squares holding each survey square, as published (uncertainty 3,500 m). The taxa IUCN-threatened in this range are not in this table (E7 scope, 3): %s; haas_2025_sweden_coastalbirds_count has them, with coordinates coarsened.", paste(flag, collapse = ", "))) else
      list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): the published 5 km grid centres snapped to their 0.1-degree cell centre, because taxa IUCN-threatened in their native range are in the table (E7, ruling on the publisher 2026-11-06): %s. Uncertainty = the source's 3,500 m plus the cell half-diagonal. haas_2025_sweden_coastal_exact_count keeps the other taxa at the published centres.", paste(flag, collapse = ", "))),
    covariateNote = paste0("obs_n_adult = adults counted (equals y except for eider ducklings)", if (exact && eid %in% fl) "" else "; obs_n_pulli = eider ducklings counted (eider rows at counts where ducklings were counted; NA otherwise); obs_pulli_size_class = the source's duckling size class relative to adults, where given", "; obs_time = start/end time of the count as published; unit_span = whether the square boundary is the original or a redrawn one (source eMoF 'span'); unit_area_km2 = square area; observer = the source's pseudonymous recorder ids, several joined by '|'."),
    notes = "White-tailed eagle (Artdatabanken security class 4) is withheld by the publisher (no rows; its absence is not a zero). Razorbill is withheld on square I0002 (Stora Karlsö), which therefore has no razorbill rows (__survey_taxa). One count per square-year, so the replication is across years. Larus fuscus is reported by subspecies (fuscus and intermedius), never at species level. Names are the source's (Dyntaxa) spelling; vernacularName is Swedish.",
    notShipped = c(if (exact) list(`IUCN-threatened taxa` = sprintf("%s: in haas_2025_sweden_coastalbirds_count only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "))), list(
      mammals = "28 presence records of American mink, badger and red fox without a count (mammals are not surveyed)",
      euTaxonID = "EU Birds Directive species codes per occurrence (eMoF)",
      constants = "noObservations (false everywhere), locationType ('Square'), locationProtected ('yes')")))
  ds <- write_table(lt, name, dataset, taxa = tt, periods = periods, survey_taxa = stx, script = "data/haas_2025_sweden_coastalbirds_count.R")
  stage_dict_row(name,
    description = sprintf("Breeding-season counts of %d bird taxa on %d archipelago squares of the Swedish national coastal bird monitoring programme, 2015-2024, one count per square-year, all birds counted.", nt, uniqueN(lt$unit)),
    url = "https://doi.org/10.15468/sg5spw",
    reference = "Haas F, Green M, Jönsson A (2025). Swedish Bird Survey: Swedish coastal bird monitoring programme (Nationella kustfågelövervakningen). Version 1.8. Department of Biology, Lund University. https://doi.org/10.15468/sg5spw",
    doi_paper = "", doi_data = "10.15468/sg5spw", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste0(if (exact) "E7 sibling without the IUCN-threatened taxa; " else "Grid centres coarsened to 0.1 degree (IUCN-threatened taxa); ", "Swedish GBIF IPT DwC-A (lu_sft_kfr v1.8). Survey set = event core; white-tailed eagle withheld by the publisher."),
    source_via = "GBIF (Swedish GBIF IPT, Lund University)")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture / annual count index (multi-species, multi-season)",
    sampling_protocol = "area_count", design = sprintf("Multi-season (%d years x 1 count per square-year)", nrow(periods)),
    realm = "Marine", country = "SWE", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = "National coastal (archipelago) breeding bird monitoring; boat-based counts of 2 x 2 km squares.")
}
emit(TABLE, exact = FALSE)
emit(EXACT, exact = TRUE)
