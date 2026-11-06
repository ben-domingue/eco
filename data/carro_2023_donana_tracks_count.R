#!/usr/bin/env Rscript
# Table:  carro_2023_donana_tracks_count
# Source: nine GBIF sampling-event datasets of the Doñana Long-term Ecological Monitoring Program (ICTS-RBD, Estación
#         Biológica de Doñana, CSIC), version 20230915, published through the GBIF Spain IPT, one per taxon:
#         hedgehog doi:10.15470/yvoou1, otter doi:10.15470/xavass, Felis doi:10.15470/oaffix, Iberian lynx
#         doi:10.15470/2us9py, domestic dog doi:10.15470/zmqncw, common genet doi:10.15470/pjpxhp, Egyptian mongoose
#         doi:10.15470/up1q9h, badger doi:10.15470/4pcvqq, red fox doi:10.15470/p09dsf.
#         Licence as shown on each GBIF page and in each archive: CC BY 4.0.
#         Citation (hedgehog; the others differ only in title and DOI): Carro F, Román I, Laffite Alaminos R, Paz D,
#         Ceballos O, Chico A, Torrijo-Salesa M, Díaz-Delgado R, Bustamante J, Márquez-Ferrando R (2023). Long-term
#         monitoring of the relative density in the Western European hedgehog (Erinaceus europaeus) with track counts in
#         Doñana National Park 2007-2022. Estación Biológica de Doñana (CSIC). Sampling event dataset.
# Paper:  none; protocol Carro F. (2014) Protocolo de muestreo 13: Censos de huellas de carnívoros en el Parque Nacional de
#         Doñana (ICTS-RBD technical document), cited in every event row.
# Data:   nine Darwin Core Archives (event core + occurrence extension) sharing one event set (444 events, asserted
#         identical eventIDs, transects and hydrological years; eventDate written d/m/Y in one archive and Y-m-d in the
#         others, one locality spelt without the tilde in one, one empty verbatimCoordinates in the fox archive; dates
#         are taken from the eventID).
#   event.txt: one row per transect run: eventID DONANA:CARN:TRACKS:<area>:<transect>:<date>; verbatimLocality the
#     transect (12, each 2 km x 1.5 m driven slowly by car); verbatimEventDate 'hydrological year <Y>' (October to
#     September; runs in October-January); verbatimCoordinates the GPS start/end of the run (varies by a few metres
#     between runs).
#   occurrence.txt: one row per group of footprints (individualCount 1-8 tracks groups, organismQuantityType
#     'animaltracks', the point's GPS position) or one absent row (count 0) for a run with no track of the taxon.
#     Every run has a row in every archive (asserted), except three fox rows whose eventIDs are not in the event core.
#   Protocol (EML): after the first autumn rains, the 12 permanent transects are run in the morning and the groups of
#     footprints of each carnivore (and hedgehog, dog) crossing or along the track are counted; usually three runs per
#     transect a year.
# Mapping (repeated counts, carnivore community; responseType count): unit = transect (verbatimLocality), period =
#   hydrological year (2008..2023 as published; 2022 has no runs), occasion = run within the hydrological year in date
#   order, date = from the eventID. taxon = the nine target taxa (Felis at genus rank: wildcat and domestic cat tracks
#   are not separated). y = groups of footprints of the taxon on the run (individualCount summed). surveyEvidence =
#   sample_table: every run is an event and every archive reports its taxon at every run (present or absent = 0).
#   taxonInclusion = target (all nine targets surveyed at every run). obs_ effort: none (all runs 2,000 m by car).
#   Coordinates: the Iberian lynx is IUCN VU (downlisted from EN in 2024; asserted from GBIF's category below), so the
#   transect positions (the median GPS start point of its runs, six decimals in the source) are coarsened to the 0.1
#   degree cell centre with coarsen_coords() (E7); point positions of track groups are not shipped.
# Not shipped: the per-track GPS positions and times (dynamicProperties); recordedBy/identifiedBy; the three fox rows
#   without an event.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "carro_2023_donana_tracks_count"
RES <- data.table(
  res = c("erinaceustracks_20230915", "lutratracks_ev_20230915", "felistracks_20230915", "lynxtracks_20230915", "canistracks_ev_20230915",
          "genettatracks_20230915", "herpestestracks_20230915", "melestracks_20230915", "vulpestracks_20230915"),
  doi = c("10.15470/yvoou1", "10.15470/xavass", "10.15470/oaffix", "10.15470/2us9py", "10.15470/zmqncw", "10.15470/pjpxhp",
          "10.15470/up1q9h", "10.15470/4pcvqq", "10.15470/p09dsf"),
  taxon = c("ERIEUR", "LUTLUT", "FELIS_SP", "LYNPAR", "CANFAM", "GENGEN", "HERICH", "MELMEL", "VULVUL"),
  sci = c("Erinaceus europaeus", "Lutra lutra", "Felis", "Lynx pardinus", "Canis lupus familiaris", "Genetta genetta", "Herpestes ichneumon",
          "Meles meles", "Vulpes vulpes"),
  vern = c("Western European hedgehog", "Eurasian otter", "cats (wildcat and domestic cat)", "Iberian lynx", "domestic dog", "common genet",
           "Egyptian mongoose", "European badger", "red fox"))
