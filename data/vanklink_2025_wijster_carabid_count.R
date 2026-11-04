#!/usr/bin/env Rscript
# Table:  vanklink_2025_wijster_carabid_count
# Source: GBIF sampling-event dataset 776f3477-2a0d-407d-8332-5bd6b1a31b4a, doi:10.15468/3mcqja,
#         NLBIF IPT resource bsw_standard_series, EML packageId .../v1.8, pubDate 2025-10-09.
#         Licence as shown on GBIF and in the EML: CC0 1.0 (Creative Commons Zero v1.0 Universal,
#         "the publisher has waived all rights to these data").
#         Citation (EML): Van Klink R, Gerrits G, Vermeulen R (2025). Biological Station Wijster
#         standard trapping program: Sampling event data for ground beetles (Coleoptera:
#         Carabidae). Netherlands Biodiversity Information Facility (NLBIF). Samplingevent
#         dataset. https://doi.org/10.15468/3mcqja
# Paper:  none for this release; the programme is described in Den Boer (1977, Misc. Pap.
#         Landbouwhogeschool Wageningen 14) and used in Van Klink et al. (2019, 2020), cited in
#         the EML. The EML refers to a "data paper" not yet published.
# Data:   Darwin Core Archive, event core with occurrence and Humboldt extensions.
#   event.txt (15,435 events in four levels): the dataset (BSW); 104 series-years (a location's
#     three traps over one sampling year, 1 March - end of February, with 1062-1092 trap-days);
#     306 trap-years (locationID "<location>-pf.<n>", samplingProtocol live trap or funnel trap
#     with 3% formaldehyde); 15,024 collection events (eventDate start/end interval of the
#     catch, sampleSizeValue = trap-days 4-28, mostly 7). 54 locations, 156 traps (a trap keeps
#     its locationID and type across years), sampling years 1959, 1961, 1963, 1965, 1966.
#     Coordinates to 4 decimals with coordinateUncertaintyInMeters 20-1000 m, reconstructed by
#     the publisher from historical sources. Habitat text per location.
#   occurrence.txt (45,486 rows): one row per species x sex (m / f / u) per collection event with
#     individualCount; 4,899 rows are scientificName = 'Carabidae', individualCount = 0,
#     occurrenceStatus = absent: collections with no beetle ("zero counts were removed, and only
#     restored for events where no ground beetles were collected"). 134 species (the EML abstract says 135).
#   humboldtecologicalinventory.txt (306 rows, one per trap-year): target taxon Carabidae,
#     taxonCompletenessReported = reportedComplete, isAbsenceReported = true, adults; voucher
#     storage per trap-year.
#   EML caveats: five species pairs not reliably separated in the historical period (Calathus
#     melanocephalus / cinctus, Bradycellus collaris / harpalinus, Pterostichus nigrita /
#     rhaeticus, Bembidion lampros / properans, Poecilus versicolor / cupreus) and some species
#     in Agonum, Asaphidion, Amara and Harpalus possibly overlooked; shipped under the names
#     recorded (the deposit has no merged taxa; only one name of each pair occurs); v1.1:
#     taxonRemarks in __taxa on those five taxa.
#
# Mapping (standard E1-E5, trap counts per collection interval / community N-mixture):
#   unit = trap (locationID, 156), cluster_id = location (the three-trap series, 54),
#   taxon = 8-letter code (4 genus + 4 species letters; Harpalus rufipalpis is HARPRUPL beside
#   HARPRUFI for H. rufipes), period = sampling year index
#   1..5 (1959, 1961, 1963, 1965, 1966 in __periods; a sampling year runs 1 March - end of
#   February), occasion = collection within the trap-year in date order (46-52), y = adults of
#   the species in the catch (sum of individualCount over sexes); 0 for every one of the 134
#   species at every collection, since every carabid is identified and counted (Humboldt
#   reportedComplete). date = end of the collection interval; obs_trap_days = interval length
#   (the effort; catches accumulate when a weekly emptying was skipped). Unit covariates in
#   __units: trap type (live / funnel), location, locality, habitat, coordinates and their
#   uncertainty as published.
#   surveyEvidence = sample_table: every collection is an event with its trap-days, and every
#   occurrence row belongs to a listed collection (asserted); a collection without beetles is
#   listed with an explicit 'Carabidae' absence.
#   Coordinates: as published; the script looks up each species' IUCN category through GBIF
#   (iucn_category()) and stops if any is CR / EN / VU (none is, at the time of writing).
#   v1.1: closure = open (year-round collections), occasionKind = time, taxonInclusion =
#   recorded (all 134 species are in the occurrence records).
#   Not shipped: the sex breakdown (summed into y); the series-year and trap-year aggregates
#   (sums of the collections); voucher storage flags.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "vanklink_2025_wijster_carabid_count"

