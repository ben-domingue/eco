#!/usr/bin/env Rscript
# Tables: levy_2025_scleroglaucus_ms, levy_2025_sclerodawsoniae_ms (one per species, ruling #20)
# Source: GBIF sampling-event dataset doi:10.15468/hg6kj4, VertNet IPT resource coloradohooklesscactusdemography,
#         version 1.3 (EML packageId 09816958-ce10-4599-93ca-1c6b5c6dc88c/v1.3). Licence as shown in the EML: Creative
#         Commons Zero v1.0 Universal.
#         Citation: Levy R, DePrenger-Levin M (2025). Life History and Demography of Sclerocactus glaucus and Sclerocactus
#         dawsoniae. Version 1.3. Kathryn Kalmbach Herbarium (Denver Botanic Gardens). Samplingevent dataset.
# Paper:  none; DePrenger-Levin (2024) technical report to the BLM (cited in the EML, unpublished).
# Data:   Darwin Core Archive (event core, occurrence and extended measurement-or-fact extensions, multimedia).
#   event.txt (1,502 rows): one per census of a belt transect or macroplot ("<site> Transect: <n>", "Site: <site>",
#     109 locations), eventDate 2008-2025 (no 2020: COVID), locality (distances from towns), elevation (labelled
#     metres, values in feet), latitude / longitude to 0.1 degree (as published; 26 events have none). The EML says
#     sites are surveyed once a year in late April or early May; 124 location-years have two or three events (a
#     census spread over days).
#   occurrence.txt (27,886 rows): one per tagged plant (organismID, tag number in the remarks) per census, present
#     (with reproductive structures present / absent / NULL) or absent (the tagged plant was looked for and not
#     found: the data sheets list every previously surveyed plant). Asserted: each organismID has one species and
#     one location; 381 plant-events are entered twice (both present, both absent, or one each: 70).
#   extendedmeasurementorfact.txt: per occurrence, browsing (present / absent), height and width (cm).
# Mapping (multi-state CJS, E9 core; unit = plant): taxon = the species, unit = organismID, cluster_id = location as
#   a code ("L001"...), period = year (1 = 2008 ... 18 = 2025; 2020 has no census), y = 0 not found, 1 found without
#   reproductive structures, 2 found with them (every found record has the condition; the 4 NULLs are on absent
#   records, asserted); a plant-year with
#   several records takes the highest (found beats not found). y_raw = "absent" where the source has an absent
#   row, empty where it has no row. surveyEvidence = sample_table: the event core lists every census. Every plant
#   is a row in every census year of its location from the location's first census (E4.4: plants of unknown
#   age; the archive does not mark seedlings), 0 where it has no record. obs_height_cm, obs_width_cm, obs_browsed
#   (from found records; NA otherwise), obs_n_events (census events of the location that year).
#   Coordinates: the source publishes 0.1-degree values; kept (unit_ latitude / longitude of the location).
#   S. glaucus was ESA-threatened until 2021 (EML).
# Not shipped: locality (distances from towns, finer than the published coordinates) and the location names (codes
#   instead); elevation (labelled metres, values in feet); multimedia; tag numbers (in the remarks).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
CACHE <- "levy_2025_sclerocactus_ms"
zip <- download_cached("https://ipt.vertnet.org/archive.do?r=coloradohooklesscactusdemography", CACHE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("09816958-ce10-4599-93ca-1c6b5c6dc88c/v1.3", eml, fixed = TRUE), grepl("Creative Commons Zero v1.0 Universal", eml, fixed = TRUE))
rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL)
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("extendedmeasurementorfact.txt")
stopifnot(nrow(ev) == 1502L, nrow(oc) == 27886L, !anyDuplicated(ev$eventID), uniqueN(ev$locationID) == 109L, all(nchar(ev$eventDate) == 10L),
          all(oc$eventID %in% ev$eventID), setequal(oc$occurrenceStatus, c("present", "absent")),
          setequal(oc$scientificName, c("Sclerocactus glaucus", "Sclerocactus dawsoniae")))
