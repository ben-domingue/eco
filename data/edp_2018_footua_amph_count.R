#!/usr/bin/env Rscript
# Table:  edp_2018_footua_amph_count
# Source: GBIF sampling-event dataset ce0e12f8-0a44-44dd-bb0c-4352182b144e, doi:10.15468/uo5uyu, version 1.0 (2018),
#         GBIF Portugal IPT resource edp_tua_amphibians_pme. Licence as shown on GBIF and in the EML: CC BY 4.0.
#         Citation: Costa H, Salgueiro N, Marques A T, Coelho H, Gonçalves R, Brás L, Monteiro B, Ferreira C, Paula J,
#         Oliveira J, Puga J, Silva M, Neves T, Pereira F, Magalhães J, Romão F, Rosa L, Sousa D, Pereira P, Cabral J A,
#         Vale-Gonçalves H M, Barros P, Múrias T (2018): EDP Foz Tua: Amphibians - Ecological Monitoring Program
#         [2010-2017]. v1. EDP - Energias de Portugal. Dataset/Samplingevent. https://doi.org/10.15468/uo5uyu
# Paper:  none; Ecological Monitoring Program of the Foz Tua hydroelectric dam (EML).
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (336 rows): one dip-net visit to one plot: eventID <plot>.<n> (2011-2017 plots PAFT01..PAFT30) or the
#     2010-2011 ids PAxx[.n], QCx-Px[.n], Q3-P1; eventDate, eventTime, habitat, locationID = the river or stream
#     (not the plot), locationRemarks (stream / tank / pond / river), coordinates of the plot (5 m uncertainty),
#     samplingEffort '2 observer-minutes' and sampleSizeValue 30 (minutes) on every visit.
#   occurrence.txt (4,092 rows): one row per visit for each of 12 target species (present with individualCount and
#     lifeStage 'adult', 'larvae' or 'adults, larvae'; absent with count 0). Every PAFT visit has exactly the 12 rows
#     (asserted). The 2010-2011 ids are damaged: 8 eventIDs in the occurrences are not in the event core (PA03.1,
#     PA05.2, QC2-P1.1, ...), and five events of the core hold only a duplicated Alytes cisternasii row.
#   Protocol (EML): 42-43 plots in the main amphibian habitats (tanks, ponds, streams, rivers) within 5 km of the
#     lower Tua valley, plus the Ferradosa stream as a control outside it; each plot visited once or twice in autumn
#     (October-November, 2010-2012) and in spring (April-June, 2011-2017), before (2010), during (2011-2015)
#     construction and after the filling of the reservoir (2016-2017); dip-netting, all individuals recorded.
# Mapping (repeated counts, community with a target list; responseType count): unit = plot (PAFT01..PAFT30, the
#   eventID without its visit number; one coordinate pair per plot, asserted), period = season (spring = April-June,
#   autumn = October-November) in time order, occasion = visit within the season in date order, date = eventDate,
#   taxon = the 12 target species, y = individuals counted (individualCount). surveyEvidence = sample_table: every
#   visit is an event reporting all 12 species (present or absent = 0). taxonInclusion = target.
#   obs_life_stage = the source's lifeStage on a present row (NA on a zero); obs_habitat and obs_water_type = the
#   visit's habitat and locationRemarks (they change at some plots); obs_time = eventTime as published;
#   unit_water_body = locationID; unit_phase is not shipped (the phase is a function of the year, in __periods).
#   Coordinates: plot coordinates as published (5 m). Taxa IUCN-threatened in their native range (if any; GBIF IUCN
#   records, printed) trigger E7: this table coarsens every plot to its 0.1-degree cell centre and an _exact sibling
#   without the flagged taxa keeps the published coordinates (E7 scope, 3).
# Not shipped: the 2010-2011 plots (PA, QC, Q ids; 24 events at 13 coordinate points): their event and occurrence
#   ids do not match (8 orphan occurrence events, 5 core events with only a duplicated row), their localities differ
#   between visits of one point (Safres 1 / Safres 2, Brunheda / Sobreira 3), and their link to the PAFT plots is
#   not stated; samplingEffort and sampleSizeValue (constant: "2 observer-minutes" and 30, see notes).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "edp_2018_footua_amph_count"
EXACT <- "edp_2018_footua_amph_exact_count"
zip <- download_cached("http://ipt.gbif.pt/ipt/archive.do?r=edp_tua_amphibians_pme", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("edp_tua_amphibians_pme/v1.0", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 336L, nrow(oc) == 4092L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol == "dip-netting"),
          all(ev$samplingEffort == "2 observer-minutes"), all(ev$sampleSizeValue == "30"),
          all(ev$coordinateUncertaintyInMeters == "5"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          all(oc$license == "https://creativecommons.org/licenses/by/4.0/legalcode"),
          length(setdiff(oc$eventID, ev$eventID)) == 8L, all(!grepl("^PAFT", setdiff(oc$eventID, ev$eventID))))
ev <- ev[grepl("^PAFT\\d{2}\\.\\d+$", eventID)]
oc <- oc[eventID %in% ev$eventID]
ev[, plot := sub("\\.\\d+$", "", eventID)]
stopifnot(nrow(ev) == 312L, uniqueN(ev$plot) == 30L,
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = plot][, all(V1 == 1L)],
          ev[, uniqueN(locationID), by = plot][, all(V1 == 1L)],
          all(ev$eventID %in% oc$eventID), oc[, .N, by = eventID][, all(N == 12L)], !anyDuplicated(oc[, .(eventID, scientificName)]),
          uniqueN(oc$scientificName) == 12L,
          oc[occurrenceStatus == "absent", all(individualCount == "0" & lifeStage == "")],
          oc[occurrenceStatus == "present", all(as.integer(individualCount) >= 1L & lifeStage %in% c("adult", "larvae", "adults, larvae"))],
          setequal(oc$occurrenceStatus, c("present", "absent")))