zip <- download_cached("https://ipt.nlbif.nl/archive.do?r=bsw_standard_series", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "humboldtecologicalinventory.txt", "eml.xml", "meta.xml")))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("Creative Commons Zero v1.0 Universal", eml)), any(grepl("spdx.org/licenses/CC0-1.0", eml)),
          any(grepl("776f3477-2a0d-407d-8332-5bd6b1a31b4a/v1.8", eml)))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
hu <- fread(file.path(dwca, "humboldtecologicalinventory.txt"), quote = "", colClasses = "character")
ev[, lvl := lengths(strsplit(eventID, ".", fixed = TRUE))]
stopifnot(nrow(ev) == 15435, !anyDuplicated(ev$eventID), identical(as.vector(table(ev$lvl)), c(1L, 104L, 306L, 15024L)),
          nrow(oc) == 45486, nrow(hu) == 306)
ser <- ev[lvl == 3]; tr <- ev[lvl == 4]; co <- ev[lvl == 5]
stopifnot(all(tr$parentEventID %in% ser$eventID), all(co$parentEventID %in% tr$eventID),
          setequal(hu$id, tr$eventID), all(hu$taxonCompletenessReported == "reportedComplete"), all(hu$isAbsenceReported == "true"),
          all(hu$targetTaxonomicScope == "Carabidae"))
tr[, `:=`(funnel = grepl("funnel", samplingProtocol), loc = sub("-pf\\.[0-9]+$", "", locationID))]
stopifnot(all(grepl("^[A-Z]+-pf\\.[0-9]+$", tr$locationID)), uniqueN(tr$locationID) == 156, uniqueN(tr$loc) == 54,
          sum(tr$funnel) == 104, tr[, uniqueN(funnel), by = locationID][, all(V1 == 1)],
          all(tr$loc == ser$locationID[match(tr$parentEventID, ser$eventID)]),
          ser[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, habitat, locality)), by = locationID][, all(V1 == 1)],
          all(ev[lvl >= 3, geodeticDatum] == "WGS84"))

# collections
stopifnot(all(grepl("^\\d{4}-\\d{2}-\\d{2}/\\d{4}-\\d{2}-\\d{2}$", co$eventDate)), all(co$sampleSizeUnit == "days"),
          all(co$locationID == tr$locationID[match(co$parentEventID, tr$eventID)]))
co[, `:=`(start = as.IDate(sub("/.*$", "", eventDate)), end = as.IDate(sub("^.*/", "", eventDate)), trap_days = as.integer(sampleSizeValue))]
stopifnot(all(as.integer(co$end - co$start) == co$trap_days), all(co$trap_days >= 4 & co$trap_days <= 28),
          !anyDuplicated(co[, .(parentEventID, end)]))
tyear <- sub("^(\\d{4}).*$", "\\1", tr$eventDate); stopifnot(setequal(tyear, c("1959", "1961", "1963", "1965", "1966")))
co[, syear := as.integer(substr(tr$eventDate[match(parentEventID, tr$eventID)], 1, 4))]
years <- c(1959L, 1961L, 1963L, 1965L, 1966L)
setorder(co, parentEventID, end)
co[, occasion := seq_len(.N), by = parentEventID]
stopifnot(co[, .N, by = parentEventID][, all(N >= 46 & N <= 52)])

# occurrences
stopifnot(all(oc$eventID %in% co$eventID), all(co$eventID %in% oc$eventID),
          all(oc$individualCount == oc$organismQuantity), all(oc$organismQuantityType == "individuals"),
          oc[taxonRank == "family", all(scientificName == "Carabidae" & individualCount == "0" & occurrenceStatus == "absent")],
          oc[taxonRank == "species", all(occurrenceStatus == "present" & as.integer(individualCount) >= 1)],
          all(oc$taxonRank %in% c("species", "family")), sum(oc$taxonRank == "family") == 4899,
          oc[, .(fam = any(taxonRank == "family"), sp = any(taxonRank == "species")), by = eventID][, !any(fam & sp)],
          all(oc[taxonRank == "species", sex] %in% c("m", "f", "u")), !anyDuplicated(oc[, .(eventID, scientificName, sex)]))
