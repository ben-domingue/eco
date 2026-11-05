#!/usr/bin/env Rscript
# Table:  faveyts_2026_zwin_butterfly_count
# Source: GBIF sampling-event dataset c46d695c-bc44-439c-8645-cb04ef4cfe5d, doi:10.15468/nch6xe,
#         version 1.3, Belgian Biodiversity Platform IPT resource zwin-park-butterflies-observations.
#         Licence as shown on GBIF and in the EML: CC BY 4.0.
#         Citation: Faveyts W, Cooleman S (2026). Butterfly transect counts at the Zwin Nature Park.
#         Version 1.3. Belgian Biodiversity Platform. Samplingevent dataset.
# Paper:  none.
# Data:   Darwin Core Archive (event core + occurrence extension):
#   event.txt (260 rows): one row per transect count (eventID ZNP:Butterflies:<date>-<letter>, the
#     letter is the order of the count within the day, not a route), parentEventID = year-season,
#     eventDate, samplingProtocol "Transect count", sampleSizeValue = transect length in metres,
#     coordinates. 2023 (64) and 2024 (96) counts have no locationID and the park centroid
#     (uncertainty 299 m); the EML says routes were "not always strictly identical" then. From 2025
#     (100 counts) "every transect count is allocated to one of the 12 mapped routes"
#     (locationID ZNP_Dagvlinder_route_1..12, habitat, route coordinates, uncertainty 40-110 m).
#   occurrence.txt (6,061 rows): per count, one row per checklist taxon with individualCount and
#     occurrenceStatus (absent = 0); the checklist is 21 taxa in 2023-2024 and 27 in 2025. One 2025
#     row is a Nymphalidae "species aggregate" (Aglais urticae / Nymphalis polychloros / N.
#     xanthomelas), present at one count only.
#   Protocol (EML): one observer (W. Faveyts) walks the route in good weather (sunny, warm, calm)
#   and counts all individuals of all butterfly species seen; zero records are logged
#   systematically. Counting frequency is opportunistic (weekly to several per day).
# Mapping (repeated counts, N-mixture family): 2025 only. unit = locationID (route), unit_habitat
#   as published; period absent (one season); occasion = count on the route ordered by date then
#   eventID (route 4 was counted twice on 2025-04-17); date = eventDate; y = individualCount;
#   obs_transect_length_m = sampleSizeValue. taxon = the 27 checklist taxa reported at every 2025
#   count, including "Pieris" at genus rank (whites not identified to species); 8 checklist species
#   were not seen in 2025 and keep their zero rows (taxonInclusion = target: the observer's fixed
#   checklist). surveyEvidence = sample_table: every event is a count with explicit absent rows.
#   closure = open: counts run from April to September across butterfly flight periods.
#   Coordinates: route positions as published (uncertainty 40-110 m), in a public nature reserve;
#   all taxa are IUCN LC or not assessed, so nothing is coarsened. Favonius quercus and Ochlodes
#   sylvanus get NE by hand (GBIF's accepted names differ, so iucn_category() returns NA; the IUCN
#   record GBIF serves for both keys is NOT_EVALUATED).
#   Not shipped: 2023-2024 counts (160 events, no route identity: a count cannot be assigned to a
#   unit); the single Nymphalidae aggregate record (not on the checklist; reported at one count).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "faveyts_2026_zwin_butterfly_count"
zip <- download_cached("https://ipt.biodiversity.be/archive.do?r=zwin-park-butterflies-observations", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("Creative Commons Attribution \\(CC-BY 4.0\\)", eml)), any(grepl("c46d695c-bc44-439c-8645-cb04ef4cfe5d/v1.3", eml)))
ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 260, nrow(oc) == 6061, !anyDuplicated(ev$eventID), all(oc$eventID %in% ev$eventID),
          all(ev$samplingProtocol == "Transect count"), all(ev$sampleSizeUnit == "meter"),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)), all(oc$identifiedBy == "Wouter Faveyts"),
          all(oc[occurrenceStatus == "absent", individualCount] == "0"),
          all(as.integer(oc[occurrenceStatus == "present", individualCount]) >= 1))