EV <- list(); OC <- list()
for (i in seq_len(nrow(RES))) {
  zip <- download_cached(sprintf("https://ipt.gbif.es/archive.do?r=icts-rbd-%s", RES$res[i]), TABLE, "dwca.zip", subdir = RES$res[i])
  dwca <- file.path(dirname(zip), "dwca")
  if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
  stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
  eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
  stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl(RES$doi[i], eml, fixed = TRUE))
  e <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
  o <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
  stopifnot(nrow(e) == 444L, !anyDuplicated(e$eventID), all(grepl("creativecommons.org/licenses/by/4.0", e$license, fixed = TRUE)),
            all(e$sampleSizeValue == "2000"), all(e$samplingEffort == "by car"), all(e$datasetID == paste0("doi:", RES$doi[i])),
            uniqueN(o$scientificName) == 1L, startsWith(gsub(" +", " ", o$scientificName[1]), RES$sci[i]),
            all(o$occurrenceStatus %in% c("present", "absent")), all(o[occurrenceStatus == "absent"]$individualCount == "0"),
            all(as.integer(o[occurrenceStatus == "present"]$individualCount) >= 1L), all(o$organismQuantityType == "animaltracks"),
            o[, sum(occurrenceStatus == "absent") == 0L | .N == 1L, by = eventID][, all(V1)], all(e$eventID %in% o$eventID))
  EV[[i]] <- e[, .(eventID, verbatimLocality, verbatimEventDate, verbatimCoordinates)][order(eventID)]
  OC[[i]] <- o[, .(eventID, taxon = RES$taxon[i], n = as.integer(individualCount))]
}
stopifnot(all(sapply(EV, function(e) identical(e[, .(eventID, verbatimLocality, verbatimEventDate)], EV[[1]][, .(eventID, verbatimLocality, verbatimEventDate)]))))
oc <- rbindlist(OC)
orphan <- oc[!eventID %in% EV[[1]]$eventID]
stopifnot(nrow(orphan) == 3L, all(orphan$taxon == "VULVUL"))
oc <- oc[eventID %in% EV[[1]]$eventID]
ev <- EV[[1]]
ev[, date := sub("^.*:(\\d{4}-\\d{2}-\\d{2})$", "\\1", eventID)]
ev[, hy := as.integer(sub("^hydrological year ", "", verbatimEventDate))]
ev[, unit := verbatimLocality]
stopifnot(all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$date)), !anyNA(ev$hy), uniqueN(ev$unit) == 12L,
          all(ev$unit == sub("^DONANA:CARN:TRACKS:[^:]+:([^:]+):.*$", "\\1", ev$eventID)),
          ev[, all(hy == as.integer(substr(date, 1, 4)) + (as.integer(substr(date, 6, 7)) >= 10L))])
# transect position: median GPS start point of its runs, then coarsened (lynx, E7)
ev[, c("slat", "slon") := tstrsplit(sub("/.*$", "", verbatimCoordinates), ", ?", keep = 1:2)]
pos <- ev[grepl("^-?[0-9.]+$", slat) & grepl("^-?[0-9.]+$", slon), .(lat = median(as.numeric(slat)), lon = median(as.numeric(slon))), by = unit]
stopifnot(nrow(pos) == 12L)
cc <- coarsen_coords(pos$lat, pos$lon)
pos[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m)]
hys <- sort(unique(ev$hy))
setorder(ev, unit, date, eventID)
ev[, occasion := seq_len(.N), by = .(unit, hy)]
cnt <- oc[, .(y = sum(n)), by = .(eventID, taxon)]
long <- merge(CJ(eventID = ev$eventID, taxon = RES$taxon), cnt, by = c("eventID", "taxon"))
stopifnot(nrow(long) == 444L * 9L)
long <- merge(long, ev[, .(eventID, unit, hy, occasion, date)], by = "eventID")
long <- merge(long, pos[, .(unit, unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)], by = "unit")
long <- long[, .(unit, taxon, y, period = match(hy, hys), occasion, date, unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)]
setorder(long, unit, period, occasion, taxon)
stopifnot(sum(long$y) == sum(oc$n), !anyNA(long$y))

