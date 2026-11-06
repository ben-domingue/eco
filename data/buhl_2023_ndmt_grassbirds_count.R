#!/usr/bin/env Rscript
# Tables: buhl_2023_ndmt_grassbirds_count (whole table, place locators replaced) and
#         buhl_2023_ndmt_grassbirds_exact_count (E7.3 sibling without the IUCN CR / EN / VU taxa)
# Source: USGS ScienceBase doi:10.5066/P9JNSTKL (USGS data release, published 2023-07-07; use
#         constraints: the Northern Prairie Wildlife Research Center disclaimer (use with awareness
#         of limitations; acknowledgment "would be appreciated"; notification of new products
#         "would also be appreciated"), no restriction on use; US public domain, recorded as CC0 1.0)
#   Buhl, T.K., and Shaffer, T.L., 2023, Investigating Detection and Roadside Bias in Surveys of
#   Grassland Birds in the Northern Great Plains, ND 2015, MT 2017-2018: U.S. Geological Survey
#   data release.
# Data:   one CSV, 10,045 rows, one per stop x survey: Stop (R on-road, N near-road, O off-road
#         stops, numbered), StopID (PLSS township-range-section + stop: a locator of about a
#         square mile), observer and helper, road and route name (PLSS section), date,
#         SurveyPeriod r.d (round r = 1-3 of the breeding season, day d = 1-3 of three back-to-back
#         replicate days), route start / end time and weather, the stop's distance from the road
#         (m), stop start time, counts of 28 focal species within 100 m (NA where the species was
#         not on that state's list: ND 2015 and MT 2017-2018 differ) plus SPPI1 (Sprague's pipits
#         heard beyond 100 m, MT only), species comments, noise, livestock and vehicles during the
#         count, and the stop's perch-habitat survey (fences, trees, sage / shrub, utility poles and
#         lines, other perches, road surface, wetlands, management, ownership) made once a season.
#         Asserted: (StopID, year, SurveyPeriod) is unique (54 rows share a stop and date with
#         another SurveyPeriod: two survey periods on one day); the NA pattern of each species is
#         constant within a year; the habitat fields are constant per stop.
# Mapping: community counts. unit = stop, cluster_id = route, period = year (1 = 2015, 2 = 2017,
#   3 = 2018), occasion = SurveyPeriod as (round - 1) * 3 + day (1-9), observer = Observer, y = count
#   within 100 m. surveyEvidence row_presence: one row per stop survey. __survey_taxa: the
#   species on each state's list (the non-NA columns), keyed on unit (no stop is in both states).
#   obs_sppi_beyond_100m (MT only), obs_start_time, obs_noise, obs_livestock, obs_vehicles,
#   obs_distance_m (constant per stop except for 3 stops), obs_route_* start weather;
#   unit_stop_type (on / near / off road) and the perch-habitat fields as unit_ codes (as
#   deposited; meanings in the release metadata).
#   Coordinates (E7): none are deposited, but StopID and the route name are PLSS sections, finer
#   than 0.1 degree, and taxa are IUCN VU/EN (GBIF, asserted below), so under the agency
#   coordinates precedent (bull trout, moccasinshell) the whole table replaces stop and route ids
#   by sequential codes and drops road and route names (E7.4); the _exact sibling keeps the PLSS
#   ids and drops the flagged taxa (E7.3).
# Not shipped: Helper, comments, route end weather and times (route-level), PerchDate and the
#   habitat observer; place locators in the whole table (see above).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "buhl_2023_ndmt_grassbirds_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/64a6e867d34ef77fcb063e20?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
x <- fread(download_cached(fl[[grep("\\.csv$", names(fl), value = TRUE)]], TABLE, filename = "grassbirds.csv"), colClasses = "character", na.strings = NULL, encoding = "UTF-8")
setnames(x, 1, "Stop")
sp <- c("RNPH", "UPSA", "LBCU", "MODO", "WEKI", "EAKI", "HOLA", "SPPI", "CCSP", "SAVS", "VESP", "GRSP", "BRSP", "BAIS", "LASP", "LCSP",
        "DICK", "SEWR", "CCLO", "MCLO", "BOBO", "LARB", "WEME", "RWBL", "YHBL", "BRBL", "BHCO", "COGR")