ev[, year := substr(eventDate, 1, 4)]
stopifnot(identical(as.integer(table(ev$year)), c(64L, 96L, 100L)), all(ev[year < "2025", locationID] == ""),
          all(ev[year == "2025", locationID] != ""), uniqueN(ev[year == "2025", locationID]) == 12,
          ev[year == "2025", uniqueN(paste(habitat, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1)])
e <- ev[year == "2025"]
o <- oc[eventID %in% e$eventID]
nym <- o[scientificName == "Nymphalidae"]
stopifnot(nrow(nym) == 1, nym$individualCount == "1")
o <- o[scientificName != "Nymphalidae"]
stopifnot(o[, .N, by = eventID][, .N == 100 && all(N == 27)], uniqueN(o$scientificName) == 27)   # full checklist at every count

sp <- unique(o[, .(scientificName, taxonRank, vernacularName)])
sp[, name := sub(" \\(?[A-Z][^ ]*.*$", "", scientificName)]        # drop the authorship
sp[, name := sub(" Hübner, 1819$", "", name)]
stopifnot(sp[taxonRank == "genus", name] == "Pieris", all(lengths(strsplit(sp[taxonRank == "species", name], " ")) == 2))
sp[, taxon := ifelse(taxonRank == "genus", "PIESPP", toupper(paste0(substr(name, 1, 3), substr(sub(".* ", "", name), 1, 3))))]
stopifnot(!anyDuplicated(sp$taxon))
o <- merge(o, sp[, .(scientificName, taxon)], by = "scientificName")
setorder(e, locationID, eventDate, eventID)
e[, occasion := seq_len(.N), by = locationID]
long <- merge(o[, .(eventID, taxon, y = as.integer(individualCount))],
              e[, .(eventID, unit = sub("ZNP_Dagvlinder_route_", "R", locationID), occasion, date = eventDate, unit_habitat = habitat,
                    unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
                    unit_coordinateUncertaintyInMeters = as.integer(coordinateUncertaintyInMeters),
                    obs_transect_length_m = as.integer(sampleSizeValue))], by = "eventID")
long[, eventID := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 2700, uniqueN(long$unit) == 12, max(long$occasion) == 13, sum(long$y) == 957)

# the butterfly genus: plain "Pieris" is a homonym (also a plant genus) and GBIF strict matching returns NONE
taxa <- make_taxa(sp$taxon, sp$name, vernacularName = sp$vernacularName, taxonRank = sp$taxonRank,
                  lookupName = ifelse(sp$taxon == "PIESPP", "Pieris Schrank, 1801", sp$name),
                  taxon_n_individuals_2025 = long[, sum(y), by = taxon][match(sp$taxon, taxon), V1])
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# Favonius quercus and Ochlodes sylvanus: GBIF treats them as synonyms of Quercusia quercus and Ochlodes
# venata, so iucn_category() returns NA; GBIF's IUCN record for both keys reads NOT_EVALUATED (NE). Set by hand.
stopifnot(setequal(taxa[is.na(taxon_iucnCategory), taxon], c("FAVQUE", "OCHSYL")))
taxa[taxon %in% c("FAVQUE", "OCHSYL"), taxon_iucnCategory := "NE"]
stopifnot(all(taxa$taxon_iucnCategory %in% c("LC", "NE")))

dataset <- list(
  title = "Butterfly transect counts on 12 routes in the Zwin Nature Park, Belgium, 2025 (27 checklist taxa, 100 counts)",
  creator = "Faveyts, Wouter; Cooleman, Stijn",
  pubDate = "2026", doi = "10.15468/nch6xe", sourceURL = "https://doi.org/10.15468/nch6xe",
  citation = "Faveyts W, Cooleman S (2026). Butterfly transect counts at the Zwin Nature Park. Version 1.3. Belgian Biodiversity Platform. Samplingevent dataset. https://doi.org/10.15468/nch6xe",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Repeated butterfly transect counts by one observer on 12 mapped routes (80-300 m) in the Zwin Nature Park, a coastal dune and salt-marsh reserve at Knokke-Heist, Belgium, April to September 2025. Each count reports every taxon on the observer's 27-taxon checklist, with explicit zeros. Counts were made opportunistically in good weather, from weekly to several per day.",
  samplingProtocol = "Transect count: one observer walks a mapped route in sunny, warm, calm weather and counts all butterflies seen of every species; absences on the checklist are recorded as zero.",
  samplingProtocolCode = "transect_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "open", occasionKind = "time", taxonInclusion = "target",
  closureNote = "occasion = count on a route ordered by date, April to September 2025; counts span the flight periods of different species, so abundance changes across occasions",
  geographicCoverage = "Zwin Nature Park, Knokke-Heist, West Flanders, Belgium (route coordinates as published, uncertainty 40-110 m)",
  temporalCoverage = "2025-04/2025-09",
  coordinatesCoarsened = list(value = FALSE, method = "Route coordinates as published by the data holder (uncertainty 40-110 m); public nature reserve; no IUCN-flagged taxon."),
  notes = "Pieris at genus rank (PIESPP) is the observer's 'Pieris' category for whites not identified to species, reported at every count alongside the four Pieris species. Eight checklist species were not seen in 2025 (zero at every count). Counting effort varies: obs_transect_length_m is the route length; dates are opportunistic, not a fixed schedule.",
  notShipped = list(
    `2023-2024 counts` = "160 counts with no route identity (park centroid, no locationID; the EML says routes were not always identical): a count cannot be assigned to a unit",
    `Nymphalidae aggregate` = "one record (Aglais urticae / Nymphalis polychloros / N. xanthomelas, 1 individual, route 5, 2025-04-03): not on the checklist, reported at one count only"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = sprintf("data/%s.R", TABLE))
stage_dict_row(TABLE,
  description = "Repeated butterfly transect counts (27 checklist taxa with explicit zeros) on 12 routes in the Zwin Nature Park, Belgium, April-September 2025, with route length and habitat.",
  url = "https://doi.org/10.15468/nch6xe",
  reference = "Faveyts W, Cooleman S (2026). Butterfly transect counts at the Zwin Nature Park. Version 1.3. Belgian Biodiversity Platform.",
  doi_paper = "", doi_data = "10.15468/nch6xe",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Belgian Biodiversity Platform IPT DwC-A (v1.3). 2025 only: 2023-2024 counts carry no route identity.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open)",
  sampling_protocol = "transect_count", design = "Single-season (12 routes x 6-13 counts)", realm = "Terrestrial",
  country = "BEL", coordinates = "As published", notes = "Single observer; opportunistic timing in good weather; route length varies.",
  status = "tagged")
