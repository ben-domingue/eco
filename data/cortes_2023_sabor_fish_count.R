#!/usr/bin/env Rscript
# Table:  cortes_2023_sabor_fish_count (and the E7 sibling cortes_2023_sabor_fish_exact_count, if any taxon is flagged)
# Source: GBIF sampling-event dataset 33d6fee2-ffc3-45db-a6ae-c781972ab207, doi:10.15468/ut55sa, version 1.0 (2023),
#         GBIF Portugal IPT resource edp_sabor_ichtyofauna_2015-20. Licence as shown on GBIF and in the EML: CC BY 4.0.
#         Citation: Cortes R, Varandas S, Jesus J, Santos C, Lopes M, Pereira V, Bessa I, Assunção T, Albuquerque A,
#         Sanches D (2023). EDP Baixo Sabor: Fishes – Ecological Monitoring and Complementary Measures Programs
#         [2015-2020]. Version 1.0. EDP - Energias de Portugal. Samplingevent dataset. https://doi.org/10.15468/ut55sa
# Paper:  none; Ecological Monitoring (PME) and Compensatory Measures (PMC) programmes of the Baixo Sabor dams (EML).
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (456 rows): one fishing event at one station: samplingProtocol 'electric fishing' (408), 'deep netting'
#     (24), 'surface netting' (24); sampleSizeValue/Unit (electrofishing minutes, 0 on 34 events; netting area in m2),
#     samplingEffort ('4 person-minute', '3 person-minute', '3 person-14 hours'), habitat (lotic / lentic),
#     locationID (68 stations; PIMA ... = PMC stations, a trailing C marks a control; ... PMEAS = PME stations),
#     locationRemarks (which programme and compensatory measure uses the station), waterBody, coordinates (5 m).
#     Every station is electrofished once a year 2015-2020; the four lentic PME stations (7, 9, 14, 15 PMEAS) are also
#     netted (deep and surface gill nets) each year (asserted).
#   occurrence.txt (8,208 rows): one row per event for each of 18 classes (17 species and the genus Achondrostoma),
#     present with individualCount, absent 0. 'Sender lucioperca' and 'Cobitis paludicola' are
#     misspellings of Sander lucioperca and Cobitis paludica.
#   Protocol (EML): lotic stations electrofished with restitution; lentic stations in the reservoirs sampled with
#     surface and deep netting and with electrofishing of the margins; spring-summer each year, exploration phase of
#     the dams (2015-2020); PMC compensatory measures MC1, MC2, MC3, MC10 compared with control stations.
# Mapping (annual counts with methods as occasions; responseType count): unit = station (locationID), period = year
#   2015..2020, occasion = method within the year (electrofishing 1, then surface netting 2 and deep netting 3 at the
#   four lentic stations; occasionKind = method, a paired design under E9's multi-method form), obs_method, date =
#   eventDate. obs_duration_min = electrofishing minutes (NA where the source gives 0), obs_area_m2 = netted area,
#   obs_effort = samplingEffort as published, obs_habitat = habitat at the event. unit_program = locationRemarks,
#   unit_control = 1 for PMC control stations (name ending in C), unit_water_body. taxon = the 18 classes, y =
#   individuals caught. surveyEvidence = sample_table: every event reports all 18 classes, present or absent = 0.
#   taxonInclusion = target. Station PIMA A2C is published at one point in 2015-2019 and at another, 22 km away, in
#   2020; the 2020 event is the separate unit PIMA A2C_2020.
#   Coordinates as published (5 m) unless a species is IUCN-threatened in its native range (GBIF IUCN records,
#   printed), in which case this table is coarsened to 0.1 degree and the _exact sibling drops the flagged taxa.
# Not shipped: nothing beyond the 0-minute durations (NA).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "cortes_2023_sabor_fish_count"
EXACT <- "cortes_2023_sabor_fish_exact_count"
zip <- download_cached("http://ipt.gbif.pt/ipt/archive.do?r=edp_sabor_ichtyofauna_2015-20", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("edp_sabor_ichtyofauna_2015-20/v1.0", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
ev[, year := as.integer(substr(eventDate, 1, 4))]
METH <- c("electric fishing" = 1L, "surface netting" = 2L, "deep netting" = 3L)
lentic <- c("14 PMEAS", "15 PMEAS", "7 PMEAS", "9 PMEAS")
stopifnot(nrow(ev) == 456L, nrow(oc) == 8208L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol %in% names(METH)),
          all(grepl("^\\d{4}-0[67]-\\d{2}$", ev$eventDate)), uniqueN(ev$locationID) == 68L, all(ev$year %in% 2015:2020),
          ev[samplingProtocol == "electric fishing", .N, by = .(locationID, year)][, all(N == 1L)],
          ev[samplingProtocol == "electric fishing", .N, by = locationID][, all(N == 6L)],
          setequal(ev[samplingProtocol != "electric fishing"]$locationID, lentic),
          ev[samplingProtocol != "electric fishing", .N, by = .(locationID, year, samplingProtocol)][, all(N == 1L)],
          ev[samplingProtocol == "electric fishing", all(sampleSizeUnit == "minutes")],
          ev[samplingProtocol != "electric fishing", all(sampleSizeUnit == "square meters")],
          sum(ev$sampleSizeValue == "0") == 34L, ev[, uniqueN(waterBody), by = locationID][, all(V1 == 1L)],
          all(oc$license == "https://creativecommons.org/licenses/by/4.0/legalcode"),
          setequal(oc$eventID, ev$eventID), oc[, .N, by = eventID][, all(N == 18L)], !anyDuplicated(oc[, .(eventID, scientificName)]),
          oc[occurrenceStatus == "absent", all(individualCount == "0")],
          oc[occurrenceStatus == "present", all(as.integer(individualCount) >= 1L)])
ev[, unit := locationID]
ev[locationID == "PIMA A2C" & year == 2020L, unit := "PIMA A2C_2020"]
stopifnot(ev[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = unit][, all(V1 == 1L)],
          ev[, uniqueN(locationRemarks), by = locationID][, all(V1 == 1L | locationID %in% lentic)])
ev[, occasion := METH[samplingProtocol]]
prog <- ev[samplingProtocol == "electric fishing", .(unit_program = locationRemarks[1]), by = unit]

oc[, name := fifelse(taxonRank == "genus", genus, paste(genus, specificEpithet))]
sp <- unique(oc[, .(name, taxonRank)])
fix <- c("Sender lucioperca" = "Sander lucioperca", "Cobitis paludicola" = "Cobitis paludica")
sp[, lookup := fifelse(name %in% names(fix), fix[name], name)]
sp[, taxon := fifelse(taxonRank == "genus", toupper(paste0(substr(lookup, 1, 3), "SPP")),
                      toupper(paste0(substr(lookup, 1, 3), substr(sub("^\\S+ ", "", lookup), 1, 3))))]
stopifnot(nrow(sp) == 18L, !anyDuplicated(sp$taxon), sum(sp$taxonRank == "genus") == 1L)
oc <- merge(oc, sp[, .(name, taxon)], by = "name")
long <- merge(oc[, .(eventID, taxon, y = as.integer(individualCount))],
              ev[, .(eventID, unit, period = year - 2014L, occasion, date = eventDate,
                     obs_method = samplingProtocol,
                     obs_duration_min = fifelse(samplingProtocol == "electric fishing" & sampleSizeValue != "0", as.numeric(sampleSizeValue), NA_real_),
                     obs_area_m2 = fifelse(samplingProtocol != "electric fishing", as.numeric(sampleSizeValue), NA_real_),
                     obs_effort = samplingEffort, obs_habitat = habitat, unit_water_body = waterBody,
                     unit_control = as.integer(grepl("^PIMA .*C(_2020)?$", unit)),
                     unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude))],
              by = "eventID")
