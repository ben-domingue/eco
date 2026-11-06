#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_batwinter_count
# Source: GBIF sampling-event dataset 166dae2d-563f-4ccd-ad93-8ce3b01db975, doi:10.15468/5s3ctr, version 1.7 (2025),
#         INBO IPT resource meetnetten-vleermuizen-wintertelling-telobject-occurrences. Licence as shown on GBIF and in
#         the EML: CC0 1.0 (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, De Bruyn L, Gyselings R, Dekeukeleire D, Cooleman S, Brosens D, Westra T, Desmet P,
#         Ruyts S, Lefevre A, Vandendriessche B, Boers K, Vermeiren H, Palmans G, Roels E, Pollet M (2025). Meetnetten.be -
#         Bat winter roosts counts (totals per site) Flanders, Belgium. Version 1.7. Research Institute for Nature and
#         Forest (INBO). Sampling event dataset. https://doi.org/10.15468/5s3ctr
# Paper:  none; protocol in the Meetnetten.be bat monitoring protocol (INBO), summarised in the EML.
# Data:   Darwin Core Archive, event core with an occurrence extension.
#   event.txt (11,319 rows): one row per count of a hibernation site (cellar, bunker, ice-house, small fort) at which
#     only the totals per species are registered for the whole site; eventDate one day; locationID the site (1,380);
#     decimalLatitude/Longitude generalised by INBO to the centroid of a 5 or 10 km UTM square ('original locations
#     available upon request'); 1943-2024, mostly October-March.
#   occurrence.txt (25,490 rows): individuals per taxon per count, behavior 'hibernation'; 25,293 present and 197
#     absent rows (count 0); bats (Chiroptera) plus incidental hibernating moths, butterflies, flies, spiders and
#     amphibians. Two identification classes share a scientificName with a species: 'Myotis mystacinus' with
#     identificationQualifier 'species aggregate' (verbatim 'Myotis mystacinus/brandtii') and 'Plecotus auritus' with
#     'species aggregate' (verbatim 'Plecotus auritus/austriacus'); the class key is scientificName + qualifier
#     (asserted unique per count). 126 counts have no occurrence row (no animal found). 12 occurrence rows point to
#     eventIDs missing from the event core (dropped, notShipped).
#   Protocol (EML): all hibernating bats in the site are counted and identified as far as possible during the winter
#     counts; totals per species are registered for the entire site.
# Mapping (repeated counts, bat community; responseType count): unit = hibernation site (locationID, S<number>),
#   period = winter, labelled by its January year (counts from August to December belong to the next winter; 1943 to
#   2025), occasion = count within the winter in date order, date = eventDate. taxon = identification class of a bat
#   (23 classes: 17 species, the two species aggregates, Myotis, Pipistrellus and Nyctalus at genus rank, Chiroptera
#   at order rank, as recorded). y = individuals of the class counted (0 where the class has no row at a count, or an
#   absent row). surveyEvidence = sample_table: the event core lists every count, and the protocol counts every bat in
#   the site, so a class with no row at a count was counted zero; the 126 counts without any occurrence are counts at
#   which no animal was found. taxonInclusion = recorded. A zero for 'Myotis mystacinus' (species) is not an absence
#   of the species where the aggregate class was used; the taxonRemarks say so.
#   Coordinates: generalised by INBO (an agency) to UTM square centroids before publication; kept as published (E7).
# Not shipped: non-bat taxa (incidental hibernating invertebrates and amphibians, not counted by protocol).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_batwinter_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-vleermuizen-wintertelling-telobject-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("166dae2d-563f-4ccd-ad93-8ce3b01db975/v1.7", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 11319L, nrow(oc) == 25490L, !anyDuplicated(ev$eventID),
          all(ev$samplingProtocol == "Bat winter roosts counts (totals per site)"),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          uniqueN(ev$locationID) == 1380L, all(ev$dataGeneralizations %in% c("UTM 5km", "UTM 10km")),
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1L)],
          sum(!oc$eventID %in% ev$eventID) == 12L, sum(!ev$eventID %in% oc$eventID) == 126L,
          all(oc$occurrenceStatus %in% c("present", "absent")), sum(oc$occurrenceStatus == "absent") == 197L,
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          all(oc$identificationQualifier %in% c("", "species aggregate")),
          setequal(oc[identificationQualifier == "species aggregate", unique(scientificName)], c("Myotis mystacinus", "Plecotus auritus")),
          !anyDuplicated(oc[, .(eventID, scientificName, identificationQualifier)]))
orphan <- oc[!eventID %in% ev$eventID]
oc <- oc[eventID %in% ev$eventID]