ev[, year := as.integer(substr(eventDate, 1, 4))]
stopifnot(!2020 %in% ev$year, all(ev$year %in% 2008:2025))
oc <- merge(oc[, !"eventDate"], ev[, .(eventID, locationID, year)], by = "eventID")
stopifnot(oc[, uniqueN(scientificName), by = organismID][, all(V1 == 1)], oc[, uniqueN(locationID), by = organismID][, all(V1 == 1)],
          sum(duplicated(oc[, .(organismID, eventID)])) == 381L)
m <- dcast(mf[measurementType %in% c("plant height", "plant width", "herbivorous browsing")], occurrenceID ~ measurementType, value.var = "measurementValue", fun.aggregate = function(z) z[1])
setnames(m, c("herbivorous browsing", "plant height", "plant width"), c("browse", "height", "width"))
oc <- merge(oc, m, by = "occurrenceID", all.x = TRUE)
num <- function(z) suppressWarnings(as.numeric(ifelse(z %in% c("NULL", ""), NA, z)))
oc[, st := fifelse(occurrenceStatus == "absent", 0L,
            fifelse(reproductiveCondition == "reproductive structures present", 2L,
            fifelse(reproductiveCondition == "reproductive structures absent", 1L, 3L)))]
stopifnot(sum(oc$st == 3L) == 0L)   # the 4 NULL reproductive conditions are on absent records
setorder(oc, organismID, year, -st)
py <- oc[, .(st = st[1], absent_row = any(occurrenceStatus == "absent"), height = num(height[1]), width = num(width[1]),
             browse = browse[1]), by = .(organismID, scientificName, locationID, year)]