taxa <- make_taxa(RES$taxon, RES$sci, vernacularName = RES$vern, taxonRank = ifelse(RES$taxon == "FELIS_SP", "genus", ifelse(RES$taxon == "CANFAM", "subspecies", "species")),
                  taxonRemarks = ifelse(RES$taxon == "FELIS_SP", "Tracks of wildcat (Felis silvestris) and domestic cat not separated by the protocol", NA_character_),
                  allow_higher = "FELIS_SP")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxonRank, gbifMatchType, taxon_iucnCategory)])
stopifnot(taxa[taxon == "LYNPAR", taxon_iucnCategory %in% c("EN", "VU")])
periods <- data.table(period = seq_along(hys), hydrological_year = hys, season = sprintf("%d-10/%d-09", hys - 1L, hys))
cite <- "Carro F, Román I, Laffite Alaminos R, Paz D, Ceballos O, Chico A, Torrijo-Salesa M, Díaz-Delgado R, Bustamante J, Márquez-Ferrando R (2023). Long-term monitoring of the relative density of [taxon] with track counts in Doñana National Park 2007-2022. Estación Biológica de Doñana (CSIC). Sampling event datasets (nine, one per taxon): "
dataset <- list(
  title = "Track counts of nine carnivores, hedgehog and dog on 12 permanent transects, Doñana National Park, Spain, 2007-2022",
  creator = "Carro, Francisco; Román, Isidro; Laffite Alaminos, Rafael; Paz, David; Ceballos, Olga; Chico, Antonio; Torrijo-Salesa, María; Díaz-Delgado, Ricardo; Bustamante, Javier; Márquez-Ferrando, Rubén (Estación Biológica de Doñana, CSIC)",
  pubDate = "2023", doi = "10.15470/2us9py", sourceURL = "https://doi.org/10.15470/2us9py",
  citation = paste0(cite, paste(sprintf("https://doi.org/%s", RES$doi), collapse = ", ")),
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Long-term monitoring of the relative density of the main carnivores in Doñana National Park: after the first autumn rains, 12 permanent 2 km sand-track transects are driven slowly in the morning and every group of footprints of each target taxon is counted, usually three runs per transect a year. The Doñana Monitoring Program published one GBIF dataset per taxon on a shared event set; this table joins the nine. One row per run and taxon, y the groups of footprints.",
  samplingProtocol = "Track count on a permanent 2 km x 1.5 m sand transect driven slowly by car in the morning after the first autumn rains; every group of footprints of each target taxon is counted (Carro 2014, Protocolo de muestreo 13, ICTS-RBD); usually three runs per transect in a hydrological year.",
  samplingProtocolCode = "track_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = run within a hydrological year (runs a few days apart in October-January); period = hydrological year (October-September)",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Doñana National Park, Huelva, Andalusia, Spain (transect positions coarsened to 0.1 degree)",
  temporalCoverage = sprintf("%s/%s", substr(min(ev$date), 1, 7), substr(max(ev$date), 1, 7)),
  coordinatesCoarsened = list(value = TRUE, method = "Iberian lynx (Lynx pardinus) is IUCN-listed (E7): each transect's median GPS start point (six decimals in the source) is moved to the centre of its 0.1 degree cell with coarsen_coords(); the per-track GPS points are not shipped."),
  notes = "Felis is at genus rank (wildcat and domestic cat tracks not separated). Dog tracks are domestic dogs. Hydrological year 2022 (October 2021-September 2022) has no runs. Joined from nine per-taxon GBIF datasets with identical event sets (asserted).",
  notShipped = list(`track positions` = "GPS position and time of each group of footprints (dynamicProperties)",
                    `fox rows without an event` = sprintf("%d red fox occurrence rows whose eventIDs are not in the event core: %s", nrow(orphan), paste(orphan$eventID, collapse = ", ")),
                    observers = "recordedBy / identifiedBy names"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = "Track-group counts of nine target taxa (Iberian lynx, red fox, badger, mongoose, genet, otter, cats, hedgehog, dog) on 12 permanent sand transects in Doñana National Park, Spain, 2007-2022, about three runs a year.",
  url = "https://doi.org/10.15470/2us9py",
  reference = paste0(cite, paste(RES$doi, collapse = ", ")),
  doi_paper = "", doi_data = paste(RES$doi, collapse = "; "), original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Nine GBIF Spain IPT DwC-As (icts-rbd-*tracks_20230915), one per taxon, joined on their shared event set. Transect positions coarsened to 0.1 degree (lynx).",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "track_count", design = sprintf("Multi-season (%d hydrological years x 1-%d runs)", uniqueN(long$period), max(long$occasion)),
  realm = "Terrestrial", country = "ESP", coordinates = "Coarsened (0.1 deg)",
  notes = "Long-term carnivore track-count monitoring; nine per-taxon datasets joined; lynx-sensitive positions coarsened.")