BATS <- data.table(
  sci = c("Myotis mystacinus", "Myotis mystacinus", "Myotis brandtii", "Myotis daubentonii", "Myotis nattereri", "Myotis emarginatus",
          "Myotis dasycneme", "Myotis bechsteinii", "Myotis myotis", "Myotis", "Plecotus auritus", "Plecotus auritus",
          "Plecotus austriacus", "Pipistrellus pipistrellus", "Pipistrellus nathusii", "Pipistrellus", "Eptesicus serotinus",
          "Barbastella barbastellus", "Nyctalus noctula", "Nyctalus", "Rhinolophus hipposideros", "Rhinolophus ferrumequinum", "Chiroptera"),
  qual = c("species aggregate", rep("", 10), "species aggregate", rep("", 11)),
  taxon = c("MYOMYB", "MYOMYS", "MYOBRA", "MYODAU", "MYONAT", "MYOEMA", "MYODAS", "MYOBEC", "MYOMYO", "MYOTIS_SP", "PLEAUR", "PLEAUA",
            "PLEAUS", "PIPPIP", "PIPNAT", "PIPISTRELLUS_SP", "EPTSER", "BARBAR", "NYCNOC", "NYCTALUS_SP", "RHIHIP", "RHIFER", "CHIROPTERA"))
BATS[, name := fifelse(qual == "species aggregate", fifelse(sci == "Myotis mystacinus", "Myotis mystacinus/brandtii", "Plecotus auritus/austriacus"), sci)]
BATS[, rank := fifelse(qual == "species aggregate", "speciesAggregate", fifelse(sci %in% c("Myotis", "Pipistrellus", "Nyctalus"), "genus",
                fifelse(sci == "Chiroptera", "order", "species")))]
BATS[, lookup := fifelse(qual == "species aggregate", sub(" .*", "", sci), sci)]
nonbat <- oc[!paste(scientificName, identificationQualifier) %in% BATS[, paste(sci, qual)]]
stopifnot(!any(grepl("^(Myotis|Plecotus|Pipistrellus|Nyctalus|Eptesicus|Barbastella|Rhinolophus|Chiroptera)", nonbat$scientificName)))
bo <- merge(oc[, .(eventID, sci = scientificName, qual = identificationQualifier, n = as.integer(individualCount))], BATS[, .(sci, qual, taxon)],
            by = c("sci", "qual"))
stopifnot(nrow(bo) + nrow(nonbat) == nrow(oc), setequal(bo$taxon, BATS$taxon))

ev[, `:=`(year = as.integer(substr(eventDate, 1, 4)), month = as.integer(substr(eventDate, 6, 7)))]
ev[, winter := year + (month >= 8L)]
winters <- sort(unique(ev$winter))
setorder(ev, locationID, eventDate, eventID)
ev[, occasion := seq_len(.N), by = .(locationID, winter)]
grid <- CJ(eventID = ev$eventID, taxon = BATS$taxon)
long <- merge(grid, bo[, .(eventID, taxon, n)], by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(n), n := 0L]
long <- merge(long, ev[, .(eventID, locationID, date = eventDate, winter, occasion, lat = decimalLatitude, lon = decimalLongitude,
                           unc = coordinateUncertaintyInMeters)], by = "eventID")
long <- long[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "S", locationID), taxon, y = n, period = match(winter, winters), occasion, date,
                 unit_decimalLatitude = as.numeric(lat), unit_decimalLongitude = as.numeric(lon),
                 unit_coordinateUncertaintyInMeters = as.integer(unc))]
setorder(long, unit, period, occasion, taxon)
stopifnot(nrow(long) == 11319L * 23L, !anyNA(long$y), sum(long$y) == sum(bo$n), sum(long$y > 0) == sum(bo$n > 0))

rem <- rep(NA_character_, nrow(BATS))
rem[BATS$taxon == "MYOMYB"] <- "Species aggregate recorded as one class (Myotis mystacinus / M. brandtii not separated); taxonID is the genus Myotis"
rem[BATS$taxon == "PLEAUA"] <- "Species aggregate recorded as one class (Plecotus auritus / P. austriacus not separated); taxonID is the genus Plecotus"
rem[BATS$taxon == "MYOMYS"] <- "Individuals identified as M. mystacinus; others are in MYOMYB, so a zero here is not an absence of the species"
rem[BATS$taxon == "PLEAUR"] <- "Individuals identified as P. auritus; others are in PLEAUA, so a zero here is not an absence of the species"
rem[BATS$taxon %in% c("MYOTIS_SP", "PIPISTRELLUS_SP", "NYCTALUS_SP", "CHIROPTERA")] <- "Individuals not identified below this rank"
taxa <- make_taxa(BATS$taxon, BATS$name, taxonRank = BATS$rank, lookupName = BATS$lookup, taxonRemarks = rem,
                  allow_higher = c("MYOMYB", "PLEAUA", "MYOTIS_SP", "NYCTALUS_SP", "CHIROPTERA"), no_key = "PIPISTRELLUS_SP")
