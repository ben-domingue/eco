#!/usr/bin/env Rscript
# Table:  edp_2019_footua_winterbirds_count (and the E7 sibling edp_2019_footua_winterbd_exact_count, if any taxon is flagged)
# Source: GBIF sampling-event dataset 273d1a81-32e8-4453-9e22-6b78ed0c0ebd, doi:10.15468/ix79tw, version 1.0 (2019),
#         GBIF Portugal IPT resource edp_tua_birds_win_pints_pme. Licence as shown on GBIF and in the EML: CC BY 4.0.
#         Citation: Costa H, Salgueiro N, Santos J, Marques A T, Coelho H, Zina H, Ribeiro E, Pedroso R, Cardoso H,
#         Quirós L, Paula J, Cabral J A, Travassos P, Santos R, Carvalho D, Gomes C, Múrias T (2019): EDP Foz Tua:
#         Terrestrial Birds, Winter (point counts) - Ecological Monitoring Program [2011-2017]. v1. EDP - Energias de
#         Portugal. Dataset/Samplingevent. https://doi.org/10.15468/ix79tw
# Paper:  none; Ecological Monitoring Program of the Foz Tua hydroelectric dam (EML).
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (349 rows): one 5-minute point count in January or February 2011-2017: eventID, eventDate, eventTime,
#     habitat, locationID (the point's code, renumbered over the years: C/A codes in 2011, 'A11/PPFT05B'-style in
#     2012, PPFT01..PPFT60 from 2013, 'PPFT12/11'-style in 2017), coordinates (5 m).
#   occurrence.txt (24,430 rows): one row per count for each of 70 species (present with individualCount, absent 0).
#     Every count has 70 rows; one count of 2011 (BW5.1) holds two species twice and lacks two others (asserted).
#   Protocol (EML): 28 points in 2011, 27 in 2012, a grid of 60 from 2013, in the main habitats of the lower Tua
#     valley (within 5 km), some points counted twice in a winter (and in 2011-2012 some points twice on one day,
#     once per habitat); 5 minutes, all birds seen or heard within two 50 m bands recorded (the bands are not in the
#     archive).
# Mapping (annual counts with occasional repeats; responseType count): unit = point, identified by its coordinates
#   (rounded to 4 decimals, about 10 m; the source's codes change between years), named pNNN in latitude order, with
#   the source codes used at it in unit_source_ids; period = winter (calendar year 2011..2017), occasion = count
#   within the winter in date and time order, date = eventDate, observer = recordedBy, obs_time = eventTime,
#   obs_habitat = habitat as recorded at the count. taxon = the 70 species, y = individuals (individualCount).
#   surveyEvidence = sample_table: every count lists all 70 species, present or absent = 0. taxonInclusion = recorded
#   (the 70 are the species ever recorded in the scheme; the EML names no closed target list).
#   Coordinates: as published (5 m) unless a taxon is IUCN-threatened in its native range (GBIF IUCN records, printed),
#   in which case this table is coarsened to 0.1 degree and the _exact sibling drops the flagged taxa (E7 scope, 3).
# Not shipped: count BW5.1 (2011-01-25, point C1): Galerida cristata and Monticola solitarius twice, Galerida theklae
#   and Motacilla alba missing, so which row belongs to which species is not recoverable; sampleSizeValue and
#   samplingEffort (constant, 5 minutes).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "edp_2019_footua_winterbirds_count"
EXACT <- "edp_2019_footua_winterbd_exact_count"
zip <- download_cached("http://ipt.gbif.pt/ipt/archive.do?r=edp_tua_birds_win_pints_pme", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("edp_tua_birds_win_pints_pme/v1.0", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 349L, nrow(oc) == 24430L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol == "point counts"),
          all(ev$sampleSizeValue == "5"), all(ev$license == "https://creativecommons.org/licenses/by/4.0/legalcode"),
          all(ev$coordinateUncertaintyInMeters == "5"), all(grepl("^\\d{4}-0[12]-\\d{2}$", ev$eventDate)),
          setequal(oc$eventID, ev$eventID), oc[, .N, by = eventID][, all(N == 70L)], uniqueN(oc$scientificName) == 70L,
          oc[occurrenceStatus == "absent", all(individualCount == "0")],
          oc[occurrenceStatus == "present", all(as.integer(individualCount) >= 1L)],
          oc[, uniqueN(recordedBy), by = eventID][, all(V1 == 1L)])
bad <- oc[, .(nd = anyDuplicated(scientificName) > 0), by = eventID][nd == TRUE, eventID]
stopifnot(identical(bad, "BW5.1"))
ev <- ev[eventID != "BW5.1"]; oc <- oc[eventID != "BW5.1"]
stopifnot(!anyDuplicated(oc[, .(eventID, scientificName)]))