sp <- data.table(scientificName = sort(unique(oc[taxonRank == "species", scientificName])))
sp[, binomial := sub("^(\\S+ \\S+).*$", "\\1", scientificName)]
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", binomial), 1, 4), substr(sub("^\\S+ ", "", binomial), 1, 4)))]
sp[binomial == "Harpalus rufipalpis", taxon := "HARPRUPL"]       # HARPRUFI is Harpalus rufipes
stopifnot(nrow(sp) == 134, !anyDuplicated(sp$binomial), !anyDuplicated(sp$taxon))
counts <- oc[taxonRank == "species", .(y = sum(as.integer(individualCount))), by = .(eventID, scientificName)]
counts[, taxon := sp$taxon[match(scientificName, sp$scientificName)]]

# taxa and the IUCN check
taxa <- make_taxa(sp$taxon, sp$binomial, lookupName = sp$binomial, scientificNameAuthorship = trimws(sub("^\\S+ \\S+", "", sp$scientificName)))
# iucn_category() checks the assessed name: GBIF links Calathus mollis (Marsham), a common dune
# carabid, through a synonym "Calathus mollis Marsh." to the extinct St Helena C. extensicollis,
# which comes back NA (not this species' assessment) and is set to NE
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa[is.na(taxon_iucnCategory), taxon], "CALAMOLL"))
taxa[taxon == "CALAMOLL", taxon_iucnCategory := "NE"]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))

# species pairs the EML says were not reliably separated in the historical period: only one name
# of each pair is recorded in the deposit; it is shipped as recorded and taxonRemarks says it may
# include the other (E6)
pairs <- list(c("Calathus melanocephalus", "Calathus cinctus"), c("Bradycellus harpalinus", "Bradycellus collaris"),
              c("Pterostichus nigrita", "Pterostichus rhaeticus"), c("Bembidion lampros", "Bembidion properans"),
              c("Poecilus versicolor", "Poecilus cupreus"))
stopifnot(all(sapply(pairs, `[`, 1) %in% taxa$scientificName), !any(sapply(pairs, `[`, 2) %in% taxa$scientificName))
taxa[, taxonRemarks := NA_character_]
for (pp in pairs)
  taxa[scientificName == pp[1], taxonRemarks := sprintf("not reliably separated from %s in the historical period (EML), which is not recorded separately; may include it", pp[2])]

# long table
units <- tr[!duplicated(locationID)][, .(unit = locationID, unit_trap_type = fifelse(funnel, "funnel_formaldehyde", "live"), unit_location = loc)]
loc <- ser[!duplicated(locationID), .(unit_location = locationID, unit_locality = locality, unit_habitat = habitat,
          unit_decimalLatitude = as.numeric(decimalLatitude), unit_decimalLongitude = as.numeric(decimalLongitude),
          unit_coordinateUncertaintyInMeters = as.numeric(coordinateUncertaintyInMeters))]
units <- merge(units, loc, by = "unit_location")[, .(unit, unit_trap_type, unit_location, unit_locality, unit_habitat,
          unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)]
stopifnot(nrow(units) == 156, !anyNA(units$unit_decimalLatitude))
surveys <- co[, .(eventID, unit = locationID, cluster_id = sub("-pf\\.[0-9]+$", "", locationID), period = match(syear, years),
                  occasion, date = format(end), obs_trap_days = trap_days)]
long <- surveys[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(surveys))]
long <- merge(long, counts[, .(eventID, taxon, y)], by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, eventID := NULL]
stopifnot(nrow(long) == 15024 * 134, sum(long$y) == 90070, uniqueN(long$unit) == 156)
long <- order_eco(long)

periods <- data.table(period = seq_along(years), period_year = years,
                      period_start = sapply(years, function(yy) format(min(co[syear == yy, start]))),
                      period_end = sapply(years, function(yy) format(max(co[syear == yy, end]))),
                      period_n_traps = sapply(years, function(yy) co[syear == yy, uniqueN(locationID)]))