# Pipistrellus is a homonym on the GBIF backbone (strict match falls to the kingdom); matched with Vespertilionidae as a hint
h <- gbif_taxon_hinted("Pipistrellus", list(kingdom = "Animalia", class = "Mammalia", family = "Vespertilionidae"))
stopifnot(identical(h$canonicalName, "Pipistrellus"), identical(h$kingdom, "Animalia"), identical(h$rank, "genus"))
taxa[taxon == "PIPISTRELLUS_SP", `:=`(taxonID = h$taxonID, gbifMatchType = paste0(h$matchType, " (hinted)"),
     taxonRemarks = paste0(taxonRemarks, "; a homonym on the GBIF backbone, matched with family Vespertilionidae as a hint"))]
stopifnot(!any(kingdom_taxonID(taxa$taxonID)))
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxonRank, taxon_iucnCategory)])
periods <- data.table(period = seq_along(winters), winter = sprintf("%d/%d", winters - 1L, winters), january_year = winters)
dataset <- list(
  title = sprintf("Meetnetten.be winter counts of hibernating bats at %d sites, Flanders, Belgium, %d-%d", uniqueN(long$unit), min(ev$year), max(ev$year)),
  creator = "Piesschaert, Frederik; De Bruyn, Luc; Gyselings, Ralf; Dekeukeleire, Daan; Cooleman, Sam; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ruyts, Sabine; Lefevre, Anne; Vandendriessche, Bart; Boers, Kristiaan; Vermeiren, Hans; Palmans, Gerrit; Roels, Eline; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2025", doi = "10.15468/5s3ctr", sourceURL = "https://doi.org/10.15468/5s3ctr",
  citation = "Piesschaert F, De Bruyn L, Gyselings R, Dekeukeleire D, Cooleman S, Brosens D, Westra T, Desmet P, Ruyts S, Lefevre A, Vandendriessche B, Boers K, Vermeiren H, Palmans G, Roels E, Pollet M (2025). Meetnetten.be - Bat winter roosts counts (totals per site) Flanders, Belgium. Version 1.7. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/5s3ctr",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Winter counts of hibernating bats at %d hibernation sites (cellars, bunkers, ice-houses, small forts) in Flanders, from the Meetnetten.be monitoring network run by INBO and Natuurpunt Studie with volunteers, and earlier counts brought into it (from 1943; most sites from the 1980s). All bats in a site are counted and identified as far as possible, and the totals per species are registered for the site. One row per identification class per count.", uniqueN(long$unit)),
  samplingProtocol = "Winter count of all hibernating bats in a hibernation site without sublocations (or without registration per sublocation); bats identified as far as possible without disturbance, totals per taxon registered for the whole site; usually one count per winter.",
  samplingProtocolCode = "roost_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "period = winter (January year); occasion = count within a winter (most sites are counted once; up to 23 counts in a winter)",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Flanders, Belgium (coordinates generalised by INBO to 5 or 10 km UTM square centroids)",
  temporalCoverage = sprintf("%d/%d", min(ev$year), max(ev$year)),
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO, a government agency) to the centroid of a 5 or 10 km UTM square (coordinateUncertaintyInMeters 3536 or 7071) before publication; kept as published."),
  notes = "Identification classes as recorded: Myotis mystacinus/brandtii and Plecotus auritus/austriacus are species aggregates beside the species-level classes, so species-level zeros are not absences where the aggregate was used (taxonRemarks). Counts before about 1975 are few (one to four sites a winter).",
  notShipped = list(`occurrences without an event` = sprintf("%d occurrence rows whose eventID is not in the event core (no date or site): %s", nrow(orphan), paste(unique(orphan$eventID), collapse = ", ")),
    `non-bat taxa` = sprintf("%d rows of hibernating moths, butterflies, flies, spiders and amphibians recorded incidentally (not counted by protocol)", nrow(nonbat))))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Winter counts of hibernating bats (23 identification classes) at %d hibernation sites of the INBO Meetnetten.be network, Flanders, Belgium, %d-%d; totals per taxon per site count.", uniqueN(long$unit), min(ev$year), max(ev$year)),
  url = "https://doi.org/10.15468/5s3ctr",
  reference = "Piesschaert F, De Bruyn L, Gyselings R, et al. (2025). Meetnetten.be - Bat winter roosts counts (totals per site) Flanders, Belgium. Version 1.7. INBO.",
  doi_paper = "", doi_data = "10.15468/5s3ctr", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-vleermuizen-wintertelling-telobject-occurrences v1.7). Bats only; coordinates generalised by INBO.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "roost_count", design = sprintf("Multi-season (%d winters x 1-%d counts)", uniqueN(long$period), max(long$occasion)),
  realm = "Terrestrial", country = "BEL", coordinates = "As published",
  notes = "Hibernation-site counts of bats, totals per taxon; two species aggregates beside species-level classes.")