ev[, `:=`(lat = round(as.numeric(decimalLatitude), 4), lon = round(as.numeric(decimalLongitude), 4), year = as.integer(substr(eventDate, 1, 4)))]
pts <- ev[, .(unit_source_ids = paste(sort(unique(locationID)), collapse = " | ")), by = .(lat, lon)][order(lat, lon)]
pts[, unit := sprintf("p%03d", .I)]
ev <- merge(ev, pts, by = c("lat", "lon"))
years <- 2011:2017
stopifnot(nrow(pts) == 128L, all(ev$year %in% years))
setorder(ev, unit, eventDate, eventTime, eventID)
ev[, occasion := seq_len(.N), by = .(unit, year)]
obs <- unique(oc[, .(eventID, observer = recordedBy)])
ev <- merge(ev, obs, by = "eventID")

sp <- data.table(scientificName = sort(unique(oc$scientificName)))
sp[, name := sub("^(\\S+ \\S+).*$", "\\1", scientificName)]
fix <- c("Actitis hypoelucos" = "Actitis hypoleucos", "Turdus illiacus" = "Turdus iliacus")
sp[, lookup := fifelse(name %in% names(fix), fix[name], name)]
sp[, taxon := toupper(paste0(substr(lookup, 1, 3), substr(sub("^\\S+ ", "", lookup), 1, 3)))]
dup <- sp[taxon %in% sp[duplicated(taxon), taxon]]
cat("  code collisions: ", paste(dup$lookup, collapse = "; "), "\n")
sp[taxon %in% dup$taxon, taxon := toupper(paste0(substr(lookup, 1, 4), substr(sub("^\\S+ ", "", lookup), 1, 4)))]
stopifnot(!anyDuplicated(sp$taxon), !anyDuplicated(sp$lookup))
oc <- merge(oc, sp[, .(scientificName, taxon)], by = "scientificName")
long <- merge(oc[, .(eventID, taxon, y = as.integer(individualCount))],
              ev[, .(eventID, unit, period = match(year, years), occasion, date = eventDate, observer, obs_time = eventTime,
                     obs_habitat = habitat, unit_source_ids, unit_decimalLatitude = lat, unit_decimalLongitude = lon)], by = "eventID")
long[, eventID := NULL]
long[, unit_coordinateUncertaintyInMeters := 10L]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date", "observer"))
stopifnot(nrow(long) == 348L * 70L, !anyDuplicated(long[, .(unit, taxon, period, occasion)]))

# Chloris is also a grass genus: the bare binomial has no strict GBIF match, so the lookup carries the authorship
taxa <- make_taxa(sp$taxon, sp$lookup, lookupName = fifelse(sp$lookup == "Chloris chloris", "Chloris chloris (Linnaeus, 1758)", sp$lookup),
                  taxonRemarks = ifelse(sp$name != sp$lookup, sprintf("source spelling '%s'", sp$name), NA_character_))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
