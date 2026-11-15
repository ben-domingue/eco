#!/usr/bin/env Rscript
# Table:  beja_2021_sabor_fish_count (and the E7 sibling beja_2021_sabor_fish_exact_count, if any taxon is flagged)
# Source: GBIF sampling-event dataset 80d4429a-0b88-4952-b943-5999324b805f, doi:10.15468/pep8ma, version 1.3,
#         GBIF Portugal IPT resource lter_sabor_ictiofauna_2012-20 (CIBIO). Licence as shown on GBIF and in the EML:
#         CC BY 4.0.
#         Citation: Beja P, Motta-Ferreira M, Filipe A F, Carona S, Henrique P, Severino R, Ivone S, Henrique S, Prata D,
#         Lopes J, Guilherme J, Barradas J, Cereja R, Pace G, Rosa I, Pinto M, Agudelo W, Buzzo G, Sá F, Quaglietta L,
#         Pereira N, Múrias T (2021): lter_sabor_ictiofauna_2012-20. CIBIO (Research Center in Biodiversity and Genetic
#         Resources) Portugal. Dataset/Samplingevent. https://doi.org/10.15468/pep8ma
# Paper:  none; LTER Baixo Sabor (lter_eu_pt_002, https://deims.org/45722713-80e3-4387-a47b-82c97a6ef62b).
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (302 rows): one electrofishing survey of one 50 m reach: eventID, eventDate (June-September), locationID
#     (74 reaches), waterBody, verbatimLocality, coordinates (5 m); sampleSizeValue 50 m and samplingEffort
#     '15 to 25 minutes-collector' on every event. 74 reaches in 2012, 28-30 of them each year 2013-2020; one survey
#     per reach and year (asserted).
#   occurrence.txt (4,228 rows): one row per survey for each of 14 target species (present with individualCount,
#     absent 0); the scientificName strings are garbled ('Salmo truttaLinnaeus, 1758'), genus and specificEpithet are
#     clean and are used. Survey E72.9 lists S. carolitertii twice (both 0) and lacks S. alburnoides (asserted).
#   Protocol (EML): standard electrofishing (INAG 2008) of a 50 m stretch for 15-25 minutes (longer in wider streams),
#     single anode, one operator and one netter, all fish identified and released (exotics euthanised).
# Mapping (annual counts; responseType count): unit = reach (locationID), period = year 2012..2020, no occasion (one
#   survey per reach-year), date = eventDate, taxon = the 14 species, y = individuals caught (individualCount).
#   unit_water_body = waterBody. surveyEvidence = sample_table: every survey reports all 14 species, present or absent
#   = 0. taxonInclusion = target. Reach M12 is published at one point in 2014 and at another 57 km away in
#   2015-2020; the 2014 survey is the separate unit M12_2014.
#   Coordinates as published (5 m) unless a species is IUCN-threatened in its native range (GBIF IUCN records,
#   printed), in which case this table is coarsened to 0.1 degree and the _exact sibling drops the flagged taxa
#   (E7 scope, 3).
# Not shipped: sampleSizeValue and samplingEffort (constant, 50 m and 15-25 minutes).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "beja_2021_sabor_fish_count"
EXACT <- "beja_2021_sabor_fish_exact_count"
zip <- download_cached("http://ipt.gbif.pt/ipt/archive.do?r=lter_sabor_ictiofauna_2012-20", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("80d4429a-0b88-4952-b943-5999324b805f/v1.3", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
ev[, year := as.integer(substr(eventDate, 1, 4))]
stopifnot(nrow(ev) == 302L, nrow(oc) == 4228L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol == "electric fiishing"),
          all(ev$sampleSizeValue == "50"), all(ev$samplingEffort == "15 to 25 minutes-collector"),
          all(grepl("^\\d{4}-0[6-9]-\\d{2}$", ev$eventDate)), uniqueN(ev$locationID) == 74L, !anyDuplicated(ev[, .(locationID, year)]),
          ev[, uniqueN(waterBody), by = locationID][, all(V1 == 1L)],
          all(oc$license == "https://creativecommons.org/licenses/by/4.0/legalcode"),
          setequal(oc$eventID, ev$eventID), oc[, .N, by = eventID][, all(N == 14L)], all(oc$taxonRank == "species"),
          oc[occurrenceStatus == "absent", all(individualCount == "0")],
          oc[occurrenceStatus == "present", all(as.integer(individualCount) >= 1L)])
# survey E72.9 lists Squalius carolitertii twice (both 0) and no S. alburnoides: the second row is read as the
# missing alburnoides zero (either reading gives y = 0 for both species)
dd <- oc[duplicated(oc[, .(eventID, genus, specificEpithet)]) | duplicated(oc[, .(eventID, genus, specificEpithet)], fromLast = TRUE)]
stopifnot(nrow(dd) == 2L, all(dd$eventID == "E72.9"), all(dd$specificEpithet == "carolitertii"), all(dd$individualCount == "0"),
          !"alburnoides" %in% oc[eventID == "E72.9"]$specificEpithet)
oc[occurrenceID == dd$occurrenceID[2], specificEpithet := "alburnoides"]
stopifnot(!anyDuplicated(oc[, .(eventID, genus, specificEpithet)]))
# reach M12 is surveyed at one point in 2014 and at another, 57 km away, in 2015-2020: the 2014 survey is a unit of
# its own (M12_2014), since which coordinate pair is right cannot be told from the archive
ev[, unit := locationID]
ev[locationID == "M12" & year == 2014L, unit := "M12_2014"]
stopifnot(sum(ev$unit == "M12_2014") == 1L, ev[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = unit][, all(V1 == 1L)])
xy <- unique(ev[, .(unit, lat = as.numeric(decimalLatitude), lon = as.numeric(decimalLongitude))])
years <- 2012:2020
stopifnot(all(ev$year %in% years))

oc[, name := paste(genus, specificEpithet)]
sp <- unique(oc[, .(name, genus, specificEpithet)])
sp[, taxon := toupper(paste0(substr(genus, 1, 3), substr(specificEpithet, 1, 3)))]
stopifnot(nrow(sp) == 14L, !anyDuplicated(sp$taxon))
oc <- merge(oc, sp[, .(name, taxon)], by = "name")
long <- merge(oc[, .(eventID, taxon, y = as.integer(individualCount))],
              ev[, .(eventID, unit, period = match(year, years), date = eventDate, unit_water_body = waterBody)], by = "eventID")
long <- merge(long, xy[, .(unit, unit_decimalLatitude = lat, unit_decimalLongitude = lon)], by = "unit")
long[, eventID := NULL]
long[, unit_coordinateUncertaintyInMeters := 5L]
setcolorder(long, c("unit", "taxon", "y", "period", "date"))
stopifnot(nrow(long) == 302L * 14L, sum(long$y) == sum(as.integer(oc$individualCount)))

# Achondrostoma gallaicum is not on the GBIF backbone (the match falls to the genus): no key, with a remark
taxa <- make_taxa(sp$taxon, sp$name, no_key = "ACHGAL",
                  taxonRemarks = fifelse(sp$taxon == "ACHGAL", "not on the GBIF backbone (2026-11-13; the match falls to genus Achondrostoma); name as published", NA_character_))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
print(taxa[, .(taxon, scientificName, taxon_iucnCategory)])
stopifnot(identical(taxa[taxon == "ACHGAL", taxon_iucnCategory], NA_character_))
fl <- taxa[iu %in% c("CR", "EN", "VU"), taxon]
flag <- taxa[taxon %in% fl, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
periods <- ev[, .(n_reaches = .N), by = year][order(year)]
periods <- data.table(period = match(periods$year, years), periods)

cite <- "Beja P, Motta-Ferreira M, Filipe A F, Carona S, Henrique P, Severino R, Ivone S, Henrique S, Prata D, Lopes J, Guilherme J, Barradas J, Cereja R, Pace G, Rosa I, Pinto M, Agudelo W, Buzzo G, Sá F, Quaglietta L, Pereira N, Múrias T (2021): lter_sabor_ictiofauna_2012-20. CIBIO (Research Center in Biodiversity and Genetic Resources) Portugal. Dataset/Samplingevent. https://doi.org/10.15468/pep8ma"
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
    title = paste0(sprintf("LTER Baixo Sabor electrofishing: counts of %d fish species in %d stream reaches of the Sabor basin, Portugal, 2012-2020", nt, uniqueN(lt$unit)),
                   if (exact) " (taxa that are not IUCN-threatened; coordinates as published)" else ""),
    creator = "Beja, Pedro; Motta-Ferreira, Mafalda; Filipe, Ana Filipa; and 19 co-authors (CIBIO, University of Porto)", pubDate = "2021",
    doi = "10.15468/pep8ma", sourceURL = "https://doi.org/10.15468/pep8ma", citation = cite,
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
    abstract = "Fish community surveys of the Long Term Ecological Research site Baixo Sabor (northeast Portugal): 50 m reaches across the Sabor watershed and its main tributaries were electrofished once each summer, all reaches in 2012 and a fixed subset of them every year from 2013 to 2020. Fish were identified and released (exotics removed). One row per reach-year and species, y the individuals caught.",
    samplingProtocol = "Single-pass electrofishing of a 50 m stream reach for 15-25 minutes (longer in wider streams; INAG 2008 protocol), single anode at 350-750 V DC, one operator and one netter; all fish identified on site; once per summer (June-September).",
    samplingProtocolCode = "electrofishing", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
    closure = "none", closureNote = "one survey per reach and year; period = year; the replication is across years",
    occasionKind = "none", taxonInclusion = "target",
    geographicCoverage = "Sabor river basin (Douro), Bragança district, northeast Portugal",
    temporalCoverage = sprintf("%s/%s", substr(min(ev$eventDate), 1, 7), substr(max(ev$eventDate), 1, 7)),
    coordinatesCoarsened = if (!length(fl)) list(value = FALSE, method = "Reach coordinates as published (5 m).") else if (exact)
      list(value = FALSE, method = sprintf("Reach coordinates as published (5 m). The IUCN-threatened taxa are not in this table (E7 scope, 3): %s; %s has them, with coordinates coarsened.", paste(flag, collapse = ", "), TABLE)) else
      list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): reach coordinates snapped to their 0.1-degree cell centre, because IUCN-threatened taxa are in the table (E7): %s. Uncertainty = 5 m plus the cell half-diagonal. %s keeps the other taxa at the published coordinates.", paste(flag, collapse = ", "), EXACT)),
    covariateNote = "unit_water_body = the stream or river of the reach.",
    notes = "Survey E72.9 lists Squalius carolitertii twice, both 0, and no S. alburnoides; the second row is read as the alburnoides zero (either reading gives 0 for both). All reaches were surveyed in 2012 and 28-30 of them each year from 2013. Species names are rebuilt from the source's genus and specificEpithet, because its scientificName strings run the authorship into the epithet. Reach M12 is published at one point in 2014 and at another 57 km away in 2015-2020; the 2014 survey is the unit M12_2014.",
    notShipped = c(if (exact && length(fl)) list(`IUCN-threatened taxa` = sprintf("%s: in %s only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "), TABLE)), list(
      effort = "sampleSizeValue (50 m) and samplingEffort ('15 to 25 minutes-collector'), constant")))
  ds <- write_table(lt, name, dataset, taxa = tt, periods = periods, script = "data/beja_2021_sabor_fish_count.R")
  stage_dict_row(name,
    description = sprintf("Single-pass electrofishing counts of %d fish species in %d stream reaches of the LTER Baixo Sabor, northeast Portugal, every summer 2012-2020.", nt, uniqueN(lt$unit)),
    url = "https://doi.org/10.15468/pep8ma", reference = cite, doi_paper = "", doi_data = "10.15468/pep8ma",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste0(if (exact) "E7 sibling without the IUCN-threatened taxa; " else if (length(fl)) "Coordinates coarsened to 0.1 degree (IUCN-threatened taxa); " else "", "GBIF Portugal IPT DwC-A (lter_sabor_ictiofauna_2012-20 v1.3)."),
    source_via = "GBIF (GBIF Portugal IPT)")
  stage_tag_row(name, ds, taxon_group = "Fish", model_family = "N-mixture / annual count index (multi-species, multi-season)",
    sampling_protocol = "electrofishing", design = sprintf("Multi-season (%d years x 1 survey per reach-year)", uniqueN(lt$period)),
    realm = "Freshwater", country = "PRT", coordinates = if (exact || !length(fl)) "As published" else "Coarsened (0.1 deg)",
    notes = "LTER Baixo Sabor; Mediterranean stream fish community; single-pass electrofishing.")
}
emit(TABLE, exact = FALSE)
if (length(fl)) emit(EXACT, exact = TRUE)