ev[, `:=`(year = as.integer(substr(eventDate, 1, 4)), month = as.integer(substr(eventDate, 6, 7)))]
stopifnot(all(ev$month %in% c(4:6, 10:11)))
ev[, season := ifelse(month <= 6, "spring", "autumn")]
ev[, skey := year * 10L + (season == "autumn")]
seas <- unique(ev[, .(skey, year, season)])[order(skey)]
seas[, period := seq_len(.N)]
ev <- merge(ev, seas[, .(skey, period)], by = "skey")
setorder(ev, plot, period, eventDate, eventID)
ev[, occasion := seq_len(.N), by = .(plot, period)]

sp <- data.table(scientificName = sort(unique(oc$scientificName)))
sp[, name := trimws(sub("^(\\S+ \\S+).*$", "\\1", scientificName))]
sp[, lookup := c("Discolgossus galganoi" = "Discoglossus galganoi", "Pelophilax perezi" = "Pelophylax perezi")[name]]
sp[is.na(lookup), lookup := name]
sp[, taxon := toupper(paste0(substr(lookup, 1, 3), substr(sub("^\\S+ ", "", lookup), 1, 3)))]
stopifnot(!anyDuplicated(sp$taxon), sum(sp$lookup != sp$name) == 2L)
oc <- merge(oc, sp[, .(scientificName, taxon)], by = "scientificName")
long <- merge(oc[, .(eventID, taxon, y = as.integer(individualCount), obs_life_stage = fifelse(lifeStage == "", NA_character_, lifeStage))],
              ev[, .(eventID, unit = plot, period, occasion, date = eventDate, obs_time = eventTime,
                     obs_habitat = habitat, obs_water_type = locationRemarks, unit_water_body = locationID,
                     unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude))],
              by = "eventID")
long[, eventID := NULL]
long[, unit_coordinateUncertaintyInMeters := 5L]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
stopifnot(nrow(long) == 312L * 12L, !anyDuplicated(long[, .(unit, taxon, period, occasion)]))

taxa <- make_taxa(sp$taxon, sp$lookup, lookupName = sp$lookup,
                  taxonRemarks = ifelse(sp$name != sp$lookup, sprintf("source spelling '%s'", sp$name), NA_character_))
