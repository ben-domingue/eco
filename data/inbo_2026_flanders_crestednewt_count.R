#!/usr/bin/env Rscript
# Table:  inbo_2026_flanders_crestednewt_count
# Source: GBIF sampling-event dataset ea64939f-0dd1-4f6a-9f16-bd6c37b6c2e5, doi:10.15468/zeaq2t, version 1.26 (2026),
#         INBO IPT resource meetnetten-amfibieen-fuiken-occurrences. Licence as shown on GBIF and in the EML: CC0 1.0
#         (INBO asks users to follow its norms for data use, a request, not a term).
#         Citation: Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026).
#         Meetnetten.be - Fyke counts for Amphibia in Flanders, Belgium. Version 1.26. Research Institute for Nature and
#         Forest (INBO). Sampling event dataset. https://doi.org/10.15468/zeaq2t
# Paper:  none; protocol in the Meetnetten.be amphibian monitoring protocol (Speybroeck et al., INBO, cited in the EML).
# Data:   Darwin Core Archive, event core with occurrence extension.
#   event.txt (1,486 rows): one row per fyke set at a pond on a visit; parentEventID = the visit (619; one date and one
#     pond each, asserted; 1 to 10 fykes per visit, mostly 2), locationID = the pond (145, 'Kamsalamander' project),
#     eventDate 2017-2025 (March to June), coordinates generalised by INBO to the centroid of a 5 km UTM square.
#   occurrence.txt (9,666 rows): per fyke the target Triturus cristatus is reported in four categories (male adult,
#     female adult, unknown adult, unknown juvenile 'juveniel'; the juvenile category is missing at 222 fykes), each
#     present with a count or absent = 0, one row per category (asserted); ten other amphibians are reported at
#     some fykes only (where caught, their other categories then carry 0), so their zeros are not evidenced.
# Mapping (repeated counts, single species; responseType count): unit = pond (locationID), period = calendar year
#   2017..2025 as 1..9, occasion = visit within the year in date order (then visit id), date = eventDate, y = adult
#   great crested newts (male + female + unknown adult) summed over the visit's fykes, obs_n_fykes = fykes set on
#   the visit (effort; every fyke reports the target's adult categories, asserted). surveyEvidence = sample_table:
#   every fyke is an event with the target's explicit category rows. taxonInclusion single.
#   Coordinates: generalised by INBO (an agency) to 5 km squares; kept as published (E7). T. cristatus is IUCN LC.
# Not shipped: juveniles (the category is not reported at 222 of 1,486 fykes, so its zeros are not evidenced
#   everywhere; 35 juveniles in total); the per-fyke split (summed, obs_n_fykes kept); other amphibians (recorded
#   at some fykes only); pond names (locality).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "inbo_2026_flanders_crestednewt_count"
zip <- download_cached("https://ipt.inbo.be/archive.do?r=meetnetten-amfibieen-fuiken-occurrences", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public Domain (CC0 1.0)", eml, fixed = TRUE), grepl("ea64939f-0dd1-4f6a-9f16-bd6c37b6c2e5/v1.26", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 1486L, nrow(oc) == 9666L, !anyDuplicated(ev$eventID), all(ev$samplingProtocol == "amphibia fykes"),
          all(ev$eventRemarks == "data collected in the Kamsalamander project"), all(grepl("^\\d{4}-\\d{2}-\\d{2}$", ev$eventDate)),
          all(ev$license == "http://creativecommons.org/publicdomain/zero/1.0/"), uniqueN(ev$parentEventID) == 619L,
          uniqueN(ev$locationID) == 145L, ev[, .(uniqueN(locationID), uniqueN(eventDate)), by = parentEventID][, all(V1 == 1L & V2 == 1L)],
          ev[, uniqueN(paste(decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters)), by = locationID][, all(V1 == 1L)],
          all(ev$dataGeneralizations %in% c("UTM 5km", "UTM 10km")), all(substr(ev$eventDate, 6, 7) %in% c("03", "04", "05", "06")),
          all(oc$eventID %in% ev$eventID), all(oc$occurrenceStatus %in% c("present", "absent")),
          all(oc[occurrenceStatus == "absent"]$individualCount == "0"), all(as.integer(oc[occurrenceStatus == "present"]$individualCount) >= 1L),
          oc[scientificName != "Triturus cristatus", uniqueN(eventID)] < 1486L)
t <- oc[scientificName == "Triturus cristatus"]
t[, cat := paste(sex, lifeStage)]
stopifnot(setequal(t$cat, c("male adult", "female adult", "unknown adult", "unknown juveniel")), !anyDuplicated(t[, .(eventID, cat)]),
          setequal(t[lifeStage == "adult", .N, by = eventID][N == 3L, eventID], ev$eventID),
          uniqueN(t[lifeStage == "juveniel", eventID]) == 1486L - 222L)
fy <- t[lifeStage == "adult", .(y = sum(as.integer(individualCount))), by = eventID]
n_juv <- t[lifeStage == "juveniel", sum(as.integer(individualCount))]
ev <- merge(ev, fy, by = "eventID")
vis <- ev[, .(y = sum(y), n_fykes = .N, locationID = locationID[1], date = eventDate[1], lat = decimalLatitude[1], lon = decimalLongitude[1],
              unc = coordinateUncertaintyInMeters[1]), by = parentEventID]