fl <- taxa[iu %in% c("CR", "EN", "VU"), taxon]
flag <- taxa[taxon %in% fl, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  IUCN CR/EN/VU: ", paste(flag, collapse = "; "), "\n")
periods <- ev[, .(n_counts = .N, n_points = uniqueN(unit)), by = year][order(year)]
periods <- data.table(period = match(periods$year, years), periods)

cite <- "Costa H, Salgueiro N, Santos J, Marques A T, Coelho H, Zina H, Ribeiro E, Pedroso R, Cardoso H, Quirós L, Paula J, Cabral J A, Travassos P, Santos R, Carvalho D, Gomes C, Múrias T (2019): EDP Foz Tua: Terrestrial Birds, Winter (point counts) - Ecological Monitoring Program [2011-2017]. v1. EDP - Energias de Portugal. Dataset/Samplingevent. https://doi.org/10.15468/ix79tw"
emit <- function(name, exact) {
  lt <- copy(long); tt <- taxa
  if (exact) { lt <- lt[!taxon %in% fl]; tt <- taxa[!taxon %in% fl] }
  else if (length(fl)) {
    cc <- coarsen_coords(lt$unit_decimalLatitude, lt$unit_decimalLongitude, 0.1)
    lt[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
              unit_coordinateUncertaintyInMeters = as.integer(10L + cc$uncertainty_m))]
  }
  nt <- nrow(tt)
  dataset <- list(
    title = paste0(sprintf("EDP Foz Tua winter bird point counts: %d species at %d points, lower Tua valley, Portugal, 2011-2017", nt, uniqueN(lt$unit)),
                   if (exact) " (taxa that are not IUCN-threatened; coordinates as published)" else ""),
    creator = "Costa, Hugo; Salgueiro, Nuno; Santos, Joana; and 14 co-authors (EDP - Energias de Portugal; Bio3)", pubDate = "2019",
    doi = "10.15468/ix79tw", sourceURL = "https://doi.org/10.15468/ix79tw", citation = cite,
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
    abstract = "Winter point counts of terrestrial birds for the monitoring programme of the Foz Tua hydroelectric dam (northeast Portugal), run for EDP: points in the main habitats within 5 km of the lower Tua valley (a smaller set in 2011-2012, a grid of 60 from 2013), counted for 5 minutes in January or February, once or occasionally twice a winter, through the dam's construction and the filling of the reservoir. One row per count and species, y the individuals seen or heard.",
    samplingProtocol = "Point count of 5 minutes in the early morning or late afternoon, January-February; all birds seen or heard within two 50 m bands recorded (bands not deposited); once or twice per winter (EDP Foz Tua Ecological Monitoring Program).",
    samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
    closure = "closed", closureNote = "occasion = count within a winter (most point-winters have one); period = winter (calendar year); the replication is mainly across years",
    occasionKind = "time", taxonInclusion = "recorded",
    geographicCoverage = "Lower Tua valley, Vila Real and Bragança districts, northeast Portugal",
    temporalCoverage = sprintf("%s/%s", substr(min(ev$eventDate), 1, 7), substr(max(ev$eventDate), 1, 7)),
    coordinatesCoarsened = if (!length(fl)) list(value = FALSE, method = "Point coordinates as published (5 m), rounded to 4 decimals to match points across years; no species is IUCN-threatened in its native range (GBIF IUCN records).") else if (exact)
      list(value = FALSE, method = sprintf("Point coordinates as published (5 m), rounded to 4 decimals to match points across years. The IUCN-threatened taxa are not in this table (E7 scope, 3): %s; %s has them, with coordinates coarsened.", paste(flag, collapse = ", "), TABLE)) else
      list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): point coordinates snapped to their 0.1-degree cell centre, because IUCN-threatened taxa are in the table (E7): %s. %s keeps the other taxa at the published coordinates.", paste(flag, collapse = ", "), EXACT)),
    covariateNote = "unit_source_ids = the point codes the source used at this location over the years (renumbered between phases); obs_habitat = habitat recorded at the count; obs_time = start/end time as published; observer = the recorder's name as published.",
    notes = "Points are identified by their coordinates (4 decimals) because the source renumbers them between years (2011 C/A codes, 2012 combined codes, PPFT01-60 from 2013, shifted 'PPFT12/11' codes in 2017); the 2013 grid partly moved in 2015. In 2011-2012 some points were counted twice on one day, once per habitat: these are occasions 1 and 2. Two misspellings are corrected in __taxa (source spelling in taxonRemarks).",
    notShipped = c(if (exact && length(fl)) list(`IUCN-threatened taxa` = sprintf("%s: in %s only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "), TABLE)), list(
      `count BW5.1` = "2011-01-25 at point C1: two species listed twice and two missing, so the rows cannot be assigned to species",
      effort = "sampleSizeValue and samplingEffort, constant (5 minutes)")))
  ds <- write_table(lt, name, dataset, taxa = tt, periods = periods, script = "data/edp_2019_footua_winterbirds_count.R")
  stage_dict_row(name,
    description = sprintf("Winter point counts of %d bird species at %d points of the EDP Foz Tua dam monitoring programme, northeast Portugal, January-February 2011-2017.", nt, uniqueN(lt$unit)),
    url = "https://doi.org/10.15468/ix79tw", reference = cite, doi_paper = "", doi_data = "10.15468/ix79tw",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste0(if (exact) "E7 sibling without the IUCN-threatened taxa; " else if (length(fl)) "Coordinates coarsened to 0.1 degree (IUCN-threatened taxa); " else "", "GBIF Portugal IPT DwC-A (edp_tua_birds_win_pints_pme v1.0); points matched across years by coordinates."),
    source_via = "GBIF (GBIF Portugal IPT)")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture / annual count index (multi-species, multi-season)",
    sampling_protocol = "point_count", design = sprintf("Multi-season (%d winters x 1-%d counts)", uniqueN(lt$period), max(lt$occasion)),
    realm = "Terrestrial", country = "PRT", coordinates = if (exact || !length(fl)) "As published" else "Coarsened (0.1 deg)",
    notes = "Hydroelectric dam impact monitoring; winter point counts; points matched across years by coordinates.")
}
emit(TABLE, exact = FALSE)
if (length(fl)) emit(EXACT, exact = TRUE)