iu <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
taxa[, taxon_iucnCategory := iu]
print(taxa[, .(taxon, scientificName, taxonID, taxon_iucnCategory)])
fl <- taxa[iu %in% c("CR", "EN", "VU"), taxon]
flag <- taxa[taxon %in% fl, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
periods <- seas[, .(period, year, season, phase = fifelse(year <= 2015, "construction", "reservoir filled"))]

cite <- "Costa H, Salgueiro N, Marques A T, Coelho H, Gonçalves R, Brás L, Monteiro B, Ferreira C, Paula J, Oliveira J, Puga J, Silva M, Neves T, Pereira F, Magalhães J, Romão F, Rosa L, Sousa D, Pereira P, Cabral J A, Vale-Gonçalves H M, Barros P, Múrias T (2018): EDP Foz Tua: Amphibians - Ecological Monitoring Program [2010-2017]. v1. EDP - Energias de Portugal. Dataset/Samplingevent. https://doi.org/10.15468/uo5uyu"
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
    title = paste0(sprintf("EDP Foz Tua amphibian monitoring: dip-net counts of %d species at %d plots, lower Tua valley, Portugal, 2011-2017", nt, uniqueN(lt$unit)),
                   if (exact) " (taxa that are not IUCN-threatened; coordinates as published)" else ""),
    creator = "Costa, Hugo; Salgueiro, Nuno; Marques, Ana Teresa; and 20 co-authors (EDP - Energias de Portugal; Bio3)", pubDate = "2018",
    doi = "10.15468/uo5uyu", sourceURL = "https://doi.org/10.15468/uo5uyu", citation = cite,
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
    abstract = "Amphibian monitoring for the Foz Tua hydroelectric dam (northeast Portugal), run for EDP: plots in tanks, ponds, streams and rivers within 5 km of the lower Tua valley, at a gradient of distance from the future reservoir, plus the Ferradosa stream as a control outside the valley, sampled by dip-netting for adults and larvae once or twice each autumn (2011-2012) and spring (2012-2017), through the dam's construction and the filling of the reservoir (2016-2017). One row per visit and target species, y the individuals recorded.",
    samplingProtocol = "Dip-netting of the plot's water body (tank, pond, stream or river) for adult and larval amphibians, about 30 minutes per visit (the source's sampleSizeValue; samplingEffort is given as '2 observer-minutes'), all individuals of the 12 target species recorded; once or twice per season (EDP Foz Tua Ecological Monitoring Program).",
    samplingProtocolCode = "dip_net", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
    closure = "closed", closureNote = "occasion = visit within a season (spring April-June, autumn October-November); period = season in time order; 1-3 visits per plot-season",
    occasionKind = "time", taxonInclusion = "target",
    geographicCoverage = "Lower Tua valley and Ferradosa stream, Vila Real and Bragança districts, northeast Portugal",
    temporalCoverage = sprintf("%s/%s", substr(min(ev$eventDate), 1, 7), substr(max(ev$eventDate), 1, 7)),
    coordinatesCoarsened = if (!length(fl)) list(value = FALSE, method = "Plot coordinates as published (5 m); no target species is IUCN-threatened in its native range (GBIF IUCN records).") else if (exact)
      list(value = FALSE, method = sprintf("Plot coordinates as published (5 m). The IUCN-threatened taxa are not in this table (E7 scope, 3): %s; %s has them, with coordinates coarsened.", paste(flag, collapse = ", "), TABLE)) else
      list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): the published plot coordinates snapped to their 0.1-degree cell centre, because IUCN-threatened taxa are in the table (E7): %s. Uncertainty = 5 m plus the cell half-diagonal. %s keeps the other taxa at the published coordinates.", paste(flag, collapse = ", "), EXACT)),
    covariateNote = "obs_life_stage = the source's lifeStage on a present row (adult, larvae, or 'adults, larvae'), NA on a zero; obs_habitat = surrounding habitat as recorded at the visit; obs_water_type = stream, river, tank or pond as recorded at the visit; obs_time = start/end time as published; unit_water_body = the river or stream (the source's locationID); __periods gives year, season and phase (construction to 2015, reservoir filled 2016-2017).",
    notes = "The source gives samplingEffort '2 observer-minutes' and sampleSizeValue 30 on every visit; read as about 30 minutes by two observers. Names follow the source except two misspellings, corrected in __taxa (the source spelling is in taxonRemarks).",
    notShipped = c(if (exact && length(fl)) list(`IUCN-threatened taxa` = sprintf("%s: in %s only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "), TABLE)), list(
      `2010-2011 plots` = "24 events at 13 points with PA/QC/Q ids, autumn 2010 to spring 2011: 8 occurrence event ids absent from the event core, 5 core events holding only a duplicated Alytes cisternasii row, localities that differ between visits of one point, and no stated link to the PAFT plots",
      effort = "samplingEffort and sampleSizeValue, constant on every visit (see notes)")))
  ds <- write_table(lt, name, dataset, taxa = tt, periods = periods, script = "data/edp_2018_footua_amph_count.R")
  stage_dict_row(name,
    description = sprintf("Dip-net counts of %d amphibian species at %d plots of the EDP Foz Tua dam monitoring programme, northeast Portugal, spring and autumn 2011-2017, 1-3 visits per season.", nt, uniqueN(lt$unit)),
    url = "https://doi.org/10.15468/uo5uyu", reference = cite, doi_paper = "", doi_data = "10.15468/uo5uyu",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste0(if (exact) "E7 sibling without the IUCN-threatened taxa; " else if (length(fl)) "Coordinates coarsened to 0.1 degree (IUCN-threatened taxa); " else "", "GBIF Portugal IPT DwC-A (edp_tua_amphibians_pme v1.0); 2010-2011 plots not shipped (damaged ids)."),
    source_via = "GBIF (GBIF Portugal IPT)")
  stage_tag_row(name, ds, taxon_group = "Amphibians", model_family = "N-mixture (open / multi-season)",
    sampling_protocol = "dip_net", design = sprintf("Multi-season (%d seasons x 1-%d visits)", uniqueN(lt$period), max(lt$occasion)),
    realm = "Freshwater", country = "PRT", coordinates = if (exact || !length(fl)) "As published" else "Coarsened (0.1 deg)",
    notes = "Hydroelectric dam impact monitoring; before/during/after reservoir filling; Ferradosa control stream.")
}
emit(TABLE, exact = FALSE)
if (length(fl)) emit(EXACT, exact = TRUE)