vis[, year := as.integer(substr(date, 1, 4))]
years <- 2017:2025
stopifnot(nrow(vis) == 619L, all(vis$year %in% years))
setorder(vis, locationID, date, parentEventID)
vis[, occasion := seq_len(.N), by = .(locationID, year)]
long <- vis[, .(unit = sub("^INBO:MEETNET:LOCATION:0*", "P", locationID), taxon = "TRICRI", y, period = match(year, years), occasion, date,
                unit_decimalLatitude = as.numeric(lat), unit_decimalLongitude = as.numeric(lon),
                unit_coordinateUncertaintyInMeters = as.integer(unc), obs_n_fykes = n_fykes)]
stopifnot(sum(long$y) == sum(fy$y))
cat(sprintf("  %d visits at %d ponds; visits per pond-year: %s\n", nrow(long), uniqueN(long$unit),
            paste(names(table(long[, .N, by = .(unit, period)]$N)), table(long[, .N, by = .(unit, period)]$N), sep = ":", collapse = " ")))

taxa <- make_taxa("TRICRI", "Triturus cristatus", vernacularName = "Great Crested Newt")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
stopifnot(!taxa$taxon_iucnCategory %in% c("CR", "EN", "VU"))
periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
dataset <- list(
  title = sprintf("Meetnetten.be fyke counts of great crested newts (Triturus cristatus) in %d ponds, Flanders, Belgium, %d-%d", uniqueN(long$unit), min(vis$year), max(vis$year)),
  creator = "Piesschaert, Frederik; Speybroeck, Jeroen; Brosens, Dimitri; Westra, Toon; Desmet, Peter; Ledegen, Hannes; Van de Poel, Sander; Pollet, Marc (Research Institute for Nature and Forest, INBO)",
  pubDate = "2026", doi = "10.15468/zeaq2t", sourceURL = "https://doi.org/10.15468/zeaq2t",
  citation = "Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026). Meetnetten.be - Fyke counts for Amphibia in Flanders, Belgium. Version 1.26. Research Institute for Nature and Forest (INBO). Sampling event dataset. https://doi.org/10.15468/zeaq2t",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Great crested newt monitoring of the Meetnetten.be priority-species network (INBO and Natuurpunt Studie with volunteers): small fykes set overnight in monitored ponds in spring, several visits in a counting year. One row per pond visit: adult great crested newts caught, summed over the fykes set (obs_n_fykes).",
  samplingProtocol = "Amphibian fykes (small funnel traps) set in a pond and emptied the next day, during the newts' aquatic phase (March to June), several visits per counting year; adults of the target counted by sex (Meetnetten.be amphibian protocol).",
  samplingProtocolCode = "funnel_trap", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = visit within one breeding season (March to June); populations may change between years (period)",
  occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_n_fykes",
  geographicCoverage = "Flanders, Belgium (coordinates generalised by INBO to 5 km UTM square centroids)",
  temporalCoverage = sprintf("%d/%d", min(vis$year), max(vis$year)),
  coordinatesCoarsened = list(value = FALSE, method = "Generalised by the publisher (INBO, a government agency) to the centroid of a 5 km UTM square before publication; kept as published."),
  covariateNote = "obs_n_fykes = number of fykes set on the visit (effort); y sums the adults caught in them.",
  notes = sprintf("y = adults (male, female and unknown-sex adults) summed over the visit's fykes. %d juveniles were reported in total and are not shipped (the category is missing at 222 fykes).", n_juv),
  notShipped = list(
    juveniles = sprintf("the juvenile category (missing at 222 of 1,486 fykes, so its zeros are not evidenced everywhere; %d juveniles)", n_juv),
    `per-fyke counts` = "summed per visit (obs_n_fykes gives the number of fykes)",
    `other amphibians` = "ten other species reported at some fykes only (where caught)",
    locality = "pond names"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Repeated fyke-trap counts of adult great crested newts (Triturus cristatus) in %d ponds of the INBO Meetnetten.be monitoring network, Flanders, Belgium, %d-%d, summed per visit with the number of fykes as effort.", uniqueN(long$unit), min(vis$year), max(vis$year)),
  url = "https://doi.org/10.15468/zeaq2t",
  reference = "Piesschaert F, Speybroeck J, Brosens D, Westra T, Desmet P, Ledegen H, Van de Poel S, Pollet M (2026). Meetnetten.be - Fyke counts for Amphibia in Flanders, Belgium. Version 1.26. INBO.",
  doi_paper = "", doi_data = "10.15468/zeaq2t", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "INBO IPT DwC-A (meetnetten-amfibieen-fuiken-occurrences v1.26). Target species only; adults summed over sex and fykes; coordinates generalised by INBO.",
  source_via = "GBIF")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "funnel_trap", design = sprintf("Multi-season (%d years x 1-%d visits)", uniqueN(long$period), max(long$occasion)),
  realm = "Freshwater", country = "BEL", coordinates = "As published",
  notes = "Priority-species monitoring with volunteers; fyke counts summed per visit, fykes as effort.")