dataset <- list(
  title = "Pitfall-trap counts of 134 ground beetle species per collection at 156 traps, Biological Station Wijster, Drenthe, the Netherlands, 1959-1967",
  creator = "Van Klink, Roel; Gerrits, Gijs; Vermeulen, Rikjan", pubDate = "2025-10-09", sourceURL = "https://doi.org/10.15468/3mcqja",
  citation = "Van Klink R, Gerrits G, Vermeulen R (2025). Biological Station Wijster standard trapping program: Sampling event data for ground beetles (Coleoptera: Carabidae). Netherlands Biodiversity Information Facility (NLBIF). Samplingevent dataset. https://doi.org/10.15468/3mcqja (CC0 1.0).",
  dataDOI = "10.15468/3mcqja",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Year-round pitfall trapping of ground beetles in forests, heathlands and bogs of Drenthe by the Biological Station Wijster (P. J. den Boer's programme), sampling years 1959, 1961, 1963, 1965 and 1966: three traps per location (two live traps and one funnel trap with formaldehyde), emptied mostly weekly; every carabid identified to species and counted. 15,024 collections, 90,070 beetles, 134 species.",
  samplingProtocol = "Square metal pitfall traps (1 m perimeter) with rain covers, three per location about 10 m apart in a line, the middle one with a funnel into 3% formaldehyde, the outer two live traps; run year-round (1 March - end of February) and emptied mostly weekly; catches accumulate over a skipped emptying (obs_trap_days).",
  samplingProtocolCode = "pitfall_trap", effortColumn = "obs_trap_days", occasionLength = "one collection interval (4-28 days, mostly 7)",
  surveyEvidence = "sample_table",
  surveyEvidenceNote = "Every collection is an event (level 5) with its interval and trap-days; collections with no beetles carry an explicit 'Carabidae' absence record, and the Humboldt extension declares complete reporting of Carabidae per trap-year, so a species absent from a collection's records is a zero.",
  responseType = "count", unitKind = "site",
  closure = "open", closureNote = "not assumed: occasions are the successive collections of a whole year, so activity-density follows each species' phenology; period = sampling year",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Forests, heathlands and bogs in Drenthe, the Netherlands (Mantingerbos, Dwingelderveld, Mantingerveld, Bargerveen, Dalerpeel, Kraloo, Wijster, Bruntinge, Eursinge)",
                            boundingBox = list(west = min(units$unit_decimalLongitude), east = max(units$unit_decimalLongitude),
                                               south = min(units$unit_decimalLatitude), north = max(units$unit_decimalLatitude))),
  temporalCoverage = sprintf("%s/%s", min(co$start), max(co$end)),
  coordinatesCoarsened = list(value = FALSE, method = "As published (reconstructed historical trap locations, uncertainty 20-1000 m in unit_coordinateUncertaintyInMeters); no species is IUCN CR, EN or VU (checked through GBIF) and the source flags none"),
  notShipped = list(`occurrence.txt sex` = "male / female / unknown breakdown, summed into y",
                    `series-year and trap-year events` = "aggregates (sums) of the collections",
                    `humboldtecologicalinventory.txt voucher fields` = "which trap-years' material is stored at Naturalis",
                    `possibly overlooked species` = "per the EML, species of Agonum, Asaphidion, Amara and Harpalus may have been overlooked in the historical period (the five species pairs not reliably separated are shipped as recorded, with taxonRemarks in __taxa)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/vanklink_2025_wijster_carabid_count.R")

stage_dict_row(TABLE,
  description = "Counts of 134 ground beetle species in 15,024 mostly weekly pitfall collections at 156 traps (54 three-trap locations) in forests, heathlands and bogs of Drenthe, the Netherlands, run year-round in 1959, 1961, 1963, 1965 and 1966 by the Biological Station Wijster, with trap-days per collection, trap type and habitat.",
  url = "https://doi.org/10.15468/3mcqja",
  reference = "Van Klink R, Gerrits G, Vermeulen R (2025). Biological Station Wijster standard trapping program: Sampling event data for ground beetles (Coleoptera: Carabidae). NLBIF. Samplingevent dataset.",
  doi_data = "10.15468/3mcqja", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Zeros from the collection event list (empty collections carry an explicit Carabidae absence; Humboldt reportedComplete). Sexes summed. Five species pairs not reliably separated historically (EML). First digitised part of a programme running since 1959; later years to follow.",
  source_via = "GBIF (NLBIF IPT)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "pitfall_trap", design = "Multi-season (5 sampling years x 46-52 collections per trap); three traps per location",
  realm = "Terrestrial", country = "Netherlands", coordinates = "As published",
  notes = "Historical (1959-1967) carabid pitfall series; obs_trap_days is the effort; occasions span a whole year (phenology, not closure).", status = "tagged")
