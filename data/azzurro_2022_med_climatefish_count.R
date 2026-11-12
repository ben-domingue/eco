#!/usr/bin/env Rscript
# Table:  azzurro_2022_med_climatefish_count
# Source: VLIZ IPT (eurobis) resource climate-fish-abundance, Darwin Core Archive published 2022-10-04; GBIF
#         doi:10.15468/wphfqt; EurOBIS / EMODnet Biology IMIS dataset 8121 (found on EDITO, the European Digital Twin of
#         the Ocean). The same data are deposited on SEANOE, doi:10.17882/86784 (published 2022-03-29). Licence: CC BY 4.0
#         (EML, IMIS record, SEANOE page).
#         Citation: Azzurro E, Ballerini T, Antoniadou C, et al. (2022). ClimateFish: Abundance of selected coastal fish
#         species as candidate indicators of climate change in the Mediterranean Sea. SEANOE. doi:10.17882/86784
# Paper:  Azzurro E, et al. (2022). ClimateFish: a collaborative database to track the abundance of selected coastal
#         fish species as candidate indicators of climate change in the Mediterranean Sea. Frontiers in Marine Science 9,
#         910887. doi:10.3389/fmars.2022.910887. Simplified underwater visual census (after Garrabou et al. 2019): at each
#         location and depth layer (0-3, 5-10, 11-20, 21-30 m) a diver swims four consecutive replicate transects of five
#         minutes at about 10 m/min (about 50 x 5 m), counting 15 target species (7 native, 8 non-indigenous).
# Data:   Darwin Core Archive, event core with an occurrence extension (EML minimal; protocol from the paper).
#   event.txt (3,142 rows): one per transect: eventDate (2,685 to the day, 457 to the month only), locality (102
#     locations, one coordinate pair each), minimum/maximumDepthInMeters (the depth layer: 1-3, 5-10, 11-20, 21-30),
#     institutionCode (20 contributing teams), country (8).
#   occurrence.txt (47,130 rows): every one of the 15 species at every transect, organismQuantity = individuals counted
#     (integer 0-420), occurrenceStatus absent exactly where the count is 0.
#   Transects per location x depth layer x date are mostly 4 (552 of 719), also 8 (57; two divers or two sets), and 1-3
#     or more in a few; event numbers run consecutively within a group in most cases.
# Mapping (repeated counts, fish community; responseType count): unit = location x depth layer (<locality>_<min>m),
#   cluster_id = location, period = calendar month (1 = September 2009), occasion = transect within the unit-month in
#   event order, date = the transect's day where the source gives it (empty for the 457 month-only transects, whose
#   month is the period). taxon = the 15 target species (taxonInclusion = target). y = individuals counted.
#   surveyEvidence = sample_table: the event core lists every transect and every target species has a row at each.
#   unit_depth_min_m / unit_depth_max_m; unit_country; obs_team = the contributing institution.
#   Coordinates: Epinephelus marginatus is IUCN VU and native to the Mediterranean, so location coordinates are coarsened
#   to the 0.1 degree cell centre (E7(b)).
# Not shipped: exact coordinates (coarsened).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "azzurro_2022_med_climatefish_count"
zip <- download_cached("https://ipt.vliz.be/eurobis/archive.do?r=climate-fish-abundance", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("2022-10-04", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 3142L, nrow(oc) == 47130L, !anyDuplicated(ev$eventID), all(grepl("^event-\\d+$", ev$eventID)),
          uniqueN(ev$locality) == 102L, ev[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = locality][, all(V1 == 1L)],
          all(grepl("^\\d{4}-\\d{2}(-\\d{2})?$", ev$eventDate)), sum(nchar(ev$eventDate) == 7L) == 457L,
          setequal(paste(ev$minimumDepthInMeters, ev$maximumDepthInMeters), c("1 3", "5 10", "11 20", "21 30")))
stopifnot(uniqueN(oc$scientificName) == 15L, setequal(oc$eventID, ev$eventID), !anyDuplicated(oc[, .(eventID, scientificName)]),
          oc[, .N, by = eventID][, all(N == 15L)], all(grepl("^\\d+$", oc$organismQuantity)),
          all((oc$organismQuantity == "0") == (oc$occurrenceStatus == "absent")))

ev[, `:=`(n = as.integer(sub("event-", "", eventID)), unit = paste0(gsub("[^A-Za-z0-9]+", "_", locality), "_", minimumDepthInMeters, "m"),
          yr = as.integer(substr(eventDate, 1, 4)), mo = as.integer(substr(eventDate, 6, 7)))]
stopifnot(uniqueN(ev$unit) == uniqueN(ev[, .(locality, minimumDepthInMeters)]))
m0 <- ev[, min(yr * 12L + mo - 1L)]
ev[, period := yr * 12L + mo - 1L - m0 + 1L]
setorder(ev, unit, period, n)
ev[, occasion := seq_len(.N), by = .(unit, period)]
cc <- coarsen_coords(as.numeric(ev$decimalLatitude), as.numeric(ev$decimalLongitude))
ev[, `:=`(clat = cc$lat, clon = cc$lon, cunc = as.integer(cc$uncertainty_m))]

SP <- data.table(sci = sort(unique(oc$scientificName)))
SP[, taxon := toupper(paste0(substr(sub(" .*", "", sci), 1, 3), substr(sub(".* ", "", sci), 1, 3)))]
stopifnot(!anyDuplicated(SP$taxon))
long <- merge(oc[, .(eventID, sci = scientificName, y = as.integer(organismQuantity))], SP, by = "sci")
long <- merge(long, ev[, .(eventID, unit, period, occasion, date = fifelse(nchar(eventDate) == 10L, eventDate, NA_character_),
                           cluster_id = gsub("[^A-Za-z0-9]+", "_", locality), unit_depth_min_m = as.integer(minimumDepthInMeters),
                           unit_depth_max_m = as.integer(maximumDepthInMeters), unit_country = country,
                           unit_decimalLatitude = clat, unit_decimalLongitude = clon, unit_coordinateUncertaintyInMeters = cunc,
                           obs_team = institutionCode)], by = "eventID")
long <- long[, .(unit, taxon, y, period, occasion, date, cluster_id, unit_depth_min_m, unit_depth_max_m, unit_country,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters, obs_team)]
setorder(long, unit, period, occasion, taxon)
stopifnot(nrow(long) == 47130L, !anyNA(long$y), sum(long$y) == sum(as.integer(oc$organismQuantity)),
          long[, uniqueN(paste(unit_country, unit_decimalLatitude, cluster_id)), by = unit][, all(V1 == 1L)])

taxa <- make_taxa(SP$taxon, SP$sci)
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxon_iucnCategory)])
# set by hand from the IUCN record GBIF returns: Epinephelus marginatus is assessed as Mycteroperca marginata, VU (IUCN 7859)
stopifnot(is.na(taxa[taxon == "EPIMAR", taxon_iucnCategory]))
taxa[taxon == "EPIMAR", taxon_iucnCategory := "VU"]
stopifnot(taxa[scientificName == "Epinephelus marginatus", taxon_iucnCategory %in% c("VU", "EN", "CR")])
NIS <- c("Fistularia commersonii", "Siganus luridus", "Siganus rivulatus", "Pterois miles", "Stephanolepis diaspros",
         "Parupeneus forsskali", "Pempheris rhomboidea", "Torquigener flavimaculosus")