long <- merge(long, prog, by = "unit")
long[, eventID := NULL]
long[, unit_coordinateUncertaintyInMeters := 5L]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
stopifnot(nrow(long) == 456L * 18L, !anyDuplicated(long[, .(unit, taxon, period, occasion)]), sum(long$y) == sum(as.integer(oc$individualCount)))

taxa <- make_taxa(sp$taxon, sp$lookup, lookupName = sp$lookup, taxonRank = sp$taxonRank,
                  allow_higher = sp[taxonRank == "genus", taxon],
                  taxonRemarks = fifelse(sp$taxonRank == "genus", "genus-level class as published (Achondrostoma sp.)",
                                 fifelse(sp$name != sp$lookup, sprintf("source spelling '%s'", sp$name), NA_character_)))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := fifelse(taxa$taxonRank == "genus", NA_character_, iu)]
print(taxa[, .(taxon, scientificName, taxonRank, taxon_iucnCategory)])
fl <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
flag <- taxa[taxon %in% fl, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
periods <- data.table(period = 1:6, year = 2015:2020)

cite <- "Cortes R, Varandas S, Jesus J, Santos C, Lopes M, Pereira V, Bessa I, Assunção T, Albuquerque A, Sanches D (2023). EDP Baixo Sabor: Fishes – Ecological Monitoring and Complementary Measures Programs [2015-2020]. Version 1.0. EDP - Energias de Portugal. Samplingevent dataset. https://doi.org/10.15468/ut55sa"
emit <- function(name, exact) {
  lt <- copy(long); tt <- taxa
  if (exact) { lt <- lt[!taxon %in% fl]; tt <- taxa[!taxon %in% fl] }
  else if (length(fl)) {
    cc <- coarsen_coords(lt$unit_decimalLatitude, lt$unit_decimalLongitude, 0.1)
    lt[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
              unit_coordinateUncertaintyInMeters = as.integer(5L + cc$uncertainty_m))]
  }
  nt <- nrow(tt)
  dataset <- list(
    title = paste0(sprintf("EDP Baixo Sabor fish monitoring: counts of %d fish taxa at %d stations by electrofishing and netting, Sabor basin, Portugal, 2015-2020", nt, uniqueN(lt$unit)),
                   if (exact) " (taxa that are not IUCN-threatened; coordinates as published)" else ""),
    creator = "Cortes, Rui; Varandas, Simone; Jesus, Joaquim; and 7 co-authors (University of Trás-os-Montes e Alto Douro, for EDP - Energias de Portugal)", pubDate = "2023",
    doi = "10.15468/ut55sa", sourceURL = "https://doi.org/10.15468/ut55sa", citation = cite,
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
    abstract = "Fish monitoring of the Baixo Sabor hydroelectric dams (northeast Portugal) in their first years of operation, for EDP's Ecological Monitoring and Compensatory Measures programmes: stream stations electrofished once each spring-summer, including stations of four compensatory measures and their controls, and four reservoir stations sampled each year by electrofishing of the margins and by surface and deep gill netting. One row per station, year, method and taxon, y the individuals caught.",
    samplingProtocol = "Electrofishing with restitution at lotic stations (about 15 minutes, 3-4 people; duration per event in obs_duration_min) once a year in June-July; at four lentic reservoir stations also surface and deep netting (330 and 360 m2 of net, 3 people, about 14 hours) on the same visit (EDP Baixo Sabor PME and PMC).",
    samplingProtocolCode = "electrofishing", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
    closure = "closed", closureNote = "occasion = method within a year's visit (electrofishing; surface and deep netting at the four reservoir stations); period = year",
    occasionKind = "method", taxonInclusion = "target",
    geographicCoverage = "Lower Sabor river basin and reservoirs (Douro), Bragança district, northeast Portugal",
    temporalCoverage = sprintf("%s/%s", substr(min(ev$eventDate), 1, 7), substr(max(ev$eventDate), 1, 7)),
    coordinatesCoarsened = if (!length(fl)) list(value = FALSE, method = "Station coordinates as published (5 m); no species is IUCN-threatened in its native range (GBIF IUCN records).") else if (exact)
      list(value = FALSE, method = sprintf("Station coordinates as published (5 m). The IUCN-threatened taxa are not in this table (E7 scope, 3): %s; %s has them, with coordinates coarsened.", paste(flag, collapse = ", "), TABLE)) else
      list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): station coordinates snapped to their 0.1-degree cell centre, because IUCN-threatened taxa are in the table (E7): %s. %s keeps the other taxa at the published coordinates.", paste(flag, collapse = ", "), EXACT)),
    covariateNote = "obs_method = electric fishing, surface netting or deep netting; obs_duration_min = electrofishing minutes (NA where the source gives 0); obs_area_m2 = netted area; obs_effort = samplingEffort as published; obs_habitat = lotic or lentic at the event; unit_program = the programme and compensatory measure the station serves (source locationRemarks); unit_control = 1 for a PMC control station; unit_water_body = stream or reservoir.",
    notes = "Achondrostoma is a genus-level class as published. 'Sender lucioperca' and 'Cobitis paludicola' are corrected to Sander lucioperca and Cobitis paludica in __taxa (source spelling in taxonRemarks). Station PIMA A2C is published at a different point in 2020 (22 km away); that event is the unit PIMA A2C_2020. 34 electrofishing events give a duration of 0 minutes, shipped as NA.",
    notShipped = c(if (exact && length(fl)) list(`IUCN-threatened taxa` = sprintf("%s: in %s only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "), TABLE)), list(
      `zero durations` = "sampleSizeValue 0 on 34 electrofishing events, read as not recorded (NA)")))
  ds <- write_table(lt, name, dataset, taxa = tt, periods = periods, script = "data/cortes_2023_sabor_fish_count.R")
  stage_dict_row(name,
    description = sprintf("Fish counts of %d taxa at %d stations of the EDP Baixo Sabor dam monitoring (electrofishing every year; surface and deep netting at four reservoir stations), northeast Portugal, 2015-2020.", nt, uniqueN(lt$unit)),
    url = "https://doi.org/10.15468/ut55sa", reference = cite, doi_paper = "", doi_data = "10.15468/ut55sa",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste0(if (exact) "E7 sibling without the IUCN-threatened taxa; " else if (length(fl)) "Coordinates coarsened to 0.1 degree (IUCN-threatened taxa); " else "", "GBIF Portugal IPT DwC-A (edp_sabor_ichtyofauna_2015-20 v1.0); method as occasion; compensatory-measure controls flagged."),
    source_via = "GBIF (GBIF Portugal IPT)")
  stage_tag_row(name, ds, taxon_group = "Fish", model_family = "N-mixture / annual count index (multi-species, multi-season)",
    sampling_protocol = "electrofishing", design = sprintf("Multi-season (%d years x 1-3 methods)", uniqueN(lt$period)),
    realm = "Freshwater", country = "PRT", coordinates = if (exact || !length(fl)) "As published" else "Coarsened (0.1 deg)",
    notes = "Dam operation monitoring; compensatory measures vs controls; reservoir netting as extra occasions.")
}
emit(TABLE, exact = FALSE)
if (length(fl)) emit(EXACT, exact = TRUE)