stopifnot(nrow(x) == 10045, all(sp %in% names(x)), "SPPI1" %in% names(x))
x[, d := as.IDate(Date, format = "%m/%d/%Y")][, yr := year(d)]
stopifnot(!anyNA(x$d), setequal(unique(x$yr), c(2015, 2017, 2018)), all(grepl("^[123]\\.[123]$", x$SurveyPeriod)),
          !anyDuplicated(x[, .(StopID, yr, SurveyPeriod)]))
for (s in c(sp, "SPPI1")) stopifnot(x[, uniqueN(get(s) == "NA"), by = yr][, all(V1 == 1)], all(x[[s]] == "NA" | grepl("^[0-9]+$", x[[s]])))
hab <- c("NumFences", "FenceType", "Trees", "SageShrubPportion", "Dominant", "Shrubs", "NumUtilPoles", "NumUtilLines", "Other", "RoadSurface", "Wetlands", "Management", "Ownership")
stopifnot(x[, lapply(.SD, uniqueN), by = StopID, .SDcols = hab][, all(unlist(.SD) == 1), .SDcols = hab],
          sum(x[, uniqueN(Distance), by = StopID]$V1 > 1) == 3, x[, uniqueN(yr == 2015), by = StopID][, all(V1 == 1)])
x[, occasion := (as.integer(substr(SurveyPeriod, 1, 1)) - 1L) * 3L + as.integer(substr(SurveyPeriod, 3, 3))]
x[, period := match(yr, c(2015, 2017, 2018))]
nai <- function(v) { v <- suppressWarnings(as.integer(v)); v }
L <- melt(x[, c("StopID", "RouteName", "Stop", "period", "occasion", "d", "Observer", sp), with = FALSE],
          id.vars = c("StopID", "RouteName", "Stop", "period", "occasion", "d", "Observer"), variable.name = "taxon", value.name = "v", variable.factor = FALSE)
L <- L[v != "NA"]
cv <- x[, .(StopID, period, occasion, sppi1 = nai(SPPI1), start = StartTime, noise = nai(ExcessiveNoise), livestock = nai(Livestock), vehicles = nai(Vehicles),
            dist = as.numeric(Distance), rtemp = nai(StartTemp), rwind = nai(StartWind), rsky = nai(StartSky))]
L <- merge(L, cv, by = c("StopID", "period", "occasion"))
uh <- unique(x[, c("StopID", hab), with = FALSE])
uh[, (hab) := lapply(.SD, nai), .SDcols = hab]
setnames(uh, hab, paste0("unit_", tolower(hab)))
L <- merge(L, uh, by = "StopID")
L[, stop_type := c(R = "on_road", N = "near_road", O = "off_road")[substr(Stop, 1, 1)]]
stopifnot(!anyNA(L$stop_type), nrow(L) == sum(x[, sum(unlist(.SD) != "NA"), .SDcols = sp, by = seq_len(nrow(x))]$V1))
nm <- c(RNPH = "Phasianus colchicus", UPSA = "Bartramia longicauda", LBCU = "Numenius americanus", MODO = "Zenaida macroura", WEKI = "Tyrannus verticalis",
        EAKI = "Tyrannus tyrannus", HOLA = "Eremophila alpestris", SPPI = "Anthus spragueii", CCSP = "Spizella pallida", SAVS = "Passerculus sandwichensis",
        VESP = "Pooecetes gramineus", GRSP = "Ammodramus savannarum", BRSP = "Spizella breweri", BAIS = "Centronyx bairdii", LASP = "Chondestes grammacus",
        LCSP = "Ammospiza leconteii", DICK = "Spiza americana", SEWR = "Cistothorus stellaris", CCLO = "Calcarius ornatus", MCLO = "Rhynchophanes mccownii",
        BOBO = "Dolichonyx oryzivorus", LARB = "Calamospiza melanocorys", WEME = "Sturnella neglecta", RWBL = "Agelaius phoeniceus",
        YHBL = "Xanthocephalus xanthocephalus", BRBL = "Euphagus cyanocephalus", BHCO = "Molothrus ater", COGR = "Quiscalus quiscula")