stopifnot(all(NIS %in% SP$sci))
taxa[, taxon_mediterranean_status := fifelse(scientificName %in% NIS, "non-indigenous", "native")]
periods <- unique(ev[, .(period, year = yr, month = mo)])
setorder(periods, period)
dataset <- list(
  title = sprintf("ClimateFish: visual-census counts of 15 coastal fish species on %d transects at %d locations x depth layers, Mediterranean Sea, %d-%d",
                  nrow(ev), uniqueN(long$unit), min(ev$yr), max(ev$yr)),
  creator = "Azzurro, Ernesto; Ballerini, Tosca; Antoniadou, Chryssanthi; et al. (ClimateFish network)",
  pubDate = "2022", doi = "10.17882/86784", sourceURL = "https://doi.org/10.17882/86784", paperDOI = "10.3389/fmars.2022.910887",
  citation = "Azzurro E, Ballerini T, Antoniadou C, et al. (2022). ClimateFish: Abundance of selected coastal fish species as candidate indicators of climate change in the Mediterranean Sea. SEANOE. https://doi.org/10.17882/86784",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("ClimateFish collaborative monitoring of 15 coastal fish species chosen as candidate indicators of climate change in the Mediterranean (7 native, 8 non-indigenous, among them Siganus luridus, S. rivulatus and Pterois miles). Divers count every target species on four consecutive five-minute transects (about 50 x 5 m) per location and depth layer (0-3, 5-10, 11-20, 21-30 m). %d transects at %d locations in %d countries, %d-%d. One row per transect and species, y = individuals counted; the unit is a location x depth layer, the period a calendar month, the occasion a transect within it.",
                     nrow(ev), uniqueN(ev$locality), uniqueN(ev$country), min(ev$yr), max(ev$yr)),
  samplingProtocol = "Simplified underwater visual census: at each location and depth layer a diver swims four consecutive replicate transects of five minutes at about 10 m/min (about 50 x 5 m), counting all individuals of 15 target species (Azzurro et al. 2022, after Garrabou et al. 2019).",
  samplingProtocolCode = "visual_census", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "Replicate transects are swum consecutively on one dive in most unit-months; a few unit-months combine transects from different days of the month (date shows which), and 457 transects are dated to the month only.",
  occasionKind = "spatial", taxonInclusion = "target",
  geographicCoverage = "Mediterranean Sea: Malta, Italy, Croatia, Spain, France, Greece, Tunisia, Cyprus (coordinates coarsened to 0.1 degree)",
  temporalCoverage = sprintf("%d-%02d/%d-%02d", min(ev$yr), ev[yr == min(yr), min(mo)], max(ev$yr), ev[yr == max(yr), max(mo)]),
  coordinatesCoarsened = list(value = TRUE, rule = "taxon", method = "Location coordinates (5 decimals) coarsened to the 0.1 degree cell centre with coarsen_coords(): Epinephelus marginatus (dusky grouper) is IUCN VU and native to the Mediterranean."),
  notes = "Counts of target species only (taxonInclusion = target). Most unit-months have four transects; 57 have eight (two divers or two sets) and a few fewer than four. obs_team is the contributing institution (20). Non-indigenous status of each species is taxon_mediterranean_status in the taxa side table (from the paper).",
  notShipped = list(exact_coordinates = "coarsened to 0.1 degree (Epinephelus marginatus, IUCN VU)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("ClimateFish visual-census counts of 15 coastal fish species (7 native, 8 non-indigenous) on four replicate transects per location x depth layer, %d locations in 8 Mediterranean countries, %d-%d.",
                        uniqueN(ev$locality), min(ev$yr), max(ev$yr)),
  url = "https://doi.org/10.17882/86784",
  reference = "Azzurro E, et al. (2022). ClimateFish: a collaborative database to track the abundance of selected coastal fish species as candidate indicators of climate change in the Mediterranean Sea. Frontiers in Marine Science 9, 910887.",
  doi_paper = "10.3389/fmars.2022.910887", doi_data = "10.17882/86784", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "VLIZ IPT DwC-A (climate-fish-abundance, 2022-10-04), same data as SEANOE 10.17882/86784; found via EDITO / EurOBIS (IMIS 8121).",
  source_via = "VLIZ IPT")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "visual_census", design = sprintf("Multi-season (%d months; 4 replicate transects per location x depth layer x visit)", uniqueN(long$period)),
  realm = "Marine", country = "MLT, ITA, HRV, ESP, FRA, GRC, TUN, CYP", coordinates = "Coarsened (0.1 deg)",
  notes = "Diver transect counts of 15 indicator species including 8 non-indigenous (Lessepsian) fishes.")