py[st == 0L, `:=`(height = NA, width = NA, browse = NA)]
stopifnot(all(py$browse %in% c(NA, "present", "absent")))
ly <- ev[, .(n_events = .N, lat = num(decimalLatitude[1]), lon = num(decimalLongitude[1])), by = .(locationID, year)]
locs <- sort(unique(ev$locationID))
loc_first <- ly[, .(fy = min(year)), by = locationID]
years <- setdiff(2008:2025, 2020)
emit <- function(sp, code, TABLE, vern) {
  pl <- unique(py[scientificName == sp, .(organismID, locationID)])
  g <- merge(pl, ly, by = "locationID", allow.cartesian = TRUE)
  g <- merge(g, py[scientificName == sp, .(organismID, year, st, absent_row, height, width, browse)], by = c("organismID", "year"), all.x = TRUE)
  stopifnot(nrow(py[scientificName == sp]) == g[!is.na(st), .N])
  g[is.na(st), `:=`(st = 0L, absent_row = FALSE)]
  long <- g[, .(unit = organismID, taxon = code, y = st, y_raw = ifelse(absent_row & st == 0L, "absent", ""), period = match(year, years),
                cluster_id = sprintf("L%03d", match(locationID, locs)), obs_height_cm = height, obs_width_cm = width,
                obs_browsed = ifelse(is.na(browse) | browse == "NULL", NA_integer_, as.integer(browse == "present")), obs_n_events = n_events)]
  never <- long[, max(y), by = unit][V1 == 0, unit]
  long <- long[!unit %in% never]
  un <- unique(g[, .(unit = organismID, unit_decimalLatitude = lat, unit_decimalLongitude = lon)])[order(unit)]
  un <- un[, .(unit_decimalLatitude = unit_decimalLatitude[!is.na(unit_decimalLatitude)][1], unit_decimalLongitude = unit_decimalLongitude[!is.na(unit_decimalLongitude)][1]), by = unit]
  long <- merge(long, un, by = "unit")
  taxa <- if (code == "SCLDAW") make_taxa(code, sp, vernacularName = vern, no_key = code,
                                          taxonRemarks = "Sclerocactus dawsoniae McGlaughlin & Naibauer, split from S. glaucus in 2024 (EML); not in the GBIF backbone")
          else make_taxa(code, sp, vernacularName = vern)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  periods <- data.table(period = seq_along(years), year = years)[period %in% long$period]
  nu <- uniqueN(long$unit)
  dataset <- list(
    title = sprintf("Annual census histories of %s tagged %s (%s) on belt transects and macroplots, western Colorado, 2008-2025", format(nu, big.mark = ","), vern, sp),
    creator = "Levy, Rebecca; DePrenger-Levin, Michelle (Denver Botanic Gardens)",
    pubDate = "2025", doi = "10.15468/hg6kj4", sourceURL = "https://doi.org/10.15468/hg6kj4",
    citation = "Levy R, DePrenger-Levin M (2025). Life History and Demography of Sclerocactus glaucus and Sclerocactus dawsoniae. Version 1.3. Kathryn Kalmbach Herbarium (Denver Botanic Gardens). Samplingevent dataset. https://doi.org/10.15468/hg6kj4",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = "Denver Botanic Gardens' long-term demographic study of the Colorado hookless cactus and Dawson's hookless cactus (split in 2024), western Colorado: every Sclerocactus within 1 m of permanent belt transects and in macroplots is tagged, measured and checked for flowers or fruit at an annual spring census, and previously tagged plants not found are recorded as absent.",
    samplingProtocol = "Annual census (late April or early May) of permanent 1 m belt transects and macroplots: plants located from data sheets listing every previously tagged plant, measured (height, width), scored for reproductive structures and browsing; new plants tagged; tagged plants not found recorded absent.",
    samplingProtocolCode = "marked_plant_census", surveyEvidence = "sample_table", responseType = "state", unitKind = "individual",
    stateCodes = list(`0` = "not found (y_raw absent: the source's absent record; empty: no record)", `1` = "found, no reproductive structures",
                      `2` = "found, reproductive structures present", `3` = "found, reproductive condition not recorded"),
    closure = "none", occasionKind = "none", taxonInclusion = "single",
    closureNote = "period = year (one census a year, occasionally spread over two or three dates: obs_n_events); a plant is a row in every census year of its location from the location's first census.",
    geographicCoverage = "Mesa, Delta and Montrose counties, western Colorado, USA (coordinates published at 0.1 degree)",
    temporalCoverage = "2008/2025",
    coordinatesCoarsened = list(value = FALSE, method = "Published by the source at 0.1 degree (Coarsened by the source); kept. Location names and localities are not shipped."),
    notShipped = list(locality = "distances from towns and transect / site names (location codes instead)", elevation = "minimumElevationInMeters (values in feet)",
                      duplicates = "381 plant-census records entered twice (the higher state kept)", never_found = sprintf("%d tagged plants never recorded as found", length(never))),
    notes = "Plants of unknown age: histories start at the location's first census. 2020: no census (COVID-19). S. dawsoniae was split from S. glaucus in 2024; the archive assigns each plant to one of them.")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/levy_2025_sclerocactus_ms.R")
  stage_dict_row(TABLE,
    description = sprintf("Annual multi-state census histories (not found / vegetative / reproductive) of %s tagged %s on permanent transects and macroplots in western Colorado, 2008-2025, with size and browsing.", format(nu, big.mark = ","), sp),
    url = "https://doi.org/10.15468/hg6kj4",
    reference = "Levy R, DePrenger-Levin M (2025). Life History and Demography of Sclerocactus glaucus and Sclerocactus dawsoniae. Version 1.3. Denver Botanic Gardens. GBIF sampling-event dataset.",
    doi_data = "10.15468/hg6kj4", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "VertNet IPT DwC-A v1.3; absent rows are the source's searched-not-found records.", source_via = "GBIF")
  stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Multi-state CJS", sampling_protocol = "marked_plant_census",
    design = sprintf("Multi-season (%d annual censuses)", uniqueN(long$period)), realm = "Terrestrial", country = "USA",
    coordinates = "Coarsened (by the source, 0.1 deg)", notes = "Endemic cactus; demographic monitoring with BLM.")
  invisible(length(never))
}
n1 <- emit("Sclerocactus glaucus", "SCLGLA", "levy_2025_scleroglaucus_ms", "Colorado hookless cactus")
n2 <- emit("Sclerocactus dawsoniae", "SCLDAW", "levy_2025_sclerodawsoniae_ms", "Dawson's hookless cactus")