vn <- c(RNPH = "Ring-necked pheasant", UPSA = "Upland sandpiper", LBCU = "Long-billed curlew", MODO = "Mourning dove", WEKI = "Western kingbird",
        EAKI = "Eastern kingbird", HOLA = "Horned lark", SPPI = "Sprague's pipit", CCSP = "Clay-colored sparrow", SAVS = "Savannah sparrow",
        VESP = "Vesper sparrow", GRSP = "Grasshopper sparrow", BRSP = "Brewer's sparrow", BAIS = "Baird's sparrow", LASP = "Lark sparrow",
        LCSP = "LeConte's sparrow", DICK = "Dickcissel", SEWR = "Sedge wren", CCLO = "Chestnut-collared longspur", MCLO = "McCown's longspur",
        BOBO = "Bobolink", LARB = "Lark bunting", WEME = "Western meadowlark", RWBL = "Red-winged blackbird", YHBL = "Yellow-headed blackbird",
        BRBL = "Brewer's blackbird", BHCO = "Brown-headed cowbird", COGR = "Common grackle")
taxa_all <- make_taxa(sp, unname(nm[sp]), vernacularName = unname(vn[sp]))
taxa_all[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
flagged <- taxa_all[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
message("flagged: ", paste(flagged, collapse = ", "))
stopifnot(identical(flagged, c("SPPI", "CCLO")))
stops <- sort(unique(L$StopID)); routes <- sort(unique(L$RouteName))
periods <- data.table(period = 1:3, year = c(2015L, 2017L, 2018L), state = c("North Dakota", "Montana", "Montana"))
emit <- function(name, exact) {
  lg <- if (exact) L[!taxon %in% flagged] else copy(L)
  lg[, `:=`(u = if (exact) StopID else sprintf("S%04d", match(StopID, stops)), cl = if (exact) RouteName else sprintf("R%03d", match(RouteName, routes)))]
  long <- lg[, .(unit = u, taxon, y = as.integer(v), period, occasion, date = format(d), observer = Observer, cluster_id = cl,
                 unit_stop_type = stop_type, unit_numfences, unit_fencetype, unit_trees, unit_sageshrubpportion, unit_dominant, unit_shrubs,
                 unit_numutilpoles, unit_numutillines, unit_other, unit_roadsurface, unit_wetlands, unit_management, unit_ownership,
                 obs_sppi_beyond_100m = sppi1, obs_start_time = start, obs_distance_m = dist, obs_noise = noise, obs_livestock = livestock,
                 obs_vehicles = vehicles, obs_route_start_temp_f = rtemp, obs_route_start_wind = rwind, obs_route_start_sky = rsky)]
  if (exact) long[, obs_sppi_beyond_100m := NULL]   # a Sprague's pipit count: flagged taxon
  st <- unique(long[, .(taxon, unit)])
  tx <- taxa_all[taxon %in% long$taxon]
  dataset <- list(
    title = sprintf("Repeated counts of %d grassland bird species at on-, near- and off-road stops, North Dakota 2015 and Montana 2017-2018%s",
                    nrow(tx), if (exact) " (IUCN-threatened species omitted)" else ""),
    creator = "Buhl, Thomas K.; Shaffer, Terry L.",
    pubDate = "2023", doi = "10.5066/P9JNSTKL", sourceURL = "https://doi.org/10.5066/P9JNSTKL",
    citation = "Buhl, T.K., and Shaffer, T.L., 2023, Investigating Detection and Roadside Bias in Surveys of Grassland Birds in the Northern Great Plains, ND 2015, MT 2017-2018: U.S. Geological Survey data release, https://doi.org/10.5066/P9JNSTKL.",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (NPWRC disclaimer; no use restriction)"),
    abstract = "Northern Prairie Wildlife Research Center crews counted focal grassland birds within 100 m of on-, near- and off-road stops nine times a breeding season (three rounds of three back-to-back days, late May to mid-July), North Dakota 2015 and Montana 2017-2018, to measure detection and roadside bias in Breeding Bird Survey style counts; perch habitat was recorded once per stop.",
    samplingProtocol = "Breeding Bird Survey style 3-minute stop counts of focal species within 100 m, at on-road, near-road and off-road stops along routes; three survey rounds per season, each of three replicate surveys on back-to-back days; observers assigned by a design that allows observer effects; perch habitat within 100 m recorded once.",
    samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
    closure = "open", occasionKind = "time", taxonInclusion = "target",
    closureNote = "occasion = (round - 1) x 3 + day: replicate days within a round are closed by design; rounds span late May to mid-July.",
    geographicCoverage = list(description = "Grasslands of North Dakota (2015) and Montana (2017-2018), USA",
                              boundingBox = list(west = -108.22, east = -98.29, south = 46.63, north = 48.99)),
    temporalCoverage = "2015-05/2018-07",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("Stop and route ids are PLSS sections as published; the IUCN CR/EN/VU species (%s) are not in this table (E7.3)", paste(flagged, collapse = ", "))) else
      list(value = TRUE, method = sprintf("No coordinates deposited; StopID and route names are PLSS sections (about 1.6 km), so unit and cluster_id are sequential codes and road / route names are not shipped (E7.4), because %s are IUCN CR/EN/VU (GBIF; agency precedent of bull trout and moccasinshell, an open question for Ben). The PLSS ids are in buhl_2023_ndmt_grassbirds_exact_count without those species.", paste(flagged, collapse = ", "))),
    notShipped = c(list(route_level = "route end time and weather, helper, route and species comments, PerchDate, habitat observer"),
                   if (exact) list(flagged_taxa = sprintf("%s, and SPPI1 (Sprague's pipits beyond 100 m): in buhl_2023_ndmt_grassbirds_count only", paste(flagged, collapse = ", "))) else
                     list(locators = "StopID, RouteName and RoadName (PLSS sections and road names; E7.4); in buhl_2023_ndmt_grassbirds_exact_count")),
    notes = "Species lists differ by state (NA columns): __survey_taxa. unit_ habitat fields are the release's codes (FenceType 1 barbed wire ... 5 none; Trees, Shrubs, Wetlands 1 present 2 absent; RoadSurface 1 gravel 2 paved 3 none; Management 2 pasture 3 idle; Ownership 1-6). obs_route_start_* are the route's start weather; obs_noise, obs_livestock, obs_vehicles per stop count.")
  ds <- write_table(long, name, dataset, taxa = tx, periods = periods, survey_taxa = st, script = "data/buhl_2023_ndmt_grassbirds_count.R")
  stage_dict_row(name,
    description = sprintf("Nine-visit-per-season counts of %d focal grassland bird species within 100 m of on-, near- and off-road stops in North Dakota (2015) and Montana (2017-2018), with observers, stop habitat and count conditions%s.", nrow(tx),
                          if (exact) "; IUCN-threatened species omitted, PLSS stop ids kept" else "; stop locators replaced by codes"),
    url = "https://doi.org/10.5066/P9JNSTKL",
    reference = "Buhl, T.K., and Shaffer, T.L. (2023). Investigating Detection and Roadside Bias in Surveys of Grassland Birds in the Northern Great Plains, ND 2015, MT 2017-2018. U.S. Geological Survey data release.",
    doi_data = "10.5066/P9JNSTKL", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
    notes = if (exact) "E7.3 sibling of buhl_2023_ndmt_grassbirds_count without the flagged species." else "Whole table with stop and route codes; PLSS ids in the _exact sibling.",
    source_via = "USGS ScienceBase")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture (community)", sampling_protocol = "point_count",
    design = "Multi-season (3 years x 9 visits: 3 rounds of 3 days)", realm = "Terrestrial", country = "USA",
    coordinates = if (exact) "None in source (PLSS section ids as published)" else "None in source (PLSS locators replaced by codes)",
    notes = "Roadside bias study: on-, near- and off-road stops; designed observer rotation.")
}
emit(TABLE, exact = FALSE)
emit("buhl_2023_ndmt_grassbirds_exact_count", exact = TRUE)
